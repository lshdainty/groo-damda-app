import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/features/dutch_pay/domain/dutch_pay.dart';

/// 더치페이 목록 화면의 셈(I-15 25 ~ 29 · 40) — 화면 · 시험이 같은 함수를 쓴다. 웹 `pages/dutch-pay/model` 과 같은 규칙이다.

/// 정산 날짜 내림 — 진행 중 · 완료 모두(웹 · 앱 한 정렬).
List<DutchPay> dutchSorted(Iterable<DutchPay> items, {required bool settled}) =>
    [
      for (final d in items)
        if (d.isSettled == settled) d,
    ]..sort((a, b) => (b.dutchPayDate ?? '').compareTo(a.dutchPayDate ?? ''));

/// 받을 돈 — 진행 중 정산의 안 낸 참여자 몫의 합과 사람 수(지금 셈 그대로).
({int amount, int count}) dutchReceivable(Iterable<DutchPay> active) {
  var amount = 0;
  var count = 0;
  for (final d in active) {
    for (final p in d.participants) {
      // 서버는 결제자를 isPaid=N 으로 두지만 갚을 사람이 아니다
      if (!p.isPaid && !p.isPayer) {
        amount += p.amount;
        count++;
      }
    }
  }
  return (amount: amount, count: count);
}

/// 친구 한 명 — 이름 기준 집계.
class DutchFriend {
  DutchFriend(this.name);
  final String name;
  int sessions = 0;

  /// 그 친구에게서 받을 돈(안 낸 몫의 합).
  int net = 0;
}

/// participantName(빈 글 제외) 기준 집계 — 함께 한 횟수가 많은 차례, 같으면 받을 돈.
List<DutchFriend> dutchFriends(Iterable<DutchPay> items) {
  final map = <String, DutchFriend>{};
  for (final d in items) {
    for (final p in d.participants) {
      final name = (p.participantName ?? '').trim();
      if (name.isEmpty || p.isPayer) continue;
      final f = map.putIfAbsent(name, () => DutchFriend(name));
      f.sessions++;
      if (!d.isSettled && !p.isPaid) f.net += p.amount;
    }
  }
  return map.values.toList()..sort((a, b) {
    if (a.sessions != b.sessions) return b.sessions.compareTo(a.sessions);
    return b.net.compareTo(a.net);
  });
}

/// 낸 수 = **결제자 + 낸 사람**(서버는 결제자를 `isPaid = N` 으로 만든다 — 결제자만 낸 정산이 "0/4" 로 보이던 셈을 고친다).
int dutchPaidCount(DutchPay d) =>
    d.participants.where((p) => p.isPayer || p.isPaid).length;

/// "1인당" 글 — 가장 작은 몫을 [each] 로 둔다. 몫이 모두 같으면 [each] 만, 딱 한 사람만 [each] + r (r < 인원)이면 그 사람과 r,
/// 그 밖(비율 · 직접 입력)은 [shown] = false 로 "1인당" 조각을 뺀다. 웹과 같은 꼴이다.
class DutchPerPerson {
  const DutchPerPerson(
    this.each, {
    this.restName,
    this.rest = 0,
    this.shown = true,
  });
  final int each;
  final String? restName;
  final int rest;
  final bool shown;
  bool get even => restName == null;
}

/// 저장된 몫과 이름으로 셈 — 목록 · 만들기 · 상세가 같은 함수를 쓴다.
DutchPerPerson dutchPerPersonOf(List<int> shares, List<String> names) {
  if (shares.isEmpty) return const DutchPerPerson(0, shown: false);
  final m = shares.reduce((a, b) => a < b ? a : b);
  final over = [
    for (var i = 0; i < shares.length; i++)
      if (shares[i] != m) i,
  ];
  if (over.isEmpty) return DutchPerPerson(m);
  if (over.length == 1) {
    final r = shares[over.first] - m;
    if (r < shares.length) {
      return DutchPerPerson(m, restName: names[over.first].trim(), rest: r);
    }
  }
  return DutchPerPerson(m, shown: false);
}

DutchPerPerson dutchPerPerson(DutchPay d) => dutchPerPersonOf(
  [for (final p in d.participants) p.amount],
  [for (final p in d.participants) p.participantName ?? ''],
);

/// 정산 날짜 — 올해는 줄임 "10월 14일", 다른 해는 표준 "2025년 10월 14일". 해를 버리지 않고 날짜 글을 통째로 읽는다(앱 "2000년" 결함).
String dutchDateLabel(String? raw, {DateTime? now}) {
  final s = (raw ?? '').trim();
  if (s.length < 10) return '';
  final d = DateTime.tryParse(s.substring(0, 10));
  if (d == null) return '';
  return d.year == (now ?? DateTime.now()).year ? monthDay(d) : fullDate(d);
}

/// 상세 날짜 — 요일 붙임 "10월 20일 (화)" · 다른 해 "2025년 10월 20일 (월)".
String dutchDateDowLabel(String? raw) {
  final s = (raw ?? '').trim();
  if (s.length < 10) return '';
  final d = DateTime.tryParse(s.substring(0, 10));
  return d == null ? '' : monthDayDow(d);
}
