// I-09 09-3 관리 · 공유(37 ~ 43) · 라벨(44 ~ 49) — 흰 면 하나, 안내는 Callout, 실패는 원문 없이 Result Section,
// 다시 받기 실패는 받아 둔 목록을 남기고, 라벨 삭제는 편집 시트 바닥 [삭제] 로도 닿고 실패는 고정 한 문장 + [다시 시도].
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/auth/auth_notifier.dart';
import 'package:groo_damda_app/core/auth/user.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/features/calendar/application/calendar_providers.dart';
import 'package:groo_damda_app/features/calendar/data/calendar_repository.dart';
import 'package:groo_damda_app/features/calendar/data/user_calendar_repository.dart';
import 'package:groo_damda_app/features/calendar/domain/calendar_event.dart';
import 'package:groo_damda_app/features/calendar/domain/event_label.dart';
import 'package:groo_damda_app/features/calendar/domain/user_calendar.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_labels_screen.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_share_screen.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/callout/p_callout.dart';
import 'package:groo_damda_app/shared/ds/list/list_row.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import 'package:groo_damda_app/shared/widgets/p_card.dart';
import 'package:groo_damda_app/shared/widgets/p_divider.dart';

import '../../support/plain_text.dart';

class _NoAuth extends AuthNotifier {
  @override
  Future<User?> build() async => null;
}

class _CalendarRepo extends UserCalendarRepository {
  _CalendarRepo() : super(Dio());

  @override
  Future<List<CalendarMember>> members(int id) async =>
      const <CalendarMember>[];
}

/// 라벨 삭제 호출 수를 센다 — [failDelete] 면 던진다(서버 글이 실려 있다).
class _LabelRepo extends CalendarRepository {
  _LabelRepo(this.labelList) : super(Dio());

  final List<EventLabel> labelList;
  int deletes = 0;
  bool failDelete = false;

  @override
  Future<List<EventLabel>> labels() async => labelList;

  @override
  Future<List<CalendarEvent>> events({
    required String startDate,
    required String endDate,
  }) async => <CalendarEvent>[];

  @override
  Future<void> deleteLabel(int id) async {
    deletes++;
    if (failDelete) {
      throw ApiException(code: 'X', message: '서버가 낸 원문 글', statusCode: 500);
    }
  }
}

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
    overrides: [
      authProvider.overrideWith(_NoAuth.new),
      userCalendarRepositoryProvider.overrideWith(
        (ref) async => _CalendarRepo(),
      ),
      ...overrides,
    ],
    child: MaterialApp(
      theme: GrooTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      builder: (c, child) => PSnackbarHost(closeLabel: '닫기', child: child!),
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
    });

    testWidgets('긴 이름은 말줄임 없이 줄바꿈된다', (tester) async {
      await size(tester);
      await tester.pumpWidget(
        app(const CalendarShareScreen(), [
          userCalendarListProvider.overrideWith((ref) async => const [family]),
        ]),
      );
      await tester.pumpAndSettle();
      final title = find.descendant(
        of: find.byKey(const ValueKey('cal-share-2')),
        matching: find.byKey(const ValueKey('plist-title')),
      );
      final p = tester.renderObject<RenderParagraph>(title.first);
      expect(p.maxLines, isNull);
      expect(p.overflow, isNot(TextOverflow.ellipsis));
      expect(p.didExceedMaxLines, isFalse);
      // 한 줄이 아니다 — 29자 이름이 두 줄 이상으로 풀린다
      expect(p.size.height, greaterThan(40));
      expect(tester.takeException(), isNull);
    });

    testWidgets('묶음 사이는 목록 제목 위 24 — 앞 줄 끝 ↔ 제목 사이가 8 이 아니다', (tester) async {
      await size(tester);
      await tester.pumpWidget(
        app(const CalendarShareScreen(), [
          userCalendarListProvider.overrideWith(
            (ref) async => const [mine, editable],
          ),
        ]),
      );
      await tester.pumpAndSettle();
      final row = tester.getRect(find.byKey(const ValueKey('cal-share-1')));
      final head = tester.getRect(
        find.byKey(const ValueKey('plist-header')).at(1),
      );
      // 내 캘린더 줄 아래 ↔ "공유받은 캘린더" 머리 위: 24 (머리 위 여백)
      expect(head.top - row.bottom, 24);
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

    testWidgets('실패 — Result Section 하나 · 원문 0 · 다시 시도는 그 질의만', (tester) async {
      await size(tester);
      var calendarCalls = 0;
      var labelCalls = 0;
      await tester.pumpWidget(
        app(
          Consumer(
            builder: (_, ref, _) {
              // 다른 질의를 함께 들고 있다 — 다시 시도가 이쪽을 건드리지 않아야 한다
              ref.watch(eventLabelsProvider);
              return const CalendarShareScreen();
            },
          ),
          [
            userCalendarListProvider.overrideWith((ref) async {
              calendarCalls++;
              throw StateError('서버가 낸 원문 오류');
            }),
            eventLabelsProvider.overrideWith((ref) async {
              labelCalls++;
              return const <EventLabel>[];
            }),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PResultSection), findsOneWidget);
      expect(find.textContaining('서버가 낸 원문'), findsNothing);
      expect(find.textContaining('StateError'), findsNothing);
      final before = (calendarCalls, labelCalls);
      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();
      expect(calendarCalls, before.$1 + 1);
      expect(labelCalls, before.$2);
    });

    testWidgets('다시 받기가 실패해도 받아 둔 목록이 남는다', (tester) async {
      await size(tester);
      var fail = false;
      await tester.pumpWidget(
        app(const CalendarShareScreen(), [
          userCalendarListProvider.overrideWith((ref) async {
            if (fail) throw StateError('끊김');
            return const [mine, editable];
          }),
        ]),
      );
      await tester.pumpAndSettle();
      expect(findRichPlain('가족'), findsOneWidget);
      fail = true;
      ProviderScope.containerOf(
        tester.element(find.byType(CalendarShareScreen)),
      ).invalidate(userCalendarListProvider);
      await tester.pumpAndSettle();
      expect(find.byType(PResultSection), findsNothing);
      expect(findRichPlain('가족'), findsOneWidget);
    });

    testWidgets('불러오는 중에도 "캘린더 추가" 글 단추가 있다', (tester) async {
      await size(tester);
      await tester.pumpWidget(
        app(const CalendarShareScreen(), [
          userCalendarListProvider.overrideWith(
            (ref) => Future<List<UserCalendar>>.delayed(
              const Duration(seconds: 30),
              () => const <UserCalendar>[],
            ),
          ),
        ]),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('캘린더 추가'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 31));
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
      await tester.tap(find.byKey(const ValueKey('cal-share-1')));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
    });
  });

  group('라벨', () {
    const labels = [
      EventLabel(rowId: 1, labelName: '가족 행사·경조사 모임', color: '#2d8060'),
      EventLabel(rowId: 2, labelName: '출장', color: '#8b4dba'),
    ];

    List<Override> withRepo(_LabelRepo repo) => [
      calendarRepositoryProvider.overrideWith((ref) async => repo),
      eventLabelsProvider.overrideWith((ref) async => repo.labelList),
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

    testWidgets('빈 상태 — R9 한 줄 + 힌트(Result Section 아님)', (tester) async {
      await size(tester);
      await tester.pumpWidget(
        app(const CalendarLabelsScreen(), [
          eventLabelsProvider.overrideWith((ref) async => const []),
        ]),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PResultSection), findsNothing);
      expect(findPlain('라벨이 없어요'), findsOneWidget);
      expect(findPlain("위 '라벨 추가' 로 만들어요"), findsOneWidget);
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

    testWidgets('다시 받기가 실패해도 받아 둔 라벨이 남는다', (tester) async {
      await size(tester);
      var fail = false;
      await tester.pumpWidget(
        app(const CalendarLabelsScreen(), [
          eventLabelsProvider.overrideWith((ref) async {
            if (fail) throw StateError('끊김');
            return labels;
          }),
        ]),
      );
      await tester.pumpAndSettle();
      expect(findPlain('출장'), findsOneWidget);
      fail = true;
      ProviderScope.containerOf(
        tester.element(find.byType(CalendarLabelsScreen)),
      ).invalidate(eventLabelsProvider);
      await tester.pumpAndSettle();
      expect(find.byType(PResultSection), findsNothing);
      expect(findPlain('출장'), findsOneWidget);
    });

    testWidgets('줄은 누르는 줄이고 밀기 둘(수정 · 삭제)이 남는다', (tester) async {
      await size(tester);
      final repo = _LabelRepo(labels);
      await tester.pumpWidget(
        app(const CalendarLabelsScreen(), withRepo(repo)),
      );
      await tester.pumpAndSettle();
      await tester.drag(findPlain('출장').first, const Offset(-250, 0));
      await tester.pumpAndSettle();
      expect(find.text('수정'), findsWidgets);
      expect(find.text('삭제'), findsWidgets);
    });

    testWidgets('편집 시트 바닥에 [삭제] — 수정 폼에만, 추가 폼에는 없다', (tester) async {
      await size(tester);
      final repo = _LabelRepo(labels);
      await tester.pumpWidget(
        app(const CalendarLabelsScreen(), withRepo(repo)),
      );
      await tester.pumpAndSettle();
      await tester.tap(findPlain('출장').first);
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('삭제'), findsOneWidget);

      // 추가 폼
      await tester.pumpWidget(
        app(const CalendarLabelsScreen(), withRepo(repo)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('라벨 추가'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('삭제'), findsNothing);
    });

    testWidgets('[삭제] → 확인창 → 지움 — 시트가 닫히고 라벨을 다시 받는다', (tester) async {
      await size(tester);
      final repo = _LabelRepo(labels);
      await tester.pumpWidget(
        app(const CalendarLabelsScreen(), withRepo(repo)),
      );
      await tester.pumpAndSettle();
      await tester.tap(findPlain('출장').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('삭제').last);
      await tester.pumpAndSettle();
      // 확인창의 [삭제]
      await tester.tap(find.text('삭제').last);
      await tester.pumpAndSettle();
      expect(repo.deletes, 1);
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('삭제 실패 — 고정 한 문장 + [다시 시도](바로 다시 요청) · 서버 글 0', (tester) async {
      await size(tester);
      final repo = _LabelRepo(labels)..failDelete = true;
      await tester.pumpWidget(
        app(const CalendarLabelsScreen(), withRepo(repo)),
      );
      await tester.pumpAndSettle();
      await tester.tap(findPlain('출장').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('삭제').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('삭제').last);
      await tester.pumpAndSettle();
      expect(repo.deletes, 1);
      expect(find.text('라벨을 삭제하지 못했어요.'), findsOneWidget);
      expect(find.textContaining('서버가 낸 원문'), findsNothing);
      // 확인창은 닫혀 있고, [다시 시도] 는 묻지 않고 바로 요청한다
      repo.failDelete = false;
      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();
      expect(repo.deletes, 2);
    });

    testWidgets('이름 칸 — 세는 줄 n/12 · 12자는 저장 가능 · 13째 글자는 입력되지 않는다', (
      tester,
    ) async {
      await size(tester);
      final repo = _LabelRepo(labels);
      await tester.pumpWidget(
        app(const CalendarLabelsScreen(), withRepo(repo)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('라벨 추가'));
      await tester.pumpAndSettle();
      expect(find.text('0/12'), findsOneWidget);
      await tester.enterText(find.byType(EditableText), '가나다라마바사아자차카타');
      await tester.pumpAndSettle();
      expect(find.text('12/12'), findsOneWidget);
      // 13자를 넣어도 12 에서 멈춘다
      await tester.enterText(find.byType(EditableText), '가나다라마바사아자차카타파');
      await tester.pumpAndSettle();
      expect(find.text('12/12'), findsOneWidget);
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        '가나다라마바사아자차카타',
      );
    });

    testWidgets('12자를 넘긴 옛 이름 — 칸 오류 "이름은 12자 이내로 입력해주세요." 가 보인다', (
      tester,
    ) async {
      await size(tester);
      const long = EventLabel(
        rowId: 9,
        labelName: '가나다라마바사아자차카타파',
        color: '#2d8060',
      );
      final repo = _LabelRepo(const [long]);
      await tester.pumpWidget(
        app(const CalendarLabelsScreen(), withRepo(repo)),
      );
      await tester.pumpAndSettle();
      await tester.tap(findPlain('가나다라마바사아자차카타파').first);
      await tester.pumpAndSettle();
      expect(find.text('이름은 12자 이내로 입력해주세요.'), findsOneWidget);
    });
  });
}
