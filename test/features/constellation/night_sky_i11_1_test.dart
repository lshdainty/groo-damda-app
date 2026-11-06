// I-11 11-1 앱 — 밤하늘 · 관측 리포트 · 별자리 상세. 360 폭 · 글자 200% · 라이트 · 다크.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/features/constellation/application/constellation_providers.dart';
import 'package:groo_damda_app/features/constellation/domain/constellation.dart';
import 'package:groo_damda_app/features/constellation/presentation/constellation_detail_sheet.dart';
import 'package:groo_damda_app/features/constellation/presentation/constellation_painter.dart';
import 'package:groo_damda_app/features/constellation/presentation/forest_report_screen.dart';
import 'package:groo_damda_app/features/constellation/presentation/night_sky_hero.dart';
import 'package:groo_damda_app/features/constellation/presentation/night_sky_screen.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/badge/p_badge.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';

import '../todo/todo_test_support.dart';
import '../../support/plain_text.dart';

// 실제 star_map — groo-sql `desk/data/27. constellation.sql` 에서 뽑은 공용 JSON(웹 · 앱 하네스 · 그리기 시험이 같이 읽는다).
// 원본 사본: /home/lshdainty/qa/design-work/impl-audit/instructions/I-11-1-star-map-fixture.json — 바꾸면 같이 바꿀 것.
final Map<String, Map<String, dynamic>> _fx = {
  for (final c
      in (jsonDecode(
            File('test/fixtures/i11_1_star_map.json').readAsStringSync(),
          )['constellations']
          as List))
    (c as Map<String, dynamic>)['key'] as String: c,
};

/// 켄타우루스자리 목표 별 수(16).
final int _goal = _fx['cen']!['star_count'] as int;

ConstellationInfo _info(String key, String name, {String color = 'blue'}) {
  final c = _fx[key];
  return ConstellationInfo(
    rowId: 1,
    constellationKey: key,
    name: c == null ? name : c['name'] as String,
    nameEn: c == null ? name : c['name'] as String,
    description: '밤하늘에서 W 자 모양으로 보이는 별자리예요.',
    descriptionEn: null,
    colorKey: c == null ? color : c['color'] as String,
    starCount: c == null ? 5 : c['star_count'] as int,
    starMapRaw: c == null
        ? '{"pts":[[10,20],[30,35],[50,30],[70,50],[90,80]],"edges":[[0,1],[1,2],[2,3],[3,4]]}'
        : jsonEncode(c['star_map']),
    sortOrder: c == null ? 1 : c['sort_order'] as int,
  );
}

CollectionEntry _entry(String key, String name, int n, String? last) =>
    CollectionEntry(
      constellation: _info(key, name),
      collectCount: n,
      lastCollectedDate: last,
    );

String _d(int back) {
  final d = DateTime.now().subtract(Duration(days: back));
  return ymd(d);
}

List<SkyDay> _sky() => [
  for (var i = 13; i >= 0; i--)
    SkyDay(
      date: _d(i),
      status: i == 0
          ? 'REST'
          : (i % 3 == 0 ? 'GROWN' : (i % 3 == 1 ? 'WITHERED' : 'REST')),
      constellationKey: i % 3 == 0 && i != 0 ? 'cass' : null,
      colorKey: i % 3 == 0 && i != 0 ? 'violet' : null,
      points: i % 3 == 0 ? 5 : 1,
      guardUsed: i % 3 == 1 && i % 2 == 1,
    ),
];

ConstellationToday _today({
  int streak = 128,
  String name = '켄타우루스자리',
  bool collected = false,
}) => ConstellationToday(
  constellation: _info('cen', name),
  points: 12,
  goal: 16,
  collected: collected,
  todoPoints: 10,
  memoPoints: 2,
  streak: streak,
  guardCount: 3,
  totalCollected: 37,
);

List<CollectionEntry> _entries() => [
  _entry('cen', '켄타우루스자리', 0, null),
  _entry('cass', '카시오페이아', 128, _d(1)),
  _entry('orion', '오리온자리', 3, _d(5)),
  _entry('uma', '큰곰자리', 1, _d(9)),
  _entry('lyra', '거문고자리', 0, null),
];

List<dynamic> _ov({
  ConstellationToday? today,
  bool failToday = false,
  bool failSky = false,
  bool failColl = false,
  List<dynamic> extra = const [],
}) => [
  ...todoOverrides(
    sky: today ?? _today(),
    skyDays: _sky(),
    todos: [todo(1, '두 번째 줄까지 길게 이어지는 아주 긴 할 일 제목입니다', due: today_())],
    skyError: failToday,
    skyDaysError: failSky,
  ),
  constellationCollectionProvider.overrideWith(
    (ref) async => failColl
        ? throw 'x'
        : ConstellationCollectionData(
            entries: _entries(),
            collectedKinds: 3,
            totalCollected: 132,
          ),
  ),
];

String today_() => today();
Finder _t(String t) => find.byWidgetPredicate(
  (w) => w is Text && (w.data ?? '').replaceAll('\u2060', '') == t,
);

void semTest(String name, Future<void> Function(WidgetTester) body) =>
    testWidgets(name, (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await body(tester);
      } finally {
        handle.dispose();
      }
    });

Finder _richWith(String sub) => find.byWidgetPredicate(
  (w) =>
      w is RichText &&
      w.text.toPlainText().replaceAll('\u2060', '').contains(sub),
);

Finder _has(String sub) => find.byWidgetPredicate(
  (w) => w is Text && (w.data ?? '').replaceAll('\u2060', '').contains(sub),
);

void main() {
  setUpAll(loadRealFonts);

  group('막대 조각 최소 2', () {
    double sum(List<double> l) => l.fold(0, (a, b) => a + b);

    test('주 최대 200 · 합 16 · 각 1건짜리 조각 — 가장 작은 조각 2, 합 = 막대 높이', () {
      // 합 16 → 막대 높이 120 × 16 / 200 = 9.6, 값 [1, 1, 14]
      final h = barPieceHeights([1, 1, 14], 9.6);
      expect(h.reduce(math.min), 2);
      expect(sum(h), closeTo(9.6, 1e-9));
      expect(h[2], closeTo(5.6, 1e-9));
    });

    test('조각이 하나뿐이면 막대 높이 그대로', () {
      expect(barPieceHeights([5], 9.6), [9.6]);
    });

    test('0 인 조각은 그리지 않는다 — 값 0 은 높이 0', () {
      expect(barPieceHeights([0, 0], 9.6), [0.0, 0.0]);
    });

    test('넉넉하면 비율 그대로', () {
      final h = barPieceHeights([1, 2, 3], 60);
      expect(h, [10.0, 20.0, 30.0]);
    });
  });

  test('NEW — lastCollectedDate 가 가장 늦은 하나(횟수 무관)', () {
    expect(newestCollectedKey(_entries()), 'cass');
    expect(newestCollectedKey([_entry('a', 'A', 0, null)]), isNull);
  });

  for (final scale in [1.0, 2.0]) {
    for (final dark in [false, true]) {
      final tag = 'x$scale ${dark ? "다크" : "라이트"}';
      testWidgets('밤하늘 — 넘침 0 · 끝까지 닿기 · 흐림 0 ($tag)', (tester) async {
        await pumpApp(
          tester,
          const NightSkyScreen(),
          overrides: _ov().cast(),
          textScale: scale,
          brightness: dark ? Brightness.dark : Brightness.light,
        );
        expect(tester.takeException(), isNull);
        // 띠: 화면 폭 전체
        for (final f
            in find.byKey(const ValueKey('screen-section')).evaluate()) {
          final r = tester.getRect(find.byWidget(f.widget).first);
          expect(r.left, 0);
          expect(r.right, 360);
        }
        // 하늘 그림 글 · 칸 · 도감 줄은 Opacity 위젯으로 흐리지 않는다
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('night-sky-hero')),
            matching: find.byType(Opacity),
          ),
          findsNothing,
        );
        final faded = tester
            .widgetList<Opacity>(find.byType(Opacity))
            .where((o) => o.opacity != 0 && o.opacity != 1);
        expect(faded, isEmpty);
      });
    }
  }

  semTest('하늘 그림 — 200% 글 상자 겹침 0 · 늘어남 · 이름 의미', (tester) async {
    await pumpApp(
      tester,
      NightSkyHero(today: _today(), doneToday: 5),
      overrides: const [],
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    final hero = tester.getRect(find.byKey(const ValueKey('night-sky-hero')));
    expect(hero.height, greaterThan(168));
    final texts = ['오늘의 목표 별자리', '오늘 5건 완료 · 메모 별빛 +2 · 4별 남음', '연속 관측 128일'];
    final rects = <Rect>[];
    for (final t in texts) {
      final f = find.byWidgetPredicate(
        (w) => w is Text && (w.data ?? '').replaceAll('⁠', '') == t,
      );
      expect(f, findsWidgets, reason: t);
      rects.add(tester.getRect(f.first));
    }
    for (var i = 0; i < rects.length; i++) {
      for (var j = i + 1; j < rects.length; j++) {
        expect(rects[i].overlaps(rects[j]), isFalse, reason: '$i $j');
      }
    }
    expect(
      find.bySemanticsLabel('오늘의 목표 별자리 켄타우루스자리 12/16 별빛'),
      findsOneWidget,
    );
  });

  testWidgets('하늘 그림 — 200% 별빛 수가 아래 줄로 가도 줄 맨 앞 들임 0', (tester) async {
    await pumpApp(
      tester,
      NightSkyHero(today: _today(), doneToday: 5),
      overrides: const [],
      textScale: 2,
    );
    final rich = tester.widget<RichText>(_richWith('켄타우루스자리'));
    final span = rich.text as TextSpan;
    // 이름과 별빛 수는 한 글 흐름이다 — 사이에 공백 한 칸뿐, 들임용 상자(WidgetSpan)가 없다.
    expect(span.children!.whereType<WidgetSpan>(), isEmpty);
    final box = tester.renderObject<RenderParagraph>(_richWith('켄타우루스자리'));
    // 모든 줄의 왼쪽이 같다(첫 글자 x = 상자 왼쪽).
    final plain = box.text.toPlainText();
    final at = plain.indexOf('12/16');
    expect(at, greaterThan(0));
    Offset caret(int i) =>
        box.getOffsetForCaret(TextPosition(offset: i), Rect.zero);
    final first = caret(at);
    final prev = caret(at - 2);
    // 아래 줄로 내려갔으면 맨 앞(0)에서 시작하고, 같은 줄이면 앞 글자 바로 뒤에 붙는다 — 어느 쪽이든 들임 칸은 없다.
    final wrapped = first.dx <= prev.dx;
    if (wrapped) {
      expect(first.dx, 0, reason: '아래 줄 맨 앞 들임 0');
    } else {
      expect(first.dx, greaterThan(prev.dx));
    }
  });

  testWidgets('하늘 그림 — 보호 묶음이 두 줄이어도 구름 아이콘은 첫 줄에 맞는다', (tester) async {
    await pumpApp(
      tester,
      NightSkyHero(today: _today(), doneToday: 5),
      overrides: const [],
      textScale: 2,
    );
    final cloud = tester.getRect(find.byIcon(LucideIcons.cloud));
    final guard = _has('보호');
    final g = tester.getRect(guard);
    // 아이콘 윗선이 글 첫 줄(줄 높이 18×2=36 안 위쪽)에 있다.
    expect(cloud.top, lessThan(g.top + 36));
    expect(cloud.center.dy, lessThan(g.center.dy));
  });

  semTest('도감 — NEW 는 마지막 수집 하나 · 배지 · 단추 이름', (tester) async {
    await pumpApp(tester, const NightSkyScreen(), overrides: _ov().cast());
    await tester.scrollUntilVisible(
      _t('카시오페이아'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(findText('NEW'), findsOneWidget);
    expect(findText('128회'), findsOneWidget);
    expect(_t('미수집'), findsWidgets);
    expect(find.bySemanticsLabel('카시오페이아 감상하기'), findsOneWidget);
    expect(find.byType(PBadge), findsWidgets);
  });

  testWidgets('관측 리포트 줄 — 줄 끝 꺾쇠 18 하나 · 이름 의미', (tester) async {
    await pumpApp(tester, const NightSkyScreen(), overrides: _ov().cast());
    final chevron = find.descendant(
      of: find.byType(PListButtonItem),
      matching: find.byIcon(LucideIcons.chevronRight),
    );
    expect(chevron, findsOneWidget);
    expect(tester.widget<Icon>(chevron).size, 18);
  });

  testWidgets('질의 하나 = 실패 상자 하나 — 나의 밤하늘만 실패', (tester) async {
    await pumpApp(
      tester,
      const NightSkyScreen(),
      overrides: _ov(failSky: true).cast(),
    );
    expect(_t('나의 밤하늘을 불러오지 못했어요'), findsOneWidget);
    expect(_t('밤하늘을 불러오지 못했어요'), findsNothing);
    expect(findTextContaining('Exception'), findsNothing);
    expect(findText('다시 시도'), findsOneWidget);
  });

  testWidgets('오늘 질의 실패 — 화면 전체 상자 하나', (tester) async {
    await pumpApp(
      tester,
      const NightSkyScreen(),
      overrides: _ov(failToday: true).cast(),
    );
    expect(_t('밤하늘을 불러오지 못했어요'), findsOneWidget);
    expect(findText('다시 시도'), findsOneWidget);
  });

  semTest('별자리 상세 — 이름 제목 · 키-값 줄 · 미수집', (tester) async {
    await pumpApp(
      tester,
      Builder(
        builder: (c) => TextButton(
          onPressed: () =>
              showConstellationDetail(c, _entry('lyra', '거문고자리', 0, null)),
          child: const Text('open'),
        ),
      ),
    );
    await tester.tap(findText('open'));
    await tester.pumpAndSettle();
    expect(_t('거문고자리'), findsWidgets);
    expect(_t('별 개수'), findsOneWidget);
    expect(_t('6개'), findsOneWidget);
    expect(_t('미수집'), findsOneWidget);
    expect(_t('아직 만나지 못한 별자리예요'), findsOneWidget);
    // 안내 글은 이미지 밖이라 읽힌다 · 그림은 이름 붙은 이미지 하나
    expect(find.bySemanticsLabel('아직 만나지 못한 별자리예요'), findsOneWidget);
    expect(find.bySemanticsLabel('거문고자리 별자리 그림'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('관측 리포트', () {
    for (final (tag, sky, coll) in [
      ('날별 관측', true, false),
      ('모은 별빛', false, true),
    ]) {
      testWidgets('$tag 를 처음 받지 못하면 "관측 0" 이 아니라 그 자리 실패 + 다시 시도', (
        tester,
      ) async {
        await pumpApp(
          tester,
          const ForestReportScreen(),
          overrides: _ov(failSky: sky, failColl: coll).cast(),
        );
        expect(_t('관측 리포트를 불러오지 못했어요'), findsOneWidget);
        expect(findText('다시 시도'), findsOneWidget);
        expect(findText('관측 결과'), findsNothing);
      });
    }

    for (final streak in [128, 1000]) {
      for (final scale in [1.0, 2.0]) {
        semTest('도장 — $streak일째 x$scale 글이 원 안에 든다', (tester) async {
          await pumpApp(
            tester,
            const ForestReportScreen(),
            overrides: _ov(today: _today(streak: streak)).cast(),
            textScale: scale,
          );
          expect(tester.takeException(), isNull);
          expect(find.bySemanticsLabel('$streak일째 연속 관측'), findsOneWidget);
          final stampBox = tester.renderObject<RenderBox>(
            find.byKey(const ValueKey('report-stamp')),
          );
          expect(
            stampBox.size.width,
            closeTo(72 * scale, 0.5),
            reason: '원이 글자 배율을 따른다',
          );
          // 글 상자 네 귀퉁이를 회전까지 반영한 진짜 점으로 — 한계는 테두리 안쪽 선(반지름 36 × 배율 − 2)
          final center = stampBox.localToGlobal(
            stampBox.size.center(Offset.zero),
          );
          for (final t in ['$streak일째', '연속 관측!']) {
            final box = tester.renderObject<RenderBox>(findText(t));
            final w = box.size.width;
            final h = box.size.height;
            for (final local in [
              Offset.zero,
              Offset(w, 0),
              Offset(0, h),
              Offset(w, h),
            ]) {
              expect(
                (box.localToGlobal(local) - center).distance,
                lessThanOrEqualTo(36.0 * scale - 2),
                reason: '$streak x$scale "$t" 가 테두리 안쪽 선 밖',
              );
            }
          }
        });
      }
    }

    semTest('날 줄 — 360 · 200% 넘침 0 · 오늘 고른 날 · 오는 날 막힘 · 날짜 줄 두 자리 꼴', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const ForestReportScreen(),
        overrides: _ov().cast(),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      final todayCell = find.bySemanticsLabel(RegExp(r', 오늘$'));
      expect(todayCell, findsOneWidget);
      final flags = tester.getSemantics(todayCell);
      expect(flags.flagsCollection.isSelected, Tristate.isTrue);
      expect(flags.flagsCollection.isButton, isTrue);
      // 오는 날(오늘이 일요일이면 없다)은 활성이 아니다 · 눌러도 고른 날이 안 바뀐다
      final n = DateTime.now();
      if (n.weekday < 7) {
        final future = find.bySemanticsLabel(
          monthDayDow(n.add(const Duration(days: 1))),
        );
        expect(future, findsOneWidget);
        expect(
          tester.getSemantics(future).flagsCollection.isEnabled,
          Tristate.isFalse,
        );
        expect(
          tester.getSemantics(future).flagsCollection.isSelected,
          Tristate.isFalse,
        );
      }
      // 날짜 줄 "26.10.02 목" 꼴 — 두 자리 달 · 날
      final dateRow = find.byWidgetPredicate(
        (w) =>
            w is Text &&
            RegExp(r'^\d{2}\.\d{2}\.\d{2} .$').hasMatch(w.data ?? ''),
      );
      expect(dateRow, findsOneWidget);
      expect(findText('관측 결과'), findsOneWidget);
      expect(findText('관측 결과 :'), findsNothing);
    });

    semTest('날 줄 ↔ 날짜 줄 틈 — 칸 바닥 ↔ 날짜 글 위 12 ~ 14 (칸 아래 4 + 위 12)', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const ForestReportScreen(),
        overrides: _ov().cast(),
      );
      final cell = tester.getRect(find.bySemanticsLabel(RegExp(r', 오늘$')));
      final dateText = tester.getRect(
        find.byWidgetPredicate(
          (w) =>
              w is Text &&
              RegExp(r'^\d{2}\.\d{2}\.\d{2} .$').hasMatch(w.data ?? ''),
        ),
      );
      // 칸 아래 4 안에 원 아래가 든다 → 칸 바닥 ~ 날짜 줄 = 12(글 줄 높이 안 여백 포함 14 이내)
      expect(dateText.top - cell.bottom, inInclusiveRange(12, 14));
    });

    for (final guard in [false, true]) {
      semTest('흐린 밤 글 — guardUsed $guard 면 ${guard ? "보호 글" : "흐린 밤"}', (
        tester,
      ) async {
        await pumpApp(
          tester,
          const ForestReportScreen(),
          overrides: _ov().cast(),
        );
        // _sky(): i=1 흐린 밤(보호 씀) · i=4 흐린 밤(보호 안 씀)
        final back = guard ? 1 : 4;
        final d = DateTime.now().subtract(Duration(days: back));
        final monday = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
        ).subtract(Duration(days: DateTime.now().weekday - 1));
        if (DateTime(d.year, d.month, d.day).isBefore(monday)) {
          await tester.tap(find.bySemanticsLabel('이전 주'));
          await tester.pump(const Duration(milliseconds: 300));
        }
        await tester.tap(find.bySemanticsLabel(monthDayDow(d)));
        await tester.pump(const Duration(milliseconds: 400));
        expect(_t('흐린 밤'), guard ? findsNothing : findsOneWidget);
        expect(
          _t('흐린 밤 · 구름 보호로 스트릭 유지'),
          guard ? findsOneWidget : findsNothing,
        );
      });
    }

    for (final scale in [1.0, 2.0]) {
      semTest('요일 원 — 최소 28 · 글이 커지면 따라 커진다 x$scale', (tester) async {
        await pumpApp(
          tester,
          const ForestReportScreen(),
          overrides: _ov().cast(),
          textScale: scale,
        );
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -900));
        await tester.pump(const Duration(milliseconds: 400));
        final dow = weekdayLabels(
          mondayFirst: true,
        )[DateTime.now().weekday - 1];
        final circle = tester.getSize(
          find
              .ancestor(
                of: findText(dow).last,
                matching: find.byType(Container),
              )
              .first,
        );
        expect(circle.width, scale == 1 ? 28 : greaterThan(28));
        expect(circle.height, circle.width);
      });
    }

    semTest('범례 글 — 굵기 400', (tester) async {
      await pumpApp(
        tester,
        const ForestReportScreen(),
        overrides: _ov().cast(),
      );
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -900));
      await tester.pump(const Duration(milliseconds: 400));
      final legend = tester.widget<Text>(_has('중요 완료'));
      expect(legend.style!.fontWeight, FontWeight.w400);
    });

    semTest('지난주로 넘기면 — 같은 요일이 골라지고 아래가 그날 것이다(10-29 결정 4)', (tester) async {
      await pumpApp(
        tester,
        const ForestReportScreen(),
        overrides: _ov().cast(),
      );
      await tester.tap(find.bySemanticsLabel('이전 주'));
      await tester.pump(const Duration(milliseconds: 400));
      // 날 줄에 고른 칸이 하나 있고(오늘 칸은 없다) 날짜 줄이 지난주 같은 요일이다.
      expect(find.bySemanticsLabel(RegExp(r', 오늘$')), findsNothing);
      final want = DateTime.now().subtract(const Duration(days: 7));
      final selected = tester.getSemantics(
        find.bySemanticsLabel(monthDayDow(want)),
      );
      expect(selected.flagsCollection.isSelected, Tristate.isTrue);
      // 도장(오늘 것)은 오늘이 아니라 사라진다
      expect(find.byKey(const ValueKey('report-stamp')), findsNothing);
      // 다음 주로 돌아오면 오늘
      await tester.tap(find.bySemanticsLabel('다음 주'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.bySemanticsLabel(RegExp(r', 오늘$')), findsOneWidget);
    });

    testWidgets('하늘 카드 — 썸네일 88 · 달 아이콘 없음 · 눌러 상세(오늘의 목표 모양)', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, const NightSkyScreen(), overrides: _ov().cast());
      expect(
        tester.getSize(find.byKey(const ValueKey('night-sky-thumb'))),
        const Size(88, 88),
      );
      expect(find.byIcon(LucideIcons.moon), findsNothing);
      await tester.tap(find.byKey(const ValueKey('night-sky-hero')));
      await tester.pumpAndSettle();
      expect(_t('오늘의 목표 별자리'), findsWidgets);
      expect(_t('오늘 모은 별빛'), findsOneWidget);
      expect(_t('75%'), findsOneWidget);
      expect(_t('12/16 별빛 · 4별 남음'), findsOneWidget);
      expect(_t('아직 만나지 못한 별자리예요'), findsNothing);
      handle.dispose();
    });

    testWidgets('도감에서 오늘의 목표를 열어도 같은 모양 · 다른 못 모은 별자리는 지금대로', (tester) async {
      await pumpApp(tester, const NightSkyScreen(), overrides: _ov().cast());
      await tester.scrollUntilVisible(
        _t('카시오페이아'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      // 오늘의 목표(켄타우루스자리) 줄의 미리보기
      await tester.tap(findText('미리보기').first);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('constellation-detail-progress')),
        findsOneWidget,
      );
      expect(_t('12/16 별빛 · 4별 남음'), findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        _t('거문고자리'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(findText('미리보기').last);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('constellation-detail-progress')),
        findsNothing,
      );
      expect(_t('아직 만나지 못한 별자리예요'), findsOneWidget);
    });

    for (final scale in [1.0, 2.0]) {
      testWidgets('하늘 카드 — 이름 뒤 › 20(배율 상관없이) · 글과 썸네일 12 x$scale', (
        tester,
      ) async {
        await pumpApp(
          tester,
          const NightSkyScreen(),
          overrides: _ov().cast(),
          textScale: scale,
        );
        final hero = find.byKey(const ValueKey('night-sky-hero'));
        final chev = find.descendant(
          of: hero,
          matching: find.byIcon(LucideIcons.chevronRight),
        );
        expect(chev, findsOneWidget);
        // 눈에 보이는 크기(배율이 한 번 더 곱해진 뒤)가 20
        expect(tester.getRect(chev).width, closeTo(20, 0.6));
        // 이름 글 칸 오른쪽 ↔ 썸네일 왼쪽 12
        final thumb = tester.getRect(
          find.byKey(const ValueKey('night-sky-thumb')),
        );
        final nameBox = tester.getRect(
          find.descendant(of: hero, matching: find.byType(Expanded)).first,
        );
        expect(thumb.left - nameBox.right, closeTo(12, 0.5));
        // 카드 안 여백 20 에서 위 · 오른쪽으로 4 나간 썸네일(자리는 84)
        final card = tester.getRect(hero);
        expect(card.right - thumb.right, closeTo(20 - 4, 0.5));
        expect(thumb.top - card.top, closeTo(20 - 4, 0.5));
      });
    }

    testWidgets('하늘 카드 — "오늘의 목표 별자리" 는 200% 에서도 낱말을 끊지 않는다', (tester) async {
      await pumpApp(
        tester,
        const NightSkyScreen(),
        overrides: _ov().cast(),
        textScale: 2,
      );
      final f = find.byWidgetPredicate(
        (w) =>
            w is Text &&
            (w.data ?? '').replaceAll('\u2060', '') == '오늘의 목표 별자리',
      );
      final ro = tester.renderObject<RenderParagraph>(
        find.descendant(of: f, matching: find.byType(RichText)).first,
      );
      final txt = ro.text.toPlainText();
      final iByol = txt.indexOf('별');
      final iRi = txt.lastIndexOf('리');
      double top(int at) => ro
          .getBoxesForSelection(
            TextSelection(baseOffset: at, extentOffset: at + 1),
          )
          .first
          .top;
      expect(top(iRi), top(iByol), reason: '별자리가 한 줄에 있어야 한다');
    });

    testWidgets('상세 — 목표를 다 모으면 "100%" 대신 "달성"', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        const NightSkyScreen(),
        overrides: _ov(
          today: ConstellationToday(
            constellation: _info('cen', '켄타우루스자리'),
            points: 16,
            goal: 16,
            collected: true,
            todoPoints: 13,
            memoPoints: 2,
            streak: 5,
            guardCount: 3,
            totalCollected: 37,
          ),
        ).cast(),
      );
      await tester.tap(find.byKey(const ValueKey('night-sky-hero')));
      await tester.pumpAndSettle();
      expect(_t('달성'), findsOneWidget);
      expect(_t('100%'), findsNothing);
      final reached = tester.widget<Text>(_t('달성'));
      final cc = Theme.of(tester.element(_t('달성'))).extension<PColors>()!;
      expect(reached.style!.fontWeight, FontWeight.w700);
      expect(reached.style!.color, cc.fgNeutral);
      // 막대 이름 "{이름} {목표} 중 {현재}" · 값 "달성"
      final bar = tester.getSemantics(
        find.bySemanticsLabel('오늘 모은 별빛 16 중 16'),
      );
      expect(bar.value, '달성');
      handle.dispose();
    });

    testWidgets('하늘 카드 누름 — 눌린 동안 2px 거리 축소만(색은 그대로) · 떼면 돌아온다', (
      tester,
    ) async {
      await pumpApp(tester, const NightSkyScreen(), overrides: _ov().cast());
      final hero = find.byKey(const ValueKey('night-sky-hero'));
      AnimatedScale scaleOf() => tester.widget<AnimatedScale>(
        find.ancestor(of: hero, matching: find.byType(AnimatedScale)).first,
      );
      expect(scaleOf().scale, 1);
      final h = tester.getSize(hero).height;
      final g = await tester.startGesture(tester.getCenter(hero));
      await tester.pump(const Duration(milliseconds: 200));
      expect(scaleOf().scale, closeTo((h - 2) / h, 0.0005));
      await g.up();
      await tester.pumpAndSettle();
      expect(scaleOf().scale, 1);
    });

    testWidgets(
      '상세 키-값 줄 — 제목 fg-neutral · 값 t5 fg-neutral-subtle 400(list.yaml)',
      (tester) async {
        await pumpApp(tester, const NightSkyScreen(), overrides: _ov().cast());
        await tester.tap(find.byKey(const ValueKey('night-sky-hero')));
        await tester.pumpAndSettle();
        final cc = Theme.of(
          tester.element(find.byType(ConstellationDetailSheet)),
        ).extension<PColors>()!;
        final value = tester.widget<Text>(_t('16개'));
        expect(value.style!.color, cc.fgNeutralSubtle);
        expect(value.style!.fontWeight, isNot(FontWeight.w700));
        final title = tester.widget<Text>(
          find.byWidgetPredicate(
            (w) =>
                w is Text && (w.data ?? '').replaceAll('\u2060', '') == '별 개수',
          ),
        );
        expect(title.style!.color, cc.fgNeutral);
      },
    );

    testWidgets('하늘 카드 읽기 — 단추 하나 · 이름 + 설명, 안 글이 한 번 더 읽히지 않고 U+2060 도 없다', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, const NightSkyScreen(), overrides: _ov().cast());
      final node = tester.getSemantics(
        find.byKey(const ValueKey('night-sky-hero')),
      );
      expect(node.label, '오늘의 목표 별자리 켄타우루스자리 12/16 별빛');
      expect(node.hint, contains('연속 관측 128일'));
      expect(
        node.label.contains('\u2060') || node.hint.contains('\u2060'),
        isFalse,
      );
      // 그림 안 글(자식 마디)은 없다
      var children = 0;
      node.visitChildren((_) {
        children++;
        return true;
      });
      expect(children, 0);
      handle.dispose();
    });

    testWidgets('도감 줄 타일 — 타일 40 안에 그림 30(기하 파일 collection-tile-30 의 패널)', (
      tester,
    ) async {
      await pumpApp(tester, const NightSkyScreen(), overrides: _ov().cast());
      await tester.scrollUntilVisible(
        _t('카시오페이아'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      final icon = find.byWidgetPredicate(
        (w) =>
            w is ConstellationIcon &&
            w.info.constellationKey == 'cass' &&
            w.size == 30,
      );
      expect(tester.getSize(icon.first), const Size(30, 30));
      final tile = find.ancestor(
        of: icon.first,
        matching: find.byWidgetPredicate(
          (w) => w is Container && w.decoration is BoxDecoration,
        ),
      );
      expect(tester.getSize(tile.first), const Size(40, 40));
    });
  });
}
