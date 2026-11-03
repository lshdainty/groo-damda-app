// I-09 09-2 앱 — 일정 폼 시트의 흐름: 칸 오류 · 닫기 물음 · 한 단계 · 고르기 · 저장 실패 · 삭제 · 달 비우기 · 200% (줄 21 ~ 30).
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart' show HitTestResult;
import 'package:flutter/rendering.dart' show RenderBox, RenderPointerListener;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/network/patch.dart';
import 'package:groo_damda_app/features/calendar/application/calendar_providers.dart';
import 'package:groo_damda_app/features/calendar/data/calendar_repository.dart';
import 'package:groo_damda_app/features/calendar/domain/calendar_event.dart';
import 'package:groo_damda_app/features/calendar/domain/user_calendar.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/callout/p_callout.dart';
import 'package:groo_damda_app/shared/ds/date_picker/p_date_picker.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/forms/picker_row.dart';

import 'support/event_form_support.dart';

class _Repo extends CalendarRepository {
  _Repo() : super(Dio());

  int creates = 0;
  int updates = 0;
  int deletes = 0;
  bool fail = false;
  Map<String, Object?>? lastCreate;
  Map<String, Object?>? lastUpdate;

  CalendarEvent _fake() => CalendarEvent.fromJson(_event(rrule: null));

  @override
  Future<CalendarEvent> createEvent({
    required String title,
    String? description,
    String? eventType,
    String? color,
    int? calendarRowId,
    required String startDate,
    required String endDate,
    bool isAllDay = false,
    int? labelRowId,
    String? location,
    String? rrule,
    List<int>? reminderMinutes,
  }) async {
    if (fail) throw ApiException(code: 'X', message: 'Server error');
    creates++;
    lastCreate = {
      'title': title,
      'startDate': startDate,
      'endDate': endDate,
      'isAllDay': isAllDay,
      'location': location,
      'description': description,
    };
    return _fake();
  }

  @override
  Future<CalendarEvent> updateEvent({
    required int id,
    required String title,
    Patch<String> description = const Patch.keep(),
    String? eventType,
    String? color,
    int? calendarRowId,
    required String startDate,
    required String endDate,
    bool isAllDay = false,
    Patch<int> labelRowId = const Patch.keep(),
    Patch<String> location = const Patch.keep(),
    Patch<String> rrule = const Patch.keep(),
    List<int>? reminderMinutes,
    String? occurrenceStartDate,
  }) async {
    if (fail) throw ApiException(code: 'X', message: 'Server error');
    updates++;
    lastUpdate = {'startDate': startDate, 'endDate': endDate};
    return _fake();
  }

  @override
  Future<void> deleteEvent(int id) async {
    if (fail) throw ApiException(code: 'X', message: 'Server error');
    deletes++;
  }
}

Map<String, dynamic> _event({String? rrule}) => {
  'rowId': 42,
  'title': '주간 회의',
  'eventType': 'WORK',
  'startDate': '2026-10-24T10:00:00',
  'endDate': '2026-10-24T11:00:00',
  'isAllDay': 'N',
  'calendarRowId': 1,
  'rrule': ?rrule,
};

const _oct = (year: 2026, month: 10);
const _nov = (year: 2026, month: 11);

void main() {
  late AppLocalizations l;
  setUpAll(() async {
    l = await AppLocalizations.delegate.load(const Locale('ko'));
  });

  Finder sheetContent() => find.byType(PBottomSheetContent);

  group('첫 초점', () {
    bool titleFocused(WidgetTester tester) => tester
        .widget<TextField>(find.byType(TextField).first)
        .focusNode!
        .hasFocus;

    testWidgets('새 일정은 제목 칸에 초점이 간다', (tester) async {
      await openEventForm(tester, repo: _Repo());
      expect(titleFocused(tester), isTrue);
    });

    testWidgets('수정으로 열면 어느 칸에도 초점을 주지 않는다', (tester) async {
      await openEventForm(
        tester,
        repo: _Repo(),
        edit: CalendarEvent.fromJson(_event()),
      );
      expect(titleFocused(tester), isFalse);
      expect(
        FocusManager.instance.primaryFocus?.context?.widget,
        isNot(isA<EditableText>()),
      );
    });
  });

  group('줄 칸', () {
    testWidgets('줄 아홉이 이 차례로 있고 새 일정은 종일이 켜져 있다', (tester) async {
      await openEventForm(tester, repo: _Repo());
      final order = [
        l.calFieldCalendar,
        l.calFieldLabel,
        l.calAllDay,
        l.calStartDate,
        l.calEndDate,
        l.calRepeat,
        l.calFieldReminder,
        l.calLocation,
        l.calFieldDescription,
      ];
      var last = -1.0;
      for (final t in order) {
        final y = tester.getTopLeft(rowTitle(t).last).dy;
        expect(y, greaterThan(last), reason: t);
        last = y;
      }
      expect(find.text('10월 29일 (목)'), findsNWidgets(2));
      // 종일이라 시각 조각이 없다
      expect(find.text('오전 9:00'), findsNothing);
    });

    testWidgets('종일을 끄면 시각 조각이 생기고 누르는 자리는 44 이상이다', (tester) async {
      await openEventForm(tester, repo: _Repo());
      await tapRow(tester, l.calAllDay);
      expect(find.text('오전 9:00'), findsOneWidget);
      expect(find.text('오전 10:00'), findsOneWidget);
      // 줄 높이는 글 줄 하나(22)지만 누르는 자리는 위아래 11 씩 줄 밖으로 넓어 44 다(웹 Piece -my-[11px] min-h-[44px])
      for (final t in ['10월 29일 (목)', '오전 9:00']) {
        final box = tester.getRect(
          find
              .ancestor(
                of: find.text(t).first,
                matching: find.byType(GestureDetector),
              )
              .first,
        );
        expect(box.height, closeTo(22, 0.6), reason: '$t 줄 높이');
        final x = box.center.dx;
        for (final dy in [-21.0, 21.0]) {
          final r = HitTestResult();
          tester.binding.hitTestInView(
            r,
            Offset(x, box.center.dy + dy),
            tester.view.viewId,
          );
          expect(
            r.path.any((e) => e.target is RenderPointerListener),
            isTrue,
            reason: '$t 위아래 21 에서도 눌린다(누르는 자리 44)',
          );
        }
      }
      // 시작 · 종료 줄은 다른 줄과 같은 46 이다(위아래 여백 12 + 글 줄 22)
      final rowH = tester
          .getSize(
            find
                .ancestor(
                  of: rowTitle(l.calStartDate),
                  matching: find.byKey(const ValueKey('plist-item')),
                )
                .first,
          )
          .height;
      expect(rowH, closeTo(46, 0.6));
    });

    testWidgets('조각의 이름은 "시작 날짜, 10월 29일 (목)" 꼴이다', (tester) async {
      final handle = tester.ensureSemantics();
      await openEventForm(tester, repo: _Repo());
      expect(
        find.bySemanticsLabel('${l.calFormStartDay}, 10월 29일 (목)'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('${l.calFormEndDay}, 10월 29일 (목)'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('캘린더를 못 불러오면 줄에 "불러오지 못했어요" 를 두고 누르면 다시 받는다', (tester) async {
      var builds = 0;
      final repo = _Repo();
      await openEventForm(tester, repo: repo, calendars: const []);
      expect(valueText(l.calFormCalendarLoadFailed), findsOneWidget);
      builds++;
      await tester.tap(valueText(l.calFormCalendarLoadFailed));
      await tester.pumpAndSettle();
      expect(builds, 1);
      expect(valueText(l.calFormCalendarLoadFailed), findsOneWidget);
    });

    testWidgets('라벨이 0 개여도 라벨 줄이 있고 고르기 시트에 만드는 곳 안내가 뜬다', (tester) async {
      await openEventForm(tester, repo: _Repo());
      expect(valueText(l.calNoLabel), findsOneWidget);
      await tapRow(tester, l.calFieldLabel);
      expect(find.text(l.calFormLabelHint), findsOneWidget);
    });

    testWidgets('고르기 시트는 누르면 바로 닫히고 줄 값이 바뀐다', (tester) async {
      await openEventForm(
        tester,
        repo: _Repo(),
        calendars: const [
          UserCalendar(rowId: 1, calendarName: '개인', isDefault: true),
          UserCalendar(rowId: 3, calendarName: '가족'),
        ],
      );
      await tapRow(tester, l.calFieldCalendar);
      expect(sheetContent(), findsNWidgets(2));
      await tapRow(tester, '가족');
      expect(sheetContent(), findsOneWidget);
      expect(valueTextContaining('가족'), findsOneWidget);
    });

    testWidgets('알림 시트는 "완료" 전에는 줄 값이 그대로이고 닫으면 버려진다', (tester) async {
      await openEventForm(tester, repo: _Repo());
      await tapRow(tester, l.calFieldReminder);
      await tapRow(tester, l.calReminderDayBefore);
      expect(valueText(l.calFormNoReminder), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('p-bottom-sheet-close')).last);
      await tester.pumpAndSettle();
      expect(valueText(l.calFormNoReminder), findsOneWidget);
      expect(sheetContent(), findsOneWidget);
    });
  });

  group('날짜 · 시각', () {
    testWidgets('날짜 시트는 2030 이후도 고르는 범위다 — 상한이 없다', (tester) async {
      await openEventForm(tester, repo: _Repo());
      await tester.tap(find.text('10월 29일 (목)').first);
      await tester.pumpAndSettle();
      final picker = tester.widget<PDatePicker>(find.byType(PDatePicker));
      expect(picker.max, isNull);
      expect(picker.today, DateTime(2026, 10, 29, 13));
    });

    testWidgets('날짜를 고르고 "완료" 해야 줄 값이 바뀌고 종료가 따라 밀린다', (tester) async {
      final repo = _Repo();
      await openEventForm(tester, repo: repo);
      await enterTitle(tester, '출장');
      await tester.tap(find.text('10월 29일 (목)').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('30').first);
      await tester.pumpAndSettle();
      // 완료 전에는 줄 값 그대로
      expect(find.text('10월 29일 (목)'), findsNWidgets(2));
      await tapButton(tester, l.actionDone);
      expect(
        find.text('10월 30일 (금)'),
        findsNWidgets(2),
        reason: '종일이라 끝이 시작 날로 끌려간다',
      );
      await tapButton(tester, l.actionSave);
      expect(repo.lastCreate!['startDate'], startsWith('2026-10-30'));
      expect(repo.lastCreate!['endDate'], startsWith('2026-10-30'));
    });

    testWidgets('시각 시트에서 "완료" 하면 지금 보이던 시각이 들어간다', (tester) async {
      await openEventForm(tester, repo: _Repo());
      await tapRow(tester, l.calAllDay);
      await tester.tap(find.text('오전 9:00'));
      await tester.pumpAndSettle();
      await tapButton(tester, l.actionDone);
      expect(find.text('오전 9:00'), findsOneWidget);
      expect(find.text('오전 10:00'), findsOneWidget);
    });

    testWidgets('끝을 시작보다 앞 날로 고르고 저장하면 종료 줄 아래 오류가 뜨고 요청은 없다', (tester) async {
      final repo = _Repo();
      await openEventForm(tester, repo: repo);
      await enterTitle(tester, '출장');
      await tester.tap(find.text('10월 29일 (목)').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('28').first);
      await tester.pumpAndSettle();
      await tapButton(tester, l.actionDone);
      expect(
        find.text(l.calFormEndBeforeStart),
        findsNothing,
        reason: '저장을 누르기 전에는 안 띄운다',
      );
      await tapButton(tester, l.actionSave);
      expect(find.text(l.calFormEndBeforeStart), findsOneWidget);
      expect(repo.creates, 0);
    });
  });

  group('저장 · 칸 오류', () {
    testWidgets('[저장] 은 켜 둔다 — 제목이 비면 칸 오류가 뜨고 요청은 없다', (tester) async {
      final repo = _Repo();
      await openEventForm(tester, repo: repo);
      await tapButton(tester, l.actionSave);
      expect(find.text(keepAll(l.calFormTitleRequired)), findsOneWidget);
      expect(repo.creates, 0);
      // 치기 시작하면 오류가 걷힌다
      await enterTitle(tester, '출장');
      expect(find.text(keepAll(l.calFormTitleRequired)), findsNothing);
    });

    testWidgets('저장이 실패하면 시트가 열린 채 폼 맨 위 Callout 이 뜨고 쓴 값이 남는다', (
      tester,
    ) async {
      final repo = _Repo()..fail = true;
      await openEventForm(tester, repo: repo);
      await enterTitle(tester, '출장');
      await tapButton(tester, l.actionSave);
      expect(find.byType(PCallout), findsOneWidget);
      expect(find.text(l.calFormSaveFailed), findsOneWidget);
      expect(
        find.text('Server error'),
        findsNothing,
        reason: '서버 글을 그대로 내지 않는다',
      );
      expect(sheetContent(), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        '출장',
      );
      // 다시 눌러 성공하면 닫힌다
      repo.fail = false;
      await tapButton(tester, l.actionSave);
      expect(repo.creates, 1);
      expect(sheetContent(), findsNothing);
    });
  });

  group('닫기 물음', () {
    testWidgets('바뀐 값이 없으면 바로 닫힌다', (tester) async {
      await openEventForm(tester, repo: _Repo());
      await tester.tap(find.byKey(const ValueKey('p-bottom-sheet-close')));
      await tester.pumpAndSettle();
      expect(sheetContent(), findsNothing);
    });

    testWidgets('바뀐 값이 있으면 "작성한 내용이 사라져요" 를 묻고 계속 작성하면 남는다', (tester) async {
      await openEventForm(tester, repo: _Repo());
      await enterTitle(tester, '출장');
      await tester.tap(find.byKey(const ValueKey('p-bottom-sheet-close')));
      await tester.pumpAndSettle();
      expect(find.byType(PAlertDialogView), findsOneWidget);
      await tester.tap(find.text(l.sheetLeaveStay));
      await tester.pumpAndSettle();
      expect(sheetContent(), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('p-bottom-sheet-close')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.sheetLeaveLeave));
      await tester.pumpAndSettle();
      expect(sheetContent(), findsNothing);
    });

    testWidgets('딤을 눌러도 닫히지 않는다', (tester) async {
      await openEventForm(tester, repo: _Repo(), size: const Size(390, 1000));
      await tester.tapAt(const Offset(195, 10));
      await tester.pumpAndSettle();
      expect(sheetContent(), findsOneWidget);
    });
  });

  group('장소 · 설명 한 단계', () {
    testWidgets('들어가면 머리가 ← 제목 · 완료로 바뀌고 닫기 원과 바닥 [저장] 이 사라진다', (tester) async {
      await openEventForm(tester, repo: _Repo());
      await tapRow(tester, l.calLocation);
      expect(sheetContent(), findsOneWidget, reason: '시트를 겹치지 않는다');
      expect(
        find.byKey(const ValueKey('p-bottom-sheet-back-slot')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('p-bottom-sheet-close')), findsNothing);
      expect(button(l.actionSave), findsNothing);
      expect(button(l.actionDone), findsOneWidget);
    });

    testWidgets('"완료" 는 친 글을 넣고, ← 는 바뀐 글이 있으면 묻고 나가면 버린다', (tester) async {
      await openEventForm(tester, repo: _Repo());
      await writeStep(
        tester,
        row: l.calLocation,
        text: '치과 3층',
        done: l.actionDone,
      );
      expect(valueText('치과 3층'), findsOneWidget);

      await tapRow(tester, l.calLocation);
      await tester.enterText(find.byType(TextField).last, '버려질 글');
      await tester.tap(find.byKey(const ValueKey('p-bottom-sheet-back-slot')));
      await tester.pumpAndSettle();
      // 들어올 때와 글이 달라 먼저 묻는다(웹 M-7 과 같다) — 계속 작성은 그 단계에 머문다
      expect(find.byType(PAlertDialogView), findsOneWidget);
      await tester.tap(find.text(l.sheetLeaveStay));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('p-bottom-sheet-back-slot')),
        findsOneWidget,
        reason: '계속 작성 — 안 단계 그대로',
      );
      await tester.tap(find.byKey(const ValueKey('p-bottom-sheet-back-slot')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.sheetLeaveLeave));
      await tester.pumpAndSettle();
      expect(valueText('치과 3층'), findsOneWidget);
      expect(valueText('버려질 글'), findsNothing);
    });

    testWidgets('글을 안 바꿨으면 ← 가 묻지 않고 바로 줄 칸으로 간다', (tester) async {
      await openEventForm(tester, repo: _Repo());
      await tapRow(tester, l.calLocation);
      await tester.tap(find.byKey(const ValueKey('p-bottom-sheet-back-slot')));
      await tester.pumpAndSettle();
      expect(find.byType(PAlertDialogView), findsNothing);
      expect(
        find.byKey(const ValueKey('p-bottom-sheet-back-slot')),
        findsNothing,
      );
    });

    testWidgets('뒤로 가기 · Esc 는 단계만 닫고, 그다음에야 시트가 닫힌다', (tester) async {
      await openEventForm(tester, repo: _Repo());
      await tapRow(tester, l.calFieldDescription);
      await tester.enterText(find.byType(TextField).last, '버려질 글');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      // 바뀐 글이 있어 먼저 묻는다 — 나가면 그 단계만 닫힌다
      expect(find.byType(PAlertDialogView), findsOneWidget);
      await tester.tap(find.text(l.sheetLeaveLeave));
      await tester.pumpAndSettle();
      expect(sheetContent(), findsOneWidget);
      expect(
        find.byKey(const ValueKey('p-bottom-sheet-back-slot')),
        findsNothing,
      );
      expect(valueText('버려질 글'), findsNothing);

      await tapRow(tester, l.calLocation);
      debugPrint(
        'FOCUS ${FocusManager.instance.primaryFocus?.debugLabel} ${FocusManager.instance.primaryFocus?.context?.widget.runtimeType}',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(sheetContent(), findsOneWidget);
      expect(
        find.byKey(const ValueKey('p-bottom-sheet-back-slot')),
        findsNothing,
      );

      // 줄 칸에서는 시트를 닫는다(바뀐 값이 없어 묻지 않는다)
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(sheetContent(), findsNothing);
    });

    testWidgets('설명 단계의 글자 수는 10,000 · 장소는 500 이 상한이다', (tester) async {
      await openEventForm(tester, repo: _Repo());
      await tapRow(tester, l.calLocation);
      await tester.enterText(find.byType(TextField).last, 'ㄱ' * 600);
      await tapButton(tester, l.actionDone);
      expect(
        tester
            .widget<Text>(
              find.byWidgetPredicate(
                (w) => w is Text && (w.semanticsLabel ?? '').startsWith('ㄱ'),
              ),
            )
            .semanticsLabel!
            .length,
        500,
      );
    });

    testWidgets('긴 장소는 줄 끝에서 줄바꿈하고 제목은 한 줄이다(200%)', (tester) async {
      await openEventForm(tester, repo: _Repo(), scale: 2);
      await writeStep(
        tester,
        row: l.calLocation,
        text: '본사 3층 큰 회의실 — 길게 써도 줄이 바뀌어 모두 보여야 해요',
        done: l.actionDone,
      );
      expect(tester.takeException(), isNull);
      final h = tester.getSize(rowTitle(l.calLocation).last).height;
      expect(h, lessThan(70), reason: '제목이 글자 하나 폭으로 눌려 세로로 깨지면 이보다 훨씬 크다');
    });
  });

  group('큰 글자에서 값 자리(list.md 좁은 줄)', () {
    Future<(Rect, Rect)> rects(WidgetTester tester, double scale) async {
      await openEventForm(
        tester,
        repo: _Repo(),
        scale: scale,
        size: const Size(360, 2400),
      );
      await writeStep(
        tester,
        row: l.calLocation,
        text: '본사 3층 큰 회의실',
        done: l.actionDone,
      );
      return (
        tester.getRect(rowTitle(l.calLocation).last),
        tester.getRect(valueTextContaining('본사 3층').last),
      );
    }

    testWidgets('값 앞 색 점은 글자 배율과 무관하게 8 × 8 이다', (tester) async {
      for (final scale in [1.0, 2.0]) {
        await openEventForm(tester, repo: _Repo(), scale: scale);
        // 글 안 WidgetSpan 은 그릴 때 배율이 곱해진다 — 그려진 크기는 화면 좌표로 잰다
        final box = tester.renderObject<RenderBox>(
          find.byType(PickerDot).first,
        );
        final shown =
            box.localToGlobal(box.size.bottomRight(Offset.zero)) -
            box.localToGlobal(Offset.zero);
        expect(shown.dx, closeTo(8, 0.1), reason: 'scale $scale');
        expect(shown.dy, closeTo(8, 0.1), reason: 'scale $scale');
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('값 글은 낱말 단위로 줄을 바꾼다(keepAll — 낱말 사이에만 끊는다)', (tester) async {
      await openEventForm(tester, repo: _Repo(), scale: 2);
      await writeStep(
        tester,
        row: l.calFieldDescription,
        text: '검진 전 8시간 금식 신분증 챙기기',
        done: l.actionDone,
      );
      final t = tester.widget<Text>(
        find.byWidgetPredicate(
          (w) => w is Text && (w.semanticsLabel ?? '') == '검진 전 8시간 금식 신분증 챙기기',
        ),
      );
      expect(t.textSpan!.toPlainText(), contains('\u2060'));
      expect(t.textSpan!.toPlainText(), keepAll('검진 전 8시간 금식 신분증 챙기기'));
    });

    testWidgets('100% 는 값이 제목 오른쪽 같은 줄에 선다', (tester) async {
      final (title, value) = await rects(tester, 1);
      expect(value.left, greaterThan(title.right));
      expect(value.top, lessThan(title.bottom));
    });

    testWidgets('200%(줄 안 폭 < 16em)는 값이 제목 아래로 내려간다', (tester) async {
      final (title, value) = await rects(tester, 2);
      expect(value.top, greaterThanOrEqualTo(title.bottom - 1));
      expect(value.left, closeTo(title.left, 1), reason: '본문 칸 안 왼쪽 맞춤');
    });
  });

  group('수정 · 삭제 · 달 비우기', () {
    testWidgets('수정 바닥은 [삭제][저장] 이고 삭제는 확인 뒤에 지운다', (tester) async {
      final repo = _Repo();
      await openEventForm(
        tester,
        repo: repo,
        edit: CalendarEvent.fromJson(_event()),
      );
      expect(button(l.actionDelete), findsOneWidget);
      expect(button(l.actionSave), findsOneWidget);
      await tapButton(tester, l.actionDelete);
      expect(find.byType(PAlertDialogView), findsOneWidget);
      expect(repo.deletes, 0);
      await tester.tap(
        find.descendant(
          of: find.byType(PAlertDialogView),
          matching: find.text(l.actionDelete),
        ),
      );
      await tester.pumpAndSettle();
      expect(repo.deletes, 1);
      expect(sheetContent(), findsNothing);
    });

    testWidgets('반복이 아닌 일정은 그 달만 다시 받는다', (tester) async {
      final builds = <MonthYM, int>{};
      await openEventForm(
        tester,
        repo: _Repo(),
        edit: CalendarEvent.fromJson(_event()),
        monthBuilds: builds,
        watchMonths: [_oct, _nov],
      );
      final before = Map.of(builds);
      await tapButton(tester, l.actionSave);
      expect(builds[_oct], before[_oct]! + 1);
      expect(builds[_nov], before[_nov]);
    });

    testWidgets('반복 일정을 저장하면 받아 둔 모든 달을 다시 받는다', (tester) async {
      final builds = <MonthYM, int>{};
      await openEventForm(
        tester,
        repo: _Repo(),
        edit: CalendarEvent.fromJson(_event(rrule: 'FREQ=WEEKLY')),
        monthBuilds: builds,
        watchMonths: [_oct, _nov],
      );
      final before = Map.of(builds);
      await tapButton(tester, l.actionSave);
      expect(builds[_oct], before[_oct]! + 1);
      expect(builds[_nov], before[_nov]! + 1);
    });

    testWidgets('반복 일정을 지워도 모든 달을 다시 받는다', (tester) async {
      final builds = <MonthYM, int>{};
      await openEventForm(
        tester,
        repo: _Repo(),
        edit: CalendarEvent.fromJson(_event(rrule: 'FREQ=WEEKLY')),
        monthBuilds: builds,
        watchMonths: [_oct, _nov],
      );
      final before = Map.of(builds);
      await tapButton(tester, l.actionDelete);
      await tester.tap(
        find.descendant(
          of: find.byType(PAlertDialogView),
          matching: find.text(l.actionDelete),
        ),
      );
      await tester.pumpAndSettle();
      expect(builds[_oct], before[_oct]! + 1);
      expect(builds[_nov], before[_nov]! + 1);
    });
  });

  testWidgets('글자 200% · 폭 360 에서 시트가 넘치지 않고 시작 · 종료 조각이 잘리지 않는다', (
    tester,
  ) async {
    await openEventForm(
      tester,
      repo: _Repo(),
      scale: 2,
      size: const Size(360, 1800),
    );
    await tapRow(tester, l.calAllDay);
    expect(tester.takeException(), isNull);
    final sheet = tester.getRect(
      find.byKey(const ValueKey('p-bottom-sheet-root')),
    );
    expect(sheet.right, lessThanOrEqualTo(360.5));
    for (final t in ['10월 29일 (목)', '오전 9:00']) {
      final r = tester.getRect(find.text(t).first);
      expect(r.right, lessThanOrEqualTo(360 - 24 + 0.5), reason: t);
    }
  });
}
