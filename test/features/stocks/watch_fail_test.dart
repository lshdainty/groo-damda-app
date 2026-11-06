// 관심 종목 · 그룹 실패 — 그룹 저장은 맨 위 Callout(값 유지) · 삭제는 확인창 뒤 스낵바 + 다시 시도 ·
// 별 토글은 스낵바 + 다시 시도, 모두 silent 이고 서버 글은 나오지 않는다.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/features/stocks/application/stocks_providers.dart';
import 'package:groo_damda_app/features/stocks/data/stocks_repository.dart';
import 'package:groo_damda_app/features/stocks/data/watch_dto.dart';
import 'package:groo_damda_app/features/stocks/presentation/watch_actions.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import 'package:groo_damda_app/shared/forms/form_error_callout.dart';

import '../../support/plain_text.dart';

const _group = StockWatchGroup(
  rowId: 1,
  groupName: '관심',
  sortOrder: 0,
  items: [],
);

class _Repo extends StocksRepository {
  _Repo() : super(Dio());
  final silent = <String>[];
  int deletes = 0;
  int adds = 0;

  Never _fail() => throw ApiException(code: 'X', message: '서버 원문');

  @override
  Future<StockWatchGroup> createWatchGroup(
    String groupName, {
    bool silent = false,
  }) async {
    if (silent) this.silent.add('create');
    _fail();
  }

  @override
  Future<void> deleteWatchGroup(int groupId, {bool silent = false}) async {
    if (silent) this.silent.add('delete');
    deletes++;
    _fail();
  }

  @override
  Future<WatchItem> addWatchItem(
    int groupId,
    String symbol, {
    String? marketCode,
    bool silent = false,
  }) async {
    if (silent) this.silent.add('add');
    adds++;
    _fail();
  }
}

Future<_Repo> _pump(
  WidgetTester tester,
  Widget Function(BuildContext, WidgetRef) open,
) async {
  final repo = _Repo();
  tester.view.physicalSize = const Size(390 * 2, 844 * 2);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        stocksRepositoryProvider.overrideWith((ref) async => repo),
        watchGroupsProvider.overrideWith((ref) async => const [_group]),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        builder: (c, child) => PSnackbarHost(closeLabel: '닫기', child: child!),
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) {
              ref.watch(watchGroupsProvider);
              return open(context, ref);
            },
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  late AppLocalizations l;
  setUpAll(() async {
    l = await AppLocalizations.delegate.load(const Locale('ko'));
  });

  testWidgets('그룹 추가 실패 — 맨 위 Callout · silent · 이름 유지 · 서버 글 없음', (
    tester,
  ) async {
    final repo = await _pump(
      tester,
      (c, ref) => TextButton(
        onPressed: () => showWatchGroupForm(c, ref),
        child: const Text('open'),
      ),
    );
    await tester.tap(findText('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '배당');
    await tester.pumpAndSettle();
    await tester.tap(findPlain(l.actionSave));
    await tester.pumpAndSettle();
    expect(repo.silent, ['create']);
    expect(l.stocksWatchGroupSaveFail, '그룹을 저장하지 못했어요.');
    expect(findPlain(l.stocksWatchGroupSaveFail), findsOneWidget);
    expect(find.byType(FormErrorCallout), findsOneWidget);
    expect(findTextContaining('서버 원문'), findsNothing);
    expect(findText('배당'), findsWidgets);
  });

  testWidgets('그룹 삭제 실패 — 확인창 뒤 스낵바 + 다시 시도(묻지 않고 한 번 더)', (tester) async {
    final repo = await _pump(
      tester,
      (c, ref) => TextButton(
        onPressed: () => confirmDeleteWatchGroup(c, ref, _group),
        child: const Text('open'),
      ),
    );
    await tester.tap(findText('open'));
    await tester.pumpAndSettle();
    await tester.tap(findPlain(l.stocksWatchGroupDelete).last);
    await tester.pumpAndSettle();
    expect(repo.deletes, 1);
    expect(l.stocksWatchGroupDeleteFail, '그룹을 삭제하지 못했어요.');
    expect(findPlain(l.stocksWatchGroupDeleteFail), findsOneWidget);
    expect(findTextContaining('서버 원문'), findsNothing);
    await tester.tap(findPlain(l.actionRetry));
    await tester.pumpAndSettle();
    expect(repo.deletes, 2);
  });

  testWidgets(
    '관심 종목 담기 실패 — 스낵바 한 문장 · 다시 시도 없음(별은 토글, 판단 ②) · silent · 서버 글 없음',
    (tester) async {
      final repo = await _pump(
        tester,
        (c, ref) => TextButton(
          onPressed: () => toggleWatch(c, ref, '000660'),
          child: const Text('open'),
        ),
      );
      await tester.tap(findText('open'));
      await tester.pumpAndSettle();
      expect(repo.adds, 1);
      expect(repo.silent, ['add']);
      expect(l.stocksWatchAddFail, '관심 종목에 넣지 못했어요.');
      expect(findPlain(l.stocksWatchAddFail), findsOneWidget);
      expect(findTextContaining('서버 원문'), findsNothing);
      expect(
        findPlain(l.actionRetry),
        findsNothing,
        reason: '누르는 순간 바뀌는 값 — 다시 누르면 된다',
      );
      expect(repo.adds, 1);
    },
  );
}
