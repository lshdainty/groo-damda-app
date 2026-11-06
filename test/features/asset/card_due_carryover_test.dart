// 결제 대기 청구분 칸(2026-09-22 사용자 결정).
//
// 결제일 전에 카드를 등록하면 실제 카드사는 지난달 청구분을 다가오는 결제일에, 이번 달 쓴
// 금액을 그다음 결제일에 뺀다. 한 칸으로 받으면 전부 다음 달 결제일에 빠져 한 달 동안 통장
// 잔액이 실제보다 많았다. 그래서 칸을 둘로 나눈다(웹 lshdainty/porest-desk-front#421,
// 서버 lshdainty/porest-desk-back#358).
//
// 여기서 잠그는 것은 넷이다.
//   ① 창 계산 — 오늘이 이번 달 결제일 **전**일 때만 연다. 결제일 당일은 이미 닫힌 회차다(D2).
//      서버 `dueCycleFor` · 웹 `pendingBillWindow` 와 같은 규칙이다
//   ② 새 카드 — 칸 이름·안내에 두 결제일이 들어가고, 청구분은 있을 때만 싣는다
//   ③ 기존 카드 — 서버가 칸을 줄 때만 보인다. 열려 있으면 0 까지 싣고(서버가 지운다),
//      잠겼으면 키째 뺀다(D15 와 같다)
//   ④ 응답을 읽고, 본문에 키가 실린다
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/core/network/patch.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/data/asset_repository.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/presentation/card_add_dialog.dart';
import 'package:groo_damda_app/features/card/application/card_providers.dart';
import 'package:groo_damda_app/features/card/domain/card_catalog.dart';
import 'package:groo_damda_app/features/card/domain/card_catalog_page.dart';
import 'package:groo_damda_app/features/expense/domain/card_cycle.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_form_sheet.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/select/p_select.dart';

import '../../support/plain_text.dart';
import 'asset_form_test_helpers.dart';

/// 오늘 — 9월 3일. 결제일 7일이면 8월분이 9월 7일을 기다린다. (결제일 목록은 드롭다운이라
/// 아래쪽 날짜는 스크롤해야 만들어진다 — 위쪽 날짜만 쓴다.)
final _today = DateTime(2026, 9, 3, 12);

/// 기존 신용카드 — 8월분 12만이 9월 25일을 기다린다(등록한 달의 그 회차가 아직 열려 있다).
const _credit = Asset(
  rowId: 7,
  assetName: '신한 Deep Dream',
  assetType: 'CREDIT_CARD',
  balance: -129000,
  institution: '신한카드',
  isIncludedInTotal: 'Y',
  paymentDay: 25,
  carryoverAmount: 9000,
  dueCarryover: DueCarryover(amount: 120000, paymentDate: '2026-09-25'),
);

const _bank = Asset(
  rowId: 8,
  assetName: 'QA 주거래',
  assetType: 'BANK_ACCOUNT',
  balance: 100,
);

const _catalog = CardCatalogPage(
  content: [
    CardCatalogSummary(
      rowId: 101,
      cardName: 'QA 신용카드',
      cardType: 'CREDIT',
      company: CardCompany(rowId: 1, name: '신한카드'),
    ),
  ],
  totalElements: 1,
  totalPages: 1,
  number: 0,
  size: 40,
  first: true,
  last: true,
  empty: false,
);

/// 화면이 넘긴 인자를 그대로 잡아 둔다.
class _Repo extends AssetRepository {
  _Repo() : super(Dio());

  Map<String, Object?>? created;
  Map<String, Object?>? updated;

  @override
  Future<Asset> create({
    required String assetName,
    required String assetType,
    int? balance,
    String? currency,
    double? exchangeRate,
    String? color,
    String? institution,
    String? memo,
    String? isIncludedInTotal,
    String? isAmountHidden,
    int? sortOrder,
    int? cardCatalogRowId,
    int? creditLimit,
    int? paymentDay,
    int? paymentAssetRowId,
    bool? isOverdraft,
    List<AssetHolding>? holdings,
    int? dueCarryoverAmount,
    bool silent = false,
  }) async {
    created = {
      'balance': balance,
      'paymentDay': paymentDay,
      'dueCarryoverAmount': dueCarryoverAmount,
    };
    return _credit;
  }

  @override
  Future<Asset> update({
    required int id,
    required String assetName,
    required String assetType,
    int? balance,
    String? currency,
    Patch<double> exchangeRate = const Patch.keep(),
    String? color,
    String? institution,
    Patch<String> memo = const Patch.keep(),
    String? isIncludedInTotal,
    String? isAmountHidden,
    int? cardCatalogRowId,
    Patch<int> creditLimit = const Patch.keep(),
    Patch<int> paymentDay = const Patch.keep(),
    Patch<int> paymentAssetRowId = const Patch.keep(),
    bool? isOverdraft,
    List<AssetHolding>? holdings,
    int? carryoverAmount,
    int? dueCarryoverAmount,
    bool silent = false,
  }) async {
    updated = {
      'carryoverAmount': carryoverAmount,
      'dueCarryoverAmount': dueCarryoverAmount,
    };
    return _credit;
  }
}

/// 요청 바디를 잡아 두는 Dio(put_clear_payload_test 패턴).
(Dio, List<Map<String, dynamic>>) _capturingDio() {
  final captured = <Map<String, dynamic>>[];
  final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        captured.add((options.data as Map).cast<String, dynamic>());
        handler.resolve(
          Response<Map<String, dynamic>>(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'code': 'COMMON_200',
              'message': 'OK',
              'data': {
                'rowId': 7,
                'assetName': 'x',
                'assetType': 'CREDIT_CARD',
              },
            },
          ),
        );
      },
    ),
  );
  return (dio, captured);
}

String _md(String key) => monthDay(DateTime.parse(key));

Finder get _dueInput => find.descendant(
  of: find.byKey(const ValueKey('due-carryover-input')),
  matching: find.byType(TextField),
);

/// 금액 칸들(placeholder `0`) — 청구분 칸이 있으면 첫째가 청구분, 마지막이 그 뒤 쓴 금액이다.
/// 결제 대기 청구분 칸 — 라벨이 "{날짜}에 결제될 금액" 이다.
Finder get _dueField => find.byWidgetPredicate(
  (w) => w is PField && (w.label ?? '').contains('에 결제될 금액'),
  description: '결제 대기 청구분 칸',
);

Finder _submitButton(String label) => buttonLabeled(label);

/// 첫 Select 가 결제일이다(둘째는 결제 출금계좌) — 31줄 목록이라 보이는 자리까지 굴려서 고른다.
Future<void> _pickDay(WidgetTester tester, int day) async {
  await tester.tap(find.byType(PSelect<int>).first);
  await tester.pumpAndSettle();
  await tester.ensureVisible(findPlain('$day일').last);
  await tester.pumpAndSettle();
  await tester.tap(findPlain('$day일').last);
  await tester.pumpAndSettle();
}

Future<_Repo> _host(
  WidgetTester tester,
  void Function(BuildContext ctx) open, {
  DateTime? today,
}) async {
  final repo = _Repo();
  // 시트 본문은 ListView 다 — 좁은 화면에서는 아래쪽 칸이 아예 안 만들어진다.
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final now = today ?? _today;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        assetsProvider.overrideWith((ref) async => const [_credit, _bank]),
        assetRepositoryProvider.overrideWith((ref) async => repo),
        cardCatalogPageProvider.overrideWith((ref, key) async => _catalog),
        cardFormClockProvider.overrideWithValue(() => now),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => open(ctx),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(findText('open'));
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  late AppLocalizations l;
  setUpAll(() async {
    l = await AppLocalizations.delegate.load(const Locale('ko'));
  });

  group('창 계산 — 오늘이 이번 달 결제일 전일 때만', () {
    test('결제일 전이면 다가오는 결제일과 그다음 결제일을 준다', () {
      expect(pendingBillWindow('2026-09-10', 14), (
        dueDate: '2026-09-14',
        afterDate: '2026-10-14',
      ));
    });

    test('결제일 당일부터는 없다 — 그 회차는 이미 닫혔다(D2)', () {
      expect(pendingBillWindow('2026-09-14', 14), isNull);
      expect(pendingBillWindow('2026-09-13', 14), isNotNull);
    });

    test('결제일이 지났거나 없으면 없다', () {
      expect(pendingBillWindow('2026-09-20', 14), isNull);
      expect(pendingBillWindow('2026-09-10', null), isNull);
      expect(pendingBillWindow('2026-09-10', 0), isNull);
    });

    test('1월에는 작년 12월 회차가 기다린다', () {
      expect(pendingBillWindow('2027-01-05', 25), (
        dueDate: '2027-01-25',
        afterDate: '2027-02-25',
      ));
    });

    test('짧은 달은 말일로 당긴다', () {
      expect(pendingBillWindow('2026-02-10', 31), (
        dueDate: '2026-02-28',
        afterDate: '2026-03-31',
      ));
    });
  });

  group('응답·본문', () {
    test('응답의 dueCarryover 를 읽는다 — 없으면 null(옛 서버)', () {
      final a = Asset.fromJson({
        'rowId': 7,
        'assetName': 'x',
        'assetType': 'CREDIT_CARD',
        'dueCarryover': {
          'amount': 120000,
          'locked': true,
          'paymentDate': '2026-09-25',
        },
      });
      expect(a.dueCarryover!.amount, 120000);
      expect(a.dueCarryover!.locked, isTrue);
      expect(a.dueCarryover!.paymentDate, '2026-09-25');

      final old = Asset.fromJson({
        'rowId': 7,
        'assetName': 'x',
        'assetType': 'CREDIT_CARD',
      });
      expect(old.dueCarryover, isNull);
    });

    test('만들 때 청구분을 주면 키가 실리고, 안 주면 키가 없다', () async {
      final (dio, captured) = _capturingDio();
      final repo = AssetRepository(dio);
      await repo.create(
        assetName: 'x',
        assetType: 'CREDIT_CARD',
        balance: -50000,
        dueCarryoverAmount: 300000,
      );
      await repo.create(assetName: 'x', assetType: 'CREDIT_CARD');
      expect(captured[0]['dueCarryoverAmount'], 300000);
      expect(captured[1].containsKey('dueCarryoverAmount'), isFalse);
    });

    test('고칠 때 0 은 실리고(서버가 지운다), null 이면 키가 없다(유지)', () async {
      final (dio, captured) = _capturingDio();
      final repo = AssetRepository(dio);
      await repo.update(
        id: 7,
        assetName: 'x',
        assetType: 'CREDIT_CARD',
        dueCarryoverAmount: 0,
      );
      await repo.update(id: 7, assetName: 'x', assetType: 'CREDIT_CARD');
      expect(captured[0]['dueCarryoverAmount'], 0);
      expect(captured[1].containsKey('dueCarryoverAmount'), isFalse);
    });
  });

  group('새 카드', () {
    Future<void> pickCard(WidgetTester tester) =>
        pickCardProduct(tester, l.assetCardProduct, 'QA 신용카드');

    Future<void> pickDay(WidgetTester tester, int day, {int? from}) =>
        _pickDay(tester, day);

    testWidgets('결제일을 고르기 전에는 칸이 하나다', (tester) async {
      await _host(tester, showCardAddDialog);
      expect(_dueField, findsNothing);
      expect(fieldWithLabel(l.assetCurrentUsage), findsOneWidget);
    });

    testWidgets('결제일 전이면 두 칸 — 두 결제일이 칸 이름·안내에 들어간다', (tester) async {
      await _host(tester, showCardAddDialog);
      await pickDay(tester, 7);

      expect(fieldWithLabel('${_md('2026-09-07')}에 결제될 금액'), findsOneWidget);
      expect(
        findRichPlain("카드사 앱에 '결제 예정 금액'으로 보이는 금액이에요. 그날 결제계좌에서 빠져요."),
        findsOneWidget,
      );
      expect(fieldWithLabel('그 뒤 쓴 금액'), findsOneWidget);
      expect(
        findRichPlain('지난 청구 뒤로 쓴 금액이에요. ${_md('2026-10-07')}에 결제돼요.'),
        findsOneWidget,
      );
      expect(fieldWithLabel(l.assetCurrentUsage), findsNothing);
    });

    testWidgets('저장하면 청구분은 dueCarryoverAmount, 그 뒤 쓴 금액은 balance 로 간다', (
      tester,
    ) async {
      final repo = await _host(tester, showCardAddDialog);
      await pickCard(tester);
      await pickDay(tester, 7);
      await tester.enterText(_dueInput, '300000');
      await typeInto(tester, l.assetCarryoverAfterLabel, '50000');
      await tester.tap(_submitButton(l.calAdd));
      await tester.pumpAndSettle();

      expect(repo.created, isNotNull, reason: '생성이 안 불렸다');
      expect(repo.created!['dueCarryoverAmount'], 300000);
      expect(repo.created!['balance'], -50000, reason: '그 뒤 쓴 금액만 잔액(음수)으로 간다');
      expect(repo.created!['paymentDay'], 7);
    });

    testWidgets('청구분이 0 이면 키를 안 싣는다 — 종전 한 칸과 같다', (tester) async {
      final repo = await _host(tester, showCardAddDialog);
      await pickCard(tester);
      await pickDay(tester, 7);
      await typeInto(tester, l.assetCarryoverAfterLabel, '50000');
      await tester.tap(_submitButton(l.calAdd));
      await tester.pumpAndSettle();

      expect(repo.created!['dueCarryoverAmount'], isNull);
      expect(repo.created!['balance'], -50000);
    });

    testWidgets('이미 지난 결제일로 바꾸면 한 칸 — 적어 둔 청구분도 안 싣는다', (tester) async {
      final repo = await _host(tester, showCardAddDialog);
      await pickCard(tester);
      await pickDay(tester, 7);
      await tester.enterText(_dueInput, '300000');
      await tester.pumpAndSettle();

      // 9월 2일은 이미 지났다 — 8월분은 결제가 끝났다.
      await pickDay(tester, 2, from: 7);
      expect(_dueField, findsNothing);
      expect(fieldWithLabel(l.assetCurrentUsage), findsOneWidget);

      await typeInto(tester, l.assetCurrentUsage, '50000');
      await tester.tap(_submitButton(l.calAdd));
      await tester.pumpAndSettle();

      expect(repo.created!['dueCarryoverAmount'], isNull);
      expect(repo.created!['balance'], -50000);
    });

    testWidgets('결제일 당일에 등록하면 한 칸이다(D2)', (tester) async {
      await _host(tester, showCardAddDialog, today: DateTime(2026, 9, 7, 9));
      await pickDay(tester, 7);
      expect(_dueField, findsNothing);
    });
  });

  group('기존 카드', () {
    testWidgets('서버가 칸을 주면 채워서 연다 — 그 뒤 쓴 금액 안내엔 날짜가 없다', (tester) async {
      await _host(tester, (ctx) => showCardEditDialog(ctx, _credit));

      expect(fieldWithLabel('${_md('2026-09-25')}에 결제될 금액'), findsOneWidget);
      expect(tester.widget<TextField>(_dueInput).controller!.text, '120,000');
      expect(textOf(tester, l.assetCarryoverAfterLabel), '9,000');
      expect(fieldWithLabel('그 뒤 쓴 금액'), findsOneWidget);
      expect(findRichPlain('지난 청구 뒤로 쓴 금액이에요.'), findsOneWidget);
    });

    testWidgets('그대로 저장하면 같은 값을 싣는다', (tester) async {
      final repo = await _host(
        tester,
        (ctx) => showCardEditDialog(ctx, _credit),
      );
      await tester.tap(_submitButton(l.actionSave));
      await tester.pumpAndSettle();

      expect(repo.updated!['dueCarryoverAmount'], 120000);
      expect(repo.updated!['carryoverAmount'], 9000);
    });

    testWidgets('비우고 저장하면 0 을 싣는다 — 서버가 청구분을 지운다', (tester) async {
      final repo = await _host(
        tester,
        (ctx) => showCardEditDialog(ctx, _credit),
      );
      await tester.enterText(_dueInput, '');
      await tester.pumpAndSettle();
      await tester.tap(_submitButton(l.actionSave));
      await tester.pumpAndSettle();

      expect(repo.updated!['dueCarryoverAmount'], 0);
    });

    testWidgets('그 회차 결제일이 됐으면 읽기 전용이고 키를 안 싣는다(D15)', (tester) async {
      final locked = _credit.copyWith(
        dueCarryover: const DueCarryover(
          amount: 120000,
          locked: true,
          paymentDate: '2026-09-25',
        ),
      );
      final repo = await _host(
        tester,
        (ctx) => showCardEditDialog(ctx, locked),
      );

      expect(
        tester
            .widget<PInput>(find.byKey(const ValueKey('due-carryover-input')))
            .readOnly,
        isTrue,
      );
      expect(findRichPlain(l.assetCarryoverLocked), findsOneWidget);
      await tester.tap(_submitButton(l.actionSave));
      await tester.pumpAndSettle();
      expect(repo.updated!['dueCarryoverAmount'], isNull);
    });

    testWidgets('서버가 칸을 안 주면(옛 서버 포함) 칸도 키도 없다', (tester) async {
      final repo = await _host(
        tester,
        (ctx) => showCardEditDialog(ctx, _credit.copyWith(dueCarryover: null)),
      );
      expect(_dueField, findsNothing);
      expect(fieldWithLabel(l.assetCurrentUsage), findsOneWidget);

      await tester.tap(_submitButton(l.actionSave));
      await tester.pumpAndSettle();
      expect(repo.updated!['dueCarryoverAmount'], isNull);
    });

    testWidgets('체크카드로 바꾸면 칸이 사라지고 키도 없다', (tester) async {
      final repo = await _host(
        tester,
        (ctx) => showCardEditDialog(ctx, _credit),
      );
      await tester.tap(findPlain(l.assetTypeCheckCard));
      await tester.pumpAndSettle();
      expect(_dueField, findsNothing);

      await tester.tap(_submitButton(l.actionSave));
      await tester.pumpAndSettle();
      expect(repo.updated!['dueCarryoverAmount'], isNull);
    });
  });

  // 결제일을 말하는 문장은 웹처럼 연도를 안 붙인다(QA 28 4). 앱 formatDay 는 올해가 아니면
  // 연도를 붙여서 12월에 "2027년 1월 7일에 결제돼요" 가 됐다 — 웹은 "1월 7일에 결제돼요".
  group('12월 — 결제일 문장에 연도가 없다', () {
    testWidgets('새 카드 안내: 그다음 결제일이 내년 1월이어도 "1월 7일"', (tester) async {
      await _host(tester, showCardAddDialog, today: DateTime(2026, 12, 3, 9));
      await _pickDay(tester, 7);

      expect(fieldWithLabel('12월 7일에 결제될 금액'), findsOneWidget);
      expect(findRichPlain('지난 청구 뒤로 쓴 금액이에요. 1월 7일에 결제돼요.'), findsOneWidget);
      expect(findTextContaining('2027년'), findsNothing);
    });

    testWidgets('결제일 변경 확인창: "12월분은 1월 25일에 결제돼요"', (tester) async {
      // 12/28 — 11월분은 12/25 에 결제가 끝났고, 12월분이 옛 결제일(25일)인 1/25 에 나간다.
      await _host(
        tester,
        (ctx) => showCardEditDialog(
          ctx,
          _credit.copyWith(dueCarryover: null, cardClosedThrough: '2026-11-30'),
        ),
        today: DateTime(2026, 12, 28, 9),
      );
      await _pickDay(tester, 5);
      await tester.tap(_submitButton(l.actionSave));
      await tester.pumpAndSettle();

      expect(
        findRichPlain('바꾼 결제일은 다음 회차부터 적용돼요. 12월분은 1월 25일에 결제돼요.'),
        findsOneWidget,
      );
    });
  });
}
