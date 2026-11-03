// 고쳐 쓰기 확인창 글(`rewriteConfirmMessage`) — 새 거래가 닫힌 회차 · 열린 회차 · 결제일 변경 대기 회차에 떨어질 때 무엇을 말하나.
// 날짜를 글로 쳐서 바꾸던 폼 시험(money_lock_rewrite 의 두 케이스)이 달력 고르기로 바뀌며 지워져, 같은 뜻을 단위로 옮겼다(I-21 21-2 앱 M).
// 작성만 했다 — 돌리지 않는다.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/expense/presentation/closed_cycle_notice.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';

/// 결제일 12일 카드 — 8월분(9/12 결제)까지 닫혔다.
const _card = Asset(
  rowId: 9,
  assetName: '현대카드',
  assetType: 'CREDIT_CARD',
  balance: -125000,
  paymentDay: 12,
  paymentAssetRowId: 3,
  cardClosedThrough: '2026-08-31',
);

void main() {
  late AppLocalizations l;
  setUpAll(() async {
    l = await AppLocalizations.delegate.load(const Locale('ko'));
  });

  test('닫힌 회차로 떨어지면 기록만 바뀐다고 말한다', () {
    final m = rewriteConfirmMessage(l, newAsset: _card, dateKey: '2026-08-20');
    expect(m, '${l.expRewriteConfirmLead} ${l.expRewriteConfirmClosed}');
  });

  test('열린 회차로 옮기면 그 회차 결제일에 청구된다고 말한다', () {
    final m = rewriteConfirmMessage(l, newAsset: _card, dateKey: '2026-09-10');
    expect(
      m,
      '${l.expRewriteConfirmLead} ${l.expRewriteConfirmOpen(monthDay(DateTime(2026, 10, 12)))}',
    );
    expect(m, isNot(contains(l.expRewriteConfirmClosed)));
  });

  test('결제일 변경이 대기 중이면 서버가 준 그 회차의 결제일을 말한다', () {
    // 서버가 이 회차를 옛 결제일(10/5)에 내보낸다고 알려 줬다 — 지금 결제일(12일)로 세지 않는다.
    final pending = _card.copyWith(nextPaymentDate: '2026-10-05');
    final m = rewriteConfirmMessage(
      l,
      newAsset: pending,
      dateKey: '2026-09-10',
    );
    expect(
      m,
      '${l.expRewriteConfirmLead} ${l.expRewriteConfirmOpen(monthDay(DateTime(2026, 10, 5)))}',
    );
  });

  test('카드가 아니거나 자산이 없으면 첫 문장만', () {
    expect(
      rewriteConfirmMessage(l, newAsset: null, dateKey: '2026-09-10'),
      l.expRewriteConfirmLead,
    );
  });
}
