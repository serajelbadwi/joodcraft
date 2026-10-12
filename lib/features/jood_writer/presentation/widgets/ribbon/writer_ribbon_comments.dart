/// تعليقات المستند في «جود كاتب» — مخزن مستقلّ يُثبّت كل تعليق على فهرس
/// كتلة ويحفظه في `SharedPreferences` تحت مفتاح خاص بالمستند.
///
/// التعليق ليس جزءاً من نموذج المستند (كي لا يُقص من صفحات العرض/الطباعة)
///؛ هو طبقة مراجعة تُقرأ وتُدار من تبويب «المراجعة» فقط.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WriterComment {
  const WriterComment({
    required this.id,
    required this.blockIndex,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final int blockIndex;
  final String text;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'block': blockIndex,
    'text': text,
    'at': createdAt.toIso8601String(),
  };

  static WriterComment fromJson(Map<String, dynamic> json) => WriterComment(
    id: '${json['id'] ?? ''}',
    blockIndex: json['block'] as int? ?? 0,
    text: '${json['text'] ?? ''}',
    createdAt: DateTime.tryParse('${json['at'] ?? ''}') ?? DateTime.now(),
  );
}

class WriterCommentsStore extends ChangeNotifier {
  WriterCommentsStore(this._documentId);

  final String _documentId;

  /// كل التعليقات مرتّبة بحسب الكتلة ثم التاريخ.
  final List<WriterComment> _comments = <WriterComment>[];

  bool _loaded = false;

  List<WriterComment> get comments => List<WriterComment>.unmodifiable(_comments);

  int get length => _comments.length;

  /// تعليقات كتلة بعينها (لكتابة الشارات بجانبها في الاختبارات).
  List<WriterComment> forBlock(int blockIndex) => _comments
      .where((WriterComment c) => c.blockIndex == blockIndex)
      .toList();

  String get _prefsKey => 'jood_writer_comments_$_documentId';

  /// تحميل محفوظات المستند (مرة واحدة — وبلا فشل يُسقط الواجهة).
  Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List) return;
      _comments
        ..clear()
        ..addAll(
          decoded
              .whereType<Map>()
              .map((Object? e) => WriterComment.fromJson(Map<String, dynamic>.from(e as Map))),
        );
      notifyListeners();
    } catch (_) {
      // ملف تعليقات تالف: نبدأ صفاً جديداً بدل إسقاط الشاشة.
    }
  }

  Future<void> add({required int blockIndex, required String text}) async {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _comments.add(
      WriterComment(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        blockIndex: blockIndex,
        text: trimmed,
        createdAt: DateTime.now(),
      ),
    );
    _comments.sort((WriterComment a, WriterComment b) => a.blockIndex.compareTo(b.blockIndex));
    notifyListeners();
    await _persist();
  }

  Future<void> remove(String id) async {
    _comments.removeWhere((WriterComment c) => c.id == id);
    notifyListeners();
    await _persist();
  }

  Future<void> clearAll() async {
    _comments.clear();
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsKey,
        jsonEncode(<dynamic>[for (final WriterComment c in _comments) c.toJson()]),
      );
    } catch (_) {
      // غياب التخزين (ويب بلا إعدادات) لا يُسقط الإضافة في الذاكرة.
    }
  }
}
