/// شاشة «الرسائل» — قائمة محادثات العضو: كل أهل قريته بآخر رسالة بينه
/// وبينهم + المتبقي من حدّ الإرسال، والضغط يفتح المحادثة.
library;

import 'package:flutter/material.dart';

import '../../data/farah_repository.dart';
import '../../domain/farah_models.dart';
import '../../domain/farah_text.dart';
import '../../../village/presentation/village_theme.dart';
import '../farah_theme.dart';
import '../widgets/farah_common.dart';
import 'farah_chat_screen.dart';

class FarahMessagesScreen extends StatefulWidget {
  const FarahMessagesScreen({
    super.key,
    required this.repository,
    required this.session,
  });

  final FarahRepository repository;
  final FarahSession session;

  @override
  State<FarahMessagesScreen> createState() => _FarahMessagesScreenState();
}

class _FarahMessagesScreenState extends State<FarahMessagesScreen> {
  List<FarahConversation> _conversations = const <FarahConversation>[];
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final List<FarahConversation> items =
          await widget.repository.fetchConversations(widget.session.phone);
      if (!mounted) return;
      setState(() {
        _conversations = items;
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

  Future<void> _open(FarahConversation conversation) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => FarahChatScreen(
          repository: widget.repository,
          session: widget.session,
          partnerId: conversation.partnerId,
          partnerName: conversation.partnerName,
        ),
      ),
    );
    // عدّاد الحدّ والمحتوى يتبدّلان بعد كل محادثة — نعيد القائمة حيّة.
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    return FarahShell(
      key: const ValueKey<String>('farah-messages'),
      appBar: FarahAppBar(
        title: FarahText.conversationsTitle,
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('farah-messages-refresh'),
            tooltip: FarahText.refresh,
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SizedBox(height: VillageMetrics.space8),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(VillageMetrics.space24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_errorMessage != null)
            FarahErrorBanner(message: _errorMessage!)
          else if (_conversations.isEmpty)
            const FarahNote(message: FarahText.conversationsEmpty)
          else
            Container(
              key: const ValueKey<String>('farah-messages-list'),
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
                  for (int i = 0; i < _conversations.length; i++) ...<Widget>[
                    if (i > 0)
                      Divider(
                        height: 1,
                        color: VillageColors.border.withValues(alpha: 0.5),
                      ),
                    _ConversationTile(
                      conversation: _conversations[i],
                      onTap: () => _open(_conversations[i]),
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

/// صفّ محادثة: الاسم الكامل + آخر رسالة + المتبقي من الحدّ.
class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation, required this.onTap});

  final FarahConversation conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool mine = conversation.lastFromMe;
    final String preview = conversation.hasMessages
        ? (mine ? 'أنت: ${conversation.lastBody}' : conversation.lastBody)
        : FarahText.lastMessageEmpty;

    return InkWell(
      key: ValueKey<String>('farah-conversation-${conversation.partnerId}'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: VillageMetrics.space16,
          vertical: VillageMetrics.space12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              conversation.partnerIsOwner
                  ? Icons.workspace_premium_rounded
                  : Icons.person_outline_rounded,
              color: conversation.partnerIsOwner
                  ? VillageColors.gold
                  : VillageColors.muted,
              size: 26,
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
                          conversation.partnerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: VillageColors.white,
                            height: 1.5,
                          ),
                        ),
                      ),
                      if (conversation.partnerIsOwner) ...<Widget>[
                        const SizedBox(width: VillageMetrics.space8),
                        const FarahOwnerBadge(),
                      ],
                    ],
                  ),
                  const SizedBox(height: VillageMetrics.space4),
                  Text(
                    preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: mine
                          ? VillageColors.goldSoft
                          : VillageColors.muted,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: VillageMetrics.space8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                if (conversation.lastAt != null)
                  Text(
                    _timeLabel(conversation.lastAt!),
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: VillageColors.muted,
                      height: 1.5,
                    ),
                  ),
                const SizedBox(height: VillageMetrics.space4),
                _RemainingChip(remaining: conversation.remaining),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// وقت آخر رسالة: «اليوم ٧:٣٠» أو «١٢ أكتوبر».
  String _timeLabel(DateTime at) {
    final DateTime now = DateTime.now();
    final DateTime local = at.toLocal();
    if (local.year == now.year &&
        local.month == now.month &&
        local.day == now.day) {
      final String hour = local.hour.toString().padLeft(2, '0');
      final String minute = local.minute.toString().padLeft(2, '0');
      return 'اليوم $hour:$minute';
    }
    return '${local.day}/${local.month}';
  }
}

/// شارة المتبقي من الحدّ — حمراء عند النفاد.
class _RemainingChip extends StatelessWidget {
  const _RemainingChip({required this.remaining});

  final int remaining;

  @override
  Widget build(BuildContext context) {
    final bool empty = remaining <= 0;
    final Color color =
        empty ? VillageColors.danger : VillageColors.tealSoft;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VillageMetrics.space8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(VillageMetrics.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        '$remaining',
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: color,
          height: 1.5,
        ),
      ),
    );
  }
}
