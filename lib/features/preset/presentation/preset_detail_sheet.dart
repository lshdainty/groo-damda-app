import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/preset/domain/expense_template.dart';
import 'package:groo_damda_app/features/preset/presentation/preset_actions.dart';
import 'package:groo_damda_app/features/preset/presentation/preset_view.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/forms/form_delete_footer.dart';

/// 상세에서 돌려주는 동작 — 삭제는 이 시트 안에서 끝낸다(확인창 → 지움 → 목록을 다시 받은 뒤 닫힘).
enum PresetDetailAction { edit }

const _tabular = [FontFeature.tabularFigures()];

/// 프리셋 상세(I-20 C 18) — 조회 시트(바깥 누름 · 끌어내림으로 닫힌다). 머리(타일 48 + 이름) → 금액 → 설명 한 줄 → 키-값 줄.
/// 값이 없는 줄은 그리지 않는다. 바닥은 [삭제](ghost critical 왼쪽) + [수정](나머지). 줄 끝 ⋮ 가 없으니 지우기는 여기다.
///
/// [삭제] → 확인창(PAlertDialog) → 지움. 실패하면 확인창을 닫고 critical 스낵바 + [다시 시도](바로 요청)로 알린다 — 전역 오류
/// 토스트와 겹치지 않는다. 지우는 동안과 지운 뒤 닫히기 전에는 두 버튼을 막는다.
Future<PresetDetailAction?> showPresetDetailSheet(
  BuildContext context, {
  required ExpenseTemplate template,
}) {
  return PBottomSheet.show<PresetDetailAction>(
    context,
    builder: (_) => PresetDetailBody(template: template),
  );
}

class PresetDetailBody extends ConsumerStatefulWidget {
  const PresetDetailBody({super.key, required this.template});
  final ExpenseTemplate template;

  @override
  ConsumerState<PresetDetailBody> createState() => _PresetDetailBodyState();
}

class _PresetDetailBodyState extends ConsumerState<PresetDetailBody> {
  bool _busy = false;

  /// [삭제] → 확인창 → 지움. **확인창 실패는 확인창을 닫고 critical 스낵바 + [다시 시도]** 다(웹과 같다 — 스낵바 호스트는 길잡이 바깥이라
  /// 시트 · 확인창 위에 뜬다). 다시 시도는 묻지 않고 바로 지운다(이미 한 번 확정한 삭제). 지우는 동안과 지운 뒤 닫히기 전에는 두 버튼을 막는다.
  Future<void> _delete() async {
    if (_busy) return;
    final l = AppLocalizations.of(context);
    final sheet = PBottomSheet.of(context);
    final snack = PSnackbar.of(context);
    final container = ProviderScope.containerOf(context);
    setState(() => _busy = true);
    final r = await askDeletePreset(context, widget.template);
    if (r.confirmed && r.failure == null) {
      sheet.close();
      return;
    }
    if (mounted) setState(() => _busy = false);
    if (r.confirmed && r.failure != null) {
      _failed(container, snack, l, sheet);
    }
  }

  void _failed(
    ProviderContainer container,
    PSnackbarApi snack,
    AppLocalizations l,
    PBottomSheetController sheet,
  ) {
    snack.show(
      message: l.presetDeleteFailed,
      tone: PSnackbarTone.critical,
      action: PSnackbarAction(
        label: l.actionRetry,
        onPressed: () async {
          try {
            await deletePresetRequest(container, widget.template.rowId);
            // 시트가 아직 열려 있으면 닫는다(지운 프리셋의 상세가 남지 않게)
            if (mounted) sheet.close();
          } catch (_) {
            _failed(container, snack, l, sheet);
          }
        },
      ),
    );
  }

  List<({String key, String name, String value})> _rows(AppLocalizations l) {
    final p = widget.template;
    final rows = <({String key, String name, String value})>[];
    void add(String key, String name, String? value) {
      if (value != null && value.isNotEmpty) {
        rows.add((key: key, name: name, value: value));
      }
    }

    final isTransfer = p.expenseType == 'TRANSFER';
    final isIncome = p.expenseType == 'INCOME';
    add(
      'type',
      l.presetTypeLabel,
      isTransfer
          ? l.expTypeTransfer
          : (isIncome ? l.expTypeIncome : l.expTypeExpense),
    );
    if (isTransfer) {
      add('from', l.presetFromAccount, p.assetName);
      add('to', l.presetToAccount, p.toAssetName);
      add(
        'fee',
        l.presetFeeLabel,
        (p.fee ?? 0) > 0 ? krwSigned(p.fee!, false, unit: true) : null,
      );
      add(
        'interest',
        l.expInterest,
        (p.interestAmount ?? 0) > 0
            ? krwSigned(p.interestAmount!, false, unit: true)
            : null,
      );
    } else {
      add('category', l.expCategory, p.categoryName);
      add('asset', l.presetAssetCard, p.assetName);
      add('payment', l.expPaymentMethod, switch (p.paymentMethod) {
        'CASH' => l.expPayCash,
        'CARD' => l.expPayCard,
        'TRANSFER' => l.expPayTransfer,
        'OTHER' => l.expPayOther,
        _ => null,
      });
      add('merchant', l.presetMerchant, p.merchant);
    }
    add('memo', l.expDescription, p.description);
    if (!isTransfer) {
      add(
        'fixed',
        isIncome ? l.presetFixedTitleIncome : l.presetFixedTitleExpense,
        p.isFixed ? l.presetFixedOn : l.presetFixedOff,
      );
    }
    return rows;
  }

  /// 설명 한 줄 — "고정 금액 · 3번 썼어요 · 마지막 10월 3일"(0번이면 "아직 쓰지 않았어요", 마지막 쓴 날이 없으면 그 조각을 뺀다).
  String _note(AppLocalizations l) {
    final p = widget.template;
    final uses = p.useCount ?? 0;
    final last = p.lastUsedAt == null ? null : DateTime.tryParse(p.lastUsedAt!);
    return [
      presetHasAmount(p) ? l.presetNoteFixed : l.presetAmountEmpty,
      uses > 0 ? l.presetNoteUses(uses) : l.presetNoteUnused,
      if (uses > 0 && last != null) l.presetNoteLast(last.month, last.day),
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final p = widget.template;
    final masked = ref.watch(hideCardProvider('etc.preset'));
    final categories =
        ref.watch(categoriesProvider).value ?? const <ExpenseCategory>[];
    final category = p.categoryRowId == null
        ? null
        : categories.byRowId(p.categoryRowId!);
    final amount = presetAmountText(p, masked: masked);

    return PBottomSheetContent(
      title: l.presetDetailTitle,
      closeLabel: l.actionClose,
      // 내용만큼 높다(스펙 "내용만큼 높고 90% 를 넘지 않는다") — 끝 흐림은 위 20 · 아래 80 여백을 더해 시트를 키우므로 두지 않는다
      flushBody: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 머리 — 타일 48 + 이름(t7 · 700 · 줄바꿈), 사이 12 · 위 0(머리 아래 16 에서 바로) · 아래 8(T16)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PSpacing.globalGutter,
              0,
              PSpacing.globalGutter,
              PSpacing.x2,
            ),
            child: Row(
              spacing: PSpacing.x3,
              children: [
                presetTile(
                  context,
                  p,
                  category,
                  size: PSpacing.x12,
                  iconSize: PSpacing.x6,
                ),
                Expanded(
                  child: Text(
                    keepAll(p.templateName),
                    semanticsLabel: p.templateName,
                    style: PTypography.t7.copyWith(
                      color: c.fgNeutral,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 금액(고정일 때만 t9) · 설명 — 금액 위 12 · 아래 4, 설명 위 4 · 아래 8
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PSpacing.globalGutter,
              PSpacing.x3,
              PSpacing.globalGutter,
              PSpacing.x1,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (amount != null)
                  Text(
                    keepAllAmount(amount),
                    semanticsLabel: amount,
                    style: PTypography.t9.copyWith(
                      color: presetAmountColor(context, p),
                      fontWeight: FontWeight.w700,
                      fontFeatures: _tabular,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(
                    top: PSpacing.x1,
                    bottom: PSpacing.x2,
                  ),
                  child: Text(
                    keepAll(_note(l)),
                    semanticsLabel: _note(l),
                    style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
                  ),
                ),
              ],
            ),
          ),
          // 키-값 줄 — 열쇠 fg-neutral · 값 fg-neutral-muted 줄 끝 오른쪽 맞춤(줄 수와 상관없이)
          PList(
            semanticLabel: l.presetDetailTitle,
            children: [
              for (final r in _rows(l))
                PListItem(
                  key: ValueKey('preset-detail-${r.key}'),
                  title: r.name,
                  suffix: Text(
                    keepAll(r.value),
                    semanticsLabel: r.value,
                    textAlign: TextAlign.end,
                  ),
                ),
            ],
          ),
        ],
      ),
      footerRow: PFormDeleteFooter(
        deleteLabel: l.actionDelete,
        onDelete: _busy ? null : _delete,
        save: PButton(
          label: l.actionEdit,
          size: PButtonSize.large,
          onPressed: _busy
              ? null
              : () => PBottomSheet.of(context).close(PresetDetailAction.edit),
        ),
      ),
    );
  }
}
