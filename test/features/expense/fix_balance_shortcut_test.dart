// [잔액 고치기] — 결제가 끝난 회차 거래를 바꾼 뒤 결제계좌 수정 폼으로 바로 간다(D9).
//
// 닫힌 회차의 변경은 통장을 안 움직인다. 카드사가 실제로 돈을 돌려줬으면 사용자가
// 결제계좌 잔액을 고쳐야 하는데, 그 폼까지 다섯 번 안팎을 눌러야 했다. 여기서 잠그는 것은
//   ① 닫힌 회차 거래를 지우면 토스트에 [잔액 고치기] — 누르면 `?edit=<결제계좌>` 로 간다
//   ② 결제계좌가 없거나 열린 회차면 그 버튼이 없다
//   ③ 상세 "환불됨" 배너에도 같은 버튼 — 시트를 닫고 같은 곳으로 간다
//   ④ 그 주소로 들어오면 관리 화면이 그 자산의 수정 폼을 바로 연다(탭도 옮긴다)
//   ⑤ 자산 상세 [수정]도 같은 주소를 쓴다
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/domain/asset_transfer.dart';
import 'package:groo_damda_app/features/asset/presentation/account_card_manage_screen.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_detail_dialog.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_edit_route.dart';
import 'package:groo_damda_app/features/card/application/card_providers.dart';
import 'package:groo_damda_app/features/card/domain/card_catalog_page.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/data/expense_repository.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/expense/presentation/expense_actions.dart';
import 'package:groo_damda_app/features/expense/presentation/tx_detail_dialog.dart';
import 'package:groo_damda_app/features/dutch_pay/application/dutch_pay_providers.dart';
import 'package:groo_damda_app/features/expense_split/application/expense_split_providers.dart';
import 'package:groo_damda_app/features/recurring/application/recurring_providers.dart';
import 'package:groo_damda_app/features/notification/application/user_preferences_providers.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/swipe_actions/p_swipe_actions.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';
import '../../support/plain_text.dart';

const _card = Asset(
  rowId: 9,
  assetName: '현대카드',
  assetType: 'CREDIT_CARD',
  balance: -125000,
  paymentDay: 12,
  paymentAssetRowId: 3,
  cardClosedThrough: '2026-08-31',
);

const _account = Asset(
  rowId: 3,
  assetName: '생활비 통장',
  assetType: 'BANK_ACCOUNT',
  balance: 1200000,
  isIncludedInTotal: 'Y',
);

const _closed = Expense(
  rowId: 77,
  categoryRowId: 11,
  categoryName: '교통',
  assetRowId: 9,
  assetName: '현대카드',
  expenseType: 'EXPENSE',
  amount: 58600,
  merchant: '버스',
  expenseDate: '2026-08-20T10:00:00',
);

const _emptyPage = CardCatalogPage(
  content: [],
  totalElements: 0,
  totalPages: 0,
  number: 0,
  size: 40,
  first: true,
  last: true,
  empty: true,
);

class _FakeRepo extends ExpenseRepository {
  _FakeRepo() : super(Dio(BaseOptions(baseUrl: 'https://example.invalid')));

  @override
  Future<int?> delete(int id, {bool silent = false}) async => null;
}

/// 라우터를 단 앱 — `/` 에 [home], 관리 화면 자리에는 들어온 주소를 적는 표지만 둔다.
Future<void> _pumpRouted(
  WidgetTester tester,
  Widget home, {
  List<Asset> assets = const [_card, _account],
}) async {
  tester.view.physicalSize = const Size(1500, 2600);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(body: PSwipeActionsProvider(child: home)),
      ),
      GoRoute(
        path: '/account-card-manage',
        builder: (_, state) => Scaffold(
          body: Text('관리 edit=${state.uri.queryParameters['edit']}'),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        expenseRepositoryProvider.overrideWith((ref) async => _FakeRepo()),
        assetsProvider.overrideWith((ref) async => assets),
        categoriesProvider.overrideWith((ref) async => const []),
        expenseSplitsProvider.overrideWith((ref, id) async => const []),
        merchantMonthExpensesProvider.overrideWith(
          (ref, key) async => const [],
        ),
        recurringListProvider.overrideWith((ref) async => const []),
        dutchPayListProvider.overrideWith((ref) async => const []),
        hideCardProvider.overrideWith((ref, card) => false),
        // 지우기 · 환불 뒤 그 달 목록을 다시 받을 때까지 기다린다(1a9d9de7) — 가짜 저장소에 list 가 없어 덮는다
        monthExpensesProvider.overrideWith((ref, key) async => const []),
      ],
      child: MaterialApp.router(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        // 앱과 같은 자리 — 결과 스낵바(ds)가 뜨는 호스트
        builder: (context, child) => Material(
          type: MaterialType.transparency,
          child: PSnackbarHost(closeLabel: '닫기', child: child!),
        ),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Widget _swipeRow(Expense e, Asset asset) => Consumer(
  builder: (ctx, ref, _) => PSwipeActions(
    actions: expenseActions.dsSwipeActions(ctx, ref, e, asset: asset),
    child: const SizedBox(
      height: 64,
      width: double.infinity,
      child: Text('거래 행'),
    ),
  ),
);

Future<void> _swipeDeleteAndConfirm(WidgetTester tester) async {
  await tester.drag(findText('거래 행'), const Offset(-300, 0));
  await tester.pumpAndSettle();
  await tester.tap(findText('삭제'));
  await tester.pumpAndSettle();
  await tester.tap(findText('삭제').last);
  await tester.pumpAndSettle();
}

void main() {
  test('주소는 관리 화면 + 자산 id 다', () {
    expect(assetEditLocation(3), '/account-card-manage?edit=3');
  });

  group('토스트의 [잔액 고치기]', () {
    testWidgets('닫힌 회차 거래를 지우면 결제계좌 수정 폼으로 가는 버튼이 뜬다', (tester) async {
      await _pumpRouted(tester, _swipeRow(_closed, _card));

      await _swipeDeleteAndConfirm(tester);
      expect(findText('결제가 끝난 회차라 기록만 바뀌고 계좌 잔액은 그대로예요.'), findsOneWidget);

      await tester.tap(findText('잔액 고치기'));
      await tester.pumpAndSettle();

      // push 라 기준 주소는 그대로고, 그 위에 관리 화면이 `?edit=3` 으로 올라온다.
      expect(findText('관리 edit=3'), findsOneWidget);
    });

    testWidgets('결제계좌가 없는 카드면 버튼도 토스트도 없다', (tester) async {
      final noAccount = _card.copyWith(paymentAssetRowId: null);
      await _pumpRouted(
        tester,
        _swipeRow(_closed, noAccount),
        assets: [noAccount],
      );

      await _swipeDeleteAndConfirm(tester);

      expect(findText('잔액 고치기'), findsNothing);
      expect(findText('결제가 끝난 회차라 기록만 바뀌고 계좌 잔액은 그대로예요.'), findsNothing);
    });

    testWidgets('열린 회차 거래는 버튼이 없다', (tester) async {
      final open = _closed.copyWith(expenseDate: '2026-09-10T10:00:00');
      await _pumpRouted(tester, _swipeRow(open, _card));

      await _swipeDeleteAndConfirm(tester);

      expect(findText('잔액 고치기'), findsNothing);
    });
  });

  group('환불됨 배너의 [잔액 고치기]', () {
    Widget opener(Expense e) => Builder(
      builder: (ctx) => TextButton(
        onPressed: () => showTxDetailDialog(ctx, e),
        child: const Text('open'),
      ),
    );

    testWidgets('닫힌 회차 환불이면 배너에 있고, 누르면 시트를 닫고 간다', (tester) async {
      await _pumpRouted(
        tester,
        opener(_closed.copyWith(refundedAt: '2026-09-15T12:00:00')),
      );
      await tester.tap(findText('open'));
      await tester.pumpAndSettle();

      expect(findText('환불 취소'), findsOneWidget);
      await tester.tap(findText('잔액 고치기'));
      await tester.pumpAndSettle();

      expect(findText('관리 edit=3'), findsOneWidget);
      expect(findText('환불 취소'), findsNothing, reason: '상세 시트는 닫혔다');
    });

    testWidgets('열린 회차 환불이면 배너에 없다', (tester) async {
      await _pumpRouted(
        tester,
        opener(
          _closed.copyWith(
            expenseDate: '2026-09-10T10:00:00',
            refundedAt: '2026-09-15T12:00:00',
          ),
        ),
      );
      await tester.tap(findText('open'));
      await tester.pumpAndSettle();

      expect(findText('환불 취소'), findsOneWidget);
      expect(findText('잔액 고치기'), findsNothing);
    });
  });

  group('관리 화면 ?edit=', () {
    Future<void> pumpManage(WidgetTester tester, {int? editAssetId}) async {
      tester.view.physicalSize = const Size(1500, 2600);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            assetsProvider.overrideWith((ref) async => const [_card, _account]),
            hideCardProvider.overrideWith((ref, card) => false),
            defaultCurrencyProvider.overrideWith((ref) => 'KRW'),
            // 카드 폼은 상품 목록을 부른다 — 비워 두지 않으면 로딩이 안 끝난다.
            cardCatalogPageProvider.overrideWith(
              (ref, key) async => _emptyPage,
            ),
          ],
          child: MaterialApp(
            theme: GrooTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            // 앱과 같은 자리 — 결과 스낵바(ds)가 뜨는 호스트
            builder: (context, child) => Material(
              type: MaterialType.transparency,
              child: PSnackbarHost(closeLabel: '닫기', child: child!),
            ),
            home: AccountCardManageScreen(editAssetId: editAssetId),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('그 자산의 수정 폼이 바로 열린다', (tester) async {
      await pumpManage(tester, editAssetId: 3);

      expect(findPlain('입출금 수정'), findsOneWidget);
      expect(findText('1,200,000'), findsOneWidget, reason: '잔액 칸이 채워져 있다');
    });

    testWidgets('카드면 카드 폼을 연다(탭이 없다)', (tester) async {
      await pumpManage(tester, editAssetId: 9);

      expect(findPlainContaining('카드 수정'), findsOneWidget);
    });

    testWidgets('없는 자산이면 목록만 보여 준다', (tester) async {
      await pumpManage(tester, editAssetId: 404);

      expect(findPlain('입출금 수정'), findsNothing);
      expect(findPlain('생활비 통장'), findsOneWidget);
    });

    testWidgets('주소가 없으면 폼을 안 연다', (tester) async {
      await pumpManage(tester);

      expect(findPlain('입출금 수정'), findsNothing);
    });
  });

  // 자산 상세의 조회들(추이·최근 거래·이체)을 비워 두고 [수정] 만 누른다.
  // 16682210 — 자산 상세의 [수정] 은 연필 아이콘이고 화면을 옮기지 않고 그 자리에서 수정 폼을 연다(주소 이동 아님)
  testWidgets('자산 상세 [수정]은 그 자리에서 그 자산의 수정 폼을 연다', (tester) async {
    tester.view.physicalSize = const Size(1500, 2600);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: Builder(
              builder: (ctx) => TextButton(
                onPressed: () => showAssetDetailRich(ctx, _account),
                child: const Text('open'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/account-card-manage',
          builder: (_, state) => Scaffold(
            body: Text('관리 edit=${state.uri.queryParameters['edit']}'),
          ),
        ),
        // 자산 상세는 화면이다(16682210) — 앱 라우터와 같은 주소
        GoRoute(
          path: '/asset/:id',
          builder: (_, state) => AssetDetailScreen(
            assetId: int.parse(state.pathParameters['id']!),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assetsProvider.overrideWith((ref) async => const [_account]),
          hideCardProvider.overrideWith((ref, card) => false),
          assetTransfersProvider.overrideWith(
            (ref, key) async => const <AssetTransfer>[],
          ),
          assetBalanceTrendProvider.overrideWith((ref, key) async => const []),
          expensesByAssetProvider.overrideWith(
            (ref, key) async => const <Expense>[],
          ),
        ],
        child: MaterialApp.router(
          theme: GrooTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          // 앱과 같은 자리 — 결과 스낵바(ds)가 뜨는 호스트
          builder: (context, child) => Material(
            type: MaterialType.transparency,
            child: PSnackbarHost(closeLabel: '닫기', child: child!),
          ),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(findText('open'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is PTopNavigationIconButton && w.label == '수정',
      ),
    );
    await tester.pumpAndSettle();

    expect(findPlain('입출금 수정'), findsOneWidget);
    expect(findText('생활비 통장'), findsWidgets);
    expect(findText('관리 edit=3'), findsNothing);
  });
}
