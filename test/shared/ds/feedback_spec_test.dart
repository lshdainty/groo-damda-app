// 11 피드백 묶음(Snackbar · Callout · Page Banner · Result Section)이 스펙 값(test/fixtures/design_spec/
// {snackbar,callout,page-banner,result-section}.json)대로 그려지는지 — 조합 × 상태 × 라이트 · 다크를 모두 돈다.
// 웹은 같은 JSON 을 크로미움에서 잰다(desk-front `npm run ds:check`).
//
// 앱에 없는 상태(웹의 hovered · focused — 올림 · 포커스 링)는 재지 않는다. 문장으로 된 값은 그린 결과나 동작으로 본다 —
// 누름 축소("세로 2px 축소")는 그려진 배율로, 누르는 영역("44 × 44")은 넓힌 자리를 눌러서, 시간("4000ms")은 흐르는
// 시간으로, 그림자 없음은 그려진 장식으로 잰다. 스펙이 정한 동작(한 번에 하나 · 멈춤 · 피할 자리)은 아래 동작 group 이 본다.
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/text_button/p_text_button.dart';
import 'package:groo_damda_app/shared/ds/callout/feedback_parts.dart';
import 'package:groo_damda_app/shared/ds/callout/p_callout.dart';
import 'package:groo_damda_app/shared/ds/page_banner/p_page_banner.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import 'package:groo_damda_app/shared/ds/snackbar/snackbar_demo.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';

import '../../support/design_spec.dart';
import '../../support/plain_text.dart';

final _snackbar = DesignSpec.load('snackbar');
final _callout = DesignSpec.load('callout');
final _pageBanner = DesignSpec.load('page-banner');
final _result = DesignSpec.load('result-section');

/// 앱의 상태 — 웹의 hovered(올림) · focused(키보드 포커스 링)는 앱에 없다.
List<String> _appStates(DesignSpec spec) =>
    spec.states.where((s) => s != 'hovered' && s != 'focused').toList();

ThemeData _theme(Brightness mode) =>
    mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light();

MaterialApp _app(Brightness mode, {Widget? home, TransitionBuilder? builder}) {
  final app = MaterialApp(
    theme: _theme(mode),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('ko'),
    builder: builder,
    home: home,
  );
  return app;
}

/// 폰이 아닌 넓은 화면 — 최대 폭이 있는 띠를 재려고. 테스트가 끝나면 되돌린다.
void _viewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// 놓인 자리를 정해 그린다 — 폭 [width] 안에서 위에 붙는다(높이는 내용만큼).
Widget _placed(
  Brightness mode,
  Widget child, {
  double width = 320,
  bool reduceMotion = false,
}) {
  final app = _app(
    mode,
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: width, child: child),
      ),
    ),
  );
  return reduceMotion
      ? MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: app,
        )
      : app;
}

/// 전환(색 150ms · 누름 축소 150ms · 나타남 150ms)이 끝나게 기다린다. 누름이면 누른 채로 둔다.
Future<TestGesture?> _settle(
  WidgetTester tester,
  String state,
  Finder target,
) async {
  TestGesture? gesture;
  if (state == 'pressed') {
    gesture = await tester.startGesture(tester.getCenter(target));
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 400));
  return gesture;
}

/// 실패를 모으는 도우미 — 색 · 수 · 글자를 스펙과 맞춘다.
class _Check {
  _Check(this.mode, this.want, this.where);

  final Brightness mode;
  final Map<String, Object?> want;
  final String where;
  final failures = <String>[];

  void fail(String message) => failures.add('$where — $message');

  void color(String key, Color actual) {
    final w = pickMode(want[key], mode);
    if (w == null) return;
    if (!sameColor(specColor(w), actual)) {
      fail('$key: 스펙 $w · 실제 ${colorHex(actual)}');
    }
  }

  void px(String key, num actual) {
    final w = want[key];
    if (w is num && (w - actual).abs() > 0.5) {
      fail('$key: 스펙 $w · 실제 $actual');
    }
  }

  /// 스펙 값에서 [minus] 를 뺀 값과 맞춘다(블리드처럼 스펙이 한 값에서 파생되는 자리).
  void pxMinus(String key, num minus, num actual) {
    final w = want[key];
    if (w is num && (w - minus - actual).abs() > 0.5) {
      fail('$key − $minus: 스펙 ${w - minus} · 실제 $actual');
    }
  }

  void exact(String key, num actual) {
    final w = want[key];
    if (w is num && (w - actual).abs() > 1e-3) {
      fail('$key: 스펙 $w · 실제 $actual');
    }
  }

  void typo(String key, TextStyle style) {
    final t = want[key] as Map?;
    if (t == null) return;
    final lineHeight = style.fontSize! * (style.height ?? 1);
    if (t['fontSize'] != style.fontSize ||
        ((t['lineHeight'] as num) - lineHeight).abs() > 0.01) {
      fail(
        '$key: 스펙 ${t['fontSize']}/${t['lineHeight']} · 실제 ${style.fontSize}/$lineHeight',
      );
    }
    final family = '${t['fontFamily']}'.split(',').first.trim();
    if (style.fontFamily != family) {
      fail('$key 글꼴: 스펙 $family · 실제 ${style.fontFamily}');
    }
  }

  void weight(String key, TextStyle style) {
    final w = want[key];
    if (w is num && style.fontWeight?.value != w) {
      fail('$key: 스펙 $w · 실제 ${style.fontWeight}');
    }
  }
}

void _expectClean(List<String> failures) {
  if (failures.isNotEmpty) {
    fail('${failures.length}개가 스펙과 다르다\n${failures.join('\n')}');
  }
}

/// 눌린 배율 — (기준 − 2) ÷ 기준.
double _pressScale(num basis) => (basis - 2) / basis;

/// 스펙의 누름 축소 시간 · 곡선(예: "150ms" · "cubic-bezier(0, 0, 0.15, 1)")을 위젯의 [AnimatedScale] 과 맞춘다.
void _checkScaleMotion(
  _Check k,
  AnimatedScale scale,
  String slot, {
  required String durationKey,
  required String easingKey,
}) {
  final duration = specMs(k.want['$slot.$durationKey']);
  if (scale.duration != duration) {
    k.fail('$slot.$durationKey: 스펙 $duration · 실제 ${scale.duration}');
  }
  final cubic = specCubic(k.want['$slot.$easingKey']);
  final curve = scale.curve;
  if (curve is! Cubic ||
      curve.a != cubic[0] ||
      curve.b != cubic[1] ||
      curve.c != cubic[2] ||
      curve.d != cubic[3]) {
    k.fail('$slot.$easingKey: 스펙 $cubic · 실제 $curve');
  }
}

/// 글 조각의 실제 스타일 — 뿌리 스타일 위에 그 조각의 스타일을 덮는다.
TextStyle _spanStyle(TextSpan root, String text) {
  TextStyle? found;
  void visit(TextSpan span, TextStyle inherited) {
    final style = inherited.merge(span.style);
    if (span.text != null && span.text!.contains(text)) found = style;
    for (final child in span.children ?? const <InlineSpan>[]) {
      if (child is TextSpan) visit(child, style);
    }
  }

  visit(root, const TextStyle());
  if (found == null) throw StateError('글 조각이 없다: $text');
  return found!;
}

/// [Text.rich] 의 뿌리 조각.
TextSpan _rootSpan(WidgetTester tester, Finder text) =>
    tester
            .widget<RichText>(
              // 링크(WidgetSpan)가 안에 또 RichText 를 품으므로 바깥 것이 첫째다
              find.descendant(of: text, matching: find.byType(RichText)).first,
            )
            .text
        as TextSpan;

const _closeLabel = '닫기';

void main() {
  // ══════════════════════════════════════════════════════════════
  // Snackbar
  // ══════════════════════════════════════════════════════════════
  group('Snackbar 모양', () {
    Widget view(
      PSnackbarTone tone, {
      bool withAction = true,
      String message = '거래를 삭제했어요.',
      VoidCallback? onAction,
    }) => PSnackbarView(
      tone: tone,
      message: message,
      closeLabel: _closeLabel,
      action: withAction
          ? PSnackbarAction(label: '되돌리기', onPressed: onAction ?? () {})
          : null,
    );

    for (final mode in Brightness.values) {
      testWidgets('${mode.name} — 톤 × 상태가 스펙 값이다', (tester) async {
        _viewport(tester, const Size(800, 600));
        final failures = <String>[];
        for (final combo in _snackbar.combos(['tone'])) {
          final tone = PSnackbarTone.values.byName(combo['tone']!);
          for (final state in _appStates(_snackbar)) {
            await tester.pumpWidget(_placed(mode, view(tone), width: 800));
            final action = find.byKey(const ValueKey('snackbar-action'));
            final gesture = await _settle(tester, state, action);
            final k = _Check(
              mode,
              _snackbar.resolve(combo, state),
              '${mode.name} $combo $state',
            );

            final band = find.byKey(const ValueKey('snackbar-band'));
            final rect = tester.getRect(band);
            // ── 띠 ──
            k.px('root.maxWidth', rect.width);
            k.px('root.minHeight', rect.height);
            final deco =
                tester.widget<DecoratedBox>(band).decoration as BoxDecoration;
            k.px('root.radius', (deco.borderRadius! as BorderRadius).topLeft.x);
            k.color('root.background', deco.color!);
            // 그림자 없이 면 색으로 뜬다 — 장식에 그림자가 없고 Material 의 올림도 없다
            if (k.want['root.shadow'] == 'none') {
              if (deco.boxShadow != null && deco.boxShadow!.isNotEmpty) {
                k.fail('root.shadow: none 인데 그림자가 있다');
              }
              for (final type in [Material, PhysicalModel, PhysicalShape]) {
                if (find
                    .descendant(
                      of: band,
                      matching: find.byElementPredicate(
                        (e) => e.widget.runtimeType == type,
                      ),
                    )
                    .evaluate()
                    .isNotEmpty) {
                  k.fail('root.shadow: none 인데 $type 이 있다');
                }
              }
            }

            // ── 아이콘 ──
            final hasIcon = tone != PSnackbarTone.neutral;
            final icon = find.byKey(const ValueKey('snackbar-icon'));
            expect(icon, hasIcon ? findsOneWidget : findsNothing);
            var messageStart = rect.left + (k.want['root.padding']! as num);
            if (hasIcon) {
              final box = tester.getRect(
                find.ancestor(of: icon, matching: find.byType(SizedBox)).first,
              );
              k.px('icon.size', box.width);
              k.px('icon.size', box.height);
              // 그림은 칸 안 오른쪽 여백 2 를 뺀 22
              k.px('icon.paddingRight', box.right - tester.getRect(icon).right);
              // 그림은 칸 안 오른쪽 여백 2 를 뺀 22 — 칸 높이가 24 라 그림 칸도 세로는 24 로 서고 글자만 22 다
              final glyph = tester.widget<Icon>(icon).size!;
              k.px('icon.size', glyph + (k.want['icon.paddingRight']! as num));
              k.px('root.padding', box.left - rect.left);
              k.px('root.padding', box.top - rect.top);
              k.color('icon.color', tester.widget<Icon>(icon).color!);
              expect(
                tester.widget<Icon>(icon).icon,
                tone == PSnackbarTone.positive
                    ? LucideIcons.circleCheck
                    : LucideIcons.circleAlert,
              );
              messageStart = box.right;
            }

            // ── 글 ──
            final message = find.byKey(const ValueKey('snackbar-message'));
            final text = tester.widget<Text>(message);
            k.typo('message.typography', text.style!);
            k.weight('message.fontWeight', text.style!);
            k.color('message.foreground', text.style!.color!);
            // 글은 띠 가장자리에서 16(아이콘이 있으면 40)
            if (state == 'enabled') {
              k.px(
                'content.paddingX',
                tester.getRect(message).left - messageStart,
              );
            }

            // ── 액션 ──
            final actionText = tester.widget<Text>(action);
            k.typo('action.typography', actionText.style!);
            k.weight('action.fontWeight', actionText.style!);
            k.color('action.foreground', actionText.style!.color!);
            if (state == 'enabled') {
              // 글과 액션은 양 끝 — 사이는 적어도 10
              final messageBox = tester.getRect(
                find
                    .ancestor(of: message, matching: find.byType(Padding))
                    .first,
              );
              k.px(
                'content.gap',
                tester.getRect(action).left - messageBox.right,
              );
              // 액션 오른쪽은 띠 가장자리에서 16(띠 여백 10 + 글 좌우 6)
              k.px(
                'content.paddingX',
                rect.right - tester.getRect(action).right - 10,
              );
            }

            // ── 누름 ──
            if (state == 'pressed') {
              final scale = tester.widget<AnimatedScale>(
                find.ancestor(of: action, matching: find.byType(AnimatedScale)),
              );
              // 기준 max(높이, 폭 ÷ 4, 24) — 글 한 줄 19 × 폭 ÷ 4 는 24 보다 작다
              final size = tester.getSize(action);
              final basis = math.max(size.height, math.max(size.width / 4, 24));
              if ((scale.scale - _pressScale(basis)).abs() > 1e-6) {
                k.fail(
                  'action.scale: 기준 $basis 의 ${_pressScale(basis)} · 실제 ${scale.scale}',
                );
              }
              _checkScaleMotion(
                k,
                scale,
                'action',
                durationKey: 'scaleDuration',
                easingKey: 'scaleEasing',
              );
            }
            await gesture?.up();
            await tester.pump(const Duration(milliseconds: 400));
            failures.addAll(k.failures);
          }
        }
        _expectClean(failures);
      });
    }
  });

  group('Snackbar 동작', () {
    final bandFinder = find.byKey(const ValueKey('snackbar-band'));

    /// 호스트를 앱 맨 위에 두고 띄우는 쪽을 돌려준다. [body] 는 호스트 안의 화면.
    Future<PSnackbarApi> mount(
      WidgetTester tester, {
      Widget? body,
      Brightness mode = Brightness.light,
      bool reduceMotion = false,
    }) async {
      late PSnackbarApi api;
      Widget app = _app(
        mode,
        builder: (context, child) =>
            PSnackbarHost(closeLabel: _closeLabel, child: child!),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              api = PSnackbar.of(context);
              return body ?? const SizedBox.expand();
            },
          ),
        ),
      );
      if (reduceMotion) {
        app = MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: app,
        );
      }
      await tester.pumpWidget(app);
      return api;
    }

    Future<void> advance(WidgetTester tester, int ms) =>
        tester.pump(Duration(milliseconds: ms));

    /// 띄운 뒤 첫 프레임을 그린다(나타나는 중).
    Future<void> show(
      WidgetTester tester,
      PSnackbarApi api, {
      String message = '거래를 저장했어요.',
      PSnackbarTone tone = PSnackbarTone.neutral,
      PSnackbarAction? action,
    }) async {
      api.show(message: message, tone: tone, action: action);
      await tester.pump();
    }

    Future<void> unmount(WidgetTester tester) =>
        tester.pumpWidget(const SizedBox());

    // 띠의 초점 자리 — 호스트는 길잡이 바깥이라 다른 화면에서 Tab 으로 닿지 않는다(터치 앱). 초점이 와 있는 때를 직접 만든다
    FocusNode bandFocus(WidgetTester tester) =>
        Focus.of(tester.element(bandFinder));

    // 키보드로 닿은 초점 — 웹 :focus-visible
    void keyboardMode() {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
    }

    testWidgets('PSnackbar.of 는 호스트 밖이면 어디에 두는지 알려 준다', (tester) async {
      late BuildContext captured;
      await tester.pumpWidget(
        _app(
          Brightness.light,
          home: Builder(
            builder: (context) {
              captured = context;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(PSnackbar.maybeOf(captured), isNull);
      expect(() => PSnackbar.of(captured), throwsAssertionError);
    });

    testWidgets('띄우면 화면 아래 가운데 8 위에 뜬다 — 초점은 옮기지 않는다', (tester) async {
      _viewport(tester, const Size(800, 600));
      final outside = FocusNode();
      addTearDown(outside.dispose);
      final api = await mount(
        tester,
        body: Focus(focusNode: outside, child: const SizedBox.expand()),
      );
      outside.requestFocus();
      await tester.pump();
      await show(tester, api);
      await advance(tester, 200);

      final rect = tester.getRect(bandFinder);
      // 넓은 화면 — 가운데에 최대 464
      expect(rect.width, 464);
      expect(rect.center.dx, 400);
      // region.paddingBottom 8
      expect(
        rect.bottom,
        600 -
            (_snackbar.resolve({
                  'tone': 'neutral',
                }, 'enabled')['region.paddingBottom']!
                as num),
      );
      expect(outside.hasPrimaryFocus, isTrue);
      await unmount(tester);
    });

    testWidgets('폰 폭에서는 좌우 8 을 뺀 만큼이다(region.paddingX)', (tester) async {
      _viewport(tester, const Size(390, 800));
      final api = await mount(tester);
      await show(tester, api);
      await advance(tester, 200);
      final want = _snackbar.resolve({'tone': 'neutral'}, 'enabled');
      final rect = tester.getRect(bandFinder);
      expect(rect.left, want['region.paddingX']);
      expect(rect.right, 390 - (want['region.paddingX']! as num));
      await unmount(tester);
    });

    testWidgets('글이 길면 줄을 바꾸고 자르지 않는다 — 띠가 늘어난다', (tester) async {
      _viewport(tester, const Size(390, 800));
      final api = await mount(tester);
      const long = '1,204건을 가져왔어요. 건너뛴 줄 3건은 가져오기 기록에서 다시 볼 수 있어요.';
      await show(tester, api, message: long);
      await advance(tester, 200);
      expect(tester.getSize(bandFinder).height, greaterThan(44));
      final text = tester.widget<Text>(
        find.byKey(const ValueKey('snackbar-message')),
      );
      expect(text.maxLines, isNull);
      expect(text.overflow, isNull);
      await unmount(tester);
    });

    testWidgets('4초 뒤 닫히고 사라지는 동안은 읽지 않는다 — 끝나면 걷는다', (tester) async {
      final semantics = tester.ensureSemantics();
      final api = await mount(tester);
      await show(tester, api);
      await advance(tester, 3999);
      expect(bandFinder, findsOneWidget);
      await advance(tester, 1);
      // 사라지는 중 — 아직 있고 읽히지 않는다
      expect(bandFinder, findsOneWidget);
      expect(find.semantics.byLabel('거래를 저장했어요.'), findsNothing);
      await advance(tester, 150);
      expect(bandFinder, findsNothing);
      semantics.dispose();
      await unmount(tester);
    });

    testWidgets('액션이 있으면 6초 — 누르면 그 일을 하고 닫는다', (tester) async {
      final api = await mount(tester);
      var restored = 0;
      await show(
        tester,
        api,
        message: '거래를 삭제했어요.',
        action: PSnackbarAction(label: '되돌리기', onPressed: () => restored++),
      );
      await advance(tester, 5999);
      expect(bandFinder, findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('snackbar-action')));
      await advance(tester, 10);
      expect(restored, 1);
      await advance(tester, 150);
      expect(bandFinder, findsNothing);

      await show(
        tester,
        api,
        message: '거래를 삭제했어요.',
        action: PSnackbarAction(label: '되돌리기', onPressed: () => restored++),
      );
      await advance(tester, 6000);
      await advance(tester, 150);
      expect(bandFinder, findsNothing);
      expect(restored, 1);
      await unmount(tester);
    });

    testWidgets('PSnackbar.duration 은 스펙의 4000ms · 액션은 6000ms 다', (
      tester,
    ) async {
      final want = _snackbar.resolve({'tone': 'neutral'}, 'enabled');
      expect(PSnackbar.duration, specMs(want['root.duration']));
      expect(PSnackbar.durationWithAction, const Duration(milliseconds: 6000));
    });

    testWidgets('액션의 일이 던져도 띠는 닫는다 — 던진 것은 삼키지 않는다', (tester) async {
      final api = await mount(tester);
      await show(
        tester,
        api,
        action: PSnackbarAction(
          label: '되돌리기',
          onPressed: () => throw StateError('되돌리지 못함'),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('snackbar-action')));
      await advance(tester, 10);
      await advance(tester, 200);
      expect(tester.takeException(), isStateError);
      expect(bandFinder, findsNothing);
      await unmount(tester);
    });

    testWidgets('액션 누르는 영역은 글 + 좌우 8 × 44 다', (tester) async {
      final api = await mount(tester);
      var count = 0;
      await show(
        tester,
        api,
        action: PSnackbarAction(label: '되돌리기', onPressed: () => count++),
      );
      await advance(tester, 200);
      final action = tester.getRect(
        find.byKey(const ValueKey('snackbar-action')),
      );
      // 글 높이 19 의 위아래로 12 씩 — 44 안
      await tester.tapAt(Offset(action.left - 6, action.center.dy + 20));
      await advance(tester, 200);
      expect(count, 1);

      await show(
        tester,
        api,
        action: PSnackbarAction(label: '되돌리기', onPressed: () => count++),
      );
      await advance(tester, 200);
      final again = tester.getRect(
        find.byKey(const ValueKey('snackbar-action')),
      );
      // 8 을 넘으면 받지 않는다 · 44 를 넘어도 받지 않는다
      await tester.tapAt(Offset(again.left - 12, again.center.dy));
      await tester.tapAt(Offset(again.center.dx, again.center.dy + 24));
      await advance(tester, 100);
      expect(count, 1);
      expect(bandFinder, findsOneWidget);
      await unmount(tester);
    });

    testWidgets('손가락으로 누르고 있으면 멈추고, 떼면 처음부터 다시 센다', (tester) async {
      final api = await mount(tester);
      await show(tester, api);
      await advance(tester, 3000);
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('snackbar-message'))),
      );
      await advance(tester, 10000);
      expect(bandFinder, findsOneWidget);
      await gesture.up();
      await advance(tester, 3999);
      expect(bandFinder, findsOneWidget);
      await advance(tester, 1);
      await advance(tester, 150);
      expect(bandFinder, findsNothing);
      await unmount(tester);
    });

    testWidgets('마우스를 올리면 멈추고, 떠나면 처음부터 다시 센다', (tester) async {
      final api = await mount(tester);
      await show(tester, api);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(1, 1));
      addTearDown(mouse.removePointer);
      await advance(tester, 3000);
      await mouse.moveTo(tester.getCenter(bandFinder));
      await advance(tester, 10000);
      expect(bandFinder, findsOneWidget);
      await mouse.moveTo(const Offset(1, 1));
      await advance(tester, 3999);
      expect(bandFinder, findsOneWidget);
      await advance(tester, 1);
      await advance(tester, 150);
      expect(bandFinder, findsNothing);
      await unmount(tester);
    });

    testWidgets('키보드 초점이 띠 안에 있으면 멈추고, 나가면 처음부터 다시 센다', (tester) async {
      keyboardMode();
      final outside = FocusNode();
      addTearDown(outside.dispose);
      final api = await mount(
        tester,
        body: Focus(focusNode: outside, child: const SizedBox.expand()),
      );
      outside.requestFocus();
      await tester.pump();
      await show(tester, api);
      await advance(tester, 3000);
      bandFocus(tester).requestFocus();
      await tester.pump();
      expect(outside.hasFocus, isFalse);
      await advance(tester, 10000);
      expect(bandFinder, findsOneWidget);
      outside.requestFocus();
      await tester.pump();
      await advance(tester, 3999);
      expect(bandFinder, findsOneWidget);
      await advance(tester, 1);
      await advance(tester, 150);
      expect(bandFinder, findsNothing);
      await unmount(tester);
    });

    testWidgets('터치로 닿은 초점은 멈추지 않는다 — 누름만 멈춘다', (tester) async {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTouch;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      final api = await mount(tester);
      await show(tester, api);
      bandFocus(tester).requestFocus();
      await tester.pump();
      await advance(tester, 4000);
      await advance(tester, 150);
      expect(bandFinder, findsNothing);
      await unmount(tester);
    });

    testWidgets('스크린 리더 초점이 띠에 있는 동안 멈춘다', (tester) async {
      final semantics = tester.ensureSemantics();
      final api = await mount(tester);
      await show(tester, api);
      await advance(tester, 200);
      final node = find.semantics.byLabel('거래를 저장했어요.');
      tester.semantics.performAction(
        node,
        SemanticsAction.didGainAccessibilityFocus,
      );
      await advance(tester, 10000);
      expect(bandFinder, findsOneWidget);
      tester.semantics.performAction(
        node,
        SemanticsAction.didLoseAccessibilityFocus,
      );
      await advance(tester, 3999);
      expect(bandFinder, findsOneWidget);
      await advance(tester, 1);
      await advance(tester, 150);
      expect(bandFinder, findsNothing);
      semantics.dispose();
      await unmount(tester);
    });

    testWidgets('한 번에 하나 — 새 띠는 지금 띠를 바로 내보내고, 그 사이 또 오면 마지막 것만 남는다', (
      tester,
    ) async {
      final api = await mount(tester);
      await show(tester, api, message: '첫째');
      await advance(tester, 200);
      api.show(message: '둘째');
      api.show(message: '셋째');
      await tester.pump();
      // 내보내는 중 — 띠는 하나, 첫째
      expect(bandFinder, findsOneWidget);
      expect(findText(keepAll('첫째')), findsOneWidget);
      await advance(tester, 150);
      await advance(tester, 200);
      expect(bandFinder, findsOneWidget);
      expect(findText(keepAll('둘째')), findsNothing);
      expect(findText(keepAll('셋째')), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('액션 띠는 끝날 때까지 지킨다 — 새 띠는 그 띠가 시간으로 끝난 뒤에 온다(I-04 19)', (
      tester,
    ) async {
      final api = await mount(tester);
      await show(
        tester,
        api,
        message: '삭제했어요.',
        action: PSnackbarAction(label: '되돌리기', onPressed: () {}),
      );
      await advance(tester, 200);
      api.show(message: '새 띠');
      await tester.pump();
      await advance(tester, 500);
      expect(findText(keepAll('삭제했어요.')), findsOneWidget, reason: '액션 띠를 지킨다');
      expect(findText(keepAll('새 띠')), findsNothing);
      await advance(tester, 6000);
      await advance(tester, 300);
      expect(findText(keepAll('삭제했어요.')), findsNothing);
      expect(findText(keepAll('새 띠')), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('액션을 누르면 그 띠가 끝나고 기다리던 띠가 온다 · 기다리는 띠는 하나(마지막)', (
      tester,
    ) async {
      final api = await mount(tester);
      var done = 0;
      await show(
        tester,
        api,
        message: '삭제했어요.',
        action: PSnackbarAction(label: '되돌리기', onPressed: () => done++),
      );
      await advance(tester, 200);
      api.show(message: '둘째');
      api.show(message: '셋째');
      await tester.pump();
      await tester.tap(findText('되돌리기'));
      await advance(tester, 200);
      await advance(tester, 300);
      expect(done, 1);
      expect(findText(keepAll('둘째')), findsNothing);
      expect(findText(keepAll('셋째')), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('액션이 없는 띠끼리는 바로 바뀐다(액션 띠 뒤 새 띠와 다르다)', (tester) async {
      final api = await mount(tester);
      await show(tester, api, message: '첫째');
      await advance(tester, 200);
      api.show(message: '둘째');
      await tester.pump();
      await advance(tester, 150);
      await advance(tester, 200);
      expect(findText(keepAll('첫째')), findsNothing);
      expect(findText(keepAll('둘째')), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('같은 프레임에 두 번 띄우면 앞 띠는 그려지지 않고 바로 걷힌다', (tester) async {
      final api = await mount(tester);
      api.show(message: '첫째');
      api.show(message: '둘째');
      await tester.pump();
      await advance(tester, 200);
      expect(bandFinder, findsOneWidget);
      expect(findText(keepAll('둘째')), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('dismiss() 는 띠를 닫고 기다리는 것도 버린다', (tester) async {
      final api = await mount(tester);
      await show(tester, api, message: '첫째');
      api.show(message: '둘째');
      await tester.pump();
      api.dismiss();
      await tester.pump();
      await advance(tester, 200);
      await advance(tester, 200);
      expect(bandFinder, findsNothing);
      await unmount(tester);
    });

    testWidgets('글 누르기 · Esc · 밀기로는 닫히지 않는다', (tester) async {
      final api = await mount(tester);
      await show(tester, api);
      await advance(tester, 200);
      await tester.tap(find.byKey(const ValueKey('snackbar-message')));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.fling(bandFinder, const Offset(300, 0), 1000);
      await tester.fling(bandFinder, const Offset(0, 100), 1000);
      await advance(tester, 200);
      expect(bandFinder, findsOneWidget);
      await unmount(tester);
    });

    testWidgets('보조 기술용 닫기 — 이름이 있고 누르면 닫힌다', (tester) async {
      final semantics = tester.ensureSemantics();
      final api = await mount(tester);
      await show(tester, api);
      await advance(tester, 200);
      final close = find.bySemanticsLabel(_closeLabel);
      expect(close, findsOneWidget);
      final data = tester.getSemantics(close).getSemanticsData();
      expect(data.flagsCollection.isButton, isTrue);
      tester.semantics.tap(find.semantics.byLabel(_closeLabel));
      await advance(tester, 10);
      await advance(tester, 200);
      expect(bandFinder, findsNothing);
      semantics.dispose();
      await unmount(tester);
    });

    testWidgets('키보드 초점이 닫기에 오면 띠 오른쪽 끝에 44 · X 16 으로 보인다', (tester) async {
      _viewport(tester, const Size(800, 600));
      final spec = _snackbar.resolve({'tone': 'neutral'}, 'enabled');
      final api = await mount(tester);
      await show(
        tester,
        api,
        action: PSnackbarAction(label: '되돌리기', onPressed: () {}),
      );
      await advance(tester, 200);
      expect(find.byKey(const ValueKey('snackbar-close')), findsNothing);
      // 보조 기술용 닫기에 키보드 초점이 온다
      keyboardMode();
      Focus.of(
        tester.element(find.byKey(const ValueKey('snackbar-close-hidden'))),
      ).requestFocus();
      await tester.pump();
      await tester.pump();
      final close = find.byKey(const ValueKey('snackbar-close'));
      expect(close, findsOneWidget);
      final rect = tester.getRect(close);
      expect(
        rect.size,
        Size.square((spec['closeButton.size']! as num).toDouble()),
      );
      expect(rect.right, tester.getRect(bandFinder).right);
      final icon = tester.widget<Icon>(
        find.descendant(of: close, matching: find.byType(Icon)),
      );
      expect(icon.size, spec['closeButton.iconSize']);
      for (final mode in Brightness.values) {
        expect(
          sameColor(
            specColor(pickMode(spec['closeButton.color'], mode)),
            (mode == Brightness.light ? PColors.light : PColors.dark)
                .fgNeutralInverted,
          ),
          isTrue,
        );
      }
      // 글이 닫기 자리를 비켜 선다
      expect(
        tester.getRect(find.byKey(const ValueKey('snackbar-action'))).right,
        lessThanOrEqualTo(rect.left),
      );
      // Enter 로 닫는다
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await advance(tester, 10);
      await advance(tester, 200);
      expect(bandFinder, findsNothing);
      await unmount(tester);
    });

    testWidgets('초점이 띠 안에 있다가 닫히면 띠에 들어오기 전 자리로 돌려준다', (tester) async {
      final outside = FocusNode();
      addTearDown(outside.dispose);
      final api = await mount(
        tester,
        body: Focus(focusNode: outside, child: const SizedBox.expand()),
      );
      outside.requestFocus();
      await tester.pump();
      await show(tester, api);
      bandFocus(tester).requestFocus();
      await tester.pump();
      expect(outside.hasFocus, isFalse);
      api.dismiss();
      await tester.pump();
      expect(outside.hasPrimaryFocus, isTrue);
      await advance(tester, 200);
      await unmount(tester);
    });

    testWidgets('나타남 — 가운데에서 0.8 → 1 + 투명도, 150ms enter. 사라짐 100ms exit', (
      tester,
    ) async {
      final api = await mount(tester);
      await show(tester, api);
      ScaleTransition scale() => tester.widget(
        find
            .ancestor(of: bandFinder, matching: find.byType(ScaleTransition))
            .first,
      );
      FadeTransition fade() => tester.widget(
        find
            .ancestor(of: bandFinder, matching: find.byType(FadeTransition))
            .first,
      );
      expect(scale().scale.value, closeTo(0.8, 1e-6));
      expect(fade().opacity.value, closeTo(0, 1e-6));
      await advance(tester, 75);
      final eased = PEasing.enter.transform(0.5);
      expect(scale().scale.value, closeTo(0.8 + 0.2 * eased, 1e-3));
      expect(fade().opacity.value, closeTo(eased, 1e-3));
      expect(scale().alignment, Alignment.center);
      await advance(tester, 75);
      expect(scale().scale.value, closeTo(1, 1e-6));
      expect(fade().opacity.value, closeTo(1, 1e-6));

      api.dismiss();
      await tester.pump();
      await advance(tester, 50);
      // 사라짐 — exit 곡선, 100ms
      final out = PEasing.exit.transform(0.5);
      expect(fade().opacity.value, closeTo(1 - out, 1e-3));
      expect(scale().scale.value, closeTo(1 - 0.2 * out, 1e-3));
      await advance(tester, 60);
      expect(bandFinder, findsNothing);
      await unmount(tester);
    });

    testWidgets('모션 줄이기면 크기는 그대로이고 투명도만 바뀐다', (tester) async {
      final api = await mount(tester, reduceMotion: true);
      await show(tester, api);
      expect(
        find.ancestor(of: bandFinder, matching: find.byType(ScaleTransition)),
        findsNothing,
      );
      final fade = tester.widget<FadeTransition>(
        find
            .ancestor(of: bandFinder, matching: find.byType(FadeTransition))
            .first,
      );
      expect(fade.opacity.value, closeTo(0, 1e-6));
      await advance(tester, 150);
      expect(fade.opacity.value, closeTo(1, 1e-6));
      await unmount(tester);
    });

    testWidgets('띠는 라이브 영역이고 액션은 이름 있는 버튼이다', (tester) async {
      final semantics = tester.ensureSemantics();
      final api = await mount(tester);
      await show(
        tester,
        api,
        message: '거래를 삭제했어요.',
        action: PSnackbarAction(label: '되돌리기', onPressed: () {}),
      );
      await advance(tester, 200);
      final band = tester.getSemantics(find.bySemanticsLabel('거래를 삭제했어요.'));
      expect(band.getSemanticsData().flagsCollection.isLiveRegion, isTrue);
      // 이음 문자는 읽지 않는다
      expect(band.label, isNot(contains('⁠')));
      final action = tester.getSemantics(find.bySemanticsLabel('되돌리기'));
      expect(action.getSemanticsData().flagsCollection.isButton, isTrue);
      semantics.dispose();
      await unmount(tester);
    });

    testWidgets('카탈로그 견본 — 틀 안에서 띄우고, 탭 바를 켜면 그 위 8 에 선다', (tester) async {
      _viewport(tester, const Size(390, 1600));
      await tester.pumpWidget(
        _app(
          Brightness.light,
          home: const Scaffold(
            body: SingleChildScrollView(child: SnackbarDemo()),
          ),
        ),
      );
      await tester.ensureVisible(findText('결과 — 4초'));
      await tester.pump();
      await tester.tap(findText('결과 — 4초'));
      await tester.pump();
      await advance(tester, 300);
      final frame = tester.getRect(
        find
            .ancestor(
              of: find.byType(PSnackbarHost),
              matching: find.byType(Container),
            )
            .first,
      );
      final live = find.descendant(
        of: find.byType(PSnackbarHost),
        matching: bandFinder,
      );
      expect(live, findsOneWidget);
      // 틀 아래 8 — 틀의 안전 영역은 0 이다
      expect(frame.bottom - tester.getRect(live).bottom, 8 + 1);
      await tester.tap(findText('탭 바 켜기'));
      await tester.pump();
      await tester.pump();
      await advance(tester, 300);
      // 탭 바 66 위 8
      expect(frame.bottom - tester.getRect(live).bottom, 66 + 8 + 1);
      await tester.tap(findText('홈 표시줄 켜기'));
      await tester.pump();
      await tester.pump();
      await advance(tester, 300);
      // 홈 표시줄 34 를 품은 탭 바(66 + 34) 위 8 — 더하지 않는다
      expect(frame.bottom - tester.getRect(live).bottom, 66 + 34 + 8 + 1);
      await unmount(tester);
    });

    testWidgets('띠 안 글은 낱말 단위로 줄을 바꾼다(v114)', (tester) async {
      final api = await mount(tester);
      await show(tester, api, message: '거래를 저장했어요.');
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('snackbar-message')))
            .data,
        keepAll('거래를 저장했어요.'),
      );
      await unmount(tester);
    });

    // ── 자리 — 안전 영역 · 키보드 · 피할 자리 ──
    const tabKey = ValueKey('tab-bar');
    Widget screenWith(double? tabHeight) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        if (tabHeight != null)
          PSnackbarAvoidOverlap(
            child: SizedBox(key: tabKey, height: tabHeight),
          ),
      ],
    );

    // 띠가 서 있는 아래 — 화면 아래에서 띠 아랫변까지
    Future<double> bottomGap(
      WidgetTester tester,
      PSnackbarApi api, {
      required double screenHeight,
    }) async {
      await show(tester, api);
      await advance(tester, 300);
      return screenHeight - tester.getRect(bandFinder).bottom;
    }

    testWidgets('아래는 안전 영역 + 8 — 홈 표시줄을 피한다', (tester) async {
      _viewport(tester, const Size(390, 800));
      tester.view.viewPadding = const FakeViewPadding(bottom: 34);
      tester.view.padding = const FakeViewPadding(bottom: 34);
      final api = await mount(tester);
      expect(await bottomGap(tester, api, screenHeight: 800), 34 + 8);
      await unmount(tester);
    });

    testWidgets('피할 자리 위 8 — 탭 바 · 바닥 버튼 위에 선다', (tester) async {
      _viewport(tester, const Size(390, 800));
      final api = await mount(tester, body: screenWith(66));
      await tester.pump();
      expect(await bottomGap(tester, api, screenHeight: 800), 66 + 8);
      await unmount(tester);
    });

    testWidgets('안전 영역과 피할 자리는 더하지 않고 큰 쪽이다(SEED 와 다르다)', (tester) async {
      _viewport(tester, const Size(390, 800));
      tester.view.viewPadding = const FakeViewPadding(bottom: 34);
      tester.view.padding = const FakeViewPadding(bottom: 34);
      // 탭 바가 안전 영역을 품은 높이 90 — 90 + 8
      var api = await mount(tester, body: screenWith(90));
      await tester.pump();
      expect(await bottomGap(tester, api, screenHeight: 800), 90 + 8);
      api.dismiss();
      await advance(tester, 10);
      await advance(tester, 200);
      // 피할 것이 안전 영역보다 낮으면 안전 영역 — 20 이 아니라 34 + 8
      api = await mount(tester, body: screenWith(20));
      await tester.pump();
      expect(await bottomGap(tester, api, screenHeight: 800), 34 + 8);
      await unmount(tester);
    });

    testWidgets('키보드가 올라와 있으면 그 위에 선다', (tester) async {
      _viewport(tester, const Size(390, 800));
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      tester.view.viewPadding = const FakeViewPadding(bottom: 34);
      final api = await mount(tester);
      expect(await bottomGap(tester, api, screenHeight: 800), 300 + 8);
      await unmount(tester);
    });

    testWidgets('피할 것이 바뀌면 다시 재서 200ms 로 따라가고, 떨어지면 아래로 돌아간다', (tester) async {
      _viewport(tester, const Size(390, 800));
      final api = await mount(tester, body: screenWith(66));
      await tester.pump();
      await show(tester, api, message: '거래를 저장했어요.');
      await advance(tester, 300);
      expect(800 - tester.getRect(bandFinder).bottom, 66 + 8);

      // 크기가 바뀐다 — 탭 바가 90 으로
      await mount(tester, body: screenWith(90));
      await tester.pump();
      await tester.pump();
      await advance(tester, 100);
      final mid = 800 - tester.getRect(bandFinder).bottom;
      expect(mid, inExclusiveRange(66 + 8, 90 + 8));
      await advance(tester, 150);
      expect(800 - tester.getRect(bandFinder).bottom, 90 + 8);
      expect(
        tester
            .state<PSnackbarHostState>(find.byType(PSnackbarHost))
            .avoidOffset,
        90,
      );

      // 떨어진다
      await mount(tester, body: screenWith(null));
      await tester.pump();
      await tester.pump();
      await advance(tester, 300);
      expect(800 - tester.getRect(bandFinder).bottom, 8);
      await unmount(tester);
    });

    testWidgets('모션 줄이기면 피할 자리가 바뀔 때 바로 옮긴다', (tester) async {
      _viewport(tester, const Size(390, 800));
      final api = await mount(tester, body: screenWith(66), reduceMotion: true);
      await tester.pump();
      await show(tester, api);
      await advance(tester, 300);
      await mount(tester, body: screenWith(90), reduceMotion: true);
      await tester.pump();
      await tester.pump();
      expect(800 - tester.getRect(bandFinder).bottom, 90 + 8);
      await unmount(tester);
    });

    testWidgets('피할 것이 여럿이면 가장 위의 것 위에 선다', (tester) async {
      _viewport(tester, const Size(390, 800));
      final api = await mount(
        tester,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            PSnackbarAvoidOverlap(child: const SizedBox(height: 40)),
            PSnackbarAvoidOverlap(child: const SizedBox(height: 56)),
          ],
        ),
      );
      await tester.pump();
      // 가장 위 요소의 윗변 — 아래에서 96
      expect(await bottomGap(tester, api, screenHeight: 800), 96 + 8);
      await unmount(tester);
    });

    testWidgets('위를 다른 화면이 덮으면(보이지 않으면) 그 탭 바는 피하지 않는다', (tester) async {
      _viewport(tester, const Size(390, 800));
      late BuildContext inner;
      final api = await mount(tester, body: screenWith(66));
      inner = tester.element(find.byKey(tabKey));
      await tester.pump();
      Navigator.of(inner).push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: SizedBox()),
        ),
      );
      await tester.pumpAndSettle();
      expect(await bottomGap(tester, api, screenHeight: 800), 8);
      await unmount(tester);
    });

    testWidgets('호스트가 다시 그려져도 시간을 처음부터 세지 않는다', (tester) async {
      _viewport(tester, const Size(390, 800));
      final api = await mount(tester, body: screenWith(66));
      await tester.pump();
      await show(tester, api);
      await advance(tester, 3000);
      // 피할 자리가 바뀌어 호스트가 다시 그려진다
      await mount(tester, body: screenWith(90));
      await tester.pump();
      await tester.pump();
      expect(bandFinder, findsOneWidget);
      await advance(tester, 999);
      expect(bandFinder, findsOneWidget);
      await advance(tester, 1);
      await advance(tester, 150);
      expect(bandFinder, findsNothing);
      await unmount(tester);
    });

    testWidgets('호스트 밖의 PSnackbarAvoidOverlap 은 아무것도 하지 않고 자식을 그린다', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          Brightness.light,
          home: const PSnackbarAvoidOverlap(child: Text('탭 바')),
        ),
      );
      expect(findText('탭 바'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('시트가 열려 있어도 그 위에 뜨고, 띠를 눌러도 시트가 닫히지 않으며 액션이 먹는다', (
      tester,
    ) async {
      _viewport(tester, const Size(390, 800));
      late BuildContext screen;
      final api = await mount(
        tester,
        body: Builder(
          builder: (context) {
            screen = context;
            return const SizedBox.expand();
          },
        ),
      );
      showModalBottomSheet<void>(
        context: screen,
        builder: (_) =>
            const SizedBox(height: 300, child: Center(child: Text('시트 내용'))),
      );
      await tester.pumpAndSettle();
      expect(findText('시트 내용'), findsOneWidget);

      var restored = 0;
      await show(
        tester,
        api,
        message: '거래를 삭제했어요.',
        action: PSnackbarAction(label: '되돌리기', onPressed: () => restored++),
      );
      await advance(tester, 300);
      // 시트(아래 300) 위에 그려진다 — 띠가 시트 안에 있다
      expect(tester.getRect(bandFinder).bottom, greaterThan(800 - 300));

      await tester.tap(find.byKey(const ValueKey('snackbar-message')));
      await advance(tester, 300);
      expect(findText('시트 내용'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('snackbar-action')));
      await advance(tester, 300);
      expect(restored, 1);
      expect(findText('시트 내용'), findsOneWidget);

      // 시트 바깥(진짜 바깥 누르기)은 시트를 닫는다 — 막힌 것이 아니라 띠가 바깥이 아니었던 것
      await tester.tapAt(const Offset(195, 100));
      await tester.pumpAndSettle();
      expect(findText('시트 내용'), findsNothing);
      await unmount(tester);
    });
  });

  // ══════════════════════════════════════════════════════════════
  // Callout
  // ══════════════════════════════════════════════════════════════
  group('Callout 모양', () {
    const box = ValueKey('callout-box');
    const text = ValueKey('callout-text');

    PCallout callout(
      PCalloutTone tone,
      PCalloutInteraction interaction, {
      String? title = '안내',
      String description = '저장했어요.',
      bool open = true,
    }) => PCallout(
      key: UniqueKey(),
      tone: tone,
      interaction: interaction,
      title: title,
      description: description,
      link: interaction == PCalloutInteraction.actionable
          ? null
          : PCalloutLink(label: '자세히', onPressed: () {}),
      onPressed: interaction == PCalloutInteraction.actionable ? () {} : null,
      dismissLabel: interaction == PCalloutInteraction.dismissible
          ? _closeLabel
          : null,
    );

    for (final mode in Brightness.values) {
      testWidgets('${mode.name} — 톤 × 상호작용 × 상태가 스펙 값이다', (tester) async {
        final failures = <String>[];
        for (final combo in _callout.combos(['tone', 'interaction'])) {
          final tone = PCalloutTone.values.byName(combo['tone']!);
          final interaction = PCalloutInteraction.values.byName(
            combo['interaction']!,
          );
          // 누름이 있는 것은 전체 누르기(상자) · 닫기(닫기 버튼)뿐 — 보이기는 누를 것이 없다
          final states = interaction == PCalloutInteraction.display
              ? ['enabled']
              : _appStates(_callout);
          for (final state in states) {
            await tester.pumpWidget(
              _placed(mode, callout(tone, interaction), width: 320),
            );
            final target = interaction == PCalloutInteraction.dismissible
                ? find.byKey(const ValueKey('callout-close'))
                : find.byKey(box);
            final gesture = await _settle(tester, state, target);
            final k = _Check(
              mode,
              _callout.resolve(combo, state),
              '${mode.name} $combo $state',
            );

            final boxFinder = find.byKey(box);
            final rect = tester.getRect(boxFinder);
            // ── 상자 ── 누르면 상자 전체가 줄어 보이므로 놓인 자리는 누르지 않은 때만 잰다
            final deco =
                tester.widget<DecoratedBox>(boxFinder).decoration
                    as BoxDecoration;
            k.px('root.radius', (deco.borderRadius! as BorderRadius).topLeft.x);
            // 누름 바탕은 색 전환(150ms)이 끝난 뒤의 색이다
            k.color('root.background', deco.color!);
            final icon = find.byKey(const ValueKey('callout-icon'));
            final iconWidget = tester.widget<Icon>(icon);
            k.px('icon.size', iconWidget.size!);
            k.color('root.foreground', iconWidget.color!);
            expect(iconWidget.icon, pCalloutToneIcon(tone));
            final textRect = tester.getRect(find.byKey(text));
            if (state == 'enabled') {
              if (rect.width != 320) {
                k.fail('root.width: 100%(320) · 실제 ${rect.width}');
              }
              k.px('root.minHeight', rect.height);
              // 안쪽 14 · 아이콘 ↔ 글 12
              final iconRect = tester.getRect(icon);
              k.px('icon.size', iconRect.width);
              k.px('root.padding', iconRect.left - rect.left);
              k.px('root.gap', textRect.left - iconRect.right);
              // 한 줄 — 위 · 아래 안쪽 14 + 줄 19 = 47 → 최소 50 안에서 가운데(alignItems center)
              if ((textRect.center.dy - rect.center.dy).abs() > 0.5) {
                k.fail(
                  'root.alignItems: center · 글 가운데 ${textRect.center.dy} · 상자 ${rect.center.dy}',
                );
              }
            }

            // ── 제목 · 본문 · 링크 — 한 문단 ──
            final root = _rootSpan(tester, find.byKey(text));
            final title = _spanStyle(root, keepAll('안내'));
            k.typo('title.typography', title);
            k.weight('title.fontWeight', title);
            k.color('root.foreground', title.color!);
            final description = _spanStyle(root, keepAll('저장했어요.'));
            k.typo('description.typography', description);
            k.weight('description.fontWeight', description);
            k.color('root.foreground', description.color!);
            if (interaction != PCalloutInteraction.actionable) {
              final link = tester.widget<Text>(findText('자세히')).style!;
              k.typo('link.typography', link);
              k.weight('link.fontWeight', link);
              k.color('root.foreground', link.color!);
              if (link.decoration != TextDecoration.underline) {
                k.fail(
                  'link.textDecoration: underline · 실제 ${link.decoration}',
                );
              }
            }

            // ── 뒤 화살표 · 닫기 ──
            final chevron = find.byKey(const ValueKey('callout-chevron'));
            final close = find.byKey(const ValueKey('callout-close'));
            expect(
              chevron,
              interaction == PCalloutInteraction.actionable
                  ? findsOneWidget
                  : findsNothing,
            );
            expect(
              close,
              interaction == PCalloutInteraction.dismissible
                  ? findsOneWidget
                  : findsNothing,
            );
            if (interaction == PCalloutInteraction.actionable) {
              k.px('suffixIcon.size', tester.widget<Icon>(chevron).size!);
              if (state == 'enabled') {
                final r = tester.getRect(chevron);
                k.px('suffixIcon.size', r.width);
                k.px('root.padding', rect.right - r.right);
              }
              k.color('root.foreground', tester.widget<Icon>(chevron).color!);
              expect(
                tester.widget<Icon>(chevron).icon,
                LucideIcons.chevronRight,
              );
            }
            if (interaction == PCalloutInteraction.dismissible) {
              final closeRect = tester.getRect(close);
              k.px(
                'closeButton.iconSize',
                tester
                    .widget<Icon>(
                      find.descendant(of: close, matching: find.byType(Icon)),
                    )
                    .size!,
              );
              final closeDeco =
                  tester.widget<Container>(close).decoration as BoxDecoration;
              k.px(
                'closeButton.radius',
                (closeDeco.borderRadius! as BorderRadius).topLeft.x,
              );
              if (state == 'enabled') {
                k.px('closeButton.size', closeRect.width);
                k.px('closeButton.size', closeRect.height);
                // 닫기 아이콘은 오른쪽 끝에서 14
                k.px(
                  'root.padding',
                  rect.right -
                      tester
                          .getRect(
                            find.descendant(
                              of: close,
                              matching: find.byType(Icon),
                            ),
                          )
                          .right,
                );
              } else {
                // 눌린 닫기 — 톤의 누름 바탕
                k.color('closeButton.background', closeDeco.color!);
              }
              k.color(
                'root.foreground',
                tester
                    .widget<Icon>(
                      find.descendant(of: close, matching: find.byType(Icon)),
                    )
                    .color!,
              );
            }

            // ── 누름 축소 ──
            if (state == 'pressed') {
              if (interaction == PCalloutInteraction.actionable) {
                final scale = tester.widget<AnimatedScale>(
                  find.ancestor(
                    of: boxFinder,
                    matching: find.byType(AnimatedScale),
                  ),
                );
                // 기준 max(높이, 폭 ÷ 4, 24) — 50 × 320
                final basis = math.max(50, math.max(320 / 4, 24));
                if ((scale.scale - _pressScale(basis)).abs() > 1e-6) {
                  k.fail(
                    'root.scale: 기준 $basis 의 ${_pressScale(basis)} · 실제 ${scale.scale}',
                  );
                }
                _checkScaleMotion(
                  k,
                  scale,
                  'root',
                  durationKey: 'scaleDuration',
                  easingKey: 'scaleEasing',
                );
              } else {
                final scale = tester.widget<AnimatedScale>(
                  find.ancestor(
                    of: close,
                    matching: find.byType(AnimatedScale),
                  ),
                );
                if ((scale.scale - _pressScale(40)).abs() > 1e-6) {
                  k.fail(
                    'closeButton.scale: 기준 40 의 ${_pressScale(40)} · 실제 ${scale.scale}',
                  );
                }
                _checkScaleMotion(
                  k,
                  scale,
                  'closeButton',
                  durationKey: 'scaleDuration',
                  easingKey: 'scaleEasing',
                );
              }
            }
            await gesture?.up();
            await tester.pump(const Duration(milliseconds: 400));
            failures.addAll(k.failures);
          }
        }
        _expectClean(failures);
      });
    }
  });

  group('Callout 동작', () {
    const box = ValueKey('callout-box');

    testWidgets('톤마다 기본 앞 아이콘이 있고 바꾸거나 뺄 수 있다', (tester) async {
      const want = {
        PCalloutTone.neutral: LucideIcons.info,
        PCalloutTone.informative: LucideIcons.info,
        PCalloutTone.positive: LucideIcons.circleCheck,
        PCalloutTone.warning: LucideIcons.triangleAlert,
        PCalloutTone.critical: LucideIcons.circleAlert,
      };
      for (final tone in PCalloutTone.values) {
        await tester.pumpWidget(
          _placed(
            Brightness.light,
            PCallout(key: UniqueKey(), tone: tone, description: '본문'),
          ),
        );
        expect(
          tester.widget<Icon>(find.byKey(const ValueKey('callout-icon'))).icon,
          want[tone],
        );
      }
      await tester.pumpWidget(
        _placed(
          Brightness.light,
          const PCallout(description: '본문', icon: LucideIcons.bell),
        ),
      );
      expect(
        tester.widget<Icon>(find.byKey(const ValueKey('callout-icon'))).icon,
        LucideIcons.bell,
      );
      await tester.pumpWidget(
        _placed(
          Brightness.light,
          const PCallout(description: '본문', hideIcon: true),
        ),
      );
      expect(find.byKey(const ValueKey('callout-icon')), findsNothing);
    });

    testWidgets('여러 줄이면 아이콘 · 화살표 · 닫기가 상자 가운데에 선다', (tester) async {
      const long =
          '가져온 데이터는 기존 거래에 더해지고 덮어쓰지 않아요. 같은 거래가 두 번 들어오면 한 번만 남겨요. 마음 놓고 가져와요.';
      for (final interaction in PCalloutInteraction.values) {
        await tester.pumpWidget(
          _placed(
            Brightness.light,
            PCallout(
              key: UniqueKey(),
              interaction: interaction,
              title: '안내',
              description: long,
              onPressed: interaction == PCalloutInteraction.actionable
                  ? () {}
                  : null,
              dismissLabel: interaction == PCalloutInteraction.dismissible
                  ? _closeLabel
                  : null,
            ),
          ),
        );
        final rect = tester.getRect(find.byKey(box));
        expect(rect.height, greaterThan(50));
        // 글 높이 + 위아래 14
        final text = tester.getRect(find.byKey(const ValueKey('callout-text')));
        expect(rect.height, text.height + 28);
        for (final key in [
          'callout-icon',
          'callout-chevron',
          'callout-close',
        ]) {
          final finder = find.byKey(ValueKey(key));
          if (finder.evaluate().isEmpty) continue;
          expect(
            tester.getRect(finder).center.dy,
            closeTo(rect.center.dy, 0.5),
            reason: '$interaction $key',
          );
        }
      }
    });

    testWidgets('글은 낱말 단위로 줄을 바꾸고 제목 · 본문 · 링크는 두 칸 띄운다', (tester) async {
      await tester.pumpWidget(
        _placed(
          Brightness.light,
          PCallout(
            title: '안내',
            description: '저장했어요.',
            link: PCalloutLink(label: '자세히', onPressed: () {}),
          ),
        ),
      );
      final root = _rootSpan(
        tester,
        find.byKey(const ValueKey('callout-text')),
      );
      final plain = root.toPlainText(includeSemanticsLabels: false);
      expect(plain, contains('${keepAll('안내')}  ${keepAll('저장했어요.')}  '));
    });

    testWidgets('Display 는 문단으로 읽고 이음 문자는 읽지 않는다 — 링크는 링크다', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _placed(
          Brightness.light,
          PCallout(
            title: '안내',
            description: '저장했어요.',
            link: PCalloutLink(label: '자세히', onPressed: () {}),
          ),
        ),
      );
      final node = tester.getSemantics(
        find.byKey(const ValueKey('callout-text')),
      );
      expect(node.label, contains('안내'));
      expect(node.label, contains('저장했어요.'));
      expect(node.label, isNot(contains('⁠')));
      expect(node.getSemanticsData().flagsCollection.isButton, isFalse);
      final link = tester.getSemantics(findText('자세히'));
      expect(link.getSemanticsData().flagsCollection.isLink, isTrue);
      semantics.dispose();
    });

    testWidgets('링크를 누르면 그 일을 한다', (tester) async {
      var count = 0;
      await tester.pumpWidget(
        _placed(
          Brightness.light,
          PCallout(
            description: '저장했어요.',
            link: PCalloutLink(label: '자세히', onPressed: () => count++),
          ),
        ),
      );
      await tester.tap(findText('자세히'));
      expect(count, 1);
    });

    testWidgets('alert 는 라이브 영역으로 읽힌다 — 처음부터 있는 안내는 아니다', (tester) async {
      final semantics = tester.ensureSemantics();
      for (final alert in [true, false]) {
        await tester.pumpWidget(
          _placed(
            Brightness.light,
            PCallout(
              key: UniqueKey(),
              tone: PCalloutTone.critical,
              description: '저장하지 못했어요.',
              alert: alert,
            ),
          ),
        );
        final node = tester.getSemantics(
          find.byKey(const ValueKey('callout-text')),
        );
        expect(node.getSemanticsData().flagsCollection.isLiveRegion, alert);
      }
      semantics.dispose();
    });

    testWidgets('Actionable — 상자 전체가 버튼이고 이름은 글 전체다', (tester) async {
      final semantics = tester.ensureSemantics();
      var count = 0;
      await tester.pumpWidget(
        _placed(
          Brightness.light,
          PCallout(
            interaction: PCalloutInteraction.actionable,
            title: '증권',
            description: '토스증권을 연결해요.',
            onPressed: () => count++,
          ),
        ),
      );
      final node = tester.getSemantics(
        find.byKey(const ValueKey('callout-text')),
      );
      expect(node.getSemanticsData().flagsCollection.isButton, isTrue);
      expect(node.label, contains('증권'));
      expect(node.label, contains('토스증권을 연결해요.'));
      // 상자 어디를 눌러도 — 가장자리 · 화살표 · 글
      final rect = tester.getRect(find.byKey(box));
      await tester.tapAt(rect.topLeft + const Offset(2, 2));
      await tester.tapAt(rect.bottomRight - const Offset(2, 2));
      await tester.tap(find.byKey(const ValueKey('callout-chevron')));
      await tester.tap(find.byKey(const ValueKey('callout-text')));
      expect(count, 4);
      semantics.dispose();
    });

    testWidgets('Actionable 누름 — 모션 줄이기면 줄지 않고 색만 바뀐다', (tester) async {
      await tester.pumpWidget(
        _placed(
          Brightness.light,
          PCallout(
            interaction: PCalloutInteraction.actionable,
            description: '토스증권을 연결해요.',
            onPressed: () {},
          ),
          reduceMotion: true,
        ),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(box)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        tester
            .widget<AnimatedScale>(
              find.ancestor(
                of: find.byKey(box),
                matching: find.byType(AnimatedScale),
              ),
            )
            .scale,
        1,
      );
      final deco =
          tester.widget<DecoratedBox>(find.byKey(box)).decoration
              as BoxDecoration;
      expect(deco.color, PColors.light.bgNeutralWeakPressed);
      await gesture.up();
    });

    testWidgets('Actionable 은 링크를, 그 밖은 닫기 · open 을 받지 않는다', (tester) async {
      expect(
        () => PCallout(
          description: '본문',
          interaction: PCalloutInteraction.actionable,
          onPressed: () {},
          link: PCalloutLink(label: '자세히', onPressed: () {}),
        ),
        throwsAssertionError,
      );
      expect(
        () => PCallout(
          description: '본문',
          interaction: PCalloutInteraction.actionable,
        ),
        throwsAssertionError,
      );
      expect(
        () => PCallout(
          description: '본문',
          interaction: PCalloutInteraction.dismissible,
        ),
        throwsAssertionError,
      );
      expect(
        () => PCallout(description: '본문', open: true),
        throwsAssertionError,
      );
    });

    testWidgets('Dismissible — 닫기는 이름 있는 버튼이고, 누르면 바로 걷힌다(스스로 닫힘)', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      var dismissed = 0;
      await tester.pumpWidget(
        _placed(
          Brightness.light,
          PCallout(
            interaction: PCalloutInteraction.dismissible,
            title: '새 기능',
            description: '반복 거래를 기록해요.',
            dismissLabel: _closeLabel,
            onDismiss: () => dismissed++,
          ),
        ),
      );
      final close = tester.getSemantics(find.bySemanticsLabel(_closeLabel));
      expect(close.getSemanticsData().flagsCollection.isButton, isTrue);
      await tester.tap(find.byKey(const ValueKey('callout-close')));
      // 모션 없이 바로 — 프레임 하나
      await tester.pump();
      expect(find.byKey(box), findsNothing);
      expect(dismissed, 1);
      semantics.dispose();
    });

    testWidgets('Dismissible — open 을 주면 부르는 쪽이 정한다(닫은 것을 기억한다)', (
      tester,
    ) async {
      var open = true;
      late StateSetter setOuter;
      await tester.pumpWidget(
        _placed(
          Brightness.light,
          StatefulBuilder(
            builder: (context, setState) {
              setOuter = setState;
              return PCallout(
                interaction: PCalloutInteraction.dismissible,
                description: '반복 거래를 기록해요.',
                dismissLabel: _closeLabel,
                open: open,
                onDismiss: () {},
              );
            },
          ),
        ),
      );
      // 닫기를 눌러도 부르는 쪽이 open 을 그대로 두면 그대로 있다
      await tester.tap(find.byKey(const ValueKey('callout-close')));
      await tester.pump();
      expect(find.byKey(box), findsOneWidget);
      setOuter(() => open = false);
      await tester.pump();
      expect(find.byKey(box), findsNothing);
      setOuter(() => open = true);
      await tester.pump();
      expect(find.byKey(box), findsOneWidget);
    });

    testWidgets('닫기 누르는 영역은 40 × 40 이다', (tester) async {
      var dismissed = 0;
      await tester.pumpWidget(
        _placed(
          Brightness.light,
          PCallout(
            key: UniqueKey(),
            interaction: PCalloutInteraction.dismissible,
            description: '반복 거래를 기록해요.',
            dismissLabel: _closeLabel,
            onDismiss: () => dismissed++,
            open: true,
          ),
        ),
      );
      final close = tester.getCenter(
        find.byKey(const ValueKey('callout-close')),
      );
      // 아이콘(16) 밖 · 상자(40) 안
      await tester.tapAt(close + const Offset(18, 0));
      await tester.tapAt(close + const Offset(0, -18));
      expect(dismissed, 2);
      // 상자 밖
      await tester.tapAt(close + const Offset(22, 0));
      expect(dismissed, 2);
    });

    testWidgets('키보드로 닫으면 초점이 다음 요소로 간다', (tester) async {
      final after = FocusNode();
      addTearDown(after.dispose);
      await tester.pumpWidget(
        _placed(
          Brightness.light,
          Column(
            children: [
              const PCallout(
                interaction: PCalloutInteraction.dismissible,
                description: '반복 거래를 기록해요.',
                dismissLabel: _closeLabel,
              ),
              Focus(focusNode: after, child: const SizedBox(height: 20)),
            ],
          ),
        ),
      );
      Focus.of(
        tester.element(find.byKey(const ValueKey('callout-close'))),
      ).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.pump();
      expect(find.byKey(box), findsNothing);
      expect(after.hasPrimaryFocus, isTrue);
    });

    testWidgets('키보드 — Enter · Space 로 전체 누르기를 한다', (tester) async {
      var count = 0;
      await tester.pumpWidget(
        _placed(
          Brightness.light,
          PCallout(
            interaction: PCalloutInteraction.actionable,
            description: '토스증권을 연결해요.',
            onPressed: () => count++,
          ),
        ),
      );
      Focus.of(
        tester.element(find.byKey(const ValueKey('callout-text'))),
      ).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(count, 2);
    });
  });

  // ══════════════════════════════════════════════════════════════
  // Page Banner
  // ══════════════════════════════════════════════════════════════
  group('Page Banner 모양', () {
    const box = ValueKey('page-banner-box');
    const text = ValueKey('page-banner-text');

    PPageBanner banner(
      PPageBannerTone tone,
      PPageBannerVariant variant,
      PPageBannerInteraction interaction,
    ) => PPageBanner(
      key: UniqueKey(),
      tone: tone,
      variant: variant,
      interaction: interaction,
      title: '새 버전',
      description: '더 빨라졌어요.',
      button: interaction == PPageBannerInteraction.display
          ? PPageBannerButton(label: '업데이트', onPressed: () {})
          : null,
      onPressed: interaction == PPageBannerInteraction.actionable
          ? () {}
          : null,
      dismissLabel: interaction == PPageBannerInteraction.dismissible
          ? _closeLabel
          : null,
    );

    for (final mode in Brightness.values) {
      testWidgets('${mode.name} — 바탕 × 톤 × 상호작용 × 상태가 스펙 값이다', (tester) async {
        final failures = <String>[];
        for (final combo in _pageBanner.combos([
          'variant',
          'tone',
          'interaction',
        ])) {
          final tone = PPageBannerTone.values.byName(combo['tone']!);
          final variant = PPageBannerVariant.values.byName(combo['variant']!);
          final interaction = PPageBannerInteraction.values.byName(
            combo['interaction']!,
          );
          for (final state in _appStates(_pageBanner)) {
            await tester.pumpWidget(
              _placed(mode, banner(tone, variant, interaction), width: 390),
            );
            // 누르는 것 — 전체 누르기는 띠, 보이기는 글 버튼, 닫기는 닫기 버튼
            final target = switch (interaction) {
              PPageBannerInteraction.actionable => find.byKey(box),
              PPageBannerInteraction.display => find.byKey(
                const ValueKey('page-banner-button'),
              ),
              PPageBannerInteraction.dismissible => find.byKey(
                const ValueKey('page-banner-close'),
              ),
            };
            final gesture = await _settle(tester, state, target);
            final k = _Check(
              mode,
              _pageBanner.resolve(combo, state),
              '${mode.name} $combo $state',
            );

            final boxFinder = find.byKey(box);
            final rect = tester.getRect(boxFinder);
            final deco =
                tester.widget<DecoratedBox>(boxFinder).decoration
                    as BoxDecoration;
            // ── 띠 ── 화면 폭 전체 · 모서리 없음. 누름은 안의 내용만 줄고 바탕은 그대로다
            if (rect.width != 390) {
              k.fail('root.width: 100%(390) · 실제 ${rect.width}');
            }
            k.px('root.minHeight', rect.height);
            k.px('root.radius', deco.borderRadius == null ? 0 : 1);
            k.color('root.background', deco.color!);

            // ── 아이콘 ──
            final icon = find.byKey(const ValueKey('page-banner-icon'));
            final iconWidget = tester.widget<Icon>(icon);
            k.px('icon.size', iconWidget.size!);
            k.color('root.foreground', iconWidget.color!);
            expect(iconWidget.icon, pPageBannerToneIcon(tone));

            // ── 제목 · 본문 ──
            final root = _rootSpan(tester, find.byKey(text));
            final title = _spanStyle(root, keepAll('새 버전'));
            k.typo('title.typography', title);
            k.weight('title.fontWeight', title);
            k.color('root.foreground', title.color!);
            final description = _spanStyle(root, keepAll('더 빨라졌어요.'));
            k.typo('description.typography', description);
            k.weight('description.fontWeight', description);
            k.color('root.foreground', description.color!);

            // ── 버튼 · 화살표 · 닫기 ──
            final button = find.byKey(const ValueKey('page-banner-button'));
            final chevron = find.byKey(const ValueKey('page-banner-chevron'));
            final close = find.byKey(const ValueKey('page-banner-close'));
            expect(
              button,
              interaction == PPageBannerInteraction.display
                  ? findsOneWidget
                  : findsNothing,
            );
            expect(
              chevron,
              interaction == PPageBannerInteraction.actionable
                  ? findsOneWidget
                  : findsNothing,
            );
            expect(
              close,
              interaction == PPageBannerInteraction.dismissible
                  ? findsOneWidget
                  : findsNothing,
            );
            if (interaction == PPageBannerInteraction.display) {
              final label = tester.widget<Text>(button).style!;
              k.typo('button.typography', label);
              k.weight('button.fontWeight', label);
              k.color('root.foreground', label.color!);
            }
            if (interaction == PPageBannerInteraction.actionable) {
              final w = tester.widget<Icon>(chevron);
              k.px('suffixIcon.size', w.size!);
              k.color('root.foreground', w.color!);
              expect(w.icon, LucideIcons.chevronRight);
            }
            if (interaction == PPageBannerInteraction.dismissible) {
              final w = tester.widget<Icon>(
                find.descendant(of: close, matching: find.byType(Icon)),
              );
              k.px('closeButton.iconSize', w.size!);
              k.color('root.foreground', w.color!);
              expect(w.icon, LucideIcons.x);
            }

            // ── 놓인 자리 — 누르지 않은 때만(누르면 안의 내용이 줄어 보인다) ──
            if (state == 'enabled') {
              final iconRect = tester.getRect(icon);
              final textRect = tester.getRect(find.byKey(text));
              k.px('root.paddingX', iconRect.left - rect.left);
              k.px('icon.size', iconRect.width);
              // 아이콘은 첫 줄 가운데 — 위 여백 + 2
              final iconTop = k.want['root.paddingY']! as num;
              k.px('icon.marginTop', iconRect.top - rect.top - iconTop);
              k.px('root.paddingY', textRect.top - rect.top);
              k.px('root.gap', textRect.left - iconRect.right);
              if (interaction == PPageBannerInteraction.display) {
                // 한 줄에 들어가면 버튼은 오른쪽 끝 · 글과 같은 줄 가운데
                final b = tester.getRect(button);
                k.px('root.paddingX', rect.right - b.right);
                if ((b.center.dy - textRect.center.dy).abs() > 1) {
                  k.fail(
                    'content.justifyContent: 한 줄 가운데 · 버튼 ${b.center.dy} · 글 ${textRect.center.dy}',
                  );
                }
              }
              if (interaction == PPageBannerInteraction.actionable) {
                final r = tester.getRect(chevron);
                k.px('suffixIcon.size', r.width);
                k.px('root.paddingX', rect.right - r.right);
                if ((r.center.dy - rect.center.dy).abs() > 0.5) {
                  k.fail('화살표는 띠 가운데: ${r.center.dy} · ${rect.center.dy}');
                }
              }
              if (interaction == PPageBannerInteraction.dismissible) {
                final c = tester.getRect(close);
                k.px('closeButton.size', c.width);
                k.px('closeButton.size', c.height);
                // 아이콘은 오른쪽 끝에서 24
                final r = tester.getRect(
                  find.descendant(of: close, matching: find.byType(Icon)),
                );
                k.px('root.paddingX', rect.right - r.right);
                if ((c.center.dy - rect.center.dy).abs() > 0.5) {
                  k.fail('닫기는 띠 가운데: ${c.center.dy} · ${rect.center.dy}');
                }
              }
            }

            // ── 누름 ──
            if (state == 'pressed') {
              // 전체 누르기는 띠 안쪽(화살표가 있는 층)이 줄고, 나머지는 누른 것이 준다
              final scaled = interaction == PPageBannerInteraction.actionable
                  ? find.byKey(const ValueKey('page-banner-chevron'))
                  : target;
              final scale = tester.widget<AnimatedScale>(
                find.ancestor(of: scaled, matching: find.byType(AnimatedScale)),
              );
              switch (interaction) {
                case PPageBannerInteraction.actionable:
                  // 안의 내용만 줄고 바탕은 그대로다 — 기준 max(높이, 폭 ÷ 4, 24) = 390 ÷ 4
                  final basis = math.max(40, math.max(390 / 4, 24));
                  if ((scale.scale - _pressScale(basis)).abs() > 1e-6) {
                    k.fail(
                      'content.scale: 기준 $basis 의 ${_pressScale(basis)} · 실제 ${scale.scale}',
                    );
                  }
                  _checkScaleMotion(
                    k,
                    scale,
                    'content',
                    durationKey: 'scaleDuration',
                    easingKey: 'scaleEasing',
                  );
                  if (rect.height != 40) {
                    k.fail('바탕은 그대로여야 한다: ${rect.height}');
                  }
                case PPageBannerInteraction.display:
                  // 글 버튼 — 글 + 사방 11 의 높이 40 이 기준(폭 ÷ 4 가 더 크면 그쪽)
                  final size = tester.getSize(button);
                  final basis = math.max(
                    size.height + 22,
                    math.max((size.width + 22) / 4, 24),
                  );
                  if ((scale.scale - _pressScale(basis)).abs() > 0.002) {
                    k.fail(
                      'button.scale: 기준 $basis 의 ${_pressScale(basis)} · 실제 ${scale.scale}',
                    );
                  }
                  _checkScaleMotion(
                    k,
                    scale,
                    'button',
                    durationKey: 'scaleDuration',
                    easingKey: 'scaleEasing',
                  );
                case PPageBannerInteraction.dismissible:
                  if ((scale.scale - _pressScale(40)).abs() > 1e-6) {
                    k.fail(
                      'closeButton.scale: 기준 40 의 ${_pressScale(40)} · 실제 ${scale.scale}',
                    );
                  }
                  _checkScaleMotion(
                    k,
                    scale,
                    'closeButton',
                    durationKey: 'scaleDuration',
                    easingKey: 'scaleEasing',
                  );
              }
            }
            await gesture?.up();
            await tester.pump(const Duration(milliseconds: 400));
            failures.addAll(k.failures);
          }
        }
        _expectClean(failures);
      });
    }
  });

  group('Page Banner 동작', () {
    const box = ValueKey('page-banner-box');
    const text = ValueKey('page-banner-text');
    const button = ValueKey('page-banner-button');

    Future<void> pumpBanner(
      WidgetTester tester,
      PPageBanner banner, {
      double width = 390,
      bool reduceMotion = false,
    }) => tester.pumpWidget(
      _placed(
        Brightness.light,
        banner,
        width: width,
        reduceMotion: reduceMotion,
      ),
    );

    PPageBanner display({
      String description = '더 빨라졌어요.',
      VoidCallback? onPressed,
    }) => PPageBanner(
      key: UniqueKey(),
      title: '새 버전',
      description: description,
      button: PPageBannerButton(label: '업데이트', onPressed: onPressed ?? () {}),
    );

    testWidgets('본문과 버튼이 한 줄에 들어가면 버튼은 오른쪽 끝, 안 들어가면 다음 줄 본문 시작선이다', (
      tester,
    ) async {
      await pumpBanner(tester, display());
      var rect = tester.getRect(find.byKey(box));
      var body = tester.getRect(find.byKey(text));
      var b = tester.getRect(find.byKey(button));
      expect(b.right, rect.right - 24);
      expect(b.center.dy, closeTo(body.center.dy, 1));
      expect(rect.height, 40);

      // 좁은 폭 + 긴 글 — 버튼이 다음 줄로(줄 사이 6)
      await pumpBanner(
        tester,
        display(description: '토스증권 키가 만료돼 시세를 받지 못해요. 새 키를 발급받아 다시 연결해 주세요.'),
        width: 300,
      );
      rect = tester.getRect(find.byKey(box));
      body = tester.getRect(find.byKey(text));
      b = tester.getRect(find.byKey(button));
      expect(b.left, body.left);
      expect(b.top - body.bottom, 6);
      // 위 10 + 글 + 6 + 버튼 줄 18 + 아래 10
      expect(rect.height, 10 + body.height + 6 + 18 + 10);
    });

    testWidgets('한 줄에 안 들어가는 긴 글은 본문이 줄을 바꾸고 아이콘은 첫 줄에 붙는다', (tester) async {
      await pumpBanner(
        tester,
        PPageBanner(
          description:
              '토스증권 키가 만료돼 시세를 받지 못해요. 새 키를 발급받아 다시 연결해 주세요. 그동안은 지난 값을 보여 드려요.',
        ),
        width: 300,
      );
      final rect = tester.getRect(find.byKey(box));
      final body = tester.getRect(find.byKey(text));
      expect(body.height, greaterThan(19 * 2));
      expect(rect.height, 10 + body.height + 10);
      // 아이콘은 첫 줄 가운데 — 위 여백 10 + 2
      final icon = tester.getRect(
        find.byKey(const ValueKey('page-banner-icon')),
      );
      expect(icon.top - rect.top, 12);
    });

    testWidgets('버튼을 누르면 그 일을 한다 — 누르는 영역은 글 + 사방 11 이다', (tester) async {
      var count = 0;
      await pumpBanner(tester, display(onPressed: () => count++));
      final b = tester.getRect(find.byKey(button));
      await tester.tapAt(b.center);
      await tester.tapAt(b.centerLeft - const Offset(10, 0));
      await tester.tapAt(b.centerRight + const Offset(10, 0));
      expect(count, 3);
      // 11 을 넘으면 받지 않는다
      await tester.tapAt(b.centerLeft - const Offset(14, 0));
      expect(count, 3);
    });

    testWidgets('글 버튼 — 이름은 글이고 버튼으로 읽는다', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpBanner(tester, display());
      final node = tester.getSemantics(find.byKey(button));
      expect(node.getSemanticsData().flagsCollection.isButton, isTrue);
      expect(node.label, '업데이트');
      semantics.dispose();
    });

    testWidgets('Actionable — 띠 전체가 버튼이고 이름은 글 전체다', (tester) async {
      final semantics = tester.ensureSemantics();
      var count = 0;
      await pumpBanner(
        tester,
        PPageBanner(
          interaction: PPageBannerInteraction.actionable,
          title: '곧 만료',
          description: 'Pro 이용이 10월 31일에 끝나요.',
          onPressed: () => count++,
        ),
      );
      final node = tester.getSemantics(find.byKey(text));
      expect(node.getSemanticsData().flagsCollection.isButton, isTrue);
      expect(node.label, contains('곧 만료'));
      expect(node.label, contains('Pro 이용이 10월 31일에 끝나요.'));
      final rect = tester.getRect(find.byKey(box));
      await tester.tapAt(rect.topLeft + const Offset(2, 2));
      await tester.tapAt(rect.bottomRight - const Offset(2, 2));
      await tester.tap(find.byKey(const ValueKey('page-banner-chevron')));
      expect(count, 3);
      semantics.dispose();
    });

    testWidgets('Actionable 누름 — 모션 줄이기면 줄지 않고 바탕 색만 바뀐다', (tester) async {
      await pumpBanner(
        tester,
        PPageBanner(
          interaction: PPageBannerInteraction.actionable,
          description: 'Pro 이용이 10월 31일에 끝나요.',
          onPressed: () {},
        ),
        reduceMotion: true,
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(box)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        tester
            .widget<AnimatedScale>(
              find.ancestor(
                of: find.byKey(const ValueKey('page-banner-chevron')),
                matching: find.byType(AnimatedScale),
              ),
            )
            .scale,
        1,
      );
      final deco =
          tester.widget<DecoratedBox>(find.byKey(box)).decoration
              as BoxDecoration;
      expect(deco.color, PColors.light.bgNeutralWeakPressed);
      await gesture.up();
    });

    testWidgets('alert 는 라이브 영역으로 읽힌다', (tester) async {
      final semantics = tester.ensureSemantics();
      for (final alert in [true, false]) {
        await pumpBanner(
          tester,
          PPageBanner(
            key: UniqueKey(),
            tone: PPageBannerTone.critical,
            title: '연결 끊김',
            description: '시세를 받지 못해요.',
            alert: alert,
          ),
        );
        expect(
          tester
              .getSemantics(find.byKey(text))
              .getSemanticsData()
              .flagsCollection
              .isLiveRegion,
          alert,
        );
      }
      semantics.dispose();
    });

    testWidgets('규칙에 어긋난 조합은 만들 수 없다', (tester) async {
      expect(
        () => PPageBanner(
          description: '본문',
          interaction: PPageBannerInteraction.actionable,
        ),
        throwsAssertionError,
      );
      expect(
        () => PPageBanner(
          description: '본문',
          interaction: PPageBannerInteraction.actionable,
          onPressed: () {},
          button: PPageBannerButton(label: '업데이트', onPressed: () {}),
        ),
        throwsAssertionError,
      );
      expect(
        () => PPageBanner(
          description: '본문',
          interaction: PPageBannerInteraction.dismissible,
          dismissLabel: _closeLabel,
          button: PPageBannerButton(label: '업데이트', onPressed: () {}),
        ),
        throwsAssertionError,
      );
      expect(
        () => PPageBanner(
          description: '본문',
          interaction: PPageBannerInteraction.dismissible,
        ),
        throwsAssertionError,
      );
    });

    testWidgets('Dismissible — 닫기는 이름 있는 버튼, 누르면 바로 걷히고 초점은 다음 요소로 간다', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final after = FocusNode();
      addTearDown(after.dispose);
      var dismissed = 0;
      await tester.pumpWidget(
        _placed(
          Brightness.light,
          Column(
            children: [
              PPageBanner(
                interaction: PPageBannerInteraction.dismissible,
                title: '새 기능',
                description: '반복 거래를 기록해요.',
                dismissLabel: _closeLabel,
                onDismiss: () => dismissed++,
              ),
              Focus(focusNode: after, child: const SizedBox(height: 20)),
            ],
          ),
          width: 390,
        ),
      );
      final node = tester.getSemantics(find.bySemanticsLabel(_closeLabel));
      expect(node.getSemanticsData().flagsCollection.isButton, isTrue);
      Focus.of(
        tester.element(find.byKey(const ValueKey('page-banner-close'))),
      ).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.pump();
      expect(find.byKey(box), findsNothing);
      expect(dismissed, 1);
      expect(after.hasPrimaryFocus, isTrue);
      semantics.dispose();
    });

    testWidgets('Dismissible — open 을 주면 부르는 쪽이 정하고 닫기 누르는 영역은 40 × 40 이다', (
      tester,
    ) async {
      var open = true;
      var dismissed = 0;
      late StateSetter setOuter;
      await tester.pumpWidget(
        _placed(
          Brightness.light,
          StatefulBuilder(
            builder: (context, setState) {
              setOuter = setState;
              return PPageBanner(
                interaction: PPageBannerInteraction.dismissible,
                description: '반복 거래를 기록해요.',
                dismissLabel: _closeLabel,
                open: open,
                onDismiss: () => dismissed++,
              );
            },
          ),
          width: 390,
        ),
      );
      final center = tester.getCenter(
        find.byKey(const ValueKey('page-banner-close')),
      );
      await tester.tapAt(center + const Offset(18, 0));
      await tester.tapAt(center + const Offset(0, -18));
      expect(dismissed, 2);
      // 부르는 쪽이 open 을 그대로 두면 그대로 있다
      expect(find.byKey(box), findsOneWidget);
      await tester.tapAt(center + const Offset(22, 0));
      expect(dismissed, 2);
      setOuter(() => open = false);
      await tester.pump();
      expect(find.byKey(box), findsNothing);
    });

    testWidgets('글은 낱말 단위로 줄을 바꾸고 제목과 본문은 두 칸 띄운다', (tester) async {
      await pumpBanner(tester, display());
      final plain = _rootSpan(
        tester,
        find.byKey(text),
      ).toPlainText(includeSemanticsLabels: false);
      expect(plain, '${keepAll('새 버전')}  ${keepAll('더 빨라졌어요.')}');
    });
  });

  // ══════════════════════════════════════════════════════════════
  // Result Section
  // ══════════════════════════════════════════════════════════════
  group('Result Section 모양', () {
    const content = ValueKey('result-section-content');
    const asset = ValueKey('result-section-asset');
    const title = ValueKey('result-section-title');
    const description = ValueKey('result-section-description');
    const primary = ValueKey('result-section-primary');
    const secondary = ValueKey('result-section-secondary');

    Widget placedIn(Brightness mode, Widget child, {double height = 700}) =>
        _app(
          mode,
          home: Scaffold(
            body: SizedBox(width: 390, height: height, child: child),
          ),
        );

    PResultSection section(
      PResultKind kind,
      PResultSize size, {
      PResultPlacement placement = PResultPlacement.screen,
      bool withDescription = true,
      bool withPrimary = true,
      bool withSecondary = true,
    }) => PResultSection(
      kind: kind,
      size: size,
      placement: placement,
      icon: kind == PResultKind.empty ? LucideIcons.receiptText300 : null,
      title: '이번 달 거래가 없어요',
      description: withDescription ? '거래를 기록하면 여기에 모여요.' : null,
      primaryAction: withPrimary
          ? PResultAction(label: '거래 추가', onPressed: () {})
          : null,
      secondaryAction: withSecondary
          ? PResultAction(label: '홈으로', onPressed: () {})
          : null,
    );

    for (final mode in Brightness.values) {
      testWidgets('${mode.name} — 크기 × 결과가 스펙 값이다', (tester) async {
        _viewport(tester, const Size(390, 700));
        final failures = <String>[];
        for (final combo in _result.combos(['size', 'kind'])) {
          final size = PResultSize.values.byName(combo['size']!);
          final kind = PResultKind.values.byName(combo['kind']!);
          await tester.pumpWidget(placedIn(mode, section(kind, size)));
          await tester.pump(const Duration(milliseconds: 400));
          final k = _Check(
            mode,
            _result.resolve(combo, 'enabled'),
            '${mode.name} $combo',
          );

          // ── 묶음 ── 좌우 48 · 위아래 16, 가운데
          final pad = tester.widget<Padding>(find.byKey(content)).padding;
          k.px('root.paddingX', pad.horizontal / 2);
          k.px('root.paddingY', pad.vertical / 2);
          final group = tester.getRect(find.byKey(content));
          // 놓인 자리(390 × 700)의 가로 · 세로 가운데
          if ((group.center.dx - 195).abs() > 0.5 ||
              (group.center.dy - 350).abs() > 0.5) {
            k.fail('root.alignItems: 가운데 (195, 350) · 실제 ${group.center}');
          }

          // ── 아이콘 ── 40 · 아래 16
          final icon = tester.widget<Icon>(find.byKey(asset));
          k.px('asset.size', icon.size!);
          k.color('asset.color', icon.color!);
          final iconRect = tester.getRect(find.byKey(asset));
          final titleRect = tester.getRect(find.byKey(title));
          k.px('asset.marginBottom', titleRect.top - iconRect.bottom);
          // 가운데 정렬
          for (final r in [iconRect, titleRect]) {
            if ((r.center.dx - 195).abs() > 0.5) {
              k.fail('textAlign center: 가운데 195 · 실제 ${r.center.dx}');
            }
          }
          if (kind == PResultKind.failure) {
            expect(icon.icon, LucideIcons.circleAlert300);
          } else if (kind == PResultKind.done) {
            expect(icon.icon, LucideIcons.circleCheck300);
          }
          // 선 1.5 — lucide 300 굵기
          expect(icon.icon!.fontFamily, 'Lucide300');

          // ── 제목 · 설명 ──
          final titleText = tester.widget<Text>(find.byKey(title));
          k.typo('title.typography', titleText.style!);
          k.weight('title.fontWeight', titleText.style!);
          k.color('title.foreground', titleText.style!.color!);
          expect(titleText.textAlign, TextAlign.center);
          final descText = tester.widget<Text>(find.byKey(description));
          k.typo('description.typography', descText.style!);
          k.weight('description.fontWeight', descText.style!);
          k.color('description.foreground', descText.style!.color!);
          expect(descText.textAlign, TextAlign.center);
          final descRect = tester.getRect(find.byKey(description));
          k.px('description.marginTop', descRect.top - titleRect.bottom);

          // ── 버튼 ── 위 28 · 24, 첫 버튼 medium 40 neutralWeak, 둘째 글 버튼 36 muted
          final primaryButton = tester.widget<PButton>(
            find.descendant(
              of: find.byKey(primary),
              matching: find.byType(PButton),
            ),
          );
          final secondaryRect = tester.getRect(
            find.descendant(
              of: find.byKey(secondary),
              matching: find.byKey(const ValueKey('text-button-box')),
            ),
          );
          final secondaryLabel = tester.widget<Text>(
            find.descendant(
              of: find.byKey(secondary),
              matching: find.byKey(const ValueKey('text-button-label')),
            ),
          );
          final primaryRect = tester.getRect(
            find.descendant(
              of: find.byKey(primary),
              matching: find.byType(PButton),
            ),
          );
          k.px('actions.marginTop', primaryRect.top - descRect.bottom);
          final primarySpec = '${k.want['primaryButton.buttonSize']}'.split(
            ' ',
          );
          final secondarySpec = '${k.want['secondaryButton.buttonSize']}'.split(
            ' ',
          );
          if (primaryButton.size.name != primarySpec[0] ||
              primaryRect.height != double.parse(primarySpec[1]) ||
              primaryButton.variant != PButtonVariant.neutralWeak) {
            k.fail(
              'primaryButton: 스펙 ${primarySpec.join(' ')} neutralWeak · 실제 ${primaryButton.size.name} ${primaryRect.height} ${primaryButton.variant}',
            );
          }
          // 글 버튼(D2) — 보이는 상자 36, 글 t4 · 700 · fg-neutral-muted
          if (secondaryRect.height != double.parse(secondarySpec[1])) {
            k.fail(
              'secondaryButton: 스펙 ${secondarySpec.join(' ')} · 실제 ${secondaryRect.height}',
            );
          }
          k.color('secondaryButton.foreground', secondaryLabel.style!.color!);
          // 사이 20 — 둘째 버튼이 위아래로 8 블리드해 보이는 상자 사이는 12
          k.pxMinus('actions.gap', 8, secondaryRect.top - primaryRect.bottom);
          // 둘째 버튼은 레이아웃에서 위 8 · 아래 8 을 뺀다 — 묶음 높이 40 + 20 + 20
          final actionsHeight =
              tester.getRect(find.byKey(secondary)).bottom - primaryRect.top;
          final want = 40 + (k.want['actions.gap']! as num) + 20 - 8 - 8 + 8;
          if ((actionsHeight - (40 + 12 + 28)).abs() > 0.5) {
            k.fail('버튼 묶음 높이: 40 + 12 + 28 · 실제 $actionsHeight ($want)');
          }
          failures.addAll(k.failures);
        }
        _expectClean(failures);
      });
    }
  });

  group('Result Section 동작', () {
    const content = ValueKey('result-section-content');
    const title = ValueKey('result-section-title');
    const primary = ValueKey('result-section-primary');
    const secondary = ValueKey('result-section-secondary');

    Future<void> pumpIn(
      WidgetTester tester,
      Widget child, {
      double height = 700,
      bool reduceMotion = false,
    }) async {
      Widget app = _app(
        Brightness.light,
        home: Scaffold(
          body: SizedBox(width: 390, height: height, child: child),
        ),
      );
      if (reduceMotion) {
        app = MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: app,
        );
      }
      await tester.pumpWidget(app);
    }

    testWidgets('놓인 자리에 따라 좌우 여백이 갈린다 — 화면 48 · 카드 0 · 목록 카드 24', (
      tester,
    ) async {
      for (final (placement, want) in [
        (PResultPlacement.screen, 48.0),
        (PResultPlacement.card, 0.0),
        (PResultPlacement.listCard, 24.0),
      ]) {
        await pumpIn(
          tester,
          PResultSection(
            key: UniqueKey(),
            kind: PResultKind.failure,
            size: PResultSize.medium,
            placement: placement,
            title: '거래를 불러오지 못했어요',
          ),
        );
        final pad = tester.widget<Padding>(find.byKey(content)).padding;
        expect(pad.horizontal / 2, want, reason: '$placement');
        expect(resultSectionPaddingX(placement), want);
      }
    });

    testWidgets('카드 안에서는 좁은 카드에서도 제목이 한 줄에 들어간다(좌우 72 를 만들지 않는다)', (
      tester,
    ) async {
      Future<double> titleHeight(PResultPlacement placement) async {
        await tester.pumpWidget(
          _app(
            Brightness.light,
            home: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 300,
                  height: 300,
                  child: PResultSection(
                    key: UniqueKey(),
                    kind: PResultKind.failure,
                    size: PResultSize.medium,
                    placement: placement,
                    title: '거래를 불러오지 못했어요',
                  ),
                ),
              ),
            ),
          ),
        );
        return tester.getSize(find.byKey(title)).height;
      }

      // 폭 300 − 96 = 204 에서는 두 줄 · 카드(0)에서는 한 줄
      expect(await titleHeight(PResultPlacement.screen), 44);
      expect(await titleHeight(PResultPlacement.card), 22);
    });

    testWidgets('empty 는 아이콘을 꼭 준다 · failure · done 은 기본 아이콘이 있다', (
      tester,
    ) async {
      expect(() => PResultSection(title: '이번 달 거래가 없어요'), throwsAssertionError);
      expect(
        () => PResultSection(title: '제목', icon: LucideIcons.bell300),
        returnsNormally,
      );
      await pumpIn(
        tester,
        const PResultSection(kind: PResultKind.failure, title: '문제가 생겼어요'),
      );
      expect(
        tester
            .widget<Icon>(find.byKey(const ValueKey('result-section-asset')))
            .icon,
        LucideIcons.circleAlert300,
      );
      await pumpIn(
        tester,
        const PResultSection(kind: PResultKind.done, title: '끝났어요'),
      );
      expect(
        tester
            .widget<Icon>(find.byKey(const ValueKey('result-section-asset')))
            .icon,
        LucideIcons.circleCheck300,
      );
    });

    testWidgets('설명 · 버튼은 없어도 된다 — 제목만 있는 404', (tester) async {
      await pumpIn(
        tester,
        const PResultSection(
          icon: LucideIcons.searchX300,
          title: '페이지를 찾을 수 없어요',
        ),
      );
      expect(
        find.byKey(const ValueKey('result-section-description')),
        findsNothing,
      );
      expect(find.byKey(primary), findsNothing);
      expect(find.byKey(secondary), findsNothing);
      expect(findText(keepAll('페이지를 찾을 수 없어요')), findsOneWidget);
    });

    testWidgets('버튼을 누르면 그 일을 하고, 로딩 중인 첫 버튼은 누르기를 삼킨다', (tester) async {
      var retry = 0;
      var home = 0;
      await pumpIn(
        tester,
        PResultSection(
          kind: PResultKind.failure,
          title: '문제가 생겼어요',
          primaryAction: PResultAction(
            label: '다시 시도',
            onPressed: () => retry++,
          ),
          secondaryAction: PResultAction(label: '홈으로', onPressed: () => home++),
        ),
      );
      await tester.tap(findText('다시 시도'));
      await tester.tap(findText('홈으로'));
      expect(retry, 1);
      expect(home, 1);

      await pumpIn(
        tester,
        PResultSection(
          key: UniqueKey(),
          kind: PResultKind.failure,
          title: '문제가 생겼어요',
          primaryAction: PResultAction(
            label: '다시 시도',
            loading: true,
            onPressed: () => retry++,
          ),
        ),
      );
      await tester.tap(find.byKey(primary));
      expect(retry, 1);
      expect(tester.widget<PButton>(find.byType(PButton)).loading, isTrue);
    });

    testWidgets('둘째 버튼만 있어도 글 자리만 차지한다(위아래 8 블리드)', (tester) async {
      await pumpIn(
        tester,
        PResultSection(
          kind: PResultKind.failure,
          title: '문제가 생겼어요',
          secondaryAction: PResultAction(label: '홈으로', onPressed: () {}),
        ),
      );
      expect(tester.getSize(find.byKey(secondary)).height, 36 - 16);
    });

    testWidgets('제목은 제목으로, 묶음은 라이브 영역으로 읽고 아이콘은 읽지 않는다', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpIn(
        tester,
        const PResultSection(
          kind: PResultKind.failure,
          title: '거래를 불러오지 못했어요',
          description: '잠시 뒤 다시 시도해 주세요.',
          headingLevel: 1,
        ),
      );
      // 처음 한 프레임은 투명도 0 이라 읽히지 않는다 — 나타나는 때 라이브 영역이 읽는다(웹의 첫 프레임 감춤과 같다)
      expect(find.semantics.byLabel(RegExp('거래를 불러오지 못했어요')), findsNothing);
      await tester.pump(const Duration(milliseconds: 20));
      final heading = tester.getSemantics(find.byKey(title));
      final flags = heading.getSemanticsData().flagsCollection;
      expect(flags.isHeader, isTrue);
      expect(heading.getSemanticsData().headingLevel, 1);
      // 제목 · 설명이 한 묶음으로 읽히고 이음 문자는 읽지 않는다 — 아이콘은 읽지 않는다
      expect(heading.label, contains('거래를 불러오지 못했어요'));
      expect(heading.label, contains('잠시 뒤 다시 시도해 주세요.'));
      expect(heading.label, isNot(contains('\u2060')));
      expect(flags.isLiveRegion, isTrue);
      semantics.dispose();
    });

    testWidgets('결과로 바뀌면 150ms enter 로 투명도가 올라온다 — 모션 줄이기면 바로', (tester) async {
      await pumpIn(
        tester,
        const PResultSection(kind: PResultKind.done, title: '끝났어요'),
      );
      Opacity opacity() => tester.widget<Opacity>(
        find.ancestor(of: find.byKey(content), matching: find.byType(Opacity)),
      );
      expect(opacity().opacity, 0);
      await tester.pump(const Duration(milliseconds: 75));
      expect(opacity().opacity, closeTo(PEasing.enter.transform(0.5), 1e-3));
      await tester.pump(const Duration(milliseconds: 100));
      expect(opacity().opacity, 1);

      await pumpIn(
        tester,
        PResultSection(key: UniqueKey(), kind: PResultKind.done, title: '끝났어요'),
        reduceMotion: true,
      );
      expect(
        find.ancestor(of: find.byKey(content), matching: find.byType(Opacity)),
        findsNothing,
      );
    });

    testWidgets('높이를 정해 주지 않아도(목록 안) 내용만큼 차지한다', (tester) async {
      await tester.pumpWidget(
        _app(
          Brightness.light,
          home: Scaffold(
            body: ListView(
              children: const [
                PResultSection(
                  kind: PResultKind.failure,
                  size: PResultSize.medium,
                  title: '거래를 불러오지 못했어요',
                  description: '잠시 뒤 다시 시도해 주세요.',
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
      // 위 16 + 아이콘 40 + 16 + 제목 22 + 8 + 설명 19 + 아래 16
      expect(
        tester.getSize(find.byKey(content)).height,
        16 + 40 + 16 + 22 + 8 + 19 + 16,
      );
    });
  });

  group('피드백 부품', () {
    test('누르는 자리 — 보이는 상자 + 넓힘, 그래도 모자라면 가운데 기준으로 더 넓힌다', () {
      const box = Rect.fromLTWH(100, 100, 60, 19);
      expect(
        feedbackSlopArea(box, const EdgeInsets.symmetric(horizontal: 8), 0, 44),
        const Rect.fromLTRB(92, 87.5, 168, 131.5),
      );
      expect(
        feedbackSlopArea(box, const EdgeInsets.all(11), 0, 0),
        const Rect.fromLTRB(89, 89, 171, 130),
      );
      // 이미 충분하면 더 넓히지 않는다
      expect(
        feedbackSlopArea(box, const EdgeInsets.all(30), 44, 44),
        const Rect.fromLTRB(70, 70, 190, 149),
      );
    });
  });
}
