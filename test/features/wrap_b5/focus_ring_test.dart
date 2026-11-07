// B5-3 — 키보드(Tab)로 초점을 받는 모든 것에 링, 터치로 눌러서는 링 없음.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/stocks/presentation/stocks_parts.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/chip/p_chip.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/text_button/p_text_button.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';

Widget _app(Widget body) => MaterialApp(
  theme: GrooTheme.light(),
  locale: const Locale('ko'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: Center(child: SizedBox(width: 312, child: body)),
  ),
);

int _rings() => find.byKey(const ValueKey('focus-ring')).evaluate().length;

Future<void> _tab(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.pump();
}

void main() {
  final parts = <String, Widget Function()>{
    'PListButtonItem': () => PListButtonItem(title: '줄', onTap: () {}),
    'PChip': () => PChip(label: '칩', onPressed: () {}),
    'PChipRadio': () => PChipRadioGroup<String>(
      value: 'b',
      onChanged: (_) {},
      children: const [PChipRadio<String>(value: 'a', label: '칩')],
    ),
    'PTopNavigationIconButton': () =>
        PTopNavigationIconButton.back(label: '뒤로', onPressed: () {}),
    'PTopNavigationTextButton': () =>
        PTopNavigationTextButton(label: '완료', onPressed: () {}),
    'StocksSearchEntry': () => StocksSearchEntry(onTap: () {}),
    'PTextButton': () => PTextButton(label: '전체 보기', onPressed: () {}),
    'PButton(기준)': () => PButton(label: '확인', onPressed: () {}),
  };

  for (final e in parts.entries) {
    testWidgets('${e.key} — Tab 으로 초점을 받으면 링이 그려진다', (tester) async {
      await tester.pumpWidget(_app(e.value()));
      await tester.pumpAndSettle();
      expect(_rings(), 0);
      await _tab(tester);
      final f = FocusManager.instance.primaryFocus;
      expect(f, isNotNull);
      expect(f is FocusScopeNode, isFalse, reason: '범위 노드가 아니라 부품이 초점을 받아야 한다');
      expect(_rings(), 1);
      // 초점이 나가면 링도 사라진다
      FocusManager.instance.primaryFocus!.unfocus();
      await tester.pumpAndSettle();
      expect(_rings(), 0);
    });

    testWidgets('${e.key} — 터치로 눌러서는 링이 없다', (tester) async {
      await tester.pumpWidget(_app(e.value()));
      await tester.pumpAndSettle();
      // 터치 입력 — highlightMode 가 touch 가 된다
      final g = await tester.startGesture(
        tester.getCenter(find.byType(Scaffold)),
        kind: PointerDeviceKind.touch,
      );
      await g.up();
      await tester.pumpAndSettle();
      expect(FocusManager.instance.highlightMode, FocusHighlightMode.touch);
      expect(_rings(), 0);
    });
  }

  testWidgets('PTextButton — Enter 로 누른다(초점만이 아니라 눌린다)', (tester) async {
    var n = 0;
    await tester.pumpWidget(
      _app(PTextButton(label: '전체 보기', onPressed: () => n++)),
    );
    await _tab(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(n, 2);
  });

  testWidgets('종목 찾기 입구 — 링은 입구 전체 상자(312x40) 둘레다', (tester) async {
    await tester.pumpWidget(_app(StocksSearchEntry(onTap: () {})));
    await tester.pumpAndSettle();
    await _tab(tester);
    final box = tester.getSize(
      find.byKey(const ValueKey('stocks-search-entry')),
    );
    final ring = tester.getSize(find.byKey(const ValueKey('focus-ring')));
    // 띄움 2 + 두께 2 를 사방에 더한 크기
    expect(ring.width, box.width + 8);
    expect(ring.height, box.height + 8);
  });

  testWidgets('줄 · 상단 바 단추의 링은 상자 안쪽이다(화면 폭에서 잘리지 않는다)', (tester) async {
    await tester.pumpWidget(_app(PListButtonItem(title: '줄', onTap: () {})));
    await tester.pumpAndSettle();
    await _tab(tester);
    final row = tester.getRect(find.byKey(const ValueKey('plist-item')));
    final ring = tester.getRect(find.byKey(const ValueKey('focus-ring')));
    expect(ring, row);
  });
}
