import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/settings/mask_flags.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset_transfer.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/expense/presentation/expense_actions.dart';
import 'package:groo_damda_app/features/expense/presentation/transfer_detail_sheet.dart';
import 'package:groo_damda_app/features/expense/presentation/widgets/expense_row.dart';
import 'package:groo_damda_app/features/expense/presentation/widgets/transfer_row.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/swipe_actions/p_swipe_actions.dart';
import 'package:groo_damda_app/shared/widgets/p_day_group.dart';

/// 날짜 묶음 하나 — 머리 + 거래 줄 + 이체 줄. 묶음 위 12 · 첫 묶음 4.
///
/// 거래 줄은 밀기(ds Swipe Actions)로 [수정, 삭제] 를 하고, 줄을 누르면 상세 시트가 열린다. 시스템이 만든 거래는 동작이 없어 밀기가 없다.
/// 이체 줄은 감싸지 않는다. 알림 · 검색에서 들어온 줄은 `bg-brand-weak` 로 강조한다.
class LedgerDayGroup extends ConsumerWidget {
  const LedgerDayGroup({
    super.key,
    required this.date,
    required this.items,
    required this.categoriesAsync,
    required this.flags,
    required this.first,
    this.transfers = const [],
    this.rowKeys,
    this.focusTxId,
  });

  final DateTime date;
  final List<Expense> items;
  final List<AssetTransfer> transfers;
  final AsyncValue<dynamic> categoriesAsync;
  final MaskFlags flags;
  final bool first;
  final Map<int, GlobalKey>? rowKeys;
  final int? focusTxId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).value ?? const [];
    // 삭제 확인창이 결제가 끝난 회차인지 가르는 데 쓴다 — 카드의 cardClosedThrough.
    final assets = ref.watch(assetsProvider).value;

    return Padding(
      padding: EdgeInsets.only(top: first ? PSpacing.x1 : PSpacing.x3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PDayHeader(date: date, items: items, flags: flags),
          for (final e in items)
            Builder(
              builder: (_) {
                final isFocus = focusTxId == e.rowId;
                final k = isFocus
                    ? (rowKeys?.putIfAbsent(e.rowId, () => GlobalKey()))
                    : null;
                final actions = expenseActions.dsSwipeActions(
                  context,
                  ref,
                  e,
                  asset: e.assetRowId == null
                      ? null
                      : assets?.byRowId(e.assetRowId!),
                );
                final name = expenseActions.displayNameOf(context, e);
                // 거래 줄은 ds List 줄(제 좌우 24)이다 — 바깥 24 는 없다(I-07 4).
                final row = ExpenseRow(
                  expense: e,
                  category: e.categoryRowId == null
                      ? null
                      : categories.byRowId(e.categoryRowId!),
                  flags: flags,
                  highlighted: isFocus,
                );
                final line = PSwipeActions(
                  actions: actions,
                  rowLabel: name,
                  child: row,
                );
                return KeyedSubtree(key: k, child: line);
              },
            ),
          // 이체는 시각이 없어(LocalDate) 그날의 맨 뒤 — web 정렬(내림차순)과 동일한 자리.
          for (final tr in transfers)
            TransferRow(
              key: ValueKey('t${tr.rowId}'),
              transfer: tr,
              flags: flags,
              // 금액 · 수수료는 보내는 계좌 통화, 받는 금액은 받는 계좌 통화(I-13) — 통화는 이미 받은 자산 목록에서 읽는다
              currencyOf: (id) => assets?.byRowId(id)?.currency,
              onTap: () => showTransferDetailSheet(context, tr),
            ),
        ],
      ),
    );
  }
}

/// 불러오는 동안의 날짜 묶음 — 머리 한 줄 + 거래 줄 [rows] 개(List 두 줄 줄 66 = 위아래 12 + 타일 40 · 글 42).
class LedgerDaySkeleton extends StatelessWidget {
  const LedgerDaySkeleton({super.key, required this.rows, this.first = false});

  final int rows;
  final bool first;

  /// 줄 하나의 높이 — 위아래 12 + 제목 t5(22) + 설명 t3(18) + 사이 2.
  static const double rowHeight = 66;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: first ? PSpacing.x1 : PSpacing.x3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PSpacing.globalGutter,
              vertical: PSpacing.x2,
            ),
            child: Row(
              children: [
                PSkeleton.text(PTypography.t4, width: 96),
                const Spacer(),
                PSkeleton.text(PTypography.t4, width: 72),
              ],
            ),
          ),
          for (var i = 0; i < rows; i++)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                PSpacing.globalGutter,
                PSpacing.x3,
                PSpacing.globalGutter,
                PSpacing.x3,
              ),
              child: Row(
                children: [
                  const PSkeleton(
                    width: PSpacing.x10,
                    height: PSpacing.x10,
                    radius: PSkeletonRadius.r12,
                  ),
                  const SizedBox(width: PSpacing.x3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: PSpacing.x0_5,
                      children: [
                        PSkeleton.text(PTypography.t5, width: 120),
                        PSkeleton.text(PTypography.t3, width: 80),
                      ],
                    ),
                  ),
                  const SizedBox(width: PSpacing.x2),
                  PSkeleton.text(PTypography.t5, width: 80),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
