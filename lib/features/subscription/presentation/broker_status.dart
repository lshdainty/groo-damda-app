import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/features/subscription/data/subscription_repository.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';

/// 증권사 줄의 상태 글 — 목록 줄의 둘째 줄과 연결 화면 머리가 같은 글을 쓴다.
///
/// 연결됨은 "연결됨 · 11월 5일 확인", 아니면 "연결 안 됨". `verifiedAt` 은 서버 `[UTC]` 라 로컬 날짜로 바꿔 읽는다
/// ([parseServerUtc]) — 앞 10자를 자르면 KST 새벽 0~9시 연동이 전날로 보인다. 못 읽는 값이면 날짜 없이 "연결됨".
String brokerStatusText(AppLocalizations l, BrokerConnection c) {
  if (!c.connected) return l.subBrokerStatusNone;
  final at = parseServerUtc(c.verifiedAt);
  return at == null
      ? l.subConnected
      : l.subBrokerStatusConnectedAt(monthDay(at));
}
