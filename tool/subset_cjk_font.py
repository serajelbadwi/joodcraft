#!/usr/bin/env python3
"""تصغير خط Noto Sans SC قبل حزمه كخط احتياطي للصينية في واجهة فلاتر.

لماذا التصغير أصلاً؟
--------------------
المشروع يمرّر ``AppAssets.uiFontFallback`` مع **كل** نمط نص في الثيم، لذلك على
الويب سيُطلب أي خط محزوم من كل مستخدم — والخط الكامل يبلغ ‎~17MB‎. خط مُصغَّر
يبقي وزن الصفحة معقولاً بينما نضمن غطاءً كاملاً لكل نصوص ترجمة ``app_zh.arb``
وللبيانات التي يُدخلها المستخدم.

ماذا يبقى في المجموعة؟
-----------------------
* كل محارف ``lib/l10n/app_zh.arb`` — هذا هو المطلوب أساساً: ترجمة صينية بلا
  مربعات فارغة (□□□).
* كامل جدول GB2312 (‎~6763‎ هانزي + رموزه) — يغطي ‎>99%‎ من أي نص صيني يكتبه
  المستخدم (أسماء المتدربين في ملفات Excel مثلاً).
* ASCII والتنقيط المكثّف المستعمل في الواجهة.

المصدر متغيّر الوزن (``wght`` 100–900) فيُثبَّت أولاً على 400 (Regular) فتسقط
جداول ``gvar``/``HVAR`` كاملة، ثم يُقصّ الباقي.

الاستخدام
---------
    python tool/subset_cjk_font.py            # تنزيل المصدر إن لزم ثم التصغير
    python tool/subset_cjk_font.py --src X.ttf

المتطلبات: ``fontTools`` (يأتي مع أداة ``pyftsubset``).
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import urllib.request

SOURCE_URL = (
    "https://raw.githubusercontent.com/google/fonts/main/ofl/notosanssc/"
    "NotoSansSC%5Bwght%5D.ttf"
)
# بصمة المصدر — نتحقق منها عند التنزيل حتى لا يتسلّل ملف بديل (كما نفعل لكل خط
# محزوم في المشروع: راجع ملاحظة SHA-256 في pubspec.yaml).
SOURCE_SHA256 = "a3041811a78c361b1de50f953c805e0244951c21c5bd412f7232ef0d899af0da"
SOURCE_CACHE = os.path.join(os.path.dirname(__file__), ".cjk_src.ttf")
DEFAULT_OUT = os.path.join("assets", "fonts", "noto_sans_sc", "NotoSansSC-Regular.ttf")
ARB_DIR = os.path.join("lib", "l10n")
PRIMARY_FONT = os.path.join("assets", "fonts", "cairo", "Cairo-Regular.ttf")
PINNED_WEIGHT = 400  # Regular


def sha256(path: str) -> str:
    import hashlib

    digest = hashlib.sha256()
    with open(path, "rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


def download(dest: str) -> None:
    print("downloading %s" % SOURCE_URL)
    urllib.request.urlretrieve(SOURCE_URL, dest)
    actual = sha256(dest)
    if actual != SOURCE_SHA256:
        raise SystemExit("SHA-256 mismatch: %s (expected %s)" % (actual, SOURCE_SHA256))


def gb2312_chars() -> set[str]:
    """كل رموز GB2312 (zones A1..F7): ‎~6763‎ هانزي + رموز وتنقيط كامل."""
    out: set[str] = set()
    for hi in range(0xA1, 0xF8):
        for lo in range(0xA1, 0xFF):
            try:
                out.add(bytes((hi, lo)).decode("gb2312"))
            except UnicodeDecodeError:
                continue
    return {ch for ch in out if ch}


def arb_chars(arb_dir: str) -> set[str]:
    """كل المحارف في كل ملفات الترجمة — أي نص واجهة يجب أن يُرسم بلا مربعات."""
    out: set[str] = set()
    if not os.path.isdir(arb_dir):
        return out
    for name in sorted(os.listdir(arb_dir)):
        if not name.endswith(".arb"):
            continue
        with open(os.path.join(arb_dir, name), encoding="utf-8") as handle:
            data = json.load(handle)
        for value in data.values():
            if isinstance(value, str):
                out.update(value)
    return out


def base_chars() -> set[str]:
    """ASCII واللاتيني والتنقيط وكتل رموز CJK/الشكل الكامل الكاملة.

    لا نكتفي بالحرف الصيني وحده: نصوص المستخدم تخلط الرموز والتنقيط الصيني
    (``，。「」``) وأشكال العرض الكاملة والأرقام المحيَّطة والأسهم والرموز
    الهندسية، وغياب أي منها يعني مربعاً فارغاً يظهر بصمت. نضمّ الكتل كاملة ولا
    نختار محارف بعينها، فيبقى الغطاء قابلاً للفحص وثابتاً عبر إصدارات Unicode.
    """
    out = {chr(code) for code in range(0x20, 0x7F)}  # ASCII
    out |= {chr(code) for code in range(0xA0, 0x100)}  # Latin-1 Supplement
    out |= {chr(code) for code in range(0x2000, 0x2070)}  # General Punctuation
    out |= {chr(code) for code in range(0x2190, 0x2200)}  # Arrows
    out |= {chr(code) for code in range(0x2200, 0x2300)}  # Mathematical Operators
    out |= {chr(code) for code in range(0x2460, 0x2500)}  # Enclosed Alphanumerics
    out |= {chr(code) for code in range(0x25A0, 0x2600)}  # Geometric Shapes
    out |= {chr(code) for code in range(0x2600, 0x2700)}  # Miscellaneous Symbols
    out |= {chr(code) for code in range(0x2700, 0x27C0)}  # Dingbats
    out |= {chr(code) for code in range(0x2E80, 0x2F00)}  # CJK Radicals Supplement
    out |= {chr(code) for code in range(0x2F00, 0x2FE0)}  # Kangxi Radicals
    out |= {chr(code) for code in range(0x3000, 0x3040)}  # CJK punctuation
    out |= {chr(code) for code in range(0x3100, 0x3130)}  # Bopomofo
    out |= {chr(code) for code in range(0x31A0, 0x31C0)}  # Bopomofo Extended
    out |= {chr(code) for code in range(0x31C0, 0x31F0)}  # CJK Strokes
    out |= {chr(code) for code in range(0x3200, 0x3300)}  # Enclosed CJK Letters
    out |= {chr(code) for code in range(0x3300, 0x3400)}  # CJK Compatibility
    out |= {chr(code) for code in range(0xFE10, 0xFE20)}  # Vertical Forms
    out |= {chr(code) for code in range(0xFE30, 0xFE50)}  # CJK Compatibility Forms
    out |= {chr(code) for code in range(0xFE50, 0xFE70)}  # Small Form Variants
    out |= {chr(code) for code in range(0xFF00, 0xFFF0)}  # Half/Fullwidth Forms
    out |= set("—–‘’“”…•·«»©®™¥€±×÷°№※")
    return out


def collect_charset(arb_dir: str) -> set[str]:
    chars = base_chars() | gb2312_chars() | arb_chars(arb_dir)
    # نسقط علامات التحكم فقط (‎< U+0020‎) — لا نسقط الفراغات، فمنها الفراغ
    # الصيني U+3000 اللازم لنص صيني صحيح.
    return {ch for ch in chars if ord(ch) >= 0x20}


def is_cjk(ch: str) -> bool:
    """نطاقات الكتابات شرق آسيا — هذا وحده ما يلزم هذا الخط تغطيته."""
    code = ord(ch)
    return (
        0x2E80 <= code <= 0x9FFF
        or 0xF900 <= code <= 0xFAFF
        or 0xFF00 <= code <= 0xFFEF
        or 0x3000 <= code <= 0x30FF
    )


def subset(src: str, out_path: str, arb_dir: str, primary_path: str) -> None:
    from fontTools import subset
    from fontTools.ttLib import TTFont
    from fontTools.varLib.instancer import instantiateVariableFont

    font = TTFont(src)
    if "fvar" in font:
        print("pinning variable font to wght=%d" % PINNED_WEIGHT)
        instantiateVariableFont(
            font, {"wght": PINNED_WEIGHT}, inplace=True, updateFontNames=True
        )

    chars = collect_charset(arb_dir)
    print("charset: %d characters" % len(chars))

    options = subset.Options()
    options.hinting = False  # تعليمات التلميح تضخّم الحجم بلا فائدة تُذكر للصينية
    options.legacy_kern = False
    options.name_IDs = ["*"]
    options.name_legacy = True
    options.name_languages = ["*"]
    options.notdef_outline = True
    # نص أفقي فقط: نسقط جداول الكتابة الرأسية وأساسات التخطيط.
    options.drop_tables += ["BASE", "vhea", "vmtx"]

    before = font["maxp"].numGlyphs
    before_size = os.path.getsize(src)

    subsetter = subset.Subsetter(options=options)
    subsetter.populate(text="".join(sorted(chars)))
    subsetter.subset(font)
    font.save(out_path)

    after = TTFont(out_path)["maxp"].numGlyphs
    out_size = os.path.getsize(out_path)
    print("glyphs: %d -> %d" % (before, after))
    print("size:   %d -> %d bytes (%.2f MB)" % (before_size, out_size, out_size / 1048576))

    verify(out_path, arb_dir, primary_path)

def verify(path: str, arb_dir: str, primary_path: str) -> None:
    """نرفض إخراج ملف يغيب محرفاً واحداً — فالمربعات تعود بصمت.

    قاعدة التغطية مقسّمة على أساس المنطق، لا على أساس المصادفة:

    * **هذا الخط وحده** يجب أن يغطي كل CJK: كل رموز GB2312 (نص المستخدم) وكل
      محارف CJK في ملفات الترجمة — والخط الأساسي (Cairo) لا يعرفها أصلاً.
    * **الطليعة الأساسي + هذا الخط معاً** يجب أن يغطيا كل حرف يظهر في أي ترجمة،
      لأن Cairo هو من يرسم العربية والأوردو واللاتينية.
    """
    from fontTools.ttLib import TTFont

    subset_cmap = TTFont(path).getBestCmap()
    primary_cmap = (
        TTFont(primary_path).getBestCmap()
        if primary_path and os.path.exists(primary_path)
        else {}
    )

    localized = {
        ch
        for ch in arb_chars(arb_dir)
        if ch.isprintable() and not ch.isspace()
    }
    own_required = gb2312_chars() | {ch for ch in localized if is_cjk(ch)}

    missing_own = sorted(ch for ch in own_required if ord(ch) not in subset_cmap)
    if missing_own:
        raise SystemExit(
            "subset is missing %d glyphs it must own: %r"
            % (len(missing_own), "".join(missing_own[:40]))
        )

    missing_union = sorted(
        ch
        for ch in localized
        if ord(ch) not in subset_cmap and ord(ch) not in primary_cmap
    )
    if missing_union:
        raise SystemExit(
            "%d localized characters are in neither font (would render as "
            "squares): %r" % (len(missing_union), "".join(missing_union[:40]))
        )

    print(
        "coverage OK: %d own characters, %d localized characters covered "
        "by Cairo + subset" % (len(own_required), len(localized))
    )


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--src", help="path to the source variable font")
    parser.add_argument("--out", default=DEFAULT_OUT, help="output path")
    parser.add_argument("--arb-dir", default=ARB_DIR, help="localizations dir")
    parser.add_argument(
        "--primary",
        default=PRIMARY_FONT,
        help="الخط الأساسي (Cairo) الذي يكمل هذا الخط في تغطية الترجمات",
    )
    args = parser.parse_args(argv)

    src = args.src
    if src is None:
        src = SOURCE_CACHE
        if not os.path.exists(src):
            os.makedirs(os.path.dirname(src) or ".", exist_ok=True)
            download(src)
        actual = sha256(src)
        if actual != SOURCE_SHA256:
            raise SystemExit("SHA-256 mismatch: %s (expected %s)" % (actual, SOURCE_SHA256))

    os.makedirs(os.path.dirname(args.out) or ".", exist_ok=True)
    subset(src, args.out, args.arb_dir, args.primary)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
