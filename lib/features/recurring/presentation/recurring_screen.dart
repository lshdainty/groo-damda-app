import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/recurring/application/recurring_providers.dart';
import 'package:groo_damda_app/features/recurring/domain/recurring_schedule.dart';
import 'package:groo_damda_app/features/recurring/domain/recurring_transaction.dart';
import 'package:groo_damda_app/features/recurring/presentation/recurring_actions.dart';
import 'package:groo_damda_app/features/recurring/presentation/recurring_detail_sheet.dart';
import 'package:groo_damda_app/features/recurring/presentation/recurring_form.dart';
import 'package:groo_damda_app/features/recurring/presentation/recurring_format.dart';
import 'package:groo_damda_app/features/recurring/presentation/recurring_view.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/async/load_failure.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/ds/pull_to_refresh/p_pull_to_refresh.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/screen_band/p_screen_band.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/swipe_actions/p_swipe_actions.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';
import 'package:groo_damda_app/shared/ds/skeleton/loading_region.dart';

const _tabular = [FontFeature.tabularFigures()];

/// 반복 거래 관리(설정 > 반복 거래 관리) — 웹 `RecurringManager.tsx` 미러(I-20 D 21 ~ 25).
///
/// 폰은 흰 면 하나다: 머리(← + "추가") → 종류별 묶음(지출 → 수입 → 이체, 빈 묶음은 없다) → 줄. 요약 카드 · 다가오는 7일 · 거르기 칩은
/// 없다. 묶음 머리에 "이번 달" 합계(지출 · 수입)가 있다. 줄 누름 = 상세, 밀면 [수정][삭제] 지름길이다 — 줄 끝 ⋮ 는 없다.
class RecurringScreen extends ConsumerStatefulWidget {
  const RecurringScreen({super.key});

  @override
  ConsumerState<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends ConsumerState<RecurringScreen> {
  void _add() => showRecurringFormSheet(context);

  Future<void> _openDetail(RecurringTransaction it) async {
    final act = await showRecurringDetailSheet(context, rowId: it.rowId);
    if (act == RecurringDetailAction.edit && mounted) {
      final fresh = ref
          .read(recurringListProvider)
          .value
          ?.where((e) => e.rowId == it.rowId)
          .firstOrNull;
      await showRecurringFormSheet(context, recurring: fresh ?? it);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final listAsync = ref.watch(recurringListProvider);
    final catsAsync = ref.watch(categoriesProvider);
    final loading = !listAsync.hasValue && !listAsync.hasError;
    final failed = !loading && !listAsync.hasValue;
    final items = listAsync.value ?? const <RecurringTransaction>[];

    return Scaffold(
      backgroundColor: c.bgLayerBasement,
      // 머리 = ds 상단 바(← + 제목 + 글 버튼 "추가") — 비어 있거나 불러오는 중 · 실패에서는 "추가" 를 두지 않는다
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(PTopNavigation.heightOf(context)),
        child: PTopNavigation(
          title: l.navRecurring,
          leading: PTopNavigationIconButton.back(
            label: l.actionBack,
            onPressed: () => context.pop(),
          ),
          actions: [
            if (!loading && !failed && items.isNotEmpty)
              PTopNavigationTextButton(
                label: l.recurringAddAction,
                onPressed: _add,
              ),
          ],
        ),
      ),
      body: PScreenBandBody(
        child: PSwipeActionsProvider(
          child: PPullToRefresh(
            onRefresh: () async {
              ref.invalidate(recurringListProvider);
              try {
                await ref.read(recurringListProvider.future);
              } catch (_) {}
            },
            child: loading
                ? loadingRegion(const _RecurringSkeleton())
                : failed
                ? _failure(l)
                : items.isEmpty
                ? _empty(l)
                : _list(l, items, catsAsync.value ?? const <ExpenseCategory>[]),
          ),
        ),
      ),
    );
  }

  Widget _failure(AppLocalizations l) => ListView(
    padding: const EdgeInsets.symmetric(vertical: PSpacing.x6),
    children: [
      PResultSection(
        kind: PResultKind.failure,
        size: PResultSize.large,
        title: l.recLoadFailed,
        description: l.dashFailDesc,
        primaryAction: PResultAction(
          label: l.actionRetry,
          loading: ref.watch(recurringListProvider).loadRetrying,
          onPressed: () => ref.invalidate(recurringListProvider),
        ),
      ),
    ],
  );

  /// 빈 화면 — 머리 버튼이 없어서 본문 버튼이 하나다.
  Widget _empty(AppLocalizations l) => ListView(
    padding: const EdgeInsets.symmetric(vertical: PSpacing.x6),
    children: [
      PResultSection(
        kind: PResultKind.empty,
        size: PResultSize.large,
        icon: LucideIcons.repeat,
        title: l.recEmptyTitle,
        description: l.recEmptyDesc,
        primaryAction: PResultAction(label: l.recAddButton, onPressed: _add),
      ),
    ],
  );

  Widget _list(
    AppLocalizations l,
    List<RecurringTransaction> items,
    List<ExpenseCategory> categories,
  ) {
    final masked = ref.watch(hideCardProvider('etc.recurring'));
    final now = recurringNow();
    final groups = <({String type, String kind})>[
      (type: 'EXPENSE', kind: l.expTypeExpense),
      (type: 'INCOME', kind: l.expTypeIncome),
      (type: 'TRANSFER', kind: l.expTypeTransfer),
    ];
    final children = <Widget>[];
    for (final g in groups) {
      final rows = [
        for (final it in items)
          if (it.expenseType == g.type) it,
      ];
      if (rows.isEmpty) continue;
      final total = g.type == 'TRANSFER'
          ? null
          : monthTotal(items, g.type, now.year, now.month);
      final title = l.recGroupTitle(g.kind, rows.length);
      children.add(
        PListHeader(
          title: title,
          variant: PListHeaderVariant.boldSolid,
          topInset: children.isEmpty ? PSpacing.x4 : PSpacing.x6,
          trailing: total == null
              ? null
              : _MonthTotal(type: g.type, total: total, masked: masked),
        ),
      );
      children.add(
        PList(
          semanticLabel: title,
          children: [
            for (final it in rows)
              // 밀면 수정 · 삭제 — 줄을 누르면 상세이므로 밀기는 손가락 지름길이다(WCAG 2.1.1)
              PSwipeActions(
                key: ValueKey('recurring-${it.rowId}'),
                rowLabel: recDisplayTitle(l, it),
                actions: [
                  PSwipeAction(
                    label: l.actionEdit,
                    icon: LucideIcons.pencil,
                    kind: PSwipeActionKind.primary,
                    onSelect: () =>
                        showRecurringFormSheet(context, recurring: it),
                  ),
                  PSwipeAction(
                    label: l.actionDelete,
                    icon: LucideIcons.trash2,
                    kind: PSwipeActionKind.destructive,
                    // 확인은 deleteRecurringWithNotice 가 한 번만 묻는다
                    onSelect: () => deleteRecurringWithNotice(context, ref, it),
                  ),
                ],
                child: RecurringListRow(
                  item: it,
                  category: categories.byRowId(it.categoryRowId),
                  masked: masked,
                  onTap: () => _openDetail(it),
                ),
              ),
          ],
        ),
      );
    }
    return ListView(
      // 끝 숨 24 는 흰 면 안(T8)
      padding: EdgeInsets.only(
        bottom: PSpacing.x6 + MediaQuery.paddingOf(context).bottom,
      ),
      children: children,
    );
  }
}

/// 묶음 머리 오른쪽 "이번 달 −125,020,909원"(t4 · 700 · 고정폭) — 가림이 켜지면 금액만 점.
class _MonthTotal extends StatelessWidget {
  const _MonthTotal({
    required this.type,
    required this.total,
    required this.masked,
  });
  final String type;
  final int total;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final sign = total == 0 ? '' : (type == 'EXPENSE' ? kMinus : '+');
    final value = krwSigned(total, masked, sign: sign, unit: true);
    final text = '${l.recMonthLead} $value';
    return Text(
      keepAllAmount(text),
      semanticsLabel: text,
      textAlign: TextAlign.end,
      style: PTypography.t4.copyWith(
        color: c.fgNeutral,
        fontWeight: FontWeight.w700,
        fontFeatures: _tabular,
      ),
    );
  }
}

/// 불러오는 중 — 묶음 머리 둘 + 줄 넷(타일 40 · 두 줄 · 오른쪽 한 줄).
class _RecurringSkeleton extends StatelessWidget {
  const _RecurringSkeleton();

  Widget _head() => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: PSpacing.globalGutter,
      vertical: PSpacing.x2,
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        PSkeleton.text(PTypography.t4, width: PSpacing.x10 * 2),
        PSkeleton.text(PTypography.t4, width: PSpacing.x10 * 3),
      ],
    ),
  );

  Widget _row() => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: PSpacing.globalGutter,
      vertical: PSpacing.x3,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: PSpacing.x3,
      children: [
        const PSkeleton(
          width: PListTile.size,
          height: PListTile.size,
          radius: PSkeletonRadius.r12,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: PSpacing.x1,
            children: [
              PSkeleton.text(PTypography.t5, width: 140),
              PSkeleton.text(PTypography.t3, width: 180),
            ],
          ),
        ),
        PSkeleton.text(PTypography.t5, width: PSpacing.x10 * 2),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _head(),
        for (var i = 0; i < 3; i++) _row(),
        const SizedBox(height: PSpacing.x4),
        _head(),
        _row(),
      ],
    );
  }
}
