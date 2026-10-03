/// مكتبة الحقول الديناميكية المتاحة في المستندات العربية.
///
/// كل حقل يُكتب في النص بصيغة `{{المفتاح}}`، ويُستبدل عند التوليد بقيمة العمود
/// المطابق من ملف Excel (المرحلة 4) أو بالبيانات التجريبية في المعاينة.
abstract final class DynamicFields {
  const DynamicFields._();

  /// القوالب الجاهزة للشهادات.
  static const List<DynamicField> certificate = <DynamicField>[
    DynamicField(key: 'اسم_المتدرب', sample: 'محمد بن عبد الله الشمري'),
    DynamicField(key: 'اسم_الدورة', sample: 'إدارة المشاريع الاحترافية'),
    DynamicField(key: 'رقم_الشهادة', sample: 'JC-2026-000145'),
    DynamicField(key: 'التاريخ', sample: '1447/03/12 هـ'),
    DynamicField(key: 'الجهة_المانحة', sample: 'الأكاديمية السعودية للتدريب'),
    DynamicField(key: 'المدرب', sample: 'د. سارة العتيبي'),
    DynamicField(key: 'مدة_الدورة', sample: '40 ساعة تدريبية'),
    DynamicField(key: 'مستوى_الأداء', sample: 'ممتاز'),
    DynamicField(key: 'رابط_التحقق', sample: 'https://joodcraft.app/v/JC-2026-000145'),
  ];

  /// القوالب الجاهزة للعقود.
  static const List<DynamicField> contract = <DynamicField>[
    DynamicField(key: 'اسم_الطرف_الأول', sample: 'شركة جود للتجارة'),
    DynamicField(key: 'اسم_الطرف_الثاني', sample: 'مؤسسة الأفق للمقاولات'),
    DynamicField(key: 'رقم_العقد', sample: 'JC-C-2026-0044'),
    DynamicField(key: 'تاريخ_العقد', sample: '1447/03/12 هـ'),
    DynamicField(key: 'تاريخ_البداية', sample: '1447/04/01 هـ'),
    DynamicField(key: 'تاريخ_النهاية', sample: '1447/10/01 هـ'),
    DynamicField(key: 'قيمة_العقد', sample: '150000 ريال سعودي'),
    DynamicField(key: 'طريقة_الدفع', sample: 'دفعة مقدمة 40% والباقي عند التسليم'),
    DynamicField(key: 'اسم_المنشأة', sample: 'جودكرافت'),
  ];

  /// كل الحقول المدعومة (شهادات + عقود) بلا تكرار — قائمة الإدراج في المحرر.
  static List<DynamicField> get all {
    final Map<String, DynamicField> merged = <String, DynamicField>{};
    for (final DynamicField field in <DynamicField>[...certificate, ...contract]) {
      merged[field.key] = field;
    }
    return merged.values.toList(growable: false);
  }

  /// بحث عن حقل بمفتاحه.
  static DynamicField? byKey(String key) {
    for (final DynamicField field in all) {
      if (field.key == key) return field;
    }
    return null;
  }

  /// الصيغة النصية للحقل كما تُكتب داخل القالب.
  static String token(String key) => '{{$key}}';
}

/// حقل ديناميكي واحد في القالب.
class DynamicField {
  const DynamicField({required this.key, required this.sample});

  /// المفتاح كما يُكتب بين قوسين معقوفين.
  final String key;

  /// قيمة تجريبية تُستخدم في المعاينة قبل ربط Excel.
  final String sample;

  /// الصيغة الجاهزة للإدراج.
  String get token => '{{$key}}';
}
