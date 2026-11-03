import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/recurring/application/recurring_providers.dart';
import 'package:groo_damda_app/features/recurring/domain/recurring_schedule.dart';
import 'package:groo_damda_app/features/recurring/domain/recurring_transaction.dart';
import 'package:groo_damda_app/features/recurring/presentation/recurring_actions.dart';
import 'package:groo_damda_app/features/recurring/presentation/recurring_format.dart';
import 'package:groo_damda_app/features/recurring/presentation/recurring_view.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/button/p_responsive_pair.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/ds/menu_sheet/p_menu_sheet.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';

const _tabular = [FontFeature.tabularFigures()];

/// 상세에서 돌려주는 동작 — 삭제 · 일시정지는 이 시트 안에서 끝낸다.
enum RecurringDetailAction { edit }

/// 반복 거래 상세(I-20 D 24 · 25) — 조회 시트(바깥 누름 · 끌어내림으로 닫힌다). 머리 오른쪽 ⋮ 메뉴(수정 · 일시정지/다시 켜기 · 삭제) →
/// 타일 48 + 이름 → 금액 → 주기 문장 → 키-값 줄 → "다음 예정일". 바닥은 [일시정지][수정] 둘 — **삭제는 바닥에 없다**(머리 ⋮ 안).
///
/// 일시정지 · 다시 켜기는 시트를 연 채 새 값으로 다시 그린다(관리자가 id 로 들고 있다가 갱신된 항목을 준다).
Future<RecurringDetailAction?> showRecurringDetailSheet(
  BuildContext context, {
  required int rowId,
}) {
  return PBottomSheet.show<RecurringDetailAction>(
    context,
    builder: (_) => RecurringDetailBody(rowId: rowId),
  );
}

class RecurringDetailBody extends ConsumerStatefulWidget {
  const RecurringDetailBody({super.key, required this.rowId});
  final int rowId;

  @override
  ConsumerState<RecurringDetailBody> createState() =>
      _RecurringDetailBodyState();
}

class _RecurringDetailBodyState extends ConsumerState<RecurringDetailBody> {
  bool _busy = false;

  /// 마지막으로 본 값 — 지운 직후 목록이 다시 받아져 항목이 사라져도 닫히는 동안 빈 시트로 깜빡이지 않게.
  RecurringTransaction? _last;

  Future<void> _toggle(RecurringTransaction it) async {
    if (_busy) return;
    setState(() => _busy = true);
    await toggleRecurringWithNotice(context, ref, it);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _delete(RecurringTransaction it) async {
    if (_busy) return;
    final sheet = PBottomSheet.of(context);
    setState(() => _busy = true);
    final ok = await deleteRecurringWithNotice(
      context,
      ref,
      it,
      onRetried: sheet.close,
    );
    if (!mounted) return;
    if (ok) {
      // 지운 뒤 닫히기 전에는 두 버튼을 막은 채 둔다
      sheet.close();
      return;
    }
    setState(() => _busy = false);
  }

  Widget _headerAction(AppLocalizations l, RecurringTransaction it) {
    final active = it.isActive == 'Y';
    final name = recDisplayTitle(l, it);
    return PButton.icon(
      icon: LucideIcons.ellipsisVertical,
      semanticLabel: l.recMoreOf(name),
      variant: PButtonVariant.ghost,
      ghostColor: PButtonGhostColor.neutralSubtle,
      size: PButtonSize.small,
      onPressed: _busy
          ? null
          : () => PMenuSheet.show(
              context,
              title: name,
              groups: [
                PMenuSheetGroup([
                  PMenuSheetItem(
                    label: l.actionEdit,
                    icon: LucideIcons.pencil,
                    onSelect: () => PBottomSheet.of(
                      context,
                    ).close(RecurringDetailAction.edit),
                  ),
                  PMenuSheetItem(
                    label: active ? l.recPause : l.recResume,
                    icon: active ? LucideIcons.pause : LucideIcons.play,
                    onSelect: () => _toggle(it),
                  ),
                ]),
                PMenuSheetGroup([
                  PMenuSheetItem(
                    label: l.actionDelete,
                    icon: LucideIcons.trash2,
                    tone: PMenuSheetTone.critical,
                    onSelect: () => _delete(it),
                  ),
                ]),
              ],
            ),
    );
  }

  String? _payLabel(AppLocalizations l, String? v) => switch (v) {
    'CASH' => l.expPayCash,
    'CARD' => l.expPayCard,
    'TRANSFER' => l.expPayTransfer,
    'OTHER' => l.expPayOther,
    _ => null,
  };

  /// 키-값 줄 — 값 없는 줄은 그리지 않는다.
  List<({String key, String name, String value})> _rows(
    AppLocalizations l,
    RecurringTransaction it,
    ExpenseCategory? cat,
  ) {
    final rows = <({String key, String name, String value})>[];
    void add(String key, String name, String? value) {
      if (value != null && value.isNotEmpty) {
        rows.add((key: key, name: name, value: value));
      }
    }

    final isTransfer = it.expenseType == 'TRANSFER';
    final isIncome = it.expenseType == 'INCOME';
    if (isTransfer) {
      add('from', l.recFromAccount, it.assetName);
      add('to', l.recDepositAccount, it.toAssetName);
      add(
        'fee',
        l.expFee,
        (it.fee ?? 0) > 0 ? krwSigned(it.fee!, false, unit: true) : null,
      );
      add(
        'interest',
        l.expInterest,
        (it.interestAmount ?? 0) > 0
            ? krwSigned(it.interestAmount!, false, unit: true)
            : null,
      );
    } else {
      add('category', l.expCategory, cat?.categoryName ?? it.categoryName);
      add(
        'asset',
        isIncome ? l.recDepositAccount : l.recurringAssetCard,
        it.assetName,
      );
      add(
        'payment',
        isIncome ? l.recIncomeMethod : l.expPaymentMethod,
        _payLabel(l, it.paymentMethod),
      );
    }
    add('memo', l.expDescription, it.description);
    add(
      'auto',
      l.recAutoLog,
      it.autoLog ? l.recOnWithCount(it.executedCount) : l.recOff,
    );
    add(
      'notify',
      l.recNotifyDayBefore,
      it.notifyDayBefore ? l.recOn : l.recOff,
    );
    if (!isTransfer) {
      add(
        'fixed',
        isIncome ? l.fixedSwitchIncome : l.fixedSwitchExpense,
        it.isFixed ? l.recOn : l.recOff,
      );
    }
    return rows;
  }

  /// 주기를 문장으로 — 켜짐 "…, 끝나는 날 없이 반복해요. 다음은 **11월 25일 오전 9시**예요." · 쉬는 중 · 끝남.
  Widget _sentence(AppLocalizations l, RecurringTransaction it) {
    final c = context.colors;
    final base = PTypography.t5.copyWith(color: c.fgNeutral);
    final bold = base.copyWith(fontWeight: FontWeight.w700);
    final List<InlineSpan> spans;
    if (isPausedRec(it)) {
      spans = [
        TextSpan(
          text: keepAll(l.recSentencePausedPre),
          semanticsLabel: l.recSentencePausedPre,
        ),
        TextSpan(
          text: keepAll(l.recSentencePausedBold),
          semanticsLabel: l.recSentencePausedBold,
          style: bold,
        ),
        TextSpan(
          text: keepAll(l.recSentencePausedPost),
          semanticsLabel: l.recSentencePausedPost,
        ),
      ];
    } else if (isFinished(it)) {
      spans = [
        TextSpan(
          text: keepAll(l.recSentenceFinished),
          semanticsLabel: l.recSentenceFinished,
        ),
      ];
    } else {
      final end = it.maxOccurrences != null
          ? l.recEndSentenceCount(it.maxOccurrences!, it.executedCount)
          : it.endDate != null
          ? l.recEndSentenceDate(
              recDateLong(parseDayKey(it.endDate) ?? recurringNow()),
            )
          : l.recEndSentenceNone;
      final next =
          '${recDateKeyText(it.nextExecutionDate ?? '')} ${recClockText((it.executionTime ?? '09:00:00').substring(0, 5))}';
      spans = [
        TextSpan(
          text: keepAll(l.recSentenceLead(recCycleOf(l, it), end)),
          semanticsLabel: l.recSentenceLead(recCycleOf(l, it), end),
        ),
        const TextSpan(text: ' '),
        TextSpan(
          text: keepAll(l.recSentenceNextPre),
          semanticsLabel: l.recSentenceNextPre,
        ),
        TextSpan(
          text: keepAll(recNoBreak(next)),
          semanticsLabel: next,
          style: bold,
        ),
        TextSpan(
          text: keepAll(l.recSentenceNextPost),
          semanticsLabel: l.recSentenceNextPost,
        ),
      ];
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PSpacing.globalGutter,
        PSpacing.x1,
        PSpacing.globalGutter,
        PSpacing.x2,
      ),
      child: Text.rich(TextSpan(children: spans, style: base)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final list = ref.watch(recurringListProvider).value;
    final it = list?.where((e) => e.rowId == widget.rowId).firstOrNull ?? _last;
    if (it == null) {
      // 지워졌거나 목록이 없다 — 빈 시트를 그리지 않고 곧 닫는다
      return PBottomSheetContent(
        title: l.recDetailTitle,
        closeLabel: l.actionClose,
        body: const SizedBox(height: PSpacing.x10),
      );
    }
    _last = it;
    final masked = ref.watch(hideCardProvider('etc.recurring'));
    final categories =
        ref.watch(categoriesProvider).value ?? const <ExpenseCategory>[];
    final cat = categories.byRowId(it.categoryRowId);
    final active = it.isActive == 'Y';
    final amount = recAmountText(it, masked: masked);
    final dates = upcomingDates(
      ScheduleRule.of(it),
      it.nextExecutionDate ?? '',
      it.executedCount,
      3,
      active: active,
    );

    return PBottomSheetContent(
      title: l.recDetailTitle,
      closeLabel: l.actionClose,
      headerAction: _headerAction(l, it),
      flushBody: true,
      // 이름 · 메모 · 다음 예정일이 사용자 값이고 200% 에서 넘친다 — 끝 흐림을 켠다(웹 50bf362c 와 같은 판정)
      scrollFog: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 머리 — 타일 48 + 이름(t7 · 700 · 줄바꿈), 사이 12 · 위 0 · 아래 8.
          // 시트 머리 아래 16 + (끝 흐림 켬이면 본문 안 여백 위 20) = 첫 칸 간격 36 / 끔 16 — 여기서 더 얹지 않는다.
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
                recurringTile(
                  context,
                  it,
                  cat,
                  size: PSpacing.x12,
                  iconSize: PSpacing.x6,
                ),
                Expanded(
                  child: Text(
                    keepAll(recDisplayTitle(l, it)),
                    semanticsLabel: recDisplayTitle(l, it),
                    style: PTypography.t7.copyWith(
                      color: c.fgNeutral,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PSpacing.globalGutter,
              PSpacing.x3,
              PSpacing.globalGutter,
              PSpacing.x1,
            ),
            child: Text(
              keepAllAmount(amount),
              semanticsLabel: amount,
              style: PTypography.t9.copyWith(
                color: recAmountColor(context, it),
                fontWeight: FontWeight.w700,
                fontFeatures: _tabular,
              ),
            ),
          ),
          _sentence(l, it),
          // 키-값 줄 — 값은 줄 수와 상관없이 줄 끝 오른쪽 맞춤
          PList(
            semanticLabel: l.recDetailTitle,
            children: [
              for (final r in _rows(l, it, cat))
                PListItem(
                  key: ValueKey('recurring-detail-${r.key}'),
                  title: r.name,
                  suffix: Text(
                    r.value,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: c.fgNeutral,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          if (dates.isNotEmpty) ...[
            PListHeader(
              title: l.recNextDatesTitle,
              variant: PListHeaderVariant.boldSolid,
              topInset: PSpacing.x4,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PSpacing.globalGutter,
                0,
                PSpacing.globalGutter,
                PSpacing.x2,
              ),
              child: Wrap(
                spacing: PSpacing.x4,
                runSpacing: PSpacing.x1,
                children: [
                  for (final d in dates)
                    Text(
                      recDateKeyText(d),
                      style: PTypography.t4.copyWith(
                        color: c.fgNeutralMuted,
                        fontFeatures: _tabular,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
      // 알림(스낵바)이 바닥 버튼을 덮지 않고 그 위 8 에 선다(웹 `SnackbarAvoidOverlap` 과 같다)
      footerRow: PSnackbarAvoidOverlap(
        child: PResponsivePair(
          secondary: PButton(
            label: active ? l.recPause : l.recResume,
            variant: PButtonVariant.neutralWeak,
            size: PButtonSize.large,
            prefixIcon: active ? LucideIcons.pause : LucideIcons.play,
            onPressed: _busy ? null : () => _toggle(it),
          ),
          primary: PButton(
            label: l.actionEdit,
            size: PButtonSize.large,
            onPressed: _busy
                ? null
                : () => PBottomSheet.of(
                    context,
                  ).close(RecurringDetailAction.edit),
          ),
        ),
      ),
    );
  }
}
