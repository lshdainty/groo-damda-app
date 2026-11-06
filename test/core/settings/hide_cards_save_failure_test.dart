// 금액 가리기 서버 저장이 실패하면 — 로컬은 그대로고, 다음 동기화가 덮어도 드러나는 금액이 없다(I-28-5 final).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/settings/hide_cards_repository.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/core/storage/prefs_provider.dart';
import 'package:groo_damda_app/features/settings/presentation/hide_amounts_screen.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/forms/save_failure.dart';

import '../../support/plain_text.dart';

class _Repo implements HideCardsRepository {
  _Repo({this.failPut = true, this.server = const ['asset.netWorth']});
  bool failPut;
  List<String>? server;
  final List<Set<String>> pushed = [];

  @override
  Future<List<String>?> fetch() async => server;

  @override
  Future<void> put(Set<String> cards, {bool silent = true}) async {
    if (failPut) throw Exception('500');
    pushed.add({...cards});
    server = cards.toList();
  }
}

ProviderContainer _container(_Repo repo) {
  final c = ProviderContainer(
    overrides: [hideCardsRepositoryProvider.overrideWith((ref) async => repo)],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('저장 요청이 실패하면 failed 를 돌려주고 로컬은 그대로다', () async {
    SharedPreferences.setMockInitialValues({
      PrefsKeys.hideCards: ['asset.netWorth'],
    });
    final c = _container(_Repo());
    await c.read(settingsProvider.future);

    final ok = await c.read(settingsProvider.notifier).setHideCards({});

    expect(ok, WriteOutcome.failed);
    expect(c.read(settingsProvider).value!.hideCards, {'asset.netWorth'});
  });

  test('실패한 풀기 뒤 동기화가 서버 값으로 덮어도 가림이 그대로다', () async {
    SharedPreferences.setMockInitialValues({
      PrefsKeys.hideCards: ['asset.netWorth'],
      PrefsKeys.hideCardsOwner: 'me',
    });
    final repo = _Repo();
    final c = _container(repo);
    await c.read(settingsProvider.future);
    final n = c.read(settingsProvider.notifier);

    await n.revealAllCards(); // 서버가 못 받는다
    await n.syncHideCardsFromServer('me'); // 서버 옛 값 = 가림

    expect(c.read(settingsProvider).value!.hideCards, {'asset.netWorth'});
  });

  test('저장이 받아지면 done 이고 로컬에 반영된다', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = _Repo(failPut: false, server: <String>[]);
    final c = _container(repo);
    await c.read(settingsProvider.future);

    final ok = await c.read(settingsProvider.notifier).setHideCards({
      'stats.trend',
    });

    expect(ok, WriteOutcome.done);
    expect(c.read(settingsProvider).value!.hideCards, {'stats.trend'});
    expect(repo.pushed.single, {'stats.trend'});
  });

  testWidgets('[저장] 실패 — 화면이 닫히지 않고 고른 값이 남고 맨 위 Callout', (tester) async {
    tester.view.physicalSize = const Size(2400, 3600);
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final c = _container(_Repo(server: <String>[]));
    await c.read(settingsProvider.future);
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('보안')),
        ),
        GoRoute(path: '/hide', builder: (_, _) => const HideAmountsScreen()),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp.router(
          theme: GrooTheme.light(),
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    router.push('/hide');
    await tester.pumpAndSettle();

    await tester.tap(findPlain('모두 선택').first);
    await tester.pump();
    await tester.tap(findPlain('저장'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(findPlain('금액 가리기를 저장하지 못했어요.'), findsOneWidget);
    expect(find.byType(HideAmountsScreen), findsOneWidget);
    expect(c.read(settingsProvider).value!.hideCards, isEmpty);
  });
}
