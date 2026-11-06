// 조회 실패 공용 알림(I-wrap-b2b 2-1 · 2-2) — 값이 있는 채 다시 받기 실패는 "새로 고치지 못했어요." 하나, 참조 조회가 값 없이
// 실패하면 "일부 정보를 불러오지 못했어요." + [다시 시도]. 폴링 · 401 · 처음 받기 실패는 빼고, 403 · 404 는 빼지 않는다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override, ProviderListenable;
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/query_failure/query_failure_marks.dart';
import 'package:groo_damda_app/app/query_failure/query_failure_observer.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/lifecycle/screen_visibility.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/stocks/application/securities_retry.dart';
import 'package:groo_damda_app/features/stocks/application/stocks_providers.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/pull_to_refresh/p_pull_to_refresh.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import '../support/plain_text.dart';

const _refresh = '새로 고치지 못했어요.';
const _reference = '일부 정보를 불러오지 못했어요.';

/// 시험 조회 — [fail] 이 있으면 그 오류로 실패한다.
class _Q {
  _Q(this.name, {Duration? Function(int, Object)? retry}) {
    provider = FutureProvider<int>((ref) async {
      builds++;
      final f = fail;
      if (f != null) throw f;
      return 1;
    }, retry: retry);
  }
  final String name;
  late final FutureProvider<int> provider;
  Object? fail;
  int builds = 0;
}

ApiException _api(int status, [String code = 'X']) =>
    ApiException(code: code, message: '서버 원문 $status', statusCode: status);

class _Harness {
  late ProviderContainer container;
  late QueryFailureObserver observer;
}

Future<_Harness> _pump(
  WidgetTester tester, {
  required List<ProviderListenable<Object?>> watch,
  List<Override> overrides = const [],
  ValueNotifier<int>? openSheets,
  ValueNotifier<int>? shownFailures,
}) async {
  final host = GlobalKey<PSnackbarHostState>();
  final h = _Harness();
  final observer = QueryFailureObserver(
    refresh: RefreshFailureNotice(host: host),
    reference: ReferenceFailureNotice(
      host: host,
      openSheets: openSheets ?? ValueNotifier(0),
      shownFailures: shownFailures ?? ValueNotifier(0),
    ),
  );
  addTearDown(observer.dispose);
  h.observer = observer;
  await tester.pumpWidget(
    ProviderScope(
      // 앱과 같다 — riverpod 기본 재시도를 끈다(app/session_scope.dart appProviderRetry)
      retry: (_, _) => null,
      observers: [observer],
      overrides: overrides,
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        builder: (context, child) =>
            PSnackbarHost(key: host, closeLabel: '닫기', child: child!),
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) {
              h.container = ProviderScope.containerOf(context);
              for (final p in watch) {
                ref.watch(p);
              }
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return h;
}

/// 다시 받게 하고 모으는 시간이 지나 띠가 다 뜰 때까지.
Future<void> _refetch(WidgetTester tester, _Harness h, List<_Q> qs) async {
  for (final q in qs) {
    h.container.invalidate(q.provider);
  }
  await tester.pump();
  await tester.pump(kQueryFailureGather);
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  group('새로 고치지 못했어요(값이 있는 채 다시 받기 실패)', () {
    testWidgets('두 질의가 함께 실패해도 스낵바는 하나 — 한 문장 · [다시 시도] 없음', (tester) async {
      final a = _Q('a');
      final b = _Q('b');
      final h = await _pump(tester, watch: [a.provider, b.provider]);
      a.fail = _api(500);
      b.fail = _api(500);
      await _refetch(tester, h, [a, b]);
      expect(findText(_refresh), findsOneWidget);
      expect(findText('다시 시도'), findsNothing);
      expect(findTextContaining('서버 원문'), findsNothing);
      // 떠 있는 동안 또 실패해도 다시 띄우지 않는다
      await _refetch(tester, h, [a]);
      expect(findText(_refresh), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('당겨서 새로 고침이 도는 동안의 실패는 그 자리가 알린다 — 공용 글은 띄우지 않는다', (
      tester,
    ) async {
      final a = _Q('a');
      final h = await _pump(tester, watch: [a.provider]);
      a.fail = _api(500);
      pPullToRefreshInFlight.value += 1;
      addTearDown(() => pPullToRefreshInFlight.value = 0);
      await _refetch(tester, h, [a]);
      expect(findText(_refresh), findsNothing);
    });

    testWidgets('같은 조회가 연달아 실패하면 첫 실패만 — 성공하면 다시 센다, 다른 조회는 따로(판단 가)', (
      tester,
    ) async {
      final a = _Q('a');
      final b = _Q('b');
      final h = await _pump(tester, watch: [a.provider, b.provider]);
      a.fail = _api(500);
      await _refetch(tester, h, [a]);
      expect(findText(_refresh), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(findText(_refresh), findsNothing);
      // 같은 a 가 또 실패 — 띄우지 않는다
      await _refetch(tester, h, [a]);
      expect(findText(_refresh), findsNothing);
      // 다른 b 의 첫 실패 — 띄운다
      b.fail = _api(500);
      await _refetch(tester, h, [b]);
      expect(findText(_refresh), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      // a 가 한 번 성공한 뒤 다시 실패 — 다시 센다
      a.fail = null;
      await _refetch(tester, h, [a]);
      a.fail = _api(500);
      await _refetch(tester, h, [a]);
      expect(findText(_refresh), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('컨테이너를 갈면(reset) 모으던 알림을 끊는다(검수 L5)', (tester) async {
      final a = _Q('a');
      final h = await _pump(tester, watch: [a.provider]);
      a.fail = _api(500);
      h.container.invalidate(a.provider);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));
      h.observer.reset();
      await tester.pump(kQueryFailureGather);
      await tester.pump(const Duration(milliseconds: 400));
      expect(findText(_refresh), findsNothing);
    });

    testWidgets('값이 없는 처음 받기 실패는 띄우지 않는다(그 자리 Result Section)', (tester) async {
      final a = _Q('a')..fail = _api(500);
      await _pump(tester, watch: [a.provider]);
      await tester.pump(kQueryFailureGather);
      await tester.pump(const Duration(milliseconds: 400));
      expect(findText(_refresh), findsNothing);
    });

    testWidgets('401 은 빼고(로그인 흐름) 403 · 404 는 띄운다', (tester) async {
      final a = _Q('a');
      final h = await _pump(tester, watch: [a.provider]);
      a.fail = _api(401, 'AUTH_001');
      await _refetch(tester, h, [a]);
      expect(findText(_refresh), findsNothing);
      for (final status in [403, 404]) {
        a.fail = null;
        await _refetch(tester, h, [a]);
        a.fail = _api(status);
        await _refetch(tester, h, [a]);
        expect(findText(_refresh), findsOneWidget, reason: '$status');
        await tester.pumpAndSettle(const Duration(seconds: 5));
      }
    });

    testWidgets('폴링(securitiesNoRetry) 과 그 값으로 만든 조회의 실패는 띄우지 않는다', (
      tester,
    ) async {
      final poll = _Q('poll', retry: securitiesNoRetry);
      final derived = FutureProvider<int>(
        (ref) async => (await ref.watch(poll.provider.future)) + 1,
      );
      final h = await _pump(tester, watch: [poll.provider, derived]);
      poll.fail = _api(500);
      await _refetch(tester, h, [poll]);
      expect(h.container.read(derived).hasError, isTrue, reason: '전제');
      expect(findText(_refresh), findsNothing);
    });

    testWidgets('지켜보는 화면이 없는 조회는 비워도 다시 받지 않는다 — 그래서 실패도 알림도 없다', (
      tester,
    ) async {
      final watched = _Q('watched');
      final idle = _Q('idle');
      final h = await _pump(tester, watch: [watched.provider]);
      // 한 번 읽어 값을 들게 한 뒤 아무도 지켜보지 않는다
      await h.container.read(idle.provider.future);
      final before = idle.builds;
      idle.fail = _api(500);
      await _refetch(tester, h, [idle]);
      expect(idle.builds, before, reason: 'riverpod 3 은 구독자 없는 조회를 다시 만들지 않는다');
      expect(findText(_refresh), findsNothing);
    });
  });

  group('일부 정보를 불러오지 못했어요(참조 조회)', () {
    late List<ExpenseCategory>? cats;
    late Object? catsFail;
    late int catsBuilds;
    late List<Override> overrides;
    setUp(() {
      cats = const [];
      catsFail = null;
      catsBuilds = 0;
      overrides = [
        categoriesProvider.overrideWith((ref) async {
          catsBuilds++;
          if (catsFail != null) throw catsFail!;
          return cats!;
        }),
      ];
    });

    test('표식 — 참조 · 폴링 이름', () {
      expect(isReferenceProvider(categoriesProvider), isTrue);
      expect(isReferenceProvider(assetsProvider), isTrue);
      expect(
        isReferenceProvider(monthExpensesProvider((year: 1, month: 1))),
        isFalse,
      );
      expect(isPollingProvider(tossPricesProvider('A,B')), isTrue);
      expect(isPollingProvider(tossHoldingsProvider), isTrue);
      expect(isPollingProvider(investmentValuationMapProvider), isTrue);
      expect(isPollingProvider(categoriesProvider), isFalse);
    });

    testWidgets('값 없이 실패하면 한 줄 + [다시 시도] — 누르면 다시 받는다, 공용 새로 고침 글은 뜨지 않는다', (
      tester,
    ) async {
      catsFail = _api(500);
      await _pump(tester, watch: [categoriesProvider], overrides: overrides);
      await tester.pump(kQueryFailureGather);
      await tester.pump(const Duration(milliseconds: 400));
      expect(findText(_reference), findsOneWidget);
      expect(findText(_refresh), findsNothing);
      expect(findTextContaining('서버 원문'), findsNothing);
      final before = catsBuilds;
      catsFail = null;
      await tester.tap(findText('다시 시도'));
      await tester.pumpAndSettle();
      expect(catsBuilds, before + 1);
      await tester.pumpAndSettle(const Duration(seconds: 7));
    });

    testWidgets('받아 둔 값이 있는 채 다시 받기에 실패하면 값을 두고 아무것도 띄우지 않는다', (tester) async {
      final h = await _pump(
        tester,
        watch: [categoriesProvider],
        overrides: overrides,
      );
      catsFail = _api(500);
      h.container.invalidate(categoriesProvider);
      await tester.pump();
      await tester.pump(kQueryFailureGather);
      await tester.pump(const Duration(milliseconds: 400));
      expect(findText(_reference), findsNothing);
      expect(findText(_refresh), findsNothing);
    });

    testWidgets('시트가 열린 동안은 쉬고, 모두 닫히면 한 번 다시 판단해 띄운다', (tester) async {
      final open = ValueNotifier<int>(1);
      catsFail = _api(500);
      await _pump(
        tester,
        watch: [categoriesProvider],
        overrides: overrides,
        openSheets: open,
      );
      await tester.pump(kQueryFailureGather);
      await tester.pump(const Duration(milliseconds: 400));
      expect(findText(_reference), findsNothing);
      open.value = 0;
      await tester.pump(kQueryFailureGather);
      await tester.pump(const Duration(milliseconds: 400));
      expect(findText(_reference), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 7));
    });

    testWidgets('화면에 실패 Result Section 이 보이는 동안은 쉬고, 사라지면 띄운다(중간 검수 1)', (
      tester,
    ) async {
      final shown = ValueNotifier<int>(1);
      catsFail = _api(500);
      await _pump(
        tester,
        watch: [categoriesProvider],
        overrides: overrides,
        shownFailures: shown,
      );
      await tester.pump(kQueryFailureGather);
      await tester.pump(const Duration(milliseconds: 400));
      expect(findText(_reference), findsNothing);
      shown.value = 0;
      await tester.pump(kQueryFailureGather);
      await tester.pump(const Duration(milliseconds: 400));
      expect(findText(_reference), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 7));
    });

    testWidgets(
      '보이는 실패 Result Section 수 — failure 만, 가려진 탭(TickerMode 꺼짐)은 세지 않는다',
      (tester) async {
        Widget section(PResultKind kind) =>
            PResultSection(kind: kind, icon: Icons.info, title: '제목');
        Future<void> show(Widget w) => tester.pumpWidget(
          MaterialApp(
            theme: GrooTheme.light(),
            home: Scaffold(body: w),
          ),
        );
        expect(pResultFailureShown.value, 0);
        await show(section(PResultKind.empty));
        expect(pResultFailureShown.value, 0);
        await show(section(PResultKind.failure));
        expect(pResultFailureShown.value, 1);
        await show(
          TickerMode(enabled: false, child: section(PResultKind.failure)),
        );
        expect(pResultFailureShown.value, 0);
        await show(const SizedBox());
        expect(pResultFailureShown.value, 0);
      },
    );

    testWidgets('앞서 알린 실패로는 시트를 닫을 때 다시 뜨지 않는다(검수 M1)', (tester) async {
      final open = ValueNotifier<int>(0);
      catsFail = _api(500);
      await _pump(
        tester,
        watch: [categoriesProvider],
        overrides: overrides,
        openSheets: open,
      );
      await tester.pump(kQueryFailureGather);
      await tester.pump(const Duration(milliseconds: 400));
      expect(findText(_reference), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 7));
      expect(findText(_reference), findsNothing);
      // 다른 화면에서 시트를 열고 닫는다 — 새 실패가 없으니 띄우지 않는다
      open.value = 1;
      await tester.pump();
      open.value = 0;
      await tester.pump(kQueryFailureGather);
      await tester.pump(const Duration(milliseconds: 400));
      expect(findText(_reference), findsNothing);
    });

    testWidgets('캘린더에서 실패(시트 보류 중) → 탭을 옮기고 시트를 닫으면 뜨지 않는다(검수 M1)', (
      tester,
    ) async {
      final open = ValueNotifier<int>(1);
      catsFail = _api(500);
      final h = await _pump(
        tester,
        watch: [categoriesProvider, activeShellRouteProvider],
        overrides: overrides,
        openSheets: open,
      );
      await tester.pump(kQueryFailureGather);
      // 탭 이동(가계부로)
      h.container.read(activeShellRouteProvider.notifier).setPath('/expense');
      await tester.pump();
      open.value = 0;
      await tester.pump(kQueryFailureGather);
      await tester.pump(const Duration(milliseconds: 400));
      expect(findText(_reference), findsNothing);
    });

    testWidgets('401 은 참조 알림도 거른다(로그인 흐름, 검수 L1)', (tester) async {
      catsFail = _api(401, 'AUTH_001');
      await _pump(tester, watch: [categoriesProvider], overrides: overrides);
      await tester.pump(kQueryFailureGather);
      await tester.pump(const Duration(milliseconds: 400));
      expect(findText(_reference), findsNothing);
    });

    testWidgets('시트 수는 PBottomSheet 가 센다(열면 1 · 닫으면 0)', (tester) async {
      expect(pBottomSheetOpenCount.value, 0);
      await tester.pumpWidget(
        MaterialApp(
          theme: GrooTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => PBottomSheet.show<void>(
                context,
                builder: (_) => PBottomSheetContent(
                  title: '제목',
                  closeLabel: '닫기',
                  body: const SizedBox(height: 40),
                ),
              ),
              child: const Text('열기'),
            ),
          ),
        ),
      );
      await tester.tap(findText('열기'));
      await tester.pumpAndSettle();
      expect(pBottomSheetOpenCount.value, 1);
      await tester.tap(find.byKey(const ValueKey('p-bottom-sheet-close')));
      await tester.pumpAndSettle();
      expect(pBottomSheetOpenCount.value, 0);
    });
  });
}
