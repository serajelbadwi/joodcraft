/// تاريخ التراجع/الإعادة لمستند «جود كاتب» — طبقة **مستقلّة عن الـController**
/// تعتمد على لقطات JSON من `document` وتعيد تحميلها بـ`loadDocument`.
///
/// التصميم:
/// * تستمع إلى الـcontroller، وعند كل تغيّر تؤجّل 700ms (أي كتابة سريعة
///   متتابعة تصبح لقطة واحدة) ثم تضع لقطة إن اختلفت آخر المستند.
/// * حدّ أقصى 50 لقطة — الأقدم يُطوى (ذاكرة محدودة وثابتة).
/// * [undo]/[redo] يُعيدان تحميل المستند عبر `loadDocument` مع كتم الإشعار
///   أثناء الاستعادة حتى لا تُستدعى اللقطة ذاتها مجدداً.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../domain/jood_writer_document.dart';
import '../../writer_document_controller.dart';

class WriterRibbonHistory extends ChangeNotifier {
  WriterRibbonHistory(this._controller) {
    _listener = _onControllerChanged;
    _controller.addListener(_listener);
    // اللقطة الابتدائية: المستند المفتوح عند إنشاء التاريخ.
    _snapshotNow(_controller.document);
  }

  final WriterDocumentController _controller;
  static const int maxSnapshots = 50;
  static const Duration debounce = Duration(milliseconds: 700);

  late final VoidCallback _listener;
  Timer? _timer;

  /// اللقطات المحفوظة (الأحدث في النهاية) — التراجع يتحرّك من الأخيرة.
  final List<String> _snapshots = <String>[];
  int _cursor = 0; // عدد اللقطات «المستقبَلة» من اليمين (ل癖ط بعد التراجع)

  bool _restoring = false;

  bool get canUndo => _cursor > 0;
  bool get canRedo => _cursor < _snapshots.length - 1;

  /// عدد الخطوات المتاحة في كل اتجاه (لوحة السجلّ).
  int get undoDepth => _cursor;
  int get redoDepth => _snapshots.length - 1 - _cursor;

  /// كل اللقطات (لعرض سجل التغييرات) ومؤشر اللقطة الحالية.
  List<String> get snapshots => List<String>.unmodifiable(_snapshots);
  int get cursor => _cursor;

  void _onControllerChanged() {
    if (_restoring) return;
    _timer?.cancel();
    _timer = Timer(debounce, () {
      final String encoded = jsonEncode(_controller.document.toJson());
      if (encoded == _snapshots[_cursor]) return;
      // قصّ الذيل المُعاد إدراجه بعد تراجع — التحرير الجديد يمحو مسالك الإعادة.
      if (_cursor < _snapshots.length - 1) {
        _snapshots.removeRange(_cursor + 1, _snapshots.length);
      }
      _snapshots.add(encoded);
      if (_snapshots.length > maxSnapshots) {
        _snapshots.removeAt(0);
      } else {
        _cursor++;
      }
      notifyListeners();
    });
  }

  void _snapshotNow(JoodWriterDocument document) {
    _snapshots.add(jsonEncode(document.toJson()));
    _cursor = 0;
  }

  /// التراجع خطوة واحدة — يُعيد المستند إلى لقطته السابقة.
  bool undo() {
    _timer?.cancel();
    if (!canUndo) return false;
    _cursor--;
    _restore(_snapshots[_cursor]);
    return true;
  }

  /// الإعادة خطوة واحدة.
  bool redo() {
    _timer?.cancel();
    if (!canRedo) return false;
    _cursor++;
    _restore(_snapshots[_cursor]);
    return true;
  }

  /// قفزة مباشرة إلى لقطة بعينها من لوحة السجلّ (فهرس من 0).
  bool jumpTo(int index) {
    _timer?.cancel();
    if (index < 0 || index >= _snapshots.length) return false;
    _cursor = index;
    _restore(_snapshots[index]);
    return true;
  }

  void _restore(String encoded) {
    _restoring = true;
    try {
      final Object? decoded = jsonDecode(encoded);
      if (decoded is Map<String, dynamic>) {
        _controller.loadDocument(JoodWriterDocument.fromJson(decoded));
      }
    } finally {
      _restoring = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.removeListener(_listener);
    super.dispose();
  }
}
