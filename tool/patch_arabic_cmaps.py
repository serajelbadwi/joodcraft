# -*- coding: utf-8 -*-
"""وصل صور الحروف العربية المعزولة داخل cmaps خطوط التطبيق.

لماذا نحتاج هذا؟
    محرّك الـ PDF في دارت (حزمة `bidi`) يحوّل النص العربي إلى **صور العرض
    المتصلة** (Arabic Presentation Forms-B ‏U+FE80..FEFC) ثم يبحث عن كل صورة
    في `cmap` — بلا تنفيذ جداول GSUB. معظم الخطوط التجارية تحذف صور
    "المعزولة" (ISOLATED) بحجة أنها تُشتق من GSUB في أنظمة التشغيل، فتظهر
    مربعات فارغة في الطباعة لكل حرف واقف في أول الكلمة.

الحل (وهو صحيح بصرياً بالتعريف):
    الشكل المعزول لحرف هو **بالضبط** الشكل الافتراضي للرمز الأساسي في الخط
    (لأن المعزول هو وضع الحرف الافتراضي). فنضيف في كل جدول cmap مدخلات
    الصور الناقصة ونوجّهها إلى رمز الحرف الأساسي — بلا رسم أي رمز جديد.

آمن وقابل للتكرار:
    * يضيف الصور الناقصة فقط (ما هو موجود لا يُمسّ).
    * يرفض صمتاً أي ملف تغيّر بنيته (أي ملف ليس TTF بجداول cmap قياسية).
    * يعيد تقريراً بالأرقام قبل/بعد لكل ملف.

الاستخدام:
    python tool/patch_arabic_cmaps.py assets/fonts/**/*.ttf
"""

from __future__ import annotations

import sys
import unicodedata
from pathlib import Path

from fontTools.ttLib import TTFont

FORMS_RANGE = range(0xFE80, 0xFEF5)  # 117 صورة: U+FE80..FEF4
BASE_RANGE = range(0x0621, 0x064B)  # الحروف العربية الأساسية
ISOLATED_SUFFIX = " ISOLATED FORM"


def base_letter_map() -> dict[str, int]:
    """اسم الحرف الأساسي ← رمزه (مطابقة بالأسماء لا بجدول يدوي)."""
    out: dict[str, int] = {}
    for cp in BASE_RANGE:
        try:
            out[unicodedata.name(chr(cp))] = cp
        except ValueError:
            continue
    return out


def covered(font: TTFont) -> set[int]:
    """كل الرموز المغطاة في أي جدول cmap."""
    seen: set[int] = set()
    for table in font["cmap"].tables:
        seen.update(table.cmap.keys())
    return seen


def patch(path: Path, bases: dict[str, int]) -> int:
    font = TTFont(str(path))
    if "cmap" not in font:
        print(f"  [تخطّي] {path.name}: بلا جدول cmap")
        return 0

    have = covered(font)
    missing = [cp for cp in FORMS_RANGE if cp not in have]
    if not missing:
        print(f"  [سليم] {path.name}: 117/117 — لا حاجة للوصل")
        return 0

    additions: dict[int, int] = {}
    unresolved: list[int] = []
    for cp in missing:
        name = unicodedata.name(chr(cp), "")
        if not name.endswith(ISOLATED_SUFFIX):
            unresolved.append(cp)  # صورة نهائية/متوسطة ناقصة — لا نخمن
            continue
        base_name = name[: -len(ISOLATED_SUFFIX)]
        base_cp = bases.get(base_name)
        if base_cp is None:
            unresolved.append(cp)
            continue
        additions[cp] = base_cp

    if unresolved:
        print(
            f"  [خطأ] {path.name}: صور ناقصة لا تُوصل آمناً: "
            + ", ".join(f"U+{c:04X}" for c in unresolved)
        )
        return 0

    # إضافة المداخل لجداول cmap الستة فقط: صيغة 0 (ماك) بثمانية أBits
    # لا تحتمل رموزاً فوق 255، وصيغة 14 للاختلافات — ولا يستهلكهما أحد
    # (محرّك الـ PDF يقرأ (3,1)/format4 أو (3,10)/format12).
    glyph_for = font.getBestCmap()
    added = 0
    patched_tables = 0
    for table in font["cmap"].tables:
        if table.format not in (4, 12):
            continue
        before = len(table.cmap)
        for src_cp, dst_cp in additions.items():
            glyph = glyph_for.get(dst_cp)
            if glyph is None or src_cp in table.cmap:
                continue
            table.cmap[src_cp] = glyph
        if len(table.cmap) != before:
            patched_tables += 1
            added += len(table.cmap) - before

    if patched_tables == 0:
        print(f"  [خطأ] {path.name}: لا يوجد جدول cmap بصيغة 4/12 للوصل")
        return 0

    # حفظ ذري: إلى ملف مؤقت ثم استبدال — فلا يُترك ملف ناقص عند أي فشل.
    tmp = path.with_suffix(path.suffix + ".tmp")
    font.save(str(tmp))
    tmp.replace(path)
    # تحقق بعد الحفظ بقراءة جديدة.
    after = len(FORMS_RANGE) - len(
        [c for c in FORMS_RANGE if c not in covered(TTFont(str(path)))]
    )
    print(f"  [وُصل] {path.name}: {len(missing)} ناقصة → الآن {after}/117")
    return len(missing)


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print(__doc__)
        return 2
    bases = base_letter_map()
    files = sorted(Path().glob(argv[1])) if len(argv) == 2 else [Path(a) for a in argv[1:]]
    # دعم glob عبر الشل (tin) — القوالب تصل موسّعة أصلاً.
    total = 0
    for f in files:
        if f.suffix.lower() in (".ttf", ".otf") and f.exists():
            total += patch(f, bases)
    print(f"\nالإجمالي: {total} مدخل cmap أُضيف عبر {len(files)} ملفاً.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
