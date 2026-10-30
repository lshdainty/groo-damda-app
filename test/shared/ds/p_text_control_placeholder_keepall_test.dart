// 예시 글(placeholder)만 낱말 단위(Typography v114)로 그리고, 입력 중인 글 · 저장 값에는 U+2060 이 섞이지 않는다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/textarea/p_textarea.dart';

const _joiner = '⁠';
const _hint = '검진 전 금식하고 신분증 챙기기';

Widget _host(Widget child) => MaterialApp(
  theme: GrooTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('ko'),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: 200, child: child),
    ),
  ),
);

void main() {
  for (final textarea in [false, true]) {
    testWidgets('${textarea ? "Textarea" : "Input"} 예시 글만 낱말 단위, 값은 깨끗하다', (
      t,
    ) async {
      final c = TextEditingController();
      final changes = <String>[];
      await t.pumpWidget(
        _host(
          textarea
              ? PTextarea(
                  controller: c,
                  placeholder: _hint,
                  semanticLabel: '설명',
                  onChanged: changes.add,
                )
              : PInput(
                  controller: c,
                  placeholder: _hint,
                  semanticLabel: '장소',
                  onChanged: changes.add,
                ),
        ),
      );
      final hint = t.widget<Text>(
        find.byWidgetPredicate(
          (w) => w is Text && w.data?.contains(_joiner) == true,
        ),
      );
      expect(hint.data!.replaceAll(_joiner, ''), _hint);
      expect(c.text, '');

      await t.enterText(find.byType(TextField), '치과 3층 상담실');
      await t.pump();
      expect(c.text, '치과 3층 상담실');
      expect(c.text.contains(_joiner), isFalse);
      expect(changes.every((v) => !v.contains(_joiner)), isTrue);
      expect(
        find.byWidgetPredicate(
          (w) => w is Text && w.data?.contains(_joiner) == true,
        ),
        findsNothing,
      );
    });
  }
}
