// iOS 스타일 시각 휠 — 탭하면 휠이 뜨고, 확인/취소가 값에 반영되는지.
// 날짜는 달력 그리드 그대로 두고 등장만 시트로 — 월 전체가 보이는 쪽이 낫다.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/widgets/p_calendar.dart';
import 'package:groo_damda_app/shared/widgets/p_date_input.dart';
import '../support/plain_text.dart';

Widget _app(Widget child) => MaterialApp(
  theme: GrooTheme.dark(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('ko'),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('날짜 입력을 탭하면 달력이 시트로 올라온다', (tester) async {
    await tester.pumpWidget(
      _app(PDateInput(value: DateTime(2026, 3, 5), onChanged: (_) {})),
    );

    await tester.tap(find.byIcon(LucideIcons.calendar));
    await tester.pumpAndSettle();

    // 달력 그리드는 유지하되(월 전체가 보이는 쪽이 낫다) 등장 방식만 시트로.
    expect(find.byType(PCalendar), findsOneWidget);
    // 헤더는 월·년 select 두 개로 갈라져 있다.
    expect(findText('3월'), findsOneWidget);
    expect(findText('2026년'), findsOneWidget);
    // Material 다이얼로그 피커로 돌아가지 않았는지.
    expect(find.byType(CalendarDatePicker), findsNothing);
    expect(find.byType(CupertinoDatePicker), findsNothing);
  });

  testWidgets('년도 select 로 먼 해까지 한 번에 간다', (tester) async {
    await tester.pumpWidget(
      _app(
        PDateInput(
          value: DateTime(2026, 3, 5),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030, 12, 31),
          onChanged: (_) {},
        ),
      ),
    );

    await tester.tap(find.byIcon(LucideIcons.calendar));
    await tester.pumpAndSettle();

    await tester.tap(findText('2026년'));
    await tester.pumpAndSettle();
    // 목록이 열리면 같은 라벨이 트리거·항목 둘 다에 있다 — 마지막(항목)을 누른다.
    await tester.tap(findText('2022년').last);
    await tester.pumpAndSettle();

    expect(findText('2022년'), findsOneWidget);
    expect(findText('3월'), findsOneWidget, reason: '월은 그대로 둔다');
  });

  testWidgets('날짜를 누르면 시트가 닫히고 그 값이 올라온다', (tester) async {
    DateTime? changed;
    await tester.pumpWidget(
      _app(
        PDateInput(value: DateTime(2026, 3, 5), onChanged: (v) => changed = v),
      ),
    );

    await tester.tap(find.byIcon(LucideIcons.calendar));
    await tester.pumpAndSettle();

    await tester.tap(findText('17'));
    await tester.pumpAndSettle();

    expect(find.byType(PCalendar), findsNothing, reason: '고르면 바로 닫힌다');
    expect(changed, DateTime(2026, 3, 17));
  });

  testWidgets('시각 입력을 탭하면 휠이 뜨고, 취소하면 값이 그대로다', (tester) async {
    TimeOfDay? changed;
    await tester.pumpWidget(
      _app(
        PTimeInput(
          value: const TimeOfDay(hour: 9, minute: 0),
          onChanged: (v) => changed = v,
        ),
      ),
    );

    await tester.tap(find.byIcon(LucideIcons.clock));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoDatePicker), findsOneWidget);

    await tester.tap(findText('취소'));
    await tester.pumpAndSettle();

    expect(find.byType(CupertinoDatePicker), findsNothing);
    expect(changed, isNull, reason: '취소는 호출부 값을 건드리지 않는다');
  });

  testWidgets('휠을 굴리고 확인을 누르면 바뀐 값이 올라온다', (tester) async {
    TimeOfDay? changed;
    await tester.pumpWidget(
      _app(
        PTimeInput(
          value: const TimeOfDay(hour: 9, minute: 0),
          onChanged: (v) => changed = v,
        ),
      ),
    );

    await tester.tap(find.byIcon(LucideIcons.clock));
    await tester.pumpAndSettle();

    // 시 컬럼을 굴린다. 피커 전체를 잡으면 가운데(분 컬럼)를 미는 셈이라
    // 시가 안 움직인다 — '09' 가 그려진 시 컬럼을 직접 집는다.
    await tester.drag(findText('09'), const Offset(0, -64));
    await tester.pumpAndSettle();

    await tester.tap(findText('확인'));
    await tester.pumpAndSettle();

    expect(changed, isNotNull, reason: '확인은 고른 값을 올려보낸다');
    expect(changed!.hour, isNot(9), reason: '굴린 만큼 시가 움직였다');
  });
}
