/// تبويب «التراخيص» في لوحة تحكم المالك.
///
/// قائمة تراخيص «صاحب الفرح» كما أصدرها مالك المنصّة: الكود والقرية واسم
/// المشترك وتليفونه والتاريخ والمدة وحالة التفعيل — مع زر إصدار ترخيص
/// جديد (قرية + اسم صاحب المكتب + تليفون + مدة شهر/3 شهور/سنة).
///
/// كل ألوان البطاقة من `Theme.of(context).colorScheme` — بلا أي ثابت نهاري
/// — فيتبع التبويب الوضع الليلي كما بقيّة JoodCraft.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../data/owner_admin_repository.dart';
import '../domain/owner_models.dart';
import 'license_form_dialog.dart';
import 'widgets/owner_admin_states.dart';

class OwnerLicensesTab extends StatefulWidget {
  const OwnerLicensesTab({super.key, required this.repository});

  final OwnerAdminRepository repository;

  @override
  State<OwnerLicensesTab> createState() => _OwnerLicensesTabState();
}

class _OwnerLicensesTabState extends State<OwnerLicensesTab> {
  List<OwnerLicense> _licenses = const <OwnerLicense>[];

  /// القرى المطلوبة أصلاً لنموذج الإصدار — تُجلب مع التراخيص.
  List<OwnerVillage> _villages = const <OwnerVillage>[];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // _loading تبدأ true في الحقل — لا setState قبل أول إطار.
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final List<OwnerLicense> licenses = await widget.repository
          .fetchLicenses();
      final List<OwnerVillage> villages = await widget.repository
          .fetchVillages();
      if (!mounted) return;
      setState(() {
        _licenses = licenses;
        _villages = villages;
        _loading = false;
        _error = null;
      });
    } on OwnerAdminException catch (exception) {
      if (!mounted) return;
      setState(() {
        _error = exception.message;
        _loading = false;
      });
    }
  }

  /// إعادة تحميل مع مؤشّر — من تصرّفات المستخدم فقط (بعد أول إطار).
  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await _fetch();
  }

  Future<void> _issueLicense() async {
    final String? code = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => LicenseFormDialog(
        repository: widget.repository,
        villages: _villages,
      ),
    );
    if (code == null || !mounted) return;
    await _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('أُصدر الترخيص: $code')));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return OwnerAdminErrorView(message: _error!, onRetry: _reload);
    }
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              FilledButton.icon(
                key: const ValueKey<String>('owner-issue-license'),
                onPressed: _issueLicense,
                icon: const Icon(Icons.add_card_rounded),
                label: const Text('إصدار ترخيص'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _licenses.isEmpty
              ? const OwnerAdminEmptyView(
                  message: 'لا تراخيص بعد — ابدأ بزر «إصدار ترخيص».',
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 12),
                  itemCount: _licenses.length,
                  itemBuilder: (BuildContext context, int index) =>
                      _buildRow(_licenses[index]),
                ),
        ),
      ],
    );
  }

  /// بطاقة ترخيص: الكود والقرية والمشترك والتاريخ والمدة وحالة التفعيل.
  Widget _buildRow(OwnerLicense license) {
    final String date = _formatDate(license.createdAt);
    final bool active = license.isActive;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              active ? Icons.verified_rounded : Icons.confirmation_number_outlined,
              color: active ? scheme.success : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        license.code,
                        key: ValueKey<String>('license-code-${license.id}'),
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          license.villageName ?? 'قرية محذوفة',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    license.subscriberName ?? '—',
                    key: ValueKey<String>('license-subscriber-${license.id}'),
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (license.subscriberPhone != null &&
                      license.subscriberPhone!.isNotEmpty)
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          license.subscriberPhone!,
                          style: TextStyle(
                            fontSize: 13,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    '$date · المدة: ${license.durationLabel}',
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                // حاوية الحالة: خضراء للنجاح، ورائية للتعطيل — كلتاهما
                // تتبدّل مع السطوع فتظل النص مقروءاً فوقها.
                color: active
                    ? scheme.secondaryContainer
                    : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                active ? 'مفعّل' : 'غير مفعّل',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active ? scheme.success : scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// تاريخ مضغوط `yyyy/MM/dd` — بلا اعتماد على حزمة تراريخ.
  static String _formatDate(DateTime? createdAt) {
    if (createdAt == null) return '—';
    final DateTime local = createdAt.toLocal();
    final String month = local.month.toString().padLeft(2, '0');
    final String day = local.day.toString().padLeft(2, '0');
    return '${local.year}/$month/$day';
  }
}
