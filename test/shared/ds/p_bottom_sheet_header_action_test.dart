// Bottom Sheet 머리 오른쪽 동작 자리(headerAction) — 닫기 원 왼쪽 사이 4 · 보이는 단추 36 · 제목은 남은 폭에서 줄을 바꾸고
// 겹치지 않으며(글자 200% 포함) 초점 차례는 제목 → 동작 → 닫기다. 웹 `src/shared/ds/dialog/header-action.test.tsx` 와 같은 값.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import '../../support/plain_text.dart';

Widget _app(Widget home, {double scale = 1}) => MaterialApp(
  theme: GrooTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('ko'),
  builder: (c, child) => MediaQuery(
    data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: home,
);

Widget _host({
  required String title,
  bool closeButton = true,
  VoidCallback? onAction,
}) => Scaffold(
  body: Builder(
    builder: (context) => Center(
      child: TextButton(
        onPressed: () => PBottomSheet.show<void>(
          context,
          builder: (_) => PBottomSheetContent(
            title: title,
            closeLabel: '닫기',
            showCloseButton: closeButton,
            headerAction: PButton.icon(
              icon: LucideIcons.ellipsisVertical,
              semanticLabel: '식비 더보기',
              variant: PButtonVariant.ghost,
              ghostColor: PButtonGhostColor.neutralSubtle,
              size: PButtonSize.small,
              onPressed: onAction,
            ),
            body: const SizedBox(height: 40),
          ),
        ),
        child: const Text('열기'),
      ),
    ),
  ),
);

Future<void> _open(WidgetTester tester, Widget app) async {
  tester.view.physicalSize = const Size(360, 760);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(app);
  await tester.tap(findText('열기'));
  await tester.pumpAndSettle();
}

Rect _rect(WidgetTester t, Finder f) => t.getRect(f);

void main() {
  const actionKey = ValueKey('p-bottom-sheet-header-action');

  testWidgets('단추 36 은 닫기 원 왼쪽 끝에서 4 떨어져 같은 가운데에 선다', (tester) async {
    await _open(tester, _app(_host(title: '카테고리 수정')));
    final circle = _rect(
      tester,
      find.byKey(const ValueKey('p-bottom-sheet-close-circle')),
    );
    final button = _rect(
      tester,
      find.descendant(
        of: find.byKey(actionKey),
        matching: find.byType(PButton),
      ),
    );
    expect(button.width, 36);
    expect(button.height, 36);
    expect(circle.left - button.right, 4);
    expect(button.center.dy, circle.center.dy);
    // 누르는 영역은 사방 4 넓은 44
    expect(_rect(tester, find.byKey(actionKey)).size, const Size(44, 44));
  });

  testWidgets('닫기 버튼이 없으면 오른쪽 끝(화면 여백 24)에 선다', (tester) async {
    await _open(tester, _app(_host(title: '카테고리 수정', closeButton: false)));
    final button = _rect(
      tester,
      find.descendant(
        of: find.byKey(actionKey),
        matching: find.byType(PButton),
      ),
    );
    expect(button.right, 360 - 24);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('긴 제목은 남은 폭에서 줄을 바꾸고 동작 · 닫기와 겹치지 않는다 (글자 ${scale * 100}%)', (
      tester,
    ) async {
      await _open(
        tester,
        _app(_host(title: '카페·간식·디저트 모임 지출 항목 카테고리 수정'), scale: scale),
      );
      final title = _rect(
        tester,
        find.byKey(const ValueKey('p-bottom-sheet-title')),
      );
      final action = _rect(
        tester,
        find.descendant(
          of: find.byKey(actionKey),
          matching: find.byType(PButton),
        ),
      );
      final close = _rect(
        tester,
        find.byKey(const ValueKey('p-bottom-sheet-close-circle')),
      );
      expect(title.right, lessThanOrEqualTo(action.left));
      expect(action.right, lessThanOrEqualTo(close.left));
      expect(title.overlaps(action), isFalse);
      expect(title.overlaps(close), isFalse);
      if (scale > 1) expect(title.height, greaterThan(40));
    });
  }

  testWidgets('동작을 누르면 호출되고 이름이 읽힌다', (tester) async {
    var called = 0;
    await _open(
      tester,
      _app(_host(title: '카테고리 수정', onAction: () => called++)),
    );
    expect(find.bySemanticsLabel('식비 더보기'), findsOneWidget);
    await tester.tap(find.byKey(actionKey));
    await tester.pump();
    expect(called, 1);
  });

  testWidgets('읽는 차례는 제목 → 동작 → 닫기 (앱 포커스는 터치 기준이라 위젯 차례로 잰다)', (tester) async {
    await _open(tester, _app(_host(title: '카테고리 수정')));
    final all = tester.allElements.toList();
    int at(Key key) => all.indexWhere((e) => e.widget.key == key);
    final title = at(const ValueKey('p-bottom-sheet-title'));
    final action = at(actionKey);
    final close = at(const ValueKey('p-bottom-sheet-close'));
    expect(title, greaterThan(-1));
    expect(title, lessThan(action));
    expect(action, lessThan(close));
  });
}
