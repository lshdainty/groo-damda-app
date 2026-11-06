// flush 는 한쪽 padding 만 0 이라, 눌렀을 때 채움 상자가 뜨면 글자 기준으로 좌우가
// 비대칭이 되어 버튼이 한쪽으로 삐져나온 것처럼 보인다(웹 2026-09-16 실측).
// flush ghost 는 텍스트 버튼으로 취급한다 — 배경 없이 **글자색**으로만 반응한다
// (spec button.md Edge flush). 웹 `<Button variant="ghost" flush="left">` 미러.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/app/theme/tokens.dart';
import 'package:groo_damda_app/shared/widgets/p_button.dart';
import '../support/plain_text.dart';

Widget _host(Widget child) => MaterialApp(
  theme: GrooTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

Color _labelColor(WidgetTester tester, String label) =>
    tester.widget<Text>(findText(label)).style!.color!;

Color _iconColor(WidgetTester tester) =>
    tester.widget<Icon>(find.byIcon(LucideIcons.eyeOff)).color!;

void main() {
  final tokens = GrooTokens.light;

  testWidgets('flush ghost 는 보조톤에서 시작한다', (tester) async {
    await tester.pumpWidget(
      _host(
        PButton(
          label: '금액 가리기',
          icon: LucideIcons.eyeOff,
          variant: PButtonVariant.ghost,
          flush: PButtonFlush.left,
          onPressed: () {},
        ),
      ),
    );
    expect(_labelColor(tester, '금액 가리기'), tokens.fgSecondary);
    expect(_iconColor(tester), tokens.fgSecondary);
  });

  testWidgets('누르는 동안 본문색이 된다 — 배경은 그대로 없다', (tester) async {
    await tester.pumpWidget(
      _host(
        PButton(
          label: '금액 가리기',
          icon: LucideIcons.eyeOff,
          variant: PButtonVariant.ghost,
          flush: PButtonFlush.left,
          onPressed: () {},
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(findText('금액 가리기')),
    );
    await tester.pump(const Duration(milliseconds: 120));

    expect(_labelColor(tester, '금액 가리기'), tokens.fgPrimary);
    expect(_iconColor(tester), tokens.fgPrimary);

    // 배경은 누르는 동안에도 투명하다 — 상자가 생기면 안 된다.
    final ink = tester.widget<InkWell>(find.byType(InkWell));
    expect(ink.splashColor, Colors.transparent);
    expect(ink.highlightColor, Colors.transparent);
    expect(ink.hoverColor, Colors.transparent);
    final material = tester.widget<Material>(
      find
          .ancestor(of: find.byType(InkWell), matching: find.byType(Material))
          .first,
    );
    expect(material.color, Colors.transparent);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(_labelColor(tester, '금액 가리기'), tokens.fgSecondary);
  });

  testWidgets('flush 를 안 붙인 ghost 는 지금 규칙 그대로다', (tester) async {
    await tester.pumpWidget(
      _host(
        PButton(label: '툴바', variant: PButtonVariant.ghost, onPressed: () {}),
      ),
    );
    expect(_labelColor(tester, '툴바'), tokens.fgPrimary);
    final ink = tester.widget<InkWell>(find.byType(InkWell));
    expect(ink.splashColor, isNull);
    expect(ink.highlightColor, isNull);
  });
}
