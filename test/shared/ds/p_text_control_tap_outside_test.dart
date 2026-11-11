// 칸 밖을 누르면 키보드가 내려간다(시험 2026-11-11 DA-03 ②) — 다른 칸 · 단추를 누른 것은 그대로 한 번에 먹는다.
// 같은 자리에서 DA-06(글자를 친 직후 머리 [완료] 첫 탭) 이 헤드리스에서 재현되는지도 잰다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/forms/step_done.dart';
import '../../support/plain_text.dart';

Widget _app(Widget home) => MaterialApp(
  theme: GrooTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('ko'),
  home: home,
);

void main() {
  late FocusNode a;
  late FocusNode b;
  late TextEditingController ca;
  var doneTaps = 0;
  var buttonTaps = 0;

  Future<void> pumpForm(WidgetTester tester, {bool inSheet = false}) async {
    tester.view.physicalSize = const Size(1170, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    a = FocusNode();
    b = FocusNode();
    ca = TextEditingController();
    doneTaps = 0;
    buttonTaps = 0;
    Widget form(BuildContext c) => Column(
      children: [
        PInput(controller: ca, focusNode: a, semanticLabel: '장소'),
        const SizedBox(height: 40, key: ValueKey('blank')),
        PInput(focusNode: b, semanticLabel: '메모'),
        TextButton(onPressed: () => buttonTaps++, child: const Text('단추')),
      ],
    );
    if (!inSheet) {
      await tester.pumpWidget(_app(Scaffold(body: Builder(builder: form))));
    } else {
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: Builder(
              builder: (ctx) => TextButton(
                onPressed: () => PBottomSheet.show<void>(
                  ctx,
                  builder: (c) => PBottomSheetContent(
                    title: '장소',
                    closeLabel: '닫기',
                    showCloseButton: false,
                    headerAction: StepDoneButton(
                      label: '완료',
                      onPressed: () => doneTaps++,
                    ),
                    body: Builder(builder: form),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(findText('open'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
    }
  }

  testWidgets('빈 곳을 누르면 초점이 풀린다(키보드가 내려간다)', (tester) async {
    await pumpForm(tester);
    await tester.tap(find.byType(TextField).first);
    await tester.pump();
    expect(a.hasFocus, isTrue);
    await tester.tapAt(tester.getCenter(find.byKey(const ValueKey('blank'))));
    await tester.pumpAndSettle();
    expect(a.hasFocus, isFalse);
  });

  testWidgets('다른 칸을 누르면 그 칸이 한 번에 초점을 받는다', (tester) async {
    await pumpForm(tester);
    await tester.tap(find.byType(TextField).first);
    await tester.pump();
    await tester.tap(find.byType(TextField).last);
    await tester.pumpAndSettle();
    expect(b.hasFocus, isTrue);
    expect(a.hasFocus, isFalse);
  });

  testWidgets('단추는 한 번 눌러 한 번 먹고, 그 뒤 키보드가 내려간다', (tester) async {
    await pumpForm(tester);
    await tester.tap(find.byType(TextField).first);
    await tester.pump();
    await tester.tap(findText('단추'));
    await tester.pumpAndSettle();
    expect(buttonTaps, 1);
    expect(a.hasFocus, isFalse);
  });

  testWidgets('끌기로 시작한 손짓도 키보드를 내린다(누르는 순간에 푼다)', (tester) async {
    await pumpForm(tester);
    await tester.tap(find.byType(TextField).first);
    await tester.pump();
    await tester.timedDragFrom(
      tester.getCenter(find.byKey(const ValueKey('blank'))),
      const Offset(0, -80),
      const Duration(milliseconds: 200),
    );
    await tester.pumpAndSettle();
    expect(a.hasFocus, isFalse);
  });

  testWidgets('DA-06 재현 — 글자를 친 직후 시트 머리 [완료] 한 번 탭이 먹는다', (tester) async {
    await pumpForm(tester, inSheet: true);
    await tester.tap(find.byType(TextField).first);
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'a');
    await tester.pump();
    await tester.tap(findText('완료'));
    await tester.pumpAndSettle();
    expect(doneTaps, 1);
  });

  testWidgets('DA-06 재현 2 — 키보드(viewInsets)가 떠 시트가 줄어든 채로도 한 번 탭이 먹는다', (
    tester,
  ) async {
    await pumpForm(tester, inSheet: true);
    await tester.tap(find.byType(TextField).first);
    await tester.pump();
    tester.view.viewInsets = const FakeViewPadding(bottom: 1008);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'a');
    await tester.pump();
    await tester.tap(findText('완료'));
    await tester.pumpAndSettle();
    expect(doneTaps, 1);
  });
}
