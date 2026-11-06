// I-27 달 고르기 — 연 | 월 휠 시트. wheel-picker.yaml "달만 고르기": medium 44 · 5칸 220 · 연 120 오른쪽 · 월 96 왼쪽 반복,
// 바닥 "완료" 로만 값이 들어가고, 바깥 누르기 · 끌어내리기 · 닫기는 값 없이 닫는다. 4 × 3 월 격자는 없다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/month_picker/p_month_picker.dart';
import 'package:groo_damda_app/shared/ds/wheel_picker/p_wheel_picker.dart';
import '../../support/plain_text.dart';

DateTime? _result;
bool _closed = false;

Widget _app({double scale = 1}) => MaterialApp(
  theme: GrooTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('ko'),
  builder: (context, c) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: c!,
  ),
  home: Builder(
    builder: (context) => Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () async {
            _closed = false;
            _result = await showPMonthPicker(
              context,
              initial: DateTime(2026, 10, 17),
              title: '월 선택',
            );
            _closed = true;
          },
          child: const Text('열기'),
        ),
      ),
    ),
  ),
);

Future<void> _open(WidgetTester tester, {double scale = 1}) async {
  tester.view.physicalSize = const Size(360, 780);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(scale: scale));
  await tester.tap(findText('열기'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('연 | 월 휠 — 5칸 220, 연 120 · 월 96, 격자 없음', (tester) async {
    await _open(tester);
    expect(find.byType(PWheelPicker), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('wheel-root'))).height,
      220,
    );
    final cols = find.byType(PWheelPickerColumn<int>);
    expect(cols, findsNWidgets(2));
    expect(tester.getSize(cols.at(0)).width, 120);
    expect(tester.getSize(cols.at(1)).width, 96);
    // 열 때 지금 달에서 시작 — 고른 항목 글
    expect(findText('2026년'), findsWidgets);
    expect(findText('10월'), findsWidgets);
    // 옛 격자의 "오늘로" · 연 ‹ › 는 없다
    expect(findText('오늘로'), findsNothing);
    expect(find.byType(GridView), findsNothing);
    expect(findText('완료'), findsOneWidget);
  });

  testWidgets('완료는 열 때의 달을 1일로 돌려준다', (tester) async {
    await _open(tester);
    await tester.tap(findText('완료'));
    await tester.pumpAndSettle();
    expect(_closed, isTrue);
    expect(_result, DateTime(2026, 10, 1));
  });

  testWidgets('월을 눌러 옮기고 완료하면 그 달', (tester) async {
    await _open(tester);
    // 월 칼럼의 보이는 "11월" 을 눌러 가운데로
    final next = find.descendant(
      of: find.byWidgetPredicate(
        (w) => w is PWheelPickerColumn && w.semanticLabel == '월',
      ),
      matching: findText('11월'),
    );
    await tester.tap(next.first);
    await tester.pumpAndSettle();
    await tester.tap(findText('완료'));
    await tester.pumpAndSettle();
    expect(_result, DateTime(2026, 11, 1));
  });

  testWidgets('바깥 누르기도 닫기 버튼도 값 없이 닫는다', (tester) async {
    await _open(tester);
    await tester.tapAt(const Offset(180, 20));
    await tester.pumpAndSettle();
    expect(_closed, isTrue);
    expect(_result, isNull);
    await _open(tester);
    await tester.tap(find.bySemanticsLabel('닫기').first);
    await tester.pumpAndSettle();
    expect(_closed, isTrue);
    expect(_result, isNull);
  });

  testWidgets('글자 200% 에서도 휠은 220 그대로, 완료는 넘치지 않는다', (tester) async {
    await _open(tester, scale: 2);
    expect(
      tester.getSize(find.byKey(const ValueKey('wheel-root'))).height,
      220,
    );
    expect(tester.takeException(), isNull);
    expect(findText('완료'), findsOneWidget);
  });

  testWidgets('선택 띠는 휠 끝에서 16 들여 x 40~320 (100% · 200%)', (tester) async {
    for (final scale in [1.0, 2.0]) {
      await _open(tester, scale: scale);
      final root = tester.getRect(find.byKey(const ValueKey('wheel-root')));
      final band = tester.getRect(
        find.byKey(const ValueKey('wheel-indicator')),
      );
      // 시트 본문 좌우 24 → 휠 24~336, 띠는 휠 끝에서 16 → 40~320
      expect(root.left, 24);
      expect(root.right, 336);
      expect(band.left, 40);
      expect(band.right, 320);
      await tester.tapAt(const Offset(180, 20));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('아래로 끌어도 값 없이 닫힌다', (tester) async {
    await _open(tester);
    // 열린 뒤 0.5초가 지나야 끌린다(스펙) — 그 뒤에 끈다
    await tester.pump(const Duration(milliseconds: 700));
    await tester.fling(
      find.byType(PBottomSheetContent),
      const Offset(0, 500),
      2000,
    );
    await tester.pumpAndSettle();
    expect(_closed, isTrue);
    expect(_result, isNull);
  });
}
