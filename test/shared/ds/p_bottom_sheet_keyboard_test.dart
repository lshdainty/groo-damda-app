// 키보드가 올라온 시트 — 위 안전 영역(상태 표시줄) 밑에서 멈추고 ✕ 가 화면 안에서 눌린다(시험 2026-11-11 DA-03 ①).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import '../../support/plain_text.dart';

void main() {
  testWidgets('키보드 + 위 안전 영역 — 시트 윗선이 안전 영역 아래, ✕ 가 눌린다', (tester) async {
    // iPhone 17 급: 402 × 874 pt, 위 62 · 아래 34, 키보드 336
    tester.view.physicalSize = const Size(1206, 2622);
    tester.view.devicePixelRatio = 3.0;
    tester.view.padding = const FakeViewPadding(top: 186, bottom: 102);
    tester.view.viewPadding = const FakeViewPadding(top: 186, bottom: 102);
    addTearDown(tester.view.reset);
    var closed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => PBottomSheet.show<void>(
                ctx,
                builder: (c) => PBottomSheetContent(
                  title: '거래 추가',
                  closeLabel: '닫기',
                  onClose: () => closed = true,
                  body: Column(
                    children: [
                      for (var i = 0; i < 12; i++) const SizedBox(height: 80),
                    ],
                  ),
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
    tester.view.viewInsets = const FakeViewPadding(bottom: 1008); // 336pt
    await tester.pumpAndSettle();

    final top = tester.getTopLeft(find.byType(PBottomSheetContent)).dy;
    expect(top, greaterThanOrEqualTo(62), reason: '시트 윗선은 상태 표시줄 밑');
    final close = find.bySemanticsLabel('닫기');
    final center = tester.getCenter(close.first);
    expect(center.dy, greaterThan(62));
    // hit test — 그 자리를 누르면 닫기 단추가 받는다
    await tester.tapAt(center);
    await tester.pumpAndSettle();
    expect(closed, isTrue, reason: '✕ 가 눌려야 한다');
  });
}
