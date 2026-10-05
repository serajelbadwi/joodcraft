import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/editor/widgets/font_selector.dart';

/// اختبارات منتقي الخطوط الموحّد: التجميع المعنون، البحث الفوري، حالة عدم
/// المطابقة، وإعادة الخيار المختار.
void main() {
  const List<FontSelectorGroup> groups = <FontSelectorGroup>[
    FontSelectorGroup(
      title: 'مضمّن',
      items: <FontSelectorItem>[
        FontSelectorItem(id: 'builtin:cairo', label: 'Cairo'),
        FontSelectorItem(id: 'builtin:amiri', label: 'Amiri'),
      ],
    ),
    FontSelectorGroup(
      title: 'مرفوع',
      items: <FontSelectorItem>[
        FontSelectorItem(id: 'JoodCustom:My Font', label: 'My Font'),
      ],
    ),
    FontSelectorGroup(
      title: 'نظام',
      items: <FontSelectorItem>[
        FontSelectorItem(id: 'Arial', label: 'Arial'),
        FontSelectorItem(id: 'Tahoma', label: 'Tahoma'),
        FontSelectorItem(id: 'Consolas', label: 'Consolas'),
      ],
    ),
  ];

  Future<void> openDialog(WidgetTester tester) async {
    await tester.pumpWidget(const _Harness(groups));
    await tester.tap(find.text('فتح المنتقي'));
    await tester.pumpAndSettle();
  }

  testWidgets('يعرض المجموعات الثلاث بعنوانها وعدد خطوطها', (
    WidgetTester tester,
  ) async {
    await openDialog(tester);

    expect(find.text('مضمّن · 2'), findsOneWidget);
    expect(find.text('مرفوع · 1'), findsOneWidget);
    expect(find.text('نظام · 3'), findsOneWidget);
    expect(find.text('Cairo'), findsOneWidget);
    expect(find.text('My Font'), findsOneWidget);
    expect(find.text('Consolas'), findsOneWidget);
  });

  testWidgets('البحث الفوري يرشّح الخطوط ويُسقط المجموعة الفارغة', (
    WidgetTester tester,
  ) async {
    await openDialog(tester);

    await tester.enterText(find.byType(TextField), 'ta');
    await tester.pumpAndSettle();

    // «Tahoma» وحدها تطابق، فتبقى مجموعة النظام بقائمة واحدة.
    expect(find.text('Tahoma'), findsOneWidget);
    expect(find.text('نظام · 1'), findsOneWidget);
    // مجموعتا المضمّن والمرفوع صارتا فارغتين فأُسقطتا.
    expect(find.text('مضمّن · 2'), findsNothing);
    expect(find.text('مرفوع · 1'), findsNothing);
    expect(find.text('Arial'), findsNothing);
  });

  testWidgets('يبحث دون حساسية لحالة الأحرف', (WidgetTester tester) async {
    await openDialog(tester);

    await tester.enterText(find.byType(TextField), 'CONSOLAS');
    await tester.pumpAndSettle();

    expect(find.text('Consolas'), findsOneWidget);
  });

  testWidgets('يعرض رسالة عدم المطابقة عند غياب أي خط', (
    WidgetTester tester,
  ) async {
    await openDialog(tester);

    await tester.enterText(find.byType(TextField), 'لا يوجد خط كهذا');
    await tester.pumpAndSettle();

    expect(find.text('لا توجد خطوط مطابقة.'), findsOneWidget);
    expect(find.text('Cairo'), findsNothing);
  });

  testWidgets('يعيد الخيار المختار إلى المستدعي', (WidgetTester tester) async {
    await openDialog(tester);

    await tester.tap(find.byKey(const ValueKey<String>('font-option-Arial')));
    await tester.pumpAndSettle();

    expect(find.text('اخترت:Arial'), findsOneWidget);
  });

  testWidgets('يُعلّم الخيار المختار حالياً', (WidgetTester tester) async {
    // مجموعتان صغيرتان تضمنان ظهور العنصرين كليهما داخل نافذة الحوار.
    const List<FontSelectorGroup> small = <FontSelectorGroup>[
      FontSelectorGroup(
        title: 'مضمّن',
        items: <FontSelectorItem>[
          FontSelectorItem(id: 'builtin:cairo', label: 'Cairo'),
          FontSelectorItem(id: 'builtin:amiri', label: 'Amiri'),
        ],
      ),
    ];
    await tester.pumpWidget(
      const _Harness(small, selectedId: 'builtin:cairo'),
    );
    await tester.tap(find.text('فتح المنتقي'));
    await tester.pumpAndSettle();

    final ListTile selectedTile = tester.widget<ListTile>(
      find.byKey(const ValueKey<String>('font-option-builtin:cairo')),
    );
    final ListTile otherTile = tester.widget<ListTile>(
      find.byKey(const ValueKey<String>('font-option-builtin:amiri')),
    );
    expect(selectedTile.selected, isTrue);
    expect(otherTile.selected, isFalse);
  });
}

class _Harness extends StatefulWidget {
  const _Harness(this.groups, {this.selectedId});

  final List<FontSelectorGroup> groups;
  final String? selectedId;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  FontSelectorItem? _picked;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          // Builder ليحمل سياقاً أسفل MaterialApp (فيه Navigator وترجمات المواد).
          body: Builder(
            builder: (BuildContext inner) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ElevatedButton(
                    onPressed: () async {
                      final FontSelectorItem? item =
                          await showFontSelectorDialog(
                        inner,
                        groups: widget.groups,
                        title: 'الخط',
                        searchHint: 'ابحث في الخطوط…',
                        noMatchText: 'لا توجد خطوط مطابقة.',
                        selectedId: widget.selectedId,
                      );
                      if (!mounted) return;
                      setState(() => _picked = item);
                    },
                    child: const Text('فتح المنتقي'),
                  ),
                  if (_picked != null)
                    Text('اخترت:${_picked!.id}',
                        textDirection: TextDirection.ltr),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
