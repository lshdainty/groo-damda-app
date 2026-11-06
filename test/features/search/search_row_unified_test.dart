// 검색 결과가 **가계부 목록과 같은 모양**인지 고정한다(#166).
//
// 예전에는 검색이 자체 _ResultRow 를 그렸다 — 부제가 "카테고리 · 날짜" 이고 금액에
// 단위 '원' 이 없었으며(`-3,000`), 행 사이에 구분선(indent 60)이 있었다. 같은 거래가
// 가계부에서는 "카테고리 · 자산 · 시각" + `-3,000원` + 구분선 없음으로 보였다.
//
// 지금은 둘 다 ExpenseRow 를 쓰고 날짜는 PDayHeader 로 묶는다. 여기서 보는 것은
// 그 셋이다 — 행 위젯 · 금액 단위 · 구분선 없음.
//
// I-wrap-b1 α — 옛 부품(AppBar · PTabs · PSearchField · PDateInput · PButton · showPSheet)을 ds 로 옮긴 것도 잠근다:
// 상단 바 제목 자리 검색칸 · 칩 줄(Scroll Auto Hide) · 흰 면 하나 · 실패는 고정 글 + [다시 시도](서버 글 · 예외 글 없음) ·
// 글자 200% 에서 칩 글이 잘리지 않음 · 고급 필터 시트(ds Bottom Sheet · 최소 > 최대 막음).
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/data/expense_repository.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/search/presentation/search_screen.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/widgets/p_day_group.dart';
import 'package:groo_damda_app/shared/widgets/p_divider.dart';
import 'package:groo_damda_app/features/expense/presentation/widgets/expense_row.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/shared/ds/chip/p_chip.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/scroll_auto_hide/p_scroll_auto_hide.dart';
import 'package:groo_damda_app/shared/ds/screen_band/p_screen_band.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../support/plain_text.dart';

/// 검색만 답하는 대역 — 나머지 메서드는 이 화면이 안 부른다. [fail] 이 있으면 그 예외를 던진다(부를 때마다 하나씩 꺼낸다).
class _FakeRepo extends ExpenseRepository {
  _FakeRepo(this.rows, {List<Object?>? fail}) : fail = fail ?? [], super(Dio());
  final List<Expense> rows;
  final List<Object?> fail;
  int calls = 0;
  String? lastType;
  int? lastMin;
  int? lastMax;
  String? lastStart;
  String? lastEnd;

  /// [hold] 면 부를 때마다 답을 기다리는 Completer 를 쌓는다 — 늦게 오는 답을 흉내 낸다.
  final List<Completer<List<Expense>>> pending = [];
  bool hold = false;

  @override
  Future<List<Expense>> search({
    int? categoryId,
    int? assetId,
    String? expenseType,
    String? keyword,
    String? merchant,
    int? minAmount,
    int? maxAmount,
    String? startDate,
    String? endDate,
    bool? fixed,
  }) async {
    calls++;
    lastType = expenseType;
    lastMin = minAmount;
    lastMax = maxAmount;
    lastStart = startDate;
    lastEnd = endDate;
    if (hold) {
      final c = Completer<List<Expense>>();
      pending.add(c);
      return c.future;
    }
    if (fail.isNotEmpty) {
      final e = fail.removeAt(0);
      if (e != null) throw e;
    }
    return rows;
  }
}

Expense _e({
  required int rowId,
  required int amount,
  required String date,
  String type = 'EXPENSE',
  String? merchant,
}) => Expense(
  rowId: rowId,
  expenseType: type,
  amount: amount,
  expenseDate: date,
  merchant: merchant ?? '가맹점 $rowId',
  description: '메모 $rowId',
  categoryName: '식비',
);

Future<_FakeRepo> _pump(
  WidgetTester tester,
  List<Expense> rows, {
  List<Object?>? fail,
  double textScale = 1,
}) async {
  final repo = _FakeRepo(rows, fail: fail);
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: '/search',
    routes: [GoRoute(path: '/search', builder: (_, _) => const SearchScreen())],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        expenseRepositoryProvider.overrideWith((ref) async => repo),
        categoriesProvider.overrideWith((ref) async => const []),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

/// 검색어를 넣고 디바운스(350ms)를 흘려 결과를 받는다.
Future<void> _search(WidgetTester tester, String q) async {
  await tester.enterText(
    find.descendant(
      of: find.byKey(const ValueKey('search-field')),
      matching: find.byType(EditableText),
    ),
    q,
  );
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}

Future<void> _openAdvanced(WidgetTester tester) async {
  await tester.tap(find.byIcon(LucideIcons.slidersHorizontal));
  await tester.pumpAndSettle();
}

/// 고급 필터 시트의 금액 칸 — 0 최소 · 1 최대(맨 앞은 바의 검색칸).
Finder _amountField(int i) => find
    .descendant(of: find.byType(PInput), matching: find.byType(EditableText))
    .at(i + 1);

void main() {
  testWidgets('결과 행이 가계부와 같은 ExpenseRow 다', (tester) async {
    await _pump(tester, [
      _e(rowId: 1, amount: 3000, date: '2026-09-12T11:20:00'),
      _e(rowId: 2, amount: 5000, date: '2026-09-12T18:00:00'),
    ]);
    await _search(tester, '커피');

    expect(find.byType(ExpenseRow), findsNWidgets(2));
  });

  testWidgets("금액에 단위 '원' 이 붙는다 — 예전에는 -3,000 이었다", (tester) async {
    await _pump(tester, [
      _e(rowId: 1, amount: 3000, date: '2026-09-12T11:20:00'),
    ]);
    await _search(tester, '커피');

    // 행의 금액 텍스트를 찾는다. '원' 이 없으면 여기서 깨진다.
    expect(
      find.descendant(
        of: find.byType(ExpenseRow),
        matching: findTextContaining('원'),
      ),
      findsWidgets,
    );
  });

  testWidgets('행 사이에 구분선이 없다', (tester) async {
    await _pump(tester, [
      _e(rowId: 1, amount: 3000, date: '2026-09-12T11:20:00'),
      _e(rowId: 2, amount: 5000, date: '2026-09-12T18:00:00'),
    ]);
    await _search(tester, '커피');

    expect(find.byType(PDivider), findsNothing);
  });

  testWidgets('날짜가 다르면 날짜 그룹 헤더로 묶인다', (tester) async {
    await _pump(tester, [
      _e(rowId: 1, amount: 3000, date: '2026-09-12T11:20:00'),
      _e(rowId: 2, amount: 5000, date: '2026-09-11T18:00:00'),
    ]);
    await _search(tester, '커피');

    // 날짜가 둘이면 헤더도 둘 — 부제에 날짜를 넣던 옛 방식이면 0 이다.
    expect(find.byType(PDayHeader), findsNWidgets(2));
    expect(findTextContaining('9월 12일'), findsOneWidget);
    expect(findTextContaining('9월 11일'), findsOneWidget);
  });

  testWidgets('같은 날이면 헤더 하나로 묶인다', (tester) async {
    await _pump(tester, [
      _e(rowId: 1, amount: 3000, date: '2026-09-12T11:20:00'),
      _e(rowId: 2, amount: 5000, date: '2026-09-12T18:00:00'),
    ]);
    await _search(tester, '커피');

    expect(find.byType(PDayHeader), findsOneWidget);
    // 헤더에 그날 합계(8,000원)가 선다.
    expect(findTextContaining('8,000'), findsOneWidget);
  });

  group('ds 로 옮긴 화면(I-wrap-b1 α)', () {
    final rows = [
      _e(rowId: 1, amount: 3000, date: '2026-09-12T11:20:00'),
      _e(rowId: 2, amount: 5000, date: '2026-09-11T18:00:00'),
    ];

    testWidgets(
      '상단 바는 ds Top Navigation — 제목 자리에 검색칸(상자형 medium), 보이지 않는 머리말 "검색"',
      (tester) async {
        final handle = tester.ensureSemantics();
        await _pump(tester, rows);
        expect(find.byType(AppBar), findsNothing);
        expect(find.byType(PTopNavigation), findsOneWidget);
        final field = tester.widget<PInput>(
          find.byKey(const ValueKey('search-field')),
        );
        expect(field.size, PInputSize.medium);
        expect(field.placeholder, '거래 검색');
        expect(
          tester.getSemantics(
            find.byKey(const ValueKey('top-navigation-search-heading')),
          ),
          isSemantics(label: '검색', isHeader: true),
        );
        // 고급 필터 — 이름 있는 아이콘 버튼, 걸린 것이 없으면 점 없음
        expect(find.bySemanticsLabel('고급 필터'), findsOneWidget);
        handle.dispose();
      },
    );

    testWidgets(
      '유형은 칩 줄(전체 · 지출 · 수입, outlineStrong) — Scroll Auto Hide 안, 고르면 그 유형으로 검색',
      (tester) async {
        final repo = await _pump(tester, rows);
        final chips = find.byKey(const ValueKey('search-type-chips'));
        expect(
          find.ancestor(of: chips, matching: find.byType(PScrollAutoHide)),
          findsOneWidget,
        );
        final radios = tester.widgetList<PChipRadio<String>>(
          find.byType(PChipRadio<String>),
        );
        expect(radios.map((r) => r.label), ['전체', '지출', '수입']);
        expect(
          radios.every((r) => r.variant == PChipVariant.outlineStrong),
          isTrue,
        );
        await tester.tap(findText('지출'));
        await tester.pumpAndSettle();
        expect(repo.lastType, 'EXPENSE');
        expect(repo.calls, 1);
        await tester.tap(findText('전체'));
        await tester.pumpAndSettle();
        // 전체로 돌아오고 검색어도 없으면 처음 안내 — 서버를 부르지 않는다
        expect(findText('키워드, 가맹점, 메모로 검색해보세요'), findsOneWidget);
        expect(repo.calls, 1);
      },
    );

    testWidgets('결과는 흰 면 하나 — 날짜 묶음마다 띠를 두지 않는다', (tester) async {
      await _pump(tester, rows);
      await _search(tester, '커피');
      expect(find.byType(PDayHeader), findsNWidgets(2));
      expect(find.byType(PScreenBand), findsNothing);
      expect(find.byType(PScreenBandBody), findsNothing);
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      final c = tester.element(find.byType(SearchScreen)).colors;
      expect(scaffold.backgroundColor, c.bgLayerDefault);
    });

    testWidgets('서버 실패 — 서버 글 대신 고정 글 + [다시 시도], 누르면 다시 검색해 결과로', (
      tester,
    ) async {
      final repo = await _pump(
        tester,
        rows,
        fail: [
          ApiException(
            code: 'EXPENSE_500',
            message: 'could not execute statement; SQL [n/a]',
            statusCode: 500,
          ),
        ],
      );
      await _search(tester, '커피');
      final failure = tester.widget<PResultSection>(
        find.byType(PResultSection),
      );
      expect(failure.kind, PResultKind.failure);
      expect(findText('검색하지 못했어요'), findsOneWidget);
      expect(findTextContaining('could not execute'), findsNothing);
      expect(findTextContaining('검색 실패'), findsNothing);
      expect(repo.calls, 1);

      await tester.tap(findText('다시 시도'));
      await tester.pumpAndSettle();
      expect(repo.calls, 2);
      expect(find.byType(ExpenseRow), findsNWidgets(2));
    });

    testWidgets('예외 실패도 같은 고정 글 — "Instance of" 가 화면에 나가지 않는다', (tester) async {
      await _pump(tester, rows, fail: [TypeError()]);
      await _search(tester, '커피');
      expect(findText('검색하지 못했어요'), findsOneWidget);
      expect(findTextContaining('Instance of'), findsNothing);
      expect(findTextContaining('TypeError'), findsNothing);
    });

    testWidgets('결과 없음 · 처음 안내는 해요체 Result Section', (tester) async {
      await _pump(tester, const []);
      expect(findText('키워드, 가맹점, 메모로 검색해보세요'), findsOneWidget);
      await _search(tester, '없는말');
      expect(findText('결과가 없어요'), findsOneWidget);
      expect(findTextContaining('없습니다'), findsNothing);
    });

    testWidgets('글자 200% — 칩 글이 위아래로 잘리지 않는다(줄 높이를 글이 정한다)', (tester) async {
      await _pump(tester, rows, textScale: 2);
      for (final label in ['전체', '지출', '수입']) {
        final text = findText(label);
        final chip = find.ancestor(
          of: text,
          matching: find.byType(PChipRadio<String>),
        );
        final t = tester.getRect(text);
        final box = tester.getRect(chip);
        expect(t.top, greaterThanOrEqualTo(box.top - 0.5), reason: label);
        expect(t.bottom, lessThanOrEqualTo(box.bottom + 0.5), reason: label);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '고급 필터 — 최소 > 최대면 칸 아래 오류 + [적용] 막힘, 고치면 적용해 그 조건으로 검색 · 점 + 이름',
      (tester) async {
        final handle = tester.ensureSemantics();
        final repo = await _pump(tester, rows);
        await tester.tap(find.byIcon(LucideIcons.slidersHorizontal));
        await tester.pumpAndSettle();
        final inputs = find.descendant(
          of: find.byType(PInput),
          matching: find.byType(EditableText),
        );
        // 바의 검색칸 + 최소 · 최대
        await tester.enterText(inputs.at(1), '5000');
        await tester.enterText(inputs.at(2), '1000');
        await tester.pump();
        expect(findText('최소 금액을 최대 금액보다 작게 해주세요'), findsOneWidget);
        await tester.tap(findText('적용'));
        await tester.pumpAndSettle();
        expect(repo.calls, 0, reason: '막힌 [적용] 은 검색하지 않는다');

        await tester.enterText(inputs.at(2), '9000');
        await tester.pump();
        await tester.tap(findText('적용'));
        await tester.pumpAndSettle();
        expect(repo.calls, 1);
        expect((repo.lastMin, repo.lastMax), (5000, 9000));
        expect(find.bySemanticsLabel('고급 필터, 적용 중'), findsOneWidget);
        handle.dispose();
      },
    );

    testWidgets('✕ 는 기다리지 않고 바로 비운다 — 지운 검색어의 결과가 남지 않는다', (tester) async {
      final repo = await _pump(tester, rows);
      await _search(tester, '커피');
      expect(find.byType(ExpenseRow), findsNWidgets(2));
      await tester.tap(find.bySemanticsLabel('지우기'));
      await tester.pump(); // 디바운스(350ms)를 흘리지 않는다
      expect(find.byType(ExpenseRow), findsNothing);
      expect(findText('키워드, 가맹점, 메모로 검색해보세요'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 400));
      expect(repo.calls, 1, reason: '비운 뒤 다시 부르지 않는다');
    });

    testWidgets('늦게 온 앞 요청의 답이 새 결과를 덮지 않는다', (tester) async {
      final repo = await _pump(tester, const []);
      repo.hold = true;
      final field = find.descendant(
        of: find.byKey(const ValueKey('search-field')),
        matching: find.byType(EditableText),
      );
      await tester.enterText(field, '앞');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.enterText(field, '뒤');
      await tester.pump(const Duration(milliseconds: 400));
      expect(repo.pending, hasLength(2));
      // 새 요청이 먼저 오고, 앞 요청이 늦게 온다
      repo.pending[1].complete([
        _e(
          rowId: 2,
          amount: 5000,
          date: '2026-09-11T18:00:00',
          merchant: '새 답',
        ),
      ]);
      await tester.pump();
      repo.pending[0].complete([
        _e(
          rowId: 1,
          amount: 3000,
          date: '2026-09-12T11:20:00',
          merchant: '옛 답',
        ),
      ]);
      await tester.pumpAndSettle();
      expect(findText('새 답'), findsOneWidget);
      expect(findText('옛 답'), findsNothing);
    });

    testWidgets('[다시 시도] 를 누르면 실패 화면은 그대로 두고 단추에 진행 원', (tester) async {
      final repo = await _pump(
        tester,
        rows,
        fail: [ApiException(code: 'X', message: 'x', statusCode: 500)],
      );
      await _search(tester, '커피');
      repo.hold = true;
      await tester.tap(findText('다시 시도'));
      await tester.pump();
      final section = tester.widget<PResultSection>(
        find.byType(PResultSection),
      );
      expect(section.kind, PResultKind.failure);
      expect(section.primaryAction!.loading, isTrue);
      repo.pending.single.complete(rows);
      await tester.pumpAndSettle();
      expect(find.byType(ExpenseRow), findsNWidgets(2));
    });

    testWidgets('고급 필터 — 기간을 고르면 그 기간으로 검색한다', (tester) async {
      final repo = await _pump(tester, rows);
      await _openAdvanced(tester);
      await tester.tap(find.byKey(const ValueKey('search-period')));
      await tester.pumpAndSettle();
      await tester.tap(findText('이번 달').last);
      await tester.pumpAndSettle();
      await tester.tap(findText('완료'));
      await tester.pumpAndSettle();
      await tester.tap(findText('적용'));
      await tester.pumpAndSettle();
      final now = DateTime.now();
      final ym =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
      expect(repo.lastStart, '$ym-01');
      expect(repo.lastEnd, startsWith(ym));
    });

    testWidgets('고급 필터 — [초기화] 는 시트 안 값을 비우고, 적용하면 조건 없이(처음 안내)', (
      tester,
    ) async {
      final repo = await _pump(tester, rows);
      await _openAdvanced(tester);
      await tester.enterText(_amountField(0), '1000');
      await tester.pump();
      await tester.tap(findText('적용'));
      await tester.pumpAndSettle();
      expect(repo.lastMin, 1000);
      final calls = repo.calls;

      await _openAdvanced(tester);
      expect(
        tester.widget<EditableText>(_amountField(0)).controller.text,
        '1000',
      );
      await tester.tap(findText('초기화'));
      await tester.pump();
      expect(tester.widget<EditableText>(_amountField(0)).controller.text, '');
      await tester.tap(findText('적용'));
      await tester.pumpAndSettle();
      // 조건이 다 빠졌다 — 서버를 부르지 않고 처음 안내
      expect(repo.calls, calls);
      expect(findText('키워드, 가맹점, 메모로 검색해보세요'), findsOneWidget);
    });

    testWidgets('고급 필터 — 100억을 넘으면 칸 오류 + [적용] 막힘(보이는 숫자와 걸리는 조건이 같다)', (
      tester,
    ) async {
      final repo = await _pump(tester, rows);
      await _openAdvanced(tester);
      await tester.enterText(_amountField(0), '99999999999999999999');
      await tester.pump();
      expect(findText('금액은 100억원까지 입력할 수 있어요.'), findsOneWidget);
      await tester.tap(findText('적용'));
      await tester.pumpAndSettle();
      expect(repo.calls, 0);
      await tester.enterText(_amountField(0), '10000000000');
      await tester.pump();
      expect(findText('금액은 100억원까지 입력할 수 있어요.'), findsNothing);
    });

    testWidgets(
      '이름은 칸마다 다르다 — "거래 검색" · "최소 금액" · "최대 금액", 예시 글이 이름과 같으면 다시 읽지 않는다',
      (tester) async {
        final handle = tester.ensureSemantics();
        await _pump(tester, rows);
        final node = tester.getSemantics(
          find.descendant(
            of: find.byKey(const ValueKey('search-field')),
            matching: find.byType(EditableText),
          ),
        );
        expect(node.label, contains('거래 검색'));
        expect(
          '${node.label}\n${node.hint}'.split('거래 검색').length - 1,
          1,
          reason: '이름 "거래 검색" 은 한 번만',
        );
        await _openAdvanced(tester);
        expect(find.bySemanticsLabel(RegExp('^최소 금액')), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp('^최대 금액')), findsOneWidget);
        handle.dispose();
      },
    );
  });
}
