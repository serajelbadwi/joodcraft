import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/editor/dock/dock_controller.dart';
import 'package:joodcraft/core/editor/dock/dock_layout.dart';
import 'package:joodcraft/core/editor/widgets/dockable_toolbar.dart';
import 'package:joodcraft/core/theme/app_theme.dart';

/// اختبارات لوحة الأدوات القابلة للإرساء: الطيّ، الحجم، النقل من القائمة،
/// والسحب مع الالتقاط المغناطيسي ومؤشّره على الحافة المقصودة.
void main() {
  const String panelId = DockLayout.toolsPanel;

  late DockController dock;
  late GlobalKey viewportKey;

  setUp(() {
    dock = DockController();
    viewportKey = GlobalKey();
  });

  tearDown(() => dock.dispose());

  Widget host({bool withViewport = true}) => MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: Stack(
              key: withViewport ? viewportKey : null,
              children: <Widget>[
                Positioned(
                  left: dock.tools.dx,
                  top: dock.tools.dy,
                  child: DockableToolbar(
                    dock: dock,
                    panelId: panelId,
                    title: 'لوحة الأدوات',
                    icon: Icons.handyman_outlined,
                    viewportKey: withViewport ? viewportKey : null,
                    slotLabel: (DockSlot slot) => slot == DockSlot.topBar
                        ? 'الشريط العلوي'
                        : slot.jsonValue,
                    child: const SizedBox(
                      width: 44,
                      height: 120,
                      child: Text('أدوات'),
                    ),
                  ),
                ),
                // مؤشّر الالتقاط المغناطيسي (يُرسمه صاحب مساحة العمل).
                Positioned.fill(
                  child: IgnorePointer(
                    child: DockSnapIndicator(
                      dock: dock,
                      slotLabel: (DockSlot slot) => slot == DockSlot.topBar
                          ? 'الشريط العلوي'
                          : slot.jsonValue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  /// يضع اللوحة عائمة في الإحداثيات المطلوبة بلا تشغيل سحب حقيقي.
  void placeFloating(double x, double y) {
    dock.beginDrag();
    dock.updateDrag(
      id: panelId,
      x: x,
      y: y,
      width: 120,
      height: 120,
      viewportWidth: 800,
      viewportHeight: 600,
    );
    dock.cancelDrag();
  }

  Finder byKeyText(String key) => find.byKey(ValueKey<String>(key));

  testWidgets('الطيّ يُخفي الجسم ويُبقيه قابل الفتح', (WidgetTester tester) async {
    await tester.pumpWidget(host());

    expect(find.text('أدوات'), findsOneWidget);
    expect(byKeyText('dock-resize-editor-tools'), findsOneWidget);

    await tester.tap(byKeyText('dock-collapse-editor-tools'));
    await tester.pump();

    expect(dock.tools.collapsed, isTrue);
    expect(find.text('أدوات'), findsNothing);
    expect(byKeyText('dock-resize-editor-tools'), findsNothing);

    await tester.tap(byKeyText('dock-collapse-editor-tools'));
    await tester.pump();
    expect(dock.tools.collapsed, isFalse);
    expect(find.text('أدوات'), findsOneWidget);
  });

  testWidgets('سحب المقبض يغيّر حجم اللوحة داخل حدوده',
      (WidgetTester tester) async {
    await tester.pumpWidget(host());
    final double initial = dock.tools.size;

    await tester.drag(byKeyText('dock-resize-editor-tools'), const Offset(0, -60));
    await tester.pump();
    expect(dock.tools.size, lessThan(initial));
    expect(dock.tools.size, greaterThanOrEqualTo(DockPanelState.minSize));

    await tester.drag(byKeyText('dock-resize-editor-tools'), const Offset(0, 1000));
    await tester.pump();
    expect(dock.tools.size, DockPanelState.maxSize);
  });

  testWidgets('قائمة موضع الإرساء تنقل اللوحة إلى اللوحة الجانبية',
      (WidgetTester tester) async {
    await tester.pumpWidget(host());

    await tester.tap(byKeyText('dock-anchor-editor-tools'));
    await tester.pumpAndSettle();
    await tester.tap(byKeyText('dock-slot-inspector'));
    await tester.pumpAndSettle();

    expect(dock.tools.slot, DockSlot.inspector);
  });

  testWidgets('السحب قرب الحافة العليا يُظهر المؤشّر ويُرسي في الشريط العلوي',
      (WidgetTester tester) async {
    placeFloating(150, 100);
    await tester.pumpWidget(host());

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(byKeyText('dock-drag-editor-tools')),
    );
    // حركتان: الأولى تُفعّل السحب (تستهلك عتبة السحب) والثانية تُحدّث الموضع.
    await gesture.moveBy(const Offset(0, -40));
    await gesture.moveBy(const Offset(0, -60));
    await tester.pump();

    expect(dock.isDragging, isTrue);
    expect(dock.snapPreview?.slot, DockSlot.topBar);
    expect(byKeyText('dock-snap-indicator-top'), findsOneWidget);
    expect(find.text('الشريط العلوي'), findsWidgets);

    await gesture.up();
    await tester.pump();

    expect(dock.isDragging, isFalse);
    expect(dock.snapPreview, isNull);
    expect(dock.tools.slot, DockSlot.topBar);
    expect(byKeyText('dock-snap-indicator-top'), findsNothing);
  });

  testWidgets('الإفلات في وسط مساحة العمل يُبقي اللوحة عائمة',
      (WidgetTester tester) async {
    placeFloating(150, 100);
    await tester.pumpWidget(host());

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(byKeyText('dock-drag-editor-tools')),
    );
    await gesture.moveBy(const Offset(0, 20));
    await gesture.moveBy(const Offset(0, 40));
    await tester.pump();

    expect(dock.isDragging, isTrue);
    expect(dock.snapPreview, isNull);
    expect(byKeyText('dock-overflow-chip'), findsNothing);

    await gesture.up();
    await tester.pump();

    expect(dock.tools.slot, DockSlot.floating);
    expect(dock.snapPreview, isNull);
  });

  testWidgets('بلا مساحة عمل معروفة لا يُسحب الرأس (النقل من القائمة فقط)',
      (WidgetTester tester) async {
    dock.moveTo(panelId, DockSlot.floating);
    await tester.pumpWidget(host(withViewport: false));

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(byKeyText('dock-drag-editor-tools')),
    );
    await gesture.moveBy(const Offset(0, -120));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(dock.isDragging, isFalse);
    expect(dock.tools.slot, DockSlot.floating);
  });
}
