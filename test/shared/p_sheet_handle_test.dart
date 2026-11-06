// 시트 드래그 핸들은 40×4 가운데 조각이다. Column 이 stretch 라 width 가 무시돼
// 전체 폭 선이 헤더 위에 그어졌던 적이 있다(2026-09-03 신고).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/widgets/p_modal.dart';
import '../support/plain_text.dart';

void main() {
  testWidgets('드래그 핸들은 전체 폭으로 늘어나지 않는다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Builder(
          builder: (ctx) => TextButton(
            onPressed: () => showPSheet<void>(
              ctx,
              title: '투자 상세',
              contentBuilder: (_, _) => const SizedBox(height: 200),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(findText('open'));
    await tester.pumpAndSettle();

    final handle = find.byWidgetPredicate(
      (w) => w is Container && w.constraints?.maxWidth == 40,
    );
    expect(handle, findsOneWidget);
    expect(tester.getSize(handle).width, 40);
  });
}
