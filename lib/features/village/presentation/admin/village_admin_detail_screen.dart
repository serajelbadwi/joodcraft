/// صفحة قرية واحدة داخل اللوحة: هويتها + عدّاداتها + مداخل الإدار الثلاثة
/// (الفيديوهات، الأعضاء، الإعلانات).
///
/// العدّادات تُعاد قراءتها بعد العودة من أي شاشة فرعية، فتتحدّث فوراً بعد
/// الحذف أو الإضافة هناك دون رجوع المستخدم للوحة.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/village_admin_repository.dart';
import '../../domain/village.dart';
import '../../domain/village_admin_overview.dart';
import '../../domain/village_admin_text.dart';
import 'village_admin_direction.dart';
import 'village_admin_feedback.dart';

class VillageAdminDetailScreen extends StatefulWidget {
  const VillageAdminDetailScreen({
    super.key,
    required this.repository,
    required this.overview,
  });

  /// المستودع — يُمرَّر إلى الشاشات الفرعية حتى تبقى متسقة.
  final VillageAdminRepository repository;

  /// بيانات القرية وعدّاداتها كما جاءت من اللوحة.
  final VillageAdminOverview overview;

  @override
  State<VillageAdminDetailScreen> createState() =>
      _VillageAdminDetailScreenState();
}

class _VillageAdminDetailScreenState extends State<VillageAdminDetailScreen> {
  late VillageAdminOverview _overview = widget.overview;

  /// يعيد قراءة عدّاداتها من السيرفر (بعد حذف/إضافة في شاشة فرعية).
  Future<void> _refresh() async {
    try {
      final List<VillageAdminOverview> items =
          await widget.repository.fetchOverviews();
      if (!mounted) return;
      final String id = _overview.village.id;
      for (final VillageAdminOverview item in items) {
        if (item.village.id == id) {
          setState(() => _overview = item);
          break;
        }
      }
    } catch (failure) {
      if (!mounted) return;
      context.showAdminError(failure);
    }
  }

  Future<void> _open(String path) async {
    await context.push<void>(path, extra: _overview.village);
    if (!mounted) return;
    await _refresh();
  }

  @override
  Widget build(BuildContext context) => VillageAdminDirection(
    child: _buildContent(context),
  );

  /// محتوى الشاشة — يُغلَّف بـ[VillageAdminDirection] في [build].
  Widget _buildContent(BuildContext context) {
    final Village village = _overview.village;
    return Scaffold(
      appBar: AppBar(
        title: Text(village.name),
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('village-detail-refresh'),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: VillageAdminText.retry,
            onPressed: _refresh,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.space20),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.space16),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.villa_rounded, size: 32),
                  const SizedBox(width: AppTheme.space16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          village.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppTheme.space4),
                        Text(
                          village.code,
                          textDirection: TextDirection.ltr,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.space12),
          Wrap(
            spacing: AppTheme.space12,
            runSpacing: AppTheme.space12,
            children: <Widget>[
              _Metric(
                value: '${_overview.membersCount}',
                label: VillageAdminText.statMembers,
              ),
              _Metric(
                value: '${_overview.videosCount}',
                label: VillageAdminText.statVideos,
              ),
              _Metric(
                value: '${_overview.activeAdsCount}',
                label: VillageAdminText.statAds,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space8),
          _SectionCard(
            key: const ValueKey<String>('section-videos'),
            icon: Icons.video_library_rounded,
            title: VillageAdminText.sectionVideos,
            description: VillageAdminText.sectionVideosDesc,
            onTap: () =>
                _open('${AppRoutes.villageAdmin}/village/videos'),
          ),
          _SectionCard(
            key: const ValueKey<String>('section-members'),
            icon: Icons.groups_rounded,
            title: VillageAdminText.sectionMembers,
            description: VillageAdminText.sectionMembersDesc,
            onTap: () =>
                _open('${AppRoutes.villageAdmin}/village/members'),
          ),
          _SectionCard(
            key: const ValueKey<String>('section-ads'),
            icon: Icons.campaign_rounded,
            title: VillageAdminText.sectionAds,
            description: VillageAdminText.sectionAdsDesc,
            onTap: () => _open('${AppRoutes.villageAdmin}/village/ads'),
          ),
        ],
      ),
    );
  }
}

/// عدّاد واحد في صفّ العدّادات.
class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space16,
            vertical: AppTheme.space12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppTheme.space2),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

/// بطاقة مدخل إداري (أيقونة + عنوان + وصف + سهم).
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.space12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(description, style: const TextStyle(height: 1.5)),
        trailing: const Icon(Icons.chevron_left_rounded),
        onTap: onTap,
      ),
    );
  }
}
