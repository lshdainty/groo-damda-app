// I-09b 6 — 일정 상세 본문(1-2B): List 줄 · 폼과 같은 차례 · 아이콘 · 없는 값은 줄 0 · 꺾쇠 0 · 색은 점으로만 · D-day · 설명 다 보임 · 긴 값.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/format/chart_palette.dart';
import 'package:groo_damda_app/features/calendar/domain/calendar_event.dart';
import 'package:groo_damda_app/features/calendar/domain/user_calendar.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_event_detail_body.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/badge/p_badge.dart';
import 'package:groo_damda_app/shared/forms/picker_row.dart';

import '../../support/plain_text.dart';

final _today = DateTime(2026, 10, 29, 13);
const _cal = UserCalendar(
  rowId: 4,
  calendarName: '개인',
  color: '#8b4dba',
  myRole: 'OWNER',
);

CalendarEvent _ev({
  String title = '안과 정기 검진',
  String start = '2026-10-24T10:00:00',
  String end = '2026-10-24T11:00:00',
  String allDay = 'N',
  bool full = true,
  String? rrule,
  String? color = '#ff00ff',
  String? description,
  String? location,
}) => CalendarEvent(
  rowId: 1,
  title: title,
  color: color,
  startDate: start,
  endDate: end,
  isAllDay: allDay,
  calendarRowId: 4,
  calendarColor: '#8b4dba',
  labelRowId: full ? 1 : null,
  labelName: full ? '가족 행사' : null,
  labelColor: full ? '#2d8060' : null,
  location: full ? (location ?? '서울 강남구') : null,
  description: full ? (description ?? '시력 검사') : null,
  rrule: rrule,
  reminders: full
      ? const [
          EventReminder(rowId: 1, minutesBefore: 60),
          EventReminder(rowId: 2, minutesBefore: 1440),
        ]
      : const [],
);

Future<void> _pump(
  WidgetTester tester,
  CalendarEvent e, {
  double scale = 1,
  double width = 390,
  List<UserCalendar> calendars = const [_cal],
}) async {
  tester.view.physicalSize = Size(width, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: GrooTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      builder: (c, child) => MediaQuery(
        data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: CalendarEventDetailBody(
            event: e,
            calendars: calendars,
            today: _today,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

List<String?> _titles(WidgetTester tester) => [
  for (final w in tester.widgetList<Text>(
    find.byWidgetPredicate(
      (w) => w is Text && w.key == const ValueKey('plist-title'),
    ),
  ))
    w.semanticsLabel,
];

void main() {
  testWidgets('줄 차례는 폼과 같다 — 캘린더 · 라벨 · 시작 · 종료 · 반복 · 알림 · 장소 · 설명', (
    tester,
  ) async {
    await _pump(tester, _ev(rrule: 'FREQ=WEEKLY'));
    expect(_titles(tester), ['캘린더', '라벨', '시작', '종료', '반복', '알림', '장소', '설명']);
    for (final icon in [
      LucideIcons.calendar,
      LucideIcons.tag,
      LucideIcons.clock,
      LucideIcons.repeat,
      LucideIcons.bell,
      LucideIcons.mapPin,
      LucideIcons.text,
    ]) {
      expect(find.byIcon(icon), findsWidgets, reason: '$icon');
    }
    // 값 글 — 시각 조각 · 걸린 시간 · 반복 · 알림 짧은 차례
    expect(findPlain('10월 24일 (토)'), findsNWidgets(2));
    expect(findPlain('오전 10:00'), findsOneWidget);
    expect(findPlain('오전 11:00'), findsOneWidget);
    expect(findPlain('1시간'), findsOneWidget);
    expect(findRichPlain('매주'), findsOneWidget);
    expect(findRichPlain('1시간 전, 1일 전'), findsOneWidget);
  });

  testWidgets('없는 값(라벨 · 알림 · 장소 · 설명)은 줄을 두지 않고 반복은 늘 둔다', (tester) async {
    await _pump(tester, _ev(full: false));
    expect(_titles(tester), ['캘린더', '시작', '종료', '반복']);
    expect(findRichPlain('반복 안 함'), findsOneWidget);
  });

  testWidgets('캘린더를 못 찾으면 캘린더 줄을 두지 않는다', (tester) async {
    await _pump(tester, _ev(full: false), calendars: const []);
    expect(_titles(tester), ['시작', '종료', '반복']);
  });

  testWidgets('종일은 시작 · 종료 대신 "종일" 한 줄 — 여러 날이면 날짜 뒤에 "~ 끝 날"', (tester) async {
    await _pump(
      tester,
      _ev(
        full: false,
        allDay: 'Y',
        start: '2026-10-23T00:00:00',
        end: '2026-10-25T23:59:59',
      ),
    );
    expect(_titles(tester), ['캘린더', '종일', '반복']);
    expect(findPlain('10월 23일 (금)'), findsOneWidget);
    expect(findPlain('~ 10월 25일 (일)'), findsOneWidget);
    expect(find.byIcon(LucideIcons.sun), findsOneWidget);
  });

  testWidgets('다른 해는 날짜에 연도가 붙는다', (tester) async {
    await _pump(
      tester,
      _ev(
        full: false,
        start: '2027-01-03T09:00:00',
        end: '2027-01-03T10:00:00',
      ),
    );
    expect(findPlain('2027년 1월 3일 (일)'), findsNWidgets(2));
  });

  testWidgets('꺾쇠가 없다 — 보기만 하는 줄', (tester) async {
    await _pump(tester, _ev());
    expect(find.byIcon(LucideIcons.chevronRight), findsNothing);
  });

  testWidgets('색은 줄 앞 점으로만 — 캘린더 · 라벨 색이고 일정 색은 어디에도 없다', (tester) async {
    await _pump(tester, _ev());
    final ctx = tester.element(find.byType(CalendarEventDetailBody));
    final dots = [
      for (final d in tester.widgetList<PickerDot>(find.byType(PickerDot)))
        d.color,
    ];
    expect(dots, [
      chartToneOf(ctx, '#8b4dba').solid,
      chartToneOf(ctx, '#2d8060').solid,
    ]);
    expect(
      dots,
      isNot(contains(chartToneOf(ctx, '#ff00ff').solid)),
      reason: '일정 색(event.color)은 상세에 그리지 않는다',
    );
  });

  testWidgets('D-day 배지 — 오늘 · 3일 남음은 경고, 4일 남음 · 지남은 중립', (tester) async {
    Future<PBadge> badgeOf(String start) async {
      await _pump(tester, _ev(full: false, start: start, end: start));
      return tester.widget<PBadge>(find.byType(PBadge));
    }

    var b = await badgeOf('2026-10-29T18:00:00');
    expect((b.label, b.tone), ('D-DAY', PBadgeTone.warning));
    b = await badgeOf('2026-11-01T09:00:00');
    expect((b.label, b.tone), ('D-3', PBadgeTone.warning));
    b = await badgeOf('2026-11-02T09:00:00');
    expect((b.label, b.tone), ('D-4', PBadgeTone.neutral));
    b = await badgeOf('2026-10-24T10:00:00');
    expect((b.label, b.tone), ('5일 지남', PBadgeTone.neutral));
    expect(b.size, PBadgeSize.large);
  });

  testWidgets('설명은 다 보인다 — 말줄임 없이 줄바꿈 그대로, 줄 제목 글 시작(58)에 맞춘다', (tester) async {
    const desc = '첫째 줄 설명입니다\n둘째 줄 설명입니다\n셋째 줄 설명입니다';
    await _pump(tester, _ev(description: desc));
    final w = tester.widget<Text>(
      find.byKey(const ValueKey('calendar-detail-description')),
    );
    expect(w.maxLines, isNull);
    expect(plainOf(w.data!), desc);
    final title = tester.getRect(
      find.byWidgetPredicate(
        (w) =>
            w is Text &&
            w.key == const ValueKey('plist-title') &&
            w.semanticsLabel == '설명',
      ),
    );
    final body = tester.getRect(
      find.byKey(const ValueKey('calendar-detail-description')),
    );
    expect(body.left, closeTo(title.left, 1), reason: '제목 글 시작과 맞춤');
    expect(body.left, closeTo(58, 1));
  });

  testWidgets('가장 나쁜 값(50자 제목 · 긴 장소) · 폭 360 · 글자 200% 에서 넘치지 않는다', (
    tester,
  ) async {
    await _pump(
      tester,
      _ev(
        title:
            '분기 회고 · 다음 분기 목표 정리 회의(길게 쓴 제목이 줄과 상세 안에서 어떻게 보이는지 확인하는 아주 긴 일정)',
        location: '본사 3층 큰 회의실 — 길게 써도 줄이 바뀌는지 보려는 아주 긴 장소 이름',
        rrule: 'FREQ=WEEKLY',
      ),
      scale: 2,
      width: 360,
    );
    expect(tester.takeException(), isNull);
    final right = tester.getRect(find.byType(CalendarEventDetailBody)).right;
    for (final r in tester.renderObjectList<RenderParagraph>(
      find.byType(RichText),
    )) {
      expect(
        r.localToGlobal(Offset(r.size.width, 0)).dx,
        lessThanOrEqualTo(right + 0.5),
      );
    }
  });

  testWidgets('긴 캘린더 이름이 두 줄이면 두 줄 모두 같은 오른쪽 끝에 맞고 점은 첫 줄 높이에 선다', (
    tester,
  ) async {
    const name = '가족 공유 캘린더 — 주말 나들이 · 경조사 · 병원 동행';
    await _pump(
      tester,
      _ev(full: false),
      calendars: const [
        UserCalendar(rowId: 4, calendarName: name, color: '#b83b7a'),
      ],
    );
    final textFinder = find.byWidgetPredicate(
      (w) => w is Text && w.data != null && plainOf(w.data!) == name,
    );
    final para = tester.renderObject<RenderParagraph>(
      find.descendant(of: textFinder, matching: find.byType(RichText)),
    );
    expect(para.size.height, greaterThan(30), reason: '두 줄로 접혔다');
    double endX(int offset) => para
        .getBoxesForSelection(
          TextSelection(baseOffset: offset - 1, extentOffset: offset),
        )
        .last
        .right;
    // 첫 줄의 끝 — 글자 상자의 위가 첫 글자보다 내려가는 첫 자리
    final top0 = para
        .getBoxesForSelection(
          const TextSelection(baseOffset: 0, extentOffset: 1),
        )
        .first
        .top;
    var firstLineEnd = 1;
    while (firstLineEnd < para.text.toPlainText().length &&
        (para
                    .getBoxesForSelection(
                      TextSelection(
                        baseOffset: firstLineEnd,
                        extentOffset: firstLineEnd + 1,
                      ),
                    )
                    .firstOrNull
                    ?.top ??
                top0) <
            top0 + 5) {
      firstLineEnd++;
    }
    expect(firstLineEnd, lessThan(para.text.toPlainText().length));
    // 줄 끝 공백은 보이지 않는 글자라 그 앞 글자의 오른쪽 끝으로 잰다
    final firstEnd = endX(firstLineEnd - 1);
    final secondEnd = endX(para.text.toPlainText().length);
    // 글자 끝 기준 — 줄마다 같은 세로선(±1)이다(오른쪽 맞춤). 두 줄 길이가 다르니 왼쪽은 들쭉날쭉해도 된다
    expect(
      para.size.width - firstEnd,
      lessThan(8),
      reason: '첫 줄도 같은 오른쪽 끝(줄 끝 공백 하나 폭 안)',
    );
    expect(
      para.size.width - secondEnd,
      lessThan(1.5),
      reason: '마지막 줄이 상자 오른쪽 끝에 붙는다(오른쪽 맞춤)',
    );
    // 점은 글 첫 글자 바로 앞(사이 6) — 글 흐름 안이라 첫 줄 높이에 서고 오른쪽 맞춤에서 첫 줄과 같이 움직인다
    final dot = tester.getRect(find.byType(PickerDot));
    final firstChar = para
        .getBoxesForSelection(
          const TextSelection(baseOffset: 1, extentOffset: 2),
        )
        .first;
    final firstCharLeft = para.localToGlobal(Offset(firstChar.left, 0)).dx;
    expect(firstCharLeft - dot.right, closeTo(6, 1));
    final text = tester.getRect(textFinder);
    expect(dot.center.dy, lessThan(text.top + 22));
    expect(dot.center.dy, greaterThan(text.top));
  });
}
