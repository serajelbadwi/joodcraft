{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}}
  },
  config: {
    // ---------------------------------------------------------------------
    // أوفلاين أولاً: منع أي جلب للخطوط من الشبكة (fonts.gstatic.com).
    //
    // المحرك يبني مسار خط التعويض كـ: fontFallbackBaseUrl + <مسار الخط>.
    // عند القيمة الافتراضية (أو null — لذا لا يُضبط null!) يكون الأساس
    // https://fonts.gstatic.com/s/ فيُنزّل Roboto عند الإقلاع وNoto Sans
    // Arabic عند نقص محرف عربي.
    //
    // نضبطه على جذر التطبيق: تُطلب نفس الملفات بمساراتها الحرفية من هذا
    // الموقع (موحّاة في web/ — انظر web/THIRD_PARTY_FONTS.txt) فلا يخرج أي
    // طلب خارجي، ويبقى احتياط المحرك سليماً يعمل بلا إنترنت.
    // ---------------------------------------------------------------------
    // ---------------------------------------------------------------------
    // أوفلاين أولاً (2): منع تحميل CanvasKit من gstatic أيضاً.
    //
    // بدون هذا البند يختار flutter.js شبه المحرّك
    // https://www.gstatic.com/flutter-canvaskit/<revision>/ افتراضياً رغم أن
    // الملفات مبنية محلياً في build/web/canvaskit/. القيمة "canvaskit"
    // مطابقة حرفية لفرع "محلي" داخل flutter.js نفسه.
    // ---------------------------------------------------------------------
    canvasKitBaseUrl: "canvaskit",
    fontFallbackBaseUrl: "",
  },
});
