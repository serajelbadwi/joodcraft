import 'dart:io';

/// يبحث عن [fileName] في مجلد التشغيل وأسلافه ثم بجانب الملف التنفيذي.
///
/// أثناء `flutter run` يكون `Directory.current` جذر المشروع، فتُقرأ أحدث نسخة
/// من `env.json` دون إعادة بناء. وفي نسخة الإنتاج يشمل البحث مجلد الملف
/// التنفيذي وأسلافه، فإن وُضع `env.json` بجانب التطبيق وُجد (وإلا يغطّي
/// الأصل المحزوم).
Future<String?> readEnvFile(String fileName) async {
  for (final String dir in _candidateDirectories()) {
    final File file = File(_join(dir, fileName));
    try {
      if (await file.exists()) return await file.readAsString();
    } on Object {
      // ملف غير قابل للقراءة (أذونات مرفوضة أو مسار غير صالح) — التالي.
    }
  }
  return null;
}

/// مجلدات البحث بترتيب الأسبقية، بلا تكرار وبنهاية مضمونة.
Iterable<String> _candidateDirectories() sync* {
  final Set<String> seen = <String>{};

  Directory? current = Directory.current;
  for (int i = 0; i < 6 && current != null; i++) {
    final String path = current.path;
    if (seen.add(path)) yield path;
    final Directory parent = current.parent;
    current = parent.path == path ? null : parent;
  }

  try {
    Directory? executable = File(Platform.resolvedExecutable).parent;
    for (int i = 0; i < 4 && executable != null; i++) {
      final String path = executable.path;
      if (seen.add(path)) yield path;
      final Directory parent = executable.parent;
      executable = parent.path == path ? null : parent;
    }
  } on Object {
    // بعض المنصات لا تسمح بمعرفة مسار التنفيذ — البحث السابق يكفي.
  }
}

String _join(String directory, String fileName) =>
    directory.endsWith(Platform.pathSeparator)
        ? '$directory$fileName'
        : '$directory${Platform.pathSeparator}$fileName';
