import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/bottom_sheet_parts.dart';

/// groo-design Layout "Safe Area" — 시트 · 대화상자는 좌우 안전 영역을 뺀 자리의 가운데에 선다(본문과 같은 세로 줄).
/// iPhone Duo 처럼 상태 칸이 옆(오른쪽 84)에 있으면 화면 가운데와 42 어긋난다.
void main() {
  const duoRight = EdgeInsets.only(right: 84);

  group('bottomSheetLeft', () {
    test('펼침 951 — 480 시트가 안전 영역 가운데', () {
      final left = bottomSheetLeft(951, kBottomSheetMaxWidth, duoRight);
      expect(left + kBottomSheetMaxWidth / 2, (951 - 84) / 2);
    });

    test('접힘 466 — 화면 폭 시트는 화면 안 왼쪽 끝(넘쳐 나가지 않는다)', () {
      expect(bottomSheetLeft(466, 466, duoRight), 0);
    });

    test('좌우가 같으면 화면 가운데', () {
      const both = EdgeInsets.symmetric(horizontal: 47);
      expect(bottomSheetLeft(932, 480, both), (932 - 480) / 2);
    });

    test('안전 영역이 없으면 화면 가운데', () {
      expect(bottomSheetLeft(800, 480, EdgeInsets.zero), 160);
    });
  });

  testWidgets('대화상자 — 펼친 Duo 에서 안전 영역 가운데', (tester) async {
    tester.view.physicalSize = const Size(951, 669);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(padding: duoRight),
            child: Scaffold(
              body: PAlertDialogView(
                title: '거래를 삭제할까요?',
                description: '삭제한 거래는 되돌릴 수 없어요.',
                cancelLabel: '취소',
                actionLabel: '삭제',
                destructive: true,
                onCancel: () {},
              ),
            ),
          ),
        ),
      ),
    );
    final card = find.byWidgetPredicate(
      (w) =>
          w is DecoratedBox &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).color ==
              PColors.light.bgLayerFloating &&
          (w.decoration as BoxDecoration).borderRadius != null,
    );
    final rect = tester.getRect(card.first);
    expect(rect.center.dx, closeTo((951 - 84) / 2, 0.5));
    expect(rect.right, lessThanOrEqualTo(951 - 84));
  });
}
