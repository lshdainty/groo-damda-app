// Image Frame · Card Art 가 스펙 값(test/fixtures/design_spec/image-frame.json · card-art.json)대로인지 —
// 비율 여덟 × 모서리 넷 × 맞춤 둘 × 라이트 · 다크의 틀 크기 · 모서리 · 윤곽 · 흰 판, 세 상태(받는 중 · 다 받음 · 없음 · 실패),
// 10초(틀이 화면에 들어온 때부터 · 실패 뒤엔 안 바꿈), 세로 카드 그림 90°, 그림 위 요소(자리 · 둘까지 · 짧은 변 80),
// Indicator, 이름 · 대체 그림이 alt 를 이어받음, 카드 면(크기 셋 · 기관 색 · 글자색 · 모르는 카드사). 웹은 같은 JSON 을 크로미움에서 잰다.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/shared/ds/aspect_ratio/p_aspect_ratio.dart';
import 'package:groo_damda_app/shared/ds/badge/p_badge.dart';
import 'package:groo_damda_app/shared/ds/content_placeholder/p_content_placeholder.dart';
import 'package:groo_damda_app/shared/ds/image_frame/p_card_art.dart';
import 'package:groo_damda_app/shared/ds/image_frame/p_image_frame.dart';
import 'package:groo_damda_app/shared/ds/institution_colors/institution_colors.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';

import '../../support/design_spec.dart';
import '../../support/fake_image.dart';
import '../../support/plain_text.dart';

final _frame = DesignSpec.load('image-frame');
final _card = DesignSpec.load('card-art');

Widget _host(Brightness mode, Widget child, {bool reduceMotion = false}) =>
    MaterialApp(
      theme: mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(800, 600),
          disableAnimations: reduceMotion,
        ),
        child: Scaffold(
          body: Align(alignment: Alignment.topLeft, child: child),
        ),
      ),
    );

/// "W / H" → W ÷ H
double _parse(Object? spec) {
  final p = '$spec'.split('/').map((s) => double.parse(s.trim())).toList();
  return p[0] / p[1];
}

PAspectRatioValue _ratioOf(String id) =>
    PAspectRatioValue.values.firstWhere((v) => v.id == id);

// 모서리 → 그 모서리가 나오는 설정
({double? width, bool bleed}) _forRadius(String radius) => switch (radius) {
  '0' => (width: 120, bleed: true),
  '4' => (width: 24, bleed: false),
  '6' => (width: 40, bleed: false),
  _ => (width: 120, bleed: false),
};

Finder _inFrame(Finder f) =>
    find.descendant(of: find.byType(PImageFrame), matching: f);

Finder _strokeBox() => find.descendant(
  of: find.byType(PImageStroke),
  matching: find.byType(DecoratedBox),
);

void main() {
  setUpAll(() {
    PInstitutionColors.table = PInstitutionTable.fromSpecJson(
      jsonDecode(
            File(
              'test/fixtures/design_spec/institution-colors.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>,
    );
  });
  tearDownAll(() => PInstitutionColors.table = PInstitutionTable.empty);

  test('축 · 기본값이 스펙과 같다', () {
    expect(PAspectRatioValue.values.map((v) => v.id), _frame.axes['ratio']);
    expect(_frame.defaults, {'ratio': '4:3', 'radius': '8', 'fit': 'cover'});
    // 모서리는 폭으로 — 24 이하 4 · 48 이하 6 · 그 위 8, 모르면 8
    expect(imageFrameRadius(24), 4);
    expect(imageFrameRadius(24.5), 6);
    expect(imageFrameRadius(48), 6);
    expect(imageFrameRadius(49), 8);
    expect(imageFrameRadius(null), 8);
    // 틀 하나에 둘까지 · 짧은 변 80
    expect(kImageFrameMaxFloaters, 2);
    expect(kImageFrameFloaterMinSide, 80);
  });

  for (final mode in Brightness.values) {
    testWidgets(
      '${mode.name} — 비율 × 모서리 × 맞춤이 스펙 값이다(틀 · 모서리 · 윤곽 · 흰 판 · 맞춤)',
      (tester) async {
        final picture = await testPicture(tester, 600, 450);
        final failures = <String>[];
        for (final combo in _frame.combos(['ratio', 'radius', 'fit'])) {
          final want = _frame.resolve(combo, 'loaded');
          final cfg = _forRadius(combo['radius']!);
          await tester.pumpWidget(
            _host(
              mode,
              PImageFrame(
                key: UniqueKey(),
                image: FakeImage(picture),
                alt: '',
                ratio: _ratioOf(combo['ratio']!),
                width: cfg.width,
                bleed: cfg.bleed,
                fit: combo['fit'] == 'contain'
                    ? PImageFit.contain
                    : PImageFit.cover,
              ),
            ),
          );
          void check(String what, Object? expected, Object? actual) {
            if (expected != actual) {
              failures.add('$combo $what: 스펙 $expected · 위젯 $actual');
            }
          }

          final size = tester.getSize(find.byType(PImageFrame));
          check('폭', cfg.width, size.width);
          final h = cfg.width! / _parse(want['root.aspectRatio']);
          if ((size.height - h).abs() > 0.01) {
            failures.add('$combo 높이: 스펙 $h · 위젯 ${size.height}');
          }
          final clip = tester.widget<ClipRRect>(
            _inFrame(find.byType(ClipRRect)),
          );
          check(
            '모서리',
            (want['root.radius'] as num).toDouble(),
            (clip.borderRadius as BorderRadius).topLeft.x,
          );
          final stroke =
              tester.widget<DecoratedBox>(_strokeBox()).decoration
                  as BoxDecoration;
          final side = (stroke.border as Border).top;
          check(
            '윤곽 두께',
            (want['stroke.borderWidth'] as num).toDouble(),
            side.width,
          );
          if (!sameColor(
            specColor(pickMode(want['stroke.borderColor'], mode)),
            side.color,
          )) {
            failures.add('$combo 윤곽 색 ${colorHex(side.color)}');
          }
          check(
            '윤곽 모서리',
            (want['root.radius'] as num).toDouble(),
            (stroke.borderRadius as BorderRadius).topLeft.x,
          );
          final image = tester.widget<Image>(_inFrame(find.byType(Image)));
          check(
            '맞춤',
            combo['fit'] == 'contain' ? BoxFit.contain : BoxFit.cover,
            image.fit,
          );
          final plates = _inFrame(find.byType(ColoredBox)).evaluate().where((
            e,
          ) {
            final w = e.widget as ColoredBox;
            return w.color == const Color(0xFFFFFFFF);
          });
          if (combo['fit'] == 'contain') {
            check(
              '흰 판',
              specColor(want['plate.background']),
              const Color(0xFFFFFFFF),
            );
            if (plates.isEmpty) failures.add('$combo 흰 판이 없다');
          } else if (plates.isNotEmpty) {
            failures.add('$combo cover 에 흰 판이 있다');
          }
        }
        expect(failures, isEmpty, reason: failures.join('\n'));
      },
    );

    testWidgets('${mode.name} — 받는 중 · 없음 · 실패가 스펙 값이다(스켈레톤 · 대체 그림)', (
      tester,
    ) async {
      final loading = _frame.resolve({}, 'loading');
      final fallback = _frame.resolve({}, 'fallback');
      // 받는 중 — 같은 모서리의 Skeleton(면 · 반짝임은 Skeleton 규칙), 그림은 보이지 않는다
      final pending = FakeImage();
      await tester.pumpWidget(
        _host(mode, PImageFrame(width: 150, image: pending, alt: '')),
      );
      expect(_inFrame(find.byType(PSkeleton)), findsOneWidget);
      expect(_inFrame(find.byType(Image)), findsNothing);
      final skeletonFace = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(PSkeleton),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect(
        sameColor(
          specColor(pickMode(loading['skeleton.background'], mode)),
          (skeletonFace.decoration as BoxDecoration).color!,
        ),
        isTrue,
      );
      expect(tester.getSize(find.byType(PSkeleton)), const Size(150, 112.5));

      // 없음 — 처음부터 대체 그림
      for (final entry in {
        '그림 없음': PImageFrame(width: 150, alt: ''),
        '실패': PImageFrame(width: 150, image: _failed(), alt: ''),
      }.entries) {
        await tester.pumpWidget(_host(mode, entry.value));
        await tester.pump();
        expect(
          _inFrame(find.byType(PContentPlaceholder)),
          findsOneWidget,
          reason: entry.key,
        );
        expect(_inFrame(find.byType(PSkeleton)), findsNothing);
        expect(_inFrame(find.byType(Image)), findsNothing);
        final face = tester.widget<DecoratedBox>(
          find
              .descendant(
                of: find.byType(PContentPlaceholder),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        expect(
          sameColor(
            specColor(pickMode(fallback['fallback.background'], mode)),
            (face.decoration as BoxDecoration).color!,
          ),
          isTrue,
          reason: entry.key,
        );
        // 틀 높이의 50%
        final icon = tester.widget<Icon>(_inFrame(find.byType(Icon)));
        expect(icon.size, 112.5 * 0.5);
        expect(
          sameColor(
            specColor(pickMode(fallback['fallback.glyphColor'], mode)),
            icon.color!,
          ),
          isTrue,
        );
      }
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('모션 — 그림이 오면 투명도로(150ms · enter), 이미 받은 그림은 그대로 · 모션 줄이기면 바로', (
    tester,
  ) async {
    final m = (_frame.json['motion'] as Map)['그림이 옴'] as Map;
    expect(specMs(m['duration']), PDuration.d3);
    final cubic = specCubic(m['easing']);
    final enter = PEasing.enter as Cubic;
    expect([enter.a, enter.b, enter.c, enter.d], cubic);

    final picture = await testPicture(tester, 600, 450);
    final late = FakeImage();
    await tester.pumpWidget(
      _host(Brightness.light, PImageFrame(width: 150, image: late, alt: '')),
    );
    expect(_inFrame(find.byType(PSkeleton)), findsOneWidget);
    late.emit(picture);
    await tester.pump();
    // 스켈레톤을 걷고 그림이 투명도 0 에서 시작
    expect(_inFrame(find.byType(PSkeleton)), findsNothing);
    double opacity() =>
        tester.widget<Opacity>(_inFrame(find.byType(Opacity))).opacity;
    expect(opacity(), 0);
    await tester.pump(const Duration(milliseconds: 75));
    expect(opacity(), greaterThan(0));
    expect(opacity(), lessThan(1));
    await tester.pump(const Duration(milliseconds: 100));
    expect(opacity(), 1);

    // 붙을 때 이미 받아 둔 그림 — 움직임 없이 그대로
    await tester.pumpWidget(
      _host(
        Brightness.light,
        PImageFrame(width: 150, image: FakeImage(picture), alt: ''),
      ),
    );
    expect(_inFrame(find.byType(PSkeleton)), findsNothing);
    expect(_inFrame(find.byType(Opacity)), findsNothing);
    expect(_inFrame(find.byType(Image)), findsOneWidget);

    // 모션 줄이기 — 늦게 와도 바로
    final late2 = FakeImage();
    await tester.pumpWidget(
      _host(
        Brightness.light,
        PImageFrame(width: 150, image: late2, alt: ''),
        reduceMotion: true,
      ),
    );
    late2.emit(picture);
    await tester.pump();
    expect(_inFrame(find.byType(Opacity)), findsNothing);
    expect(_inFrame(find.byType(Image)), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  group('10초', () {
    testWidgets('화면에 있는 틀 — 10초가 지나면 실패, 그 뒤에 온 그림은 다시 바꾸지 않는다', (
      tester,
    ) async {
      final picture = await testPicture(tester, 600, 450);
      final slow = FakeImage();
      await tester.pumpWidget(
        _host(Brightness.light, PImageFrame(width: 150, image: slow, alt: '')),
      );
      await tester.pump(const Duration(milliseconds: 9900));
      expect(_inFrame(find.byType(PSkeleton)), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
      expect(_inFrame(find.byType(PSkeleton)), findsNothing);
      expect(_inFrame(find.byType(PContentPlaceholder)), findsOneWidget);
      slow.emit(picture);
      await tester.pump(const Duration(seconds: 1));
      expect(_inFrame(find.byType(PContentPlaceholder)), findsOneWidget);
      expect(_inFrame(find.byType(Image)), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('화면 밖 틀 — 들어온 때부터 잰다(아래쪽 그림이 보기도 전에 실패로 바뀌지 않는다)', (
      tester,
    ) async {
      final below = FakeImage();
      final controller = ScrollController();
      await tester.pumpWidget(
        MaterialApp(
          theme: GrooTheme.light(),
          home: MediaQuery(
            data: const MediaQueryData(size: Size(800, 600)),
            child: Scaffold(
              body: SingleChildScrollView(
                controller: controller,
                child: Column(
                  children: [
                    const SizedBox(height: 2000),
                    PImageFrame(width: 150, image: below, alt: ''),
                    const SizedBox(height: 800),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 30));
      expect(find.byType(PSkeleton), findsOneWidget);
      controller.jumpTo(1900);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 9900));
      expect(find.byType(PSkeleton), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(PSkeleton), findsNothing);
      expect(find.byType(PContentPlaceholder), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('10초 안에 오면 타이머가 남지 않는다', (tester) async {
      final picture = await testPicture(tester, 600, 450);
      final ok = FakeImage();
      await tester.pumpWidget(
        _host(Brightness.light, PImageFrame(width: 150, image: ok, alt: '')),
      );
      await tester.pump(const Duration(seconds: 3));
      ok.emit(picture);
      await tester.pump(const Duration(seconds: 20));
      expect(_inFrame(find.byType(Image)), findsOneWidget);
      expect(_inFrame(find.byType(PContentPlaceholder)), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('세로 카드 그림', () {
    Finder rotated() => _inFrame(find.byType(RotatedBox));

    testWidgets('card 비율의 세로 그림만 다 받은 뒤 시계 방향 90° — 그 전엔 돌리지 않는다', (
      tester,
    ) async {
      expect(
        _frame.resolve({'ratio': 'card'}, 'loaded')['image.rotate'],
        '90deg',
      );
      final tall = await testPicture(tester, 540, 856);
      final late = FakeImage();
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PImageFrame(
            ratio: PAspectRatioValue.card,
            width: 150,
            image: late,
            alt: '',
          ),
        ),
      );
      expect(rotated(), findsNothing);
      late.emit(tall);
      await tester.pump();
      final box = tester.widget<RotatedBox>(rotated());
      expect(box.quarterTurns, 1);
      // 틀을 꽉 채운다 — 돌린 그림 상자도 틀 크기다
      expect(
        tester.getSize(rotated()),
        tester.getSize(find.byType(PImageFrame)),
      );
      expect(
        tester.widget<Image>(_inFrame(find.byType(Image))).fit,
        BoxFit.cover,
      );
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('가로 · 정사각 그림은 그대로, 세로 그림도 card 가 아니면 그대로', (tester) async {
      final wide = await testPicture(tester, 856, 540);
      final square = await testPicture(tester, 500, 500);
      final tall = await testPicture(tester, 540, 856);
      for (final (ratio, picture) in [
        (PAspectRatioValue.card, wide),
        (PAspectRatioValue.card, square),
        (PAspectRatioValue.r4x3, tall),
        (PAspectRatioValue.r4x5, tall),
      ]) {
        await tester.pumpWidget(
          _host(
            Brightness.light,
            PImageFrame(
              key: UniqueKey(),
              ratio: ratio,
              width: 150,
              image: FakeImage(picture),
              alt: '',
            ),
          ),
        );
        expect(
          rotated(),
          findsNothing,
          reason: '${ratio.id} ${picture.width}x${picture.height}',
        );
      }
    });
  });

  group('그림 위 요소', () {
    const topStart = PImageFrameFloater(
      placement: PImageFramePlacement.topStart,
      child: PBadge(label: '단종', variant: PBadgeVariant.solid),
    );
    const bottomEnd = PImageFrameFloater(
      placement: PImageFramePlacement.bottomEnd,
      child: PImageFrameIndicator(text: '1 / 12', label: '사진 12장 중 1번째'),
    );
    const topEnd = PImageFrameFloater(
      placement: PImageFramePlacement.topEnd,
      child: PBadge(label: '새것', variant: PBadgeVariant.solid),
    );

    test('자리마다 하나 · 둘까지(앞에서부터) 거른다', () {
      expect(PImageFrame.pickFloaters(const [topStart, bottomEnd, topEnd]), [
        topStart,
        bottomEnd,
      ]);
      const dup = PImageFrameFloater(
        placement: PImageFramePlacement.topStart,
        child: SizedBox(),
      );
      expect(PImageFrame.pickFloaters(const [topStart, dup, topEnd]), [
        topStart,
        topEnd,
      ]);
    });

    testWidgets('짧은 변 160 — 네 모서리에서 6, 누르지 않는다', (tester) async {
      final picture = await testPicture(tester, 600, 450);
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PImageFrame(
            width: 160,
            image: FakeImage(picture),
            alt: '',
            floaters: const [topStart, bottomEnd],
          ),
        ),
      );
      final frame = tester.getRect(find.byType(PImageFrame));
      final badge = tester.getRect(find.byType(PBadge));
      final indicator = tester.getRect(find.byType(PImageFrameIndicator));
      expect(_frame.resolve({}, 'loaded')['floater.offset'], 6);
      expect(badge.topLeft - frame.topLeft, const Offset(6, 6));
      expect(frame.bottomRight - indicator.bottomRight, const Offset(6, 6));
      // 누르지 않는다
      expect(
        find.ancestor(
          of: find.byType(PBadge),
          matching: find.byType(IgnorePointer),
        ),
        findsWidgets,
      );
    });

    testWidgets('짧은 변이 80 보다 작으면 그리지 않는다(경계 80 은 그린다)', (tester) async {
      final picture = await testPicture(tester, 600, 450);
      for (final (w, drawn) in [(56.0, false), (79.0, false), (80.0, true)]) {
        await tester.pumpWidget(
          _host(
            Brightness.light,
            PImageFrame(
              key: UniqueKey(),
              ratio: PAspectRatioValue.r1x1,
              width: w,
              image: FakeImage(picture),
              alt: '',
              floaters: const [topStart],
            ),
          ),
        );
        expect(
          find.byType(PBadge),
          drawn ? findsOneWidget : findsNothing,
          reason: '$w',
        );
      }
      // 긴 변이 아니라 짧은 변 — 가로로 긴 틀(폭 200 · 2:1 = 높이 100)은 그린다, 높이 75(4:3 폭 100)는 안 그린다
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PImageFrame(
            width: 100,
            image: FakeImage(picture),
            alt: '',
            floaters: const [topStart],
          ),
        ),
      );
      expect(find.byType(PBadge), findsNothing);
    });

    for (final mode in Brightness.values) {
      testWidgets(
        '${mode.name} — Indicator 가 스펙 값이다(검정 65% · 흰 11/15 500 · 6 · 2 · 19 · 알약)',
        (tester) async {
          final want = _frame.resolve({}, 'loaded');
          await tester.pumpWidget(
            _host(
              mode,
              const PImageFrameIndicator(text: '1 / 12', label: '사진 12장 중 1번째'),
            ),
          );
          final box =
              tester
                      .widget<DecoratedBox>(
                        find
                            .descendant(
                              of: find.byType(PImageFrameIndicator),
                              matching: find.byType(DecoratedBox),
                            )
                            .first,
                      )
                      .decoration
                  as BoxDecoration;
          // rgba(0, 0, 0, 0.65) — 두 모드 같다
          expect(want['indicator.background'], 'rgba(0, 0, 0, 0.65)');
          expect(box.color!.a, closeTo(0.65, 0.01));
          expect(box.color!.r + box.color!.g + box.color!.b, 0);
          expect(
            (box.borderRadius as BorderRadius).topLeft.x,
            (want['indicator.radius'] as num).toDouble(),
          );
          final text = tester.widget<Text>(findText('1 / 12'));
          final typo = want['indicator.typography'] as Map;
          expect(text.style!.fontSize, (typo['fontSize'] as num).toDouble());
          expect(
            text.style!.height! * text.style!.fontSize!,
            closeTo((typo['lineHeight'] as num).toDouble(), 0.01),
          );
          expect(text.style!.fontWeight, FontWeight.w500);
          expect(
            sameColor(
              specColor(want['indicator.foreground']),
              text.style!.color!,
            ),
            isTrue,
          );
          final pad = tester.widget<Padding>(
            find.descendant(
              of: find.byType(PImageFrameIndicator),
              matching: find.byType(Padding),
            ),
          );
          expect(
            pad.padding,
            EdgeInsets.symmetric(
              horizontal: (want['indicator.paddingX'] as num).toDouble(),
              vertical: (want['indicator.paddingY'] as num).toDouble(),
            ),
          );
          expect(
            tester.getSize(find.byType(PImageFrameIndicator)).height,
            greaterThanOrEqualTo(
              (want['indicator.minHeight'] as num).toDouble(),
            ),
          );
        },
      );
    }

    testWidgets('Indicator — 보이는 글은 숨기고 읽는 글 하나만 읽는다', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const PImageFrameIndicator(text: '1 / 12', label: '사진 12장 중 1번째'),
        ),
      );
      expect(find.bySemanticsLabel('사진 12장 중 1번째'), findsOneWidget);
      expect(find.bySemanticsLabel('1 / 12'), findsNothing);
      semantics.dispose();
    });
  });

  group('이름', () {
    testWidgets('이름 있는 그림은 alt 로 읽고, ""(장식)이면 읽지 않는다', (tester) async {
      final semantics = tester.ensureSemantics();
      final picture = await testPicture(tester, 600, 450);
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PImageFrame(width: 150, image: FakeImage(picture), alt: '제주 바다'),
        ),
      );
      expect(find.bySemanticsLabel('제주 바다'), findsOneWidget);
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PImageFrame(
            key: UniqueKey(),
            width: 150,
            image: FakeImage(picture),
            alt: '',
          ),
        ),
      );
      expect(find.bySemanticsLabel('제주 바다'), findsNothing);
      semantics.dispose();
    });

    testWidgets('대체 그림이 alt 를 이름으로 이어받는다 — 없음 · 실패 모두, 받는 중에는 읽지 않는다', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(Brightness.light, PImageFrame(width: 150, alt: '제주 바다')),
      );
      expect(find.bySemanticsLabel('제주 바다'), findsOneWidget);
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PImageFrame(width: 150, image: _failed(), alt: '제주 바다'),
        ),
      );
      await tester.pump();
      expect(find.bySemanticsLabel('제주 바다'), findsOneWidget);
      await tester.pumpWidget(
        _host(Brightness.light, PImageFrame(width: 150, alt: '')),
      );
      expect(find.bySemanticsLabel('제주 바다'), findsNothing);
      // 받는 중 — 스켈레톤은 읽지 않는다
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PImageFrame(width: 150, image: FakeImage(), alt: ''),
        ),
      );
      expect(_inFrame(find.byType(ExcludeSemantics)), findsWidgets);
      semantics.dispose();
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('Card Art', () {
    Finder issuerText(String s) => find.byWidgetPredicate(
      (w) => w is Text && (w.data ?? '').replaceAll('⁠', '') == s,
    );

    testWidgets('면의 크기는 틀의 폭으로 — 96 미만 첫 글자 · 96 ~ 239 한 줄 · 240 이상 두 줄', (
      tester,
    ) async {
      expect(cardArtSizeFor(95.9), PCardArtSize.small);
      expect(cardArtSizeFor(96), PCardArtSize.medium);
      expect(cardArtSizeFor(239), PCardArtSize.medium);
      expect(cardArtSizeFor(240), PCardArtSize.large);

      final small = _card.resolve({'size': 'small'}, 'enabled');
      final medium = _card.resolve({'size': 'medium'}, 'enabled');
      final large = _card.resolve({'size': 'large'}, 'enabled');

      // small — 회사 첫 글자만, 면 높이의 40%(정수 · 가장 작아도 10)
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const PCardArt(issuer: 'KB국민카드', name: '노리2', width: 44),
        ),
      );
      expect(issuerText('K'), findsOneWidget);
      expect(issuerText('KB국민카드'), findsNothing);
      expect(issuerText('노리2'), findsNothing);
      expect(
        tester.widget<Text>(issuerText('K')).style!.fontSize,
        cardArtInitialSize(44 / 1.586),
      );
      expect(cardArtInitialSize(35.3), 14);
      expect(cardArtInitialSize(42.9), 17);
      expect(cardArtInitialSize(27.7), 11);
      expect(cardArtInitialSize(10), 10);
      expect(small['initial.fontWeight'], 700);
      expect(
        tester.widget<Text>(issuerText('K')).style!.fontWeight,
        FontWeight.w700,
      );

      for (final (w, want, size) in [
        (96.0, medium, PCardArtSize.medium),
        (160.0, medium, PCardArtSize.medium),
        (282.0, large, PCardArtSize.large),
      ]) {
        await tester.pumpWidget(
          _host(
            Brightness.light,
            PCardArt(
              key: UniqueKey(),
              issuer: '신한카드',
              name: '이름이 아주아주 길어서 줄이 넘치는 카드 이름 확인용 카드 이름 확인용',
              width: w,
            ),
          ),
        );
        final issuer = tester.widget<Text>(issuerText('신한카드'));
        final nameText = tester.widget<Text>(
          find.byWidgetPredicate(
            (w) =>
                w is Text &&
                (w.data ?? '').replaceAll('\u2060', '').startsWith('이름이'),
          ),
        );
        for (final (t, key) in [(issuer, 'issuer'), (nameText, 'name')]) {
          final typo = want['$key.typography'] as Map;
          expect(
            t.style!.fontSize,
            (typo['fontSize'] as num).toDouble(),
            reason: '$w $key',
          );
          expect(
            t.style!.height! * t.style!.fontSize!,
            closeTo((typo['lineHeight'] as num).toDouble(), 0.01),
            reason: '$w $key',
          );
        }
        expect(issuer.style!.fontWeight, FontWeight.w500);
        expect(nameText.style!.fontWeight, FontWeight.w700);
        expect(issuer.maxLines, 1);
        expect(issuer.overflow, TextOverflow.ellipsis);
        expect(
          nameText.maxLines,
          (want['name.lineClamp'] as num).toInt(),
          reason: '$w',
        );
        expect(nameText.overflow, TextOverflow.ellipsis);
        // 안쪽 여백 — 좌우 · 아래
        final pad = tester.widget<Padding>(
          find
              .ancestor(of: issuerText('신한카드'), matching: find.byType(Padding))
              .first,
        );
        expect(
          pad.padding,
          EdgeInsets.fromLTRB(
            (want['label.paddingX'] as num).toDouble(),
            0,
            (want['label.paddingX'] as num).toDouble(),
            (want['label.paddingBottom'] as num).toDouble(),
          ),
          reason: '$size',
        );
      }
      await tester.pumpWidget(const SizedBox());
    });

    for (final mode in Brightness.values) {
      testWidgets('${mode.name} — 아는 카드사는 기관 색 한 색 · 표의 글자색, 모든 기관이 4.5 이상', (
        tester,
      ) async {
        final entries = PInstitutionColors.table.entries;
        expect(entries, hasLength(78));
        final c = mode == Brightness.dark ? PColors.dark : PColors.light;
        final failures = <String>[];
        // 면이 모드를 따르지 않으므로 글자는 라이트 fg-neutral · 다크 fg-neutral-inverted(둘 다 짙다)
        for (final e in entries) {
          await tester.pumpWidget(
            _host(
              mode,
              PCardArt(
                key: UniqueKey(),
                issuer: e.name,
                name: '카드',
                width: 160,
              ),
            ),
          );
          final face = tester.widget<ColoredBox>(
            find
                .descendant(
                  of: find.byType(PCardFace),
                  matching: find.byType(ColoredBox),
                )
                .first,
          );
          if (face.color != e.color) failures.add('${e.name} 면 색');
          final text = tester.widget<Text>(issuerText(e.name.trim()));
          final want = e.text == PInstitutionText.white
              ? c.staticWhite
              : (mode == Brightness.dark ? c.fgNeutralInverted : c.fgNeutral);
          if (text.style!.color != want) failures.add('${e.name} 글자 색');
          final ratio = _contrast(e.color, text.style!.color!);
          if (ratio < 4.5)
            failures.add('${e.name} 대비 ${ratio.toStringAsFixed(2)}');
        }
        expect(failures, isEmpty, reason: failures.join('\n'));
      });
    }

    testWidgets('모르는 카드사는 대체 그림(credit-card) — 브랜드 색 면이 없다', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const PCardArt(issuer: '어떤카드사', name: '이름 모르는 카드', width: 160),
        ),
      );
      expect(find.byType(PCardFace), findsNothing);
      expect(find.byType(PContentPlaceholder), findsOneWidget);
      expect(tester.widget<Icon>(find.byType(Icon)).icon!.codePoint, isNotNull);
      expect(
        tester.getSize(find.byType(PCardArt)).aspectRatio,
        closeTo(1.586, 0.001),
      );
    });

    testWidgets('그림이 실패하면 카드 면, 그림이 오면 그림 — 세로는 90°', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PCardArt(
            issuer: '롯데카드',
            name: 'LOCA 365',
            width: 160,
            image: _failed(),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(PCardFace), findsOneWidget);
      final tall = await testPicture(tester, 540, 856);
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PCardArt(
            key: UniqueKey(),
            issuer: '롯데카드',
            name: 'LOCA 365',
            width: 160,
            image: FakeImage(tall),
          ),
        ),
      );
      expect(find.byType(PCardFace), findsNothing);
      expect(find.byType(RotatedBox), findsOneWidget);
    });

    testWidgets('decorative 기본은 숨김, false 면 "카드사 카드이름" 을 읽고 면의 글은 따로 읽지 않는다', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const PCardArt(issuer: '우리카드', name: '카드의정석', width: 160),
        ),
      );
      expect(find.bySemanticsLabel('우리카드 카드의정석'), findsNothing);
      expect(find.bySemanticsLabel('우리카드'), findsNothing);
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PCardArt(
            key: UniqueKey(),
            issuer: '우리카드',
            name: '카드의정석',
            width: 160,
            decorative: false,
          ),
        ),
      );
      expect(find.bySemanticsLabel('우리카드 카드의정석'), findsOneWidget);
      expect(find.bySemanticsLabel('우리카드'), findsNothing);
      semantics.dispose();
    });

    test('keepWords — 단어 안에는 U+2060, 공백 자리는 그대로', () {
      expect(keepWords('올원 카드'), '올⁠원 카⁠드');
      expect(keepWords('A'), 'A');
    });
  });
}

FakeImage _failed() => FakeImage.failing();

double _lum(Color c) {
  double ch(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

double _contrast(Color a, Color b) {
  final hi = math.max(_lum(a), _lum(b));
  final lo = math.min(_lum(a), _lum(b));
  return (hi + 0.05) / (lo + 0.05);
}
