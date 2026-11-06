// 시트 바닥 버튼은 스낵바가 피할 자리다(snackbar.md "자리" — 바닥 버튼 위 8). 띠가 [삭제] · [수정] 을 덮지 않고
// 버튼 윗변 위 8 에 선다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import '../../support/plain_text.dart';

void main() {
  testWidgets('스낵바 아래 끝은 시트 바닥 버튼 윗변 위 8 이다', (tester) async {
    tester.view.physicalSize = const Size(390, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    late BuildContext outer;
    await tester.pumpWidget(
      MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (c, child) => PSnackbarHost(closeLabel: '닫기', child: child!),
        home: Builder(
          builder: (c) {
            outer = c;
            return const Scaffold(body: SizedBox.expand());
          },
        ),
      ),
    );
    PBottomSheet.show<void>(
      outer,
      builder: (c) => PBottomSheetContent(
        title: '상세',
        closeLabel: '닫기',
        body: const SizedBox(height: 80),
        footer: [
          PButton(
            label: '삭제',
            size: PButtonSize.large,
            variant: PButtonVariant.neutralWeak,
            onPressed: () {},
          ),
          PButton(label: '수정', size: PButtonSize.large, onPressed: () {}),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    PSnackbar.of(outer).show(message: '삭제하지 못했어요.');
    await tester.pump();
    // 띠가 뜬 뒤 피할 자리를 재고 200ms 로 올라간다
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    final band = tester.getRect(find.byKey(const ValueKey('snackbar-band')));
    final button = tester.getRect(findWidgetWithText(PButton, '삭제'));
    expect(button.top - band.bottom, closeTo(8, 0.5));
  });
}
