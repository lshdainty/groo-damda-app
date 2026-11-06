// 모달 footer 버튼은 라벨만 — 아이콘을 붙이지 않는다(spec drawer.md 액션 구성).
//
// 공용 footer 가 삭제 앞에 휴지통, 수정 앞에 연필을 넣고 있었다. 호출부가 아니라
// 공용 쪽이라 한 번 새면 모든 시트에 한꺼번에 돌아온다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/widgets/p_modal.dart';
import '../support/plain_text.dart';

Widget _host(Widget child) => MaterialApp(
  theme: GrooTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('ko'),
  home: Scaffold(body: child),
);

void main() {
  testWidgets('PViewFooter 는 삭제·수정에 아이콘을 두지 않는다', (tester) async {
    await tester.pumpWidget(_host(PViewFooter(onDelete: () {}, onEdit: () {})));

    // 라벨은 그대로 있다.
    expect(findText('삭제'), findsOneWidget);
    expect(findText('수정'), findsOneWidget);

    // 아이콘은 없다.
    expect(find.byIcon(LucideIcons.trash2), findsNothing);
    expect(find.byIcon(LucideIcons.pencil), findsNothing);
  });

  testWidgets('PSheetFooter 는 삭제·저장에 아이콘을 두지 않는다', (tester) async {
    final controller = PSheetController()..onDelete = () async {};
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _host(PSheetFooter(controller: controller, submitLabel: '저장')),
    );

    expect(findText('삭제'), findsOneWidget);
    expect(findText('저장'), findsOneWidget);

    expect(find.byIcon(LucideIcons.trash2), findsNothing);
  });
}
