// 필터 금액 범위 — 100억을 넘겨 치면 막고 그 줄 아래에 알린다(웹 FilterAmountBody 와 같다).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/expense/domain/expense_filter.dart';
import 'package:groo_damda_app/features/expense/presentation/widgets/filter_bodies.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import '../../support/plain_text.dart';

void main() {
  testWidgets('100억 넘게 치면 막고 줄 아래에 알린다 — 다음 유효한 입력에서 사라진다', (tester) async {
    List<AmountRange>? last;
    await tester.pumpWidget(
      MaterialApp(
        theme: GrooTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: FilterAmountBody(
              initial: const [AmountRange(), AmountRange()],
              onChanged: (v) => last = v,
            ),
          ),
        ),
      ),
    );
    const msg = '금액은 100억원까지 입력할 수 있어요.';
    final fields = find.byType(EditableText);
    await tester.enterText(fields.at(0), '10000000000');
    await tester.pump();
    expect(findPlain(msg), findsNothing, reason: '정확히 100억은 받는다');

    await tester.enterText(fields.at(0), '100000000000');
    await tester.pump();
    expect(findPlain(msg), findsOneWidget);
    expect(last!.first.min, 10000000000, reason: '넘는 글자는 받지 않는다');

    // 다른 줄에서 유효한 입력을 해도 그 줄의 오류는 그 줄의 다음 입력에서 걷힌다
    await tester.enterText(fields.at(0), '5000');
    await tester.pump();
    expect(findPlain(msg), findsNothing);
  });
}
