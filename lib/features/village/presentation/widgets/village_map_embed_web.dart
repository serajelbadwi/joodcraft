/// تنفيذ الويب: وسم `iframe` حقيقي لخريطة جوجل داخل شجرة الواجهة.
library;

import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// نوع العرض — يُسجَّل **مرة واحدة** (تسجيله مرتين يرمي استثناءً في المحرّك).
const String _viewType = 'jood-village-google-map';

bool _registered = false;

Widget buildMapEmbed({
  required String iframeUrl,
  required String query,
  required double height,
}) {
  if (!_registered) {
    _registered = true;
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final web.HTMLIFrameElement iframe = web.HTMLIFrameElement()
        ..src = iframeUrl
        ..title = 'خريطة القرية';
      iframe.setAttribute(
        'style',
        'border:0;width:100%;height:100%;display:block;background:#3D3D3D;',
      );
      iframe.setAttribute('loading', 'lazy');
      iframe.setAttribute('allowfullscreen', 'true');
      iframe.setAttribute('referrerpolicy', 'no-referrer-when-downgrade');
      return iframe;
    });
  }
  return const HtmlElementView(viewType: _viewType);
}
