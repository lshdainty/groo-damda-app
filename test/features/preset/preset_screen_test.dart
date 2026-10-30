// 프리셋 관리 화면(I-20 C 13 ~ 18) — 목록 제목 · 정렬 · 줄 누름 = 상세 · 줄 끝 ⋮ 없음 · 빈 화면 · 상세 바닥 · 삭제 실패.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/preset/application/preset_providers.dart';
import 'package:groo_damda_app/features/preset/data/preset_repository.dart';
import 'package:groo_damda_app/features/preset/domain/expense_template.dart';
import 'package:groo_damda_app/features/preset/presentation/preset_screen.dart';
import 'package:groo_damda_app/features/preset/presentation/preset_view.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';

const _cat = ExpenseCategory(
  rowId: 1,
  categoryName: '식비',
  expenseType: 'EXPENSE',
  sortOrder: 0,
  icon: 'utensils',
  color: '#2c70bf',
);
const _a = ExpenseTemplate(
  rowId: 1,
  templateName: '점심',
  expenseType: 'EXPENSE',
  categoryRowId: 1,
  categoryName: '식비',
  assetName: '카드',
  amount: 4500,
  lockAmount: 'Y',
  useCount: 3,
);
const _b = ExpenseTemplate(
  rowId: 2,
  templateName: '월급',
  expenseType: 'INCOME',
  categoryRowId: 1,
  categoryName: '식비',
  useCount: 9,
);
const _tr = ExpenseTemplate(
  rowId: 3,
  templateName: '이동',
  expenseType: 'TRANSFER',
  assetName: '가',
  toAssetName: '나',
  useCount: 1,
);

class _Repo extends PresetRepository {
  _Repo(this.fail) : super(Dio());
  final bool fail;
  int deletes = 0;
  @override
  Future<void> delete(int id, {bool silent = false}) async {
    deletes++;
    if (fail) throw ApiException(code: 'X', message: '서버 원문');
  }
}

Future<_Repo> _open(
  WidgetTester tester,
  List<ExpenseTemplate> items, {
  bool failDelete = false,
  bool failList = false,
}) async {
  final repo = _Repo(failDelete);
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        presetListProvider.overrideWith((ref) async {
          if (failList) throw Exception('x');
          return items;
        }),
        categoriesProvider.overrideWith((ref) async => [_cat]),
        presetRepositoryProvider.overrideWith((ref) async => repo),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        builder: (c, ch) => PSnackbarHost(closeLabel: '닫기', child: ch!),
        home: const PresetScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

Finder _t(String s) => find.byWidgetPredicate(
  (w) => w is Text && (w.data ?? '').replaceAll('⁠', '') == s,
);

void main() {
  late AppLocalizations l;
  setUpAll(
    () async => l = await AppLocalizations.delegate.load(const Locale('ko')),
  );

  test('금액 글 — 지출 − · 수입 + · 이체 부호 없음 · 금액 비움은 null', () {
    expect(presetAmountText(_a), '−4,500원');
    expect(
      presetAmountText(
        const ExpenseTemplate(
          rowId: 9,
          templateName: 'x',
          expenseType: 'INCOME',
          amount: 10,
          lockAmount: 'Y',
        ),
      ),
      '+10원',
    );
    expect(
      presetAmountText(
        const ExpenseTemplate(
          rowId: 9,
          templateName: 'x',
          expenseType: 'TRANSFER',
          amount: 10,
          lockAmount: 'Y',
        ),
      ),
      '10원',
    );
    expect(presetAmountText(_b), isNull);
  });

  testWidgets('목록 제목 "프리셋 n개" · 안내 상자 0 · 줄 끝 ⋮ 0', (tester) async {
    await _open(tester, [_a, _b, _tr]);
    expect(_t(l.presetListTitle(3)), findsOneWidget);
    expect(find.text('프리셋이란?'), findsNothing);
    expect(find.byIcon(Icons.more_vert), findsNothing);
    expect(find.bySemanticsLabel(RegExp('더보기')), findsNothing);
  });

  testWidgets('정렬 — 많이 쓴 순이 처음, 이름순으로 바꾸면 가나다', (tester) async {
    await _open(tester, [_a, _b, _tr]);
    final titles = () => [
      for (final w in tester.widgetList<PListButtonItem>(
        find.byType(PListButtonItem),
      ))
        w.title,
    ];
    expect(titles(), ['월급', '점심', '이동']);
    await tester.tap(_t(l.presetSortName));
    await tester.pumpAndSettle();
    expect(titles(), ['월급', '이동', '점심']..sort());
  });

  testWidgets('줄을 누르면 상세가 열리고 바닥에 [삭제][수정] — 앱도 열린다', (tester) async {
    await _open(tester, [_a]);
    await tester.tap(_t('점심'));
    await tester.pumpAndSettle();
    expect(_t(l.presetDetailTitle), findsOneWidget);
    expect(find.text(l.actionDelete), findsWidgets);
    expect(find.text(l.actionEdit), findsWidgets);
  });

  testWidgets('빈 화면 — 안내 글 · 본문 버튼 하나 · 머리 "추가" 없음', (tester) async {
    await _open(tester, []);
    expect(_t(l.presetEmptyTitle), findsOneWidget);
    expect(_t(l.presetEmptyDesc), findsOneWidget);
    expect(find.text(l.presetAddAction), findsNothing);
    expect(find.text(l.presetAdd), findsOneWidget);
  });

  testWidgets('목록 조회 실패 — Result Section + 다시 시도, 서버 원문 0', (tester) async {
    await _open(tester, [], failList: true);
    expect(_t(l.presetLoadFailed), findsOneWidget);
    expect(find.text(l.actionRetry), findsOneWidget);
    expect(find.textContaining('x'), findsNothing);
  });

  testWidgets('삭제 실패 — 확인창을 닫고 시트 안 Callout + 다시 시도', (tester) async {
    final repo = await _open(tester, [_a], failDelete: true);
    await tester.tap(_t('점심'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.actionDelete).last);
    await tester.pumpAndSettle();
    expect(_t(l.presetDeleteConfirmTitle('점심')), findsOneWidget);
    await tester.tap(find.text(l.actionDelete).last);
    await tester.pumpAndSettle();
    expect(repo.deletes, 1);
    expect(_t(l.presetDeleteFailed), findsOneWidget);
    expect(find.text(l.actionRetry), findsOneWidget);
    expect(_t(l.presetDetailTitle), findsOneWidget, reason: '시트는 열려 있다');
  });
}
