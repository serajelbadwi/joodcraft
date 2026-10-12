/// شاشة استخراج النص من صورة — تقسيم: الصورة يساراً والنصّ المحرَّر يميناً.
///
/// **تصميم الشاشة (فواصل أفقي/عمودي):**
/// ```text
/// ┌────────────────────────────────────────┐
/// │  استخراج نص من صورة              [×]  │
/// ├────────────────────┬───────────────────┤
/// │  [الصورة — تكبير]  │  [النص المحرَّر]   │
/// ├────────────────────┴───────────────────┤
/// │ اللغة ▾  التقطيع ▾  التكبير ──●──       │
/// │ ⚠ دقة الاستخراج قد لا تكون 100%…      │
/// │ [استيراد صورة][استيراد PDF][استخراج النص]│
/// │ [إدراج في المحرر][نسخ][إلغاء]           │
/// └────────────────────────────────────────┘
/// ```
///
/// الشاشة **لا تعرف وجهة الإدراج**: تُسلّم النصّ عبر [OcrScreen.onInsert]
/// فيقرّر المُضيف (Jood Writer أو محرّر الشهادات أو الحافظة) كيف يتصرّف.
/// ذلك يمنع اعتماد الشاشة على تبويبات أخرى مملوكة لتبويبات متوازية.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n/app_l10n.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/ocr_engine.dart';
import '../../domain/ocr_engine_status.dart';
import '../../domain/ocr_settings.dart';
import '../providers/ocr_controller.dart';

/// يفتح شاشة الاستخراج كنافذة عائمة ويعيد النصّ المقبول إلى [onInsert].
///
/// إذا فُتحت بـ`onInsert` ظهر زر «إدراج في المحرر»؛ و«قبول» يُغلق الشاشة
/// ويعيد النصّ المحرَّر (أو `null` عند الإلغاء) ليراجعه الندّي المتقدّم.
Future<String?> showOcrScreen(
  BuildContext context, {
  ValueChanged<String>? onInsert,
  OcrEngine? engine,
  OcrController? controller,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) =>
        OcrScreen(onInsert: onInsert, engine: engine, controller: controller),
  );
}

/// شاشة استخراج النص من صورة (قابلة للاستخدام كحوار أو محتوى مسار).
class OcrScreen extends StatefulWidget {
  const OcrScreen({
    super.key,
    required this.onInsert,
    this.engine,
    this.controller,
  });

  /// النصّ المقبول من المستخدم — يُدرَج في وجهة يحدّدها المُضيف إن وُجد.
  final ValueChanged<String>? onInsert;

  /// محرّك مخصّص (لاختبارات أو بيئة معيّنة) — وإلا Tesseract.
  final OcrEngine? engine;

  /// متحكّم جاهز (لاختبارات) — وإلا يُنشأ واحد داخلياً.
  final OcrController? controller;

  @override
  State<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  late final OcrController _controller =
      widget.controller ?? OcrController(engine: widget.engine);
  late final TextEditingController _text = TextEditingController();
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller.addListener(_syncText);
  }

  @override
  void dispose() {
    _controller.removeListener(_syncText);
    _text.dispose();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  /// يزامن حقل الإدخال مع نصّ المتحكّم (عند اكتمال الاستخراج أو الرجوع).
  void _syncText() {
    if (_text.text != _controller.editedText) {
      _text.text = _controller.editedText;
      _text.selection = TextSelection.collapsed(offset: _text.text.length);
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final bool processing = _controller.state == OcrViewState.processing;

    return Dialog(
      key: const Key('ocr_screen'),
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100, maxHeight: 760),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _Header(l10n: l10n, onClose: () => Navigator.of(context).pop()),
            Divider(height: 1, color: theme.dividerColor),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                    child: _ImagePane(controller: _controller, l10n: l10n),
                  ),
                  VerticalDivider(width: 1, color: theme.dividerColor),
                  Expanded(
                    child: _TextPane(
                      controller: _controller,
                      text: _text,
                      l10n: l10n,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: theme.dividerColor),
            _OptionsPane(
              controller: _controller,
              l10n: l10n,
              enabled: !processing,
            ),
            _ActionsPane(
              controller: _controller,
              l10n: l10n,
              processing: processing,
              onInsert: widget.onInsert,
            ),
          ],
        ),
      ),
    );
  }
}

/// شريط العنوان.
class _Header extends StatelessWidget {
  const _Header({required this.l10n, required this.onClose});

  final AppLocalizations? l10n;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: <Widget>[
          const Icon(Icons.document_scanner_outlined),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  l10n?.ocrTitle ?? 'استخراج نص من صورة',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  l10n?.ocrSubtitle ?? 'استورد صورة أو PDF واستخرج النص منها',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            key: const Key('ocr_close_button'),
            onPressed: onClose,
            icon: const Icon(Icons.close),
            tooltip: l10n?.ocrCancel ?? 'إلغاء',
          ),
        ],
      ),
    );
  }
}

/// لوحة الصورة: عارض تفاعلي (تكبير/تحريك) + حالة فارغة/تحميل/خطأ.
class _ImagePane extends StatelessWidget {
  const _ImagePane({required this.controller, required this.l10n});

  final OcrController controller;
  final AppLocalizations? l10n;

  @override
  Widget build(BuildContext context) {
    final Uint8List? bytes = controller.imageBytes;
    final ThemeData theme = Theme.of(context);

    if (bytes == null) {
      return Center(
        key: const Key('ocr_image_empty'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.image_outlined, size: 64, color: theme.disabledColor),
            const SizedBox(height: 12),
            Text(
              l10n?.ocrNoImage ?? 'اختر صورة أو PDF أولاً.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    Widget image = Image.memory(
      bytes,
      key: const Key('ocr_preview_image'),
      fit: BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (BuildContext context, Object error, StackTrace? stack) =>
          Text(l10n?.ocrInvalidImage ?? 'صورة غير صالحة.'),
    );
    image = InteractiveViewer(
      maxScale: 6,
      constrained: false,
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 200, minWidth: 200),
          child: image,
        ),
      ),
    );

    return Container(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      child: image,
    );
  }
}

/// لوحة النص: حقل تحرير متعدد الأسطر + شريط حالة.
class _TextPane extends StatelessWidget {
  const _TextPane({
    required this.controller,
    required this.text,
    required this.l10n,
  });

  final OcrController controller;
  final TextEditingController text;
  final AppLocalizations? l10n;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final OcrResultSummary summary = OcrResultSummary.of(controller);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Row(
            children: <Widget>[
              Text(
                l10n?.ocrPreview ?? 'معاينة النص',
                style: theme.textTheme.titleSmall,
              ),
              const Spacer(),
              if (summary.hasSummary)
                Text(
                  summary.label(l10n),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              key: const Key('ocr_text_field'),
              controller: text,
              expands: true,
              maxLines: null,
              minLines: null,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: l10n?.ocrProcessing ?? 'جاري المعالجة...',
              ),
              onChanged: controller.updateText,
            ),
          ),
        ),
      ],
    );
  }
}

/// خلاصة النتيجة للعرض: «الدقة 61% · 132 كلمة · 0.9 ثانية».
class OcrResultSummary {
  const OcrResultSummary._({required this.hasSummary, required this.label});

  final bool hasSummary;
  final String Function(AppLocalizations? l10n) label;

  static OcrResultSummary of(OcrController controller) {
    final result = controller.result;
    if (result == null) {
      return const OcrResultSummary._(hasSummary: false, label: _empty);
    }
    return OcrResultSummary._(
      hasSummary: true,
      label: (AppLocalizations? l10n) =>
          '${l10n?.ocrConfidence ?? 'الدقة'} ${(result.confidence * 100).round()}%'
          ' · ${result.recognizedWords}'
          ' · ${(result.elapsedMs / 1000).toStringAsFixed(1)}s',
    );
  }

  static String _empty(AppLocalizations? l10n) => '';
}

/// لوحة الخيارات: اللغة + وضع التقطيع + التكبير.
class _OptionsPane extends StatelessWidget {
  const _OptionsPane({
    required this.controller,
    required this.l10n,
    required this.enabled,
  });

  final OcrController controller;
  final AppLocalizations? l10n;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final OcrSettings settings = controller.settings;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Wrap(
        spacing: 16,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(l10n?.ocrLanguageLabel ?? 'اللغة'),
              const SizedBox(width: 8),
              DropdownButton<OcrLanguage>(
                key: const Key('ocr_language_dropdown'),
                value: settings.language,
                isDense: true,
                items: <DropdownMenuItem<OcrLanguage>>[
                  DropdownMenuItem<OcrLanguage>(
                    value: OcrLanguage.arabic,
                    child: Text(l10n?.ocrLanguageArabic ?? 'العربية'),
                  ),
                  DropdownMenuItem<OcrLanguage>(
                    value: OcrLanguage.english,
                    child: Text(l10n?.ocrLanguageEnglish ?? 'الإنجليزية'),
                  ),
                  DropdownMenuItem<OcrLanguage>(
                    value: OcrLanguage.both,
                    child: Text(l10n?.ocrLanguageBoth ?? 'العربية والإنجليزية'),
                  ),
                ],
                onChanged: enabled
                    ? (OcrLanguage? value) {
                        if (value != null) controller.setLanguage(value);
                      }
                    : null,
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(l10n?.ocrPsmLabel ?? 'وضع التقطيع'),
              const SizedBox(width: 8),
              DropdownButton<OcrPsm>(
                key: const Key('ocr_psm_dropdown'),
                value: settings.psm,
                isDense: true,
                items: OcrPsm.values
                    .map(
                      (OcrPsm psm) => DropdownMenuItem<OcrPsm>(
                        value: psm,
                        child: Text(_psmLabel(psm, l10n)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: enabled
                    ? (OcrPsm? value) {
                        if (value != null) controller.setPsm(value);
                      }
                    : null,
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(l10n?.ocrScaleLabel ?? 'التكبير'),
              SizedBox(
                width: 140,
                child: Slider(
                  key: const Key('ocr_scale_slider'),
                  value: settings.scale,
                  min: OcrSettings.minScale,
                  max: OcrSettings.maxScale,
                  divisions: 8,
                  label: settings.scale.toStringAsFixed(1),
                  onChanged: enabled ? controller.setScale : null,
                ),
              ),
              Text(settings.scale.toStringAsFixed(1)),
            ],
          ),
        ],
      ),
    );
  }

  static String _psmLabel(OcrPsm psm, AppLocalizations? l10n) {
    return switch (psm) {
      OcrPsm.auto => l10n?.ocrPsmAuto ?? psm.labelAr,
      OcrPsm.singleBlock => l10n?.ocrPsmBlock ?? psm.labelAr,
      OcrPsm.singleLine => l10n?.ocrPsmLine ?? psm.labelAr,
      OcrPsm.sparseText => l10n?.ocrPsmSparse ?? psm.labelAr,
    };
  }
}

/// شريط الأزرار: استيراد/استخراج/إدراج/نسخ/إلغاء + تحذير الدقة + التقدّم.
class _ActionsPane extends StatelessWidget {
  const _ActionsPane({
    required this.controller,
    required this.l10n,
    required this.processing,
    required this.onInsert,
  });

  final OcrController controller;
  final AppLocalizations? l10n;
  final bool processing;
  final ValueChanged<String>? onInsert;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (processing) ...<Widget>[
            const LinearProgressIndicator(key: Key('ocr_progress')),
            const SizedBox(height: 8),
          ],
          if (controller.engineStatus != OcrEngineStatus.ready)
            Padding(
              key: const Key('ocr_engine_hint'),
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                controller.engineStatus == OcrEngineStatus.missingLanguageData
                    ? (l10n?.ocrLanguageDataMissing ??
                          'بيانات اللغة غير مثبّتة مع Tesseract.')
                    : (l10n?.ocrEngineMissing ??
                          'لم يُعثر على Tesseract — ثبّته ثم أعد المحاولة.'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          if (controller.state == OcrViewState.error)
            Padding(
              key: const Key('ocr_error_message'),
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                controller.error?.label(l10n) ?? '',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          // تنظيف تلقائي: يظهر فقط إن صحّح المعالج اللاحق النصّ فعلاً.
          if (controller.cleanupApplied)
            Padding(
              key: const Key('ocr_cleanup_note'),
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.auto_fix_high_outlined,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n?.ocrCleanupNote ??
                          'تم تصحيح النص تلقائياً — راجعه قبل الحفظ.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  TextButton(
                    key: const Key('ocr_show_raw_button'),
                    onPressed: controller.restoreRawText,
                    child: Text(l10n?.ocrShowRaw ?? 'عرض النص الأصلي'),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              l10n?.ocrAccuracyNote ??
                  'دقة الاستخراج قد لا تكون 100% — راجع النص قبل الحفظ.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: <Widget>[
              OutlinedButton.icon(
                key: const Key('ocr_import_image_button'),
                onPressed: processing ? null : controller.pickImage,
                icon: const Icon(Icons.image_outlined),
                label: Text(l10n?.ocrImportImage ?? 'استيراد صورة'),
              ),
              OutlinedButton.icon(
                key: const Key('ocr_import_pdf_button'),
                onPressed: processing ? null : controller.pickPdf,
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: Text(l10n?.ocrImportPdf ?? 'استيراد PDF'),
              ),
              FilledButton.icon(
                key: const Key('ocr_extract_button'),
                onPressed: controller.canExtract ? controller.extract : null,
                icon: processing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(
                  controller.state == OcrViewState.done
                      ? (l10n?.ocrRetry ?? 'إعادة المحاولة')
                      : (l10n?.ocrExtractText ?? 'استخراج النص'),
                ),
              ),
              if (onInsert != null)
                FilledButton.tonalIcon(
                  key: const Key('ocr_insert_button'),
                  onPressed: controller.hasTextToInsert && !processing
                      ? () {
                          onInsert!(controller.editedText.trim());
                          Navigator.of(context).pop();
                        }
                      : null,
                  icon: const Icon(Icons.post_add_outlined),
                  label: Text(l10n?.ocrInsertInEditor ?? 'إدراج في المحرر'),
                ),
              OutlinedButton.icon(
                key: const Key('ocr_accept_button'),
                onPressed: controller.hasTextToInsert && !processing
                    ? () => Navigator.of(
                        context,
                      ).pop<String>(controller.editedText.trim())
                    : null,
                icon: const Icon(Icons.check_outlined),
                label: Text(l10n?.ocrAccept ?? 'قبول'),
              ),
              OutlinedButton.icon(
                key: const Key('ocr_copy_button'),
                onPressed: controller.hasTextToInsert && !processing
                    ? () => _copy(context)
                    : null,
                icon: const Icon(Icons.copy_outlined),
                label: Text(l10n?.ocrCopyToClipboard ?? 'نسخ'),
              ),
              TextButton(
                key: const Key('ocr_cancel_button'),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n?.ocrCancel ?? 'إلغاء'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _copy(BuildContext context) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: controller.editedText.trim()));
    messenger.showSnackBar(
      SnackBar(content: Text(l10n?.ocrCopyDone ?? 'نُسخ النص إلى الحافظة.')),
    );
  }
}

/// عدّاد الصفحات في PDF (يظهر بعد استيراد PDF متعدّد الصفحات).
String ocrPdfPagesLabel(AppLocalizations? l10n, int pages) =>
    '${l10n?.ocrPdfPages ?? 'الصفحات'} $pages';
