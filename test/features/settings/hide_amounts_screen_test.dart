import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/lock/app_lock.dart';
import 'package:groo_damda_app/core/settings/hide_amounts_cards.dart';
import 'package:groo_damda_app/core/settings/hide_cards_repository.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/core/storage/prefs_provider.dart';
import 'package:groo_damda_app/features/settings/presentation/hide_amounts_screen.dart';
import 'package:dio/dio.dart';
import 'package:groo_damda_app/core/auth/auth_notifier.dart';
import 'package:groo_damda_app/core/auth/auth_repository.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/tabs/p_tabs.dart';
import '../../support/hide_cards_fake.dart';
import '../../support/plain_text.dart';

/// OS 프롬프트 없이 정해진 결과만 돌려주는 가짜 인증.
class _FakeAuth extends AppLockAuth {
  _FakeAuth(this.result) : super(LocalAuthentication());

  final AppLockAuthResult result;
  int calls = 0;

  @override
  Future<bool> isDeviceSupported() async => true;

  @override
  Future<AppLockAuthResult> authenticate({
    required String reason,
    required String signInTitle,
    required String cancelLabel,
  }) async {
    calls++;
    return result;
  }
}

/// 읽기가 끝나지 않은 설정 — [gate] 를 완료해야 값을 준다.
class _SlowSettings extends SettingsNotifier {
  _SlowSettings(this.gate);
  final Completer<void> gate;

  @override
  Future<AppSettings> build() async {
    await gate.future;
    return super.build();
  }
}

/// 비밀번호가 맞다고 답하는 저장소.
class _Repo extends AuthRepository {
  _Repo() : super(Dio());
  int calls = 0;

  @override
  Future<void> verifyPassword(String password) async => calls++;
}

/// 목록 제목의 "n / m"(앞뒤는 줄바꿈 없는 공백).
String _count(int n, int m) => '가릴 화면 · $n\u00A0/\u00A0$m';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> pumpScreen(
    WidgetTester tester, {
    required _FakeAuth auth,
    Set<String> hidden = const {},
    bool appLock = true,
    Completer<void>? gate,
    _Repo? repo,
  }) async {
    // 기본 800×600 은 실제 폰보다 짧다. 위 '거래 종류' 영역 때문에 체크 줄이 밀려 아래쪽 줄이 뷰포트 밖으로 나간다 — 세로만 늘린다.
    tester.view.physicalSize = const Size(2400, 3600); // dpr 3.0 → 논리 800×1200
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({
      PrefsKeys.appLock: appLock,
      PrefsKeys.hideCards: hidden.toList(),
    });
    final container = ProviderContainer(
      overrides: [
        appLockAuthProvider.overrideWithValue(auth),
        hideCardsRepositoryProvider.overrideWith(
          (ref) async => OkHideCardsRepository(),
        ),
        if (repo != null)
          authRepositoryProvider.overrideWith((ref) async => repo),
        if (gate != null)
          settingsProvider.overrideWith(() => _SlowSettings(gate)),
      ],
    );
    addTearDown(container.dispose);
    container.listen(appLockedProvider, (_, _) {});
    if (gate == null) await container.read(settingsProvider.future);

    // 실제 진입과 같게 push 로 쌓는다 — 저장 후 pop 할 자리가 있어야 한다.
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
        container: container,
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
    if (gate != null) {
      // 스켈레톤은 계속 움직여 settle 이 끝나지 않는다 — 몇 프레임만 흘린다.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      return container;
    }
    await tester.pumpAndSettle();
    return container;
  }

  /// 탭 줄 안의 글 — 같은 이름의 화면 묶음 제목과 헷갈리지 않게.
  Finder tabText(String s) => find.descendant(
    of: find.byType(PTabs<HidePage?>),
    matching: findPlain(s),
  );

  Finder saveButton() =>
      find.byWidgetPredicate((w) => w is PButton && w.label == '저장');

  Future<void> tapSave(WidgetTester tester) async {
    await tester.tap(saveButton());
    // 저장 버튼이 로딩 스피너(무한 애니메이션)로 바뀌면 settle 이 끝나지 않는다.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('금액 가리기 화면', () {
    testWidgets('카드를 골라도 저장 전에는 설정이 그대로다', (tester) async {
      final auth = _FakeAuth(AppLockAuthResult.success);
      final container = await pumpScreen(tester, auth: auth);

      await tester.tap(findPlain('순자산').first);
      await tester.pumpAndSettle();

      // 화면에서만 골라 둔 상태 — 인증도 저장도 아직 없다.
      expect(auth.calls, 0);
      expect(container.read(settingsProvider).value?.hideCards, isEmpty);
    });

    testWidgets('가리기만 늘리는 저장은 인증 없이 통과한다', (tester) async {
      final auth = _FakeAuth(AppLockAuthResult.success);
      final container = await pumpScreen(tester, auth: auth);

      await tester.tap(findPlain('순자산').first);
      await tester.pumpAndSettle();
      await tapSave(tester);
      await tester.pumpAndSettle();

      expect(auth.calls, 0);
      expect(container.read(settingsProvider).value?.hideCards, {
        'home.netWorth',
      });
    });

    testWidgets('푸는 게 섞이면 저장할 때 인증을 한 번만 받는다', (tester) async {
      final auth = _FakeAuth(AppLockAuthResult.success);
      final container = await pumpScreen(
        tester,
        auth: auth,
        hidden: {'home.netWorth', 'home.budget', 'home.todaySpend'},
      );

      // 세 장을 한꺼번에 푼다 — 예전엔 스위치마다 인증이 떴다.
      for (final label in ['순자산', '예산 진행', '오늘 지출']) {
        await tester.tap(findPlain(label).first);
        await tester.pumpAndSettle();
      }
      expect(auth.calls, 0);

      await tapSave(tester);
      await tester.pumpAndSettle();

      expect(auth.calls, 1);
      expect(container.read(settingsProvider).value?.hideCards, isEmpty);
    });

    testWidgets('인증을 취소하면 아무것도 저장되지 않는다', (tester) async {
      final auth = _FakeAuth(AppLockAuthResult.failure);
      final container = await pumpScreen(
        tester,
        auth: auth,
        hidden: {'home.netWorth'},
        // 생체 실패 후 비밀번호 시트로 물러선다 — 거기서 닫는다.
      );

      await tester.tap(findPlain('순자산').first);
      await tester.pumpAndSettle();
      await tapSave(tester);

      expect(findPlain('금액 보기 인증'), findsOneWidget);
      expect(findPlain('금액 보기'), findsOneWidget); // 바닥 버튼 — 동작 이름
      await tester.tap(find.bySemanticsLabel('닫기').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(container.read(settingsProvider).value?.hideCards, {
        'home.netWorth',
      });
    });

    testWidgets('저장 버튼은 바꾼 게 있어야 눌린다', (tester) async {
      final auth = _FakeAuth(AppLockAuthResult.success);
      await pumpScreen(tester, auth: auth);

      expect(tester.widget<PButton>(saveButton()).onPressed, isNull);

      await tester.tap(findPlain('순자산').first);
      await tester.pumpAndSettle();

      expect(tester.widget<PButton>(saveButton()).onPressed, isNotNull);
    });

    testWidgets('탭은 이름만 쓰고 개수를 붙이지 않는다', (tester) async {
      final auth = _FakeAuth(AppLockAuthResult.success);
      await pumpScreen(tester, auth: auth, hidden: {'home.netWorth'});

      final tabs = tester.widget<PTabs<HidePage?>>(
        find.byType(PTabs<HidePage?>),
      );
      expect(tabs.items.map((t) => t.label).toList(), [
        '전체',
        '홈',
        '자산',
        '가계부',
        '통계',
        '예산',
        '증권',
        '더치페이',
        '기타',
      ]);
      expect(findPlain('홈 1'), findsNothing);
    });

    testWidgets('"가릴 화면 · n / m" 은 지금 탭 기준이고 모두 선택 · 해제가 따라 바뀐다', (
      tester,
    ) async {
      final auth = _FakeAuth(AppLockAuthResult.success);
      await pumpScreen(tester, auth: auth, hidden: {'home.netWorth'});

      expect(findRichText(_count(1, kScreenHideCards.length)), findsOneWidget);
      await tester.tap(tabText('홈'));
      await tester.pumpAndSettle();
      final home = cardsOfPage(HidePage.home);
      expect(findRichText(_count(1, home.length)), findsOneWidget);
      expect(findPlain('모두 선택'), findsOneWidget);

      await tester.tap(findPlain('모두 선택'));
      await tester.pumpAndSettle();
      expect(findRichText(_count(home.length, home.length)), findsOneWidget);
      expect(findPlain('모두 해제'), findsOneWidget);
    });

    testWidgets('모두 선택은 지금 탭의 카드만 고른다', (tester) async {
      final auth = _FakeAuth(AppLockAuthResult.success);
      final container = await pumpScreen(tester, auth: auth);

      // '홈' 탭으로 옮겨 그 탭만 전부 고른다.
      await tester.tap(tabText('홈'));
      await tester.pumpAndSettle();
      await tester.tap(findPlain('모두 선택'));
      await tester.pumpAndSettle();
      await tapSave(tester);
      await tester.pumpAndSettle();

      expect(
        container.read(settingsProvider).value?.hideCards,
        cardsOfPage(HidePage.home).toSet(),
      );
    });

    testWidgets('전체 탭은 화면 이름으로 묶고, 화면 탭은 그 화면의 줄만 보인다', (tester) async {
      final auth = _FakeAuth(AppLockAuthResult.success);
      await pumpScreen(tester, auth: auth);

      // 전체 — 화면 이름 목록 제목이 보인다(홈 · 자산 묶음 아래 '예정 결제' 가 각자 선다)
      expect(
        find.byKey(const ValueKey('hide-card-home.upcoming')),
        findsOneWidget,
      );
      // 홈 · 자산 묶음 제목이 각자 선다(탭 글과 따로 센다)
      expect(findRichText('홈'), findsOneWidget);
      expect(findRichText('자산'), findsOneWidget);

      await tester.tap(tabText('가계부'));
      await tester.pumpAndSettle();

      expect(findPlain('월 합계'), findsOneWidget); // 가계부 카드
      expect(findPlain('순자산'), findsNothing);
      // 화면 탭에는 화면 이름 목록 제목을 두지 않는다 — 탭 이름만 남는다.
      expect(findRichText('가계부'), findsNothing);
      expect(tabText('가계부'), findsOneWidget);
    });

    testWidgets('좌우로 밀어서 탭을 옮기지 않는다 — 탭을 눌러 바꾼다', (tester) async {
      final auth = _FakeAuth(AppLockAuthResult.success);
      await pumpScreen(tester, auth: auth);

      expect(find.byType(PageView), findsNothing);
      expect(find.byType(PListCheckGroup), findsWidgets);
    });

    testWidgets('설정을 읽기 전에는 체크 줄 스켈레톤이고, 읽은 뒤에 고름을 잡는다', (tester) async {
      final auth = _FakeAuth(AppLockAuthResult.success);
      final gate = Completer<void>();
      await pumpScreen(
        tester,
        auth: auth,
        hidden: {'home.netWorth'},
        gate: gate,
      );

      expect(find.byKey(const ValueKey('hide-amounts-skeleton')), findsWidgets);
      expect(tester.widget<PButton>(saveButton()).onPressed, isNull);

      gate.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('hide-amounts-skeleton')), findsNothing);
      // 읽은 값(순자산 가림)에서 시작한다 — 빈 고름으로 굳지 않았다.
      expect(findRichText(_count(1, kScreenHideCards.length)), findsOneWidget);
    });

    testWidgets('값이 있는 채 시트를 닫으면 작성한 내용이 사라진다고 묻고, 비어 있으면 그냥 닫힌다', (
      tester,
    ) async {
      final auth = _FakeAuth(AppLockAuthResult.success);
      final container = await pumpScreen(
        tester,
        auth: auth,
        hidden: {'home.netWorth'},
        appLock: false,
        repo: _Repo(),
      );
      await tester.tap(findPlain('순자산').first);
      await tester.pumpAndSettle();
      await tapSave(tester);
      expect(findPlain('금액 보기 인증'), findsOneWidget);

      // 비어 있으면 묻지 않고 닫힌다
      await tester.tap(find.bySemanticsLabel('닫기').last);
      await tester.pumpAndSettle();
      expect(findPlain('금액 보기 인증'), findsNothing);
      expect(findPlain('작성한 내용이 사라져요'), findsNothing);

      // 다시 열어 값을 치고 닫으면 묻는다
      await tapSave(tester);
      await tester.enterText(find.byType(EditableText).last, 'pw');
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('닫기').last);
      await tester.pumpAndSettle();
      expect(findPlain('작성한 내용이 사라져요'), findsOneWidget);
      // 계속 작성 → 시트가 남는다 · 저장은 안 됨
      await tester.tap(findPlain('계속 작성'));
      await tester.pumpAndSettle();
      expect(findPlain('금액 보기 인증'), findsOneWidget);
      expect(container.read(settingsProvider).value?.hideCards, {
        'home.netWorth',
      });
    });

    testWidgets('맞는 비밀번호면 저장하고 시트와 화면이 닫힌다', (tester) async {
      final auth = _FakeAuth(AppLockAuthResult.success);
      final repo = _Repo();
      final container = await pumpScreen(
        tester,
        auth: auth,
        hidden: {'home.netWorth'},
        appLock: false,
        repo: repo,
      );
      await tester.tap(findPlain('순자산').first);
      await tester.pumpAndSettle();
      await tapSave(tester);
      await tester.enterText(find.byType(EditableText).last, 'pw');
      await tester.pump();
      await tester.tap(
        find.byWidgetPredicate((w) => w is PButton && w.label == '금액 보기'),
      );
      await tester.pumpAndSettle();

      expect(repo.calls, 1);
      expect(container.read(settingsProvider).value?.hideCards, isEmpty);
      expect(findPlain('금액 보기 인증'), findsNothing);
      expect(find.byType(HideAmountsScreen), findsNothing);
    });
  });
}
