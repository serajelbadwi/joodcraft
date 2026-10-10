#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""قياس أداء PaddleOCR على صور عربية — مهمة **بحث/جدوى** فقط.

لا يُنتج أي كود إنتاجي ولا يلمس `lib/`. الناتج:
  • report/ocr_results/<الصورة>.txt   النصّ المستخرج سطراً بسطر
  • report/ocr_results/_timing.json   الأزمنة والذاكرة لكل صورة

ملاحظة على الواجهة: مثالك الأول كتب لواجهة PaddleOCR 2.x
(`use_angle_cls`, `show_log`, `ocr(img, cls=True)`). النسخة المثبَّتة فعلياً
هي 3.7.0 التي أعادت تسمية الكلّ: `use_angle_cls` → `use_textline_orientation`،
وأُضيف `predict()` بديلاً مُهيكلاً لـ `ocr()` تُعاد منه قواميس ذات
`rec_texts`/`rec_scores`. السكربت يستخدم الواجهة الجديدة مع احتفاظه بنفس
القياسات المطلوبة (وقت/عدد أسطر/نصّ/ذاكرة).
"""

from __future__ import annotations

import json
import os
import re
import statistics
import time
from pathlib import Path

import psutil
import numpy as np
from PIL import Image

# ⚠️ يجب ضبط هذه قبل استيراد paddle. الخطأ الأصلي عند أول تشغيل:
#   NotImplementedError: ConvertPirAttribute2RuntimeAttribute not support
#   [pir::ArrayAttribute<pir::DoubleAttribute>] (onednn_instruction.cc:118)
# عيب في مسار ONEDNN داخل PaddlePaddle 3.3.1 على Windows/CPU مع رسوم
# PP-OCRv5. لم تكفِ متغيّرات البيئة وحدها؛ الحلّ الفعّال تمرير
# `enable_mkldnn=False` إلى المُنشئ (`BUILD_OPTIONS` أدناه).
IMG_DIR = Path("tool", "ocr_test")
OUT_DIR = Path("report", "ocr_results")
IMAGES = ["sample_easy.jpg", "sample_medium.PNG", "sample_hard.PNG"]
LANG = "ar"

# دقة حد الكشف (افتراضي PaddleOCR 3.x = 736). يُوسّع القياس هذا الحد لصور
# أكبر لاختبار فرضيّة: "هل القصور من الحلّة لا من الخط؟"
DET_LIMIT = 736

ONLY = ""
CER = False
PREP = "none"

# أول تمريرة تسخين (تنزيل/تحميل النماذج) ثم القياس.
REPS = 3

os.environ.setdefault("FLAGS_use_mkldnn", "0")
os.environ.setdefault("FLAGS_enable_pir_api", "0")

from paddleocr import PaddleOCR

# ⚠️ يجب ضبط متغيّرات البيئة أعلاه **قبل** الاستيراد، ويُقرأ DET_LIMIT هنا
# بعد `parse_args` لأن الخيارات تُمرَّر على سطر الأوامر.
BUILD_OPTIONS = {
    "lang": LANG,
    "use_textline_orientation": True,
    "enable_mkldnn": False,  # إلزامي عملياً على Windows/CPU — اشرح الأعلى
    "text_det_limit_side_len": DET_LIMIT,
}


def rss_mb() -> int:
    """ذاكرة العملية الحالية بالميغابايت."""
    return int(psutil.Process().memory_info().rss / 1024 / 1024)


def extract(result) -> list[str]:
    """يستخرج النصوص من ناتج `predict()` (يدعم القواميس والكائنات)."""
    texts: list[str] = []
    for page in result or []:
        if hasattr(page, "get"):
            raw = page.get("rec_texts") or []
        else:  # pragma: no cover - احتياط لو تغيّرت بنية الناتج
            raw = getattr(page, "rec_texts", []) or []
        texts.extend(str(t) for t in raw)
    return texts


# --------------------------------------------------------------------------
#                      تجهيز مسبق للصورة (تجارب التحكّم)
# --------------------------------------------------------------------------
# فرضيّة قيد الاختبار: "هل فشل sample_easy بسبب تلوّنها (أسود + أرجواني)
# لا بسبب خطّها؟" تُختبر بتحويلات لونية/بؤرية منفصلة قبل التعرّف.
def preprocess(path: Path, mode: str, out_path: Path) -> None:
    """ينتج نسخة مُجهَّزة من الصورة في `out_path` حسب الوضع."""
    im = Image.open(path).convert("RGB")
    if mode == "none":
        im.save(out_path)
        return

    arr = np.asarray(im).astype(np.float64)

    if mode == "gray":
        # إسقاط البعد اللوني كاملاً: يبقى السطوع فقط.
        Image.fromarray(np.asarray(im.convert("L"))).save(out_path)

    elif mode == "bin":
        # تدرّج رمادي ← عتبة أوتسو: يفصل القمّتين (النصّ الداكن والغبار الفاتح).
        g = np.asarray(im.convert("L"))
        hist, _ = np.histogram(g, bins=256, range=(0, 256))
        total = g.size
        sum_all = float(np.dot(np.arange(256), hist))
        sum_b = 0.0
        w_b = 0.0
        best_var = -1.0
        thr = 127
        for t in range(256):
            w_b += hist[t]
            if w_b == 0:
                continue
            w_f = total - w_b
            if w_f == 0:
                break
            sum_b += t * hist[t]
            m_b = sum_b / w_b
            m_f = (sum_all - sum_b) / w_f
            var = w_b * w_f * (m_b - m_f) ** 2
            if var > best_var:
                best_var = var
                thr = t
        bw = np.where(g > thr, 255, 0).astype(np.uint8)
        Image.fromarray(bw, "L").save(out_path)

    elif mode == "dark":
        # إبقاء نقط/حبر داكن فقط: يقتل الأرجواني والزخرفة الملوّنة.
        # السطوع (Rec.601) للنصّ الأسود ~0-40 وللأرجواني ~85-100.
        lum = (
            0.299 * arr[:, :, 0] + 0.587 * arr[:, :, 1] + 0.114 * arr[:, :, 2]
        )
        bw = np.where(lum < 120, 0, 255).astype(np.uint8)
        Image.fromarray(bw, "L").save(out_path)

    elif mode.startswith("crop:"):
        # قصّ منطقة: crop:<x0>,<y0>,<x1>,<y1> — لاختبار عيّنة مفردة بلا زينة.
        xs = [int(v) for v in mode.split(":", 1)[1].split(",")]
        im.crop(tuple(xs)).save(out_path)

    else:
        raise SystemExit(f"وضع تجهيز غير معروف: {mode}")


def parse_args(argv: list[str]) -> None:
    """معاملات اختيارية لتجارب التحكّم (لا يحتاجها التشغيل الافتراضي).

    --res <int>   دقة حد الكشف (افتراضياً 736).
    --only <name> تقييد القياس على صورة واحدة.
    --reps <int>  عدد تمريرات القياس بعد التسخين.
    --cer         قياس الدقة مقابل المرجع المحفوظ (`gt_*.txt`).
    --prep <m>    تجهيز مسبق: none|gray|bin|dark (لتجارب الألوان).
    """
    global REPS, DET_LIMIT, ONLY, IMAGES, CER, PREP
    i = 0
    while i < len(argv):
        a = argv[i]
        if a == "--res":
            DET_LIMIT = int(argv[i + 1])
            i += 2
        elif a == "--only":
            ONLY = argv[i + 1]
            i += 2
        elif a == "--reps":
            REPS = int(argv[i + 1]) + 1
            i += 2
        elif a == "--cer":
            CER = True
            i += 1
        elif a == "--prep":
            PREP = argv[i + 1]
            i += 2
        else:
            i += 1
    if ONLY:
        IMAGES = [ONLY]


# --------------------------------------------------------------------------
#                         قياس الدقة (CER / WER)
# --------------------------------------------------------------------------
# تشكيل وعلامات بصرية تُفصل كثيراً في العربية: بلا فصلها يظلم CER الرقم لأن
# خطأً واحداً في فتحة يُحتسب خطأ حرفياً كاملاً.
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
    # توحيد الألف (أ إ آ ٱ ٰ → ا) والياء (ى ي → ي).
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

    CER/WER يقيسان الخطّ كما يُسلَّم مُستنداً كاملاً (وهو ما يهم المستخدم)،
    لكنهما يعاقبان بشدّة على **تقطيع** النصّ وفقد ترتيبه. لذا يُضاف مقياس ثالث:
    نسبة كلمات الخطّ التي ظهرت فعلاً في المرجع (بغضّ النظر عن مكانها) — يفصل
    بين "التعرّف فشل" و"التعرّف نجح لكن التقطيع/الترتيب انهارا".
    """
    print("\n=== قياس الدقة ===")
    print(
        f"{'صورة':<18} {'CER خام':>9} {'CER موحّد':>11} {'WER':>8} "
        f"{'دقة موحّدة':>11} {'كلمات مطابقة':>13}"
    )
    for name in IMAGES:
        gt_path = OUT_DIR / f"gt_{name}.txt"
        oc_path = OUT_DIR / f"{name}.txt"
        if not gt_path.exists():
            print(f"  !! لا مرجع لـ {name}: {gt_path}")
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

        # كم من كلمات المرجع ظهرت فعلاً في الناتج (بلا اعتبار للترتيب)؟
        gt_words = [w for w in ref_n.split() if w]
        hyp_set = {w for w in hyp_n.split() if w}
        hit_rate = (
            sum(1 for w in gt_words if w in hyp_set) / len(gt_words) * 100
            if gt_words
            else 0.0
        )

        print(
            f"{name:<18} {cer_raw:>8.1f}% {cer_n:>10.1f}% {wer_raw:>7.1f}% "
            f"{max(0.0, 100 - cer_n):>10.1f}% {hit_rate:>12.1f}%"
        )


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    report: dict[str, dict] = {}

    base_rss = rss_mb()
    print(f"· الذاكرة قبل التحميل: {base_rss} MB")

    t0 = time.perf_counter()
    # الخيارات تُبنى هنا لا عند الاستيراد كي تُطبَّق `--res` قبل بناء النماذج.
    final_options = dict(BUILD_OPTIONS)
    final_options["text_det_limit_side_len"] = DET_LIMIT
    # use_textline_orientation هو الاسم الجديد لـ use_angle_cls (تدوير السطر).
    ocr = PaddleOCR(**final_options)
    load_s = time.perf_counter() - t0
    after_load_rss = rss_mb()
    print(f"· تحميل النماذج: {load_s:.1f}s  →  الذاكرة {after_load_rss} MB")

    for name in IMAGES:
        path = IMG_DIR / name
        if not path.exists():
            print(f"!! ملف مفقود: {path}")
            continue

        # تجهيز مسبق (تجارب الألوان) قبل الإدخال إلى المُحرّك.
        if PREP != "none":
            # الأسماء لا تقبل ':' ولا ',' على Windows ⇒ تُطبَّع قبل الاستخدام.
            safe_mode = PREP.replace(":", "-").replace(",", "-")
            path = OUT_DIR / f"_prep_{safe_mode}_{name}.png"
            preprocess(IMG_DIR / name, PREP, path)

        with Image.open(IMG_DIR / name) as im:
            w, h = im.size

        times: list[float] = []
        texts: list[str] = []
        for i in range(REPS):
            t = time.perf_counter()
            res = ocr.predict(str(path))
            dt = time.perf_counter() - t
            if i == 0:
                texts = extract(res)  # التسخين: نحوّل النتيجة نهائية مرة واحدة
            else:
                times.append(dt)
            print(f"  [{name}] تمريرة {i + 1}: {dt:.2f}s")

        (OUT_DIR / f"{name}.txt").write_text("\n".join(texts), encoding="utf-8")

        report[name] = {
            "width": w,
            "height": h,
            "megapixels": round(w * h / 1e6, 2),
            "load_time_s": round(load_s, 2),
            "runs_s": [round(x, 2) for x in times],
            "median_s": round(statistics.median(times), 2),
            "best_s": round(min(times), 2),
            "rss_after_load_mb": after_load_rss,
            "rss_peak_mb": rss_mb(),
            "lines": len(texts),
            "chars": sum(len(t) for t in texts),
        }

    (OUT_DIR / "_timing.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8"
    )

    print("\n=== ملخّص ===")
    print(f"{'صورة':<18} {'زمن (s)':>9} {'أسطر':>7} {'أحرف':>7}")
    for name, r in report.items():
        print(
            f"{name:<18} {r['median_s']:>9.2f} {r['lines']:>7} {r['chars']:>7}"
        )
    if report:
        med = [r["median_s"] for r in report.values()]
        print(f"{'المتوسط':<18} {statistics.mean(med):>9.2f}")
    print(f"\nالنتائج في: {OUT_DIR}")


if __name__ == "__main__":
    import sys

    parse_args(sys.argv[1:])
    if CER:
        run_cer()
    else:
        main()
