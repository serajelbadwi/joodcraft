#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""قياس أداء Tesseract 5.4 على صور عربية — مهمة **بحث/جدوى** فقط.

لا يُنتج أي كود إنتاجي ولا يلمس `lib/` ولا `pubspec.yaml`. الناتج:
  • report/ocr_results/tess_<الصورة>.txt   النصّ المستخرج سطراً بسطر
  • report/ocr_results/_timing_tess.json   الأزمنة والذاكرة لكل صورة

لماذا هذا الملف: قياس PaddleOCR (report/paddleocr_benchmark.md) أثبت fallacy
الدقة (28.6% على أسهل صورة) مع 47.65 ثانية/صفحة. هذا السكربت يقيس البديل
الأرخص والأسرع (Tesseract + حزمة العربية `ara.traineddata`) بـ**نفس**
المنهجية الحاسوبية (CER/WER + الكلمات المطابقة) حتي تصبح المقارنة عادلة.

التركيب:
  tesseract 5.4.0 (UB-Mannheim) +ara.traineddata (tessdata_fast) +pytesseract
  TESSDATA تُمرَّر صراحةً عبر توجيه `--tessdata-dir` (لا اعتماد على PATH).
"""

from __future__ import annotations

import argparse
import json
import os
import re
import statistics
import sys
import time
from pathlib import Path

import psutil
from PIL import Image

import pytesseract

# وحدة تحكّم Windows الافتراضية (cp1256) تُسقِط «→» وبعض الرموز في الطباعة.
# لا يمسّ هذا جودة الناتج المكتوب على القرص (UTF-8 صريح في كل مكان) — الطباعة
# وحدها هي التي تحتاج الترميم.
if hasattr(sys.stdout, "reconfigure"):  # Python 3.7+
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

# --------------------------------------------------------------------------
#                    مسار Tesseract وبياناته (صريح لا ضمني)
# --------------------------------------------------------------------------
DEFAULT_TESS = Path(
    os.environ.get(
        "TESSERACT_CMD",
        r"C:\Users\gh\AppData\Local\Programs\Tesseract-OCR\tesseract.exe",
    )
)
DEFAULT_TESSDATA = Path(
    os.environ.get(
        "TESSDATA_DIR",
        r"C:\Users\gh\AppData\Local\Programs\Tesseract-OCR\tessdata",
    )
)

IMG_DIR = Path("tool", "ocr_test")
OUT_DIR = Path("report", "ocr_results")
IMAGES = ["sample_easy.jpg", "sample_medium.PNG", "sample_hard.PNG"]

ARGS = None  # تُملأ في main من سطر الأوامر


def rss_mb() -> int:
    """ذاكرة العملية الحالية بالميغابايت."""
    return int(psutil.Process().memory_info().rss / 1024 / 1024)


def tesseract_version() -> str:
    return str(pytesseract.get_tesseract_version())


# --------------------------------------------------------------------------
#                         قياس الدقة (CER / WER)
# --------------------------------------------------------------------------
# نفس دالّات سكربت PaddleOCR حرفياً: تشكيل وعلامات بصرية تُفصل كثيراً في
# العربية، وبلا فصلها يظلم CER الرقم لأن خطأً في فتحة يُحتسب خطأً في حرف.
_TASHKEEL = dict.fromkeys(
    list(range(0x064B, 0x0653))          # فتحة ضمة كسرة شدة سكون
    + list(range(0x0653, 0x0656))
    + list(range(0x0670, 0x0671))        # ألف خنجرية
    + list(range(0x06D6, 0x06ED))        # قرآنية وعلامات وقف
    + [0x0640]                           # تطويل
    + [0x200C, 0x200D, 0x200E, 0x200F]   # محارف اتجاه/وصل غير مرئية
)


def normalize_ar(s: str) -> str:
    """توحيد الحروف والحركات: يُبقي بقيّة النصّ كما هو."""
    s = s.translate(_TASHKEEL)
    s = re.sub("[أإآٱٰ]", "ا", s)
    s = s.replace("ى", "ي")
    return s


def _levenshtein(a: list[str], b: list[str]) -> int:
    """مسافة التحرير على متتالية من الحروف (أو الكلمات)."""
    if not a:
        return len(b)
    if not b:
        return len(a)
    prev = list(range(len(b) + 1))
    for i, ca in enumerate(a, start=1):
        cur = [i] + [0] * len(b)
        for j, cb in enumerate(b, start=1):
            cur[j] = min(
                prev[j] + 1,          # حذف
                cur[j - 1] + 1,       # إضافة
                prev[j - 1] + (ca != cb),
            )
        prev = cur
    return prev[-1]


def error_rates(hyp: str, ref: str) -> tuple[float, float]:
    """يعيد (نسبة خطأ الحرف، نسبة خطأ الكلمة) بالنسبة المئوية."""
    if not ref:
        return (0.0, 0.0)
    h_ch, r_ch = list(hyp), list(ref)
    cer = _levenshtein(h_ch, r_ch) / len(r_ch) * 100
    h_w = hyp.split()
    r_w = ref.split()
    wer = _levenshtein(h_w, r_w) / max(len(r_w), 1) * 100
    return (cer, wer)


def run_cer() -> None:
    """يقيس دقّة كل صورة مقابل ملفها المرجعي `gt_<name>.txt`.

    CER/WER يقيسان النصّ كما يُسلَّم للمستخدم (الفراغات والأسطر جزء من الناتج)،
    ومقياس «كلمات مُطابَقة» يفصل بين فشل التعرّف وفشل التقطيع/الترتيب — نفس
    تفكيك سكربت PaddleOCR حتى تُقارَن الأرقام بلُغة واحدة.
    """
    print("\n=== قياس الدقة ===")
    print(
        f"{'صورة':<18} {'CER خام':>9} {'CER موحّد':>11} {'WER':>8} "
        f"{'دقة موحّدة':>11} {'كلمات مطابقة':>13}"
    )
    for name in IMAGES:
        gt_path = OUT_DIR / f"gt_{name}.txt"
        oc_path = OUT_DIR / f"tess_{name}.txt"
        if not gt_path.exists():
            print(f"  !! لا مرجع لـ {name}: {gt_path}")
            continue
        if not oc_path.exists():
            print(f"  !! لا ناتج Tesseract لـ {name}: {oc_path}")
            continue
        ref_raw = " ".join(
            ln.strip() for ln in gt_path.read_text(encoding="utf-8").splitlines() if ln.strip()
        )
        hyp_raw = " ".join(
            ln.strip() for ln in oc_path.read_text(encoding="utf-8").splitlines() if ln.strip()
        )
        cer_raw, wer_raw = error_rates(hyp_raw, ref_raw)

        ref_n, hyp_n = normalize_ar(ref_raw), normalize_ar(hyp_raw)
        cer_n, _ = error_rates(hyp_n, ref_n)

        gt_words = [w for w in ref_n.split() if w]
        gt_set = set(gt_words)
        hyp_words = [w for w in hyp_n.split() if w]
        # كم من كلمات المرجع ظهرت فعلاً في الناتج (استذكار).
        hit_rate = (
            sum(1 for w in gt_words if w in set(hyp_words)) / len(gt_words) * 100
            if gt_words
            else 0.0
        )
        # كم من كلمات الناتج مُعرِّف فعلاً (دقّة): يفصل «قرأ زيادة» عن «أخطأ».
        # المرجع يغطّي جزءاً من الصور (خاصة hard) فبدونه يُحسب الناتج الزائد
        # خطأً كاملاً.
        precision = (
            sum(1 for w in hyp_words if w in gt_set) / len(hyp_words) * 100
            if hyp_words
            else 0.0
        )
        # أسطر المرجع التي ظهرت فعلاً في الناتج (سطراً كاملاً).
        gt_lines = [normalize_ar(ln.strip()) for ln in gt_path.read_text(encoding="utf-8").splitlines()]
        gt_lines = [ln for ln in gt_lines if ln]
        hyp_lines = {normalize_ar(ln.strip()) for ln in oc_path.read_text(encoding="utf-8").splitlines()}
        line_hit = (
            sum(1 for ln in gt_lines if ln in hyp_lines) / len(gt_lines) * 100
            if gt_lines
            else 0.0
        )

        print(
            f"{name:<18} {cer_raw:>8.1f}% {cer_n:>10.1f}% {wer_raw:>7.1f}% "
            f"{max(0.0, 100 - cer_n):>10.1f}% {hit_rate:>12.1f}% "
            f"أسطر: {line_hit:.1f}%  دقة-كلمات: {precision:.1f}%"
        )


# --------------------------------------------------------------------------
#                                القياس
# --------------------------------------------------------------------------
def extract_text(image_path: Path, psm: int, lang: str, crop: str = "", scale: float = 1.0) -> str:
    """يستخرج النصّ عبر pytesseract بإعدادات صريحة (مجلود البيانات + psm).

    `crop` بصيغة `x,y,w,h` بالبكسل: يقيّد التعرّف على منطقة من الصورة.
    `scale` يكبّر الصورة قبل التعرّف: TSTM يعمل أحسن ما يكون على نصّ ~300dpi،
    وصورتا medium/hard أقلّ من ذلك بكثير.
    """
    with Image.open(image_path) as im:
        img = im.convert("RGB")
    if crop:
        x, y, w, h = (int(v) for v in crop.split(","))
        img = img.crop((x, y, x + w, y + h))
    if scale and scale != 1.0:
        new_size = (max(1, round(img.width * scale)), max(1, round(img.height * scale)))
        img = img.resize(new_size, Image.LANCZOS)
    # ملاحظة: pytesseract يجزّئ الإعدادات على المسافات، فالمسار بلا اقتباس
    # (مسارات هذه البيئة بلا فراغات أصلاً). المسار مُمرَّر صراحةً حتى لا يعتمد
    # التقييم على متغيّرات بيئة المطوّر.
    config = f"--tessdata-dir {ARGS.tessdata} --psm {psm}"
    return pytesseract.image_to_string(img, lang=lang, config=config)


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    if not ARGS.tess.exists():
        print(f"!! Tesseract غير موجود: {ARGS.tess}")
        print("   ثبّت من https://github.com/UB-Mannheim/tesseract/releases")
        sys.exit(2)
    pytesseract.pytesseract.tesseract_cmd = str(ARGS.tess)

    base_rss = rss_mb()
    print(f"· الذاكرة قبل التحميل: {base_rss} MB")
    print(f"· Tesseract: {tesseract_version()}  ·  لغة: {ARGS.lang}  ·  psm: {ARGS.psm}  ·  بيانات: {ARGS.tessdata}")

    t0 = time.perf_counter()
    langs = pytesseract.get_languages()
    load_s = time.perf_counter() - t0
    after_load_rss = rss_mb()
    print(f"· تحميل اللغات: {load_s:.2f}s  →  الذاكرة {after_load_rss} MB  ·  المتاح: {langs}")
    if ARGS.lang.split("+")[0] not in langs:
        print(f"!! اللغة {ARGS.lang} غير متاحة في {ARGS.tessdata}")
        sys.exit(3)

    report: dict[str, dict] = {}
    images = [ARGS.only] if ARGS.only else IMAGES

    for name in images:
        path = IMG_DIR / name
        if not path.exists():
            print(f"!! ملف مفقود: {path}")
            continue

        with Image.open(path) as im:
            w, h = im.size

        times: list[float] = []
        text = ""
        for i in range(ARGS.reps):
            t = time.perf_counter()
            text = extract_text(path, ARGS.psm, ARGS.lang, ARGS.crop, ARGS.scale)
            dt = time.perf_counter() - t
            if i == 0:
                pass  # التمريرة الأولي تسخين (cache الصفحة/الخطوط) كسكربت PaddleOCR
            else:
                times.append(dt)
            print(f"  [{name}] تمريرة {i + 1}: {dt:.2f}s")

        # الناتج النهائي من آخر تمريرة (تسخين + N قياسات).
        lines = [ln.rstrip() for ln in text.splitlines()]
        # Tesseract يُخرِج أسطراً فارغة كثيرة: تُحذف الفراغات المتتالية مع إبقاء
        # ترتيب النصّ كما هو (نفس اصطلاح ملفات PaddleOCR).
        while lines and not lines[0].strip():
            lines.pop(0)
        while lines and not lines[-1].strip():
            lines.pop()
        (OUT_DIR / f"tess_{name}.txt").write_text("\n".join(lines), encoding="utf-8")

        report[name] = {
            "engine": "tesseract",
            "version": tesseract_version(),
            "lang": ARGS.lang,
            "psm": ARGS.psm,
            "width": w,
            "height": h,
            "megapixels": round(w * h / 1e6, 2),
            "load_time_s": round(load_s, 2),
            "runs_s": [round(x, 2) for x in times],
            "median_s": round(statistics.median(times), 2) if times else 0,
            "best_s": round(min(times), 2) if times else 0,
            "rss_after_load_mb": after_load_rss,
            "rss_peak_mb": rss_mb(),
            "lines": sum(1 for ln in lines if ln.strip()),
            "chars": sum(len(ln) for ln in lines),
        }

    (OUT_DIR / "_timing_tess.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8"
    )

    print("\n=== ملخّص ===")
    print(f"{'صورة':<18} {'زمن (s)':>9} {'أسطر':>7} {'أحرف':>7}")
    for name, r in report.items():
        print(
            f"{name:<18} {r['median_s']:>9.2f} {r['lines']:>7} {r['chars']:>7}"
        )
    if report:
        med = [r["median_s"] for r in report.values() if r["median_s"]]
        if med:
            print(f"{'المتوسط':<18} {statistics.mean(med):>9.2f}")
    print(f"\nالنتائج في: {OUT_DIR}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="قياس Tesseract على صور عربية")
    parser.add_argument("--tess", default=str(DEFAULT_TESS), help="مسار tesseract.exe")
    parser.add_argument("--tessdata", default=str(DEFAULT_TESSDATA), help="مجلد tessdata")
    parser.add_argument("--lang", default="ara", help="لغة التعرّف (ara / ara+eng)")
    parser.add_argument("--psm", type=int, default=3, help="وضع تقسيم الصفحة")
    parser.add_argument("--reps", type=int, default=4, help="عدد التمريرات (1 تسخين + N قياس)")
    parser.add_argument("--only", default="", help="صورة واحدة فقط")
    parser.add_argument("--crop", default="", help="قصّ الصورة قبل التعرّف: x,y,w,h")
    parser.add_argument("--scale", type=float, default=1.0, help="تكبير الصورة قبل التعرّف (1.5 / 2.0)")
    parser.add_argument("--cer", action="store_true", help="قياس الدقة مقابل المرجع")
    ARGS = parser.parse_args()
    ARGS.tess = Path(ARGS.tess)
    ARGS.tessdata = Path(ARGS.tessdata)

    if ARGS.cer:
        run_cer()
    else:
        main()
