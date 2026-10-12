/// شاشة المحادثة — رسائل 1-to-1 بين عضو وآخر من أهل قريته.
///
/// العدّاد يعرض `مستعمل / 100` (طول الرسالة الواحدة) **و** ما تبقّى من حدّ
/// الإرسال: فالمدعو محدود بـ500 حرف في اليوم (مجموع)، وصاحب الفرح محدود
/// بـ100 حرف لكل مدعو (بلا حدّ يومي). وينفد الحدّ ⇒ يُعطَّل زرّ الإرسال
/// وتظهر رسالة واضحة — ويلتجأ المستخدم إلى مدعو آخر أو ينتظر غداً.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/farah_repository.dart';
import '../../domain/farah_models.dart';
import '../../domain/farah_text.dart';
import '../../../village/presentation/village_theme.dart';
import '../farah_theme.dart';
import '../widgets/farah_common.dart';

/// حدود «فرح» — مصدر واحد للأرقام المعروضة والمفحوصة في الواجهة.
abstract final class FarahLimits {
  const FarahLimits._();

  /// طول الرسالة الواحدة (قيد على الجدول نفسه).
  static const int messageLength = 100;
}

class FarahChatScreen extends StatefulWidget {
  const FarahChatScreen({
    super.key,
    required this.repository,
    required this.session,
    required this.partnerId,
    required this.partnerName,
  });

  final FarahRepository repository;
  final FarahSession session;
  final String partnerId;
  final String partnerName;

  @override
  State<FarahChatScreen> createState() => _FarahChatScreenState();
}

class _FarahChatScreenState extends State<FarahChatScreen> {
  final TextEditingController _bodyController = TextEditingController();

  List<FarahMessage> _messages = const <FarahMessage>[];
  int _remaining = 0;
  bool _isOwner = false;
  bool _loading = true;
  bool _sending = false;
  bool _threadUnavailable = false;
  String? _errorMessage;
  int _used = 0;

  @override
  void initState() {
    super.initState();
    _bodyController.addListener(_onBodyChanged);
    _load();
  }

  @override
  void dispose() {
    _bodyController.removeListener(_onBodyChanged);
    _bodyController.dispose();
    super.dispose();
  }

  void _onBodyChanged() {
    final int length = _bodyController.text.length;
    if (length != _used) setState(() => _used = length);
  }

  /// جلب السلسلة + المتبقي من الحدّ في نداءين متوازيين.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
      _threadUnavailable = false;
    });
    try {
      final List<FarahMessage> messages = await widget.repository.fetchThread(
        phone: widget.session.phone,
        partnerId: widget.partnerId,
      );
      final FarahAllowance allowance = await widget.repository.fetchAllowance(
        phone: widget.session.phone,
        partnerId: widget.partnerId,
      );
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _remaining = allowance.remaining;
        _isOwner = allowance.isOwner;
        _loading = false;
      });
    } on FarahException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = error.message;
        // فشل تحديث لاحق يبقي السلسلة المعروضة ويعرض الخطأ أسفل الشاشة.
        _threadUnavailable = _messages.isEmpty;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = FarahText.genericError;
        _threadUnavailable = _messages.isEmpty;
      });
    }
  }

  bool get _canSend =>
      !_sending &&
      _remaining > 0 &&
      _bodyController.text.trim().isNotEmpty;

  Future<void> _send() async {
    if (!_canSend) return;
    final String body = _bodyController.text.trim();

    setState(() {
      _sending = true;
      _errorMessage = null;
    });

    try {
      final FarahSendResult result = await widget.repository.sendMessage(
        phone: widget.session.phone,
        partnerId: widget.partnerId,
        body: body,
      );
      if (!mounted) return;
      setState(() {
        _sending = false;
        _messages = List<FarahMessage>.from(_messages)
          ..add(result.message);
        _remaining = result.remaining;
        _bodyController.clear();
        _used = 0;
      });
    } on FarahException catch (error) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        // نفاد الحدّ (أو أي رفض) يعود برسالة السيرفر العربية الجاهزة.
        _errorMessage = error.message;
      });
      // حدّ يومي قد يكون نفدَ مع آخر رسالة — نُحدّث العدّاد من السيرفر.
      if (error.kind == FarahErrorKind.limitReached) _refreshAllowance();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _errorMessage = FarahText.genericError;
      });
    }
  }

  Future<void> _refreshAllowance() async {
    try {
      final FarahAllowance allowance = await widget.repository.fetchAllowance(
        phone: widget.session.phone,
        partnerId: widget.partnerId,
      );
      if (!mounted) return;
      setState(() {
        _remaining = allowance.remaining;
        _isOwner = allowance.isOwner;
      });
    } catch (_) {
      // صمت: العدّاد ثانوي ولا يمنع قراءة الرسائل.
    }
  }

  @override
  Widget build(BuildContext context) {
    return FarahShell(
      key: const ValueKey<String>('farah-chat'),
      scroll: false,
      // اسم المدعو الكامل في الشريط + زرّ تحديث للسلسلة.
      appBar: FarahAppBar(
        title: widget.partnerName,
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('farah-chat-refresh'),
            tooltip: FarahText.refresh,
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (_loading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_threadUnavailable)
            // فشل جلب السلسلة: الخطأ في مكانها (وسط الشاشة) لا سفلياً.
            Expanded(
              child: Center(child: FarahErrorBanner(message: _errorMessage!)),
            )
          else
            Expanded(child: _buildThread()),
          if (!_threadUnavailable) ...<Widget>[
            const SizedBox(height: VillageMetrics.space8),
            _buildRemainingRow(),
          ],
          if (_errorMessage != null && !_threadUnavailable) ...<Widget>[
            const SizedBox(height: VillageMetrics.space8),
            FarahErrorBanner(message: _errorMessage!),
          ],
          const SizedBox(height: VillageMetrics.space8),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildThread() {
    if (_messages.isEmpty) {
      return const Center(child: FarahNote(message: FarahText.threadEmpty));
    }
    // `reverse: true` تجعل أحدث رسالة أسفل الشاشة دائماً بلا متحكّم تمرير.
    return ListView.builder(
      key: const ValueKey<String>('farah-chat-list'),
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: VillageMetrics.space8),
      itemCount: _messages.length,
      itemBuilder: (BuildContext context, int index) {
        final FarahMessage message = _messages[_messages.length - 1 - index];
        final bool mine = message.senderId == widget.session.memberId;
        return _Bubble(message: message, mine: mine);
      },
    );
  }

  /// سطر العدّاد: «المتبقي لك اليوم: 500 حرف» أو «…لهذا المدعو: 100 حرف».
  Widget _buildRemainingRow() {
    final bool exhausted = _remaining <= 0;
    return Row(
      key: const ValueKey<String>('farah-chat-remaining'),
      children: <Widget>[
        Icon(
          exhausted ? Icons.block_rounded : Icons.bolt_rounded,
          color: exhausted ? VillageColors.danger : VillageColors.goldSoft,
          size: 16,
        ),
        const SizedBox(width: VillageMetrics.space8),
        Expanded(
          child: Text(
            exhausted
                ? (_isOwner
                    ? FarahText.limitReachedToPartner
                    : FarahText.limitReachedToday)
                : (_isOwner
                    ? FarahText.remainingToPartner(_remaining)
                    : FarahText.remainingToday(_remaining)),
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: exhausted
                  ? VillageColors.danger
                  : VillageColors.inkSoft,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputBar() {
    final bool exhausted = _remaining <= 0;
    return Container(
      padding: const EdgeInsets.all(VillageMetrics.space12),
      decoration: BoxDecoration(
        color: VillageColors.surface,
        borderRadius: BorderRadius.circular(VillageMetrics.radiusMd),
        border: Border.all(
          color: exhausted
              ? VillageColors.danger.withValues(alpha: 0.5)
              : VillageColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextField(
            key: const ValueKey<String>('farah-chat-input'),
            controller: _bodyController,
            enabled: !_sending && !exhausted,
            maxLines: 3,
            minLines: 1,
            maxLength: FarahLimits.messageLength,
            textInputAction: TextInputAction.newline,
            inputFormatters: <TextInputFormatter>[
              LengthLimitingTextInputFormatter(FarahLimits.messageLength),
            ],
            decoration: InputDecoration(
              counterText: '',
              hintText: exhausted ? FarahText.limitReachedToday : FarahText.inputHint,
              hintStyle: const TextStyle(
                color: VillageColors.muted,
                fontSize: 14,
                height: 1.7,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: VillageMetrics.space4,
                vertical: VillageMetrics.space8,
              ),
            ),
          ),
          const SizedBox(height: VillageMetrics.space4),
          Row(
            children: <Widget>[
              // عدّاد الأحرف: «١٢ / 100».
              Text(
                FarahText.charCounter(_used, FarahLimits.messageLength),
                key: const ValueKey<String>('farah-chat-counter'),
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  fontSize: 12.5,
                  color: _used >= FarahLimits.messageLength
                      ? VillageColors.danger
                      : VillageColors.muted,
                  height: 1.6,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                key: const ValueKey<String>('farah-chat-send'),
                onPressed: _canSend ? _send : null,
                icon: const Icon(Icons.send_rounded, size: 18),
                label: Text(FarahText.send),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// فقاعة رسالة: فقاعتي (تركواز بحدود ذهبية) جهة البداية، ومراسلي جهة النهاية.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.mine});

  final FarahMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final Color background =
        mine ? VillageColors.teal : VillageColors.surfaceHigh;
    final Color border =
        mine ? VillageColors.gold.withValues(alpha: 0.55) : VillageColors.border;

    return Align(
      alignment: mine
          ? AlignmentDirectional.centerStart
          : AlignmentDirectional.centerEnd,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: VillageMetrics.space8,
          vertical: VillageMetrics.space4,
        ),
        constraints: const BoxConstraints(maxWidth: 340),
        padding: const EdgeInsets.symmetric(
          horizontal: VillageMetrics.space16,
          vertical: VillageMetrics.space12,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(VillageMetrics.radiusMd),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              message.body,
              style: const TextStyle(
                fontSize: 14.5,
                color: VillageColors.white,
                height: 1.8,
              ),
            ),
            const SizedBox(height: VillageMetrics.space4),
            Text(
              _timeLabel(message.createdAt),
              style: TextStyle(
                fontSize: 11,
                color: (mine ? VillageColors.goldSoft : VillageColors.muted)
                    .withValues(alpha: 0.9),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeLabel(DateTime at) {
    final DateTime local = at.toLocal();
    final String hour = local.hour.toString().padLeft(2, '0');
    final String minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
