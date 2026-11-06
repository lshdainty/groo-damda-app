// 계좌·카드 관리(I-17 25 ~ 33, 1-B) — 탭 없는 흰 면 하나 · 묶음 한 목록 · 합계 · 상단 바 "추가" · 불러오기 갈래.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/presentation/account_card_manage_screen.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_parts.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/tabs/p_tabs.dart';

import '../../support/plain_text.dart';

const _bank = Asset(
  rowId: 1,
  assetName: '주거래 통장',
  assetType: 'BANK_ACCOUNT',
  balance: 1000000,
  institution: '국민은행',
  isIncludedInTotal: 'Y',
);
const _usd = Asset(
  rowId: 2,
  assetName: '외화 통장',
  assetType: 'BANK_ACCOUNT',
  balance: 1000,
  currency: 'USD',
  exchangeRate: 1380,
  institution: '우리은행',
  isIncludedInTotal: 'Y',
);
const _excluded = Asset(
  rowId: 3,
  assetName: '제외 통장',
  assetType: 'BANK_ACCOUNT',
  balance: 500000,
  isIncludedInTotal: 'N',
);
const _card = Asset(
  rowId: 4,
  assetName: '생활카드',
  assetType: 'CREDIT_CARD',
  balance: -300000,
  isIncludedInTotal: 'Y',
);
const _loan = Asset(
  rowId: 5,
  assetName: '전세대출',
  assetType: 'LOAN',
  balance: -85000000,
  isIncludedInTotal: 'Y',
);
const _invest = Asset(
  rowId: 6,
  assetName: '주식계좌',
  assetType: 'INVESTMENT',
  balance: 2000000,
  isIncludedInTotal: 'Y',
);

Future<void> _pump(
  WidgetTester tester, {
  Future<List<Asset>> Function()? load,
  List<Asset> assets = const [],
  double scale = 1,
}) async {
  tester.view.physicalSize = const Size(720, 3000);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        assetsProvider.overrideWith(
          (ref) => load?.call() ?? Future.value(assets),
        ),
        hideCardProvider.overrideWith((ref, c) => false),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: const AccountCardManageScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

double _top(WidgetTester t, String title) => t
    .getRect(
      find.byWidgetPredicate(
        (w) =>
            w is Text &&
            w.key == const ValueKey('plist-header-title') &&
            // 목록 제목은 Text.rich 다(075866bc)
            plainOf(w.data ?? w.textSpan!.toPlainText()) == title,
      ),
    )
    .top;

const _longCard = Asset(
  rowId: 8,
  assetName: '생활카드',
  assetType: 'CREDIT_CARD',
  balance: -1250000,
  creditLimit: 3000000,
  paymentDay: 14,
  institution: '삼성카드 프리미엄 파트너스 제휴',
  isIncludedInTotal: 'Y',
);

void main() {
  testWidgets('카드 줄에 한도 막대 · "사용 / 한도" 가 없다 · 줄어드는 것은 기관뿐(종류 · 결제일은 그대로)', (
    tester,
  ) async {
    await _pump(tester, assets: const [_longCard]);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(
      find.byWidgetPredicate((w) => w.runtimeType.toString() == 'PProgress'),
      findsNothing,
    );
    expect(findPlainContaining('3,000,000원'), findsNothing, reason: '한도 글이 없다');
    expect(findPlain('신용카드'), findsOneWidget, reason: '종류 이름이 잘리지 않는다');
    expect(
      findPlainContaining('14일 결제'),
      findsOneWidget,
      reason: '결제일이 잘리지 않는다',
    );
  });

  testWidgets('탭이 없다 · 묶음 차례는 계좌·예금 → 투자 → 카드 → 대출(I-17 25 · 27)', (
    tester,
  ) async {
    await _pump(tester, assets: const [_bank, _card, _loan, _invest]);
    expect(find.byType(PTabs), findsNothing);
    final order = ['계좌 · 예금', '투자', '카드', '대출'];
    final tops = [for (final s in order) _top(tester, s)];
    expect(tops, orderedEquals([...tops]..sort()));
    expect(tops.toSet().length, 4);
  });

  testWidgets('투자 · 대출은 있을 때만 · 계좌·예금 · 카드는 비어도 "없어요" 한 줄', (tester) async {
    await _pump(tester, assets: const [_bank]);
    final l = AppLocalizations.of(
      tester.element(find.byType(AccountCardManageScreen)),
    );
    expect(findPlain('투자'), findsNothing);
    expect(findPlain('대출'), findsNothing);
    expect(findPlain('카드'), findsWidgets);
    expect(findPlain(l.assetGroupEmpty), findsOneWidget);
  });

  testWidgets('합계 — 총액 제외는 빼고 외화는 원화로 환산해 더한다 · 카드 · 대출은 빼기 U+2212(Q4)', (
    tester,
  ) async {
    await _pump(tester, assets: const [_bank, _usd, _excluded, _card, _loan]);
    // 1,000,000 + 1,000 × 1,380 = 2,380,000 (제외 통장 500,000 은 더하지 않는다)
    expect(findPlain('2,380,000원'), findsOneWidget);
    expect(findPlain('−300,000원'), findsWidgets);
    expect(findPlain('−85,000,000원'), findsWidgets);
  });

  testWidgets('줄 끝에 화살표가 없다(Q2 B) · ⋮ 도 없다(10-25 원칙) · 설명은 "{기관} · {종류}"', (
    tester,
  ) async {
    await _pump(tester, assets: const [_bank]);
    expect(find.byIcon(LucideIcons.chevronRight), findsNothing);
    expect(find.byIcon(LucideIcons.ellipsisVertical), findsNothing);
    expect(findPlainContaining('국민은행'), findsOneWidget);
    expect(findPlainContaining('입출금'), findsWidgets);
  });

  testWidgets('상단 바 오른쪽은 글 버튼 "추가" 하나', (tester) async {
    await _pump(tester, assets: const [_bank]);
    expect(findText('추가'), findsOneWidget);
    expect(
      findTextContaining('추가'),
      findsOneWidget,
      reason: '묶음마다 [○○ 추가] 가 없다',
    );
  });

  testWidgets(
    '묶음 제목 글 위치 — 첫 묶음 바 아래 16(8 + 안쪽 8) · 다음 묶음 앞 줄 아래 24(16 + 안쪽 8), 틈 T1 · T2',
    (tester) async {
      await _pump(tester, assets: const [_bank, _card]);
      final nav = tester.getRect(find.byKey(const ValueKey('top-navigation')));
      final heads = find.byKey(const ValueKey('plist-header'));
      expect(
        tester.getRect(heads.first).top - nav.bottom,
        0,
        reason: 'T1 바와 머리 사이 틈 0',
      );
      expect(_top(tester, '계좌 · 예금') - nav.bottom, 16);
      final bankRow = tester.getRect(find.byKey(const ValueKey('asset-row-1')));
      expect(
        _top(tester, '카드') - bankRow.bottom,
        24,
        reason: 'T2 묶음 사이 회색 틈 0 · 제목 글 위 24',
      );
    },
  );

  testWidgets('흰 면 하나 — 바닥은 bg-layer-default', (tester) async {
    await _pump(tester, assets: const [_bank]);
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(
      scaffold.backgroundColor,
      tester.element(find.byType(Scaffold).first).colors.bgLayerDefault,
    );
  });

  testWidgets('불러오는 중 → 스켈레톤(오류 글 없음) · 상단 바는 그대로', (tester) async {
    final never = Completer<List<Asset>>();
    await _pump(tester, load: () => never.future);
    expect(findPlain('계좌·카드를 불러오지 못했어요'), findsNothing);
    expect(findText('추가'), findsOneWidget, reason: '상단 바는 그대로 있다');
  });

  testWidgets('실패 → Result Section + 다시 시도 · 서버 원문을 그리지 않는다', (tester) async {
    await _pump(tester, load: () async => throw Exception('RAW_SERVER_TEXT'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(findPlain('계좌·카드를 불러오지 못했어요'), findsOneWidget);
    expect(findPlain('다시 시도'), findsOneWidget);
    expect(findTextContaining('RAW_SERVER_TEXT'), findsNothing);
  });

  testWidgets('자산 0개 → 빈 Result Section(버튼 없음)', (tester) async {
    await _pump(tester, assets: const []);
    expect(findPlain('아직 등록된 자산이 없어요'), findsOneWidget);
    expect(
      findPlain('[추가]를 눌러 첫 계좌나 카드를 등록해보세요.'),
      findsOneWidget,
      reason: '이 화면 전용 안내 — 자산 화면의 "설정 →" 글이 아니다',
    );
    expect(findPlainContaining('설정 →'), findsNothing);
    expect(findPlain('다시 시도'), findsNothing);
  });

  testWidgets('글자 200% 에서도 넘침 예외가 없다', (tester) async {
    await _pump(
      tester,
      assets: const [_bank, _usd, _excluded, _card, _loan, _invest],
      scale: 2,
    );
    expect(tester.takeException(), isNull);
  });

  // 투자 줄 금액은 자산 화면과 같은 라이브 평가액 치환 함수를 쓴다(예수금 + 평가액) — 두 화면의 값이 같다.
  test('라이브 평가액 치환 — 예수금을 더하고 총액 포함만 delta 에 든다', () {
    const inv = Asset(
      rowId: 7,
      assetName: '연동 증권',
      assetType: 'INVESTMENT',
      balance: 1000000,
      cashBalance: 50000,
      isIncludedInTotal: 'Y',
    );
    final val = {7: 1200000};
    final live = applyLiveValuation([inv, _bank], val);
    expect(live.first.balance, 1250000);
    expect(live.first.holdingBalance, 1200000);
    expect(live.last.balance, _bank.balance);
    expect(liveValuationDelta([inv, _bank], val), 250000);
    expect(
      identical(applyLiveValuation([_bank], const {}).first, _bank),
      isTrue,
    );
  });

  // 외화 투자 자산의 라이브 치환 — 보유 평가 자리만 라이브 원화로, 원화 합계 = round(예수금 × 환율) + 라이브(I-13 길 A).
  // 관리 화면과 자산 화면이 같은 식을 쓰는지 잠근다(balance 는 옛 뜻 예수금 + 보유로 맞춰 둔다).
  test('외화 투자 자산 라이브 치환 — 자산 화면과 같은 식(보유 자리만 라이브, 원화 합계 10,130,000)', () {
    const usdInv = Asset(
      rowId: 8,
      assetName: '해외 증권',
      assetType: 'INVESTMENT',
      balance: 5000,
      cashBalance: 100,
      currency: 'USD',
      exchangeRate: 1300,
      isIncludedInTotal: 'Y',
    );
    final live = applyLiveValuation([usdInv], {8: 10000000});
    expect(live.single.balance, 10000100);
    expect(live.single.holdingBalance, 10000000);
    expect(liveValuationDelta([usdInv], {8: 10000000}), 10000100 - 5000);
    expect(live.single.currency, 'USD', reason: '통화는 바꾸지 않는다');
    expect(live.single.balanceInKrw, 10130000);
    expect(assetSumIncluded(live), 10130000);
  });

  testWidgets('투자 줄에 등락(▲ ▼)이 없다 — 금액만(웹 · 그림과 같다)', (tester) async {
    const inv = Asset(
      rowId: 7,
      assetName: '연동 증권',
      assetType: 'INVESTMENT',
      balance: 1000000,
      isIncludedInTotal: 'Y',
    );
    await _pump(tester, assets: const [inv]);
    expect(find.byKey(const ValueKey('asset-delta-7')), findsNothing);
  });
}
