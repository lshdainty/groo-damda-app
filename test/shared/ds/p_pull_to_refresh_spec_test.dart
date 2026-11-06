// Pull To Refresh 가 스펙 값(test/fixtures/design_spec/pull-to-refresh.json)대로인지 — 문턱 88 · 배율 0.75 · 지시자 칸 88 ·
// 원 24 neutral · 당기는 동안 채움 · 놓으면 88 에 머묾 · 끝나면 제자리 · 모션 줄이기 · 보조 기술. 웹은 두지 않는다.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/progress_circle/p_progress_circle.dart';
import 'package:groo_damda_app/shared/ds/pull_to_refresh/p_pull_to_refresh.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import 'package:go_router/go_router.dart';
import 'package:groo_damda_app/app/app.dart' show appMessengerKey;
import 'package:groo_damda_app/app/session_scope.dart';

import '../../support/design_spec.dart';
import '../../support/plain_text.dart';

final _spec = DesignSpec.load('pull-to-refresh');

Widget _host(
  Widget child, {
  bool reduceMotion = false,
  Brightness mode = Brightness.light,
  double textScale = 1,
}) {
  final app = MaterialApp(
    theme: mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('ko'),
    // 앱 뿌리와 같이 길잡이 바깥에 Snackbar 호스트를 둔다
    builder: (context, child) => Material(
      type: MaterialType.transparency,
      child: PSnackbarHost(closeLabel: '닫기', child: child!),
    ),
    home: Scaffold(body: child),
  );
  return MediaQuery(
    data: MediaQueryData(
      disableAnimations: reduceMotion,
      textScaler: TextScaler.linear(textScale),
      size: const Size(360, 640),
    ),
    child: app,
  );
}

Widget _list({
  required Future<void> Function() onRefresh,
  int count = 30,
  bool reduceMotion = false,
  Brightness mode = Brightness.light,
  double textScale = 1,
}) => _host(
  PPullToRefresh(
    onRefresh: onRefresh,
    child: ListView(
      children: [
        for (var i = 0; i < count; i++)
          SizedBox(height: 56, child: Text('줄 $i', key: ValueKey('row$i'))),
      ],
    ),
  ),
  reduceMotion: reduceMotion,
  mode: mode,
  textScale: textScale,
);

PPullToRefreshState _state(WidgetTester tester) =>
    tester.state<PPullToRefreshState>(find.byType(PPullToRefresh));

Finder get _circle => find.byKey(const ValueKey('pull-to-refresh-circle'));

/// 손가락으로 [dy] 만큼 아래로 끈다(touchSlop 을 먼저 넘긴 뒤) — 놓지 않는다.
Future<TestGesture> _pull(WidgetTester tester, double dy) async {
  final g = await tester.startGesture(const Offset(180, 200));
  // 슬롭(18)을 넘긴 첫 움직임은 델타로 세지 않는다 — 넘기고 나서 dy 만큼 더 끈다
  await g.moveBy(const Offset(0, 24));
  await tester.pump();
  await g.moveBy(Offset(0, dy));
  await tester.pump();
  return g;
}

void main() {
  test('스펙 값 — 문턱 88 · 배율 0.75 · 지시자 칸 88 · 원 24', () {
    final w = _spec.resolve({}, 'idle');
    expect(w['root.threshold'], 88);
    expect(w['root.multiplier'], '0.75');
    expect(w['indicator.height'], 88);
    expect(w['circle.size'], 24);
    expect(kPullToRefreshThreshold, 88);
    expect(kPullToRefreshMultiplier, 0.75);
  });

  testWidgets('쉴 때는 내용이 제자리이고 지시자는 보이지 않으며 보조 기술에도 숨는다', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_list(onRefresh: () async {}));
    expect(_state(tester).state, PPullToRefreshPhase.idle);
    expect(_state(tester).offset, 0);
    expect(
      tester
          .widget<Opacity>(
            find.ancestor(of: _circle, matching: find.byType(Opacity)).first,
          )
          .opacity,
      0,
    );
    expect(find.bySemanticsLabel('새로 고치는 중'), findsNothing);
    semantics.dispose();
  });

  testWidgets('당기는 동안 내용이 손가락 × 0.75 만큼 내려오고 원이 당긴 비율만큼 채워진다', (tester) async {
    await tester.pumpWidget(_list(onRefresh: () async {}));
    final top = tester.getTopLeft(find.byKey(const ValueKey('row0'))).dy;
    final g = await _pull(tester, 40);
    final first = _state(tester).offset;
    expect(first, closeTo((24 + 40) * 0.75, 0.01));
    expect(_state(tester).state, PPullToRefreshPhase.pulling);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('row0'))).dy,
      closeTo(top + first, 0.01),
    );
    await g.moveBy(const Offset(0, 20));
    await tester.pump();
    expect(
      _state(tester).offset,
      closeTo(first + 15, 0.01),
      reason: '20 더 끌면 15 더 내려온다',
    );
    // 원 — 값 있는 원, 값 = 당긴 거리 ÷ 88 × 100
    final circle = tester.widget<PProgressCircle>(_circle);
    expect(circle.value, closeTo(_state(tester).offset / 88 * 100, 0.01));
    expect(circle.animateValue, isFalse);
    expect(circle.size, PProgressCircleSize.s24);
    expect(
      circle.tone ?? PProgressCircleTone.neutral,
      PProgressCircleTone.neutral,
    );
    // 지시자 칸은 따라 내려오고 투명도는 당긴 거리 ÷ 88
    final opacity = tester
        .widget<Opacity>(
          find.ancestor(of: _circle, matching: find.byType(Opacity)).first,
        )
        .opacity;
    expect(opacity, closeTo(_state(tester).offset / 88, 0.001));
    await g.up();
    await tester.pumpAndSettle();
    expect(_state(tester).offset, 0);
  });

  testWidgets('당기는 동안 지시자는 보조 기술에 숨긴다', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_list(onRefresh: () async {}));
    final g = await _pull(tester, 60);
    expect(find.bySemanticsLabel('새로 고치는 중'), findsNothing);
    await g.up();
    await tester.pumpAndSettle();
    semantics.dispose();
  });

  testWidgets('위로 되돌리면 0 에 머문다 — 음수로 가지 않는다', (tester) async {
    await tester.pumpWidget(_list(onRefresh: () async {}));
    final g = await _pull(tester, 40);
    await g.moveBy(const Offset(0, -200));
    await tester.pump();
    expect(_state(tester).offset, greaterThanOrEqualTo(0));
    expect(_state(tester).offset, lessThan(1));
    await g.up();
    await tester.pumpAndSettle();
  });

  testWidgets('문턱(손가락 약 117) 전에 놓으면 새로 고치지 않고 300ms 에 제자리로 간다', (tester) async {
    var calls = 0;
    await tester.pumpWidget(_list(onRefresh: () async => calls++));
    final g = await _pull(tester, 90);
    expect(_state(tester).offset, lessThan(88));
    expect(_state(tester).state, PPullToRefreshPhase.pulling);
    await g.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(_state(tester).offset, greaterThan(0), reason: '움직이는 중');
    await tester.pump(const Duration(milliseconds: 200));
    expect(_state(tester).offset, 0);
    expect(_state(tester).state, PPullToRefreshPhase.idle);
    expect(calls, 0);
  });

  testWidgets('문턱을 넘기면 원이 꽉 차고, 놓으면 돌며 내용이 88 에 끝날 때까지 머문다', (tester) async {
    final semantics = tester.ensureSemantics();
    final done = Completer<void>();
    var calls = 0;
    await tester.pumpWidget(
      _list(
        onRefresh: () {
          calls++;
          return done.future;
        },
      ),
    );
    final g = await _pull(tester, 140);
    expect(_state(tester).state, PPullToRefreshPhase.ready);
    expect(
      _state(tester).offset,
      greaterThan(88),
      reason: '문턱을 넘어서도 손가락을 따라온다',
    );
    expect(tester.widget<PProgressCircle>(_circle).value, 100);
    await g.up();
    await tester.pump();
    expect(calls, 1);
    expect(_state(tester).state, PPullToRefreshPhase.refreshing);
    await tester.pump(const Duration(milliseconds: 400));
    expect(_state(tester).offset, closeTo(88, 0.01));
    // 값 없는 원 + "새로 고치는 중" 으로 읽힌다
    expect(tester.widget<PProgressCircle>(_circle).value, isNull);
    expect(find.bySemanticsLabel('새로 고치는 중'), findsOneWidget);
    // 끝나기 전에는 머문다 — 그동안 끌기는 받지 않는다
    final g2 = await _pull(tester, 60);
    expect(_state(tester).state, PPullToRefreshPhase.refreshing);
    expect(_state(tester).offset, closeTo(88, 0.01));
    await g2.up();
    await tester.pump(const Duration(seconds: 1));
    expect(_state(tester).offset, closeTo(88, 0.01));
    expect(calls, 1);
    // 끝나면 300ms 에 제자리로
    done.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(_state(tester).offset, inExclusiveRange(0, 88));
    await tester.pump(const Duration(milliseconds: 200));
    expect(_state(tester).offset, 0);
    expect(_state(tester).state, PPullToRefreshPhase.idle);
    semantics.dispose();
  });

  testWidgets('실패해도 내용을 둔 채 제자리로 돌아오고 Snackbar 로 알린다', (tester) async {
    await tester.pumpWidget(
      _list(onRefresh: () async => throw StateError('boom')),
    );
    final g = await _pull(tester, 140);
    await g.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    expect(_state(tester).offset, 0);
    expect(_state(tester).state, PPullToRefreshPhase.idle);
    expect(findText('줄 0'), findsOneWidget, reason: '보던 내용은 그대로');
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Text &&
            (w.data ?? '').replaceAll('\u2060', '').replaceAll('\u200b', '') ==
                '새로 고치지 못했어요.',
      ),
      findsOneWidget,
    );
    expect(find.byType(SnackBar), findsNothing);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('실패 알림에는 "다시 시도" 액션이 있고, 누르면 같은 새로 고침을 한 번 더 부른다', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      _list(
        onRefresh: () async {
          calls++;
          if (calls == 1) throw StateError('boom');
        },
      ),
    );
    final g = await _pull(tester, 140);
    await g.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(calls, 1);
    bool plain(Widget w, String t) =>
        w is Text &&
        (w.data ?? '').replaceAll('\u2060', '').replaceAll('\u200b', '') == t;
    final retry = find.byWidgetPredicate((w) => plain(w, '다시 시도'));
    expect(retry, findsOneWidget);
    await tester.tap(retry);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(calls, 2, reason: '액션이 같은 onRefresh 를 한 번 더 부른다');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(_state(tester).state, PPullToRefreshPhase.idle);
    expect(_state(tester).offset, 0);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('다시 시도도 실패하면 알림이 다시 뜬다', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      _list(
        onRefresh: () async {
          calls++;
          throw StateError('boom');
        },
      ),
    );
    final g = await _pull(tester, 140);
    await g.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    bool retryText(Widget w) =>
        w is Text &&
        (w.data ?? '').replaceAll('\u2060', '').replaceAll('\u200b', '') ==
            '다시 시도';
    await tester.tap(find.byWidgetPredicate(retryText));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(calls, 2);
    expect(find.byWidgetPredicate(retryText), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('모션 줄이기면 놓았을 때 바로 88 로, 끝나면 바로 제자리로 간다', (tester) async {
    final done = Completer<void>();
    await tester.pumpWidget(
      _list(onRefresh: () => done.future, reduceMotion: true),
    );
    final g = await _pull(tester, 140);
    await g.up();
    await tester.pump();
    expect(_state(tester).offset, 88);
    done.complete();
    await tester.pump();
    expect(_state(tester).offset, 0);
    expect(_state(tester).state, PPullToRefreshPhase.idle);
  });

  testWidgets('내용이 짧아 스크롤되지 않아도 당겨진다', (tester) async {
    await tester.pumpWidget(_list(onRefresh: () async {}, count: 2));
    final g = await _pull(tester, 60);
    expect(_state(tester).offset, closeTo((24 + 60) * 0.75, 0.01));
    await g.up();
    await tester.pumpAndSettle();
  });

  testWidgets('맨 위가 아닐 때(내용을 내려 둔 채)의 끌기는 당기기가 아니다', (tester) async {
    await tester.pumpWidget(_list(onRefresh: () async {}));
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    final g = await tester.startGesture(const Offset(180, 200));
    await g.moveBy(const Offset(0, 24));
    await g.moveBy(const Offset(0, 60));
    await tester.pump();
    expect(_state(tester).offset, 0);
    await g.up();
    await tester.pumpAndSettle();
  });

  testWidgets('가로로 넘기는 영역에서 시작한 끌기는 당기기가 아니다', (tester) async {
    await tester.pumpWidget(
      _host(
        PPullToRefresh(
          onRefresh: () async {},
          child: ListView(
            children: [
              SizedBox(
                height: 80,
                child: ListView(
                  key: const ValueKey('inner'),
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (var i = 0; i < 10; i++)
                      SizedBox(width: 120, child: Text('칸 $i')),
                  ],
                ),
              ),
              for (var i = 0; i < 20; i++)
                SizedBox(height: 56, child: Text('줄 $i')),
            ],
          ),
        ),
      ),
    );
    final g = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('inner'))),
    );
    await g.moveBy(const Offset(40, 0));
    await g.moveBy(const Offset(40, 0));
    await g.moveBy(const Offset(0, 30));
    await tester.pump();
    expect(_state(tester).offset, 0);
    await g.up();
    await tester.pumpAndSettle();
  });

  for (final mode in Brightness.values) {
    testWidgets(
      '${mode.name} · 글자 200% — 원은 neutral 색, 크기 24, 글자 배율에 따라 변하지 않는다',
      (tester) async {
        await tester.pumpWidget(
          _list(onRefresh: () async {}, mode: mode, textScale: 2),
        );
        final g = await _pull(tester, 60);
        final c = mode == Brightness.dark ? PColors.dark : PColors.light;
        expect(
          tester
              .getSize(
                find
                    .descendant(of: _circle, matching: find.byType(SizedBox))
                    .first,
              )
              .width,
          24,
        );
        final painter = tester
            .widgetList<CustomPaint>(
              find.descendant(of: _circle, matching: find.byType(CustomPaint)),
            )
            .map((p) => p.painter)
            .whereType<PProgressCirclePainter>()
            .single;
        expect(painter.track, c.strokeNeutralSubtle);
        expect(painter.range, c.strokeNeutralSolid);
        expect(painter.thickness, 3);
        await g.up();
        await tester.pumpAndSettle();
      },
    );
  }

  testWidgets(
    '앱 뿌리와 같은 구성(SessionScope + MaterialApp.router + 전역 messenger 키 + Snackbar 호스트)에서 실패하면 오류 알림이 실제로 뜬다',
    (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, _) => Scaffold(
              body: PPullToRefresh(
                onRefresh: () async => throw Exception('boom'),
                child: ListView(
                  children: [
                    for (var i = 0; i < 30; i++)
                      SizedBox(height: 56, child: Text('줄 $i')),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        SessionScope(
          child: MaterialApp.router(
            scaffoldMessengerKey: appMessengerKey,
            routerConfig: router,
            builder: (context, child) => Material(
              type: MaterialType.transparency,
              child: PSnackbarHost(closeLabel: '닫기', child: child!),
            ),
            theme: GrooTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final g = await _pull(tester, 140);
      await g.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Text &&
              (w.data ?? '')
                      .replaceAll('\u2060', '')
                      .replaceAll('\u200b', '') ==
                  '새로 고치지 못했어요.',
        ),
        findsOneWidget,
      );
      // 옛 Material 띠는 뜨지 않는다 — ds Snackbar 하나뿐
      expect(find.byType(SnackBar), findsNothing);
      await tester.pump(const Duration(seconds: 6));
    },
  );
}
