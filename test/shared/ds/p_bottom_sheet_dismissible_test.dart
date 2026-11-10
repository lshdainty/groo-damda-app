// Bottom Sheet `dismissible: false`(사용자 결정 2026-11-10 — 휠 · 달력을 굴리다 시트가 같이 내려가 조작이 안 됐다).
// 끄면 끌어내리기 · 바깥 누르기로 닫히지 않고 시트 몸통도 손가락을 따라가지 않는다. ✕ · [완료] · 뒤로 가기로는 닫힌다.
// 기본(켜짐)은 지금 동작 그대로다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/time_picker/p_time_picker.dart';
import 'package:groo_damda_app/shared/forms/time_sheet.dart';
import '../../support/plain_text.dart';

Future<void> _open(WidgetTester tester, {required bool wheelSheet}) async {
  tester.view.physicalSize = const Size(1170, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: GrooTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      home: Scaffold(
        body: Builder(
          builder: (ctx) => TextButton(
            onPressed: () => wheelSheet
                ? showTimeSheet(
                    ctx,
                    title: '시각',
                    value: const PTimeValue(21, 13),
                  )
                // 같은 모양의 시트인데 끄지 않은 것 — 대조군
                : PBottomSheet.show<void>(
                    ctx,
                    builder: (c) => PBottomSheetContent(
                      title: '시각',
                      closeLabel: '닫기',
                      body: const SizedBox(height: 200),
                    ),
                  ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(findText('open'));
  await tester.pumpAndSettle();
  // 열린 뒤 0.5초 동안은 끌리지 않는다(kSheetDragDelay) — 그 뒤에도 안 따라가는지 본다
  await tester.pump(const Duration(milliseconds: 600));
}

double _top(WidgetTester tester) =>
    tester.getTopLeft(find.byType(PBottomSheetContent)).dy;

void controlDrag() {
  testWidgets('대조 — 끄지 않은 시트는 제목 줄을 쓸어내리면 닫힌다', (tester) async {
    await _open(tester, wheelSheet: false);
    final h = tester.getSize(find.byType(PBottomSheetContent)).height;
    await tester.timedDragFrom(
      tester.getCenter(find.byKey(const ValueKey('p-bottom-sheet-title'))),
      Offset(0, h * 0.5),
      const Duration(seconds: 3),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PBottomSheetContent), findsNothing);
  });
}

void main() {
  controlDrag();
  wheelTests();
  testWidgets('끄면 — 시트 몸통을 아래로 끌어도 손가락을 따라가지 않고 제자리에 열려 있다', (tester) async {
    await _open(tester, wheelSheet: true);
    final t0 = _top(tester);
    // 휠 위가 아니라 시트 몸통(제목 줄)을 잡고 천천히 끌어도 몸통이 따라가지 않는다
    final g = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('p-bottom-sheet-title'))),
    );
    for (var i = 0; i < 12; i++) {
      await g.moveBy(const Offset(0, 40));
      await tester.pump(const Duration(milliseconds: 30));
      expect(_top(tester), t0, reason: '손가락을 따라 내려가지 않는다');
    }
    await g.up();
    await tester.pumpAndSettle();
    expect(find.byType(PBottomSheetContent), findsOneWidget);
    expect(_top(tester), t0);
  });

  testWidgets('끄면 — 시트 머리(제목 줄)를 빠르게 쓸어내려도 닫히지 않는다', (tester) async {
    await _open(tester, wheelSheet: true);
    final t0 = _top(tester);
    await tester.timedDragFrom(
      tester.getCenter(find.byKey(const ValueKey('p-bottom-sheet-title'))),
      const Offset(0, 300),
      const Duration(milliseconds: 60),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PBottomSheetContent), findsOneWidget);
    expect(_top(tester), t0);
  });

  testWidgets('끄면 — 바깥(딤)을 눌러도 닫히지 않는다', (tester) async {
    await _open(tester, wheelSheet: true);
    await tester.tapAt(const Offset(195, 20));
    await tester.pumpAndSettle();
    expect(find.byType(PBottomSheetContent), findsOneWidget);
  });

  testWidgets('끄면 — ✕ 로 닫힌다', (tester) async {
    await _open(tester, wheelSheet: true);
    await tester.tap(find.byKey(const ValueKey('p-bottom-sheet-close-circle')));
    await tester.pumpAndSettle();
    expect(find.byType(PBottomSheetContent), findsNothing);
  });

  testWidgets('끄면 — [완료] 로 닫히고 값이 나간다', (tester) async {
    await _open(tester, wheelSheet: true);
    await tester.tap(findText('완료'));
    await tester.pumpAndSettle();
    expect(find.byType(PBottomSheetContent), findsNothing);
  });

  testWidgets('끄면 — 뒤로 가기는 지금 규칙 그대로 닫는다', (tester) async {
    await _open(tester, wheelSheet: true);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(PBottomSheetContent), findsNothing);
  });

  testWidgets('대조 — 끄지 않은 시트는 바깥을 누르면 닫힌다(기본값은 지금 동작)', (tester) async {
    await _open(tester, wheelSheet: false);
    await tester.tapAt(const Offset(195, 20));
    await tester.pumpAndSettle();
    expect(find.byType(PBottomSheetContent), findsNothing);
  });
}

// 휠 자체를 아래로 굴려도 시트는 움직이지 않는다(휠이 제스처를 먼저 받는다)
void wheelTests() {
  testWidgets('휠을 아래로 굴려도 시트는 제자리다', (tester) async {
    await _open(tester, wheelSheet: true);
    final t0 = _top(tester);
    final g = await tester.startGesture(
      tester.getCenter(find.byType(PTimePicker)),
    );
    for (var i = 0; i < 12; i++) {
      await g.moveBy(const Offset(0, 40));
      await tester.pump(const Duration(milliseconds: 30));
    }
    await g.up();
    await tester.pumpAndSettle();
    expect(find.byType(PBottomSheetContent), findsOneWidget);
    expect(_top(tester), t0);
  });
}
