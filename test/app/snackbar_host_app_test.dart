// 앱 맨 위(MaterialApp.router builder)에 단 PSnackbarHost 가 앱 전체에 주는 영향을 앱과 같은 틀로 잰다.
// 틀(app.dart): SlidableAutoCloseBehavior > AppLockGate > Material(투명) > PSnackbarHost > 화면(Navigator).
//
// 잰 것: 값 대조(자리 · 폭 · 높이 · 모서리 · 색 · 글 · 아이콘 · 액션) · 안전 영역 · 키보드 · 넓은 화면 · 눌러지는 자리(띠 밖은 통과) ·
// 대화상자 위 · 잠금 화면 아래 · 읽는 순서(라이브 영역).
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/lock/app_lock.dart';
import 'package:groo_damda_app/core/lock/app_lock_gate.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import '../support/plain_text.dart';

class _FakeAuth extends AppLockAuth {
  _FakeAuth() : super(LocalAuthentication());
  @override
  Future<bool> isDeviceSupported() async => true;
  @override
  Future<AppLockAuthResult> authenticate({
    required String reason,
    required String signInTitle,
    required String cancelLabel,
  }) async => AppLockAuthResult.failure;
}

class _Locked extends AppLockedNotifier {
  @override
  bool build() => true;
}

final _band = find.byKey(const ValueKey('snackbar-band'));
final _action = find.byKey(const ValueKey('snackbar-action'));

/// app.dart 와 같은 틀. [home] 은 화면, [viewInsets] 는 화면 키보드, [safeBottom] 은 안전 영역.
Future<PSnackbarApi> _mount(
  WidgetTester tester, {
  required Widget home,
  Size size = const Size(390, 800),
  double viewInsets = 0,
  double safeBottom = 0,
  bool locked = false,
  Brightness mode = Brightness.light,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late PSnackbarApi api;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appLockAuthProvider.overrideWithValue(_FakeAuth()),
        if (locked) appLockedProvider.overrideWith(_Locked.new),
      ],
      child: MaterialApp(
        theme: mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            viewInsets: EdgeInsets.only(bottom: viewInsets),
            viewPadding: EdgeInsets.only(bottom: safeBottom),
            padding: EdgeInsets.only(bottom: safeBottom),
          ),
          child: SlidableAutoCloseBehavior(
            child: AppLockGate(
              child: Material(
                type: MaterialType.transparency,
                child: PSnackbarHost(
                  closeLabel: AppLocalizations.of(context).actionClose,
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ),
        home: Builder(
          builder: (context) {
            api = PSnackbar.of(context);
            return home;
          },
        ),
      ),
    ),
  );
  await tester.pump();
  return api;
}

Future<void> _show(
  WidgetTester tester,
  PSnackbarApi api, {
  PSnackbarTone tone = PSnackbarTone.neutral,
  PSnackbarAction? action,
  String message = '지난달 예산을 가져왔어요',
}) async {
  api.show(message: message, tone: tone, action: action);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  group('앱 호스트 — 값 대조(snackbar.yaml)', () {
    testWidgets('자리 · 폭 · 높이 · 모서리 · 색 · 그림자 없음 · 글 · 아이콘 · 액션', (
      tester,
    ) async {
      final api = await _mount(
        tester,
        home: const Scaffold(body: SizedBox.expand()),
      );
      var undone = 0;
      await _show(
        tester,
        api,
        tone: PSnackbarTone.positive,
        action: PSnackbarAction(label: '되돌리기', onPressed: () => undone++),
      );
      final c = tester.element(_band).colors;
      final band = tester.getRect(_band);
      // 자리 — 좌우 8 · 아래 8 · 가운데(폭 390 − 16 = 374 ≤ 464)
      expect(band.left, 8);
      expect(390 - band.right, 8);
      expect(800 - band.bottom, 8);
      // 높이 — 한 줄 글은 최소 44 안(글 19 + 위아래 10)
      expect(band.height, greaterThanOrEqualTo(44));
      expect(band.height, lessThan(52));
      // 모서리 8 · 면 색 bg-neutral-inverted · 그림자 없음
      final deco =
          tester.widget<DecoratedBox>(_band).decoration as BoxDecoration;
      expect(deco.borderRadius, BorderRadius.circular(8));
      expect(deco.color, c.bgNeutralInverted);
      expect(deco.boxShadow, isNull);
      // 글 t4 · 400 · fg-neutral-inverted
      final msg = tester.widget<Text>(
        find.byKey(const ValueKey('snackbar-message')),
      );
      expect(msg.style!.fontSize, 14);
      expect(msg.style!.fontWeight, FontWeight.w400);
      expect(msg.style!.color, c.fgNeutralInverted);
      expect(msg.style!.height! * msg.style!.fontSize!, closeTo(19, 0.6));
      // 아이콘 — 칸 24 안 그림 22 · fg-positive-inverted
      final icon = tester.widget<Icon>(
        find.byKey(const ValueKey('snackbar-icon')),
      );
      expect(icon.size, 22);
      expect(icon.color, c.fgPositiveInverted);
      final iconBox = tester.getRect(
        find
            .ancestor(
              of: find.byKey(const ValueKey('snackbar-icon')),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(iconBox.width, 24);
      // 글은 띠 가장자리에서 40(아이콘 있음)
      expect(
        tester.getRect(find.byKey(const ValueKey('snackbar-message'))).left -
            band.left,
        closeTo(40, 0.5),
      );
      // 액션 t4 · 700 · fg-brand-inverted, 누르는 자리 높이 44
      final act = tester.widget<Text>(_action);
      expect(act.style!.fontSize, 14);
      expect(act.style!.fontWeight, FontWeight.w700);
      expect(act.style!.color, c.fgBrandInverted);
      await tester.tap(_action);
      await tester.pump();
      expect(undone, 1);
    });

    testWidgets('critical 아이콘 색 · neutral 은 아이콘 없음', (tester) async {
      final api = await _mount(
        tester,
        home: const Scaffold(body: SizedBox.expand()),
      );
      await _show(tester, api, tone: PSnackbarTone.critical);
      final c = tester.element(_band).colors;
      expect(
        tester.widget<Icon>(find.byKey(const ValueKey('snackbar-icon'))).color,
        c.fgCriticalInverted,
      );
      api.dismiss();
      await tester.pump(const Duration(milliseconds: 300));
      await _show(tester, api);
      expect(find.byKey(const ValueKey('snackbar-icon')), findsNothing);
    });

    testWidgets('다크는 밝은 띠(bg-neutral-inverted 가 다크 값)', (tester) async {
      final api = await _mount(
        tester,
        home: const Scaffold(body: SizedBox.expand()),
        mode: Brightness.dark,
      );
      await _show(tester, api);
      final c = tester.element(_band).colors;
      final deco =
          tester.widget<DecoratedBox>(_band).decoration as BoxDecoration;
      expect(deco.color, c.bgNeutralInverted);
      expect(
        ThemeData.estimateBrightnessForColor(deco.color!),
        Brightness.light,
      );
    });

    testWidgets('넓은 화면은 최대 464 가운데 · 안전 영역(34)이 있으면 그 위 8', (tester) async {
      final api = await _mount(
        tester,
        home: const Scaffold(body: SizedBox.expand()),
        size: const Size(1000, 800),
        safeBottom: 34,
      );
      await _show(tester, api);
      final band = tester.getRect(_band);
      expect(band.width, 464);
      expect(band.center.dx, closeTo(500, 0.5));
      expect(800 - band.bottom, 34 + 8);
    });

    testWidgets('보조 기술용 닫기는 이름 "닫기" 로 읽히고 평소에는 보이지 않는다', (tester) async {
      final handle = tester.ensureSemantics();
      final api = await _mount(
        tester,
        home: const Scaffold(body: SizedBox.expand()),
      );
      await _show(tester, api);
      expect(find.bySemanticsLabel('닫기'), findsOneWidget);
      expect(find.byKey(const ValueKey('snackbar-close')), findsNothing);
      handle.dispose();
    });
  });

  group('앱 호스트 — 다른 화면에 주는 영향', () {
    testWidgets('키보드가 올라오면 띠는 키보드 바로 위 8 에 선다(내용을 밀지 않고 위에 겹친다)', (
      tester,
    ) async {
      final api = await _mount(
        tester,
        home: Scaffold(
          resizeToAvoidBottomInset: false,
          body: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: 700,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: TextField(key: const ValueKey('field')),
              ),
            ),
          ),
        ),
        viewInsets: 300,
      );
      await _show(tester, api);
      final band = tester.getRect(_band);
      // 띠 아래 끝 = 키보드 윗변(800 − 300) − 8
      expect(800 - 300 - band.bottom, 8);
      // 띠는 키보드에 가려지지 않는다
      expect(band.bottom, lessThanOrEqualTo(800 - 300));
    });

    testWidgets('띠 밖은 그대로 눌린다 — 띠 위쪽 버튼이 눌리고, 띠 자리는 띠가 받는다', (tester) async {
      var topTaps = 0;
      var bottomTaps = 0;
      final api = await _mount(
        tester,
        home: Scaffold(
          body: Stack(
            children: [
              Positioned(
                top: 100,
                left: 0,
                right: 0,
                child: TextButton(
                  onPressed: () => topTaps++,
                  child: const Text('위'),
                ),
              ),
              // 띠가 서는 자리 바로 아래 줄 전체에 걸친 버튼
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 120,
                child: TextButton(
                  onPressed: () => bottomTaps++,
                  child: const Text('아래'),
                ),
              ),
            ],
          ),
        ),
      );
      await _show(
        tester,
        api,
        action: PSnackbarAction(label: '되돌리기', onPressed: () {}),
      );
      await tester.tap(findText('위'));
      expect(topTaps, 1);
      // 띠 왼쪽 바깥 여백(좌 8 안, x=3) 은 아래 버튼으로 간다
      await tester.tapAt(Offset(3, tester.getRect(_band).center.dy));
      expect(bottomTaps, 1);
      // 띠 글 자리는 띠가 받는다(아래 버튼에 안 간다)
      await tester.tapAt(tester.getRect(_band).center);
      expect(bottomTaps, 1);
    });

    testWidgets('대화상자 위에 뜨고, 띠 액션을 눌러도 대화상자는 닫히지 않는다', (tester) async {
      var undone = 0;
      late BuildContext inner;
      final api = await _mount(
        tester,
        home: Builder(
          builder: (context) {
            inner = context;
            return const Scaffold(body: SizedBox.expand());
          },
        ),
      );
      showDialog<void>(
        context: inner,
        builder: (_) => const AlertDialog(content: Text('대화상자')),
      );
      await tester.pumpAndSettle();
      await _show(
        tester,
        api,
        action: PSnackbarAction(label: '되돌리기', onPressed: () => undone++),
      );
      // 띠 한가운데를 누르면 맨 위에서 띠가 받는다
      expect(
        tester.getRect(_band).bottom,
        lessThan(tester.view.physicalSize.height),
      );
      await tester.tap(_action);
      await tester.pump();
      expect(undone, 1);
      expect(findText('대화상자'), findsOneWidget);
    });

    testWidgets('잠금 화면 아래 — 잠겨 있으면 띠가 가려지고 눌리지 않는다', (tester) async {
      var undone = 0;
      final api = await _mount(
        tester,
        home: const Scaffold(body: SizedBox.expand()),
        locked: true,
      );
      await _show(
        tester,
        api,
        action: PSnackbarAction(label: '되돌리기', onPressed: () => undone++),
      );
      await tester.tap(_action, warnIfMissed: false);
      await tester.pump();
      expect(undone, 0);
    });

    testWidgets('읽는 순서 — 띠는 화면 다음에 읽히는 라이브 영역이다', (tester) async {
      final handle = tester.ensureSemantics();
      final api = await _mount(
        tester,
        home: const Scaffold(body: Center(child: Text('화면 글'))),
      );
      await _show(tester, api);
      final screen = tester.getSemantics(findText('화면 글'));
      final band = tester.getSemantics(
        find.byKey(const ValueKey('snackbar-message')),
      );
      // 라이브 영역 — 초점을 옮기지 않고 읽힌다
      var node = band;
      var live = false;
      SemanticsNode? n = node;
      while (n != null) {
        if (n.getSemanticsData().hasFlag(SemanticsFlag.isLiveRegion))
          live = true;
        n = n.parent;
      }
      expect(live, isTrue);
      // 순서 — 화면 글의 정렬 키가 띠보다 앞이다(띠가 호스트 Stack 의 뒤 자식)
      expect(
        tester.getRect(findText('화면 글')).top,
        lessThan(tester.getRect(_band).top),
      );
      expect(screen.id, isNot(band.id));
      handle.dispose();
    });
  });
}
