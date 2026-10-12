/// قوالب المستندات الجاهزة لـ«جود كاتب» — 21 قالباً في 4 فئات.
///
/// كل قالب يُبنى إلى [JoodWriterDocument] كاملة (عنوان + كتل منسّقة + إعدادات
/// صفحة أحياناً) وتُطبَّق عبر `controller.loadDocument` — فلا تغيير على
/// محرّك التخطيط، والقالب محتوى لا سلوك.
library;

import '../../../domain/jood_writer_block.dart';
import '../../../domain/jood_writer_document.dart';

enum WriterTemplateCategory {
  educational('تعليمي'),
  religious('ديني'),
  business('تجاري'),
  personal('شخصي');

  const WriterTemplateCategory(this.labelAr);
  final String labelAr;
}

class WriterDocumentTemplate {
  const WriterDocumentTemplate({
    required this.id,
    required this.nameAr,
    required this.category,
    required JoodWriterDocument Function() build,
  }) : _build = build;

  final String id;
  final String nameAr;
  final WriterTemplateCategory category;
  final JoodWriterDocument Function() _build;

  JoodWriterDocument build() => _build();
}

abstract final class WriterTemplatesCatalog {
  static const JoodWriterBlock _h1 = JoodWriterBlock(
    text: '',
    kind: JoodWriterBlockKind.heading1,
    align: JoodWriterAlign.center,
  );
  static const JoodWriterBlock _h2 = JoodWriterBlock(
    text: '',
    kind: JoodWriterBlockKind.heading2,
  );
  static const JoodWriterBlock _p = JoodWriterBlock(text: '');
  static const JoodWriterBlock _bullet = JoodWriterBlock(
    text: '',
    kind: JoodWriterBlockKind.bullet,
  );

  static JoodWriterDocument _doc(
    String title,
    List<JoodWriterBlock> blocks, {
    bool pageBorder = false,
  }) => JoodWriterDocument(
    title: title,
    blocks: blocks,
    pageBorder: pageBorder,
  );

  static JoodWriterBlock _h1t(String t) => _h1.copyWith(text: t);
  static JoodWriterBlock _h2t(String t) => _h2.copyWith(text: t);
  static JoodWriterBlock _pt(String t) => _p.copyWith(text: t);
  static JoodWriterBlock _bt(String t) => _bullet.copyWith(text: t);

  // ----------------------------- تعليمي -----------------------------
  static final List<WriterDocumentTemplate> all = <WriterDocumentTemplate>[
    WriterDocumentTemplate(
      id: 'study-note',
      nameAr: 'مذكرة دراسية',
      category: WriterTemplateCategory.educational,
      build: () => _doc('مذكرة دراسية', <JoodWriterBlock>[
        _h1t('المادة:'),
        _pt('التاريخ:'),
        _h2t('المحاضرة'),
        _pt(''),
        _h2t('أبرز النقاط'),
        _bt(''),
        _bt(''),
        _h2t('الملخّص'),
        _pt(''),
      ]),
    ),
    WriterDocumentTemplate(
      id: 'research',
      nameAr: 'بحث علمي',
      category: WriterTemplateCategory.educational,
      build: () => _doc('بحث علمي', <JoodWriterBlock>[
        _h1t('عنوان البحث'),
        _h2t('المقدمة'),
        _pt(''),
        _h2t('الإشكالية'),
        _pt(''),
        _h2t('المنهجية'),
        _pt(''),
        _h2t('النتائج'),
        _bt(''),
        _h2t('الخاتمة والمراجع'),
        _pt(''),
      ]),
    ),
    WriterDocumentTemplate(
      id: 'book-summary',
      nameAr: 'ملخّص كتاب',
      category: WriterTemplateCategory.educational,
      build: () => _doc('ملخّص كتاب', <JoodWriterBlock>[
        _h1t('ملخّص: (اسم الكتاب)'),
        _h2t('نبذة عن المؤلّف'),
        _pt(''),
        _h2t('الفكرة المركزية'),
        _pt(''),
        _h2t('أهم الأفكار'),
        _bt(''),
        _bt(''),
        _h2t('انطباعي'),
        _pt(''),
      ]),
    ),
    WriterDocumentTemplate(
      id: 'lesson-plan',
      nameAr: 'خطة درس',
      category: WriterTemplateCategory.educational,
      build: () => _doc('خطة درس', <JoodWriterBlock>[
        _h1t('خطة الدرس'),
        _pt('المادة: — الصف: — الزمن:'),
        _h2t('الأهداف'),
        _bt(''),
        _h2t('التهيئة'),
        _pt(''),
        _h2t('العرض'),
        _pt(''),
        _h2t('التقويم'),
        _pt(''),
      ]),
    ),
    WriterDocumentTemplate(
      id: 'exam-sheet',
      nameAr: 'ورقة اختبار',
      category: WriterTemplateCategory.educational,
      build: () => _doc('ورقة اختبار', <JoodWriterBlock>[
        _h1t('اسم الـمدرسة: — المادة:'),
        _h1t('الاسم: — الزمن: ٦٠ دقيقة'),
        _h2t('السؤال الأول (١٠ درجات)'),
        _pt(''),
        _h2t('السؤال الثاني (١٠ درجات)'),
        _pt(''),
        _h2t('السؤال الثالث (١٠ درجات)'),
        _pt(''),
      ], pageBorder: true),
    ),

    // ----------------------------- ديني -----------------------------
    WriterDocumentTemplate(
      id: 'friday-sermon',
      nameAr: 'خطبة جمعة',
      category: WriterTemplateCategory.religious,
      build: () => _doc('خطبة جمعة', <JoodWriterBlock>[
        _h1t('خطبة الجمعة'),
        _pt('الحمد لله رب العالمين، والصلاة والسلام على نبينا محمد وعلى آله وصحبه أجمعين، أما بعد:'),
        _h2t('الموضوع:'),
        _pt(''),
        _h2t('أثر من القرآن'),
        _pt(''),
        _h2t('أثر من السنة'),
        _pt(''),
        _h2t('الخلاصة والدعاء'),
        _pt(''),
      ]),
    ),
    WriterDocumentTemplate(
      id: 'religious-circle',
      nameAr: 'مذكرة حلقة دينية',
      category: WriterTemplateCategory.religious,
      build: () => _doc('مذكرة حلقة دينية', <JoodWriterBlock>[
        _h1t('مذكرة الحلقة'),
        _pt('الموضوع: — التاريخ: — المكان:'),
        _h2t('المحاضر'),
        _pt(''),
        _h2t('أسئلة وأجوبة'),
        _bt(''),
        _h2t('المواعيد القادمة'),
        _pt(''),
      ]),
    ),
    WriterDocumentTemplate(
      id: 'occasion-invitation',
      nameAr: 'دعوة مناسبة',
      category: WriterTemplateCategory.religious,
      build: () => _doc('دعوة مناسبة', <JoodWriterBlock>[
        _h1t('بسم الله الرحمن الرحيم'),
        _h1t('دعوة'),
        _pt('يسرّنا دعوتكم لحضور حفل (المناسبة) وذلك يوم (التاريخ) بمشيئة الله، في (المكان).'),
        _pt('تقبلوا فائق الاحترام والتقدير.'),
      ]),
    ),
    WriterDocumentTemplate(
      id: 'virtues-note',
      nameAr: 'مذكرة فضائل',
      category: WriterTemplateCategory.religious,
      build: () => _doc('مذكرة فضائل', <JoodWriterBlock>[
        _h1t('فضائل الأعمال'),
        _h2t('الفضل'),
        _pt(''),
        _h2t('دليل ذلك'),
        _pt(''),
        _h2t('نواقص العمل'),
        _bt(''),
      ]),
    ),
    WriterDocumentTemplate(
      id: 'mosque-notice',
      nameAr: 'إعلان مسجد',
      category: WriterTemplateCategory.religious,
      build: () => _doc('إعلان مسجد', <JoodWriterBlock>[
        _h1t('إعلان'),
        _h1t('(اسم المسجد)'),
        _pt('يُعلن مسجد (الاسم) عن انطلاق (الفعالية) وذلك يوم (التاريخ) بعد صلاة (الصلاة).'),
        _pt('حضور أهل الخير محبّة.'),
      ], pageBorder: true),
    ),

    // ----------------------------- تجاري -----------------------------
    WriterDocumentTemplate(
      id: 'monthly-report',
      nameAr: 'تقرير شهري',
      category: WriterTemplateCategory.business,
      build: () => _doc('تقرير شهري', <JoodWriterBlock>[
        _h1t('التقرير الشهري — (الشهر)'),
        _h2t('الملخّص التنفيذي'),
        _pt(''),
        _h2t('المؤشرات'),
        _bt('المؤشر الأول:'),
        _bt('المؤشر الثاني:'),
        _h2t('التحديات'),
        _pt(''),
        _h2t('خطة الشهر القادم'),
        _pt(''),
      ]),
    ),
    WriterDocumentTemplate(
      id: 'quotation',
      nameAr: 'عرض سعر',
      category: WriterTemplateCategory.business,
      build: () => _doc('عرض سعر', <JoodWriterBlock>[
        _h1t('عرض سعر'),
        _pt('إلى: (العميل) — التاريخ:'),
        _h2t('البيان'),
        _bt('البند الأول:'),
        _bt('البند الثاني:'),
        _h2t('الإجمالي'),
        _pt(''),
        _h2t('شروط العرض'),
        _pt('العرض ساري لمدة ١٥ يوماً.'),
      ], pageBorder: true),
    ),
    WriterDocumentTemplate(
      id: 'contract',
      nameAr: 'عقد عمل',
      category: WriterTemplateCategory.business,
      build: () => _doc('عقد عمل', <JoodWriterBlock>[
        _h1t('عقد عمل'),
        _pt('إنه في يوم (التاريخ) تمّ الاتفاق بين الطرف الأول (…) والطرف الثاني (…) على ما يلي:'),
        _h2t('المادة الأولى: موضوع العقد'),
        _pt(''),
        _h2t('المادة الثانية: المدة'),
        _pt(''),
        _h2t('المادة الثالثة: الالتزامات'),
        _bt(''),
        _pt('وحُرِّر هذا العقد من نسختين، وكل طرف يحتفظ بنسخة.'),
      ], pageBorder: true),
    ),
    WriterDocumentTemplate(
      id: 'meeting-minutes',
      nameAr: 'محضر اجتماع',
      category: WriterTemplateCategory.business,
      build: () => _doc('محضر اجتماع', <JoodWriterBlock>[
        _h1t('محضر اجتماع'),
        _pt('التاريخ: — الحضور: — الغياب:'),
        _h2t('جدول الأعمال'),
        _bt(''),
        _h2t('المناقشات'),
        _pt(''),
        _h2t('القرارات'),
        _bt(''),
        _h2t('المهام والآجال'),
        _pt(''),
      ]),
    ),
    WriterDocumentTemplate(
      id: 'official-letter',
      nameAr: 'خطاب رسمي',
      category: WriterTemplateCategory.business,
      build: () => _doc('خطاب رسمي', <JoodWriterBlock>[
        _h1t('خطاب رسمي'),
        _pt('إلى السادة: (الجهة)'),
        _pt('تحية طيبة وبعد،'),
        _pt('الموضوع:'),
        _pt('وتفضلوا بقبول فائق الاحترام،'),
        _h2t('التاريخ:'),
      ]),
    ),
    WriterDocumentTemplate(
      id: 'cv',
      nameAr: 'سيرة ذاتية',
      category: WriterTemplateCategory.business,
      build: () => _doc('سيرة ذاتية', <JoodWriterBlock>[
        _h1t('(الاسم الكامل)'),
        _pt('هاتف: — بريد:'),
        _h2t('الملخص المهني'),
        _pt(''),
        _h2t('الخبرات'),
        _bt('(الوظيفة) — (الجهة) — (الفترة)'),
        _h2t('المهارات'),
        _bt(''),
        _h2t('الشهادات'),
        _bt(''),
      ]),
    ),

    // ----------------------------- شخصي -----------------------------
    WriterDocumentTemplate(
      id: 'personal-letter',
      nameAr: 'رسالة شخصية',
      category: WriterTemplateCategory.personal,
      build: () => _doc('رسالة شخصية', <JoodWriterBlock>[
        _h1t('رسالة'),
        _pt('إلى صديقي/صديقتي (الاسم)،'),
        _pt('أرحّل الله عنك كل همّ، وبعد:'),
        _pt(''),
        _pt('مع خالص المودّة،'),
      ]),
    ),
    WriterDocumentTemplate(
      id: 'todo-list',
      nameAr: 'قائمة مهام',
      category: WriterTemplateCategory.personal,
      build: () => _doc('قائمة مهام', <JoodWriterBlock>[
        _h1t('مهام اليوم'),
        _bt(''),
        _bt(''),
        _bt(''),
        _h2t('أولوية قصوى'),
        _bt(''),
      ]),
    ),
    WriterDocumentTemplate(
      id: 'journal',
      nameAr: 'دفتر يوميات',
      category: WriterTemplateCategory.personal,
      build: () => _doc('دفتر يوميات', <JoodWriterBlock>[
        _h1t('يومية (التاريخ)'),
        _h2t('مجريات اليوم'),
        _pt(''),
        _h2t('مشاعري'),
        _pt(''),
        _h2t('امتناني اليوم'),
        _pt(''),
      ]),
    ),
    WriterDocumentTemplate(
      id: 'family-occasion',
      nameAr: 'مناسبة عائلية',
      category: WriterTemplateCategory.personal,
      build: () => _doc('مناسبة عائلية', <JoodWriterBlock>[
        _h1t('بمناسبة (الحدث)'),
        _pt('يسعدنا أن نشارككم فرحتنا بمناسبة (الحدث) يوم (التاريخ) في (المكان).'),
        _pt('حضوركم يزيد الفرح بهجة.'),
      ], pageBorder: true),
    ),
    WriterDocumentTemplate(
      id: 'certificate',
      nameAr: 'شهادة تقدير',
      category: WriterTemplateCategory.personal,
      build: () => _doc('شهادة تقدير', <JoodWriterBlock>[
        _h1t('شهادة تقدير'),
        _pt(''),
        _h1t('تُمنح هذه الشهادة إلى'),
        _h1t('(الاسم)'),
        _pt('تقديراً لجهوده المتميّزة وعطائه اللامحدود، سائلين الله له دوام التوفيق.'),
        _pt(''),
        _pt('مدير (الجهة) — التاريخ:'),
      ], pageBorder: true),
    ),
  ];

  /// القوالب المصنّفة — أو كلها عند [WriterTemplateCategory] غير محدّدة.
  static List<WriterDocumentTemplate> of(WriterTemplateCategory? category) =>
      category == null
          ? all
          : all.where((WriterDocumentTemplate t) => t.category == category).toList();

  static WriterDocumentTemplate? byId(String id) {
    for (final WriterDocumentTemplate t in all) {
      if (t.id == id) return t;
    }
    return null;
  }
}
