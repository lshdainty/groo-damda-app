import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/settings/hide_amounts_cards.dart';
import 'package:groo_damda_app/core/settings/mask_flags.dart';
import 'package:groo_damda_app/core/sync/keep_alive_refresh.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/domain/asset_transfer.dart';
import 'package:groo_damda_app/features/asset/presentation/widgets/asset_logo.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/presentation/add_tx_sheet.dart';
import 'package:groo_damda_app/features/expense/presentation/closed_cycle_notice.dart';
import 'package:groo_damda_app/features/expense/presentation/tx_detail_body.dart';
import 'package:groo_damda_app/features/expense/presentation/tx_detail_rules.dart';
import 'package:groo_damda_app/features/recurring/presentation/recurring_settings_drawer.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/logo_tile/p_logo_tile.dart';
import 'package:groo_damda_app/shared/forms/form_delete_footer.dart';

/// 이체 상세(I-21 21-1 · C) — 거래 상세와 한 벌이다. 머리 "이체 상세" · 닫기 → 회색 타일 48 + "이체" → 금액 → 날짜 → 보내는 · 받는
/// 계좌 줄(Logo Tile 40) → 값 줄(수수료 · 출금 합계 · 이자 · 원금 · 메모) → "더 하기" 반복 설정 → 바닥 [삭제][수정].
///
/// 수정 · 삭제는 서버가 이자 지출 · 잔액 이력을 되돌렸다 다시 만든다(rowId 는 유지). 시스템이 만든 이체(매수 예수금 충당 · 카드
/// 자동결제)는 금액이 원본과 묶여 있어 고칠 수 없다 — 바닥을 두지 않고 왜 그런지 Callout 으로 적는다.
///
/// [수정] 은 21-2 가 폼을 단계로 옮기기 전까지 지금 방식이다 — 상세를 내리고 옛 수정 시트를 열고, 저장하면 저장한 값으로 상세를 다시 연다.
/// "반복 설정" 은 21-3 이 단계로 옮긴다 — 그때까지 지금처럼 시트를 닫고 옛 반복 폼(이체 씨앗)을 연다.
Future<void> showTransferDetailSheet(
  BuildContext context,
  AssetTransfer transfer,
) {
  final host = hostContextOf(context);
  return PBottomSheet.show<void>(
    context,
    builder: (_) => _TransferDetail(transfer: transfer, host: host),
  );
}

class _TransferDetail extends ConsumerStatefulWidget {
  const _TransferDetail({required this.transfer, required this.host});
  final AssetTransfer transfer;
  final BuildContext host;

  @override
  ConsumerState<_TransferDetail> createState() => _TransferDetailState();
}

class _TransferDetailState extends ConsumerState<_TransferDetail> {
  bool _deleting = false;

  /// 지우기를 마치고 시트가 닫히는 중 — 닫히는 동안 버튼을 다시 열지 않는다.
  bool _closing = false;
  bool _deleteFailed = false;

  AssetTransfer get _t => widget.transfer;
  bool get _busy => _deleting || _closing;

  /// 삭제 — 확인창 → 요청. 실패는 확인창을 닫은 뒤 시트 안 보이는 자리(본문 맨 위 Callout)에 알리고 [삭제] 로 다시 시도한다.
  Future<void> _delete() async {
    if (_busy) return;
    final l = AppLocalizations.of(context);
    final ok = await PAlertDialog.show(
      context,
      title: l.transferDeleteTitle,
      description: l.transferDeleteConfirm,
      actionLabel: l.actionDelete,
      destructive: true,
      cancelLabel: l.actionCancel,
    );
    if (!ok || !mounted) return;
    setState(() {
      _deleting = true;
      _deleteFailed = false;
    });
    try {
      final repo = await ref.read(assetRepositoryProvider.future);
      await repo.deleteTransfer(_t.rowId, silent: true);
      // 서버가 양쪽 자산의 잔액 이력을 되돌리므로 자산 · 요약 · 통계를 모두 새로 받는다. 이체도 거래다.
      invalidateAfterExpenseChange(ref);
      final d = _t.transferDate;
      if (d != null && d.length >= 7) {
        final key = (
          year: int.parse(d.substring(0, 4)),
          month: int.parse(d.substring(5, 7)),
        );
        ref.invalidate(monthExpensesProvider(key));
        // 목록을 다시 받은 다음 닫는다 — 닫히며 옛 줄이 비치지 않게
        try {
          await ref.read(monthExpensesProvider(key).future);
        } catch (_) {
          // 받지 못해도 닫는다
        }
      }
      if (!mounted) return;
      _closing = true;
      PBottomSheet.of(context).close();
    } on ApiException {
      if (mounted) setState(() => _deleteFailed = true);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  /// [수정] — 상세를 내리고 옛 수정 시트를 연다. 저장하면 저장한 값으로, 저장 없이 닫혀도 상세로 돌아온다.
  void _edit() {
    if (_busy) return;
    final host = widget.host;
    final current = _t;
    PBottomSheet.of(context).close();
    showAddTxSheet(
      host,
      editTransfer: current,
      onTransferSaved: (saved) => showTransferDetailSheet(host, saved),
      onCancelled: () => showTransferDetailSheet(host, current),
    );
  }

  /// 반복 설정 — 이 이체와 **같은 값으로 규칙을 새로 만든다**. 이 이체 자체는 건드리지 않는다(이미 일어난 이체와 앞으로 실행될
  /// 규칙은 별개다).
  void _openRecurring() {
    if (_busy) return;
    final host = widget.host;
    final tr = _t;
    PBottomSheet.of(context).close();
    showRecurringSettingsDialog(host, transferSeed: tr);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locked = _t.autoSource != null;
    return PBottomSheetContent(
      key: const ValueKey('transfer-detail'),
      title: l.transferDetailTitle,
      closeLabel: l.actionClose,
      flushBody: true,
      scrollFog: true,
      body: _body(context, l, locked),
      footerRow: locked
          ? null
          : PFormDeleteFooter(
              deleteLabel: l.actionDelete,
              onDelete: _busy ? null : _delete,
              save: PButton(
                label: l.actionEdit,
                size: PButtonSize.large,
                onPressed: _busy ? null : _edit,
              ),
            ),
    );
  }

  Widget _body(BuildContext context, AppLocalizations l, bool locked) {
    final c = context.colors;
    final tr = _t;
    final fee = tr.fee ?? 0;
    final interest = tr.interestAmount ?? 0;
    // 이체 상세는 거래 상세와 같은 카드로 묶는다. 금액만 가리고 수수료를 남기면 `이체금액 = 출금총액 − 수수료` 로 좁혀지므로 한 덩어리다.
    final masked = ref
        .watch(maskFlagsProvider('ledger.txDetail'))
        .of(MaskKind.transfer);
    String won(int v) => krwSigned(v, masked, unit: true);

    final assetsAsync = ref.watch(assetsProvider);
    final loading = assetsAsync.isLoading && !assetsAsync.hasValue;
    if (loading) {
      return const TxDetailSkeleton();
    }
    final assets = assetsAsync.value ?? const <Asset>[];
    final from = assets.byRowId(tr.fromAssetRowId);
    final to = assets.byRowId(tr.toAssetRowId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_deleteFailed)
          TxFailureCallout(
            message: l.transferDeleteFailed,
            onRetry: _busy ? null : _delete,
          ),
        TxDetailHead(
          // 이체는 회색(list.md "이체 줄은 회색")
          tileBackground: c.chartGrayWeak,
          tileColor: c.chartGray,
          tileIcon: LucideIcons.arrowRightLeft,
          name: l.expTypeTransfer,
          amountText: won(tr.amount),
          amountColor: c.fgNeutral,
          dateTime: txDetailDateTimeLabel(tr.transferDate),
        ),
        // 왜 고칠 수 없는지 알려 준다 — 버튼만 없으면 고장으로 보인다
        if (locked)
          TxNoticeCallout(
            icon: LucideIcons.lock,
            text: switch (tr.autoSource) {
              'TRADE_SETTLEMENT' => l.transferAutoTradeSettlement,
              'CARD_PAYMENT' => l.transferAutoCardPayment,
              'CARD_REFUND' => l.transferAutoCardRefund,
              _ => l.transferAutoDefault,
            },
          ),
        Padding(
          key: const ValueKey('transfer-detail-accounts'),
          padding: EdgeInsets.zero,
          child: PList(
            semanticLabel: '${l.transferFromLabel} · ${l.transferToLabel}',
            children: [
              _accountRow(
                name: tr.fromAssetName,
                asset: from,
                role: l.transferFromLabel,
              ),
              _accountRow(
                name: tr.toAssetName,
                asset: to,
                role: l.transferToLabel,
              ),
            ],
          ),
        ),
        TxKvList(
          semanticLabel: l.transferDetailTitle,
          rows: [
            if (fee > 0) TxKvRow(label: l.transferFeePrefix, value: won(fee)),
            // 보내는 쪽에서 실제로 빠져나간 금액 — 수수료가 있으면 이체 금액과 다르다
            if (fee > 0)
              TxKvRow(label: l.transferWithdrawn, value: won(tr.amount + fee)),
            // 대출 상환에만 있다. 이자는 부채를 줄이지 않고 은행으로 나가는 비용이라, 안 보여 주면 "왜 원금이 이만큼밖에 안 줄었지" 가 된다
            if (interest > 0) ...[
              TxKvRow(label: l.expInterest, value: won(interest)),
              TxKvRow(
                label: l.transferPrincipal,
                value: won(tr.principalAmount ?? tr.amount - interest),
              ),
            ],
            TxKvRow(label: l.expDescription, value: tr.description),
          ],
        ),
        if (!locked)
          TxMoreSection(
            rows: [
              TxMoreRow(
                key: 'recurring',
                icon: LucideIcons.repeat,
                label: l.expConvertRecurring,
                onTap: _busy ? null : _openRecurring,
              ),
            ],
          ),
      ],
    );
  }

  /// 계좌 줄 — 앞 Logo Tile 40(그 자산의 기관), 제목 = 계좌 이름(줄바꿈), 설명 = "보내는 계좌" / "받는 계좌". 누르지 않는다.
  /// 지운 자산이라 못 찾으면 이름만 — Logo Tile 이 첫 글자를 그린다.
  Widget _accountRow({
    required String? name,
    required Asset? asset,
    required String role,
  }) {
    final title = name ?? asset?.assetName ?? '-';
    return PListItem(
      title: title,
      detail: role,
      prefix: asset != null
          ? AssetLogo(asset: asset)
          : PLogoTile(name: title, face: PLogoTileFace.name),
    );
  }
}
