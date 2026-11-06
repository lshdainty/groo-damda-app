// 글자 자간은 SoT 토큰대로다 — Material 3 기본 자간이 새지 않는다(2026-09-22).
//
// 토큰(DESIGN.desk.md typography)에서 자간이 있는 건 display-xl/lg/md 와 overline 뿐이다.
// PTypo 가 letterSpacing 을 비워 두던 동안 ThemeData 가 그 자리를 Material 3 기본값
// (bodyMedium 0.25 · bodyLarge 0.5 · bodySmall 0.4 · labelMedium 0.5 …)으로 채웠고, 그 값이
// DefaultTextStyle 을 타고 앱 글자 거의 전부에 번졌다. 같은 문구가 웹보다 넓게 그려졌다 —
// 결제가 끝난 회차 안내가 390 폭에서 3줄로 접힌 원인 중 하나였다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/app/theme/typography.dart';
import '../../support/plain_text.dart';

void main() {
  for (final (name, theme) in [
    ('light', GrooTheme.light()),
    ('dark', GrooTheme.dark()),
  ]) {
    test('$name — 테마 글꼴 15개의 자간이 토큰과 같다', () {
      final tt = theme.textTheme;
      final got = {
        'displayLarge': tt.displayLarge?.letterSpacing,
        'displayMedium': tt.displayMedium?.letterSpacing,
        'displaySmall': tt.displaySmall?.letterSpacing,
        'headlineLarge': tt.headlineLarge?.letterSpacing,
        'headlineMedium': tt.headlineMedium?.letterSpacing,
        'headlineSmall': tt.headlineSmall?.letterSpacing,
        'titleLarge': tt.titleLarge?.letterSpacing,
        'titleMedium': tt.titleMedium?.letterSpacing,
        'titleSmall': tt.titleSmall?.letterSpacing,
        'bodyLarge': tt.bodyLarge?.letterSpacing,
        'bodyMedium': tt.bodyMedium?.letterSpacing,
        'bodySmall': tt.bodySmall?.letterSpacing,
        'labelLarge': tt.labelLarge?.letterSpacing,
        'labelMedium': tt.labelMedium?.letterSpacing,
        'labelSmall': tt.labelSmall?.letterSpacing,
      };
      expect(got, {
        'displayLarge': -0.4, // display-lg
        'displayMedium': -0.32, // display-md
        'displaySmall': PTypo.h1.letterSpacing, // h1 30px — 토큰 크기표 밖, 그대로
        'headlineLarge': PTypo.h1.letterSpacing,
        'headlineMedium': 0.0, // display-sm
        'headlineSmall': 0.0, // title-lg
        'titleLarge': 0.0, // title-lg
        'titleMedium': 0.0, // title-md
        'titleSmall': 0.0,
        'bodyLarge': 0.0,
        'bodyMedium': 0.0,
        'bodySmall': 0.0,
        'labelLarge': 0.0,
        'labelMedium': 0.0,
        'labelSmall': 0.0,
      });
    });
  }

  testWidgets('스타일을 안 준 글자와 입력칸 글자도 자간 0 — 화면 안 DefaultTextStyle', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: GrooTheme.light(),
        home: const Scaffold(
          body: Column(children: [Text('기본 글자'), TextField()]),
        ),
      ),
    );
    final text = tester.element(findText('기본 글자'));
    expect(DefaultTextStyle.of(text).style.letterSpacing, 0);
    await tester.enterText(find.byType(TextField), '입력');
    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.style.letterSpacing, 0);
  });
}
