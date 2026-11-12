// I-09b 09b-2 — 캘린더 관리 페이지(21 ~ 31) · 새 캘린더 · 초대 코드 참여(34 ~ 37) · 라벨 폼(39 ~ 41).
// 작성만 했다(실행하지 않음).
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/auth/auth_notifier.dart';
import 'package:groo_damda_app/core/auth/user.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/features/calendar/application/calendar_providers.dart';
import 'package:groo_damda_app/features/calendar/data/user_calendar_repository.dart';
import 'package:groo_damda_app/features/calendar/domain/user_calendar.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_manage_forms.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_manage_screen.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/avatar/p_avatar.dart';
import 'package:groo_damda_app/shared/ds/badge/p_badge.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';

import '../../support/plain_text.dart';

class _NoAuth extends AuthNotifier {
  @override
  Future<User?> build() async => null;
}

class _Repo extends UserCalendarRepository {
  _Repo() : super(Dio());

  String? joinError;
  String? lastUpdateName;
  String? lastUpdateColor;
  int joins = 0;
  int deletes = 0;
  int roleChanges = 0;
  int stops = 0;

  @override
  Future<void> stopSharing(int id) async => stops++;

  @override
  Future<List<CalendarMember>> members(int id) async => const [
    CalendarMember(rowId: 1, userRowId: 10, userName: '나', permission: 'OWNER'),
    CalendarMember(
      rowId: 2,
      userRowId: 11,
      userName: '아주긴이름을가진가족구성원',
      userEmail: 'very.long.family.member.address@example.com',
      permission: 'EDIT',
    ),
    CalendarMember(
      rowId: 3,
      userRowId: 12,
      userName: '읽는이',
      permission: 'READ',
    ),
  ];

  @override
  Future<void> delete(int id) async => deletes++;

  @override
  Future<void> changeMemberRole(
    int id,
    int memberId,
    String permission,
  ) async => roleChanges++;

  @override
  Future<UserCalendar> update({
    required int id,
    String? calendarName,
    String? color,
    bool silent = false,
  }) async {
    lastUpdateName = calendarName;
    lastUpdateColor = color;
    return UserCalendar(rowId: id, calendarName: calendarName ?? '');
  }

  @override
  Future<UserCalendar> joinByCode(String inviteCode) async {
    joins++;
    if (joinError != null) {
      throw ApiException(code: joinError!, message: '서버 원문', statusCode: 404);
    }
    return const UserCalendar(rowId: 9, calendarName: '독서 모임');
  }
}

void main() {
  const owned = UserCalendar(
    rowId: 2,
    calendarName: '가족 일정',
    color: '#2d8060',
    inviteCode: '3F9A1C2B',
    memberCount: 3,
  );
  const dflt = UserCalendar(rowId: 1, calendarName: '기본 캘린더', isDefault: true);
  const shared = UserCalendar(
    rowId: 3,
    calendarName: '독서 모임',
    isOwner: false,
    myRole: 'READ',
    memberCount: 3,
  );

  Widget app(Widget home, _Repo repo, {List<UserCalendar>? list}) =>
      ProviderScope(
        overrides: <Override>[
          authProvider.overrideWith(_NoAuth.new),
          userCalendarRepositoryProvider.overrideWith((ref) async => repo),
          userCalendarListProvider.overrideWith(
            (ref) async => list ?? const [dflt, owned, shared],
          ),
        ],
        child: MaterialApp.router(
          theme: GrooTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          builder: (c, child) => PSnackbarHost(closeLabel: '닫기', child: child!),
          routerConfig: GoRouter(
            routes: [
              GoRoute(path: '/', builder: (_, _) => home),
              GoRoute(
                path: '/settings/calendar-share',
                builder: (_, _) => const Text('목록'),
              ),
            ],
          ),
        ),
      );

  Future<void> size(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  group('관리 페이지', () {
    testWidgets(
      '공유 켜짐 — 32자 코드 · [복사] · [새로 만들기] · [끄기], 끄기를 누르면 서버로 간다(DAM-4)',
      (tester) async {
        await size(tester);
        final repo = _Repo();
        const code = '0123456789ABCDEF0123456789ABCDEF';
        await tester.pumpWidget(
          app(
            const CalendarManageScreen(calendarId: 2),
            repo,
            list: const [
              dflt,
              UserCalendar(
                rowId: 2,
                calendarName: '가족 일정',
                inviteCode: code,
                memberCount: 3,
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();
        expect(findText(code), findsOneWidget);
        expect(findText('복사'), findsOneWidget);
        expect(findText('새로 만들기'), findsOneWidget);
        await tester.tap(findText('끄기'));
        await tester.pumpAndSettle();
        expect(repo.stops, 1);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('공유 꺼짐(코드 없음) — "공유 꺼짐" 과 [만들기] 만, [복사] · [끄기] 는 없다(DAM-4)', (
      tester,
    ) async {
      await size(tester);
      await tester.pumpWidget(
        app(
          const CalendarManageScreen(calendarId: 2),
          _Repo(),
          list: const [
            dflt,
            UserCalendar(rowId: 2, calendarName: '가족 일정', memberCount: 1),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(findPlain('공유 꺼짐'), findsOneWidget);
      expect(findText('만들기'), findsOneWidget);
      expect(findText('복사'), findsNothing);
      expect(findText('끄기'), findsNothing);
    });

    testWidgets('소유자 — 이름 · 색상 줄 · 초대 코드 · 멤버 아바타 + 권한 배지 · 삭제 줄', (
      tester,
    ) async {
      await size(tester);
      await tester.pumpWidget(
        app(const CalendarManageScreen(calendarId: 2), _Repo()),
      );
      await tester.pumpAndSettle();
      expect(findPlain('이름'), findsOneWidget);
      expect(findPlain('색상'), findsOneWidget);
      expect(findText('3F9A1C2B'), findsOneWidget);
      expect(find.byType(PAvatar), findsNWidgets(3));
      expect(find.byType(PBadge), findsNWidgets(3));
      expect(findPlain('캘린더 삭제'), findsOneWidget);
      expect(findRichText('초대 코드'), findsOneWidget);
      expect(findText('복사'), findsOneWidget);
      // 줄 끝 ⋮ 는 없다 — 내보낼 수 있는 멤버 줄은 누르는 줄이다
      expect(find.byIcon(LucideIcons.ellipsisVertical), findsNothing);
    });

    testWidgets('기본 캘린더 — 삭제 줄이 없다', (tester) async {
      await size(tester);
      await tester.pumpWidget(
        app(const CalendarManageScreen(calendarId: 1), _Repo()),
      );
      await tester.pumpAndSettle();
      expect(findPlain('캘린더 삭제'), findsNothing);
    });

    testWidgets('공유받은 캘린더 — 멤버만, 이름 · 색 · 초대 코드 · 삭제 없음', (tester) async {
      await size(tester);
      await tester.pumpWidget(
        app(const CalendarManageScreen(calendarId: 3), _Repo()),
      );
      await tester.pumpAndSettle();
      expect(findPlain('이름'), findsNothing);
      expect(findRichText('초대 코드'), findsNothing);
      expect(findPlain('캘린더 삭제'), findsNothing);
      expect(find.byType(PAvatar), findsNWidgets(3));
    });

    testWidgets('틀린 주소 — 부모(목록)로 돌아간다', (tester) async {
      await size(tester);
      await tester.pumpWidget(
        app(const CalendarManageScreen(calendarId: 99999), _Repo()),
      );
      await tester.pumpAndSettle();
      expect(findText('목록'), findsOneWidget);
    });

    testWidgets('이름 줄 → 이름 폼 → 이름만 보낸다', (tester) async {
      await size(tester);
      final repo = _Repo();
      await tester.pumpWidget(
        app(const CalendarManageScreen(calendarId: 2), repo),
      );
      await tester.pumpAndSettle();
      await tester.tap(findPlain('이름'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), '새 이름');
      await tester.tap(findText('저장'));
      await tester.pumpAndSettle();
      expect(repo.lastUpdateName, '새 이름');
      expect(repo.lastUpdateColor, isNull);
    });

    testWidgets('이름을 비우고 저장 — 칸 아래 오류(버튼은 켜 둔다)', (tester) async {
      await size(tester);
      final repo = _Repo();
      await tester.pumpWidget(
        app(const CalendarManageScreen(calendarId: 2), repo),
      );
      await tester.pumpAndSettle();
      await tester.tap(findPlain('이름'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), '');
      await tester.tap(findText('저장'));
      await tester.pumpAndSettle();
      expect(findPlain('캘린더 이름을 입력해주세요.'), findsOneWidget);
      expect(repo.lastUpdateName, isNull);
    });
  });

  group('관리 페이지 — 검수 반영', () {
    testWidgets('멤버 줄은 소유자에게만 누르는 줄 — 누르면 Menu Sheet, 권한 바꾸기는 요청이 나간다', (
      tester,
    ) async {
      await size(tester);
      final repo = _Repo();
      await tester.pumpWidget(
        app(const CalendarManageScreen(calendarId: 2), repo),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('cal-member-3')));
      await tester.pumpAndSettle();
      expect(findPlain('편집 가능으로'), findsOneWidget);
      await tester.tap(findPlain('편집 가능으로'));
      await tester.pumpAndSettle();
      expect(repo.roleChanges, 1);
    });

    testWidgets('공유받은 캘린더의 멤버 줄은 누르지 못한다', (tester) async {
      await size(tester);
      await tester.pumpWidget(
        app(const CalendarManageScreen(calendarId: 3), _Repo()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('cal-member-3')));
      await tester.pumpAndSettle();
      expect(findPlain('편집 가능으로'), findsNothing);
    });

    testWidgets('캘린더를 지우면 이 페이지 하나만 닫힌다(목록은 남는다)', (tester) async {
      await size(tester);
      final repo = _Repo();
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Text('설정'),
            routes: [
              GoRoute(
                path: 'list',
                builder: (_, _) => const Text('목록'),
                routes: [
                  GoRoute(
                    path: 'manage',
                    builder: (_, _) =>
                        const CalendarManageScreen(calendarId: 2),
                  ),
                ],
              ),
            ],
          ),
        ],
        initialLocation: '/list/manage',
      );
      // 목록 값이 지운 직후 바로 다시 받아진다 — 두 번 닫히던 자리
      var calls = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            authProvider.overrideWith(_NoAuth.new),
            userCalendarRepositoryProvider.overrideWith((ref) async => repo),
            userCalendarListProvider.overrideWith(
              (ref) async => calls++ == 0 ? const [dflt, owned] : const [dflt],
            ),
          ],
          child: MaterialApp.router(
            theme: GrooTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            builder: (c, child) =>
                PSnackbarHost(closeLabel: '닫기', child: child!),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(findPlain('캘린더 삭제'));
      await tester.pumpAndSettle();
      await tester.tap(findText('삭제').last);
      await tester.pumpAndSettle();
      expect(repo.deletes, 1);
      expect(findText('목록'), findsOneWidget);
      expect(findText('설정'), findsNothing);
    });
  });

  group('초대 코드 참여', () {
    Future<void> open(WidgetTester tester, _Repo repo) async {
      await size(tester);
      await tester.pumpWidget(
        app(
          Builder(
            builder: (c) => TextButton(
              onPressed: () => showCalendarJoinSheet(c),
              child: const Text('열기'),
            ),
          ),
          repo,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(findText('열기'));
      await tester.pumpAndSettle();
    }

    testWidgets('빈 칸으로 참여 — 칸 아래 "초대 코드를 입력해주세요."', (tester) async {
      final repo = _Repo();
      await open(tester, repo);
      await tester.tap(findText('참여').last);
      await tester.pumpAndSettle();
      expect(findPlain('초대 코드를 입력해주세요.'), findsOneWidget);
      expect(repo.joins, 0);
    });

    testWidgets('틀린 코드 — 칸 아래 오류, 서버 글 0', (tester) async {
      final repo = _Repo()..joinError = 'CAL_012';
      await open(tester, repo);
      await tester.enterText(find.byType(EditableText), 'zzzz');
      await tester.tap(findText('참여').last);
      await tester.pumpAndSettle();
      expect(findPlain('초대 코드를 확인해주세요.'), findsOneWidget);
      expect(findTextContaining('서버 원문'), findsNothing);
    });

    testWidgets('이미 참여 — 칸 아래 오류', (tester) async {
      final repo = _Repo()..joinError = 'CAL_011';
      await open(tester, repo);
      await tester.enterText(find.byType(EditableText), '3f9a1c2b');
      await tester.tap(findText('참여').last);
      await tester.pumpAndSettle();
      expect(findPlain('이미 참여한 캘린더예요.'), findsOneWidget);
    });

    testWidgets('붙여 넣은 공백 · 하이픈은 거르고 영문 · 숫자 32자만 받는다(DAM-4)', (tester) async {
      await open(tester, _Repo());
      await tester.enterText(
        find.byType(EditableText),
        '0123 4567-89ab cdef!0123456789abcdef99',
      );
      final text = tester
          .widget<EditableText>(find.byType(EditableText))
          .controller
          .text;
      expect(text, '0123456789abcdef0123456789abcdef');
    });

    testWidgets('틀린 시도 한도(CAL_017) — 칸 아래 "잠시 뒤 다시"', (tester) async {
      final repo = _Repo()..joinError = 'CAL_017';
      await open(tester, repo);
      await tester.enterText(
        find.byType(EditableText),
        '0123456789ABCDEF0123456789ABCDEF',
      );
      await tester.tap(findText('참여').last);
      await tester.pumpAndSettle();
      expect(
        findPlain('초대 코드를 너무 많이 잘못 입력했어요. 잠시 뒤 다시 시도해주세요.'),
        findsOneWidget,
      );
    });

    testWidgets('성공 — 시트가 닫히고 스낵바', (tester) async {
      final repo = _Repo();
      await open(tester, repo);
      await tester.enterText(find.byType(EditableText), '3F9A1C2B');
      await tester.tap(findText('참여').last);
      await tester.pumpAndSettle();
      expect(repo.joins, 1);
      expect(findPlain('"독서 모임" 캘린더에 참여했어요.'), findsOneWidget);
    });
  });
}
