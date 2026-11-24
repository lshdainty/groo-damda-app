/// 해지 전 점검 결과 — `GET /users/me/withdrawal-check`.
///
/// 개수를 세어 오는 이유는 화면이 **무엇을 잃는지 숫자로** 보여 줘야 하기 때문이다.
/// "모든 데이터가 삭제됩니다" 는 아무것도 알려 주지 않는다.
class WithdrawalCheck {
  const WithdrawalCheck({
    required this.blocked,
    required this.subscriptionPeriodEnd,
    required this.sharedCalendarsOwned,
    required this.calendarMemberships,
    required this.dutchPaysOwned,
    required this.dutchPayParticipations,
    this.sharedCalendarsToTransfer = 0,
  });

  /// 막는 사유. 비어 있어야 해지할 수 있다 — [blockSubscription] · [blockSharedCalendar].
  final List<String> blocked;

  /// 구독이 막고 있을 때 **언제부터 가능한지**. 서버가 시간대 없이 주는 `[UTC]` 라
  /// 화면에 보일 때는 사용자 시간대로 옮겨야 한다(그냥 자르면 KST 에서 하루 이르다).
  final String? subscriptionPeriodEnd;

  /// 내가 만든 공유 캘린더 — 해지하면 삭제되고 멤버도 못 본다.
  final int sharedCalendarsOwned;

  /// 남의 캘린더에 들어가 있는 수 — 거기서 빠진다.
  final int calendarMemberships;

  /// 내가 만든 정산 — 삭제된다.
  final int dutchPaysOwned;

  /// 남의 정산에 참가한 수 — "탈퇴한 사용자" 로 남는다.
  final int dutchPayParticipations;

  /// 내가 소유자이고 다른 멤버가 남은 캘린더 수 — 0 이 아니면 해지가 막힌다([blockSharedCalendar]).
  /// 소유자를 넘기고 나가야 풀린다(2026-11-24 사용자 결정: 공유 캘린더는 지우지 않는다).
  final int sharedCalendarsToTransfer;

  /// 해지를 막는 사유 코드.
  ///
  /// **서버가 짓는 문자열이다** — desk-back `WithdrawalServiceImpl.check()` 가
  /// `List.of("SUBSCRIPTION_ACTIVE")` 로 넣는다. 한 글자라도 다르면 [blockedBySubscription]
  /// 이 조용히 false 가 되어, 구독 때문에 막힌 사람에게 **언제부터 가능한지 날짜를 못
  /// 보여 준다**(실제로 `SUBSCRIPTION` 으로 적어 두고 dev 에서 뒤늦게 잡았다, 2026-09-17).
  /// 서버를 고치면 여기도 같이 고쳐야 한다.
  static const blockSubscription = 'SUBSCRIPTION_ACTIVE';

  /// 멤버가 남은 공유 캘린더의 소유자 — 서버 `WithdrawalServiceImpl` 이 `"SHARED_CALENDAR_OWNED"` 로 넣는다.
  /// 위와 같이 서버 문자열 그대로다.
  static const blockSharedCalendar = 'SHARED_CALENDAR_OWNED';

  /// 해지 실행이 같은 까닭으로 막혔을 때의 오류 코드(409) — 점검 뒤에 상황이 바뀐 경우다.
  static const blockedSharedCalendarCode = 'USER_022';

  bool get isBlocked => blocked.isNotEmpty;
  bool get blockedBySubscription => blocked.contains(blockSubscription);
  bool get blockedBySharedCalendar => blocked.contains(blockSharedCalendar);

  factory WithdrawalCheck.fromJson(Map<String, dynamic> json) {
    return WithdrawalCheck(
      blocked: (json['blocked'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(growable: false),
      subscriptionPeriodEnd: json['subscriptionPeriodEnd'] as String?,
      sharedCalendarsOwned: json['sharedCalendarsOwned'] as int? ?? 0,
      calendarMemberships: json['calendarMemberships'] as int? ?? 0,
      dutchPaysOwned: json['dutchPaysOwned'] as int? ?? 0,
      dutchPayParticipations: json['dutchPayParticipations'] as int? ?? 0,
      sharedCalendarsToTransfer: json['sharedCalendarsToTransfer'] as int? ?? 0,
    );
  }
}
