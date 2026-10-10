/// متحكّم الإرساء: يحفظ تخطيط اللوحات ويقود السحب والالتقاط المغناطيسي.
library;

import 'package:flutter/foundation.dart';

import 'dock_layout.dart';

/// حالة الإرساء الحيّة داخل المحرّر (بدون حفظ دائم — تُعاد للافتراضي كل فتح).
///
/// يفصل هذا المتحكّم «المنطق» (في [DockLayout]) عن الواجهة، فيبقى قابلاً
/// للاختبار مباشرةً بلا بناء شجرة ودجات.
class DockController extends ChangeNotifier {
  DockLayout _layout = const DockLayout();
  DockSnap? _snap;
  bool _dragging = false;

  DockLayout get layout => _layout;

  /// مؤشّر الالتقاط الحالي أثناء السحب (أو `null` إن لم تقترب اللوحة من حافة).
  DockSnap? get snapPreview => _snap;

  bool get isDragging => _dragging;

  DockPanelState stateOf(String id) => _layout.stateOf(id);

  /// حالة لوحة أدوات المحرّر.
  DockPanelState get tools => _layout.stateOf(DockLayout.toolsPanel);

  /// نقل لوحة إلى موضع إرساء.
  void moveTo(String id, DockSlot slot) {
    final DockLayout next = _layout.moveTo(id, slot);
    if (next == _layout) return;
    _layout = next;
    notifyListeners();
  }

  /// تدوير مواضع اللوحة (زرّ النقل السريع).
  void cycleSlot(String id) => moveTo(id, stateOf(id).slot.next);

  /// طيّ اللوحة/فتحها.
  void toggleCollapsed(String id) {
    _layout = _layout.toggleCollapsed(id);
    notifyListeners();
  }

  /// تغيير حجم جسم اللوحة بمقدار [delta] بكسل.
  void resizeBy(String id, double delta) {
    final DockLayout next = _layout.resizeBy(id, delta);
    if (next == _layout) return;
    _layout = next;
    notifyListeners();
  }

  /// العودة إلى التخطيط الافتراضي (شريط جانبي عائم موسّع).
  void reset() {
    _layout = _layout.reset;
    _snap = null;
    _dragging = false;
    notifyListeners();
  }

  /// بدء سحب اللوحة.
  void beginDrag() {
    _dragging = true;
    _snap = null;
    notifyListeners();
  }

  /// تحديث موضع اللوحة أثناء السحب وحساب الالتقاط المغناطيسي.
  ///
  /// [x]/[y] موضع اللوحة داخل مساحة العمل، و[viewportWidth]/[viewportHeight]
  /// أبعاد مساحة العمل — فيُحدَّد أقرب حدّ للإفلات.
  void updateDrag({
    required String id,
    required double x,
    required double y,
    required double width,
    required double height,
    required double viewportWidth,
    required double viewportHeight,
    double threshold = 96,
  }) {
    final DockPanelState current = stateOf(id);
    _layout = _layout.withPanel(
      id,
      current.copyWith(slot: DockSlot.floating, dx: x, dy: y),
    );
    _snap = magneticDockSnap(
      x: x,
      y: y,
      width: width,
      height: height,
      viewportWidth: viewportWidth,
      viewportHeight: viewportHeight,
      threshold: threshold,
    );
    notifyListeners();
  }

  /// إفلات اللوحة: تُرسى في الموضع المغناطيسي إن وُجد، وإلا تبقى عائمة.
  void commitDrag(String id) {
    final DockSnap? snap = _snap;
    _dragging = false;
    _snap = null;
    if (snap != null) {
      _layout = _layout.moveTo(id, snap.slot);
      if (snap.slot.isDocked) {
        _layout = _layout.withPanel(
          id,
          _layout.stateOf(id).copyWith(dx: 0, dy: 0),
        );
      }
    }
    notifyListeners();
  }

  /// إلغاء السحب بلا تغيير الموضع (مثل خروج المؤشر من النافذة).
  void cancelDrag() {
    if (!_dragging && _snap == null) return;
    _dragging = false;
    _snap = null;
    notifyListeners();
  }
}
