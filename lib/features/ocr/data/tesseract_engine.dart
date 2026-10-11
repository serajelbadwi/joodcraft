/// تنفيذ محرّك الاستخراج عبر `tesseract.exe` في عملية جانبية.
///
/// **لماذا عملية جانبية؟** لأن حزم Flutter الجاهزة (`flutter_tesseract_ocr`
/// وما شابهها) لا تُبنِ لـWindows، والـFFI يحتاج أياماً لإدارة
/// `TessBaseAPI`. القرار موثّق في `report/ocr_integration_decision.md`.
///
/// ضمانات التنفيذ (كلها مطلوبة لأننا نُطلق ملفاً تنفيذياً خارجياً):
/// * `--tessdata-dir` يُمرَّر صراحةً — لا اعتماد على `TESSDATA_PREFIX`.
/// * مهلة زمنية لكل صفحة (`timeout`) وإسقاط العملية عند تجاوزها.
/// * مدخلات كقوائم منفصلة (لا `shell`) — لا حقن أوامر.
/// * ملفات مؤقتة تُحذف في `finally` دائماً.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../domain/ocr_engine.dart';
import '../domain/ocr_engine_status.dart';
import '../domain/ocr_result.dart';
import '../domain/ocr_settings.dart';
import 'image_preprocessor.dart';

class TesseractEngine extends OcrEngine {
  TesseractEngine({
    String? executable,
    String? tessDataDir,
    this.timeout = const Duration(seconds: 25),
    Directory Function()? tempDirProvider,
  }) : _overrideExecutable = executable,
       _overrideTessDataDir = tessDataDir,
       _tempDirProvider = tempDirProvider;

  /// ملف تنفيذي مفروض (للاختبارات أو بيئة مبهمة).
  final String? _overrideExecutable;

  /// مجلد بيانات مفروض (للاختبارات).
  final String? _overrideTessDataDir;

  /// مهلة صفحة واحدة — القياس يقول ~0.9 ثانية، والحدّ يحمي من التعليق.
  final Duration timeout;

  /// مزوّد المجلد المؤقّت — يُحقن في الاختبارات لأن `path_provider`
  /// يحتاج محرّك نظام لا يتوفّر في بيئة `flutter test`.
  final Directory Function()? _tempDirProvider;

  static const List<String> _knownInstallDirectories = <String>[
    r'C:\Program Files\Tesseract-OCR',
    r'C:\Program Files (x86)\Tesseract-OCR',
  ];

  /// مجلدات تثبيت إضافية تُبنى وقت التشغيل (تثبيت UB-Mannheim الافتراضي
  /// للمستخدم الحالي: `%LOCALAPPDATA%\Programs\Tesseract-OCR`).
  static List<String> _runtimeInstallDirectories() {
    final List<String> directories = <String>[];
    final String? localAppData = Platform.environment['LOCALAPPDATA'];
    if (localAppData != null && localAppData.isNotEmpty) {
      directories.add(_join(localAppData, r'Programs\Tesseract-OCR'));
      directories.add(_join(localAppData, r'Tesseract-OCR'));
    }
    final String? programFiles = Platform.environment['ProgramFiles'];
    if (programFiles != null && programFiles.isNotEmpty) {
      directories.add(_join(programFiles, 'Tesseract-OCR'));
    }
    return directories;
  }

  static const String _binaryName = 'tesseract.exe';

  String? _cachedExecutable;
  String? _cachedTessDataDir;

  @override
  String get executableLabel =>
      _cachedExecutable ?? _overrideExecutable ?? _binaryName;

  // ==========================================================================
  //  توفّر المحرّك
  // ==========================================================================

  @override
  Future<OcrEngineStatus> status() async {
    final String? executable = _resolveExecutable();
    if (executable == null || !File(executable).existsSync()) {
      return OcrEngineStatus.missingBinary;
    }
    try {
      final ProcessResult result = await Process.run(executable, const <String>[
        '--version',
      ]);
      if (result.exitCode != 0) {
        return OcrEngineStatus.binaryNotRunnable;
      }
    } on Object {
      return OcrEngineStatus.binaryNotRunnable;
    }
    final String? tessData = _resolveTessDataDir(executable);
    if (tessData == null || !Directory(tessData).existsSync()) {
      return OcrEngineStatus.missingLanguageData;
    }
    return OcrEngineStatus.ready;
  }

  String? _resolveExecutable() {
    if (_cachedExecutable != null) return _cachedExecutable;
    if (_overrideExecutable != null) {
      _cachedExecutable = _overrideExecutable;
      return _cachedExecutable;
    }
    final String? fromEnv = Platform.environment['TESSERACT_CMD'];
    if (fromEnv != null && File(fromEnv).existsSync()) {
      _cachedExecutable = fromEnv;
      return _cachedExecutable;
    }
    // مجلدات التثبيت المعروفة (ثابتة + خاصة بالمستخدم الحالي).
    for (final String directory in <String>[
      ..._knownInstallDirectories,
      ..._runtimeInstallDirectories(),
    ]) {
      final String candidate = _join(directory, _binaryName);
      if (File(candidate).existsSync()) {
        _cachedExecutable = candidate;
        return _cachedExecutable;
      }
    }
    // مجلد التطبيق نفسه (توزيع مستقبلي) ثم PATH.
    final String appDirectory = Platform.resolvedExecutable.isEmpty
        ? Directory.current.path
        : _dirname(Platform.resolvedExecutable);
    final String local = _join(appDirectory, _binaryName);
    if (File(local).existsSync()) {
      _cachedExecutable = local;
      return _cachedExecutable;
    }
    final String? onPath = _findOnPath();
    if (onPath != null) _cachedExecutable = onPath;
    return _cachedExecutable;
  }

  /// يبحث عن التنفيذي في `PATH` (بلا إطلاق صدفة).
  String? _findOnPath() {
    final String? path = Platform.environment['PATH'];
    if (path == null || path.isEmpty) return null;
    for (final String entry in path.split(Platform.isWindows ? ';' : ':')) {
      if (entry.trim().isEmpty) continue;
      final String candidate = _join(entry.trim(), _binaryName);
      if (File(candidate).existsSync()) return candidate;
    }
    return null;
  }

  String? _resolveTessDataDir(String executable) {
    if (_cachedTessDataDir != null) return _cachedTessDataDir;
    if (_overrideTessDataDir != null) return _overrideTessDataDir;

    final String? fromEnv = Platform.environment['TESSDATA_DIR'];
    if (fromEnv != null && Directory(fromEnv).existsSync()) {
      _cachedTessDataDir = fromEnv;
      return _cachedTessDataDir;
    }
    final String beside = _join(_dirname(executable), 'tessdata');
    if (Directory(beside).existsSync()) {
      _cachedTessDataDir = beside;
      return _cachedTessDataDir;
    }
    return null;
  }

  // ==========================================================================
  //  الاستخراج
  // ==========================================================================

  @override
  Future<OcrResult> extract({
    required Uint8List image,
    required OcrSettings settings,
    String? sourceName,
  }) async {
    final String? executable = _resolveExecutable();
    if (executable == null) {
      throw const OcrEngineUnavailableException(OcrEngineStatus.missingBinary);
    }
    final String? tessData = _resolveTessDataDir(executable);
    if (tessData == null) {
      throw const OcrEngineUnavailableException(
        OcrEngineStatus.missingLanguageData,
      );
    }
    final String languageFile =
        '${settings.language.tesseractCode.split('+').first}.traineddata';
    if (!File(_join(tessData, languageFile)).existsSync()) {
      throw const OcrEngineUnavailableException(
        OcrEngineStatus.missingLanguageData,
      );
    }

    final Stopwatch stopwatch = Stopwatch()..start();

    // 1) معالجة قبلية + ملف مؤقّت.
    final PreprocessedImage prepared = ImagePreprocessor.preprocess(
      image,
      settings: settings,
    );

    final Directory temp = _tempDirProvider != null
        ? _tempDirProvider()
        : await getTemporaryDirectory();
    final Directory work = await temp.createTemp('joodcraft_ocr_');
    try {
      final String imagePath = _join(work.path, 'page.png');
      final String outputBase = _join(work.path, 'out');
      await File(imagePath).writeAsBytes(prepared.bytes, flush: true);

      // 2) عملية Tesseract — مخرجات نص + TSV (كلمات وثقتها).
      final List<String> arguments = <String>[
        imagePath,
        outputBase,
        '--tessdata-dir',
        tessData,
        '-l',
        settings.language.tesseractCode,
        '--psm',
        '${settings.psm.value}',
        '-c',
        'preserve_interword_spaces=1',
        '-c',
        'tessedit_create_tsv=1',
      ];

      final ProcessResult result;
      try {
        result = await Process.run(executable, arguments).timeout(timeout);
      } on Object catch (error) {
        throw OcrExtractionException(
          'فشل تشغيل محرّك الاستخراج بعد ${timeout.inSeconds} ثانية.',
          cause: error,
        );
      }
      if (result.exitCode != 0) {
        final String detail = _stderrOf(result);
        throw OcrExtractionException('أعاد المحرّك خطأً ($detail).');
      }

      final File tsvFile = File('$outputBase.tsv');
      if (!tsvFile.existsSync()) {
        throw const OcrExtractionException('لم يُنتج المحرّك ملف نتائج.');
      }
      final String tsv = await tsvFile.readAsString();
      final List<WordBox> words = _parseTsv(
        tsv,
      ); // `tessedit_create_tsv=1` يُسقِط ملف الـ‎.txt عمداً — فيُبنى النص من TSV
      // نفسه (سطراً بسطر حسب block/par/line) فلا نحتاج عملية ثانية.
      final String text = _textFromTsv(tsv);

      stopwatch.stop();
      return OcrResult(
        text: text,
        confidence: _confidenceOf(words),
        wordBoxes: words,
        language: settings.language.tesseractCode,
        elapsedMs: stopwatch.elapsedMilliseconds,
        imageWidth: prepared.width,
        imageHeight: prepared.height,
        sourceName: sourceName,
      );
    } finally {
      // حذف الملفات المؤقتة دائماً (صور المستخدم لا تُبقي أثراً).
      if (work.existsSync()) {
        try {
          await work.delete(recursive: true);
        } on Object {
          // لا شيء: الملفات مؤقتة من الأصل.
        }
      }
    }
  }

  /// متوسط ثقة الكلمات المعروفة على مقياس 0..1.
  double _confidenceOf(List<WordBox> words) {
    final List<WordBox> known = words
        .where(
          (WordBox box) => box.text.trim().isNotEmpty && box.confidence >= 0,
        )
        .toList(growable: false);
    if (known.isEmpty) return 0;
    final double total = known.fold<double>(
      0,
      (double sum, WordBox box) => sum + box.confidence,
    );
    return (total / known.length) / 100;
  }

  /// يقرأ TSV الخاص بـTesseract ويُخرج مربّعات الكلمات بترتيب القراءة.
  ///
  /// الأعمدة: `level page block par line word left top width height conf text`.
  List<WordBox> _parseTsv(String tsv) {
    final List<WordBox> boxes = <WordBox>[];
    final List<String> lines = const LineSplitter().convert(tsv);
    if (lines.isEmpty) return boxes;
    for (int index = 1; index < lines.length; index++) {
      final List<String> columns = lines[index].split('\t');
      if (columns.length < 12) continue;
      final int level = int.tryParse(columns[0]) ?? -1;
      if (level != 5) continue; // 5 = كلمة.
      final String text = columns.sublist(11).join('\t');
      boxes.add(
        WordBox(
          text: text.trim(),
          left: int.tryParse(columns[6]) ?? 0,
          top: int.tryParse(columns[7]) ?? 0,
          width: int.tryParse(columns[8]) ?? 0,
          height: int.tryParse(columns[9]) ?? 0,
          confidence: double.tryParse(columns[10]) ?? -1,
        ),
      );
    }
    return boxes;
  }

  /// يعيد بناء النصّ من كلمات TSV نفسها: كلمات السطر الواحد تُربط بفراغ،
  /// والأسطر بـ‎\n‎، مع حذف الأسطر الفارغة المتتالية (اصطلاح نصّ Tesseract).
  ///
  /// مربّعات الكلمات لا تحتاج سوى ثلاثة أرقام (block/par/line) لتجميعها —
  /// ولا تُحفظ في [WordBox] نفسها، فيُقرأ TSV سطراً بسطر هنا مباشرةً.
  String _textFromTsv(String tsv) {
    final List<String> lines = const LineSplitter().convert(tsv);
    if (lines.isEmpty) return '';
    // كل سطر من TSV = كلمة؛ نجمّعها في أسطر حسب (block,par,line).
    final List<List<String>> linesWords = <List<String>>[];
    String? currentKey;
    for (int index = 1; index < lines.length; index++) {
      final List<String> columns = lines[index].split('\t');
      if (columns.length < 12) continue;
      final int level = int.tryParse(columns[0]) ?? -1;
      if (level != 5) continue;
      final String key = '${columns[2]}/${columns[3]}/${columns[4]}';
      if (key != currentKey) {
        currentKey = key;
        linesWords.add(<String>[]);
      }
      linesWords.last.add(columns.sublist(11).join('\t').trim());
    }
    final List<String> textLines = linesWords
        .map(
          (List<String> words) =>
              words.where((String w) => w.isNotEmpty).join(' '),
        )
        .toList();
    // حذف الأسطر الفارغة المتتالية (Tesseract يُخرج فراغات كثيرة).
    final List<String> cleaned = <String>[];
    for (final String line in textLines) {
      if (line.isEmpty && cleaned.isEmpty) continue;
      if (line.isEmpty && cleaned.isNotEmpty && cleaned.last.isEmpty) continue;
      cleaned.add(line);
    }
    while (cleaned.isNotEmpty && cleaned.last.isEmpty) {
      cleaned.removeLast();
    }
    return cleaned.join('\n');
  }

  String _stderrOf(ProcessResult result) {
    final Object? stderr = result.stderr;
    if (stderr is List<int>) {
      final String text = utf8.decode(stderr, allowMalformed: true).trim();
      return text.isEmpty
          ? 'exit ${result.exitCode}'
          : text.split('\n').last.trim();
    }
    return 'exit ${result.exitCode}';
  }

  // ==========================================================================
  //  مسارات — بلا حزمة `path` (تبقى dependencies كما هي)
  // ==========================================================================

  /// دمج مقاطع مسار (ويندوز فقط عملياً — تطبيق سطح المكتب هذا).
  static String _join(String directory, String fileName) {
    if (directory.endsWith(r'\') || directory.endsWith('/')) {
      return '$directory$fileName';
    }
    return '$directory${Platform.pathSeparator}$fileName';
  }

  static String _dirname(String filePath) {
    final int slash = filePath.lastIndexOf(r'\');
    final int forward = filePath.lastIndexOf('/');
    final int cut = slash > forward ? slash : forward;
    return cut <= 0 ? '.' : filePath.substring(0, cut);
  }
}
