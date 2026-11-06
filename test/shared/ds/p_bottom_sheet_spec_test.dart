// Bottom Sheet 가 스펙 값(test/fixtures/design_spec/bottom-sheet.json)대로 그려지는지 — 손잡이 × 끝 흐림 × 상태 × 라이트 ·
// 다크를 모두 돈다. 웹은 같은 JSON 을 크로미움에서 잰다(desk-front `npm run ds:check`).
//
// 앱에 없는 상태(웹의 focused — 키보드 포커스 링)는 재지 않는다. 문장으로 된 값은 그린 결과나 동작으로 본다 — 최대 높이
// "화면 높이의 90%" 는 긴 내용으로, 안전 영역은 기기 여백을 줘서, 누름 축소 "2px 거리" 는 그려진 배율로, 시간 · 곡선은
// 흐르는 시간으로, z-index(100 · 101)는 라우트가 쌓이는 차례로 잰다. 동작(닫는 길 · 끌어서 닫기 · 스냅 높이 · 키보드)은
// 아래 동작 group 이 본다.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/overlay/p_overlay.dart';
import 'package:groo_damda_app/shared/ds/scroll_fog/p_scroll_fog.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';

import '../../support/design_spec.dart';
import '../../support/plain_text.dart';

final _spec = DesignSpec.load('bottom-sheet');

PColors _colors(Brightness mode) =>
    mode == Brightness.dark ? PColors.dark : PColors.light;

ThemeData _theme(Brightness mode) =>
    mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light();

void _viewport(
  WidgetTester tester,
  Size size, {
  double safeBottom = 0,
  double keyboard = 0,
}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = FakeViewPadding(bottom: safeBottom);
  tester.view.viewPadding = FakeViewPadding(bottom: safeBottom);
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
  addTearDown(tester.view.reset);
}

Widget _app(Brightness mode, Widget home) => MaterialApp(
  theme: _theme(mode),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('ko'),
  home: home,
);

PButton _btn(String label, {VoidCallback? onPressed}) => PButton(
  label: label,
  size: PButtonSize.large,
  onPressed: onPressed ?? () {},
);

PBottomSheetContent _content({
  bool fog = false,
  bool footer = true,
  bool description = true,
  bool tall = false,
  bool closeButton = true,
  bool closePressed = false,
  List<PButton>? buttons,
}) => PBottomSheetContent(
  title: '기간',
  description: description ? '고른 기간의 거래만 보여요.' : null,
  closeLabel: closeButton ? '닫기' : null,
  showCloseButton: closeButton,
  closePressed: closePressed,
  scrollFog: fog,
  body: tall
      ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < 40; i++)
              SizedBox(
                key: ValueKey('row-$i'),
                height: 48,
                child: Text('줄 $i'),
              ),
          ],
        )
      : const Text('본문', key: ValueKey('body-text')),
  footer: footer ? (buttons ?? [_btn('초기화'), _btn('적용')]) : const [],
);

Widget _view(PBottomSheetContent content, {bool handle = false}) => Scaffold(
  body: PBottomSheetView(content: content, showHandle: handle),
);

const _root = ValueKey('p-bottom-sheet-root');

Rect _rect(WidgetTester tester, Key key) =>
    tester.getRect(find.byKey(key).first);

void _expectColor(Object? want, Brightness mode, Color actual, [String? why]) {
  expect(
    sameColor(specColor(pickMode(want, mode)), actual),
    isTrue,
    reason: '${why ?? ''} 기대 ${pickMode(want, mode)} 실제 ${colorHex(actual)}',
  );
}

void main() {
  for (final mode in [Brightness.light, Brightness.dark]) {
    for (final combo in _spec.combos(['handle', 'scrollFog'])) {
      for (final state in ['enabled', 'pressed']) {
        testWidgets(
          'handle ${combo['handle']} · fog ${combo['scrollFog']} · $state · ${mode.name} — 시트가 스펙 값이다',
          (tester) async {
            // 480 보다 넓은 화면 — 가운데에 최대 폭으로 선다
            _viewport(tester, const Size(600, 900));
            final want = _spec.resolve(combo, state);
            final fog = combo['scrollFog'] == 'on';
            final handle = combo['handle'] == 'shown';
            final colors = _colors(mode);
            await tester.pumpWidget(
              _app(
                mode,
                _view(
                  _content(fog: fog, closePressed: state == 'pressed'),
                  handle: handle,
                ),
              ),
            );
            await tester.pumpAndSettle();

            // ── 시트 ──
            final sheet = _rect(tester, _root);
            expect(sheet.width, (want['root.maxWidth'] as num).toDouble());
            expect(sheet.center.dx, 300);
            expect(sheet.bottom, 900);
            final decoration =
                tester.widget<DecoratedBox>(find.byKey(_root)).decoration
                    as BoxDecoration;
            const radius = Radius.circular(24);
            expect(
              decoration.borderRadius,
              const BorderRadius.vertical(top: radius),
            );
            expect(want['root.radius'], 24);
            _expectColor(want['root.background'], mode, decoration.color!);
            expect(want['root.shadow'], 'none');
            expect(decoration.boxShadow, isNull);

            // ── 머리 ──
            final title = _rect(tester, const ValueKey('p-bottom-sheet-title'));
            final desc = _rect(
              tester,
              const ValueKey('p-bottom-sheet-description'),
            );
            final gutter = (want['header.paddingX'] as num).toDouble();
            expect(title.top - sheet.top, want['header.paddingTop']);
            expect(title.left - sheet.left, gutter);
            // 제목 오른쪽 64(24 + 원 28 + 12)를 비운다
            expect(sheet.right - title.right, 64);
            expect(desc.top - title.bottom, want['header.gap']);
            expect(desc.left - sheet.left, gutter);
            expect(sheet.right - desc.right, gutter);
            final titleStyle = tester
                .widget<Text>(
                  find.byKey(const ValueKey('p-bottom-sheet-title')),
                )
                .style!;
            final t = want['title.typography'] as Map<String, dynamic>;
            expect(titleStyle.fontSize, (t['fontSize'] as num).toDouble());
            expect(
              titleStyle.fontSize! * titleStyle.height!,
              closeTo((t['lineHeight'] as num).toDouble(), 0.01),
            );
            expect(titleStyle.fontWeight, FontWeight.w700);
            _expectColor(want['title.foreground'], mode, titleStyle.color!);
            final descStyle = tester
                .widget<Text>(
                  find.byKey(const ValueKey('p-bottom-sheet-description')),
                )
                .style!;
            final d = want['description.typography'] as Map<String, dynamic>;
            expect(descStyle.fontSize, (d['fontSize'] as num).toDouble());
            expect(
              descStyle.fontSize! * descStyle.height!,
              closeTo((d['lineHeight'] as num).toDouble(), 0.01),
            );
            expect(descStyle.fontWeight, FontWeight.w400);
            _expectColor(
              want['description.foreground'],
              mode,
              descStyle.color!,
            );

            // ── 닫기 버튼 ──
            final circle = _rect(
              tester,
              const ValueKey('p-bottom-sheet-close-circle'),
            );
            final touch = _rect(tester, const ValueKey('p-bottom-sheet-close'));
            final size = (want['closeButton.size'] as num).toDouble();
            final scale = state == 'pressed' ? (size - 2) / size : 1.0;
            // 눌렀을 때 줄어든 배율 — 가운데 기준 28 → 26
            expect(circle.width, closeTo(size * scale, 0.01));
            expect(circle.height, closeTo(size * scale, 0.01));
            expect(touch.size, const Size(44, 44));
            expect(circle.center, touch.center);
            // 위 24 · 오른쪽 24(줄어들기 전 자리)
            expect(
              touch.center.dy - sheet.top - size / 2,
              want['closeButton.top'],
            );
            expect(
              sheet.right - touch.center.dx - size / 2,
              want['closeButton.right'],
            );
            final circleBox = tester.widget<DecoratedBox>(
              find.byKey(const ValueKey('p-bottom-sheet-close-circle')),
            );
            expect(
              (circleBox.decoration as BoxDecoration).shape,
              BoxShape.circle,
            );
            expect(want['closeButton.radius'], 9999);
            _expectColor(
              want['closeButton.background'],
              mode,
              (circleBox.decoration as BoxDecoration).color!,
              'close bg',
            );
            final icon = tester.widget<Icon>(
              find.descendant(
                of: find.byKey(const ValueKey('p-bottom-sheet-close')),
                matching: find.byIcon(LucideIcons.x),
              ),
            );
            expect(icon.size, want['closeButton.iconSize']);
            _expectColor(want['closeButton.color'], mode, icon.color!);
            expect(want['closeButton.touchTarget'], '44 × 44');
            expect(want['closeButton.transitionDuration'], '150ms');
            expect(
              PDuration.colorTransition,
              const Duration(milliseconds: 150),
            );
            expect(
              state == 'pressed'
                  ? colors.bgNeutralWeakPressed
                  : colors.bgNeutralWeak,
              (circleBox.decoration as BoxDecoration).color,
            );

            // ── 본문 · 바닥 ──
            final body = _rect(tester, const ValueKey('body-text'));
            expect(body.left - sheet.left, want['body.paddingX']);
            expect(
              body.top -
                  desc.bottom -
                  (want['header.paddingBottom'] as num) -
                  (fog ? (want['body.paddingTop'] as num) : 0),
              0,
            );
            final buttons = find.byType(PButton);
            final first = tester.getRect(buttons.first);
            final second = tester.getRect(buttons.last);
            expect(first.height, 48);
            expect(want['footer.buttonSize'], 'large 48');
            expect(first.left - sheet.left, want['footer.paddingX']);
            expect(sheet.right - second.right, want['footer.paddingX']);
            // 둘이면 반씩, 사이 8
            expect(first.right + (want['footer.gap'] as num), second.left);
            expect(first.width, second.width);
            expect(sheet.bottom - first.bottom, want['footer.paddingBottom']);
            // 본문 ↔ 바닥 — 본문이 짧으면 12(바닥 위), 흐림이면 본문 안 아래 여백 80 이 더해진다
            final bodyBox = tester.getRect(
              find.descendant(
                of: find.byType(PBottomSheetContent),
                matching: find.byType(SingleChildScrollView),
              ),
            );
            expect(
              first.top - bodyBox.bottom,
              (want['footer.paddingTop'] as num).toDouble(),
            );
            if (fog) {
              expect(want['body.paddingTop'], 20);
              expect(want['body.paddingBottom'], 80);
              expect(bodyBox.bottom - body.bottom, 80);
              expect(scrollFogMetrics(PScrollFogUse.overlayBody), (
                fogStart: 20.0,
                fogEnd: 80.0,
                padStart: 20.0,
                padEnd: 80.0,
              ));
              expect(want['fog.size'], '위 20px · 아래 80px');
              // 끝 흐림 마스크가 걸려 있다
              expect(
                find.descendant(
                  of: find.byType(PBottomSheetContent),
                  matching: find.byType(ShaderMask),
                ),
                findsWidgets,
              );
            } else {
              expect(
                find.descendant(
                  of: find.byType(PBottomSheetContent),
                  matching: find.byType(ShaderMask),
                ),
                findsNothing,
              );
            }

            // ── 손잡이 ──
            final bar = find.byKey(const ValueKey('p-bottom-sheet-handle-bar'));
            if (handle) {
              final h = tester.getRect(bar);
              expect(
                h.size,
                Size(
                  (want['handle.width'] as num).toDouble(),
                  (want['handle.height'] as num).toDouble(),
                ),
              );
              expect(h.top - sheet.top, want['handle.top']);
              expect(h.center.dx, sheet.center.dx);
              final hd =
                  tester.widget<DecoratedBox>(bar).decoration as BoxDecoration;
              expect(hd.borderRadius, BorderRadius.circular(PRounded.full));
              _expectColor(want['handle.background'], mode, hd.color!);
              expect(
                _rect(tester, const ValueKey('p-bottom-sheet-handle')).size,
                const Size(44, 44),
              );
              // 보조 기술에는 숨긴다
              expect(
                find.ancestor(
                  of: find.byKey(const ValueKey('p-bottom-sheet-handle')),
                  matching: find.byType(ExcludeSemantics),
                ),
                findsWidgets,
              );
            } else {
              expect(bar, findsNothing);
            }
          },
        );
      }
    }
  }

  testWidgets('화면이 480 보다 좁으면 화면 폭 전체이고, 높이는 화면의 90% 를 넘지 않는다', (tester) async {
    _viewport(tester, const Size(390, 800));
    await tester.pumpWidget(
      _app(Brightness.light, _view(_content(tall: true))),
    );
    await tester.pumpAndSettle();
    final sheet = _rect(tester, _root);
    expect(sheet.width, 390);
    expect(sheet.height, closeTo(720, 0.01));
    expect(sheet.top, closeTo(80, 0.01));
    // 넘치는 본문은 안에서 스크롤한다
    final scroll = find.descendant(
      of: find.byType(PBottomSheetContent),
      matching: find.byType(SingleChildScrollView),
    );
    expect(
      tester
          .state<ScrollableState>(
            find.descendant(of: scroll, matching: find.byType(Scrollable)),
          )
          .position
          .maxScrollExtent,
      greaterThan(0),
    );
  });

  testWidgets('안전 영역을 바닥 아래에 더한다 · 키보드가 있으면 더하지 않는다', (tester) async {
    _viewport(tester, const Size(390, 800), safeBottom: 34);
    await tester.pumpWidget(_app(Brightness.light, _view(_content())));
    await tester.pumpAndSettle();
    var sheet = _rect(tester, _root);
    var button = tester.getRect(find.byType(PButton).first);
    expect(sheet.bottom - button.bottom, 16 + 34);

    _viewport(tester, const Size(390, 800), safeBottom: 34, keyboard: 300);
    await tester.pumpWidget(_app(Brightness.light, _view(_content())));
    await tester.pumpAndSettle();
    sheet = _rect(tester, _root);
    button = tester.getRect(find.byType(PButton).first);
    expect(sheet.bottom - button.bottom, 16);
  });

  testWidgets('바닥이 없으면 본문 아래 16 이다', (tester) async {
    _viewport(tester, const Size(390, 800));
    await tester.pumpWidget(
      _app(Brightness.light, _view(_content(footer: false))),
    );
    await tester.pumpAndSettle();
    final sheet = _rect(tester, _root);
    final body = _rect(tester, const ValueKey('body-text'));
    expect(sheet.bottom - body.bottom, 16);
  });

  testWidgets('설명이 없으면 머리는 제목뿐이고 닫기 버튼을 끄면 제목 오른쪽을 비우지 않는다', (tester) async {
    _viewport(tester, const Size(390, 800));
    await tester.pumpWidget(
      _app(
        Brightness.light,
        _view(_content(description: false, closeButton: false)),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('p-bottom-sheet-description')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('p-bottom-sheet-close')), findsNothing);
    final sheet = _rect(tester, _root);
    final title = _rect(tester, const ValueKey('p-bottom-sheet-title'));
    expect(sheet.right - title.right, 24);
  });

  testWidgets('바닥 버튼은 Button large 48 만 둔다', (tester) async {
    expect(
      () => PBottomSheetContent(
        title: '제목',
        closeLabel: '닫기',
        body: const SizedBox(),
        footer: [PButton(label: '저장', onPressed: () {})],
      ),
      throwsAssertionError,
    );
  });

  testWidgets('닫기 버튼 누르는 영역은 44 × 44 — 보이는 원 밖 가장자리를 눌러도 닫힌다', (tester) async {
    _viewport(tester, const Size(390, 800));
    var closed = 0;
    await tester.pumpWidget(
      _app(
        Brightness.light,
        Scaffold(
          body: PBottomSheetView(
            content: PBottomSheetContent(
              title: '제목',
              closeLabel: '닫기',
              onClose: () => closed += 1,
              body: const SizedBox(),
            ),
          ),
        ),
      ),
    );
    final circle = _rect(tester, const ValueKey('p-bottom-sheet-close-circle'));
    await tester.tapAt(circle.center + const Offset(20, 0));
    expect(closed, 1);
  });

  group('동작', () {
    const leaveCopy = PLeaveConfirmCopy(
      title: '작성한 내용이 사라져요',
      description: '나가면 입력한 내용이 저장되지 않아요.',
      stayLabel: '계속 작성',
      leaveLabel: '나가기',
    );

    late BuildContext ctx;
    Future<void> pumpHost(
      WidgetTester tester, {
      Brightness mode = Brightness.light,
      Size size = const Size(390, 800),
      double safeBottom = 0,
      double keyboard = 0,
      bool reduceMotion = false,
    }) async {
      _viewport(tester, size, safeBottom: safeBottom, keyboard: keyboard);
      final page = Scaffold(
        body: Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox.expand();
          },
        ),
      );
      final home = reduceMotion
          ? Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: page,
              ),
            )
          : page;
      await tester.pumpWidget(_app(mode, home));
    }

    // 마지막으로 연 시트의 결과 — 시트가 닫혀야 끝나므로 기다리지 않는다
    late Future<Object?> last;
    Future<void> show<T>(
      WidgetTester tester, {
      bool form = false,
      bool Function()? isDirty,
      List<double>? snaps,
      bool tall = false,
      bool settle = true,
      PBottomSheetContent? content,
    }) async {
      last = PBottomSheet.show<T>(
        ctx,
        form: form,
        isDirty: isDirty,
        leaveCopy: isDirty == null ? null : leaveCopy,
        snapPoints: snaps,
        builder: (_) => content ?? _content(tall: tall, footer: false),
      );
      await tester.pump();
      if (settle) await tester.pumpAndSettle();
    }

    double top(WidgetTester tester) => _rect(tester, _root).top;

    // 시트의 제목 — 짧은 시트에서도 시트 위를 잡는다
    Offset grab(WidgetTester tester) =>
        tester.getCenter(find.byKey(const ValueKey('p-bottom-sheet-title')));

    testWidgets('닫기 버튼은 닫는다', (tester) async {
      await pumpHost(tester);
      await show<void>(tester);
      var done = false;
      unawaited(last.then((_) => done = true));
      await tester.tap(find.byKey(const ValueKey('p-bottom-sheet-close')));
      await tester.pumpAndSettle();
      expect(done, isTrue);
      expect(find.byType(PBottomSheetContent), findsNothing);
    });

    testWidgets('Esc · 뒤로 가기는 늘 닫는다', (tester) async {
      await pumpHost(tester);
      await show<void>(tester, form: true);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(PBottomSheetContent), findsNothing);

      await show<void>(tester, form: true);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(PBottomSheetContent), findsNothing);
    });

    testWidgets('조회 · 고르기 시트는 바깥(딤)을 누르면 닫고, 입력 폼은 무시한다', (tester) async {
      await pumpHost(tester);
      await show<void>(tester);
      await tester.tapAt(const Offset(195, 20));
      await tester.pumpAndSettle();
      expect(find.byType(PBottomSheetContent), findsNothing);

      await show<void>(tester, form: true);
      await tester.tapAt(const Offset(195, 20));
      await tester.pumpAndSettle();
      expect(find.byType(PBottomSheetContent), findsOneWidget);
    });

    testWidgets('PBottomSheet.of 로 닫으면 결과가 show 의 값이다 — 묻지 않는다', (
      tester,
    ) async {
      await pumpHost(tester);
      await show<String>(
        tester,
        isDirty: () => true,
        form: true,
        content: PBottomSheetContent(
          title: '저장',
          closeLabel: '닫기',
          body: const SizedBox(),
          footer: [
            PButton(label: '저장', size: PButtonSize.large, onPressed: () {}),
          ],
        ),
      );
      // 바닥 버튼은 시트 안 문맥으로 닫는다
      final inside = tester.element(find.byType(PBottomSheetContent));
      PBottomSheet.of(inside).close('저장함');
      await tester.pumpAndSettle();
      expect(await last, '저장함');
      expect(find.byType(PAlertDialogView), findsNothing);
    });

    group('바뀐 값이 있으면 닫기 전에 묻는다', () {
      for (final via in ['닫기 버튼', 'Esc', '뒤로 가기']) {
        testWidgets('$via — 확인창이 뜨고 시트는 그대로, 계속 작성이면 남는다', (tester) async {
          await pumpHost(tester);
          await show<void>(tester, form: true, isDirty: () => true);
          Future<void> trigger() async {
            switch (via) {
              case '닫기 버튼':
                await tester.tap(
                  find.byKey(const ValueKey('p-bottom-sheet-close')),
                );
              case 'Esc':
                await tester.sendKeyEvent(LogicalKeyboardKey.escape);
              default:
                await tester.binding.handlePopRoute();
            }
            await tester.pumpAndSettle();
          }

          await trigger();
          expect(find.byType(PAlertDialogView), findsOneWidget);
          expect(findText(keepAll('작성한 내용이 사라져요')), findsOneWidget);
          expect(find.byType(PBottomSheetContent), findsOneWidget);
          await tester.tap(findWidgetWithText(PButton, '계속 작성'));
          await tester.pumpAndSettle();
          expect(find.byType(PAlertDialogView), findsNothing);
          expect(find.byType(PBottomSheetContent), findsOneWidget);

          // 나가기 — 시트도 닫힌다
          await trigger();
          await tester.tap(findWidgetWithText(PButton, '나가기'));
          await tester.pumpAndSettle();
          expect(find.byType(PBottomSheetContent), findsNothing);
        });
      }

      testWidgets('바뀐 값이 없으면 바로 닫는다', (tester) async {
        await pumpHost(tester);
        await show<void>(tester, form: true, isDirty: () => false);
        await tester.tap(find.byKey(const ValueKey('p-bottom-sheet-close')));
        await tester.pumpAndSettle();
        expect(find.byType(PAlertDialogView), findsNothing);
        expect(find.byType(PBottomSheetContent), findsNothing);
      });

      testWidgets('묻는 확인창은 시트 위에 뜨고 나가기는 Critical 이다', (tester) async {
        await pumpHost(tester);
        await show<void>(tester, form: true, isDirty: () => true);
        await tester.tap(find.byKey(const ValueKey('p-bottom-sheet-close')));
        await tester.pumpAndSettle();
        final leave = tester.widget<PButton>(
          findWidgetWithText(PButton, '나가기'),
        );
        expect(leave.variant, PButtonVariant.criticalSolid);
        expect(
          tester.widget<PButton>(findWidgetWithText(PButton, '계속 작성')).variant,
          PButtonVariant.neutralWeak,
        );
      });
    });

    group('끌어서 닫기', () {
      Future<double> openAndWait(
        WidgetTester tester, {
        bool form = false,
      }) async {
        await pumpHost(tester);
        await show<void>(tester, form: form);
        await tester.pump(const Duration(milliseconds: 600));
        return top(tester);
      }

      testWidgets('느리게 높이의 25% 넘게 내리면 닫는다', (tester) async {
        final t0 = await openAndWait(tester);
        final h = _rect(tester, _root).height;
        await tester.timedDragFrom(
          grab(tester),
          Offset(0, h * 0.4),
          const Duration(seconds: 3),
        );
        await tester.pumpAndSettle();
        expect(find.byType(PBottomSheetContent), findsNothing);
        expect(t0, isNonZero);
      });

      testWidgets('느리게 25% 못 미치게 내리면 제자리로 돌아온다(200ms)', (tester) async {
        final t0 = await openAndWait(tester);
        final h = _rect(tester, _root).height;
        final gesture = await tester.startGesture(grab(tester));
        for (var i = 0; i < 10; i++) {
          await gesture.moveBy(Offset(0, h * 0.2 / 10));
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(top(tester), closeTo(t0 + h * 0.2, 0.5));
        await gesture.up();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 210));
        expect(top(tester), closeTo(t0, 0.5));
        expect(find.byType(PBottomSheetContent), findsOneWidget);
      });

      testWidgets('0.4px/ms 보다 빠르게 쓸어내리면 조금만 내려도 닫는다', (tester) async {
        await openAndWait(tester);
        await tester.timedDragFrom(
          grab(tester),
          const Offset(0, 40),
          const Duration(milliseconds: 40),
        );
        await tester.pumpAndSettle();
        expect(find.byType(PBottomSheetContent), findsNothing);
      });

      testWidgets('끄는 동안 딤이 옅어진다', (tester) async {
        await openAndWait(tester);
        double dim() => tester
            .widget<Opacity>(
              find.descendant(
                of: find.byType(PDimLayer),
                matching: find.byType(Opacity),
              ),
            )
            .opacity;
        expect(dim(), closeTo(1, 0.001));
        final h = _rect(tester, _root).height;
        final gesture = await tester.startGesture(grab(tester));
        await gesture.moveBy(Offset(0, h * 0.2));
        await tester.pump();
        expect(dim(), closeTo(0.8, 0.02));
        await gesture.up();
        await tester.pumpAndSettle();
      });

      testWidgets('열린 뒤 0.5초는 끌리지 않는다', (tester) async {
        await pumpHost(tester);
        await show<void>(tester); // 열림이 끝났다 — 300ms 지남
        final t0 = top(tester);
        final gesture = await tester.startGesture(grab(tester));
        await gesture.moveBy(const Offset(0, 120));
        await tester.pump();
        expect(top(tester), t0);
        await gesture.up();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(PBottomSheetContent), findsOneWidget);
        // 0.5초가 지나면 끌린다
        final g2 = await tester.startGesture(grab(tester));
        await g2.moveBy(const Offset(0, 120));
        await tester.pump();
        expect(top(tester), closeTo(t0 + 120, 0.5));
        await g2.up();
        await tester.pumpAndSettle();
      });

      testWidgets('입력 폼은 끌리지 않는다', (tester) async {
        final t0 = await openAndWait(tester, form: true);
        await tester.timedDragFrom(
          grab(tester),
          const Offset(0, 300),
          const Duration(milliseconds: 100),
        );
        await tester.pumpAndSettle();
        expect(find.byType(PBottomSheetContent), findsOneWidget);
        expect(top(tester), t0);
      });

      testWidgets('본문이 스크롤된 동안은 끌지 않고 스크롤한다', (tester) async {
        await pumpHost(tester);
        await show<void>(tester, tall: true);
        await tester.pump(const Duration(milliseconds: 600));
        final scrollable = find.descendant(
          of: find.byType(PBottomSheetContent),
          matching: find.byType(Scrollable),
        );
        final state = tester.state<ScrollableState>(scrollable);
        // 본문 한가운데를 위로 쓸어 올려 스크롤한다
        await tester.drag(
          find.byKey(const ValueKey('row-3')),
          const Offset(0, -150),
        );
        await tester.pump();
        expect(state.position.pixels, greaterThan(0));
        final t0 = top(tester);
        // 스크롤된 채로 내리면 시트가 아니라 본문이 올라온다
        await tester.timedDragFrom(
          const Offset(195, 400),
          const Offset(0, 100),
          const Duration(milliseconds: 100),
        );
        await tester.pump();
        expect(top(tester), t0);
        expect(find.byType(PBottomSheetContent), findsOneWidget);
        expect(state.position.pixels, lessThan(150));
      });

      testWidgets('바뀐 값이 있는 시트를 끌어 닫으면 묻고, 계속 작성이면 제자리다', (tester) async {
        await pumpHost(tester);
        // 조회 · 고르기 시트도 바뀐 값을 살필 수 있다
        final f = PBottomSheet.show<void>(
          ctx,
          isDirty: () => true,
          leaveCopy: leaveCopy,
          builder: (_) => _content(footer: false),
        );
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 600));
        final t0 = top(tester);
        await tester.timedDragFrom(
          grab(tester),
          const Offset(0, 40),
          const Duration(milliseconds: 40),
        );
        await tester.pumpAndSettle();
        expect(find.byType(PAlertDialogView), findsOneWidget);
        await tester.tap(findWidgetWithText(PButton, '계속 작성'));
        await tester.pumpAndSettle();
        expect(top(tester), closeTo(t0, 0.5));
        unawaited(f);
      });
    });

    group('스냅 높이', () {
      testWidgets('손잡이가 있고 낮은 높이에서 열린다', (tester) async {
        await pumpHost(tester);
        await show<void>(tester, snaps: const [0.4, 0.9]);
        expect(
          find.byKey(const ValueKey('p-bottom-sheet-handle')),
          findsOneWidget,
        );
        final sheet = _rect(tester, _root);
        // 시트는 화면의 90% 로 고정하고 보이는 만큼만 남긴다 — 화면 높이의 40%
        expect(sheet.height, closeTo(720, 0.01));
        expect(800 - sheet.top, closeTo(320, 0.5));
      });

      testWidgets('손잡이를 누르면 다음 높이로, 가장 높은 높이에서 누르면 닫는다', (tester) async {
        await pumpHost(tester);
        await show<void>(tester, snaps: const [0.4, 0.9]);
        await tester.tap(find.byKey(const ValueKey('p-bottom-sheet-handle')));
        await tester.pumpAndSettle();
        expect(top(tester), closeTo(80, 0.5));
        expect(find.byType(PBottomSheetContent), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('p-bottom-sheet-handle')));
        await tester.pumpAndSettle();
        expect(find.byType(PBottomSheetContent), findsNothing);
      });

      testWidgets('입력 폼은 스냅 높이를 쓰지 않는다 — 손잡이가 없다', (tester) async {
        await pumpHost(tester);
        await show<void>(tester, form: true, snaps: const [0.4, 0.9]);
        expect(
          find.byKey(const ValueKey('p-bottom-sheet-handle')),
          findsNothing,
        );
      });

      testWidgets('낮은 높이에서 위로 빠르게 쓸면 다음 높이로 올라간다', (tester) async {
        await pumpHost(tester);
        await show<void>(tester, snaps: const [0.4, 0.9]);
        await tester.pump(const Duration(milliseconds: 600));
        await tester.timedDragFrom(
          const Offset(195, 600),
          const Offset(0, -80),
          const Duration(milliseconds: 80),
        );
        await tester.pumpAndSettle();
        expect(top(tester), closeTo(80, 0.5));
      });
    });

    group('키보드 · 안전 영역', () {
      testWidgets('키보드가 올라오면 시트가 그 위에 서고 높이도 그만큼 줄어든다', (tester) async {
        await pumpHost(tester, keyboard: 300);
        await show<void>(tester, tall: true);
        final sheet = _rect(tester, _root);
        expect(sheet.bottom, 500);
        expect(sheet.height, lessThanOrEqualTo(500));
      });

      testWidgets('홈 표시줄 여백을 바닥 아래에 더한다', (tester) async {
        await pumpHost(tester, safeBottom: 34);
        await show<void>(tester, content: _content());
        final sheet = _rect(tester, _root);
        expect(sheet.bottom, 800);
        expect(
          sheet.bottom - tester.getRect(find.byType(PButton).first).bottom,
          50,
        );
      });
    });

    group('모션', () {
      testWidgets('열림 300ms enter-expressive · 닫힘 200ms exit — 스펙 시간 · 곡선', (
        tester,
      ) async {
        await pumpHost(tester);
        final motion = _spec.json['motion'] as Map<String, dynamic>;
        PBottomSheet.show<void>(ctx, builder: (_) => _content(footer: false));
        await tester.pump();
        await tester.pump();
        final route = ModalRoute.of(
          tester.element(find.byType(PBottomSheetContent)),
        )!;
        expect(route.transitionDuration, specMs(motion['열림 — 시트']['duration']));
        expect(
          route.reverseTransitionDuration,
          specMs(motion['닫힘 — 시트']['duration']),
        );
        expect(
          specMs(motion['열림 — 딤']['duration']),
          const Duration(milliseconds: 300),
        );
        expect(
          specMs(motion['닫힘 — 딤']['duration']),
          const Duration(milliseconds: 200),
        );

        final enter = specCubic(motion['열림 — 시트']['easing']);
        final enterCurve = Cubic(enter[0], enter[1], enter[2], enter[3]);
        final dimEnter = specCubic(motion['열림 — 딤']['easing']);
        final dimCurve = Cubic(
          dimEnter[0],
          dimEnter[1],
          dimEnter[2],
          dimEnter[3],
        );
        final exit = specCubic(motion['닫힘 — 시트']['easing']);
        final exitCurve = Cubic(exit[0], exit[1], exit[2], exit[3]);

        await tester.pumpAndSettle();
        final rest = top(tester);
        final h = _rect(tester, _root).height;
        Navigator.of(ctx).pop();
        await tester.pump();
        // 열림은 이미 끝났다 — 닫힘의 중간(100ms = 절반) 위치
        await tester.pump(const Duration(milliseconds: 100));
        expect(top(tester) - rest, closeTo(h * exitCurve.transform(0.5), 1));
        await tester.pumpAndSettle();

        // 열림 중간(150ms = 절반)
        PBottomSheet.show<void>(ctx, builder: (_) => _content(footer: false));
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));
        expect(
          top(tester) - rest,
          closeTo(h * (1 - enterCurve.transform(0.5)), 1.5),
        );
        final dim = tester
            .widget<Opacity>(
              find.descendant(
                of: find.byType(PDimLayer),
                matching: find.byType(Opacity),
              ),
            )
            .opacity;
        expect(dim, closeTo(dimCurve.transform(0.5), 0.02));
        await tester.pumpAndSettle();
      });

      testWidgets('모션 줄이기 — 미끄러지지 않고 150ms 서서히', (tester) async {
        await pumpHost(tester, reduceMotion: true);
        PBottomSheet.show<void>(ctx, builder: (_) => _content(footer: false));
        await tester.pump();
        await tester.pump();
        final route = ModalRoute.of(
          tester.element(find.byType(PBottomSheetContent)),
        )!;
        expect(route.transitionDuration, const Duration(milliseconds: 150));
        expect(
          route.reverseTransitionDuration,
          const Duration(milliseconds: 150),
        );
        await tester.pump(const Duration(milliseconds: 60));
        final h = _rect(tester, _root);
        // 제자리 — 높이만큼 내려가 있지 않다
        expect(h.bottom, 800);
        await tester.pumpAndSettle();
      });
    });

    testWidgets('읽기 — 이름은 제목, 닫기 버튼은 "닫기", 손잡이는 숨긴다', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpHost(tester);
      await show<void>(tester, snaps: const [0.4, 0.9]);
      expect(find.bySemanticsLabel('기간'), findsOneWidget);
      expect(find.bySemanticsLabel('닫기'), findsOneWidget);
      expect(find.bySemanticsLabel('고른 기간의 거래만 보여요.'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('처음 초점은 시트(컨테이너)이고 라이트 · 다크 모두 그려진다', (tester) async {
      for (final mode in [Brightness.light, Brightness.dark]) {
        await pumpHost(tester, mode: mode);
        await show<void>(tester);
        expect(FocusManager.instance.primaryFocus?.debugLabel, 'PBottomSheet');
        Navigator.of(ctx).pop();
        await tester.pumpAndSettle();
      }
    });
  });
}
