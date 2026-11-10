// Bottom Sheet 머리 왼쪽 뒤로 가기(onBack) — 보이는 원 40 · 아이콘 24 · 누르는 44, 아이콘이 화면 여백 24 에 오고 제목은 원 오른쪽
// 사이 4 에서 시작한다. 읽는 차례는 뒤로 → 제목 → 동작 → 닫기. 웹 `src/shared/ds/dialog/header-back.test.tsx` 와 같은 값.
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
  String title = '신용카드 추가',
  VoidCallback? onBack,
  bool action = false,
}) => Scaffold(
  body: Builder(
    builder: (context) => Center(
      child: TextButton(
        onPressed: () => PBottomSheet.show<void>(
          context,
          form: true,
          builder: (_) => PBottomSheetContent(
            title: title,
            closeLabel: '닫기',
            onBack: onBack,
            backLabel: onBack == null ? null : '뒤로',
            headerAction: action
                ? PButton.icon(
                    icon: LucideIcons.ellipsisVertical,
                    semanticLabel: '더보기',
                    variant: PButtonVariant.ghost,
                    size: PButtonSize.small,
                    onPressed: () {},
                  )
                : null,
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

void main() {
  const backKey = ValueKey('p-bottom-sheet-back');
  const circleKey = ValueKey('p-bottom-sheet-back-circle');
  const titleKey = ValueKey('p-bottom-sheet-title');

  testWidgets('원 40 · 아이콘 24 가 화면 여백 24 에 오고 누르는 영역은 44, 제목은 사이 4', (
    tester,
  ) async {
    await _open(tester, _app(_host(onBack: () {})));
    final circle = tester.getRect(find.byKey(circleKey));
    final icon = tester.getRect(find.byIcon(LucideIcons.chevronLeft));
    final touch = tester.getRect(find.byKey(backKey));
    final title = tester.getRect(find.byKey(titleKey));
    expect(circle.size, const Size(40, 40));
    expect(icon.size, const Size(24, 24));
    // 11-10 8A — 돌아가기는 모두 꺾쇠(chevron-left)다, 화살표(arrow-left)가 아니다
    expect(find.byIcon(LucideIcons.arrowLeft), findsNothing);
    expect(icon.left, 24);
    expect(touch.size, const Size(44, 44));
    expect(touch.center, circle.center);
    expect(title.left - circle.right, 4);
    // 세로는 제목 첫 줄(30) 가운데
    expect(circle.center.dy, title.top + 15);
  });

  testWidgets('이름 "뒤로" 로 읽히고 누르면 부른다', (tester) async {
    var called = 0;
    await _open(tester, _app(_host(onBack: () => called++)));
    expect(find.bySemanticsLabel('뒤로'), findsOneWidget);
    await tester.tap(find.byKey(backKey));
    await tester.pump();
    expect(called, 1);
  });

  testWidgets('onBack 이 없으면 단추도 제목 들임도 없다', (tester) async {
    await _open(tester, _app(_host()));
    expect(find.byKey(backKey), findsNothing);
    expect(tester.getRect(find.byKey(titleKey)).left, 24);
  });

  testWidgets('읽는 차례는 뒤로 → 제목 → 동작 → 닫기', (tester) async {
    await _open(tester, _app(_host(onBack: () {}, action: true)));
    final all = tester.allElements.toList();
    int at(Key key) => all.indexWhere((e) => e.widget.key == key);
    final back = at(backKey);
    final title = at(titleKey);
    final action = at(const ValueKey('p-bottom-sheet-header-action'));
    final close = at(const ValueKey('p-bottom-sheet-close'));
    expect(back, greaterThan(-1));
    expect(back, lessThan(title));
    expect(title, lessThan(action));
    expect(action, lessThan(close));
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('긴 제목도 뒤로 · 닫기와 겹치지 않는다 (글자 ${scale * 100}%)', (tester) async {
      await _open(
        tester,
        _app(
          _host(title: '마이너스 통장 추가 또는 수정', onBack: () {}),
          scale: scale,
        ),
      );
      final back = tester.getRect(find.byKey(circleKey));
      final title = tester.getRect(find.byKey(titleKey));
      final close = tester.getRect(
        find.byKey(const ValueKey('p-bottom-sheet-close-circle')),
      );
      expect(title.overlaps(back), isFalse);
      expect(title.overlaps(close), isFalse);
      // 글자가 커져도 원은 제목 첫 줄 가운데에 선다
      final firstLine = 30 * scale;
      expect(back.center.dy, closeTo(title.top + firstLine / 2, 0.5));
    });
  }
}
