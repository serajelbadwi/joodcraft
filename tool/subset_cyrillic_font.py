#!/usr/bin/env python3
"""تصغير خط Noto Sans (اللاتيني/السيريلي) ليكون خط احتياط السيريلية المحزوم.

لماذا خط منفصل؟
----------------
خط الصينية المحزوم (``NotoSansSC-Regular.ttf``) **لا يملك** إلا الأبجدية
الروسية الأساسية (66 محرفاً: ``А..я`` و ``Ё/ё``). لا جدول ``cmap`` فيه للكتلة
السيريلية الكاملة (الأوكرانية ``Ї/Ґ`` والصربية ``Ђ/Љ/Њ/Ћ`` والبلغارية
والسلافية الكنسية القديمة)، ولا خط عربي محزوم يغطيها. لذلك نحزم ``Noto Sans``
نفسه كخط سيريلية مستقل ونمرّره ثانياً في سلاسل الاحتياط (الواجهة والـ PDF).

ماذا يبقى في المجموعة؟
-----------------------
* كامل الكتلة السيريلية ``U+0400..U+04FF``.
* ملحق السيريلية ``U+0500..U+052F`` والسيريلية الممتدة-A ``U+2DE0..U+2DFF``.
* ASCII و Latin-1 والتنقيط العام — كي لا يعتمد النص السيريلي المخلوط باللاتيني
  على خط آخر، ولتبقى المعاينة صحيحة وحدها.

المصدر ثابت الوزن (Regular) من مستودع ``notofonts/noto-fonts``.

الاستخدام
---------
    python tool/subset_cyrillic_font.py            # تنزيل المصدر إن لزم ثم التصغير
    python tool/subset_cyrillic_font.py --src X.ttf

المتطلبات: ``fontTools`` (يأتي مع أداة ``pyftsubset``).
"""

from __future__ import annotations

import argparse
import hashlib
import os
import sys
import urllib.request

SOURCE_URL = (
    "https://raw.githubusercontent.com/notofonts/noto-fonts/main/unhinted/ttf/"
    "NotoSans/NotoSans-Regular.ttf"
)
# بصمة المصدر — نتحقق منها عند التنزيل حتى لا يتسلّل ملف بديل (كما نفعل لكل خط
# محزوم في المشروع: راجع ملاحظة SHA-256 في pubspec.yaml).
SOURCE_SHA256 = "2118e60a3c88075064261fd7ba82c973a01673d3eb44d58a8a983ae0b9a465ed"
SOURCE_CACHE = os.path.join(os.path.dirname(__file__), ".cyr_src.ttf")
DEFAULT_OUT = os.path.join(
    "assets", "fonts", "noto_sans", "NotoSans-Cyrillic.ttf"
)


def sha256(path: str) -> str:
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


def charset() -> set[str]:
    """السيريلية الكاملة + اللاتيني الأساسي + التنقيط — كل ما يلزم نصاً سيريلياً."""
    out: set[str] = set()
    out |= {chr(c) for c in range(0x20, 0x7F)}  # ASCII
    out |= {chr(c) for c in range(0xA0, 0x100)}  # Latin-1 Supplement
    # Latin Extended-A/B — التركية ğ/ş/İ/ı وغيرها، كي يرسم هذا الخط اللاتيني
    # الممتد نفسه بلا حاجة إلى خط عربي بأساليب لاتينية مخالفة.
    out |= {chr(c) for c in range(0x0100, 0x0180)}  # Latin Extended-A
    out |= {chr(c) for c in range(0x0180, 0x0250)}  # Latin Extended-B
    out |= {chr(c) for c in range(0x0400, 0x0500)}  # Cyrillic
    out |= {chr(c) for c in range(0x0500, 0x0530)}  # Cyrillic Supplement
    out |= {chr(c) for c in range(0x2DE0, 0x2E00)}  # Cyrillic Extended-A
    out |= {chr(c) for c in range(0x2000, 0x2070)}  # General Punctuation
    out |= set("—–‘’“”…•·«»©®™±×÷°№")
    return out


def verify(path: str) -> None:
    """نرفض إخراج ملف يغيب عنه محرف سيريلي واحد — فالمربعات تعود بصمت."""
    from fontTools.ttLib import TTFont

    cmap = TTFont(path).getBestCmap()
    # السيريلية كاملة + الحروف التركية الممتدة (Latin Extended-A) التي لا يملكها
    # خط الصينية ولا الخطوط العربية بأساليب لاتينية نظيفة.
    required = (
        [c for c in range(0x0400, 0x0500)]
        + [c for c in range(0x0500, 0x0530)]
        + [c for c in range(0x2DE0, 0x2E00)]
        + [ord(ch) for ch in "ğĞşŞİı"]
    )
    missing = [c for c in required if c not in cmap]
    if missing:
        raise SystemExit(
            "subset is missing %d Cyrillic glyphs: %r"
            % (len(missing), "".join(chr(c) for c in missing[:40]))
        )
    print("coverage OK: %d Cyrillic code points" % len(required))


def subset(src: str, out_path: str) -> None:
    from fontTools import subset
    from fontTools.ttLib import TTFont

    font = TTFont(src)
    options = subset.Options()
    options.hinting = False
    options.legacy_kern = False
    options.name_IDs = ["*"]
    options.name_legacy = True
    options.name_languages = ["*"]
    options.notdef_outline = True
    options.drop_tables += ["BASE", "vhea", "vmtx"]

    before = font["maxp"].numGlyphs
    before_size = os.path.getsize(src)

    subsetter = subset.Subsetter(options=options)
    subsetter.populate(text="".join(sorted(charset())))
    subsetter.subset(font)
    font.save(out_path)

    after = TTFont(out_path)["maxp"].numGlyphs
    out_size = os.path.getsize(out_path)
    print("glyphs: %d -> %d" % (before, after))
    print("size:   %d -> %d bytes (%.1f KB)" % (before_size, out_size, out_size / 1024))

    verify(out_path)


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--src", help="path to the source static font")
    parser.add_argument("--out", default=DEFAULT_OUT, help="output path")
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
    subset(src, args.out)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
