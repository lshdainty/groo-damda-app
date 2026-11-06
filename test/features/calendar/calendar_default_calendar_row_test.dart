// 기본 캘린더 행의 표시 스위치를 뺀다 — 항상 표시로 고정 (QA 결정 5).
//
// #338 이 "숨긴 캘린더는 일정 만들기 선택 목록에서 뺀다" 를 넣으면서 경계가 하나
// 생겼다. **기본 캘린더가 숨겨져 있으면** 서버가 자동 대입하는 캘린더가 곧 숨긴
// 캘린더라, 저장은 성공했는데 화면에는 아무것도 안 남는다. 되돌릴 스위치도 필터
// 시트 안이라 "일정이 사라졌다" 로만 보인다.
//
// 그래서 기본 캘린더를 못 숨기게 한다. 서버는 표시 토글을 400 으로 막고, 앱은
// **체크박스를 아예 안 그린다** — 눌리지 않는 회색 체크박스를 두면 "왜 안 되지"
// 만 남는다. 대신 캘린더 관리 화면·웹과 같은 '기본' 배지로 이유를 남긴다.
//
// 막는 것만으로는 부족하다. 막기 전에 이미 꺼 둔 사람의 응답은 여전히
// `isVisible: false` 로 온다. 스위치를 없앤 뒤라 되돌릴 방법이 화면에 없으므로,
// **읽는 자리에서** 기본 캘린더를 보임으로 고정해 그 상태 자체를 없앤다.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/features/calendar/application/calendar_providers.dart';
import 'package:groo_damda_app/features/calendar/data/user_calendar_repository.dart';
import 'package:groo_damda_app/features/calendar/domain/calendar_event.dart';
import 'package:groo_damda_app/features/calendar/domain/calendar_visibility.dart';
import 'package:groo_damda_app/features/calendar/domain/holiday.dart';
import 'package:groo_damda_app/features/calendar/domain/user_calendar.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_screen.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/checkbox/p_checkbox.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import '../../support/plain_text.dart';

const _default = UserCalendar(rowId: 1, calendarName: '기본캘린더', isDefault: true);
const _normal = UserCalendar(rowId: 2, calendarName: '회사캘린더');

/// 표시 토글을 막기 전에 꺼 둔 기본 캘린더 — 서버가 아직 이렇게 내려준다.
const _staleHiddenDefault = UserCalendar(
  rowId: 1,
  calendarName: '기본캘린더',
  isDefault: true,
  isVisible: false,
);

/// 토글이 실제로 나갔는지 잡아 둔다.
class _RecordingRepo extends UserCalendarRepository {
  _RecordingRepo() : super(Dio());

  final toggled = <int>[];

  @override
  Future<UserCalendar> toggleVisibility(int id) async {
    toggled.add(id);
    return _normal;
  }
}

CalendarEvent _event({
  required int rowId,
  required String title,
  required int calendarRowId,
  required DateTime day,
}) {
  String at(int h) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}T${h.toString().padLeft(2, '0')}:00:00';
  return CalendarEvent(
    rowId: rowId,
    title: title,
    calendarRowId: calendarRowId,
    startDate: at(9),
    endDate: at(10),
  );
}

/// 기본 캘린더 줄의 제목 — 제목 뒤에 "기본" 배지가 이어 붙어 Text.rich 라, 줄바꿈 보호 글자를 뺀 글로 찾는다.
Finder _defaultTitle() => find.byWidgetPredicate(
  (w) => w is RichText && plainOf(w.text.toPlainText()).contains('기본캘린더'),
  description: '기본 캘린더 제목',
);

/// 필터 시트의 체크 줄 — List 체크 줄 하나가 한 행의 스위치다(공휴일 줄 포함).
Finder checkRows() => find.byType(PListCheckItem);

void main() {
  late AppLocalizations l;

  /// 이번 달 15일 — 월 그리드에 늘 그려지고 이월 칸과 숫자가 겹치지 않는다.
  DateTime thisMonth15() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 15);
  }

  Future<_RecordingRepo> pump(
    WidgetTester tester, {
    required List<UserCalendar> calendars,
  }) async {
    final repo = _RecordingRepo();
    final d = thisMonth15();
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userCalendarListProvider.overrideWith((ref) async => calendars),
          userCalendarRepositoryProvider.overrideWith((ref) async => repo),
          monthEventsProvider.overrideWith(
            (ref, key) async => [
              _event(rowId: 1, title: '기본일정', calendarRowId: 1, day: d),
              _event(rowId: 2, title: '회사일정', calendarRowId: 2, day: d),
            ],
          ),
          holidayListProvider.overrideWith((ref, key) async => <Holiday>[]),
        ],
        child: MaterialApp(
          theme: GrooTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: Builder(
            builder: (context) {
              l = AppLocalizations.of(context);
              return const Scaffold(body: CalendarScreen());
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return repo;
  }

  /// 헤더 칩을 눌러 필터 시트를 연다. 칩 글자는 "N개" 라 개수를 알아야 한다.
  Future<void> openFilterSheet(
    WidgetTester tester, {
    required int count,
  }) async {
    await tester.tap(findText(l.calCalendarChipCount(count)));
    await tester.pumpAndSettle();
  }

  group('필터 시트 — 기본 캘린더 행', () {
    testWidgets('기본 캘린더 줄은 칸만 켠 채 막힌 체크 줄(locked)이고 일반 줄은 그대로다', (
      tester,
    ) async {
      await pump(tester, calendars: const [_default, _normal]);
      // 캘린더 2 + 공휴일 1.
      await openFilterSheet(tester, count: 3);

      expect(_defaultTitle(), findsOneWidget);
      expect(findPlain('회사캘린더'), findsOneWidget);

      // 세 줄 모두 체크 줄 — 기본 캘린더 줄만 locked(켠 채 막힌 칸, 줄은 보통 색)
      expect(checkRows(), findsNWidgets(3));
      final defaultRow = tester.widget<PListCheckItem>(
        find.ancestor(
          of: _defaultTitle(),
          matching: find.byType(PListCheckItem),
        ),
      );
      expect(defaultRow.locked, isTrue);
      expect(defaultRow.checked, isTrue);
      final normalRow = tester.widget<PListCheckItem>(
        find.ancestor(
          of: findPlain('회사캘린더'),
          matching: find.byType(PListCheckItem),
        ),
      );
      expect(normalRow.locked, isFalse);
      // 칸: 기본 줄 칸은 막혀 있고(enabled false) 일반 줄 칸은 눌린다
      final marks = tester
          .widgetList<PCheckmark>(find.byType(PCheckmark))
          .toList();
      expect(marks.first.enabled, isFalse);
      expect(marks.first.checked, isTrue);
      expect(marks[1].enabled, isTrue);
    });

    testWidgets("기본 캘린더 행에는 '기본' 표식이 붙는다", (tester) async {
      await pump(tester, calendars: const [_default, _normal]);
      await openFilterSheet(tester, count: 3);

      // 관리 화면·웹이 쓰는 것과 같은 배지 — 칸이 왜 막혔는지를 남긴다.
      expect(findText(l.calDefault), findsOneWidget);
    });

    testWidgets('체크는 앞 — 기본 줄도 체크 24 → 색 점 → 이름으로 일반 줄과 한 세로선에 선다', (
      tester,
    ) async {
      await pump(tester, calendars: const [_default, _normal]);
      await openFilterSheet(tester, count: 3);

      final checks = tester
          .widgetList<PCheckmark>(find.byType(PCheckmark))
          .length;
      expect(checks, 3);
      final checkRect = tester.getRect(find.byType(PCheckmark).first);
      final normalCheck = tester.getRect(find.byType(PCheckmark).at(1));
      expect(checkRect.width, 24);
      expect(checkRect.left, normalCheck.left, reason: '기본 줄 칸이 일반 줄 칸과 같은 자리');
      // 상자 없는 파란 체크 표식은 걷었다
      expect(
        find.byKey(const ValueKey('calendar-filter-default-mark')),
        findsNothing,
      );
      final normalTitle = tester.getTopLeft(findPlain('회사캘린더')).dx;
      final defaultTitle = tester.getTopLeft(_defaultTitle()).dx;
      expect(defaultTitle, normalTitle, reason: '기본 줄 이름이 체크 줄과 한 세로선');
    });

    testWidgets('구역 이름(내 캘린더 · 기타 소스)은 List Header 기본(mediumWeak) — 옅은 500', (
      tester,
    ) async {
      await pump(tester, calendars: const [_default, _normal]);
      await openFilterSheet(tester, count: 3);

      final titles = tester
          .widgetList<Text>(find.byKey(const ValueKey('plist-header-title')))
          .toList();
      expect(titles.length, 2);
      for (final t in titles) {
        expect(t.style?.fontWeight, FontWeight.w500);
        expect(t.style?.color, PColors.light.fgNeutralSubtle);
      }
    });

    testWidgets('일반 캘린더 행은 그대로 토글된다', (tester) async {
      final repo = await pump(tester, calendars: const [_default, _normal]);
      await openFilterSheet(tester, count: 3);

      await tester.tap(findPlain('회사캘린더'));
      await tester.pumpAndSettle();

      expect(repo.toggled, [2], reason: '일반 캘린더 토글까지 같이 죽었다');
    });

    testWidgets('기본 캘린더 행은 눌러도 토글이 안 나간다', (tester) async {
      final repo = await pump(tester, calendars: const [_default, _normal]);
      await openFilterSheet(tester, count: 3);

      await tester.tap(_defaultTitle(), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(repo.toggled, isEmpty, reason: '서버가 400 으로 막는 요청이 나갔다');
    });
  });

  group('기본 캘린더는 늘 보이는 것으로 취급된다', () {
    test('서버가 isVisible:false 로 내려도 보임이다', () {
      expect(_staleHiddenDefault.isVisible, isTrue);
      expect(isCalendarVisible(const [_staleHiddenDefault], 1), isTrue);
    });

    test('응답을 파싱해도 마찬가지다', () {
      final parsed = UserCalendar.fromJson(const {
        'rowId': 1,
        'calendarName': '기본캘린더',
        'isDefault': true,
        'isVisible': false,
      });

      expect(parsed.isVisible, isTrue);
    });

    test('기본이 아닌 캘린더의 숨김은 그대로 지켜진다', () {
      const hidden = UserCalendar(
        rowId: 2,
        calendarName: '회사캘린더',
        isVisible: false,
      );

      expect(hidden.isVisible, isFalse, reason: '숨기기 기능 자체가 죽었다');
      expect(isCalendarVisible(const [hidden], 2), isFalse);
    });

    testWidgets('숨김 값이 와도 그 일정이 월 그리드에 그려진다', (tester) async {
      await pump(tester, calendars: const [_staleHiddenDefault, _normal]);

      expect(
        findText('기본일정'),
        findsWidgets,
        reason: '되돌릴 스위치가 없는데 기본 캘린더 일정이 사라졌다',
      );
    });

    testWidgets('숨김 값이 와도 헤더 개수와 색 점에 든다', (tester) async {
      await pump(tester, calendars: const [_staleHiddenDefault, _normal]);

      // 기본 + 회사 + 공휴일 = 3. 기본이 빠지면 2 가 된다.
      expect(findText(l.calCalendarChipCount(3)), findsOneWidget);
    });

    testWidgets('숨김 값이 와도 필터 시트에서 켜진 것으로 보인다', (tester) async {
      await pump(tester, calendars: const [_staleHiddenDefault, _normal]);
      await openFilterSheet(tester, count: 3);

      // 꺼진 줄은 체크가 비어 보인다 — 기본 캘린더는 늘 켠 채 막힌 칸이다.
      final row = tester.widget<PListCheckItem>(
        find.ancestor(
          of: _defaultTitle(),
          matching: find.byType(PListCheckItem),
        ),
      );
      expect(row.checked, isTrue);
      expect(row.locked, isTrue);
    });
  });
}
