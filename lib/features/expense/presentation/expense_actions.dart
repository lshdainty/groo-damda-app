import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/sync/keep_alive_refresh.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/expense/presentation/add_tx_sheet.dart';
import 'package:groo_damda_app/features/expense/presentation/closed_cycle_notice.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/actions/item_actions.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import 'package:groo_damda_app/shared/ui/confirm_fail_snackbar.dart';
import 'package:groo_damda_app/shared/ds/swipe_actions/p_swipe_actions.dart'
    as ds;

/// 거래 하나에 할 수 있는 일 — 목록 행(스와이프)과 상세 시트가 같은 것을 부른다.
///
/// 삭제는 지우고 끝나는 일이 아니다. 그 달의 목록과 자산 잔액이 같이 바뀌어야 해서
/// 무효화까지가 한 묶음이다. 한쪽에만 있으면 다른 경로로 지웠을 때 화면이 안 바뀐다.
const expenseActions = ExpenseActions();

class ExpenseActions implements ItemActions<Expense> {
  const ExpenseActions();

  /// 시스템이 만든 거래(매도 실현손익·이체 이자)는 원본을 지워야 사라진다.
  @override
  bool canDelete(Expense e) => e.autoSource == null;

  /// 환불된 거래도 못 고친다 — 돈이 이미 자산으로 돌아가 되돌릴 기준이 없다
  /// (서버도 EXP_043 으로 막는다). 먼저 환불을 취소해야 한다.
  @override
  bool canEdit(Expense e) => e.autoSource == null && !e.isRefunded;

  /// 환불할 수 있는 거래인가 — [환불] 을 띄우는 자리는 이 판정 하나를 본다.
  ///
  /// 지출만, 아직 환불 안 한 것만, 사람이 쓴 것만이다(카드 이월 같은 시스템 거래는
  /// 서버가 환불을 거절한다, 23차 10). 그리고 **거래일이 오늘보다 뒤인 예정 거래는
  /// 뺀다** — 환불일은 거래일부터 오늘까지만 받으므로(D16) 어떤 날짜를 골라도 서버가
  /// 거절한다. 날짜만 견준다(기기 날짜) — 오늘 날짜인데 시각만 뒤인 거래는 오늘을
  /// 환불일로 받으니 둔다. 거래일이 지나면 버튼이 나타난다. 서버의 거절은 그대로다.
  ///
  /// 지금 [환불] 은 상세에만 있다 — 행 스와이프는 수정·삭제뿐이다(웹도 같다).
  bool canRefund(Expense e, {DateTime? now}) {
    if (e.expenseType == 'INCOME' || e.isRefunded || e.autoSource != null) {
      return false;
    }
    final raw = e.expenseDate;
    if (raw == null || raw.length < 10) return true;
    final n = now ?? DateTime.now();
    final today =
        '${n.year.toString().padLeft(4, '0')}-'
        '${n.month.toString().padLeft(2, '0')}-'
        '${n.day.toString().padLeft(2, '0')}';
    return raw.substring(0, 10).compareTo(today) <= 0;
  }

  @override
  String deleteConfirmTitle(BuildContext context, Expense e) =>
      AppLocalizations.of(context).expDelete;

  /// 확인창이 부를 이름. 상세 화면 제목과 같은 규칙이다 — 상호명이 없으면 적요,
  /// 그것도 없으면 카테고리. 거래는 이름을 안 가질 수 있어 마지막에 기본값을 둔다.
  String displayNameOf(BuildContext context, Expense e) =>
      e.merchant ??
      e.description ??
      e.categoryName ??
      AppLocalizations.of(context).expTxFallback;

  /// 환불이 거래를 만들지 않으므로 "함께 사라지는 환불" 경고는 없다 — 환불은
  /// 원거래에 찍힌 표식이고, 원거래를 지우면 표식도 같이 없어진다.
  @override
  String deleteConfirmMessage(BuildContext context, Expense e) =>
      AppLocalizations.of(context).expDeleteConfirm(displayNameOf(context, e));

  /// 삭제 확인창 본문 — 결제가 끝난 회차의 카드 거래면 한 문구를 덧붙인다(D1).
  ///
  /// 상세와 스와이프가 **같은 것**을 부른다. 서버에 묻지 않으므로 스와이프처럼 문구가
  /// 액션을 만들 때 굳는 자리에서도 상세와 같은 말을 한다.
  String deleteConfirmMessageWith(
    BuildContext context,
    Expense e,
    Asset? asset,
  ) => withClosedCycleNote(
    AppLocalizations.of(context),
    deleteConfirmMessage(context, e),
    closedCycleSpanOfExpense(e, asset),
  );

  /// 목록 줄의 밀기 · 줄 끝 ⋮ 가 함께 쓰는 동작 — ds Swipe Actions 의 배열이다(수정 → 삭제 차례, I-07 6).
  ///
  /// 시스템이 만든 거래(`autoSource != null`)는 비어 있다(밀기 · ⋮ 모두 없음). 삭제는 ds 가 확인창을 갖지 않으므로
  /// 여기서 Alert Dialog 를 먼저 띄운다 — 제목 · 본문은 상세 시트에서 지울 때와 같다(결제가 끝난 회차 한 줄 포함).
  List<ds.PSwipeAction> dsSwipeActions(
    BuildContext context,
    WidgetRef ref,
    Expense e, {
    required Asset? asset,
  }) {
    final l = AppLocalizations.of(context);
    return [
      if (canEdit(e))
        ds.PSwipeAction(
          label: l.actionEdit,
          icon: LucideIcons.pencil,
          kind: ds.PSwipeActionKind.primary,
          onSelect: () => edit(context, ref, e),
        ),
      if (canDelete(e))
        ds.PSwipeAction(
          label: l.actionDelete,
          icon: LucideIcons.trash2,
          kind: ds.PSwipeActionKind.destructive,
          onSelect: () async {
            // 확인창 → 요청 → 실패면 확인창을 닫고 critical 스낵바 + [다시 시도]. 요청은 컨테이너로 나가 행이 사라져도 이어진다.
            final container = ProviderScope.containerOf(context);
            final host = hostContextOf(context);
            await askConfirmThenRequest(
              context,
              title: deleteConfirmTitle(context, e),
              description: deleteConfirmMessageWith(context, e, asset),
              cancelLabel: l.actionCancel,
              actionLabel: l.actionDelete,
              request: () =>
                  deleteExpenseRequest(container, host, e, asset: asset),
              failedMessage: l.expTxDeleteFailed,
              retryLabel: l.actionRetry,
            );
          },
        ),
    ];
  }

  /// 지운다.
  ///
  /// 열린 회차에서 미리 낸 돈이 남아 결제계좌로 돌아갔으면 그 금액을 스낵바로 알린다
  /// (D4). 결제가 끝난 회차의 거래였으면 [잔액 고치기] 를 단다(D9) — 둘 다 [deleteExpenseRequest] 가 한다.
  ///
  /// 요청은 **silent** 라 서버 글이 전역 토스트로 뜨지 않는다. 실패하면 고정 글의 critical 스낵바 + [다시 시도] 를 띄우고 false 를
  /// 돌려준다([throwOnError] 면 대신 던진다 — 부른 쪽이 말한다). 확인창은 부르는 쪽이 이미 받았다 — 스와이프는 확인창과 함께
  /// [askConfirmThenRequest] 로 [deleteExpenseRequest] 를 직접 부른다.
  ///
  /// [asset] 은 부르는 쪽이 이미 들고 있는 그 거래의 자산이다. 안 주면 자산 목록 캐시에서 찾는다.
  Future<bool> delete(
    BuildContext context,
    WidgetRef ref,
    Expense e, {
    Asset? asset,
    bool throwOnError = false,
  }) async {
    // 행은 지워지며 사라지고 상세 시트는 닫힌다 — 스낵바는 그보다 오래 사는 자리에.
    final host = hostContextOf(context);
    final container = ProviderScope.containerOf(context);
    final target = asset ?? assetOfExpense(ref, e);
    final l = AppLocalizations.of(context);
    final snack = PSnackbar.maybeOf(host);
    Future<void> request() =>
        deleteExpenseRequest(container, host, e, asset: target);
    try {
      await request();
      return true;
    } on ApiException {
      if (throwOnError) rethrow;
      showConfirmFailSnackbar(
        snack,
        message: l.expTxDeleteFailed,
        retryLabel: l.actionRetry,
        retry: request,
      );
      return false;
    }
  }

  @override
  Future<void> edit(BuildContext context, WidgetRef ref, Expense e) async {
    // showAddTxSheet 은 void — 시트가 닫히기를 기다리지 않는다. 스와이프에서 부를 때도
    // 기다릴 이유가 없다(닫힌 뒤 할 일이 없다).
    showAddTxSheet(context, edit: e);
  }

  /// 환불 표식을 찍는다 — 거래는 남고 합계에서만 빠진다(삭제와 같은 규칙).
  ///
  /// 확인창은 부르는 쪽이 띄운다. 상세만 부르는 자리라서 여기 두면 목록 스와이프가
  /// 쓰지 않는 문구를 안고 있게 된다.
  ///
  /// 성공하면 서버가 돌려준 거래를 준다 — 상세가 그걸로 다시 그려 배너가 뜬다.
  /// 미리 낸 돈이 계좌로 돌아갔으면 토스트로 알리고(D4), 결제가 끝난 회차였으면
  /// [잔액 고치기] 를 단다(D9). 실패는 null 이다(토스트는 인터셉터가 이미 띄웠다).
  ///
  /// [silent] · [throwOnError] 는 [delete] 와 같다. 응답은 목록을 다시 받은 뒤에 돌려준다 — 상세가 응답으로 단계를 옮길
  /// 때 옛 값이 먼저 비치지 않는다.
  Future<Expense?> refund(
    BuildContext context,
    WidgetRef ref,
    Expense e, {
    String? refundedAt,
    Asset? asset,
    bool silent = false,
    bool throwOnError = false,
  }) async {
    final host = hostContextOf(context);
    final fixBalance = fixBalanceTargetOf(e, asset ?? assetOfExpense(ref, e));
    try {
      final repo = await ref.read(expenseRepositoryProvider.future);
      final updated = await repo.refund(
        e.rowId,
        refundedAt: refundedAt,
        silent: silent,
      );
      _invalidateAfterRefund(ref);
      await _refetchMonthOf(ref, e);
      if (host.mounted) {
        showChangeResultToast(
          host,
          refundedAmount: updated.refundedAmount,
          fixBalanceAssetId: fixBalance,
        );
      }
      return updated;
    } on ApiException {
      if (throwOnError) rethrow;
      return null;
    }
  }

  /// 환불 표식을 걷는다 — 옛 환급 이체가 묶인 거래면 서버가 그 이체까지 되돌린다.
  Future<Expense?> cancelRefund(
    WidgetRef ref,
    Expense e, {
    bool silent = false,
    bool throwOnError = false,
  }) async {
    try {
      final repo = await ref.read(expenseRepositoryProvider.future);
      final updated = await repo.cancelRefund(e.rowId, silent: silent);
      _invalidateAfterRefund(ref);
      await _refetchMonthOf(ref, e);
      return updated;
    } on ApiException {
      if (throwOnError) rethrow;
      return null;
    }
  }

  /// 바뀐 거래가 속한 달 목록을 다시 받는다 — 무효화만 하고 돌아가면 상세가 새 값을 그리는 순간 목록은 옛 값이다.
  /// 받지 못해도 단계는 옮긴다(실패 알림은 그 조회가 말한다).
  Future<void> _refetchMonthOf(WidgetRef ref, Expense e) async {
    final date = e.expenseDate;
    if (date == null || date.length < 7) return;
    final y = int.tryParse(date.substring(0, 4));
    final m = int.tryParse(date.substring(5, 7));
    if (y == null || m == null) return;
    try {
      await ref.read(monthExpensesProvider((year: y, month: m)).future);
    } catch (_) {
      // 받지 못해도 단계는 옮긴다
    }
  }

  /// 환불은 달 하나로 끝나지 않는다 — 옛 환급 이체를 되돌리면 **오늘** 날짜가
  /// 바뀌므로 원거래 달과 이번 달이 함께 바뀐다. 그래서 달을 가리지 않고 전부 무효화한다.
  void _invalidateAfterRefund(WidgetRef ref) {
    ref.invalidate(monthExpensesProvider);
    invalidateAfterExpenseChange(ref);
  }
}

/// 거래가 단 자산 — 확인창 문구와 결과 토스트가 카드인지·닫힌 회차인지 본다.
Asset? assetOfExpense(WidgetRef ref, Expense e) {
  final id = e.assetRowId;
  if (id == null) return null;
  return ref.read(assetsProvider).value?.byRowId(id);
}

/// 거래 삭제 요청 — **컨테이너로** 한다(화면 State 와 무관하게 나간다 — 시트를 닫은 뒤 스낵바의 [다시 시도] 도 이걸 부른다).
/// 실패(`ApiException`)는 던진다 — 알리는 일은 부른 쪽 몫. 지운 뒤 바뀐 달 목록을 다시 받고, 결과 토스트는 오래 사는 [host] 에 띄운다.
Future<void> deleteExpenseRequest(
  ProviderContainer container,
  BuildContext host,
  Expense e, {
  Asset? asset,
}) async {
  final target =
      asset ??
      (e.assetRowId == null
          ? null
          : container.read(assetsProvider).value?.byRowId(e.assetRowId!));
  final fixBalance = fixBalanceTargetOf(e, target);
  final repo = await container.read(expenseRepositoryProvider.future);
  final refunded = await repo.delete(e.rowId, silent: true);
  final date = e.expenseDate;
  if (date != null && date.length >= 10) {
    final y = int.tryParse(date.substring(0, 4));
    final m = int.tryParse(date.substring(5, 7));
    if (y != null && m != null) {
      container.invalidate(monthExpensesProvider((year: y, month: m)));
    }
  }
  invalidateAfterExpenseChangeIn(container);
  await _refetchMonthIn(container, e);
  if (host.mounted) {
    showChangeResultToast(
      host,
      refundedAmount: refunded,
      fixBalanceAssetId: fixBalance,
    );
  }
}

/// 환불 취소 요청 — 컨테이너판([deleteExpenseRequest] 와 같은 이유). 서버가 돌려준 거래를 돌려준다. 실패는 던진다.
Future<Expense> cancelRefundRequest(
  ProviderContainer container,
  Expense e,
) async {
  final repo = await container.read(expenseRepositoryProvider.future);
  final updated = await repo.cancelRefund(e.rowId, silent: true);
  container.invalidate(monthExpensesProvider);
  invalidateAfterExpenseChangeIn(container);
  await _refetchMonthIn(container, e);
  return updated;
}

Future<void> _refetchMonthIn(ProviderContainer container, Expense e) async {
  final date = e.expenseDate;
  if (date == null || date.length < 7) return;
  final y = int.tryParse(date.substring(0, 4));
  final m = int.tryParse(date.substring(5, 7));
  if (y == null || m == null) return;
  try {
    await container.read(monthExpensesProvider((year: y, month: m)).future);
  } catch (_) {
    // 받지 못해도 돌아간다
  }
}
