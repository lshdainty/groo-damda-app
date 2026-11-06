// 03-F 고치기만 — 메뉴 시트의 보조 기술용 닫기 노드(03F-020) · 알림 띠 링크의 글자 배율(03F-018).
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/callout/p_callout.dart';
import 'package:groo_damda_app/shared/ds/menu_sheet/p_menu_sheet.dart';
import '../../support/plain_text.dart';

Widget _host(Widget child, {double scale = 1}) => MaterialApp(
  theme: GrooTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('ko'),
  home: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
    child: Scaffold(body: child),
  ),
);

void main() {
  testWidgets('메뉴 시트 — 열린 트리에 "닫기, 버튼" 노드가 크기를 가지고 남는다', (tester) async {
    final handle = tester.ensureSemantics();
    late BuildContext ctx;
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (c) {
            ctx = c;
            return const SizedBox();
          },
        ),
      ),
    );
    PMenuSheet.show(
      ctx,
      title: '박도윤',
      layout: PMenuSheetLayout.textOnly,
      groups: [
        PMenuSheetGroup([PMenuSheetItem(label: '편집 가능으로')]),
      ],
    );
    await tester.pumpAndSettle();
    final box = tester.getSize(
      find.byKey(const ValueKey('p-menu-sheet-close')),
    );
    expect(box.width, greaterThanOrEqualTo(1));
    expect(box.height, greaterThanOrEqualTo(1));
    final nodes = <SemanticsData>[];
    void walk(SemanticsNode n) {
      nodes.add(n.getSemanticsData());
      n.visitChildren((c) {
        walk(c);
        return true;
      });
    }

    walk(tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!);
    expect(nodes.any((n) => n.label.contains('닫기')), isTrue);
    handle.dispose();
  });

  testWidgets('Callout 링크는 글자 배율을 한 번만 받는다 — 200% 에서도 본문 줄 높이', (tester) async {
    await tester.pumpWidget(
      _host(
        PCallout(
          description: '본문 글입니다',
          link: PCalloutLink(label: '링크', onPressed: () {}),
        ),
        scale: 2,
      ),
    );
    final link = tester.getSize(findText('링크')).height;
    // 링크 Text 는 배율을 다시 받지 않는다 — t4 줄 높이 19 그대로(두 번 받으면 38)
    expect(link, closeTo(19, 0.5));
  });
}
