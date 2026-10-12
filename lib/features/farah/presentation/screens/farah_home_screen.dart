/// شاشة رئيسية «أهل القرية»: ترحيب باسم العضو الكامل + شارة صاحب الفرح
/// + أزرار (الرسائل · الدعوات · كود التفعيل) + **قائمة أهل القرية** بكل
/// الأسماء الكاملة — والضغط على أي اسم يفتح المحادثة معه مباشرةً.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_assets.dart';
import '../../data/farah_repository.dart';
import '../../domain/farah_models.dart';
import '../../domain/farah_text.dart';
import '../../../village/presentation/village_theme.dart';
import '../farah_theme.dart';
import '../widgets/farah_common.dart';
import 'farah_chat_screen.dart';
import 'farah_invitations_screen.dart';
import 'farah_license_screen.dart';
import 'farah_login_screen.dart';
import 'farah_messages_screen.dart';

class FarahHomeScreen extends StatefulWidget {
  const FarahHomeScreen({
    super.key,
    required this.repository,
    required this.session,
  });

  final FarahRepository repository;

  /// جلسة العضو — قد تتحدّث بعد تفعيل كود صاحب الفرح.
  final FarahSession session;

  @override
  State<FarahHomeScreen> createState() => _FarahHomeScreenState();
}

class _FarahHomeScreenState extends State<FarahHomeScreen> {
  late FarahSession _session = widget.session;

  List<FarahMember> _members = const <FarahMember>[];
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    if (!widget.repository.isAvailable) {
      setState(() {
        _loading = false;
        _errorMessage = FarahText.serviceUnavailable;
      });
      return;
    }
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final List<FarahMember> members =
          await widget.repository.fetchMembers(_session.phone);
      if (!mounted) return;
      setState(() {
        // «أهل القرية» للمراسلة: بلا حسابك أنت — فالمحادثة مع نفسك ممنوعة
        // على السيرفر فلا معنى لفتحها هنا.
        _members = members
            .where((FarahMember m) => m.memberId != _session.memberId)
            .toList(growable: false);
        _loading = false;
      });
    } on FarahException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = FarahText.genericError;
      });
    }
  }

  void _openChat(FarahMember member) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => FarahChatScreen(
          repository: widget.repository,
          session: _session,
          partnerId: member.memberId,
          partnerName: member.fullName,
        ),
      ),
    );
  }

  Future<void> _openMessages() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => FarahMessagesScreen(
          repository: widget.repository,
          session: _session,
        ),
      ),
    );
  }

  Future<void> _openLicense() async {
    final FarahSession? updated =
        await Navigator.of(context).push<FarahSession>(
      MaterialPageRoute<FarahSession>(
        builder: (BuildContext context) => FarahLicenseScreen(
          repository: widget.repository,
          session: _session,
        ),
      ),
    );
    // التفعيل الناجح يفتح صلاحيات صاحب الفرح هنا فوراً (بلا خروج).
    if (updated != null && mounted) setState(() => _session = updated);
  }

  /// خروج: يمحو التليفون المحفوظ ويعود إلى شاشة الدخول.
  Future<void> _signOut() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(farahPhonePrefsKey);
    } catch (_) {
      // لا شيء يمنع الخروج.
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return FarahShell(
      key: const ValueKey<String>('farah-home'),
      // الرئيسية **جذر** التطبيق: بلا سهم رجوع، و«خروج» في الشريط يعيد
      // لشاشة الدخول (ويمحو التليفون المحفوظ).
      appBar: FarahAppBar(
        title: FarahText.appName,
        // الشعار بارتفاع ‎40px‎ مكان النصّ (يبقى الاسم لقارئ الشاشة).
        titleWidget: Image.asset(
          AppAssets.farahLogoImage,
          key: const ValueKey<String>('farah-home-logo'),
          height: 40,
          fit: BoxFit.contain,
          errorBuilder: (
            BuildContext context,
            Object error,
            StackTrace? stackTrace,
          ) =>
              const Text(
            FarahText.appName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppAssets.amiriFont,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: VillageColors.gold,
              height: 1.5,
            ),
          ),
        ),
        showBack: false,
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('farah-home-sign-out'),
            tooltip: FarahText.signOut,
            onPressed: _signOut,
            icon: const Icon(Icons.logout_rounded, color: VillageColors.muted),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _Header(session: _session),
          const SizedBox(height: VillageMetrics.space16),
          Row(
            children: <Widget>[
              Expanded(
                child: _ActionTile(
                  key: const ValueKey<String>('farah-home-messages'),
                  icon: Icons.chat_bubble_rounded,
                  label: FarahText.messagesButton,
                  onTap: _openMessages,
                ),
              ),
              const SizedBox(width: VillageMetrics.space12),
              Expanded(
                child: _ActionTile(
                  key: const ValueKey<String>('farah-home-invitations'),
                  icon: Icons.mail_rounded,
                  label: FarahText.invitationsButton,
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) =>
                          const FarahInvitationsScreen(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: VillageMetrics.space12),
              Expanded(
                child: _ActionTile(
                  key: const ValueKey<String>('farah-home-license'),
                  icon: Icons.workspace_premium_rounded,
                  label: _session.isOwner
                      ? FarahText.ownerActive
                      : FarahText.licenseButton,
                  highlighted: _session.isOwner,
                  onTap: _openLicense,
                ),
              ),
            ],
          ),
          const SizedBox(height: VillageMetrics.space24),
          const FarahNote(message: FarahText.homeHint),
          const SizedBox(height: VillageMetrics.space24),
          Text(
            FarahText.homeTitle,
            style: const TextStyle(
              fontFamily: AppAssets.amiriFont,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: VillageColors.goldSoft,
              height: 1.5,
            ),
          ),
          const SizedBox(height: VillageMetrics.space12),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(VillageMetrics.space24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_errorMessage != null)
            FarahErrorBanner(message: _errorMessage!)
          else if (_members.isEmpty)
            const FarahNote(message: FarahText.membersEmpty)
          else
            Container(
              key: const ValueKey<String>('farah-home-members'),
              decoration: BoxDecoration(
                color: VillageColors.surface,
                borderRadius: BorderRadius.circular(VillageMetrics.radiusMd),
                border: Border.all(
                  color: VillageColors.border.withValues(alpha: 0.8),
                  width: 0.8,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (int i = 0; i < _members.length; i++) ...<Widget>[
                    if (i > 0)
                      Divider(
                        height: 1,
                        color: VillageColors.border.withValues(alpha: 0.5),
                      ),
                    _MemberTile(
                      member: _members[i],
                      onTap: () => _openChat(_members[i]),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// ترويسة الشاشة: اسم العضو الكامل + قريته + شارة صاحب الفرح.
/// (زرّ «خروج» صار في الشريط العلوي بعدله `_signOut`.)
class _Header extends StatelessWidget {
  const _Header({required this.session});

  final FarahSession session;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: VillageColors.teal.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(VillageMetrics.radiusMd),
            border: Border.all(
              color: VillageColors.tealSoft.withValues(alpha: 0.6),
            ),
          ),
          child: const Icon(
            Icons.person_rounded,
            color: VillageColors.goldSoft,
            size: 26,
          ),
        ),
        const SizedBox(width: VillageMetrics.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      session.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppAssets.amiriFont,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: VillageColors.white,
                        height: 1.45,
                      ),
                    ),
                  ),
                  if (session.isOwner) ...<Widget>[
                    const SizedBox(width: VillageMetrics.space8),
                    const FarahOwnerBadge(),
                  ],
                ],
              ),
              const SizedBox(height: VillageMetrics.space4),
              Text(
                session.villageName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: VillageColors.muted,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// زرّ إجراء في صفّ الرئيسية (الرسائل/الدعوات/التفعيل).
class _ActionTile extends StatelessWidget {
  const _ActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final Color accent = highlighted ? VillageColors.gold : VillageColors.tealSoft;
    return Material(
      color: VillageColors.surfaceHigh.withValues(alpha: 0.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VillageMetrics.radiusMd),
        side: BorderSide(
          color: highlighted
              ? VillageColors.gold.withValues(alpha: 0.7)
              : VillageColors.border,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(VillageMetrics.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: VillageMetrics.space12,
            vertical: VillageMetrics.space16,
          ),
          child: Column(
            children: <Widget>[
              Icon(icon, color: accent, size: 24),
              const SizedBox(height: VillageMetrics.space8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: VillageColors.white,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// صفّ عضو في «أهل القرية» — الاسم الكامل + شارة صاحب الفرح.
class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member, required this.onTap});

  final FarahMember member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: VillageMetrics.space16,
          vertical: VillageMetrics.space12,
        ),
        child: Row(
          children: <Widget>[
            Icon(
              member.isOwner
                  ? Icons.workspace_premium_rounded
                  : Icons.person_outline_rounded,
              color: member.isOwner
                  ? VillageColors.gold
                  : VillageColors.muted,
              size: 22,
            ),
            const SizedBox(width: VillageMetrics.space12),
            Expanded(
              child: Text(
                member.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  color: VillageColors.white,
                  height: 1.6,
                ),
              ),
            ),
            if (member.isOwner) ...<Widget>[
              const SizedBox(width: VillageMetrics.space8),
              const FarahOwnerBadge(),
            ],
            const SizedBox(width: VillageMetrics.space8),
            const Icon(
              Icons.chevron_left_rounded,
              color: VillageColors.muted,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
