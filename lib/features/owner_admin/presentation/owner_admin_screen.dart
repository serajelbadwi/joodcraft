/// شاشة «إدارة المالك» — تبويبان: القرى (إضافة/توليد كود/تعديل/حذف)
/// والتراخيص (إصدار وعرض).
///
/// تُفتح من بوابة [OwnerAdminGateScreen] التي تتحقق من `platform_admins`
/// قبل بنائها؛ فنصوصها عربية أحادية اللغة كبقية أدوات الإدارة.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../data/owner_admin_repository.dart';
import 'owner_licenses_tab.dart';
import 'owner_villages_tab.dart';

class OwnerAdminScreen extends StatelessWidget {
  const OwnerAdminScreen({super.key, required this.repository});

  final OwnerAdminRepository repository;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('إدارة المالك'),
          backgroundColor: AppColors.navy,
          foregroundColor: AppColors.onNavy,
          bottom: const TabBar(
            indicatorColor: AppColors.gold,
            labelColor: AppColors.gold,
            unselectedLabelColor: AppColors.onNavy,
            tabs: <Widget>[Tab(text: 'القرى'), Tab(text: 'التراخيص')],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            OwnerVillagesTab(repository: repository),
            OwnerLicensesTab(repository: repository),
          ],
        ),
      ),
    );
  }
}
