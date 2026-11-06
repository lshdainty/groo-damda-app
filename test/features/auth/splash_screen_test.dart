// 첫 화면(I-05 13 · 85) — 나무 + 이름 한 묶음이 화면 정중앙, 원 40 brand 는 묶음 아래 32.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/auth/presentation/splash_screen.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/brand/groo_tree.dart';
import 'package:groo_damda_app/shared/ds/progress_circle/p_progress_circle.dart';
import '../../support/plain_text.dart';

Future<void> _pump(
  WidgetTester tester, {
  required bool dark,
  required double scale,
}) async {
  tester.view.physicalSize = const Size(360 * 3, 780 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: dark ? GrooTheme.dark() : GrooTheme.light(),
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: const SplashScreen(),
    ),
  );
  await tester.pump();
}

void main() {
  for (final dark in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        '${dark ? "다크" : "라이트"} · 글자 ${(scale * 100).round()}% — 묶음이 정중앙, 원은 묶음 아래 32',
        (tester) async {
          await _pump(tester, dark: dark, scale: scale);
          final c = (dark ? GrooTheme.dark() : GrooTheme.light())
              .extension<PColors>()!;
          expect(
            tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
            c.bgLayerDefault,
          );
          final tree = tester.getRect(find.byType(GrooTree));
          final name = tester.getRect(findText('그루 담다'));
          expect(tree.height, 96);
          expect(name.top - tree.bottom, closeTo(16, 1), reason: '나무 ↔ 이름 16');
          // 묶음 = 나무 위 ~ 이름 아래
          final bundle = Rect.fromLTRB(
            tree.left < name.left ? tree.left : name.left,
            tree.top,
            tree.right > name.right ? tree.right : name.right,
            name.bottom,
          );
          if (scale == 1.0) {
            expect(bundle.height, closeTo(152, 3), reason: '96 + 16 + 40');
          }
          // 이름 줄 상자(글자 줄 높이)가 아니라 위젯 상자로 잰다 — 정중앙 ±1
          final mark = tester.getRect(find.byType(GrooTree));
          final screenH = tester.view.physicalSize.height / 3;
          final textBox = tester.getRect(
            find
                .ancestor(of: findText('그루 담다'), matching: find.byType(Column))
                .first,
          );
          expect(
            (textBox.center.dy - screenH / 2).abs(),
            lessThanOrEqualTo(1),
            reason: '묶음 가운데 = 화면 가운데 (${textBox.center.dy} vs ${screenH / 2})',
          );
          expect(mark.center.dx, closeTo(180, 1));
          final circle = tester.getRect(find.byType(PProgressCircle));
          expect(circle.size, const Size(40, 40));
          expect(
            circle.top - textBox.bottom,
            closeTo(32, 1),
            reason: '원은 묶음 아래 32',
          );
          expect(
            tester.widget<PProgressCircle>(find.byType(PProgressCircle)).tone,
            PProgressCircleTone.brand,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
