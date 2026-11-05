// 카드 · 떠 있는 버튼의 높이 표현 — 카드는 그림자 없이 1px stroke-neutral-weak + 바닥으로 가르고(01A-051),
// 떠 있는 버튼은 Material elevation 0 + shadow-s3 다(01A-052).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/shared/widgets/p_card.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets(
      '${dark ? "다크" : "라이트"} — 옛 PCard 모든 변형에 그림자가 없고, fab 은 elevation 0 + s3',
      (tester) async {
        final theme = dark ? GrooTheme.dark() : GrooTheme.light();
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: Column(
                children: [
                  for (final v in [
                    PCardVariant.shadow,
                    PCardVariant.bordered,
                    PCardVariant.raised,
                  ])
                    PCard(variant: v, child: const SizedBox(height: 20)),
                ],
              ),
            ),
          ),
        );
        final c = theme.extension<PColors>()!;
        for (final deco
            in tester
                .widgetList<Container>(find.byType(Container))
                .map((e) => e.decoration)
                .whereType<BoxDecoration>()
                .where((d) => d.borderRadius != null && d.border != null)) {
          expect(deco.boxShadow, isNull, reason: '카드는 그림자 없이');
          expect((deco.border! as Border).top.color, c.strokeNeutralWeak);
        }
      },
    );
  }
}
