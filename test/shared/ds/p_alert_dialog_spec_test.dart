// Alert Dialog 가 스펙 값(test/fixtures/design_spec/alert-dialog.json)대로 그려지는지 — 배치 × 라이트 · 다크를 모두 돈다.
// 웹은 같은 JSON 을 크로미움에서 잰다(desk-front `npm run ds:check`).
//
// 앱에 없는 상태(웹의 focused — 키보드 포커스 링)는 재지 않는다. 문장으로 된 값은 그린 결과나 동작으로 본다 —
// 그림자 없음은 그려진 장식으로, 열림 · 닫힘 시간 · 곡선은 흐르는 시간으로, z-index(300 · 301)는 라우트가 쌓이는 차례
// (시트 위에 뜬다)로 잰다. 동작(바깥 무시 · Esc · 뒤로 가기 · 처음 초점 · 확정 기다리기)은 아래 동작 group 이 본다.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/overlay/p_overlay.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';

import '../../support/design_spec.dart';
import '../../support/plain_text.dart';

final _spec = DesignSpec.load('alert-dialog');

PColors _colors(Brightness mode) =>
    mode == Brightness.dark ? PColors.dark : PColors.light;

ThemeData _theme(Brightness mode) =>
    mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light();

// 배치마다 글 — 한쪽 글이 반 폭을 넘으면 세로, 알리기는 하나
const _copy = {
  'horizontal': (
    title: '거래를 삭제할까요?',
    description: '삭제한 거래는 되돌릴 수 없어요.',
    cancel: '취소',
    action: '삭제',
  ),
  'vertical': (
    title: '작성한 내용이 사라져요',
    description: '나가면 입력한 금액과 날짜가 저장되지 않아요.',
    cancel: '계속 작성하기',
    action: '저장하지 않고 나가기',
  ),
  'single': (
    title: '이미 정산된 거래예요',
    description: '정산이 끝난 거래는 수정할 수 없어요.',
    cancel: null,
    action: '거래 보기',
  ),
};

void _viewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _app(Brightness mode, Widget home) => MaterialApp(
  theme: _theme(mode),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('ko'),
  home: home,
);

PAlertDialogView _view(String layout, {bool focus = false}) {
  final c = _copy[layout]!;
  return PAlertDialogView(
    title: c.title,
    description: c.description,
    cancelLabel: c.cancel,
    actionLabel: c.action,
    destructive: layout != 'single',
    requestFocus: focus,
    onCancel: () {},
  );
}

Finder _card(PColors colors) => find.byWidgetPredicate(
  (w) =>
      w is DecoratedBox &&
      w.decoration is BoxDecoration &&
      (w.decoration as BoxDecoration).color == colors.bgLayerFloating &&
      (w.decoration as BoxDecoration).borderRadius != null,
);

/// 스펙의 글자 — {fontSize, lineHeight} · 굵기.
void _expectText(
  Finder finder,
  WidgetTester tester,
  Object? typography,
  Object? weight,
) {
  final style = tester.widget<Text>(finder).style!;
  final t = typography! as Map<String, dynamic>;
  expect(style.fontSize, (t['fontSize'] as num).toDouble());
  expect(
    style.fontSize! * style.height!,
    closeTo((t['lineHeight'] as num).toDouble(), 0.01),
  );
  expect(style.fontWeight, FontWeight.values[(weight! as int) ~/ 100 - 1]);
}

void main() {
  for (final mode in [Brightness.light, Brightness.dark]) {
    for (final combo in _spec.combos(['layout'])) {
      final layout = combo['layout']!;
      testWidgets('$layout · ${mode.name} — 확인창이 스펙 값이다', (tester) async {
        _viewport(tester, const Size(390, 800));
        final want = _spec.resolve(combo, 'enabled');
        final copy = _copy[layout]!;
        await tester.pumpWidget(_app(mode, Scaffold(body: _view(layout))));
        final colors = _colors(mode);

        // 확인창 — 최대 272, 좌우 32 를 남긴다(390 에서는 272 로 선다)
        final card = _card(colors);
        expect(card, findsOneWidget);
        final rect = tester.getRect(card);
        expect(rect.width, (want['root.maxWidth'] as num).toDouble());
        expect(rect.center.dx, 195); // 가운데
        final decoration =
            tester.widget<DecoratedBox>(card).decoration as BoxDecoration;
        expect(
          decoration.borderRadius,
          BorderRadius.circular((want['root.radius'] as num).toDouble()),
        );
        expect(
          sameColor(
            specColor(pickMode(want['root.background'], mode)),
            decoration.color!,
          ),
          isTrue,
        );
        // 그림자 없이 딤과 표면 색으로 뜬다
        expect(want['root.shadow'], 'none');
        expect(decoration.boxShadow, isNull);

        // 안쪽 20
        final padding = want['root.padding'] as num;
        final title = findText(keepAll(copy.title));
        final description = findText(keepAll(copy.description));
        expect(
          tester.getTopLeft(title) - rect.topLeft,
          Offset(padding.toDouble(), padding.toDouble()),
        );
        expect(tester.getTopRight(title).dx, rect.right - padding);

        // 제목 20 / 27 · 700 · fg-neutral
        _expectText(
          title,
          tester,
          want['title.typography'],
          want['title.fontWeight'],
        );
        expect(
          sameColor(
            specColor(pickMode(want['title.foreground'], mode)),
            tester.widget<Text>(title).style!.color!,
          ),
          isTrue,
        );
        // 설명 16 / 22 · 짙은 fg-neutral, 제목 아래 6
        _expectText(
          description,
          tester,
          want['description.typography'],
          want['description.fontWeight'],
        );
        expect(
          sameColor(
            specColor(pickMode(want['description.foreground'], mode)),
            tester.widget<Text>(description).style!.color!,
          ),
          isTrue,
        );
        expect(
          tester.getTopLeft(description).dy - tester.getBottomLeft(title).dy,
          (want['description.marginTop'] as num).toDouble(),
        );

        // 바닥 — 설명 아래 16, 버튼 사이 8, Button medium 40
        final buttons = find.byType(PButton);
        final first = tester.getRect(buttons.first);
        expect(
          first.top - tester.getBottomLeft(description).dy,
          (want['footer.paddingTop'] as num).toDouble(),
        );
        expect(want['footer.buttonSize'], contains('medium 40'));
        for (final button in tester.widgetList<PButton>(buttons)) {
          expect(button.size, PButtonSize.medium);
        }
        for (final e in buttons.evaluate()) {
          expect(tester.getSize(find.byWidget(e.widget)).height, 40);
        }
        expect(rect.bottom - tester.getRect(buttons.last).bottom, padding);

        // 취소는 neutralWeak, 확정은 지우면 criticalSolid · 아니면 neutralSolid
        final action = tester
            .widgetList<PButton>(buttons)
            .firstWhere((b) => b.label == copy.action);
        expect(
          action.variant,
          layout == 'single'
              ? PButtonVariant.neutralSolid
              : PButtonVariant.criticalSolid,
        );
        if (copy.cancel != null) {
          expect(
            tester
                .widgetList<PButton>(buttons)
                .firstWhere((b) => b.label == copy.cancel)
                .variant,
            PButtonVariant.neutralWeak,
          );
        }

        // 배치
        final direction = want['footer.direction'];
        final cancelRect = copy.cancel == null
            ? null
            : tester.getRect(findWidgetWithText(PButton, copy.cancel!));
        final actionRect = tester.getRect(
          findWidgetWithText(PButton, copy.action),
        );
        final inner = rect.width - 2 * padding;
        if (layout == 'single') {
          expect(buttons, findsOneWidget);
          expect(actionRect.width, inner);
        } else if (direction == 'row') {
          // 나란히 — 취소 왼쪽 · 확정 오른쪽, 반씩 사이 8
          final gap = (want['footer.gap'] as num).toDouble();
          expect(cancelRect!.right + gap, actionRect.left);
          expect(cancelRect.width, actionRect.width);
          expect(cancelRect.width * 2 + gap, inner);
        } else {
          // 세로 — 확정이 위, 둘 다 폭 전체
          expect(direction, 'column');
          expect(
            actionRect.bottom + (want['footer.gap'] as num),
            cancelRect!.top,
          );
          expect(actionRect.width, inner);
          expect(cancelRect.width, inner);
        }
      });
    }
  }

  testWidgets('화면이 336 보다 좁으면 화면 폭 − 64 로 선다', (tester) async {
    _viewport(tester, const Size(300, 800));
    await tester.pumpWidget(
      _app(Brightness.light, Scaffold(body: _view('horizontal'))),
    );
    expect(tester.getSize(_card(PColors.light)).width, 300 - 64);
  });

  testWidgets('배치는 짝 버튼 부품이 정한다 — 한 라벨이 반 폭을 넘으면 세로, 버튼 하나는 single', (
    tester,
  ) async {
    _viewport(tester, const Size(390, 800));
    for (final (layout, row, column) in [
      ('horizontal', true, false),
      ('vertical', false, true),
      ('single', false, false),
    ]) {
      await tester.pumpWidget(
        _app(Brightness.light, Scaffold(body: _view(layout))),
      );
      expect(
        find.byKey(const ValueKey('pair-row')),
        row ? findsOneWidget : findsNothing,
        reason: layout,
      );
      expect(
        find.byKey(const ValueKey('pair-column')),
        column ? findsOneWidget : findsNothing,
        reason: layout,
      );
    }
    // 세로면 확정이 위
    await tester.pumpWidget(
      _app(Brightness.light, Scaffold(body: _view('vertical'))),
    );
    expect(
      tester.getTopLeft(findText('저장하지 않고 나가기')).dy,
      lessThan(tester.getTopLeft(findText('계속 작성하기')).dy),
    );
  });

  testWidgets('360 × 640 · 글자 200% · 긴 설명 — 높이는 안전 영역 안이고 확인 버튼까지 스크롤로 닿는다', (
    tester,
  ) async {
    _viewport(tester, const Size(360, 640));
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
    addTearDown(tester.view.resetPadding);
    await tester.pumpWidget(
      MaterialApp(
        theme: _theme(Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: PAlertDialogView(
            title: '이 가계부를 삭제할까요?',
            description: List.filled(
              8,
              '삭제하면 이 가계부의 거래 · 예산 · 반복 설정이 모두 사라지고 되돌릴 수 없어요.',
            ).join(' '),
            cancelLabel: '취소',
            actionLabel: '삭제',
            destructive: true,
            onCancel: () {},
            onAction: () {},
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final card = _card(PColors.light);
    final rect = tester.getRect(card);
    expect(rect.height, lessThanOrEqualTo(640 - 48));
    expect(rect.top, greaterThanOrEqualTo(24));
    expect(rect.bottom, lessThanOrEqualTo(640 - 24));
    // 처음엔 버튼이 카드 밖(스크롤 안)에 있다 → 스크롤하면 닿는다
    final scrollable = find.descendant(
      of: card,
      matching: find.byType(Scrollable),
    );
    expect(scrollable, findsOneWidget);
    await tester.scrollUntilVisible(
      findText('삭제'),
      200,
      scrollable: scrollable,
    );
    expect(
      tester.getRect(findText('삭제')).bottom,
      lessThanOrEqualTo(rect.bottom),
    );
  });

  testWidgets('제목이 없으면 설명이 맨 위이고 제목 아래 6 이 없다 · 이름은 semanticLabel', (
    tester,
  ) async {
    _viewport(tester, const Size(390, 800));
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        Brightness.light,
        const Scaffold(
          body: PAlertDialogView(
            semanticLabel: '거래를 삭제할까요?',
            description: '삭제한 거래는 되돌릴 수 없어요.',
            cancelLabel: '취소',
            actionLabel: '삭제',
          ),
        ),
      ),
    );
    final card = tester.getRect(_card(PColors.light));
    final description = findText(keepAll('삭제한 거래는 되돌릴 수 없어요.'));
    expect(tester.getTopLeft(description) - card.topLeft, const Offset(20, 20));
    expect(tester.getSemantics(find.byType(PAlertDialogView).first), isNotNull);
    expect(find.bySemanticsLabel('거래를 삭제할까요?'), findsOneWidget);
    handle.dispose();
  });

  group('동작', () {
    Future<void> open(
      WidgetTester tester,
      Brightness mode,
      void Function(Future<bool>) onResult, {
      String layout = 'horizontal',
      Future<void> Function()? onAction,
    }) async {
      _viewport(tester, const Size(390, 800));
      late BuildContext ctx;
      await tester.pumpWidget(
        _app(
          mode,
          Scaffold(
            body: Builder(
              builder: (context) {
                ctx = context;
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      );
      final c = _copy[layout]!;
      onResult(
        PAlertDialog.show(
          ctx,
          title: c.title,
          description: c.description,
          cancelLabel: c.cancel,
          actionLabel: c.action,
          destructive: true,
          onAction: onAction,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
    }

    for (final mode in [Brightness.light, Brightness.dark]) {
      testWidgets('${mode.name} — 확정은 true 로 닫고 취소는 false 로 닫는다', (
        tester,
      ) async {
        bool? result;
        await open(tester, mode, (f) => f.then((v) => result = v));
        expect(find.byType(PAlertDialogView), findsOneWidget);
        await tester.tap(findWidgetWithText(PButton, '삭제'));
        await tester.pumpAndSettle();
        expect(result, isTrue);
        expect(find.byType(PAlertDialogView), findsNothing);

        result = null;
        await open(tester, mode, (f) => f.then((v) => result = v));
        await tester.tap(findWidgetWithText(PButton, '취소'));
        await tester.pumpAndSettle();
        expect(result, isFalse);
      });
    }

    testWidgets('바깥(딤)을 눌러도 닫히지 않는다', (tester) async {
      bool? result;
      await open(tester, Brightness.light, (f) => f.then((v) => result = v));
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.byType(PAlertDialogView), findsOneWidget);
      expect(result, isNull);
      // 닫기 버튼이 없다 — 버튼은 취소 · 확정 둘뿐
      expect(find.byType(PButton), findsNWidgets(2));
    });

    testWidgets('Esc 는 취소와 같다', (tester) async {
      bool? result;
      await open(tester, Brightness.light, (f) => f.then((v) => result = v));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(result, isFalse);
      expect(find.byType(PAlertDialogView), findsNothing);
    });

    testWidgets('뒤로 가기는 취소와 같다', (tester) async {
      bool? result;
      await open(tester, Brightness.light, (f) => f.then((v) => result = v));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(result, isFalse);
      expect(find.byType(PAlertDialogView), findsNothing);
    });

    testWidgets('처음 초점은 확인창(컨테이너)이다 — 버튼이 아니다', (tester) async {
      await open(tester, Brightness.light, (_) {});
      final focus = FocusManager.instance.primaryFocus;
      expect(focus?.debugLabel, 'PAlertDialog');
      final inside = find.descendant(
        of: find.byType(PButton),
        matching: find.byType(Focus),
      );
      for (final e in inside.evaluate()) {
        expect((e.widget as Focus).focusNode, isNot(focus));
      }
    });

    testWidgets('확정이 끝날 때까지 로딩이고 닫지 않는다 — 두 번 눌러도 한 번이다', (tester) async {
      final done = Completer<void>();
      var calls = 0;
      bool? result;
      await open(
        tester,
        Brightness.light,
        (f) => f.then((v) => result = v),
        onAction: () {
          calls += 1;
          return done.future;
        },
      );
      await tester.tap(findWidgetWithText(PButton, '삭제'));
      await tester.pump();
      expect(
        tester.widget<PButton>(findWidgetWithText(PButton, '삭제')).loading,
        isTrue,
      );
      await tester.tap(findWidgetWithText(PButton, '삭제'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(PAlertDialogView), findsOneWidget);
      expect(result, isNull);
      expect(calls, 1);
      done.complete();
      await tester.pumpAndSettle();
      expect(result, isTrue);
      expect(find.byType(PAlertDialogView), findsNothing);
    });

    testWidgets('읽기 — 알림 대화상자, 이름은 제목, 버튼은 이름이 있다', (tester) async {
      final handle = tester.ensureSemantics();
      await open(tester, Brightness.light, (_) {});
      final node = tester.getSemantics(
        find.descendant(
          of: find.byType(PAlertDialogView),
          matching: find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.namesRoute == true,
          ),
        ),
      );
      expect(node.label, '거래를 삭제할까요?');
      expect(node.flagsCollection.scopesRoute, isTrue);
      expect(find.bySemanticsLabel('삭제'), findsOneWidget);
      expect(find.bySemanticsLabel('취소'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('모션 — 열림 200ms 크게 나타나며 줄어들고 딤은 100ms, 닫힘 100ms', (
      tester,
    ) async {
      _viewport(tester, const Size(390, 800));
      late BuildContext ctx;
      await tester.pumpWidget(
        _app(
          Brightness.light,
          Scaffold(
            body: Builder(
              builder: (c) {
                ctx = c;
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      );
      PAlertDialog.show(
        ctx,
        title: '제목',
        description: '설명',
        cancelLabel: '취소',
        actionLabel: '삭제',
      );
      await tester.pump();
      await tester.pump();
      final route = ModalRoute.of(
        tester.element(find.byType(PAlertDialogView)),
      )!;
      expect(
        route.transitionDuration,
        specMs(_spec.json['motion']['열림 — 확인창']['duration']),
      );
      expect(
        route.reverseTransitionDuration,
        specMs(_spec.json['motion']['닫힘 — 확인창']['duration']),
      );
      expect(
        specMs(_spec.json['motion']['열림 — 딤']['duration']),
        const Duration(milliseconds: 100),
      );

      double dim() => tester
          .widget<Opacity>(
            find.descendant(
              of: find.byType(PDimLayer),
              matching: find.byType(Opacity),
            ),
          )
          .opacity;
      double cardOpacity() => tester
          .widget<FadeTransition>(
            find
                .ancestor(
                  of: find.byType(PAlertDialogView),
                  matching: find.byType(FadeTransition),
                )
                .first,
          )
          .opacity
          .value;
      double scale() => tester
          .widget<Transform>(
            find
                .ancestor(
                  of: find.byType(PAlertDialogView),
                  matching: find.byType(Transform),
                )
                .first,
          )
          .transform
          .getMaxScaleOnAxis();

      final enter = specCubic(_spec.json['motion']['열림 — 확인창']['easing']);
      final curve = Cubic(enter[0], enter[1], enter[2], enter[3]);
      // 열림 직후 — 확인창은 1.3 배, 딤은 아직
      await tester.pump(const Duration(milliseconds: 50));
      final t = curve.transform(0.25);
      expect(cardOpacity(), closeTo(t, 0.01));
      expect(scale(), closeTo(1.3 - 0.3 * t, 0.01));
      // 100ms — 딤은 다 나타났고 확인창은 아직 줄어드는 중
      await tester.pump(const Duration(milliseconds: 50));
      expect(dim(), closeTo(1, 0.001));
      expect(scale(), greaterThan(1.0));
      await tester.pump(const Duration(milliseconds: 100));
      expect(scale(), closeTo(1, 0.001));
      expect(cardOpacity(), closeTo(1, 0.001));

      // 닫힘 — 100ms 에 사라지고 줄지 않는다
      Navigator.of(ctx).pop(false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(scale(), 1);
      expect(cardOpacity(), lessThan(1));
      await tester.pump(const Duration(milliseconds: 60));
      expect(find.byType(PAlertDialogView), findsNothing);
    });

    testWidgets('모션 줄이기 — 150ms 서서히 나타나고 줄어들지 않는다', (tester) async {
      _viewport(tester, const Size(390, 800));
      late BuildContext ctx;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 800),
            disableAnimations: true,
          ),
          child: _app(
            Brightness.light,
            Scaffold(
              body: Builder(
                builder: (c) {
                  ctx = c;
                  return const SizedBox.expand();
                },
              ),
            ),
          ),
        ),
      );
      PAlertDialog.show(ctx, title: '제목', description: '설명', actionLabel: '확인');
      await tester.pump();
      await tester.pump();
      final route = ModalRoute.of(
        tester.element(find.byType(PAlertDialogView)),
      )!;
      expect(route.transitionDuration, const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 50));
      expect(
        tester
            .widget<Transform>(
              find
                  .ancestor(
                    of: find.byType(PAlertDialogView),
                    matching: find.byType(Transform),
                  )
                  .first,
            )
            .transform
            .getMaxScaleOnAxis(),
        1,
      );
      await tester.pumpAndSettle();
    });

    testWidgets('딤은 라이트 0.50 · 다크 0.65 이고 시트 위에서도 그 위에 뜬다', (tester) async {
      for (final mode in [Brightness.light, Brightness.dark]) {
        _viewport(tester, const Size(390, 800));
        late BuildContext ctx;
        await tester.pumpWidget(
          _app(
            mode,
            Scaffold(
              body: Builder(
                builder: (c) {
                  ctx = c;
                  return const SizedBox.expand();
                },
              ),
            ),
          ),
        );
        PBottomSheet.show<void>(
          ctx,
          builder: (_) => PBottomSheetContent(
            title: '시트',
            closeLabel: '닫기',
            body: const Text('본문'),
          ),
        );
        await tester.pumpAndSettle();
        PAlertDialog.show(
          ctx,
          title: '제목',
          description: '설명',
          actionLabel: '확인',
        );
        await tester.pumpAndSettle();
        final dims = find.byType(PDimLayer);
        expect(dims, findsNWidgets(2));
        final want = _spec.resolve({
          'layout': 'horizontal',
        }, 'enabled')['overlay.background'];
        final color = tester
            .widget<ColoredBox>(
              find.descendant(of: dims.last, matching: find.byType(ColoredBox)),
            )
            .color;
        expect(
          sameColor(specColor(_rgbaToHex(pickMode(want, mode))), color),
          isTrue,
        );
        // 확인창이 시트보다 위(나중에 연 라우트)
        expect(
          tester.getRect(find.byType(PAlertDialogView)).center.dy,
          lessThan(tester.getRect(find.byType(PBottomSheetContent)).bottom),
        );
        Navigator.of(ctx).pop();
        await tester.pumpAndSettle();
        Navigator.of(ctx).pop();
        await tester.pumpAndSettle();
      }
    });
  });
}

String _rgbaToHex(Object? v) {
  // "rgba(0, 0, 0, 0.50)" → #000000 + 알파
  final m = RegExp(r'rgba\((\d+), (\d+), (\d+), ([\d.]+)\)').firstMatch('$v')!;
  String h(int n) => n.toRadixString(16).padLeft(2, '0');
  final a = (double.parse(m.group(4)!) * 255).round();
  return '#${h(int.parse(m.group(1)!))}${h(int.parse(m.group(2)!))}${h(int.parse(m.group(3)!))}${h(a)}';
}
