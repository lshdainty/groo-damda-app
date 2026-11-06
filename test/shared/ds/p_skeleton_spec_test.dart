// Skeleton 이 스펙 값(test/fixtures/design_spec/skeleton.json)대로인지 — 모서리 × 라이트 · 다크의 면 · 띠, 한 박자로
// 지나는 띠, 모션 줄이기, 그리고 기다리는 영역의 시간표(1초 · 5초) · 상태 글. 웹은 같은 JSON 을 크로미움에서 잰다.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/progress_circle/p_progress_circle.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';

import '../../support/design_spec.dart';
import '../../support/plain_text.dart';

final _spec = DesignSpec.load('skeleton');

// supportsAnnounce — 플랫폼이 알림(SemanticsService.sendAnnouncement)을 받는지. 받지 않으면(안드로이드 등) 상태 글은
// 라이브 영역으로 읽힌다
Widget _host(
  Brightness mode,
  Widget child, {
  bool reduceMotion = false,
  bool supportsAnnounce = true,
}) => MaterialApp(
  theme: mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('ko'),
  home: MediaQuery(
    data: MediaQueryData(
      disableAnimations: reduceMotion,
      supportsAnnounce: supportsAnnounce,
    ),
    child: Scaffold(body: Center(child: child)),
  ),
);

PSkeletonShimmerPainter? _shimmer(WidgetTester tester, [int index = 0]) {
  final paints = find.byWidgetPredicate(
    (w) => w is CustomPaint && w.painter is PSkeletonShimmerPainter,
  );
  if (paints.evaluate().length <= index) return null;
  return tester.widget<CustomPaint>(paints.at(index)).painter!
      as PSkeletonShimmerPainter;
}

void main() {
  for (final mode in Brightness.values) {
    testWidgets('${mode.name} — 모서리마다 면 · 띠가 스펙 값이다', (tester) async {
      final failures = <String>[];
      for (final combo in _spec.combos(['radius'])) {
        final radius = PSkeletonRadius.values.byName(
          'r${combo['radius']}'.replaceFirst('rfull', 'full'),
        );
        await tester.pumpWidget(
          _host(
            mode,
            PSkeleton(key: UniqueKey(), width: 120, height: 40, radius: radius),
          ),
        );
        final want = _spec.resolve(combo, 'enabled');
        final where = '${mode.name} $combo';

        final clip = tester.widget<ClipRRect>(find.byType(ClipRRect));
        final r = (clip.borderRadius as BorderRadius).topLeft.x;
        if (r != want['root.radius']) {
          failures.add(
            '$where — root.radius: 스펙 ${want['root.radius']} · 실제 $r',
          );
        }
        final face = tester.widget<DecoratedBox>(
          find.descendant(
            of: find.byType(PSkeleton),
            matching: find.byType(DecoratedBox),
          ),
        );
        final bg = (face.decoration as BoxDecoration).color!;
        final wantBg = pickMode(want['root.background'], mode);
        if (!sameColor(specColor(wantBg), bg)) {
          failures.add(
            '$where — root.background: 스펙 $wantBg · 실제 ${colorHex(bg)}',
          );
        }
        final band = _shimmer(tester)!.band;
        final wantBand = specGradient(
          pickMode(want['shimmer.background'], mode),
        );
        for (var i = 0; i < wantBand.colors.length; i++) {
          if (!sameColor(wantBand.colors[i], band.colors[i]) ||
              (wantBand.stops[i] - band.stops![i]).abs() > 1e-6) {
            failures.add('$where — shimmer.background $i 번째 색 · 비율이 다르다');
          }
        }
        // 띠는 가로로 지난다(90deg)
        if (band.begin != Alignment.centerLeft ||
            band.end != Alignment.centerRight) {
          failures.add('$where — 띠의 방향이 왼쪽 → 오른쪽이 아니다');
        }
      }
      if (failures.isNotEmpty) fail(failures.join('\n'));
    });
  }

  testWidgets('글 자리의 높이는 그 글자의 줄 높이다 — t4 14 → 19', (tester) async {
    await tester.pumpWidget(
      _host(Brightness.light, PSkeleton.text(PTypography.t4, width: 80)),
    );
    expect(tester.getSize(find.byType(PSkeleton)), const Size(80, 19));
  });

  testWidgets('띠는 1.5초 박자 · easing 으로 왼쪽 밖에서 오른쪽 밖으로 지나고, 늦게 붙은 띠도 같은 자리다', (
    tester,
  ) async {
    final motion = (_spec.json['motion'] as Map)['반짝임'] as Map;
    expect(PDuration.loop, specMs(motion['duration']));
    final cubic = specCubic(motion['easing']);
    final easing = PEasing.easing as Cubic;
    expect([easing.a, easing.b, easing.c, easing.d], cubic);

    final late = ValueNotifier(false);
    await tester.pumpWidget(
      _host(
        Brightness.light,
        ValueListenableBuilder(
          valueListenable: late,
          builder: (context, show, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PSkeleton(width: 100, height: 20),
              if (show) const PSkeleton(width: 100, height: 20),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    late.value = true;
    await tester.pump(const Duration(milliseconds: 300));
    final a = _shimmer(tester, 0)!.offset;
    final b = _shimmer(tester, 1)!.offset;
    expect(a, closeTo(b, 1e-9));
    expect(a, inInclusiveRange(-1, 1));
    // 한 바퀴 동안 −1 근처 → 1 근처로 간다
    final seen = <double>[];
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      seen.add(_shimmer(tester)!.offset);
    }
    expect(seen.reduce((x, y) => x < y ? x : y), lessThan(-0.9));
    expect(seen.reduce((x, y) => x > y ? x : y), greaterThan(0.9));
  });

  testWidgets('모션 줄이기면 띠가 없다 — 면만 남는다', (tester) async {
    final want = _spec.resolve({'radius': '8'}, 'reducedMotion');
    expect(want['shimmer.opacity'], 0);
    await tester.pumpWidget(
      _host(
        Brightness.light,
        const PSkeleton(width: 100, height: 20),
        reduceMotion: true,
      ),
    );
    expect(_shimmer(tester), isNull);
    expect(find.byType(DecoratedBox), findsWidgets);
  });

  testWidgets('스켈레톤은 읽지 않는다', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(Brightness.light, const PSkeleton(width: 100, height: 20)),
    );
    expect(
      find.descendant(
        of: find.byType(PSkeleton),
        matching: find.byType(ExcludeSemantics),
      ),
      findsWidgets,
    );
    semantics.dispose();
  });

  group('기다리는 영역', () {
    final region = _spec.resolve({}, 'enabled');

    test('시간표가 스펙 값이다', () {
      expect(PLoadingTiming.showAfter, specMs(region['region.showAfter']));
      expect(PLoadingTiming.slowAfter, specMs(region['region.slowAfter']));
      expect(PLoadingTiming.timeout, specMs(region['region.timeout']));
      // "2번" — 1초 · 2초 뒤
      expect(
        PLoadingTiming.retryDelays.length,
        int.parse('${region['region.retry']}'.replaceAll(RegExp(r'\D'), '')),
      );
    });

    Widget skeletonRegion({required bool pending, bool failed = false}) =>
        PLoadingRegion(
          pending: pending,
          failed: failed,
          fallback: const PSkeleton(width: 200, height: 19),
          failure: const Text('실패'),
          child: const Text('내용'),
        );

    testWidgets('1초까지는 보이지 않게(높이는 지킨다), 1초부터 보이고, 5초부터 오래 걸림 글', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(Brightness.light, skeletonRegion(pending: true)),
      );
      Visibility vis() => tester.widget<Visibility>(find.byType(Visibility));
      expect(vis().visible, isFalse);
      expect(vis().maintainSize, isTrue);
      await tester.pump(const Duration(milliseconds: 999));
      expect(vis().visible, isFalse);
      await tester.pump(const Duration(milliseconds: 2));
      expect(vis().visible, isTrue);
      expect(findText('평소보다 오래 걸리고 있어요.'), findsNothing);
      await tester.pump(const Duration(seconds: 4));
      final slow = findText('평소보다 오래 걸리고 있어요.');
      expect(slow, findsOneWidget);

      // 오래 걸림 글 — t4 · 400 · fg-neutral-muted, 스켈레톤 위 16
      final style = tester.widget<Text>(slow).style!;
      expect(
        style.fontSize,
        region['slowText.typography'] is Map
            ? (region['slowText.typography'] as Map)['fontSize']
            : null,
      );
      expect(style.fontWeight?.value, region['slowText.fontWeight']);
      expect(
        sameColor(
          specColor(pickMode(region['slowText.foreground'], Brightness.light)),
          style.color!,
        ),
        isTrue,
      );
      final column = tester.widget<Column>(
        find.ancestor(of: slow, matching: find.byType(Column)).first,
      );
      expect(column.spacing, region['slowText.gap']);
      expect(
        tester.getTopLeft(find.byType(PSkeleton)).dy,
        greaterThan(tester.getTopLeft(slow).dy),
      );
    });

    testWidgets(
      '요청 제한 10초 — 아직 기다리는 중이어도 10초에 실패 자리를 보이고, 내용이 오면 내용이 이긴다(03E-021)',
      (tester) async {
        await tester.pumpWidget(
          _host(Brightness.light, skeletonRegion(pending: true)),
        );
        await tester.pump(const Duration(milliseconds: 9990));
        expect(findText('실패'), findsNothing);
        expect(find.byType(PSkeleton), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 20));
        expect(findText('실패'), findsOneWidget);
        expect(find.byType(PSkeleton), findsNothing);
        expect(findText('내용'), findsNothing);
        // 늦게라도 내용이 오면 내용을 보인다
        await tester.pumpWidget(
          _host(Brightness.light, skeletonRegion(pending: false)),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(findText('내용'), findsOneWidget);
        expect(findText('실패'), findsNothing);
      },
    );

    testWidgets('실패 자리가 없는 영역은 10초가 지나도 계속 기다린다 · 10초 안에 오면 실패가 아니다', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const PLoadingRegion(
            pending: true,
            fallback: PSkeleton(width: 200, height: 19),
            child: Text('내용'),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 11));
      expect(find.byType(PSkeleton), findsOneWidget);
      // 10초 안에 온다
      await tester.pumpWidget(
        _host(Brightness.light, skeletonRegion(pending: true)),
      );
      await tester.pump(const Duration(seconds: 9));
      await tester.pumpWidget(
        _host(Brightness.light, skeletonRegion(pending: false)),
      );
      await tester.pump(const Duration(seconds: 3));
      expect(findText('내용'), findsOneWidget);
      expect(findText('실패'), findsNothing);
    });

    testWidgets('실패 화면의 다시 시도로 pending 이 다시 켜지면 시간표를 처음부터 센다', (tester) async {
      await tester.pumpWidget(
        _host(Brightness.light, skeletonRegion(pending: true)),
      );
      await tester.pump(const Duration(seconds: 10, milliseconds: 100));
      expect(findText('실패'), findsOneWidget);
      // 다시 시도 — 요청이 끝났다가(pending false 한 프레임) 다시 시작한다
      await tester.pumpWidget(
        _host(Brightness.light, skeletonRegion(pending: false, failed: true)),
      );
      await tester.pumpWidget(
        _host(Brightness.light, skeletonRegion(pending: true)),
      );
      await tester.pump(const Duration(seconds: 5));
      expect(findText('실패'), findsNothing);
      await tester.pump(const Duration(seconds: 5, milliseconds: 100));
      expect(findText('실패'), findsOneWidget);
    });

    testWidgets('원 모드 — 가운데 원(40), 오래 걸림 글은 원 아래', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          const PLoadingRegion.circle(pending: true, child: Text('내용')),
        ),
      );
      await tester.pump(const Duration(seconds: 5));
      expect(find.byType(PProgressCircle), findsOneWidget);
      expect(
        tester.widget<PProgressCircle>(find.byType(PProgressCircle)).size,
        PProgressCircleSize.s40,
      );
      expect(
        tester.getTopLeft(findText('평소보다 오래 걸리고 있어요.')).dy,
        greaterThan(tester.getTopLeft(find.byType(PProgressCircle)).dy),
      );
    });

    testWidgets('기다린 뒤 내용은 투명도로 나타난다(d3 · enter) — 처음부터 있던 내용은 그대로', (
      tester,
    ) async {
      final pending = ValueNotifier(true);
      await tester.pumpWidget(
        _host(
          Brightness.light,
          ValueListenableBuilder(
            valueListenable: pending,
            builder: (context, p, _) => skeletonRegion(pending: p),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 2));
      pending.value = false;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      final mid = tester
          .widget<Opacity>(
            find.ancestor(of: findText('내용'), matching: find.byType(Opacity)),
          )
          .opacity;
      expect(mid, inExclusiveRange(0, 1));
      await tester.pump(PDuration.d3);
      expect(
        tester
            .widget<Opacity>(
              find.ancestor(of: findText('내용'), matching: find.byType(Opacity)),
            )
            .opacity,
        1,
      );

      // 처음부터 내용 — 투명도 없이
      await tester.pumpWidget(
        _host(Brightness.light, skeletonRegion(pending: false)),
      );
      expect(
        find.ancestor(of: findText('내용'), matching: find.byType(Opacity)),
        findsNothing,
      );
    });

    testWidgets('실패면 failure 를 그린다', (tester) async {
      await tester.pumpWidget(
        _host(Brightness.light, skeletonRegion(pending: true, failed: true)),
      );
      expect(findText('실패'), findsOneWidget);
      expect(find.byType(PSkeleton), findsNothing);
    });

    testWidgets('상태 글은 한 번의 기다림에 같은 글을 한 번만 읽는다(영역이 여럿이어도)', (tester) async {
      final said = <String>[];
      tester.binding.defaultBinaryMessenger
          .setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, (
            message,
          ) async {
            final m = message as Map;
            if (m['type'] == 'announce') {
              said.add((m['data'] as Map)['message'] as String);
            }
            return null;
          });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger
            .setMockDecodedMessageHandler<dynamic>(
              SystemChannels.accessibility,
              null,
            ),
      );
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PLoadingAnnouncer(
            child: Column(
              children: [
                skeletonRegion(pending: true),
                skeletonRegion(pending: true),
              ],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1001));
      await tester.pump(const Duration(seconds: 4));
      expect(said, ['불러오는 중…', '평소보다 오래 걸리고 있어요.']);
    });

    testWidgets('알림을 받지 않는 플랫폼에서는 라이브 영역으로 읽고, 다 오면 비운다', (tester) async {
      final said = <String>[];
      tester.binding.defaultBinaryMessenger
          .setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, (
            message,
          ) async {
            final m = message as Map;
            if (m['type'] == 'announce') {
              said.add((m['data'] as Map)['message'] as String);
            }
            return null;
          });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger
            .setMockDecodedMessageHandler<dynamic>(
              SystemChannels.accessibility,
              null,
            ),
      );
      final semantics = tester.ensureSemantics();
      final pending = ValueNotifier(true);
      addTearDown(pending.dispose);
      await tester.pumpWidget(
        _host(
          Brightness.light,
          supportsAnnounce: false,
          PLoadingAnnouncer(
            child: ValueListenableBuilder<bool>(
              valueListenable: pending,
              builder: (context, p, _) => skeletonRegion(pending: p),
            ),
          ),
        ),
      );
      // 라이브 영역만 — 5초부터는 영역이 보이는 오래 걸림 글도 그린다(그것은 보통 글이다)
      Finder live([String? text]) => find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            (w.properties.liveRegion ?? false) &&
            (text == null || w.properties.label == text),
      );
      await tester.pump(const Duration(milliseconds: 1001));
      await tester.pump(); // 프레임이 끝난 뒤 바꾼다
      expect(said, isEmpty);
      expect(
        tester.getSemantics(live('불러오는 중…')),
        matchesSemantics(label: '불러오는 중…', isLiveRegion: true),
      );
      await tester.pump(const Duration(seconds: 4));
      await tester.pump();
      expect(live('평소보다 오래 걸리고 있어요.'), findsOneWidget);
      pending.value = false;
      await tester.pump();
      await tester.pump();
      expect(live(), findsNothing);
      expect(said, isEmpty);
      semantics.dispose();
    });
  });
}
