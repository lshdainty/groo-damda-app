import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/features/category/presentation/category_tile.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/async/load_failure.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/text/p_text.dart';
import 'package:groo_damda_app/shared/forms/pick_list.dart';

/// 카테고리 고르기 시트(I-20 C 19 — 폼 시트 위 고르기) — 고른 카테고리의 rowId 가 돌아온다. 다시 받는 중에는 Skeleton, 못 받으면
/// 시트 안 실패 Result Section + 다시 시도(앱 빨간 원문을 두지 않는다). 폼 줄 값은 그대로다.
Future<int?> showCategoryPickSheet(
  BuildContext context, {
  required String kind,
  required int? selectedRowId,
}) {
  return PBottomSheet.show<int>(
    context,
    builder: (sheetContext) {
      final l = AppLocalizations.of(sheetContext);
      return PBottomSheetContent(
        title: l.expCategory,
        closeLabel: l.actionClose,
        flushBody: true,
        scrollFog: true,
        body: CategoryPickBody(kind: kind, selectedRowId: selectedRowId),
      );
    },
  );
}

/// 카테고리 고르기 본문 — 지금 종류의 카테고리를 지금 차례로. 하위가 없는 최상위는 고르는 줄(타일 40 + 이름), 하위가 있는 최상위는
/// 그 이름의 목록 제목(고를 수 없다 — 서버 `EXPENSE_CATEGORY_NOT_LEAF`) 아래 하위 줄들이다. 누르면 바로 넣고 닫힌다.
class CategoryPickBody extends ConsumerWidget {
  const CategoryPickBody({
    super.key,
    required this.kind,
    required this.selectedRowId,
  });

  final String kind;
  final int? selectedRowId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final async = ref.watch(categoriesProvider);
    if (!async.hasValue) {
      // 실패면 실패 화면 — 다시 받는 동안은 실패를 그대로 두고 단추에 진행 원(skeleton.md:139). 처음 받는 중만 Skeleton
      if (async.loadFailed) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: PSpacing.globalGutter,
          ),
          child: PResultSection(
            kind: PResultKind.failure,
            size: PResultSize.medium,
            title: l.presetCategoryLoadFailed,
            description: l.dashFailDesc,
            primaryAction: PResultAction(
              label: l.actionRetry,
              loading: async.loadRetrying,
              onPressed: () => ref.invalidate(categoriesProvider),
            ),
          ),
        );
      }
      return Column(
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: PSpacing.globalGutter,
                vertical: PSpacing.x3,
              ),
              child: Row(
                spacing: PSpacing.x3,
                children: [
                  const PSkeleton(
                    width: PListTile.size,
                    height: PListTile.size,
                    radius: PSkeletonRadius.r12,
                  ),
                  PSkeleton.text(PTypography.t5, width: 140),
                ],
              ),
            ),
        ],
      );
    }

    final inKind = [
      for (final cat in async.requireValue)
        if (cat.expenseType == kind) cat,
    ]..sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));
    final tops = [
      for (final cat in inKind)
        if (cat.parentRowId == null) cat,
    ];
    if (tops.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: PSpacing.globalGutter,
          vertical: PSpacing.x3,
        ),
        child: PText(
          l.presetNoCategoryOfKind,
          textAlign: TextAlign.center,
          style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
        ),
      );
    }

    List<ExpenseCategory> childrenOf(int id) => [
      for (final cat in inKind)
        if (cat.parentRowId == id) cat,
    ];
    PickItem<int> item(ExpenseCategory cat) => PickItem<int>(
      value: cat.rowId,
      title: cat.categoryName,
      prefix: categoryTile(context, cat),
    );

    // 하위 없는 최상위가 이어지면 한 목록으로 묶는다
    final blocks = <Widget>[];
    var run = <ExpenseCategory>[];
    void flush() {
      if (run.isEmpty) return;
      blocks.add(
        PickList<int>(
          label: l.expCategory,
          selected: selectedRowId,
          items: [for (final cat in run) item(cat)],
        ),
      );
      run = [];
    }

    for (final top in tops) {
      final kids = childrenOf(top.rowId);
      if (kids.isEmpty) {
        run.add(top);
        continue;
      }
      flush();
      blocks.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PListHeader(title: top.categoryName, headingLevel: 3),
            PickList<int>(
              label: top.categoryName,
              selected: selectedRowId,
              items: [for (final cat in kids) item(cat)],
            ),
          ],
        ),
      );
    }
    flush();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: blocks,
    );
  }
}
