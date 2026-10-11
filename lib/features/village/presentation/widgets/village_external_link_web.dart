/// تنفيذ الويب: إنشاء وسم `<a>` والضغط عليه — بلا نوافذ منبثقة مُحجوبة.
library;

import 'package:web/web.dart' as web;

bool openInNewTab(String url) {
  final String target = url.trim();
  if (target.isEmpty) return false;
  try {
    web.HTMLAnchorElement()
      ..href = target
      ..target = '_blank'
      ..rel = 'noopener noreferrer'
      ..click();
    return true;
  } catch (_) {
    return false;
  }
}
