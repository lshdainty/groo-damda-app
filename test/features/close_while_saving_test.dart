// 저장하는 동안 화면(시트)이 닫혀도 저장 뒤 목록은 갱신된다.
//
// await 뒤에 `ref`(위젯의 것)로 비우던 자리는 화면이 사라지면 StateError 가 나거나
// `mounted` 가드에 걸려 건너뛰어졌다 — 서버는 저장했는데 목록이 옛 값이다(B6 후속 2).
// ProviderScope 는 살려 둔 채 시트만 닫고, **목록 재조회 횟수가 늘어나는지** 본다.
// 꼴마다 하나씩: 폼 시트 성공 · 응답 못 읽은 저장 · ConsumerWidget 단추 · 여러 단계 시트(가계부 이체).
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/network/patch.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/data/asset_repository.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_form_sheet.dart';
import 'package:groo_damda_app/features/calendar/application/calendar_providers.dart';
import 'package:groo_damda_app/features/calendar/data/user_calendar_repository.dart';
import 'package:groo_damda_app/features/calendar/domain/user_calendar.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_filter_sheet.dart';
import 'package:groo_damda_app/features/card/application/card_providers.dart';
import 'package:groo_damda_app/features/card/domain/card_catalog_page.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/expense/presentation/add_tx_sheet.dart';
import 'package:groo_damda_app/features/preset/application/preset_providers.dart';
import 'package:groo_damda_app/features/preset/data/preset_repository.dart';
import 'package:groo_damda_app/features/preset/domain/expense_template.dart';
import 'package:groo_damda_app/features/subscription/application/subscription_providers.dart';
import 'package:groo_damda_app/features/subscription/data/subscription_repository.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';

import '../support/plain_text.dart';
import 'asset/asset_form_test_helpers.dart';

const _account = Asset(
  rowId: 8,
  assetName: 'QA 주거래',
  assetType: 'BANK_ACCOUNT',
  balance: 1200000,
  institution: '국민은행',
  isIncludedInTotal: 'Y',
);
const _savings = Asset(
  rowId: 9,
  assetName: 'QA적금',
  assetType: 'SAVINGS',
  institution: '국민은행',
);
const _preset = ExpenseTemplate(
  rowId: 77,
  templateName: '적금이체',
  expenseType: 'TRANSFER',
  assetRowId: 8,
  toAssetRowId: 9,
  fee: 500,
  lockAmount: 'N',
);
const _category = ExpenseCategory(
  rowId: 5,
  categoryName: '식비',
  expenseType: 'EXPENSE',
  sortOrder: 0,
  icon: 'utensils',
  color: '#2c70bf',
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

/// 저장 응답을 [gate] 가 끝날 때까지 미루는 자산 저장소 — [parse] 면 응답만 못 읽은 저장(PARSE)으로 끝난다.
class _GatedAssetRepo extends AssetRepository {
  _GatedAssetRepo() : super(Dio());
  Completer<void>? gate;
  bool parse = false;

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
    await gate?.future;
    if (parse) {
      throw ApiException(code: kApiParseErrorCode, message: '응답 원문');
    }
    return _account;
  }

  @override
  Future<void> createTransfer({
    required int fromAssetRowId,
    required int toAssetRowId,
    required int amount,
    int? fee,
    int? interestAmount,
    String? description,
    required String transferDate,
    bool silent = false,
  }) async {
    await gate?.future;
  }
}

/// 목록을 계속 보고 있는 자리(탭 셸처럼) — 비우면 곧바로 다시 받는다.
Widget _home(Widget Function(BuildContext) open, ProviderListenable watched) {
  return MaterialApp(
    theme: GrooTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('ko'),
    home: Scaffold(
      body: Consumer(
        builder: (ctx, ref, _) {
          ref.watch(watched);
          return open(ctx);
        },
      ),
    ),
  );
}

void _bigView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1500, 3000);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
}

/// 열려 있는 시트를 코드로 걷는다 — 저장 중에는 사용자가 못 닫아도 라우트는 걷힐 수 있다(로그아웃 · 시스템 뒤로).
Future<void> _dismissSheet(WidgetTester tester) async {
  Navigator.of(tester.element(findText('open'))).pop();
  await tester.pumpAndSettle();
}

void main() {
  late AppLocalizations l;
  setUpAll(() async {
    l = await AppLocalizations.delegate.load(const Locale('ko'));
  });

  Future<(_GatedAssetRepo, List<int>)> openAccountForm(
    WidgetTester tester,
  ) async {
    final repo = _GatedAssetRepo();
    final builds = <int>[];
    _bigView(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assetsProvider.overrideWith((ref) async {
            builds.add(builds.length + 1);
            return [_account];
          }),
          assetRepositoryProvider.overrideWith((ref) async => repo),
          cardCatalogPageProvider.overrideWith((ref, key) async => _emptyPage),
          myFeaturesProvider.overrideWith((ref) async => MyFeatures.empty),
        ],
        child: _home(
          (ctx) => TextButton(
            onPressed: () => showAssetEditForm(ctx, _account),
            child: const Text('open'),
          ),
          assetsProvider,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(findText('open'));
    await tester.pumpAndSettle();
    return (repo, builds);
  }

  testWidgets('폼 시트 — 저장 중에 시트가 닫혀도 저장 뒤 자산 목록을 다시 받는다', (tester) async {
    final (repo, builds) = await openAccountForm(tester);
    expect(builds, hasLength(1));
    repo.gate = Completer<void>();
    await tester.tap(buttonLabeled(l.actionSave));
    await tester.pump();
    await _dismissSheet(tester);
    repo.gate!.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(builds.length, greaterThan(1), reason: '저장 뒤 목록이 갱신되지 않았다');
  });

  testWidgets('폼 시트 — 응답을 못 읽은 저장 뒤 시트가 닫혀 있어도 목록을 다시 받는다', (tester) async {
    final (repo, builds) = await openAccountForm(tester);
    repo.gate = Completer<void>();
    repo.parse = true;
    await tester.tap(buttonLabeled(l.actionSave));
    await tester.pump();
    await _dismissSheet(tester);
    repo.gate!.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(builds.length, greaterThan(1), reason: '서버는 저장했는데 목록이 옛 값이다');
  });

  testWidgets('여러 단계 시트(가계부 이체) — 저장 중에 시트가 닫혀도 자산 목록을 다시 받는다', (tester) async {
    final repo = _GatedAssetRepo();
    final builds = <int>[];
    _bigView(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoriesProvider.overrideWith((ref) async => [_category]),
          assetsProvider.overrideWith((ref) async {
            builds.add(builds.length + 1);
            return [_account, _savings];
          }),
          presetListProvider.overrideWith((ref) async => [_preset]),
          assetRepositoryProvider.overrideWith((ref) async => repo),
          presetRepositoryProvider.overrideWith(
            (ref) async => PresetRepository(Dio()),
          ),
        ],
        child: _home(
          (ctx) => TextButton(
            onPressed: () => showAddTxSheet(ctx),
            child: const Text('open'),
          ),
          assetsProvider,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(findText('open'));
    await tester.pumpAndSettle();
    await tester.tap(findText(l.expTypeTransfer));
    await tester.pumpAndSettle();
    await tester.tap(findText('적금이체'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).first, '12345');
    await tester.pumpAndSettle();
    await tester.tap(findText(l.actionNext));
    await tester.pumpAndSettle();
    final before = builds.length;
    repo.gate = Completer<void>();
    await tester.tap(findText(l.expAddShort).last);
    await tester.pump();
    await _dismissSheet(tester);
    repo.gate!.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(builds.length, greaterThan(before), reason: '이체 저장 뒤 목록이 갱신되지 않았다');
  });

  testWidgets('ConsumerWidget 단추 — 캘린더 고르기 시트가 닫혀도 보이기 토글 뒤 목록을 다시 받는다', (
    tester,
  ) async {
    final repo = _GatedCalendarRepo();
    final builds = <int>[];
    const cal = UserCalendar(rowId: 3, calendarName: '가족 캘린더');
    _bigView(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userCalendarListProvider.overrideWith((ref) async {
            builds.add(builds.length + 1);
            return [cal];
          }),
          userCalendarRepositoryProvider.overrideWith((ref) async => repo),
        ],
        child: _home(
          (ctx) => TextButton(
            onPressed: () => showCalendarFilterSheet(ctx, onManage: () {}),
            child: const Text('open'),
          ),
          userCalendarListProvider,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(findText('open'));
    await tester.pumpAndSettle();
    expect(builds, hasLength(1));
    repo.gate = Completer<void>();
    await tester.tap(findText('가족 캘린더'));
    await tester.pump();
    await _dismissSheet(tester);
    repo.gate!.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(builds.length, greaterThan(1), reason: '토글 뒤 목록이 갱신되지 않았다');
  });
}

class _GatedCalendarRepo extends UserCalendarRepository {
  _GatedCalendarRepo() : super(Dio());
  Completer<void>? gate;

  @override
  Future<UserCalendar> toggleVisibility(int id) async {
    await gate?.future;
    return const UserCalendar(rowId: 3, calendarName: '가족 캘린더');
  }
}
