// I-09 09-3 관리 · 공유(37 ~ 43) · 라벨(44 ~ 49) — 흰 면 하나, 안내는 Callout, 실패는 원문 없이 Result Section.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/calendar/application/calendar_providers.dart';
import 'package:groo_damda_app/features/calendar/domain/event_label.dart';
import 'package:groo_damda_app/features/calendar/domain/user_calendar.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_labels_screen.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_share_screen.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/callout/p_callout.dart';
import 'package:groo_damda_app/shared/ds/list/list_row.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/widgets/p_card.dart';
import 'package:groo_damda_app/shared/widgets/p_divider.dart';

import '../../support/plain_text.dart';

void main() {
  const mine = UserCalendar(rowId: 1, calendarName: '개인', isDefault: true);
  const family = UserCalendar(
    rowId: 2,
    calendarName: '동호회 · 주말 등산 모임 아주 긴 이름의 공유 캘린더',
    isOwner: false,
    myRole: 'READ',
    memberCount: 4,
  );
  const editable = UserCalendar(
    rowId: 3,
    calendarName: '가족',
    isOwner: false,
    myRole: 'EDIT',
    memberCount: 3,
  );

  Widget app(Widget screen, List<Override> overrides) => ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: GrooTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      home: screen,
    ),
  );

  Future<void> size(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  group('관리 · 공유', () {
    testWidgets('흰 면 하나 — Callout 한 문장 · 카드 0 · 줄 사이 선 0 · 배지', (tester) async {
      await size(tester);
      await tester.pumpWidget(
        app(const CalendarShareScreen(), [
          userCalendarListProvider.overrideWith(
            (ref) async => const [mine, family, editable],
          ),
        ]),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PCallout), findsOneWidget);
      expect(find.byType(PCard), findsNothing);
      expect(find.byType(PDivider), findsNothing);
      expect(
        findRichPlain('캘린더를 만들고 멤버를 초대해 가족 · 친구와 함께 일정을 관리해요.'),
        findsOneWidget,
      );
      expect(findRichText('내 캘린더 · 1'), findsOneWidget);
      expect(findRichText('공유받은 캘린더 · 2'), findsOneWidget);
      expect(findRichText('초대 코드'), findsOneWidget);
      expect(findRichPlain('기본'), findsWidgets);
      expect(findRichPlain('읽기 전용'), findsOneWidget);
      expect(findRichPlain('편집 가능'), findsOneWidget);
      // 긴 이름이 말줄임 없이 줄바꿈된다
      expect(tester.takeException(), isNull);
    });

    testWidgets('빈 목록은 해요체 한 줄', (tester) async {
      await size(tester);
      await tester.pumpWidget(
        app(const CalendarShareScreen(), [
          userCalendarListProvider.overrideWith((ref) async => const []),
        ]),
      );
      await tester.pumpAndSettle();
      expect(findPlain('소유한 캘린더가 없어요'), findsOneWidget);
      expect(findPlain('공유받은 캘린더가 없어요'), findsOneWidget);
    });

    testWidgets('실패 — Result Section 하나 · 원문 0 · 다시 시도가 그 질의만', (tester) async {
      await size(tester);
      var calls = 0;
      await tester.pumpWidget(
        app(const CalendarShareScreen(), [
          userCalendarListProvider.overrideWith((ref) async {
            calls++;
            throw StateError('서버가 낸 원문 오류');
          }),
        ]),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PResultSection), findsOneWidget);
      expect(find.textContaining('서버가 낸 원문'), findsNothing);
      expect(find.textContaining('StateError'), findsNothing);
      final before = calls;
      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();
      expect(calls, greaterThan(before));
    });

    testWidgets('캘린더 줄은 누르는 줄 — 지금의 관리 시트가 열린다', (tester) async {
      await size(tester);
      await tester.pumpWidget(
        app(const CalendarShareScreen(), [
          userCalendarListProvider.overrideWith((ref) async => const [mine]),
        ]),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PListRowFrame), findsWidgets);
      await tester.tap(findPlain('개인').first);
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
    });
  });

  group('라벨', () {
    const labels = [
      EventLabel(rowId: 1, labelName: '가족 행사·경조사 모임', color: '#2d8060'),
      EventLabel(rowId: 2, labelName: '출장', color: '#8b4dba'),
    ];

    testWidgets('Callout · 목록 제목 · 줄 — 카드 0 · 선 0', (tester) async {
      await size(tester);
      await tester.pumpWidget(
        app(const CalendarLabelsScreen(), [
          eventLabelsProvider.overrideWith((ref) async => labels),
        ]),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PCallout), findsOneWidget);
      expect(find.byType(PCard), findsNothing);
      expect(find.byType(PDivider), findsNothing);
      expect(findRichText('전체 라벨 · 2'), findsOneWidget);
      expect(findPlain('라벨 추가'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('빈 상태 — 라벨이 없어요 + 안내', (tester) async {
      await size(tester);
      await tester.pumpWidget(
        app(const CalendarLabelsScreen(), [
          eventLabelsProvider.overrideWith((ref) async => const []),
        ]),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PResultSection), findsOneWidget);
      expect(findPlain('라벨이 없어요'), findsOneWidget);
    });

    testWidgets('실패 — 원문 0 · 다시 시도', (tester) async {
      await size(tester);
      await tester.pumpWidget(
        app(const CalendarLabelsScreen(), [
          eventLabelsProvider.overrideWith((ref) async {
            throw StateError('서버가 낸 원문 오류');
          }),
        ]),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PResultSection), findsOneWidget);
      expect(find.textContaining('서버가 낸 원문'), findsNothing);
      expect(find.text('다시 시도'), findsOneWidget);
    });
  });
}
