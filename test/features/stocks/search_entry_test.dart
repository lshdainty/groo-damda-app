import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/stocks/application/stocks_providers.dart';
import 'package:groo_damda_app/features/stocks/presentation/stocks_parts.dart';
import 'package:groo_damda_app/features/stocks/presentation/watch_actions.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';

Future<void> _pump(WidgetTester t) => t.pumpWidget(
  ProviderScope(
    overrides: [stockSearchResultProvider.overrideWith((ref, q) async => [])],
    child: MaterialApp(
      theme: GrooTheme.light(),
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: StocksSearchEntry(
            onTap: () => showStockSearchSheet(context, onPick: (_) {}),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('종목 찾기 입구 — 역할 단추 · 이름 "종목 검색" (입력칸이 아니다)', (t) async {
    final handle = t.ensureSemantics();
    await _pump(t);
    final node = t.getSemantics(
      find.byKey(const ValueKey('stocks-search-entry')),
    );
    expect(node.label, '종목 검색');
    // ignore: deprecated_member_use
    expect(node.hasFlag(SemanticsFlag.isButton), isTrue);
    // ignore: deprecated_member_use
    expect(node.hasFlag(SemanticsFlag.isTextField), isFalse);
    handle.dispose();
  });

  testWidgets('누르면 시트 안 입력칸에 초점, 닫으면 초점은 입구로', (t) async {
    await _pump(t);
    await t.tap(find.byKey(const ValueKey('stocks-search-entry')));
    await t.pumpAndSettle();
    final field = find.byType(EditableText);
    expect(field, findsOneWidget);
    expect(t.widget<EditableText>(field).focusNode.hasFocus, isTrue);
    // 시트 닫기
    final nav = Navigator.of(t.element(field), rootNavigator: true);
    nav.pop();
    await t.pumpAndSettle();
    expect(find.byType(EditableText), findsNothing);
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'stocks search entry',
    );
  });
}
