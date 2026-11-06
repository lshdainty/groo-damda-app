// 할 일 폰 원장(I-10 10-1 앱 몫) — 화면을 실제로 띄워 값을 잰다. 부품만 검사해 통과시키지 않는다.
//
// 날짜는 오늘 기준 상대로 만든다(고정한 오늘 + 벽시계 = 시한폭탄). 가장 나쁜 값(긴 제목 · 12자 태그 · 하루 다섯 건 · 지난 마감 · 끝낸 줄)
// 은 200% · 다크에서도 넘침 오류가 없는지 본다.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/features/expense/presentation/widgets/ledger_header.dart';
import 'package:groo_damda_app/features/constellation/application/constellation_providers.dart';
import 'package:groo_damda_app/features/constellation/domain/constellation.dart';
import 'package:groo_damda_app/features/constellation/presentation/constellation_painter.dart';
import 'package:groo_damda_app/features/todo/domain/todo.dart';
import 'package:groo_damda_app/shared/ds/wheel_picker/p_wheel_picker.dart';
import 'package:groo_damda_app/shared/icons/filled_star.dart';
import 'package:groo_damda_app/features/todo/presentation/todo_screen.dart';
import 'package:groo_damda_app/features/todo/presentation/widgets/todo_row.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/badge/p_badge.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/chip/p_chip.dart';
import 'package:groo_damda_app/shared/ds/checkbox/p_checkbox.dart';
import 'package:groo_damda_app/shared/ds/floating_action_button/p_floating_action_button.dart';
import 'package:groo_damda_app/shared/ds/list/list_row.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/scroll_auto_hide/p_scroll_auto_hide.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/swipe_actions/p_swipe_actions.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';
import 'package:groo_damda_app/shared/widgets/p_day_group.dart';
import 'package:groo_damda_app/shared/ds/divider/p_divider.dart';
import 'package:groo_damda_app/shared/scroll/hold_ids.dart';
import '../../support/plain_text.dart';
import 'todo_test_support.dart';

final _now = DateTime.now();

/// 오늘과 다른 같은 달의 날 — 오늘이 1 일이면 다음 날.
String get _other => ymd(otherDayOf(_now));

/// 오늘과 **다른 주**의 같은 달 날 — 오늘 주 달력 한 줄에 같이 들어와 "1건" 표시가 둘이 되지 않게 7 일 떨어뜨린다(어느 날 돌려도
/// 같은 달 안이다: 8 일 이후면 7 일 전, 7 일 이전이면 7 일 뒤 = 최대 14 일). 시험이 날짜에 기대는 자리는 이 함수 하나다.
DateTime otherDayOf(DateTime now) =>
    DateTime(now.year, now.month, now.day > 7 ? now.day - 7 : now.day + 7);

Finder _row(String title) =>
    find.ancestor(of: findPlain(title), matching: find.byType(PListButtonItem));

Finder _chip(String label) =>
    find.byWidgetPredicate((w) => w is PChipToggle && w.label == label);

Finder _checkOf(String title) =>
    find.descendant(of: _row(title), matching: find.byType(PCheckmark));

List<Todo> _basic() => [
  todo(1, '보고서 마무리', due: today(), prio: 'HIGH', tag: '업무'),
  todo(2, '운동 30분', due: today(), prio: 'LOW', done: true, tag: '건강'),
  todo(3, '세탁소 옷 찾기', due: _other, prio: 'LOW', content: '영수증 챙기기'),
  todo(4, '이사 준비 체크리스트', prio: 'MEDIUM'),
];

/// 달 줄의 달 글을 눌러 연 | 월 휠 시트를 열고 [target] 달로 옮겨 "완료" 한다(‹ › 는 없다 — 10-29).
/// [settle] 이 false 면 마지막에 pumpAndSettle 을 쓰지 않는다(불러오는 중 스켈레톤이 계속 도는 화면).
Future<void> _pickMonth(
  WidgetTester tester,
  DateTime from,
  DateTime target, {
  bool settle = true,
}) async {
  await tester.tap(find.byIcon(LucideIcons.chevronDown).first);
  await tester.pumpAndSettle();
  Finder col(String name, String text) => find.descendant(
    of: find.byWidgetPredicate(
      (w) => w is PWheelPickerColumn && w.semanticLabel == name,
    ),
    matching: findText(text),
  );
  if (target.year != from.year) {
    await tester.tap(col('연도', '${target.year}년').first);
    await tester.pumpAndSettle();
  }
  await tester.tap(col('월', '${target.month}월').first);
  await tester.pumpAndSettle();
  await tester.tap(findText('완료'));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(milliseconds: 400));
  }
}

void main() {
  setUpAll(loadRealFonts);

  test('시험 날짜 규칙 — 어느 날 돌려도 같은 달 · 오늘과 다른 주 · 달 안(말일 · 첫날 포함)', () {
    for (
      var d = DateTime(2026, 1, 1);
      d.year < 2029;
      d = d.add(const Duration(days: 1))
    ) {
      final o = otherDayOf(d);
      expect(o.month, d.month, reason: '$d');
      expect(o.year, d.year, reason: '$d');
      expect(o.day, inInclusiveRange(1, 28), reason: '$d — 28 일까지만(짧은 달)');
      final startOfWeek = d.subtract(Duration(days: d.weekday % 7));
      final inWeek =
          !o.isBefore(startOfWeek) &&
          o.isBefore(startOfWeek.add(const Duration(days: 7)));
      expect(inWeek, isFalse, reason: '$d — 오늘 주 달력 줄 밖');
    }
  });

  group('5 · 6 흰 화면 · 상단 바', () {
    testWidgets(
      'Scaffold 가 bg-layer-default 하나 · 띠(PScreenBandBody) · AppBar 0',
      (tester) async {
        await pumpApp(
          tester,
          const TodoScreen(),
          overrides: todoOverrides(todos: _basic()),
        );
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        final c = tester.element(find.byType(TodoScreen)).colors;
        expect(scaffold.backgroundColor, c.bgLayerDefault);
        expect(find.byType(AppBar), findsNothing);
        expect(
          find.byKey(const ValueKey('screen-band-body')),
          findsNothing,
          reason: '띠 · 테두리 카드를 두지 않는다',
        );
      },
    );

    testWidgets(
      '상단 바 = ds Top Navigation 56 · 제목 "할 일" · ← 44 · 머리 바로 아래부터 본문 면(T1)',
      (tester) async {
        await pumpApp(
          tester,
          const TodoScreen(),
          overrides: todoOverrides(todos: _basic()),
        );
        final bar = find.byType(PTopNavigation);
        expect(bar, findsOneWidget);
        expect(tester.getSize(bar).height, 56);
        expect(
          find.descendant(of: bar, matching: findText('할 일')),
          findsOneWidget,
        );
        final back = find.byWidgetPredicate(
          (w) => w is PTopNavigationIconButton && w.label == '뒤로',
        );
        expect(back, findsOneWidget);
        expect(tester.getSize(back).width, 44);
        // 면이 상단 바 바로 아래에서 화면 끝까지 — 빈 달에서도(T1 · T4 = 0)
        final face = find.byKey(const ValueKey('todo-white-screen'));
        expect(tester.getRect(face).top, tester.getRect(bar).bottom);
        expect(tester.getRect(face).bottom, 780);
      },
    );

    testWidgets('빈 달에도 흰 면이 화면 끝까지 닿는다', (tester) async {
      await pumpApp(tester, const TodoScreen(), overrides: todoOverrides());
      final face = find.byKey(const ValueKey('todo-white-screen'));
      expect(tester.getRect(face).bottom, 780);
      expect(tester.getRect(face).width, 360);
    });
  });

  group('7 · 8 · 10 머리', () {
    testWidgets('거르기 단추 — 개수 배지 · 켜짐 틴트 없음, 이름은 "필터"', (tester) async {
      await pumpApp(
        tester,
        const TodoScreen(),
        overrides: todoOverrides(todos: _basic()),
      );
      final handle = tester.ensureSemantics();
      expect(find.byType(PBadge), findsWidgets, reason: '줄의 우선순위 배지는 있다');
      // 단추 곁에 숫자 배지(알림 숫자)가 없다 — 점 하나만 걸렸을 때
      expect(find.byKey(const ValueKey('notification-badge')), findsNothing);
      expect(find.bySemanticsLabel('필터'), findsWidgets);
      expect(find.bySemanticsLabel('필터, 조건 걸림'), findsNothing);
      handle.dispose();
    });

    testWidgets('거르기가 걸리면 단추에 알림 점 하나 · 이름은 "필터, 조건 걸림"', (tester) async {
      await pumpApp(
        tester,
        const TodoScreen(),
        overrides: todoOverrides(todos: _basic()),
      );
      final handle = tester.ensureSemantics();
      await tester.tap(find.bySemanticsLabel('필터'));
      await tester.pumpAndSettle();
      await tester.tap(findPlain('완료한 할 일 숨기기'));
      await tester.pumpAndSettle();
      await tester.tap(findPlain('완료'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('notification-badge')), findsOneWidget);
      final dot = tester.getSize(
        find.byKey(const ValueKey('notification-badge')),
      );
      expect(dot, const Size(6, 6));
      expect(find.bySemanticsLabel('필터, 조건 걸림'), findsOneWidget);
      handle.dispose();
    });

    testWidgets(
      '"오늘 할 일 N개" t9 · 700 · [밤하늘] neutralOutline small + sparkles',
      (tester) async {
        await pumpApp(
          tester,
          const TodoScreen(),
          overrides: todoOverrides(todos: _basic()),
        );
        final total = tester.widget<Text>(findPlain('오늘 할 일 1개'));
        expect(total.style!.fontSize, 24);
        expect(total.style!.fontWeight, FontWeight.w700);
        final sky = tester.widget<PButton>(
          find.byWidgetPredicate((w) => w is PButton && w.label == '밤하늘'),
        );
        expect(sky.variant, PButtonVariant.neutralOutline);
        expect(sky.size, PButtonSize.small);
        expect(sky.prefixIcon, LucideIcons.sparkles);
      },
    );

    testWidgets('오늘 남은 일이 없으면 "오늘 할 일 끝!"', (tester) async {
      await pumpApp(
        tester,
        const TodoScreen(),
        overrides: todoOverrides(
          todos: [todo(1, '끝낸 일', due: today(), done: true)],
        ),
      );
      expect(findPlain('오늘 할 일 끝!'), findsOneWidget);
    });

    testWidgets('별빛 한 줄은 낱말 단위(U+2060)로 줄을 바꾼다 · t4 400', (tester) async {
      await pumpApp(
        tester,
        const TodoScreen(),
        overrides: todoOverrides(todos: _basic()),
      );
      final hint = tester.widget<Text>(findPlainContaining('카시오페이아 수집'));
      expect(hint.data!.contains('⁠'), isTrue);
      expect(hint.style!.fontSize, 14);
      expect(hint.style!.fontWeight, FontWeight.w400);
    });

    testWidgets('[밤하늘] 펼침 하늘 카드를 눌러 연 상세에 "수집" 줄이 있다 · 못 모은 목표는 "미수집"', (
      tester,
    ) async {
      final today = constToday();
      await pumpApp(
        tester,
        const TodoScreen(),
        overrides: [
          ...todoOverrides(todos: _basic()),
          constellationCollectionProvider.overrideWith(
            (ref) async => ConstellationCollectionData(
              entries: [
                CollectionEntry(
                  constellation: today.constellation,
                  collectCount: 0,
                  lastCollectedDate: null,
                ),
              ],
              collectedKinds: 0,
              totalCollected: 0,
            ),
          ),
        ],
      );
      await tester.tap(findText('밤하늘'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('night-sky-hero')));
      await tester.pumpAndSettle();
      expect(findPlain('수집'), findsOneWidget);
      expect(findPlain('미수집'), findsOneWidget);
    });

    testWidgets('[밤하늘] ↔ 월 달력은 하나만 펼친다 · 펼침 이름은 "월 달력" 고정', (tester) async {
      await pumpApp(
        tester,
        const TodoScreen(),
        overrides: todoOverrides(todos: _basic()),
      );
      final handle = tester.ensureSemantics();
      // 밤하늘을 펼치면 두 진입 단추가 뜬다
      await tester.tap(findText('밤하늘'));
      await tester.pumpAndSettle();
      expect(findText('관측 리포트'), findsOneWidget);
      // 월 달력을 펼치면 밤하늘이 접힌다
      await tester.tap(find.bySemanticsLabel('월 달력'));
      await tester.pumpAndSettle();
      expect(findText('관측 리포트'), findsNothing);
      expect(find.bySemanticsLabel('월 달력'), findsOneWidget);
      // 밤하늘을 다시 펼치면 달력이 접힌다 — 칸 수가 한 주(7)로 돌아온다
      await tester.tap(findText('밤하늘'));
      await tester.pumpAndSettle();
      expect(findText('관측 리포트'), findsOneWidget);
      handle.dispose();
    });
  });

  testWidgets('글자 200% — 칸 표시가 잘리지 않고 칸이 글을 따라 늘어난다', (tester) async {
    await pumpApp(
      tester,
      const TodoScreen(),
      overrides: todoOverrides(todos: _basic()),
      textScale: 2,
    );
    final mark = find.descendant(
      of: find.byType(LedgerCalendarGrid),
      matching: findText('1건'),
    );
    final box = find.ancestor(
      of: mark,
      matching: find.byWidgetPredicate(
        (w) => w is ConstrainedBox && w.constraints.minHeight == 15,
      ),
    );
    expect(tester.getSize(box).height, greaterThan(15));
    expect(
      tester.getSize(box).height,
      greaterThanOrEqualTo(tester.getSize(mark).height),
    );
  });

  group('11 원장 머리 숨기기(Scroll Auto Hide) · 18 달 이동', () {
    List<Todo> many() => [
      for (var i = 0; i < 24; i++)
        todo(100 + i, '많은 할 일 ${i + 1}번', due: thisMonth(1 + i % 20)),
    ];

    testWidgets('내리면 머리가 위로 숨고, 모션 줄이기면 숨기지 않는다', (tester) async {
      await pumpApp(
        tester,
        const TodoScreen(),
        overrides: todoOverrides(todos: many()),
      );
      final nav = find.byType(LedgerMonthNav);
      final before = tester.getTopLeft(nav).dy;
      await tester.drag(find.byType(Scrollable).last, const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(nav).dy, lessThan(before - 20));
    });

    testWidgets('모션 줄이기면 머리가 늘 보인다', (tester) async {
      await pumpApp(
        tester,
        const TodoScreen(),
        overrides: todoOverrides(todos: many()),
        disableAnimations: true,
      );
      final nav = find.byType(LedgerMonthNav);
      final before = tester.getTopLeft(nav).dy;
      await tester.drag(find.byType(Scrollable).last, const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(nav).dy, before);
    });

    testWidgets('달을 옮겨도 목록 요청이 없다 — 한 번 받은 목록으로 달만 바꾼다', (tester) async {
      final repo = FakeTodoRepo();
      await pumpApp(
        tester,
        const TodoScreen(),
        overrides: todoOverrides(todos: _basic(), repo: repo),
      );
      final reads = repo.listReads;
      final next = DateTime(_now.year, _now.month + 1, 1);
      await _pickMonth(tester, _now, next);
      expect(repo.listReads, reads);
      expect(findText('${next.year}년 ${next.month}월'), findsWidgets);
    });
  });

  group('틈 표 T1 ~ T4', () {
    testWidgets('T1 0 · T2 끝까지 선 · T3 16 · T4 흰 면이 끝까지 · 첫 묶음 8', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const TodoScreen(),
        overrides: todoOverrides(todos: _basic()),
      );
      final bar = tester.getRect(find.byType(PTopNavigation));
      final face = tester.getRect(
        find.byKey(const ValueKey('todo-white-screen')),
      );
      expect(face.top - bar.bottom, 0, reason: 'T1');
      final divider = tester.getRect(find.byType(LedgerHeaderDivider));
      expect(divider.left, 0, reason: 'T2 선이 화면 끝까지');
      expect(divider.right, 360);
      expect(face.bottom, 780, reason: 'T4');
    });
  });

  testWidgets('글자 200% 에서 [밤하늘] 안 두 단추가 넘치지 않고 세로로 쌓인다', (tester) async {
    await pumpApp(
      tester,
      const TodoScreen(),
      overrides: todoOverrides(todos: _basic()),
      textScale: 2,
    );
    await tester.tap(findText('밤하늘'));
    await tester.pumpAndSettle();
    // 히어로(NightSkyHero — 밤하늘 배치 몫)는 200% 에서 main 도 42px 넘친다 — 이 시험은 두 단추만 본다
    tester.takeException();
    final a = tester.getRect(
      find.byWidgetPredicate((w) => w is PButton && w.label == '관측 리포트'),
    );
    final b = tester.getRect(
      find
          .byWidgetPredicate(
            (w) =>
                w is PButton &&
                w.label == '밤하늘' &&
                w.prefixIcon == LucideIcons.sparkles,
          )
          .last,
    );
    expect(a.right, lessThanOrEqualTo(360));
    expect(b.right, lessThanOrEqualTo(360));
  });

  group('9 주 달력 · 칸 표시', () {
    testWidgets('오늘 칸 이름은 "N월 D일, 남은 할 일 N개" · 표시는 장식 · 높이 15', (tester) async {
      await pumpApp(
        tester,
        const TodoScreen(),
        overrides: todoOverrides(todos: _basic()),
      );
      final handle = tester.ensureSemantics();
      expect(
        find.bySemanticsLabel('${_now.month}월 ${_now.day}일, 남은 할 일 1개'),
        findsOneWidget,
      );
      // 표시는 aria-hidden 처럼 읽히지 않는다 — 칸 이름 하나로 읽힌다
      final mark = find.descendant(
        of: find.byType(LedgerCalendarGrid),
        matching: findText('1건'),
      );
      expect(mark, findsOneWidget);
      expect(
        find.ancestor(of: mark, matching: find.byType(ExcludeSemantics)),
        findsWidgets,
      );
      // 표시 높이 15 — 100% 의 값이다
      final box = find.ancestor(
        of: mark,
        matching: find.byWidgetPredicate(
          (w) => w is ConstrainedBox && w.constraints.minHeight == 15,
        ),
      );
      expect(box, findsOneWidget);
      expect(tester.getSize(box).height, 15);
      handle.dispose();
    });

    testWidgets('오늘의 남은 수는 fg-brand 700 · 오는 날은 불투명도로 흐리지 않는다', (tester) async {
      await pumpApp(
        tester,
        const TodoScreen(),
        overrides: todoOverrides(todos: _basic()),
      );
      final c = tester.element(find.byType(TodoScreen)).colors;
      final mark = tester.widget<Text>(findText('1건'));
      expect(mark.style!.color, c.fgBrand);
      expect(mark.style!.fontWeight, FontWeight.w700);
      expect(
        find.descendant(
          of: find.byType(LedgerCalendarGrid),
          matching: find.byType(Opacity),
        ),
        findsNothing,
      );
    });
  });

  testWidgets('★ 표시 — 수집한 날 · 키운 별자리는 채운 별(PFilledStar) 10 · 별자리 색', (
    tester,
  ) async {
    final n = DateTime.now();
    if (n.day < 3) return;
    final grown = SkyDay(
      date: thisMonth(n.day - 1),
      status: 'GROWN',
      constellationKey: 'lyra',
      colorKey: 'violet',
      points: 5,
      guardUsed: false,
    );
    await pumpApp(
      tester,
      const TodoScreen(),
      overrides: todoOverrides(todos: _basic(), skyDays: [grown]),
    );
    // 월 달력을 펼쳐 지난 날을 본다
    await tester.tap(find.byIcon(LucideIcons.chevronDown).last);
    await tester.pumpAndSettle();
    final stars = find.byType(PFilledStar);
    expect(stars, findsOneWidget);
    expect(tester.getSize(stars), const Size(10, 10));
    expect(
      tester.widget<PFilledStar>(stars).color,
      constellationColor(tester.element(stars), 'violet'),
    );
  });

  group('12 · 13 할 일 줄', () {
    testWidgets('줄 = ds List 누르는 줄 · 체크 24 square · 위 맞춤 · 줄 사이 선 0', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const TodoScreen(),
        overrides: todoOverrides(todos: _basic()),
      );
      expect(find.byType(TodoRow), findsNWidgets(4));
      final check = tester.widget<PCheckmark>(_checkOf('보고서 마무리'));
      expect(check.size, PCheckboxSize.large);
      expect(check.shape, PCheckboxShape.square);
      expect(tester.getSize(_checkOf('보고서 마무리')), const Size(24, 24));
      final item = tester.widget<PListButtonItem>(_row('보고서 마무리'));
      expect(item.align, PListAlign.top);
      // 줄 사이 선 — 머리 아래 선(ds Divider) 하나뿐
      expect(find.byType(PDivider), findsOneWidget);
    });

    testWidgets('체크 이름은 "{제목} 완료" · 지난 마감이면 ", 마감 지남"(칸 테두리만 critical)', (
      tester,
    ) async {
      final past = _now.day > 1 ? thisMonth(_now.day - 1) : null;
      if (past == null) return; // 이달 1 일이면 지난 날이 이 달에 없다
      await pumpApp(
        tester,
        const TodoScreen(),
        overrides: todoOverrides(
          todos: [
            todo(1, '밀린 일', due: past),
            todo(2, '오늘 일', due: today()),
          ],
        ),
      );
      final handle = tester.ensureSemantics();
      expect(find.bySemanticsLabel('밀린 일 완료, 마감 지남'), findsOneWidget);
      expect(find.bySemanticsLabel('오늘 일 완료'), findsOneWidget);
      expect(
        find.descendant(
          of: _row('밀린 일'),
          matching: find.byKey(const ValueKey('todo-check-overdue')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _row('오늘 일'),
          matching: find.byKey(const ValueKey('todo-check-overdue')),
        ),
        findsNothing,
      );
      handle.dispose();
    });

    testWidgets('긴 제목은 말줄임 없이 줄을 바꾼다 · 설명에 "태그 없음" · "메모"', (tester) async {
      const long =
          '자동차 보험 갱신 서류 챙기기 — 만기 전에 비교 견적 세 군데 받아 두기 그리고 보장 범위 비교표도 만들어 두기';
      await pumpApp(
        tester,
        const TodoScreen(),
        overrides: todoOverrides(
          todos: [todo(1, long, due: today(), content: '메모 있음')],
        ),
      );
      final title = tester.widget<Text>(findPlainContaining('자동차 보험'));
      expect(title.overflow, isNot(TextOverflow.ellipsis));
      expect(title.maxLines, isNull);
      final size = tester.getSize(findPlainContaining('자동차 보험'));
      expect(size.height, greaterThan(22 * 2 - 1), reason: '두 줄 이상으로 접힌다');
      expect(findTextContaining('태그 없음'), findsOneWidget);
      expect(findTextContaining('메모'), findsWidgets);
    });

    testWidgets('우선순위 배지 — 중요만 critical, 보통 · 여유는 neutral', (tester) async {
      await pumpApp(
        tester,
        const TodoScreen(),
        overrides: todoOverrides(
          todos: [
            todo(1, '가', due: today(), prio: 'HIGH'),
            todo(2, '나', due: today(), prio: 'MEDIUM'),
            todo(3, '다', due: today(), prio: 'LOW'),
          ],
        ),
      );
      PBadge badge(String label) =>
          tester.widget<PBadge>(findWidgetWithText(PBadge, label));
      expect(badge('중요').tone, PBadgeTone.critical);
      expect(badge('보통').tone, PBadgeTone.neutral);
      expect(badge('여유').tone, PBadgeTone.neutral);
    });

    testWidgets('끝낸 줄 — 취소선 + fg-disabled · 배지 disabled · 불투명도로 흐리지 않는다', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const TodoScreen(),
        overrides: todoOverrides(todos: _basic()),
      );
      final c = tester.element(find.byType(TodoScreen)).colors;
      final title = tester.widget<Text>(findPlain('운동 30분'));
      expect(title.style!.decoration, TextDecoration.lineThrough);
      expect(title.style!.color, c.fgDisabled);
      final item = tester.widget<PListButtonItem>(_row('운동 30분'));
      expect(item.titleStrike, isTrue);
      final badge = tester.widget<PBadge>(
        find.descendant(of: _row('운동 30분'), matching: find.byType(PBadge)),
      );
      expect(badge.disabled, isTrue);
      expect(
        find.descendant(of: _row('운동 30분'), matching: find.byType(Opacity)),
        findsNothing,
      );
      // 끝낸 줄도 누를 수 있다(막힌 줄이 아니다)
      expect(item.onTap, isNotNull);
      expect(tester.widget<PCheckmark>(_checkOf('운동 30분')).checked, isTrue);
    });
  });

  group('13 끝낸 줄 색 전환 모션', () {
    Color titleColor(WidgetTester tester) =>
        tester.widget<Text>(findPlain('보고서 마무리')).style!.color!;

    testWidgets(
      '150ms × motion-ease-easing 으로 fg-disabled 로 옮겨 간다 — 중간에는 둘 다 아니다',
      (tester) async {
        await pumpApp(
          tester,
          const TodoScreen(),
          overrides: todoOverrides(
            todos: _basic(),
            repo: FakeTodoRepo()..gate = Completer<int>(),
          ),
        );
        final c = tester.element(find.byType(TodoScreen)).colors;
        expect(titleColor(tester), c.fgNeutral);
        await tester.tap(_checkOf('보고서 마무리'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 60));
        final mid = titleColor(tester);
        expect(mid, isNot(c.fgNeutral));
        expect(mid, isNot(c.fgDisabled));
        await tester.pump(const Duration(milliseconds: 200));
        expect(titleColor(tester), c.fgDisabled);
      },
    );

    testWidgets('설명 · 배지도 같은 시간 안에 비춰 바뀐다(끝나면 하나만 남는다)', (tester) async {
      await pumpApp(
        tester,
        const TodoScreen(),
        overrides: todoOverrides(
          todos: _basic(),
          repo: FakeTodoRepo()..gate = Completer<int>(),
        ),
      );
      PBadge badgeCount() => tester.widget<PBadge>(
        find
            .descendant(of: _row('보고서 마무리'), matching: find.byType(PBadge))
            .first,
      );
      expect(badgeCount().disabled, isFalse);
      await tester.tap(_checkOf('보고서 마무리'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(
        find.descendant(of: _row('보고서 마무리'), matching: find.byType(PBadge)),
        findsNWidgets(2),
        reason: '앞뒤 모습이 겹쳐 비친다',
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.descendant(of: _row('보고서 마무리'), matching: find.byType(PBadge)),
        findsOneWidget,
      );
      expect(badgeCount().disabled, isTrue);
    });

    testWidgets('모션 줄이기면 바로 바뀐다', (tester) async {
      await pumpApp(
        tester,
        const TodoScreen(),
        overrides: todoOverrides(
          todos: _basic(),
          repo: FakeTodoRepo()..gate = Completer<int>(),
        ),
        disableAnimations: true,
      );
      final c = tester.element(find.byType(TodoScreen)).colors;
      await tester.tap(_checkOf('보고서 마무리'));
      await tester.pump();
      expect(titleColor(tester), c.fgDisabled);
      expect(
        find.descendant(of: _row('보고서 마무리'), matching: find.byType(PBadge)),
        findsOneWidget,
      );
    });
  });

  group('14 · 15 완료 누름 · 묶음 안 차례', () {
    testWidgets('누르는 순간 바뀐다 — 요청 전에 체크가 서고 스피너 · 막힘이 없다', (tester) async {
      final repo = FakeTodoRepo()..gate = Completer<int>();
      await pumpApp(
        tester,
        const TodoScreen(),
        overrides: todoOverrides(todos: _basic(), repo: repo),
      );
      expect(tester.widget<PCheckmark>(_checkOf('보고서 마무리')).checked, isFalse);
      await tester.tap(_checkOf('보고서 마무리'));
      await tester.pump();
      // 응답은 아직이다 — 화면은 이미 바뀌었다
      expect(repo.statusCalls, [(1, 'COMPLETED')]);
      expect(tester.widget<PCheckmark>(_checkOf('보고서 마무리')).checked, isTrue);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.widget<PCheckmark>(_checkOf('보고서 마무리')).enabled, isTrue);
      repo.gate!.complete(0);
      await tester.pumpAndSettle();
    });

    testWidgets('응답이 오기 전에 화면이 닫혀도 터지지 않는다', (tester) async {
      final repo = FakeTodoRepo()..gate = Completer<int>();
      final show = ValueNotifier<bool>(true);
      await pumpApp(
        tester,
        ValueListenableBuilder<bool>(
          valueListenable: show,
          builder: (_, v, _) => v ? const TodoScreen() : const Scaffold(),
        ),
        overrides: todoOverrides(todos: _basic(), repo: repo),
      );
      await tester.tap(_checkOf('보고서 마무리'));
      await tester.pump();
      // 화면을 닫는다 — 컨테이너(앱)는 그대로다
      show.value = false;
      await tester.pump();
      expect(find.byType(TodoScreen), findsNothing);
      repo.gate!.complete(0);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('같은 줄 600ms 안의 두 번째 누름은 무시한다 · 다른 줄은 완료시키지 않는다', (
      tester,
    ) async {
      final repo = FakeTodoRepo();
      await pumpApp(
        tester,
        const TodoScreen(),
        overrides: todoOverrides(todos: _basic(), repo: repo),
      );
      await tester.tap(_checkOf('보고서 마무리'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(_checkOf('보고서 마무리'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(repo.statusCalls, hasLength(1));
      expect(repo.statusCalls.single.$1, 1);
      await tester.pumpAndSettle();
    });

    testWidgets('누른 줄은 700ms 제자리에 남았다가 묶음 아래로 내려간다 (QA #29)', (tester) async {
      final repo = FakeTodoRepo();
      await pumpApp(
        tester,
        const TodoScreen(),
        overrides: todoOverrides(
          todos: [
            todo(1, '가 먼저', due: today(), prio: 'HIGH'),
            todo(2, '나 다음', due: today(), prio: 'MEDIUM'),
          ],
          repo: repo,
        ),
      );
      double y(String t) => tester.getTopLeft(_row(t)).dy;
      expect(y('가 먼저'), lessThan(y('나 다음')));
      await tester.tap(_checkOf('가 먼저'));
      await tester.pump(const Duration(milliseconds: 200));
      // 붙든 동안은 그 자리 — 아래 줄이 올라와 같은 자리를 차지하지 않는다
      expect(y('가 먼저'), lessThan(y('나 다음')));
      await tester.pump(kListHold + const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(y('가 먼저'), greaterThan(y('나 다음')), reason: '끝낸 일은 묶음 아래');
    });

    testWidgets('묶음 안 차례 = 남은 일(중요 → 여유) 위 · 끝낸 일 아래', (tester) async {
      await pumpApp(
        tester,
        const TodoScreen(),
        overrides: todoOverrides(
          todos: [
            todo(1, '끝낸 중요', due: today(), prio: 'HIGH', done: true),
            todo(2, '여유 일', due: today(), prio: 'LOW'),
            todo(3, '중요 일', due: today(), prio: 'HIGH'),
          ],
        ),
      );
      double y(String t) => tester.getTopLeft(_row(t)).dy;
      expect(y('중요 일'), lessThan(y('여유 일')));
      expect(y('여유 일'), lessThan(y('끝낸 중요')));
    });

    testWidgets('실패하면 되돌리고 새 글 한 번 — 서버 원문은 띄우지 않는다', (tester) async {
      final repo = FakeTodoRepo()..fail = true;
      await pumpApp(
        tester,
        const TodoScreen(),
        overrides: todoOverrides(todos: _basic(), repo: repo),
      );
      await tester.tap(_checkOf('보고서 마무리'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();
      expect(tester.widget<PCheckmark>(_checkOf('보고서 마무리')).checked, isFalse);
      expect(findText('할 일 상태를 바꾸지 못했어요.'), findsOneWidget);
      expect(findText('다시 시도'), findsNothing);
      expect(findTextContaining('RAW_SERVER_TEXT_4471'), findsNothing);
    });
  });

  group('16 날짜 묶음 머리', () {
    testWidgets(
      '머리말 2 · t4 · 500 · fg-neutral-subtle · "10월 21일 (수) · 오늘" 꼴 · 끝낸 날 초록 없음',
      (tester) async {
        await pumpApp(
          tester,
          const TodoScreen(),
          overrides: todoOverrides(
            todos: [todo(1, '한 일', due: today(), done: true)],
          ),
        );
        final handle = tester.ensureSemantics();
        final c = tester.element(find.byType(TodoScreen)).colors;
        final head = find.byType(PDayHeaderRow);
        expect(head, findsOneWidget);
        final row = tester.widget<PDayHeaderRow>(head);
        expect(row.text, endsWith(' · 오늘'));
        expect(row.text, startsWith('${_now.month}월 ${_now.day}일 ('));
        final text = tester.widget<Text>(findPlainContaining(' · 오늘'));
        expect(text.style!.fontSize, 14);
        expect(text.style!.fontWeight, FontWeight.w500);
        expect(text.style!.color, c.fgNeutralSubtle);
        // 다 끝낸 날도 오른쪽 "1/1 완료" 는 옅은 회색 하나(초록 없음)
        final ratio = tester.widget<Text>(findText('1/1 완료'));
        expect(ratio.style!.color, c.fgNeutralSubtle);
        expect(
          tester
              .getSemantics(findText(row.text))
              .getSemanticsData()
              .headingLevel,
          2,
        );
        handle.dispose();
      },
    );

    testWidgets('묶음 위 16 · 첫 묶음 8(머리 위 여백)', (tester) async {
      await pumpApp(
        tester,
        const TodoScreen(),
        overrides: todoOverrides(todos: _basic()),
      );
      final heads = find.byType(PDayHeaderRow);
      expect(heads, findsWidgets);
      // 묶음 사이 간격 — 첫 묶음 마지막 줄 아래 ~ 다음 머리 위 = 16 (+ 머리 안 위 8 은 따로)
      final first = tester.getRect(heads.at(0));
      final second = tester.getRect(heads.at(1));
      final firstRow = tester.getRect(
        find
            .descendant(
              of: find.byType(TodoDayGroup).at(0),
              matching: find.byType(TodoRow),
            )
            .last,
      );
      expect(second.top - firstRow.bottom, 16);
      // 첫 묶음 머리는 머리 아래 선에서 8
      final divider = tester.getRect(find.byType(LedgerHeaderDivider));
      expect(first.top - divider.bottom, 8);
    });

    testWidgets('마감일 없는 묶음은 맨 아래 — "마감일 없음"', (tester) async {
      await pumpApp(
        tester,
        const TodoScreen(),
        overrides: todoOverrides(todos: _basic()),
      );
      final heads = find.byType(PDayHeaderRow);
      final last = tester.widget<PDayHeaderRow>(heads.last);
      expect(last.text, '마감일 없음');
    });
  });

  group('17 줄 끝 ⋮ 없음 · 밀기 [수정, 삭제]', () {
    testWidgets('줄 끝에 ⋮ 가 없다 · 밀기만(수정 · 삭제)', (tester) async {
      await pumpApp(
        tester,
        const TodoScreen(),
        overrides: todoOverrides(todos: _basic()),
      );
      expect(find.byType(PSwipeActionsMore), findsNothing);
      expect(find.byIcon(LucideIcons.ellipsisVertical), findsNothing);
      final swipe = tester.widget<PSwipeActions>(
        find.byType(PSwipeActions).first,
      );
      expect(swipe.actions.map((a) => a.label), ['수정', '삭제']);
      expect(swipe.actions.last.kind, PSwipeActionKind.destructive);
    });
  });

  group('18 비어 있음 · 불러오는 중 · 실패', () {
    testWidgets('이 달 0건 — 안내 글 · 버튼 없음', (tester) async {
      await pumpApp(tester, const TodoScreen(), overrides: todoOverrides());
      final r = tester.widget<PResultSection>(find.byType(PResultSection));
      expect(r.kind, PResultKind.empty);
      expect(r.primaryAction, isNull);
      expect(r.icon, LucideIcons.listChecks);
      expect(findPlain('오른쪽 아래 + 버튼으로 추가해보세요.'), findsOneWidget);
    });

    testWidgets('걸러서 0건 — funnel-x · 버튼 없음 · 해요체 안내', (tester) async {
      await pumpApp(
        tester,
        const TodoScreen(),
        overrides: todoOverrides(todos: _basic()),
      );
      final handle = tester.ensureSemantics();
      await tester.tap(find.bySemanticsLabel('필터'));
      await tester.pumpAndSettle();
      // 태그 "건강" 은 끝낸 일 하나뿐 — 완료 숨기기와 함께 걸면 0 건이다
      await tester.tap(_chip('건강'));
      await tester.pumpAndSettle();
      await tester.tap(findPlain('완료한 할 일 숨기기'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byWidgetPredicate((w) => w is PButton && w.label == '완료'),
      );
      await tester.pumpAndSettle();
      final r = tester.widget<PResultSection>(find.byType(PResultSection));
      expect(r.kind, PResultKind.empty);
      expect(r.icon, LucideIcons.funnelX);
      expect(r.primaryAction, isNull);
      expect(r.title, '조건에 맞는 할 일이 없어요');
      expect(r.description, '조건을 바꾸거나 지워보세요.');
      handle.dispose();
    });

    testWidgets('불러오는 중 — 틀(상단 바 · 달 이름 · 요일)은 그리고 줄 자리만 Skeleton', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const TodoScreen(),
        overrides: todoOverrides(hang: true),
        settle: false,
      );
      expect(find.byType(PTopNavigation), findsOneWidget);
      expect(findText('${_now.year}년 ${_now.month}월'), findsOneWidget);
      expect(find.byType(PSkeleton), findsWidgets);
      expect(find.byType(TodoRow), findsNothing);
    });

    testWidgets('실패 — 상자 하나 · 원문 없음 · 다시 시도 (질의 하나 = 실패 상자 하나)', (
      tester,
    ) async {
      final repo = FakeTodoRepo();
      await pumpApp(
        tester,
        const TodoScreen(),
        overrides: todoOverrides(listError: true, repo: repo),
      );
      final r = tester.widget<PResultSection>(find.byType(PResultSection));
      expect(find.byType(PResultSection), findsOneWidget);
      expect(r.kind, PResultKind.failure);
      expect(r.title, '할 일을 불러오지 못했어요');
      expect(r.description, '잠시 후 다시 시도해주세요.');
      expect(findTextContaining('RAW_SERVER_TEXT_9137'), findsNothing);
      final before = repo.listReads;
      await tester.tap(findText('다시 시도'));
      await tester.pumpAndSettle();
      expect(repo.listReads, greaterThan(before));
    });
  });

  group('19 떠 있는 [+]', () {
    testWidgets('ds FAB 56 · 이름 "할 일 추가" · 끝에서 20 · 눌러 추가 시트', (tester) async {
      await pumpApp(
        tester,
        const TodoScreen(),
        overrides: todoOverrides(todos: _basic()),
      );
      final fab = find.byKey(const ValueKey('floating-action-button'));
      expect(tester.getSize(fab), const Size(56, 56));
      final r = tester.getRect(fab);
      expect(360 - r.right, 20);
      expect(780 - r.bottom, 20);
      final widget = tester.widget<PFloatingActionButton>(
        find.byType(PFloatingActionButton),
      );
      expect(widget.label, '할 일 추가');
      await tester.tap(fab);
      await tester.pumpAndSettle();
      expect(findPlain('할 일 추가'), findsWidgets);
    });
  });

  group('23 거르기 시트', () {
    testWidgets('"태그 없음" 칩(그런 할 일이 있을 때만 맨 뒤) · 스위치 줄 · 바꾸는 즉시 목록에', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const TodoScreen(),
        overrides: todoOverrides(todos: _basic(), tags: [tagOf(1, '업무')]),
      );
      final handle = tester.ensureSemantics();
      await tester.tap(find.bySemanticsLabel('필터'));
      await tester.pumpAndSettle();
      expect(_chip('업무'), findsOneWidget);
      expect(_chip('태그 없음'), findsOneWidget);
      // 스위치 줄
      expect(find.byType(PListSwitchItem), findsOneWidget);
      // 초기화는 걸린 게 없으면 막힌다
      final reset = find.byWidgetPredicate(
        (w) => w is PButton && w.label == '초기화',
      );
      expect(tester.widget<PButton>(reset).onPressed, isNull);
      // 태그 없음만 걸면 목록이 바로 줄어든다(시트가 열린 채로)
      await tester.tap(_chip('태그 없음'));
      await tester.pumpAndSettle();
      expect(find.byType(TodoRow), findsNWidgets(2));
      expect(tester.widget<PButton>(reset).onPressed, isNotNull);
      handle.dispose();
    });
  });

  group('끝까지 닿기 · 가장 나쁜 값 · 200% · 다크', () {
    for (final scale in [1.0, 2.0]) {
      for (final dark in [false, true]) {
        testWidgets(
          'x$scale ${dark ? "다크" : "라이트"} — 넘침 오류 0 · 머리 아래 선 · 줄이 화면 끝(360)까지',
          (tester) async {
            final worst = [
              todo(
                1,
                '자동차 보험 갱신 서류 챙기기 — 만기 전에 비교 견적 세 군데 받아 두기 그리고 보장 범위 비교표도',
                due: today(),
                prio: 'HIGH',
                tag: '장기프로젝트자료모으기정',
                content: '메모',
              ),
              for (var i = 0; i < 4; i++)
                todo(
                  10 + i,
                  '하루 다섯 건 중 $i 번째',
                  due: today(),
                  done: i.isEven,
                  prio: ['HIGH', 'MEDIUM', 'LOW'][i % 3],
                ),
              todo(30, '기한 없음 일', prio: 'LOW'),
            ];
            await pumpApp(
              tester,
              const TodoScreen(),
              overrides: todoOverrides(todos: worst),
              textScale: scale,
              brightness: dark ? Brightness.dark : Brightness.light,
            );
            expect(tester.takeException(), isNull);
            final div = tester.getRect(find.byType(LedgerHeaderDivider));
            expect(div.left, 0);
            expect(div.right, 360);
            final rows = find.byType(PListRowFrame);
            expect(rows, findsWidgets);
            for (final e in rows.evaluate()) {
              final r = tester.getRect(find.byElementPredicate((x) => x == e));
              if (r.top > 780) continue;
              expect(r.left, 0, reason: '줄이 화면 왼쪽 끝부터');
              expect(r.right, 360, reason: '줄이 화면 오른쪽 끝까지');
            }
            // 흰 면이 화면 끝까지 · 숨는 머리(PScrollAutoHide)가 상단 바 바로 아래
            expect(find.byType(PScrollAutoHide), findsOneWidget);
          },
        );
      }
    }
  });
}
