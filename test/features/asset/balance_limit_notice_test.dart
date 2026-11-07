// 잔액 · 한도 칸 — 1,000억을 넘겨 치면 막고 칸 아래에 알린다(100억 칸과 같은 꼴, 숫자만 다름).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/asset/presentation/asset_form_parts.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import '../../support/plain_text.dart';

void main() {
  testWidgets('1,000억 넘게 치면 막고 알린다 — 다음 유효한 입력에서 사라진다', (tester) async {
    final ctrl = TextEditingController();
    addTearDown(ctrl.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: GrooTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AssetAmountField(label: '잔액', controller: ctrl, unit: '원'),
        ),
      ),
    );
    const msg = '금액은 1,000억원까지 입력할 수 있어요.';
    await tester.enterText(find.byType(EditableText), '100000000000');
    await tester.pump();
    expect(ctrl.text, '100,000,000,000');
    expect(findPlain(msg), findsNothing);

    await tester.enterText(find.byType(EditableText), '1000000000000');
    await tester.pump();
    expect(ctrl.text, '100,000,000,000', reason: '넘는 글자는 받지 않는다');
    expect(findPlain(msg), findsOneWidget);

    await tester.enterText(find.byType(EditableText), '5000');
    await tester.pump();
    expect(findPlain(msg), findsNothing);
  });
}
