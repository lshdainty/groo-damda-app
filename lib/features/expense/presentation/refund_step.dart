import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/expense/domain/card_cycle.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/expense/presentation/closed_cycle_notice.dart';
import 'package:groo_damda_app/features/expense/presentation/tx_detail_body.dart';
import 'package:groo_damda_app/features/expense/presentation/tx_detail_rules.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/callout/p_callout.dart';
import 'package:groo_damda_app/shared/ds/date_picker/p_date_picker.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';

/// 환불일로 고를 수 있는 범위 — 거래일부터 오늘까지(D16).
///
/// 날짜만 견준다(시각을 버린다). 거래 시각을 남겨 두면 거래일 당일이 범위 밖으로 떨어진다.
/// 거래일이 오늘보다 뒤인 예정 거래에는 [환불] 이 아예 없다(`ExpenseActions.canRefund`). 그래도 범위가 뒤집히지 않게만 막아 둔다.
({DateTime first, DateTime last}) refundDateRange(
  Expense expense, {
  DateTime? now,
}) {
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  final raw = expense.expenseDate;
  final txDay = raw == null || raw.length < 10
      ? null
      : DateTime.tryParse(raw.substring(0, 10));
  final first = txDay == null || txDay.isAfter(today) ? today : txDay;
  return (first: first, last: today);
}

/// 서버로 보내는 환불 시각 — `YYYY-MM-DDT12:00:00`. **정오**인 이유: 자정으로 보내면 같은 날 앞서 찍힌 거래보다 과거가 되어 카드
/// 회차 판정이 하루 밀린다.
String refundedAtIso(DateTime d) {
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '${d.year}-$m-${day}T12:00:00';
}

/// 환불 단계 — 상세 안 한 단계(I-21 I 46). 문장 · (Callout) · "환불일" 줄 → Date Picker · 안내. 바닥 [환불 처리] 와 요청은 부르는
/// 쪽이 든다. 확인창 안 날짜 칸을 대신한다(alert-dialog.md:57).
class RefundStepBody extends StatelessWidget {
  const RefundStepBody({
    super.key,
    required this.expense,
    required this.asset,
    required this.value,
    required this.onChanged,
    required this.masked,
    this.failureMessage,
  });

  final Expense expense;
  final Asset? asset;

  /// 고른 환불일(날짜만).
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final bool masked;

  /// 처리가 실패했다 — 단계 위 Callout 글(우리 글).
  final String? failureMessage;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final range = refundDateRange(expense);
    final isCreditCard = asset?.assetType == 'CREDIT_CARD';
    final cardNoPaymentAccount =
        isCreditCard && asset?.paymentAssetRowId == null;
    final span = closedCycleSpanOfExpense(expense, asset);
    final closed = span != ClosedCycleSpan.none;
    final assetName = expense.assetName ?? asset?.assetName;
    final onlyMark = refundOnlyMark(closedCycle: closed, assetName: assetName);
    final isToday = value == range.last;
    final dayText = isToday
        ? l.expRefundDateToday(monthDayDow(value))
        : monthDayDow(value);
    final txDay = DateTime.tryParse(expense.expenseDate ?? '');
    final textStyle = PTypography.articleBody.copyWith(color: c.fgNeutral);
    final noteText = closed
        ? closedCycleNote(l, span)
        : (cardNoPaymentAccount ? l.expRefundConfirmBodyCardNoAccount : null);

    return Column(
      key: const ValueKey('refund-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (failureMessage != null) TxFailureCallout(message: failureMessage!),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            PSpacing.globalGutter,
            PSpacing.x1,
            PSpacing.globalGutter,
            PSpacing.x2,
          ),
          child: onlyMark
              ? Text(
                  keepAll(l.expRefundConfirmBodyRecordOnly),
                  key: const ValueKey('refund-text'),
                  style: textStyle,
                )
              : _boldAmountText(
                  l.expRefundConfirmBody(
                    txMoney(expense.amount, masked),
                    assetName!,
                  ),
                  txMoney(expense.amount, masked),
                  textStyle,
                ),
        ),
        if (noteText != null)
          TxStatusSlot(
            child: PCallout(
              key: const ValueKey('refund-card-note'),
              description: noteText,
            ),
          ),
        PList(
          semanticLabel: l.expRefundDate,
          children: [
            PListButtonItem(
              key: const ValueKey('refund-date-row'),
              title: l.expRefundDate,
              prefix: Icon(LucideIcons.calendar, size: 22, color: c.fgNeutral),
              onTap: () => _pick(context, range),
              suffix: Text(
                keepAll(dayText),
                semanticsLabel: dayText,
                textAlign: TextAlign.end,
                style: TextStyle(color: c.fgNeutralSubtle),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            PSpacing.globalGutter,
            PSpacing.x2,
            PSpacing.globalGutter,
            PSpacing.x3,
          ),
          child: Text(
            key: const ValueKey('refund-hint'),
            l.expRefundDateHint(monthDay(txDay ?? range.first)),
            style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
          ),
        ),
      ],
    );
  }

  /// 문장 안의 금액만 굵게(700) — 금액 가리기를 따른다(가리면 점이 굵다).
  Widget _boldAmountText(String text, String amount, TextStyle style) {
    final i = text.indexOf(amount);
    if (i < 0) {
      return Text(
        keepAll(text),
        key: const ValueKey('refund-text'),
        style: style,
      );
    }
    return Text.rich(
      key: const ValueKey('refund-text'),
      TextSpan(
        style: style,
        children: [
          TextSpan(text: keepAll(text.substring(0, i))),
          TextSpan(
            text: keepAllAmount(amount),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: keepAll(text.substring(i + amount.length))),
        ],
      ),
      semanticsLabel: text,
    );
  }

  /// 환불일 고르기 시트 — 달이 이어지는 달력, 거래한 날 ~ 오늘만(그 밖은 흐리고 누르지 못한다). 고르는 동안 줄 값은 그대로이고
  /// "완료" 에 들어간다. 닫으면 버린다.
  Future<void> _pick(
    BuildContext context,
    ({DateTime first, DateTime last}) range,
  ) async {
    final picked = await showRefundDateSheet(
      context,
      value: value,
      min: range.first,
      max: range.last,
    );
    if (picked != null) onChanged(picked);
  }
}

/// 환불일 고르기 시트(고르기 시트 — 바깥 · 끌기로 닫힘, 닫으면 null).
Future<DateTime?> showRefundDateSheet(
  BuildContext context, {
  required DateTime value,
  required DateTime min,
  required DateTime max,
}) => PBottomSheet.show<DateTime>(
  context,
  builder: (ctx) {
    DateTime? draft = value;
    return StatefulBuilder(
      builder: (ctx, setSheet) {
        final l = AppLocalizations.of(ctx);
        return PBottomSheetContent(
          title: l.expRefundDate,
          closeLabel: l.actionClose,
          flushBody: true,
          body: SizedBox(
            height: PDatePicker.sheetBodyHeight(ctx),
            child: PDatePicker.single(
              labels: PDatePickerLabels.of(ctx),
              semanticLabel: l.expRefundDate,
              value: draft,
              today: max,
              min: min,
              max: max,
              visibleRange: PDateVisibleRange.continuous,
              onChanged: (v) => setSheet(() => draft = v),
            ),
          ),
          footer: [
            PButton(
              label: l.actionDone,
              size: PButtonSize.large,
              onPressed: draft == null
                  ? null
                  : () => PBottomSheet.of(ctx).close(draft),
            ),
          ],
        );
      },
    );
  },
);
