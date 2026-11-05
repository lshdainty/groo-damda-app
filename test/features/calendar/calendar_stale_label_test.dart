// 라벨을 고치거나 캘린더를 지워도 일정이 옛 모습 그대로였다 (QA #147).
//
// 일정 응답에는 라벨 이름·색이 **박혀서** 온다
// (`CalendarEvent.labelName`/`labelColor`). 그래서 라벨을 개명하거나 색을 바꾸면
// 라벨 목록(`eventLabelsProvider`)만 다시 받아서는 부족하다 — 이미 받아 둔 월
// 일정이 옛 이름·옛 색을 그대로 들고 있다. 그런데 라벨 CRUD 는 `eventLabels` 만,
// 캘린더 삭제는 `userCalendarList` 만 비웠다. `monthEventsProvider` 는 autoDispose
// 가 아니라 한 번 읽으면 남으므로, 달을 바꿔 다른 키로 넘어가기 전까지 옛 모습이
// 계속 보였다.
//
// 캘린더 삭제는 한 겹 더 있다 — 서버가 그 캘린더의 일정을 **기본 캘린더로
// 옮긴다**(`UserCalendarServiceImpl`). 다시 받지 않으면 없어진 캘린더 소속인 채로
// (색도 옛 캘린더 색으로) 남는다.
//
// 여기서 보는 건 "무효화 한 줄이 있다" 가 아니라 **실제로 다시 조회하는가** 다 —
// 리포지토리의 `events()` 호출 횟수로 센다.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/auth/auth_notifier.dart';
import 'package:groo_damda_app/core/auth/user.dart';
import 'package:groo_damda_app/features/calendar/application/calendar_providers.dart';
import 'package:groo_damda_app/features/calendar/data/calendar_repository.dart';
import 'package:groo_damda_app/features/calendar/data/user_calendar_repository.dart';
import 'package:groo_damda_app/features/calendar/domain/calendar_event.dart';
import 'package:groo_damda_app/features/calendar/domain/event_label.dart';
import 'package:groo_damda_app/features/calendar/domain/user_calendar.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_labels_screen.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_manage_screen.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart' as dsb;
import 'package:groo_damda_app/shared/widgets/p_button.dart';

import '../../support/plain_text.dart';

const _label = EventLabel(rowId: 7, labelName: '옛이름', color: '#2c70bf');
const _calendar = UserCalendar(rowId: 1, calendarName: '개인', isDefault: true);
const _deletable = UserCalendar(rowId: 5, calendarName: '회사캘린더');

/// 월 일정 조회 횟수를 센다 — 무효화가 **재조회로 이어지는지** 보는 자다.
class _CountingRepo extends CalendarRepository {
  _CountingRepo() : super(Dio());

  int eventCalls = 0;

  @override
  Future<List<CalendarEvent>> events({
    required String startDate,
    required String endDate,
  }) async {
    eventCalls++;
    return <CalendarEvent>[];
  }

  @override
  Future<List<EventLabel>> labels() async => const [_label];

  @override
  Future<EventLabel> updateLabel({
    required int id,
    required String labelName,
    String? color,
  }) async => EventLabel(rowId: id, labelName: labelName, color: color);

  @override
  Future<void> deleteLabel(int id) async {}
}

class _StubCalendarRepo extends UserCalendarRepository {
  _StubCalendarRepo() : super(Dio());

  int deleted = 0;

  @override
  Future<List<UserCalendar>> list() async => const [_calendar, _deletable];

  @override
  Future<List<CalendarMember>> members(int id) async =>
      const <CalendarMember>[];

  @override
  Future<void> delete(int id) async => deleted++;
}

/// 로그인 조회를 네트워크로 내보내지 않는다 — 관리 시트가 내 rowId 를 본다.
class _NoAuth extends AuthNotifier {
  @override
  Future<User?> build() async => null;
}

/// 텍스트를 품은 PButton — 확인 다이얼로그의 버튼과 스와이프 액션의 같은 글자를
/// 가른다(액션은 PButton 이 아니다).
Finder _button(String label) => find
    .ancestor(
      of: find.text(label),
      matching: find.byWidgetPredicate((w) => w is PButton || w is dsb.PButton),
    )
    .last;

/// 월 일정을 살려 두는 관찰자 + 대상 화면.
///
/// 무효화가 재조회로 이어지려면 듣는 쪽이 있어야 한다 — 실제 앱에서는 셸에
/// 상주하는 캘린더 화면이 그 역할이다.
Widget _harness(Widget screen, DateTime month) => MaterialApp.router(
  theme: GrooTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('ko'),
  // 관리 페이지는 지운 뒤 목록으로 돌아가므로 라우터가 필요하다
  routerConfig: GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(
          body: Column(
            children: [
              Consumer(
                builder: (_, ref, _) {
                  ref.watch(
                    monthEventsProvider((year: month.year, month: month.month)),
                  );
                  return const SizedBox.shrink();
                },
              ),
              Expanded(child: screen),
            ],
          ),
        ),
      ),
      GoRoute(
        path: '/settings/calendar-share',
        builder: (_, _) => const SizedBox(),
      ),
    ],
  ),
);

void main() {
  late AppLocalizations l;
  setUpAll(() async {
    l = await AppLocalizations.delegate.load(const Locale('ko'));
  });

  Future<_CountingRepo> pump(WidgetTester tester, Widget screen) async {
    final repo = _CountingRepo();
    // 시트 본문이 ListView 라 좁은 화면에서는 아래쪽 요소가 안 만들어진다.
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          calendarRepositoryProvider.overrideWith((ref) async => repo),
          userCalendarRepositoryProvider.overrideWith(
            (ref) async => _StubCalendarRepo(),
          ),
          authProvider.overrideWith(_NoAuth.new),
        ],
        child: _harness(screen, DateTime.now()),
      ),
    );
    await tester.pumpAndSettle();
    expect(repo.eventCalls, 1, reason: '첫 조회 한 번');
    return repo;
  }

  group('라벨', () {
    testWidgets('이름을 바꾸면 월 일정을 다시 받는다', (tester) async {
      final repo = await pump(tester, const CalendarLabelsScreen());
      expect(findPlain('옛이름'), findsWidgets);

      await tester.tap(findPlain('옛이름').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), '새이름');
      await tester.pumpAndSettle();
      await tester.tap(_button(l.actionSave));
      await tester.pumpAndSettle();

      expect(repo.eventCalls, 2, reason: '라벨 이름이 박힌 월 일정을 다시 받아야 한다');
    });

    testWidgets('지우면 월 일정을 다시 받는다', (tester) async {
      final repo = await pump(tester, const CalendarLabelsScreen());

      // 행을 밀어 삭제 액션을 꺼낸다 → 확인 다이얼로그.
      await tester.drag(findPlain('옛이름').first, const Offset(-250, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.actionDelete).first);
      await tester.pumpAndSettle();
      await tester.tap(_button(l.actionDelete));
      await tester.pumpAndSettle();

      expect(repo.eventCalls, 2, reason: '없어진 라벨이 박힌 채로 남으면 안 된다');
    });
  });

  testWidgets('캘린더를 지우면 월 일정을 다시 받는다', (tester) async {
    // 관리 페이지의 "캘린더 삭제" 줄(I-09b 29)
    final repo = await pump(
      tester,
      CalendarManageScreen(calendarId: _deletable.rowId),
    );

    await tester.tap(findPlain(l.calDeleteCalendar));
    await tester.pumpAndSettle();
    await tester.tap(_button(l.actionDelete));
    await tester.pumpAndSettle();

    expect(repo.eventCalls, 2, reason: '옮겨진 일정을 다시 받아야 한다');
  });
}
