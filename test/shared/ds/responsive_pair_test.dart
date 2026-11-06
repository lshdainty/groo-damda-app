// 짝 버튼(03A-013) — 한 라벨이 짝 폭의 절반을 넘으면 세로로 쌓는다(주 버튼 위, 라벨 한 줄).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/button/p_responsive_pair.dart';
import '../../support/plain_text.dart';

Widget _host(double width, double scale, String secondary, String primary) =>
    MaterialApp(
      theme: GrooTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: PResponsivePair(
                secondary: PButton(
                  label: secondary,
                  size: PButtonSize.large,
                  variant: PButtonVariant.neutralWeak,
                  onPressed: () {},
                ),
                primary: PButton(
                  label: primary,
                  size: PButtonSize.large,
                  onPressed: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets('짧은 라벨은 한 줄에 반씩', (tester) async {
    await tester.pumpWidget(_host(342, 1, '취소', '저장'));
    expect(find.byKey(const ValueKey('pair-row')), findsOneWidget);
    final a = tester.getRect(findText('취소'));
    final b = tester.getRect(findText('저장'));
    expect(a.center.dy, b.center.dy);
    expect(a.left, lessThan(b.left), reason: '보조 왼쪽 · 주 오른쪽');
  });

  testWidgets('긴 라벨(360 폭 "엑셀로 내보내기")은 세로로 쌓고 주 버튼이 위다', (tester) async {
    await tester.pumpWidget(_host(312, 1, '취소', '엑셀로 내보내기'));
    expect(find.byKey(const ValueKey('pair-column')), findsOneWidget);
    final primary = tester.getRect(findText('엑셀로 내보내기'));
    final secondary = tester.getRect(findText('취소'));
    expect(primary.top, lessThan(secondary.top), reason: '주 버튼이 위');
    // 라벨은 한 줄 — 넘치지 않는다
    expect(tester.takeException(), isNull);
    expect(primary.height, lessThan(30));
  });

  testWidgets('글자 크기 200% 에서는 짧은 라벨도 쌓이고 넘치지 않는다', (tester) async {
    await tester.pumpWidget(_host(312, 2, '취소', '저장하고 닫기'));
    expect(find.byKey(const ValueKey('pair-column')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('반 폭 판정 — (짝 폭 − 간격) ÷ 2', () {
    expect(PResponsivePair.fitsInRow(312, 150, 100), isTrue);
    expect(PResponsivePair.fitsInRow(312, 155, 100), isFalse);
  });

  test('3:7 몫 판정 — 보조 (폭 − 8) × 0.3 · 주 × 0.7', () {
    // 312 − 8 = 304 → 보조 91.2 · 주 212.8
    expect(
      PResponsivePair.fitsInRow(312, 212, 91, primaryFlex: 7, secondaryFlex: 3),
      isTrue,
    );
    expect(
      PResponsivePair.fitsInRow(312, 213, 91, primaryFlex: 7, secondaryFlex: 3),
      isFalse,
    );
    expect(
      PResponsivePair.fitsInRow(312, 212, 92, primaryFlex: 7, secondaryFlex: 3),
      isFalse,
    );
    // 기본 1:1 은 그대로
    expect(PResponsivePair.fitsInRow(312, 152, 152), isTrue);
    expect(PResponsivePair.fitsInRow(312, 153, 100), isFalse);
  });

  testWidgets('3:7 — 한 줄이면 폭이 3 : 7, 200% 에서는 쌓인다', (tester) async {
    Widget host(double scale) => MaterialApp(
      theme: GrooTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: 312,
              child: PResponsivePair(
                secondaryFlex: 3,
                primaryFlex: 7,
                secondary: PButton(
                  label: '취소',
                  size: PButtonSize.large,
                  variant: PButtonVariant.neutralWeak,
                  onPressed: () {},
                ),
                primary: PButton(
                  label: '설치',
                  size: PButtonSize.large,
                  onPressed: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpWidget(host(1));
    expect(find.byKey(const ValueKey('pair-row')), findsOneWidget);
    final a = tester.getSize(find.byType(PButton).first);
    final b = tester.getSize(find.byType(PButton).last);
    expect(a.width, closeTo(304 * 0.3, 0.01));
    expect(b.width, closeTo(304 * 0.7, 0.01));
    await tester.pumpWidget(host(2));
    expect(find.byKey(const ValueKey('pair-column')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
