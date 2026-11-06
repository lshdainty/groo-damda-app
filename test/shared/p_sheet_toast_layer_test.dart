// 시트가 열린 채 띄운 토스트는 시트 **위**에 보여야 한다(QA 25 Q5, 2026-09-21 확정).
//
// 토스트는 전역 ScaffoldMessenger 의 SnackBar 라 등록된 루트 Scaffold 에 그려진다. 시트(루트
// 네비게이터의 모달 라우트)에 Scaffold 가 없던 동안에는 시트 아래 페이지에만 그려져 가려졌다 —
// 상세에서 환불한 뒤 "미리 낸 돈 중 N원이 계좌로 돌아왔어요" 가 안 보였다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/widgets/p_modal.dart';
import 'package:groo_damda_app/shared/widgets/p_snack_bar.dart';
import '../support/plain_text.dart';

void main() {
  late BuildContext sheetCtx;

  Future<void> openSheet(WidgetTester tester, {bool shrinkWrap = false}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => showPSheet<void>(
                ctx,
                title: '지출 상세',
                shrinkWrap: shrinkWrap,
                contentBuilder: (c, _) {
                  sheetCtx = c;
                  return const SizedBox(height: 200);
                },
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(findText('open'));
    await tester.pumpAndSettle();
  }

  Finder inSheet(Finder f) =>
      find.descendant(of: find.byType(DraggableScrollableSheet), matching: f);

  testWidgets('시트 안에서 띄운 토스트가 시트 위에 그려지고 버튼이 눌린다', (tester) async {
    await openSheet(tester);
    var tapped = 0;
    showPSnackBar(
      sheetCtx,
      '미리 낸 돈 중 5,000원이 계좌로 돌아왔어요',
      actionLabel: '잔액 고치기',
      onAction: () => tapped++,
    );
    await tester.pumpAndSettle();

    expect(inSheet(findText('미리 낸 돈 중 5,000원이 계좌로 돌아왔어요')), findsOneWidget);
    // 시트 위의 버튼이 실제로 눌린다 — 모달 장벽 뒤 페이지의 것이 아니다.
    await tester.tap(inSheet(findText('잔액 고치기')));
    await tester.pumpAndSettle();
    expect(tapped, 1);
  });

  testWidgets('시트를 닫아도 페이지 쪽 토스트는 남는다 — 저장 → 닫힘 → 토스트 흐름', (tester) async {
    await openSheet(tester);
    showPSnackBar(sheetCtx, '저장했어요', duration: const Duration(seconds: 10));
    await tester.pumpAndSettle();
    Navigator.of(sheetCtx).pop();
    await tester.pumpAndSettle();

    expect(find.byType(DraggableScrollableSheet), findsNothing);
    expect(findText('저장했어요'), findsOneWidget);
  });

  testWidgets('시트 크기와 본문은 그대로다 — 층이 높이를 바꾸지 않는다', (tester) async {
    await openSheet(tester);
    final sheetHeight = tester
        .getSize(find.byType(DraggableScrollableSheet))
        .height;
    final screen =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;

    // 기본 initialChildSize 0.85 — 투명 Scaffold 가 끼어도 같은 높이를 받는다.
    expect(sheetHeight, closeTo(screen * 0.85, 2));
    expect(inSheet(findText('지출 상세')), findsOneWidget);
  });
}
