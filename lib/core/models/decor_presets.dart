import 'decoration.dart';

/// لوحة ألوان جاهزة للزخارف المتجهية.
///
/// اللوحات **بيانات لا كود**: كل واحدة ثلاثية ألوان (أساسي/ثانوي/لمسة) تُغذّى
/// إلى [DecorSpec]، فيغيّرها المستخدم بنقرة واحدة بدل اختيار ثلاثة ألوان يدوياً.
class DecorPalette {
  const DecorPalette({
    required this.id,
    required this.labelAr,
    required this.primaryHex,
    required this.secondaryHex,
    required this.accentHex,
  });

  final String id;
  final String labelAr;
  final String primaryHex;
  final String secondaryHex;
  final String accentHex;

  /// اللوحات الستّ المدعومة (هوية جودكرافت الذهبية أولاً).
  static const List<DecorPalette> all = <DecorPalette>[
    DecorPalette(
      id: 'royal_gold',
      labelAr: 'ذهبي ملكي',
      primaryHex: '#0D3B66',
      secondaryHex: '#C7A26B',
      accentHex: '#F4D58D',
    ),
    DecorPalette(
      id: 'royal_blue',
      labelAr: 'أزرق ملكي',
      primaryHex: '#0A2A5E',
      secondaryHex: '#2E6FB7',
      accentHex: '#9CC3E5',
    ),
    DecorPalette(
      id: 'emerald',
      labelAr: 'زمردي',
      primaryHex: '#0F5132',
      secondaryHex: '#2E8B57',
      accentHex: '#D4AF37',
    ),
    DecorPalette(
      id: 'burgundy',
      labelAr: 'عنابي',
      primaryHex: '#5B1E28',
      secondaryHex: '#A0333F',
      accentHex: '#E8C173',
    ),
    DecorPalette(
      id: 'midnight',
      labelAr: 'كحلي ليلي',
      primaryHex: '#111827',
      secondaryHex: '#374151',
      accentHex: '#C7A26B',
    ),
    DecorPalette(
      id: 'mono',
      labelAr: 'رمادي أحادي',
      primaryHex: '#1F2937',
      secondaryHex: '#9CA3AF',
      accentHex: '#E5E7EB',
    ),
  ];

  /// لوحة المعرّف المطلوب، أو لوحة جودكرافت الافتراضية.
  static DecorPalette byId(String id) => all.firstWhere(
        (DecorPalette palette) => palette.id == id,
        orElse: () => all.first,
      );

  /// مقارنة بالقيمة لا بالهوية: قوائم الاختيار في فلاتر تقارن العناصر بـ`==`،
  /// واللوحة قد تُبنى نسخة موقتة من ألوان المستخدم فتجب مساواتها بالمعرّف.
  @override
  bool operator ==(Object other) =>
      other is DecorPalette &&
      other.id == id &&
      other.primaryHex == primaryHex &&
      other.secondaryHex == secondaryHex &&
      other.accentHex == accentHex;

  @override
  int get hashCode => Object.hash(id, primaryHex, secondaryHex, accentHex);
}

/// وصفة زخرفة جاهزة: نوع + لوحة ألوان + طبقات.
///
/// المعرض يبنى من **جداء** الأنواع واللوحات (5 × 6 = 30 وصفة) بلا تكرار يدوي،
/// فأي نوع أو لوحة جديدة تُضاف إلى المصدرين تظهر في المعرض تلقائياً.
class DecorPreset {
  const DecorPreset({
    required this.id,
    required this.labelAr,
    required this.spec,
  });

  final String id;
  final String labelAr;
  final DecorSpec spec;

  /// كل الوصفات الجاهزة (نوع × لوحة).
  static final List<DecorPreset> all = <DecorPreset>[
    for (final DecorPalette palette in DecorPalette.all)
      for (final DecorKind kind in DecorKind.values)
        DecorPreset(
          id: '${kind.name}_${palette.id}',
          labelAr: '${kind.labelAr} — ${palette.labelAr}',
          spec: DecorSpec(
            kind: kind,
            primaryHex: palette.primaryHex,
            secondaryHex: palette.secondaryHex,
            accentHex: palette.accentHex,
            // الغيوش نقشة واحدة متكرّرة، فطبقات متعددة تُثقله بلا فائدة.
            layers: kind == DecorKind.guilloche ? 1 : 3,
            thickness: 2,
            seed: 7,
          ),
        ),
  ];

  /// وصفات نوع واحد فقط (لتصفية المعرض حسب النوع المختار).
  static List<DecorPreset> forKind(DecorKind kind) =>
      all.where((DecorPreset preset) => preset.spec.kind == kind).toList(
            growable: false,
          );
}
