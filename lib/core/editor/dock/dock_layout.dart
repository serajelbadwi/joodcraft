/// منطق **الإرساء والالتقاط المغناطيسي** — نقيّ بلا أي اعتماد على فلاتر.
///
/// يفصل هذا الملف «أين تقف اللوحة» عن «كيف تُرسم»: اللوحة العائمة تُسحب، وتقترب
/// من حافة فتُظهر مؤشّر التقاط، وتُفلت فتُرسى في الشريط العلوي أو الشريط الجانبي
/// أو اللوحة الجانبية. ويُحسب أيضاً ما يتّسع في الشريط العلوي فعلاً (بلا اقتطاع)
/// وما يجب إخلاؤه إلى درج «أدوات أخرى» في اللوحة الجانبية.
library;

import 'dart:math' as math;

/// حافة مساحة العمل التي تُلتقط إليها اللوحة مغناطيسياً.
enum DockEdge { top, left, right, bottom }

/// موضع إرساء لوحة الأدوات.
enum DockSlot {
  /// شريط رأسي رفيع عائم على يسار اللوحة (الموضع الافتراضي).
  leftRail('left'),

  /// مدمجة في الشريط العلوي (الصف السياقي).
  topBar('top'),

  /// أعلى اللوحة الجانبية اليمنى.
  inspector('inspector'),

  /// عائمة حرّة تُسحب بالماوس.
  floating('floating');

  const DockSlot(this.jsonValue);

  final String jsonValue;

  /// هل اللوحة مثبّتة في موضع (غير عائمة)؟
  bool get isDocked => this != DockSlot.floating;

  /// الحافة التي يقابلها هذا الموضع — تُستخدم لرسم مؤشّر الالتقاط.
  DockEdge get edge => switch (this) {
        DockSlot.topBar => DockEdge.top,
        DockSlot.leftRail => DockEdge.left,
        DockSlot.inspector => DockEdge.right,
        DockSlot.floating => DockEdge.bottom,
      };

  /// الموضع التالي في دورة المواضع (زر «نقل» السريع).
  DockSlot get next => DockSlot.values[(index + 1) % DockSlot.values.length];

  static DockSlot fromJson(Object? value) {
    final String needle = '${value ?? ''}'.trim().toLowerCase();
    for (final DockSlot slot in DockSlot.values) {
      if (slot.jsonValue == needle || slot.name.toLowerCase() == needle) {
        return slot;
      }
    }
    return DockSlot.leftRail;
  }
}

/// الموضع المقابل لحافة إفلات.
DockSlot dockSlotForEdge(DockEdge edge) => switch (edge) {
      DockEdge.top => DockSlot.topBar,
      DockEdge.left => DockSlot.leftRail,
      DockEdge.right => DockSlot.inspector,
      DockEdge.bottom => DockSlot.floating,
    };

/// حالة لوحة واحدة: موضعها وطيّها وحجمها وإزاحتها إن كانت عائمة.
final class DockPanelState {
  const DockPanelState({
    this.slot = DockSlot.leftRail,
    this.collapsed = false,
    this.size = defaultSize,
    this.dx = 0,
    this.dy = 0,
  });

  /// الحجم الافتراضي للجسم القابل للسحب (بكسل).
  static const double defaultSize = 260;
  static const double minSize = 120;
  static const double maxSize = 560;

  final DockSlot slot;
  final bool collapsed;

  /// الطول الأقصى لجسم اللوحة (ارتفاع للشريط الرأسي، عرض للأفقي).
  final double size;

  /// إزاحة اللوحة العائمة داخل مساحة العمل.
  final double dx;
  final double dy;

  bool get isFloating => slot == DockSlot.floating;

  DockPanelState copyWith({
    DockSlot? slot,
    bool? collapsed,
    double? size,
    double? dx,
    double? dy,
  }) =>
      DockPanelState(
        slot: slot ?? this.slot,
        collapsed: collapsed ?? this.collapsed,
        size: size ?? this.size,
        dx: dx ?? this.dx,
        dy: dy ?? this.dy,
      );

  /// طيّ/فتح اللوحة.
  DockPanelState toggled() => copyWith(collapsed: !collapsed);

  /// تغيير الحجم بمقدار [delta] بكسل مع البقاء داخل الحدود المسموحة.
  DockPanelState resizedBy(double delta) =>
      copyWith(size: (size + delta).clamp(minSize, maxSize).toDouble());

  /// إزاحة اللوحة العائمة مع إبقائها داخل مساحة العمل.
  DockPanelState movedBy(
    double deltaX,
    double deltaY, {
    double viewportWidth = double.infinity,
    double viewportHeight = double.infinity,
    double panelWidth = 0,
    double panelHeight = 0,
  }) {
    final double maxX = math.max(0, viewportWidth - panelWidth);
    final double maxY = math.max(0, viewportHeight - panelHeight);
    return copyWith(
      dx: (dx + deltaX).clamp(0, maxX).toDouble(),
      dy: (dy + deltaY).clamp(0, maxY).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'slot': slot.jsonValue,
        if (collapsed) 'collapsed': true,
        'size': size,
        if (dx != 0) 'dx': dx,
        if (dy != 0) 'dy': dy,
      };

  static DockPanelState fromJson(Object? value) {
    if (value is! Map) return const DockPanelState();
    double num_(String key, double fallback) {
      final Object? raw = value[key];
      if (raw is num) return raw.toDouble();
      if (raw is String) return double.tryParse(raw) ?? fallback;
      return fallback;
    }

    return DockPanelState(
      slot: DockSlot.fromJson(value['slot']),
      collapsed: value['collapsed'] == true,
      size: num_('size', defaultSize).clamp(minSize, maxSize).toDouble(),
      dx: num_('dx', 0),
      dy: num_('dy', 0),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DockPanelState &&
      other.slot == slot &&
      other.collapsed == collapsed &&
      other.size == size &&
      other.dx == dx &&
      other.dy == dy;

  @override
  int get hashCode => Object.hash(slot, collapsed, size, dx, dy);
}

/// تخطيط الإرساء: حالة كل لوحة بمفتاحها.
final class DockLayout {
  const DockLayout({this.panels = const <String, DockPanelState>{}});

  /// مفتاح لوحة أدوات المحرّر (الشريط الرفيع).
  static const String toolsPanel = 'editor-tools';

  final Map<String, DockPanelState> panels;

  DockPanelState stateOf(String id) =>
      panels[id] ?? const DockPanelState(slot: DockSlot.leftRail);

  DockLayout withPanel(String id, DockPanelState state) =>
      DockLayout(panels: <String, DockPanelState>{...panels, id: state});

  /// نقل لوحة إلى موضع إرساء (تُفتح إن كانت مطويّة).
  DockLayout moveTo(String id, DockSlot slot) => withPanel(
        id,
        stateOf(id).copyWith(slot: slot, collapsed: false),
      );

  DockLayout toggleCollapsed(String id) =>
      withPanel(id, stateOf(id).toggled());

  DockLayout resizeBy(String id, double delta) =>
      withPanel(id, stateOf(id).resizedBy(delta));

  DockLayout moveBy(
    String id,
    double deltaX,
    double deltaY, {
    double viewportWidth = double.infinity,
    double viewportHeight = double.infinity,
    double panelWidth = 0,
    double panelHeight = 0,
  }) =>
      withPanel(
        id,
        stateOf(id).movedBy(
          deltaX,
          deltaY,
          viewportWidth: viewportWidth,
          viewportHeight: viewportHeight,
          panelWidth: panelWidth,
          panelHeight: panelHeight,
        ),
      );

  /// العودة إلى التخطيط الافتراضي (شريط جانبي عائم موسّع).
  DockLayout get reset => const DockLayout();

  @override
  bool operator ==(Object other) =>
      other is DockLayout && _samePanels(other.panels, panels);

  @override
  int get hashCode => Object.hashAll(
        panels.entries.map((MapEntry<String, DockPanelState> e) => e.key),
      );

  static bool _samePanels(
    Map<String, DockPanelState> a,
    Map<String, DockPanelState> b,
  ) {
    if (a.length != b.length) return false;
    for (final MapEntry<String, DockPanelState> entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}

/// نتيجة الالتقاط المغناطيسي: الموضع المقصود وحدّ الإفلات والمسافة.
final class DockSnap {
  const DockSnap({
    required this.slot,
    required this.edge,
    required this.distance,
  });

  final DockSlot slot;
  final DockEdge edge;
  final double distance;
}

/// أقرب حافة تُلتقط إليها اللوحة إن كانت المسافة أقل من [threshold].
///
/// تُقارن المسافة من مستطيل اللوحة [rect]-style (بالإحداثيات المُمرَّرة) إلى
/// الحواف الأربع لمساحة العمل، ويُرجَع [DockSnap] لأقربها أو `null` إن كانت
/// اللوحة في وسط المساحة (تبقى عائمة).
DockSnap? magneticDockSnap({
  required double x,
  required double y,
  required double width,
  required double height,
  required double viewportWidth,
  required double viewportHeight,
  double threshold = 96,
}) {
  final List<DockSnap> candidates = <DockSnap>[
    DockSnap(slot: DockSlot.topBar, edge: DockEdge.top, distance: y),
    DockSnap(slot: DockSlot.leftRail, edge: DockEdge.left, distance: x),
    DockSnap(
      slot: DockSlot.inspector,
      edge: DockEdge.right,
      distance: viewportWidth - (x + width),
    ),
    DockSnap(
      slot: DockSlot.floating,
      edge: DockEdge.bottom,
      distance: viewportHeight - (y + height),
    ),
  ];
  candidates.sort((DockSnap a, DockSnap b) => a.distance.compareTo(b.distance));
  final DockSnap best = candidates.first;
  return best.distance <= threshold ? best : null;
}

/// خطة توزيع عناصر الشريط العلوي: ما يُعرض وما يُخلى للدرج.
final class DockOverflowPlan {
  const DockOverflowPlan({required this.visible, required this.hidden});

  /// فهارس العناصر المعروضة (بترتيبها الأصلي).
  final List<int> visible;

  /// فهارس العناصر المُخلاة إلى درج «أدوات أخرى» (بترتيبها الأصلي).
  final List<int> hidden;

  bool get hasOverflow => hidden.isNotEmpty;
}

/// أولوية العناصر المثبّتة: لا تُخفى أبداً.
const int pinnedDockPriority = 1 << 20;

/// يحسب ما يتّسع فعلاً في شريط بعرض [available].
///
/// * [widths] عرض كل عنصر (يُقاس فعلياً من الشاشة).
/// * [priorities] أولوية كل عنصر — الأعلى يبقى أطول ما يمكن.
/// * [overflowButtonWidth] عرض زرّ الدرج الذي يظهر فور إخلاء أي عنصر.
/// * [minVisible] أقل عدد عناصر تبقى معروضة (واحد على الأقل).
///
/// الخوارزمية طريق مسدود مُبكّر: نخفي دائماً العنصر **الأدنى أولوية** (وعند
/// التعادل الأيمن) حتى يتّسع الباقي، فلا تُقتطع أي أداة أبداً.
///
/// ثم خطوة **إعادة إضافة**: حين يكون العنصر المُخلى عريضاً يتّسع الشريط بعد ذلك
/// لعناصر صغيرة كانت قد أُخليت قبله، فنُعيدها بالترتيب نفسه (الأولوية الأعلى
/// أولاً) — فيبقى الشريط ممتلئاً بأكبر عدد ممكن من الأدوات بدل فراغ كبير.
DockOverflowPlan resolveDockOverflow({
  required List<double> widths,
  required List<int> priorities,
  required double available,
  double spacing = 8,
  double overflowButtonWidth = 44,
  int minVisible = 1,
}) {
  assert(widths.length == priorities.length);
  final int count = math.min(widths.length, priorities.length);
  final List<int> visible = <int>[for (int i = 0; i < count; i++) i];
  final Set<int> hidden = <int>{};

  double usedWidth() {
    if (visible.isEmpty) return 0;
    final double items = visible.fold<double>(0, (double sum, int i) => sum + widths[i]);
    final double gaps = spacing * (visible.length - 1);
    final double drawer = hidden.isEmpty ? 0 : overflowButtonWidth + spacing;
    return items + gaps + drawer;
  }

  while (visible.length > minVisible && usedWidth() > available) {
    int victim = -1;
    int victimPriority = 1 << 30;
    for (final int index in visible) {
      // المثبّت (مثل عنوان القالب) لا يُخفى أبداً.
      if (priorities[index] >= pinnedDockPriority) continue;
      final int priority = priorities[index];
      if (priority < victimPriority ||
          (priority == victimPriority && index > victim)) {
        victim = index;
        victimPriority = priority;
      }
    }
    if (victim == -1) break;
    visible.remove(victim);
    hidden.add(victim);
  }

  // إعادة الإضافة: أحياناً يُخلى عنصر عريض فتتّسع المساحة لعناصر صغيرة سبق
  // إخلاؤها، وتبقى مخفية بلا داعٍ (فراغ ظاهر في الشريط). نجرّب إعادتها من
  // الأعلى أولوية إلى الأدنى، ونُبقي ما يتّسع فعلاً — مع احتساب شارة الفيض
  // لأنها تختفي تماماً حين لا يبقى شيء مُخلى.
  final List<int> candidates = hidden.toList()
    ..sort((int a, int b) {
      final int byPriority = priorities[b].compareTo(priorities[a]);
      return byPriority != 0 ? byPriority : a.compareTo(b);
    });
  for (final int index in candidates) {
    if (priorities[index] >= pinnedDockPriority) continue;
    visible.add(index);
    hidden.remove(index);
    if (usedWidth() <= available) continue;
    visible.remove(index);
    hidden.add(index);
  }

  return DockOverflowPlan(
    visible: visible..sort(),
    hidden: hidden.toList()..sort(),
  );
}
