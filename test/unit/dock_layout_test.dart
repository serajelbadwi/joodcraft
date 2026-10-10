import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/editor/dock/dock_layout.dart';

/// اختبارات منطق الإرساء: الالتقاط المغناطيسي، حفظ الحالة، وتوزيع الازدحام.
void main() {
  group('الالتقاط المغناطيسي', () {
    DockSnap? snapAt(
      double x,
      double y, {
      double threshold = 96,
    }) =>
        magneticDockSnap(
          x: x,
          y: y,
          width: 200,
          height: 300,
          viewportWidth: 1000,
          viewportHeight: 800,
          threshold: threshold,
        );

    test('قرب الحافة اليسرى يُلتقط إلى الشريط الجانبي', () {
      final DockSnap? snap = snapAt(0, 10);
      expect(snap, isNotNull);
      expect(snap!.slot, DockSlot.leftRail);
      expect(snap.edge, DockEdge.left);
      expect(snap.distance, 0);
    });

    test('قرب الحافة اليمنى يُلتقط إلى اللوحة الجانبية', () {
      final DockSnap? snap = snapAt(760, 300);
      expect(snap!.slot, DockSlot.inspector);
      expect(snap.edge, DockEdge.right);
      expect(snap.distance, 40);
    });

    test('قرب الحافة العليا يُلتقط إلى الشريط العلوي', () {
      final DockSnap? snap = snapAt(400, 20);
      expect(snap!.slot, DockSlot.topBar);
      expect(snap.edge, DockEdge.top);
      expect(snap.distance, 20);
    });

    test('قرب الحافة السفلى يعود إلى العوم', () {
      final DockSnap? snap = snapAt(400, 460);
      expect(snap!.slot, DockSlot.floating);
      expect(snap.edge, DockEdge.bottom);
    });

    test('وسط مساحة العمل لا يُلتقط (تبقى عائمة)', () {
      expect(snapAt(400, 200), isNull);
    });

    test('عتبة الالتقاط قابلة للضبط', () {
      expect(snapAt(400, 90, threshold: 60), isNull);
      expect(snapAt(400, 90, threshold: 120)!.slot, DockSlot.topBar);
    });

    test('كل حافة تقابل موضع إرساء', () {
      expect(dockSlotForEdge(DockEdge.top), DockSlot.topBar);
      expect(dockSlotForEdge(DockEdge.left), DockSlot.leftRail);
      expect(dockSlotForEdge(DockEdge.right), DockSlot.inspector);
      expect(dockSlotForEdge(DockEdge.bottom), DockSlot.floating);
    });
  });

  group('حالة اللوحة', () {
    test('الطيّ يتبدّل والحجم يُقيَّد بحدوده', () {
      const DockPanelState state = DockPanelState();
      expect(state.collapsed, isFalse);
      expect(state.toggled().collapsed, isTrue);

      expect(state.resizedBy(-1000).size, DockPanelState.minSize);
      expect(state.resizedBy(1000).size, DockPanelState.maxSize);
      expect(state.resizedBy(30).size, DockPanelState.defaultSize + 30);
    });

    test('الإزاحة تبقى داخل مساحة العمل', () {
      const DockPanelState state = DockPanelState(dx: 180, dy: 100);
      final DockPanelState moved = state.movedBy(
        50,
        50,
        viewportWidth: 300,
        viewportHeight: 200,
        panelWidth: 100,
        panelHeight: 50,
      );
      expect(moved.dx, 200);
      expect(moved.dy, 150);
    });

    test('التسلسل إلى JSON يعود بالحالة نفسها', () {
      const DockPanelState state = DockPanelState(
        slot: DockSlot.inspector,
        collapsed: true,
        size: 320,
        dx: 12,
        dy: 34,
      );
      expect(DockPanelState.fromJson(state.toJson()), state);
    });
  });

  group('تخطيط الإرساء', () {
    test('النقل يفتح اللوحة المطويّة', () {
      const DockLayout layout = DockLayout();
      expect(layout.stateOf(DockLayout.toolsPanel).slot, DockSlot.leftRail);
      expect(layout.stateOf('unknown').slot, DockSlot.leftRail);

      final DockLayout collapsed =
          layout.toggleCollapsed(DockLayout.toolsPanel);
      expect(collapsed.stateOf(DockLayout.toolsPanel).collapsed, isTrue);

      final DockLayout docked = collapsed.moveTo(
        DockLayout.toolsPanel,
        DockSlot.topBar,
      );
      expect(docked.stateOf(DockLayout.toolsPanel).slot, DockSlot.topBar);
      expect(docked.stateOf(DockLayout.toolsPanel).collapsed, isFalse);
    });

    test('دورة المواضع تعود إلى البداية', () {
      DockLayout layout = const DockLayout();
      for (int i = 0; i < DockSlot.values.length; i++) {
        layout = layout.moveTo(
          DockLayout.toolsPanel,
          layout.stateOf(DockLayout.toolsPanel).slot.next,
        );
      }
      expect(layout.stateOf(DockLayout.toolsPanel).slot, DockSlot.leftRail);
    });

    test('الإعادة للافتراضي تُصفّر كل شيء', () {
      DockLayout layout = const DockLayout()
          .moveTo(DockLayout.toolsPanel, DockSlot.floating)
          .resizeBy(DockLayout.toolsPanel, 80)
          .toggleCollapsed(DockLayout.toolsPanel);
      layout = layout.reset;
      expect(layout, const DockLayout());
      expect(layout.stateOf(DockLayout.toolsPanel).size,
          DockPanelState.defaultSize);
      expect(layout.stateOf(DockLayout.toolsPanel).slot, DockSlot.leftRail);
    });
  });

  group('توزيع ازدحام الشريط', () {
    test('يُخلي الأدنى أولوية ويحفظ ترتيب الباقي', () {
      final DockOverflowPlan plan = resolveDockOverflow(
        widths: <double>[100, 200, 300, 400],
        priorities: <int>[20, 10, 30, 40],
        available: 1000,
        overflowButtonWidth: 100,
      );
      expect(plan.visible, <int>[0, 2, 3]);
      expect(plan.hidden, <int>[1]);
      expect(plan.hasOverflow, isTrue);
    });

    test('ما يتّسع لا يُخفى منه شيء', () {
      final DockOverflowPlan plan = resolveDockOverflow(
        widths: <double>[100, 200],
        priorities: <int>[20, 10],
        available: 1000,
      );
      expect(plan.visible, <int>[0, 1]);
      expect(plan.hidden, isEmpty);
      expect(plan.hasOverflow, isFalse);
    });

    test('العنصر المثبّت لا يُخفى أبداً', () {
      final DockOverflowPlan plan = resolveDockOverflow(
        widths: <double>[500, 500, 500],
        priorities: <int>[pinnedDockPriority, 5, 5],
        available: 600,
        overflowButtonWidth: 100,
      );
      expect(plan.visible, <int>[0]);
      expect(plan.hidden, <int>[1, 2]);
    });

    test('عند التعادل في الأولوية يُخفى الأيمن أولاً', () {
      final DockOverflowPlan plan = resolveDockOverflow(
        widths: <double>[400, 400],
        priorities: <int>[10, 10],
        available: 500,
        overflowButtonWidth: 100,
      );
      expect(plan.visible, <int>[0]);
      expect(plan.hidden, <int>[1]);
    });

    test('لا يبقى أقل من حدّ العناصر الظاهرة', () {
      final DockOverflowPlan plan = resolveDockOverflow(
        widths: <double>[500, 500],
        priorities: <int>[1, 2],
        available: 10,
        minVisible: 2,
      );
      expect(plan.visible, <int>[0, 1]);
      expect(plan.hidden, isEmpty);
    });

    test('يُعيد الأدوات الصغيرة إن اتّسعت بعد إخلاء عنصر عريض', () {
      // العنصر العريض (400) يُخفى ليتّسع الشريط، ثم تتّسع الصغيرة (100).
      final DockOverflowPlan plan = resolveDockOverflow(
        widths: <double>[100, 400, 100],
        priorities: <int>[90, 50, 10],
        available: 500,
        overflowButtonWidth: 100,
      );
      expect(plan.visible, <int>[0, 2]);
      expect(plan.hidden, <int>[1]);
    });

    test('عرض شارة الدرج يُحسب في المساحة المتاحة', () {
      // 400 + شارة 100 + فاصل 8 = 508 > 500 ⇒ لا يتّسع إلا عنصر واحد.
      final DockOverflowPlan plan = resolveDockOverflow(
        widths: <double>[400, 400],
        priorities: <int>[10, 5],
        available: 500,
        overflowButtonWidth: 100,
      );
      expect(plan.visible, <int>[0]);
      expect(plan.hidden, <int>[1]);
    });
  });
}
