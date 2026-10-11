/// تنفيذ الويب: وسم `iframe` حقيقي لفيديو يوتيوب داخل شجرة الواجهة.
///
/// كل معرّف فيديو يُسجَّل **بنوع عرض خاص به** مرة واحدة (وإلا رمى المحرّك
/// استثناءً عند التسجيل ثانياً)، فتُبنى عدة فيديوهات في الصفحة جنباً إلى جنب
/// برابط تضمين مختلف لكل واحد.
library;

import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// بادئة نوع العرض — يُضاف إليه معرّف الفيديو.
const String _viewTypePrefix = 'jood-village-youtube-';

/// أنواع العرض المسجَّلة — التسجيل مرتين يرمي استثناءً في المحرّك.
final Set<String> _registered = <String>{};

Widget buildVideoEmbed({
  required String embedUrl,
  required String youtubeId,
}) {
  final String viewType = '$_viewTypePrefix$youtubeId';
  if (_registered.add(viewType)) {
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final web.HTMLIFrameElement iframe = web.HTMLIFrameElement()
        ..src = embedUrl;
      iframe.setAttribute(
        'style',
        'border:0;width:100%;height:100%;display:block;background:#000;',
      );
      iframe.setAttribute('title', 'فيديو القرية');
      iframe.setAttribute('loading', 'lazy');
      iframe.setAttribute('allowfullscreen', 'true');
      iframe.setAttribute(
        'allow',
        'accelerometer; autoplay; clipboard-write; encrypted-media; '
            'gyroscope; picture-in-picture; web-share',
      );
      return iframe;
    });
  }
  return HtmlElementView(viewType: viewType);
}
