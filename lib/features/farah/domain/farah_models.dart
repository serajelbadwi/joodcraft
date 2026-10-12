/// نماذج بيانات تطبيق «فرح» — كيانات خالصة بلا أي اعتماد على Supabase،
/// تُبنى من صفوف دوال (RPC) وتُقرأ في الشاشات.
library;

import 'package:flutter/foundation.dart';

/// جلسة العضو بعد الدخول بتليفونه: هويّته وقريته وصلاحيته.
@immutable
class FarahSession {
  const FarahSession({
    required this.memberId,
    required this.fullName,
    required this.villageId,
    required this.villageName,
    required this.isOwner,
    required this.phone,
  });

  /// معرّف العضو في `members`.
  final String memberId;

  /// اسمه الكامل كما سجّله في صفحة القرية.
  final String fullName;

  final String villageId;
  final String villageName;

  /// هل هو صاحب الفرح (كود تفعيل مُفعَّل)؟
  final bool isOwner;

  /// التليفون الذي دخل به (يُعاد استخدامه في كل نداء لاحق).
  final String phone;

  factory FarahSession.fromRow(Map<String, dynamic> row, {required String phone}) {
    return FarahSession(
      memberId: '${row['member_id'] ?? ''}',
      fullName: '${row['full_name'] ?? ''}',
      villageId: '${row['village_id'] ?? ''}',
      villageName: '${row['village_name'] ?? ''}',
      isOwner: row['is_owner'] == true,
      phone: phone,
    );
  }

  /// نسخة بالصلاحية المحدّثة (بعد تفعيل كود صاحب الفرح).
  FarahSession copyWith({bool? isOwner}) => FarahSession(
        memberId: memberId,
        fullName: fullName,
        villageId: villageId,
        villageName: villageName,
        isOwner: isOwner ?? this.isOwner,
        phone: phone,
      );

  @override
  bool operator ==(Object other) =>
      other is FarahSession && other.memberId == memberId;

  @override
  int get hashCode => memberId.hashCode;
}

/// عضو في القرية يظهر في «أهل القرية».
@immutable
class FarahMember {
  const FarahMember({
    required this.memberId,
    required this.fullName,
    required this.isOwner,
  });

  final String memberId;
  final String fullName;
  final bool isOwner;

  factory FarahMember.fromRow(Map<String, dynamic> row) => FarahMember(
        memberId: '${row['member_id'] ?? ''}',
        fullName: '${row['full_name'] ?? ''}',
        isOwner: row['is_owner'] == true,
      );
}

/// صفّ في قائمة المحادثات: اسم المدعو + آخر رسالة + المتبقي من حدّ الإرسال.
@immutable
class FarahConversation {
  const FarahConversation({
    required this.partnerId,
    required this.partnerName,
    required this.partnerIsOwner,
    required this.lastBody,
    required this.lastAt,
    required this.lastFromMe,
    required this.remaining,
  });

  final String partnerId;
  final String partnerName;
  final bool partnerIsOwner;

  /// آخر رسالة (فارغة إن لم تُرسل رسالة بعد).
  final String lastBody;

  /// زمن آخر رسالة (فارغ إن لم تُرسل رسالة بعد).
  final DateTime? lastAt;

  /// هل آخر رسالة مني أنا؟ (لتمييز جهة الكلام).
  final bool lastFromMe;

  /// ما تبقّى من حدّ الإرسال إلى هذا المدعو.
  final int remaining;

  bool get hasMessages => lastBody.isNotEmpty;

  factory FarahConversation.fromRow(Map<String, dynamic> row) {
    final Object? at = row['last_at'];
    return FarahConversation(
      partnerId: '${row['partner_id'] ?? ''}',
      partnerName: '${row['partner_name'] ?? ''}',
      partnerIsOwner: row['partner_is_owner'] == true,
      lastBody: '${row['last_body'] ?? ''}',
      lastAt: at is String ? DateTime.tryParse(at) : null,
      lastFromMe: row['last_from_me'] == true,
      remaining: (row['remaining'] as num?)?.toInt() ?? 0,
    );
  }
}

/// رسالة واحدة في المحادثة.
@immutable
class FarahMessage {
  const FarahMessage({
    required this.id,
    required this.senderId,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String senderId;
  final String body;
  final DateTime createdAt;

  factory FarahMessage.fromRow(Map<String, dynamic> row) {
    final Object? at = row['created_at'];
    return FarahMessage(
      id: '${row['id'] ?? ''}',
      senderId: '${row['sender_id'] ?? ''}',
      body: '${row['body'] ?? ''}',
      createdAt: at is String
          ? (DateTime.tryParse(at) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}

/// نتيجة إرسال رسالة: الرسالة كما حُفظت + ما تبقّى من الحدّ بعدها.
@immutable
class FarahSendResult {
  const FarahSendResult({required this.message, required this.remaining});

  final FarahMessage message;
  final int remaining;
}

/// ما تبقّى من حدّ الإرسال في المحادثة الحالية.
@immutable
class FarahAllowance {
  const FarahAllowance({required this.remaining, required this.isOwner});

  final int remaining;
  final bool isOwner;
}
