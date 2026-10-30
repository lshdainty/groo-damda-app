import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/radius.dart';
import 'package:groo_damda_app/app/theme/spacing.dart';
import 'package:groo_damda_app/app/theme/tokens.dart';
import 'package:groo_damda_app/app/theme/typography.dart';
import 'package:groo_damda_app/core/format/amount_limits.dart';
import 'package:groo_damda_app/core/format/chart_palette.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/core/format/format_locale.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/icons/lucide_icon_map.dart';
import 'package:groo_damda_app/shared/widgets/p_category_tile.dart';
import 'package:groo_damda_app/shared/widgets/p_date_input.dart';
import 'package:groo_damda_app/shared/widgets/p_detail.dart';
import 'package:groo_damda_app/shared/widgets/p_modal.dart';
import 'package:groo_damda_app/shared/widgets/p_progress.dart';
import 'package:groo_damda_app/shared/widgets/p_section_label.dart';
import 'package:groo_damda_app/shared/widgets/p_select.dart';
import 'package:groo_damda_app/shared/widgets/p_switch.dart';
import 'package:groo_damda_app/shared/widgets/p_tabs.dart';
import 'package:groo_damda_app/shared/widgets/p_text_input.dart';
import 'package:groo_damda_app/features/asset/domain/transfer_rules.dart';
import 'package:groo_damda_app/features/asset/presentation/transfer_account_fields.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/domain/asset_transfer.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/core/sync/keep_alive_refresh.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/recurring/application/recurring_providers.dart';
import 'package:groo_damda_app/features/recurring/domain/recurring_schedule.dart';
import 'package:groo_damda_app/features/recurring/domain/recurring_transaction.dart';
import 'package:groo_damda_app/features/recurring/presentation/recurring_form.dart';

/// 반복 설정 drawer — **거래 기반 신규 생성**과 **기존 반복 수정**을 공용으로 처리.
///
/// - [expense] 제공 → 거래에서 반복 생성 (sourceExpenseRowId 연결, `repo.create`)
/// - [recurring] 제공 → 기존 반복 수정 (`repo.update`)
///
/// 정확히 하나만 제공한다. 거래 정보(카테고리·금액·가맹점)는 읽기 전용 요약
/// 카드로 보여주고, 사용자는 반복 주기·종료·옵션만 설정한다. 가계부 거래 상세의
/// "반복 설정"과 설정 화면의 "반복 거래 수정"이 같은 body를 공유한다.
/// [transferSeed] — **새로 만들되 값만 물려받는다**(이체 상세의 "반복 설정").
///
/// [recurring] 과 달리 수정 모드로 들어가지 않는다. 이미 일어난 이체와 앞으로 실행될
/// 규칙은 별개라, 여기서 금액을 고쳐도 그 이체는 그대로여야 한다(사용자 결정 2026-09-14).
void showRecurringSettingsDialog(
  BuildContext context, {
  Expense? expense,
  RecurringTransaction? recurring,
  AssetTransfer? transferSeed,
}) {
  assert(
    !(expense != null && recurring != null),
    'expense 와 recurring 을 동시에 줄 수 없습니다 (둘 다 null = 신규 추가)',
  );
  // 추가 · 수정 · 이체 씨앗은 새 폼(I-20 D 26). 거래에서 만들기(`expense:`)는 I-21 이 새 폼에 옮길 때까지 아래 옛 몸 그대로다.
  if (expense == null) {
    showRecurringFormSheet(
      context,
      recurring: recurring,
      transferSeed: transferSeed,
    );
    return;
  }
  final l = AppLocalizations.of(context);
  final controller = PSheetController();
  showPSheet<void>(
    context,
    title: l.expConvertRecurring,
    contentBuilder: (ctx, scrollCtrl) => _RecurringSettingsBody(
      expense: expense,
      scrollController: scrollCtrl,
      controller: controller,
    ),
    footerBuilder: (ctx) => PSheetFooter(
      controller: controller,
      submitLabel: l.recurringSaveSubmit,
    ),
  );
}

enum _EndMode { none, count, date }

class _RecurringSettingsBody extends ConsumerStatefulWidget {
  const _RecurringSettingsBody({
    required this.expense,
    required this.scrollController,
    required this.controller,
  });
  final Expense? expense;

  /// 추가 · 수정 · 이체 씨앗은 새 폼(`recurring_form.dart`)이 맡는다 — 이 몸은 거래에서 만들기만 한다(I-21 이 옮긴다).
  RecurringTransaction? get recurring => null;
  AssetTransfer? get transferSeed => null;
  final ScrollController scrollController;
  final PSheetController controller;

  @override
  ConsumerState<_RecurringSettingsBody> createState() =>
      _RecurringSettingsBodyState();
}

class _RecurringSettingsBodyState
    extends ConsumerState<_RecurringSettingsBody> {
  bool get _isEdit => widget.recurring != null;
  bool get _isAdd => widget.recurring == null && widget.expense == null;

  /// 거래 입력 — 신규 추가와 **기존 반복 수정**이 같은 폼을 쓴다. 수정은 저장된 값으로
  /// 채워 연다. 종전엔 수정이 금액·일정만 고칠 수 있어 계좌·거래처를 바꿀 길이 없었다
  /// (사용자 결정 2026-09-03: 생성과 수정은 같은 입력을 받는다. 이미 만들어진 실행분은
  /// 그대로고 다음 실행분부터 바뀐 값으로 만들어진다).
  _TxInputController? _txInput;
  late final DateTime _fixedBaseDate; // from-tx 시작일(기준 거래일)
  DateTime get _baseDate => _txInput?.date ?? _fixedBaseDate;
  String get _startDay => _fmt(_baseDate);

  String _frequency = 'MONTHLY';
  int _dayOfWeekUi = 1; // 0=일 ~ 6=토 (UI). 저장 시 ISO 1~7 변환.
  int _dayOfMonth = 1;

  late _EndMode _endMode;
  final TextEditingController _endCountCtrl = TextEditingController(text: '12');
  late DateTime _endDate;

  bool _autoLog = true;
  bool _notifyDayBefore = true;

  /// 고정 수입·지출 — 이 반복이 만드는 거래가 표식을 물려받는다(이체는 해당 없음).
  bool _isFixed = false;

  /// 지금 폼의 거래 종류 — 직접 추가·수정은 폼이, 거래에서 만들기는 원 거래가 정한다.
  String get _kind =>
      _txInput?.type ?? widget.expense?.expenseType ?? 'EXPENSE';
  bool _submitting = false;

  /// 실행 시각 'HH:mm' — 이 시각으로 실행분이 만들어진다. 서버 기본값은 09:00.
  String _executionTime = '09:00';

  @override
  void initState() {
    super.initState();
    final r = widget.recurring;
    final e = widget.expense;

    if (_isAdd) {
      final seed = widget.transferSeed;
      _txInput = seed == null
          ? _TxInputController(date: DateTime.now())
          : _TxInputController(
              // 이 이체가 일어난 날부터 반복한다 — 규칙은 이 거래를 본떠 만든 것이다.
              date:
                  DateTime.tryParse(
                    (seed.transferDate ?? '').padRight(10).substring(0, 10),
                  ) ??
                  DateTime.now(),
              type: 'TRANSFER',
              amount: seed.amount,
              memo: seed.description,
              assetRowId: seed.fromAssetRowId,
              toAssetRowId: seed.toAssetRowId,
              fee: seed.fee,
              interestAmount: seed.interestAmount,
            );
    } else {
      // base date: edit → recurring.startDate, from-tx → expense.expenseDate
      final raw = (_isEdit ? (r!.startDate ?? '') : (e!.expenseDate ?? ''))
          .trim();
      final parsed = raw.isNotEmpty
          ? DateTime.tryParse(raw.length >= 10 ? raw.substring(0, 10) : raw)
          : null;
      final today = DateTime.now();
      final base = parsed ?? DateTime(today.year, today.month, today.day);
      if (_isEdit) {
        // 서버는 'HH:mm:ss' 로 준다. 앞 5글자만 쓴다.
        final et = (r!.executionTime ?? '').trim();
        if (et.length >= 5) _executionTime = et.substring(0, 5);
        _txInput = _TxInputController(
          date: base,
          type: r.expenseType,
          amount: r.amount.abs(),
          merchant: r.merchant,
          memo: r.description,
          categoryRowId: r.categoryRowId,
          assetRowId: r.assetRowId,
          toAssetRowId: r.toAssetRowId,
          fee: r.fee,
          interestAmount: r.interestAmount,
          paymentMethod: r.paymentMethod ?? '',
        );
      } else {
        _fixedBaseDate = base;
      }
    }

    _frequency = r?.frequency ?? 'MONTHLY';

    // dayOfWeek: edit는 ISO 1~7 저장 → UI 0~6, create는 거래일 요일
    if (_isEdit && r!.dayOfWeek != null) {
      _dayOfWeekUi = r.dayOfWeek! % 7; // ISO Sun(7)→0, Mon(1)→1 ...
    } else {
      _dayOfWeekUi = _baseDate.weekday % 7; // Mon=1..Sun=7 → UI 1..0
    }
    _dayOfMonth = (r?.dayOfMonth ?? _baseDate.day).clamp(1, 31);

    // 종료 모드: edit는 저장값에서 복원, create는 종료일 기본
    if (_isEdit && r!.maxOccurrences != null) {
      _endMode = _EndMode.count;
    } else if (_isEdit && r!.endDate != null) {
      _endMode = _EndMode.date;
    } else if (_isEdit) {
      _endMode = _EndMode.none;
    } else {
      _endMode = _EndMode.date;
    }
    _endCountCtrl.text = (r?.maxOccurrences ?? 12).toString();
    _endDate = (_isEdit && r!.endDate != null)
        ? DateTime.parse(r.endDate!)
        : DateTime(_baseDate.year + 1, _baseDate.month, _baseDate.day);

    _autoLog = r?.autoLog ?? true;
    _notifyDayBefore = r?.notifyDayBefore ?? true;
    // 수정은 저장된 표식을, 거래에서 만들기는 원 거래의 표식을 이어받는다 — 월세를 반복으로 걸면
    // 매달 고정 월세가 된다.
    _isFixed = r?.isFixed ?? widget.expense?.isFixed ?? false;

    widget.controller.onSubmit = _save;
  }

  void _setSubmitting(bool v) {
    setState(() => _submitting = v);
    widget.controller.setSubmitting(v);
  }

  @override
  void dispose() {
    _endCountCtrl.dispose();
    _txInput?.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool get _ready {
    if (_endMode == _EndMode.count) {
      final n = int.tryParse(_endCountCtrl.text.trim());
      if (n == null || n <= 0) return false;
    }
    final i = _txInput;
    if (i != null) {
      if (i.amountInt <= 0) return false;
      // 이체는 카테고리가 없는 대신 양쪽 계좌가 있어야 성립한다 — 서버도 같은 규칙으로
      // 거절한다. 못 막으면 "저장됐다" 고 남았다가 자정 배치만 조용히 실패한다.
      if (i.isTransfer) {
        return transferPartiesReady(i.assetRowId, i.toAssetRowId);
      }
      // add·edit 공통 — 자산은 선택사항, 거래 폼과 같은 규칙(웹 정합).
      return i.categoryRowId != null;
    }
    return widget.expense!.categoryRowId != null;
  }

  Future<void> _save() async {
    if (!_ready || _submitting) return;
    _setSubmitting(true);
    final isWeekly = _frequency == 'WEEKLY';
    final isMonthlyish = _frequency == 'MONTHLY' || _frequency == 'YEARLY';
    // UI 0=일 → ISO 7=일. UI 1~6 (월~토) → ISO 1~6.
    final dow = isWeekly ? (_dayOfWeekUi == 0 ? 7 : _dayOfWeekUi) : null;
    final dom = isMonthlyish ? _dayOfMonth : null;
    final endDateStr = _endMode == _EndMode.date ? _fmt(_endDate) : null;
    final maxOcc = _endMode == _EndMode.count
        ? int.tryParse(_endCountCtrl.text.trim())
        : null;
    try {
      final repo = await ref.read(recurringRepositoryProvider.future);
      if (_isEdit) {
        final r = widget.recurring!;
        final i = _txInput!;
        // 폼 값 전부를 보낸다 — 다음 실행분부터 이 값으로 만들어진다.
        await repo.update(
          id: r.rowId,
          // 이체 칸과 지출·수입 칸은 서로 배타다 — 섞여 실리면 서버가 400 이다.
          categoryRowId: i.isTransfer ? null : i.categoryRowId,
          assetRowId: i.assetRowId,
          toAssetRowId: i.isTransfer ? i.toAssetRowId : null,
          fee: i.isTransfer ? i.feeOrNull : null,
          interestAmount: i.isTransfer ? i.interestOrNull : null,
          expenseType: i.type,
          amount: i.amountInt,
          frequency: _frequency,
          intervalValue: r.intervalValue ?? 1,
          dayOfWeek: dow,
          dayOfMonth: dom,
          executionTime: '$_executionTime:00',
          startDate: _startDay,
          endDate: endDateStr,
          maxOccurrences: maxOcc,
          description: i.memoOrNull,
          merchant: i.isTransfer ? null : i.merchantOrNull,
          paymentMethod: i.isTransfer ? null : i.paymentMethodOrNull,
          autoLog: _autoLog,
          notifyDayBefore: _notifyDayBefore,
          // 이체는 고정이 없다 — 켜 둔 채 이체로 바꿔도 싣지 않는다(서버도 꺼 버린다).
          isFixed: !i.isTransfer && _isFixed,
        );
      } else if (_isAdd) {
        final i = _txInput!;
        await repo.create(
          categoryRowId: i.isTransfer ? null : i.categoryRowId,
          assetRowId: i.assetRowId,
          toAssetRowId: i.isTransfer ? i.toAssetRowId : null,
          fee: i.isTransfer ? i.feeOrNull : null,
          interestAmount: i.isTransfer ? i.interestOrNull : null,
          sourceExpenseRowId: null,
          expenseType: i.type,
          amount: i.amountInt,
          frequency: _frequency,
          intervalValue: 1,
          dayOfWeek: dow,
          dayOfMonth: dom,
          executionTime: '$_executionTime:00',
          startDate: _startDay,
          endDate: endDateStr,
          maxOccurrences: maxOcc,
          description: i.memoOrNull,
          merchant: i.isTransfer ? null : i.merchantOrNull,
          paymentMethod: i.isTransfer ? null : i.paymentMethodOrNull,
          autoLog: _autoLog,
          notifyDayBefore: _notifyDayBefore,
          isFixed: !i.isTransfer && _isFixed,
        );
      } else {
        final e = widget.expense!;
        await repo.create(
          categoryRowId: e.categoryRowId,
          assetRowId: e.assetRowId,
          sourceExpenseRowId: e.rowId,
          expenseType: e.expenseType,
          amount: e.amount.abs(),
          frequency: _frequency,
          intervalValue: 1,
          dayOfWeek: dow,
          dayOfMonth: dom,
          executionTime: '$_executionTime:00',
          startDate: _startDay,
          endDate: endDateStr,
          maxOccurrences: maxOcc,
          description: (e.description ?? '').trim().isEmpty
              ? null
              : e.description!.trim(),
          merchant: (e.merchant ?? '').trim().isEmpty
              ? null
              : e.merchant!.trim(),
          paymentMethod: e.paymentMethod,
          autoLog: _autoLog,
          notifyDayBefore: _notifyDayBefore,
          isFixed: _isFixed,
        );
      }
      ref.invalidate(recurringListProvider);
      // 만들거나 고친 규칙의 회차가 오늘이면 서버가 그 거래를 바로 기록한다(QA 30 1, back
      // #360) — 가계부·자산·홈도 함께 새로 받는다.
      ref.invalidate(monthExpensesProvider);
      invalidateAfterExpenseChange(ref);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ApiException {
      if (!mounted) return;
    } finally {
      if (mounted) _setSubmitting(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);

    final Widget topWidget;
    if (_txInput != null) {
      // add·edit — 같은 거래 입력 폼(수정은 저장값으로 채워져 있다)
      topWidget = _TxFields(
        controller: _txInput!,
        onChanged: () => setState(() {}),
      );
    } else {
      // 요약 카드 데이터 — edit: recurring / from-tx: expense
      final cats = ref.watch(categoriesProvider).value ?? const [];
      final r = widget.recurring;
      final e = widget.expense;
      final catRowId = _isEdit ? r!.categoryRowId : e!.categoryRowId;
      final cat = catRowId == null
          ? null
          : cats.where((c) => c.rowId == catRowId).firstOrNull;
      final fg = cat == null
          ? t.fgBrand
          : resolveChartColor(context, cat.color, fallback: t.fgBrand);
      final iconData = lucideByName(cat?.icon ?? 'tag');
      final String summaryTitle;
      final int summaryAmount;
      final String summaryType;
      if (_isEdit) {
        summaryTitle = (r!.merchant ?? '').isNotEmpty
            ? r.merchant!
            : ((r.description ?? '').isNotEmpty
                  ? r.description!
                  : (r.categoryName ?? l.navRecurring));
        summaryAmount = r.amount;
        summaryType = r.expenseType;
      } else {
        summaryTitle = (e!.merchant ?? '').isNotEmpty
            ? e.merchant!
            : ((e.description ?? '').isNotEmpty
                  ? e.description!
                  : l.expTxFallback);
        summaryAmount = e.amount;
        summaryType = e.expenseType;
      }
      final isIncome = summaryType == 'INCOME';
      topWidget = PDetailSourceTx(
        icon: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: softBg(context, fg),
            borderRadius: PRadius.tile(32),
          ),
          alignment: Alignment.center,
          child: Icon(iconData, size: 16, color: fg),
        ),
        title: summaryTitle,
        sub: '${l.recurringStartFrom(_startDay)} · ${l.recurringSourceSub}',
        amount: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '${isIncome ? '+' : '−'}${krw(summaryAmount.abs())}',
                style: PTypo.bodyLg.copyWith(
                  color: t.fgPrimary,
                  fontWeight: PFontWeight.bold,
                ),
              ),
              TextSpan(
                text: wonUnit(),
                style: PTypo.body.copyWith(
                  color: t.fgPrimary,
                  fontWeight: PFontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final nextDates = previewNextDates(
      _baseDate,
      _frequency,
      _dayOfWeekUi,
      _dayOfMonth,
      3,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.setCanSubmit(_ready);
    });

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(PSpace.xl, 0, PSpace.xl, PSpace.x16),
      children: [
        // add: intro ¶ + 입력 필드 / from-tx·edit: 기준 거래 플랫 행(설명은 sub 통합)
        if (_txInput != null) ...[
          if (_isAdd) ...[
            Text(
              l.recurringIntro,
              style: PTypo.bodySm.copyWith(
                color: t.fgSecondary,
                height: PLineHeight.normal,
              ),
            ),
            const SizedBox(height: 14),
          ],
          topWidget,
          const SizedBox(height: 18),
        ] else ...[
          topWidget,
        ],

        _Section(
          title: l.recurringFrequencyLabel,
          child: PTabs<String>(
            value: _frequency,
            variant: PTabsVariant.container,
            size: PTabsSize.sm,
            expand: true,
            items: [
              PTabItem(value: 'DAILY', label: l.calRepeatDaily),
              PTabItem(value: 'WEEKLY', label: l.calRepeatWeekly),
              PTabItem(value: 'MONTHLY', label: l.calRepeatMonthly),
              PTabItem(value: 'YEARLY', label: l.calRepeatYearly),
            ],
            onChanged: (v) => setState(() => _frequency = v),
          ),
        ),

        if (_frequency == 'WEEKLY')
          _Section(
            title: l.recurringDayOfWeekLabel,
            child: _DowGrid(
              value: _dayOfWeekUi,
              onChanged: (v) => setState(() => _dayOfWeekUi = v),
              tokens: t,
            ),
          ),

        if (_frequency == 'MONTHLY')
          _Section(
            title: l.recurringDayOfMonthLabel,
            child: Row(
              children: [
                Text(
                  l.calRepeatMonthly,
                  style: PTypo.bodySm.copyWith(color: t.fgSecondary),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 64,
                  child: PTextInput(
                    numbersOnly: true,
                    textAlign: TextAlign.center,
                    inputFormatters: [LengthLimitingTextInputFormatter(2)],
                    controller:
                        TextEditingController(text: _dayOfMonth.toString())
                          ..selection = TextSelection.collapsed(
                            offset: _dayOfMonth.toString().length,
                          ),
                    onChanged: (v) {
                      final n = int.tryParse(v);
                      if (n == null) return;
                      setState(() => _dayOfMonth = n.clamp(1, 31));
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  l.dayUnit,
                  style: PTypo.bodySm.copyWith(color: t.fgSecondary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.recurringDayNote,
                    style: PTypo.caption.copyWith(color: t.fgTertiary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

        // 실행 시각 — 이 시각으로 실행분이 만들어진다. 예전에는 09:00 고정이었고
        // 서버 컬럼 기본값도 09:00 이라 안 고르면 지금과 같다.
        _Section(
          title: l.recurringExecutionTime,
          child: _TimeField(
            value: _executionTime,
            onChanged: (v) => setState(() => _executionTime = v),
          ),
        ),

        _Section(
          title: l.recurringEndLabel,
          child: Column(
            children: [
              _RadioCard(
                selected: _endMode == _EndMode.none,
                onSelect: () => setState(() => _endMode = _EndMode.none),
                title: l.recurringIndefinite,
                subtitle: l.recurringIndefiniteDesc,
                tokens: t,
              ),
              const SizedBox(height: 8),
              _RadioCard(
                selected: _endMode == _EndMode.count,
                onSelect: () => setState(() => _endMode = _EndMode.count),
                title: l.recurringByCount,
                tokens: t,
                subtitleChild: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l.recurringTotal,
                      style: PTypo.caption.copyWith(color: t.fgSecondary),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 64,
                      child: PTextInput(
                        controller: _endCountCtrl,
                        numbersOnly: true,
                        textAlign: TextAlign.center,
                        inputFormatters: [LengthLimitingTextInputFormatter(3)],
                        onChanged: (_) =>
                            setState(() => _endMode = _EndMode.count),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l.recurringTimesUnit,
                      style: PTypo.caption.copyWith(color: t.fgSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _RadioCard(
                selected: _endMode == _EndMode.date,
                onSelect: () => setState(() => _endMode = _EndMode.date),
                title: l.recurringByDate,
                tokens: t,
                subtitleChild: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: PDateInput(
                    value: _endDate,
                    onChanged: (d) {
                      if (d == null) return;
                      setState(() {
                        _endMode = _EndMode.date;
                        _endDate = d;
                      });
                    },
                    firstDate: _baseDate,
                    lastDate: DateTime(_baseDate.year + 30, 12, 31),
                  ),
                ),
              ),
            ],
          ),
        ),

        _Section(
          title: l.recurringOptions,
          child: Column(
            children: [
              _ToggleRow(
                icon: LucideIcons.zap,
                title: l.recurringAutoLog,
                subtitle: l.recurringAutoLogDesc,
                value: _autoLog,
                onChanged: (v) => setState(() => _autoLog = v),
                tokens: t,
              ),
              const SizedBox(height: 8),
              _ToggleRow(
                icon: LucideIcons.bell,
                title: l.recurringNotifyDayBefore,
                subtitle: l.recurringNotifyDesc,
                value: _notifyDayBefore,
                onChanged: (v) => setState(() => _notifyDayBefore = v),
                tokens: t,
              ),
              if (_kind != 'TRANSFER') ...[
                const SizedBox(height: 8),
                _ToggleRow(
                  icon: LucideIcons.pin,
                  title: _kind == 'INCOME'
                      ? l.fixedSwitchIncome
                      : l.fixedSwitchExpense,
                  subtitle: l.recurringFixedSub,
                  value: _isFixed,
                  onChanged: (v) => setState(() => _isFixed = v),
                  tokens: t,
                ),
              ],
            ],
          ),
        ),

        // 다음 예정일 — 플랫 섹션 (border-top + 필 칩)
        if (nextDates.isNotEmpty)
          PDetailSection(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.calendar, size: 13, color: t.fgPrimary),
                const SizedBox(width: 5),
                Text(l.recurringNextDates),
              ],
            ),
            child: Wrap(
              spacing: PSpace.x8,
              runSpacing: PSpace.x8,
              children: [
                for (final d in nextDates)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: t.bgSunken,
                      borderRadius: PRadius.brFull,
                    ),
                    child: Text(
                      localeIsEn()
                          ? formatDay(d).md
                          : '${d.month.toString().padLeft(2, '0')}월 ${d.day.toString().padLeft(2, '0')}일',
                      style: PTypo.caption.copyWith(
                        color: t.fgPrimary,
                        fontWeight: PFontWeight.semi,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── widgets ────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: PTypo.caption.copyWith(
              color: t.fgSecondary,
              fontWeight: PFontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _DowGrid extends StatelessWidget {
  const _DowGrid({
    required this.value,
    required this.onChanged,
    required this.tokens,
  });
  final int value; // 0=일 ~ 6=토
  final ValueChanged<int> onChanged;
  final GrooTokens tokens;

  @override
  Widget build(BuildContext context) {
    final labels = weekdayLabels();
    return Row(
      children: [
        for (int i = 0; i < 7; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: i == value ? tokens.bgBrandSubtle : tokens.bgSunken,
                  borderRadius: PRadius.brFull,
                ),
                child: Text(
                  labels[i],
                  style: PTypo.bodySm.copyWith(
                    color: i == value
                        ? tokens.fgBrandStrong
                        : tokens.fgSecondary,
                    fontWeight: i == value
                        ? PFontWeight.bold
                        : PFontWeight.semi,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _RadioCard extends StatelessWidget {
  const _RadioCard({
    required this.selected,
    required this.onSelect,
    required this.title,
    required this.tokens,
    this.subtitle,
    this.subtitleChild,
  });
  final bool selected;
  final VoidCallback onSelect;
  final String title;
  final String? subtitle;
  final Widget? subtitleChild;
  final GrooTokens tokens;

  @override
  Widget build(BuildContext context) {
    // design RadioRow — 플랫(카드 박스 없음), 선택 시 제목만 강조.
    return InkWell(
      onTap: onSelect,
      borderRadius: PRadius.brMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 17,
              height: 17,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? tokens.borderBrand : Colors.transparent,
                border: Border.all(
                  color: selected ? tokens.borderBrand : tokens.borderDefault,
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: tokens.bgSurface,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: PTypo.body.copyWith(
                      color: selected ? tokens.fgPrimary : tokens.fgSecondary,
                      fontWeight: PFontWeight.semi,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: PTypo.caption.copyWith(color: tokens.fgTertiary),
                    ),
                  ],
                  if (subtitleChild != null) ...[
                    const SizedBox(height: 2),
                    subtitleChild!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.tokens,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final GrooTokens tokens;

  @override
  Widget build(BuildContext context) {
    // design ToggleRow — 플랫(카드 박스 없음), 아이콘 36 원형 sunken, 행 탭 토글.
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: PRadius.brMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: tokens.bgSunken,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 15, color: tokens.fgSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: PTypo.body.copyWith(
                      color: tokens.fgPrimary,
                      fontWeight: PFontWeight.semi,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: PTypo.caption.copyWith(color: tokens.fgTertiary),
                  ),
                ],
              ),
            ),
            PSwitch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

// ─── helpers ────────────────────────────────────────────────────────────────

/// 다음 예정일 미리보기 — 서버 회차 규칙(`recurring_schedule.dart`: `adjustToFrequency` · `firstOccurrenceOnOrAfter` ·
/// `calculateNextDate`)과 같은 셈이다. 시작일이 매월 날보다 뒤면 다음 달부터, 매주는 그 요일까지 앞으로, 매월 29 ~ 31 은 말일로
/// 줄인다(I-20 D 29). UI dow 0=일 ~ 6=토. 거래에서 만들기(`expense:`)의 안내 날짜가 이 함수를 쓴다.
List<DateTime> previewNextDates(
  DateTime start,
  String frequency,
  int dayOfWeekUi, // 0=일 ~ 6=토
  int dayOfMonth,
  int count,
) => [
  for (final k in previewNextDateKeys(
    dayKey(start),
    frequency,
    dayOfWeekUi,
    dayOfMonth,
    count,
  ))
    ?parseDayKey(k),
];

// ─────────────────────────────────────────────
// 거래 입력 (inline) — add_tx_sheet 와 독립. 지출/수입만, 시간 없음, 날짜 = 반복 시작일.
// (웹 RecurringAddDialog 와 동일 구조 — 공용 TxInputForm 분리 대신 각 호스트 자체 보유)

const _txPaymentMethodValues = ['CASH', 'CARD', 'TRANSFER', 'OTHER'];

String _txPayLabel(AppLocalizations l, String v) => switch (v) {
  'CASH' => l.expPayCash,
  'CARD' => l.expPayCard,
  'TRANSFER' => l.expPayTransfer,
  _ => l.expPayOther,
};

const Map<String, List<String>?> _txPaymentAssetTypes = {
  'CASH': ['CASH'],
  'CARD': ['CREDIT_CARD', 'CHECK_CARD'],
  'TRANSFER': ['BANK_ACCOUNT', 'SAVINGS'],
  'OTHER': null,
};

/// 결제 수단 + 거래 타입으로 계좌·카드 후보를 고른다.
///
/// 지출에선 예·적금(SAVINGS: 청약·정기예금·정기적금)을 뺀다 — 만기 전까지 묶인 돈이라
/// 거기서 직접 결제나 출금이 나가지 않는다(납입·해지는 이체로 처리).
/// 수입은 이자가 그 계좌로 직접 들어오므로 남긴다.
bool _allowTxAsset(Asset a, String paymentMethod, String type) {
  final allowed = paymentMethod.isNotEmpty
      ? _txPaymentAssetTypes[paymentMethod]
      : null;
  if (allowed != null && !allowed.contains(a.assetType)) return false;
  if (type == 'EXPENSE' && a.assetType == 'SAVINGS') return false;
  return true;
}

/// 반복 추가 전용 거래 입력 상태 (지출/수입/이체). 시간 없음.
class _TxInputController {
  _TxInputController({
    DateTime? date,
    this.type = 'EXPENSE',
    int? amount,
    String? merchant,
    String? memo,
    this.categoryRowId,
    this.assetRowId,
    this.toAssetRowId,
    int? fee,
    int? interestAmount,
    this.paymentMethod = '',
  }) : date = date ?? DateTime.now(),
       amountCtrl = TextEditingController(
         text: amount == null || amount == 0 ? '' : amount.toString(),
       ),
       merchantCtrl = TextEditingController(text: merchant ?? ''),
       memoCtrl = TextEditingController(text: memo ?? ''),
       feeCtrl = TextEditingController(
         text: fee == null || fee == 0 ? '' : fee.toString(),
       ),
       interestCtrl = TextEditingController(
         text: interestAmount == null || interestAmount == 0
             ? ''
             : interestAmount.toString(),
       );

  final TextEditingController amountCtrl;
  final TextEditingController merchantCtrl;
  final TextEditingController memoCtrl;
  final TextEditingController feeCtrl;
  final TextEditingController interestCtrl;

  String type; // EXPENSE / INCOME / TRANSFER
  int? categoryRowId;

  /// 이체면 **보내는** 자산 — 서버도 같은 컬럼을 쓴다.
  int? assetRowId;

  /// 이체면 **받는** 자산.
  int? toAssetRowId;
  String paymentMethod;
  DateTime date;

  bool get isTransfer => type == 'TRANSFER';
  int? get feeOrNull {
    final v = int.tryParse(feeCtrl.text.replaceAll(',', '')) ?? 0;
    return v > 0 ? v : null;
  }

  int? get interestOrNull {
    final v = int.tryParse(interestCtrl.text.replaceAll(',', '')) ?? 0;
    return v > 0 ? v : null;
  }

  int get amountInt => int.tryParse(amountCtrl.text.replaceAll(',', '')) ?? 0;
  String get isoDate =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  String? get merchantOrNull =>
      merchantCtrl.text.trim().isEmpty ? null : merchantCtrl.text.trim();
  String? get memoOrNull =>
      memoCtrl.text.trim().isEmpty ? null : memoCtrl.text.trim();
  String? get paymentMethodOrNull =>
      paymentMethod.isEmpty ? null : paymentMethod;

  void dispose() {
    amountCtrl.dispose();
    merchantCtrl.dispose();
    memoCtrl.dispose();
    feeCtrl.dispose();
    interestCtrl.dispose();
  }
}

/// 반복 추가 거래 입력 폼 (inline). 타입(지출/수입) · 금액 · 카테고리 · 거래처 ·
/// 결제 수단 · 계좌 · 반복 시작일 · 메모.
class _TxFields extends ConsumerWidget {
  const _TxFields({required this.controller, required this.onChanged});

  final _TxInputController controller;
  final VoidCallback onChanged;

  void _set(VoidCallback mutate) {
    mutate();
    onChanged();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final c = controller;
    final categoriesAsync = ref.watch(categoriesProvider);
    final assetsAsync = ref.watch(assetsProvider);

    final amountInt = c.amountInt;
    // 이체는 지출도 수입도 아니다 — 가계부의 이체 행과 같이 중립색·무부호.
    final amountColor = c.isTransfer
        ? t.fgPrimary
        : (c.type == 'EXPENSE' ? t.fgExpense : t.fgIncome);
    final amountPrefix = c.isTransfer ? '' : (c.type == 'EXPENSE' ? '−' : '+');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 타입 (지출/수입)
        PTabs<String>(
          variant: PTabsVariant.container,
          size: PTabsSize.sm,
          expand: true,
          value: c.type,
          onChanged: (v) => _set(() => c.type = v),
          items: [
            PTabItem(value: 'EXPENSE', label: l.expTypeExpense),
            PTabItem(value: 'INCOME', label: l.expTypeIncome),
            PTabItem(value: 'TRANSFER', label: l.expTypeTransfer),
          ],
        ),
        const SizedBox(height: PSpace.x12),

        // 금액
        PSectionLabel(l.expAmount),
        const SizedBox(height: PSpace.x4),
        PTextInput(
          controller: c.amountCtrl,
          numbersOnly: true,
          amountMax: kAmountMax,
          placeholder: '0',
          prefixText: amountInt > 0 ? amountPrefix : null,
          suffixText: wonUnit(),
          style: PTypo.h4.copyWith(
            color: amountColor,
            fontWeight: PFontWeight.bold,
          ),
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: PSpace.x16),

        if (c.isTransfer) ...[
          // 이체 — 규칙과 화면 모두 거래 시트·프리셋 폼과 한 벌이다.
          TransferAccountFields(
            assets: assetsAsync,
            fromAssetRowId: c.assetRowId,
            toAssetRowId: c.toAssetRowId,
            feeController: c.feeCtrl,
            interestController: c.interestCtrl,
            amountForHint: amountInt,
            onFromChanged: (v) => _set(() => c.assetRowId = v),
            onToChanged: (v) => _set(() => c.toAssetRowId = v),
            onInterestChanged: () => _set(() {}),
            labelBuilder: (text) => PSectionLabel(text),
          ),
        ] else ...[
          // 카테고리
          PSectionLabel(l.expCategory, variant: PSectionLabelVariant.eyebrow),
          const SizedBox(height: PSpace.x8),
          categoriesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: PCircularProgressIndicator()),
            ),
            error: (e, _) => Text(
              '${l.categoryLoadError}: $e',
              style: PTypo.caption.copyWith(color: t.statusDangerFg),
            ),
            data: (categories) {
              final topCategories =
                  categories
                      .where(
                        (cat) =>
                            cat.expenseType == c.type &&
                            (cat.parentRowId == null || cat.parentRowId == 0),
                      )
                      .toList()
                    ..sort(
                      (a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0),
                    );
              if (topCategories.isEmpty) {
                return Text(
                  l.expNoCategoryForType,
                  style: PTypo.caption.copyWith(color: t.fgTertiary),
                );
              }

              final childrenByParent = <int, List<dynamic>>{};
              for (final cat in categories) {
                if (cat.parentRowId == null ||
                    cat.parentRowId == 0 ||
                    cat.expenseType != c.type) {
                  continue;
                }
                childrenByParent
                    .putIfAbsent(cat.parentRowId!, () => [])
                    .add(cat);
              }
              for (final list in childrenByParent.values) {
                list.sort(
                  (a, b) => ((a.sortOrder ?? 0) as int).compareTo(
                    (b.sortOrder ?? 0) as int,
                  ),
                );
              }

              final selectedCat = c.categoryRowId == null
                  ? null
                  : categories
                        .where((cat) => cat.rowId == c.categoryRowId)
                        .firstOrNull;
              final selectedParentId = selectedCat == null
                  ? null
                  : (selectedCat.parentRowId == null ||
                            selectedCat.parentRowId == 0
                        ? selectedCat.rowId
                        : selectedCat.parentRowId);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const gap = 6.0;
                      const columns = 5;
                      final cellWidth =
                          (constraints.maxWidth - gap * (columns - 1)) /
                          columns;
                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          for (final cat in topCategories)
                            SizedBox(
                              width: cellWidth,
                              child: PCategoryTile(
                                name: cat.categoryName,
                                color: resolveChartColor(
                                  context,
                                  cat.color,
                                  fallback: t.fgBrand,
                                ),
                                icon: lucideByName(cat.icon ?? 'tag'),
                                active: selectedParentId == cat.rowId,
                                onTap: () => _set(() {
                                  final firstChild =
                                      childrenByParent[cat.rowId]?.first;
                                  c.categoryRowId = firstChild != null
                                      ? firstChild.rowId
                                      : cat.rowId;
                                }),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  if (selectedParentId != null &&
                      (childrenByParent[selectedParentId]?.isNotEmpty ??
                          false)) ...[
                    const SizedBox(height: 10),
                    _SelectField<int>(
                      value: c.categoryRowId,
                      hint: l.expSubcategory,
                      // 상위 자신은 고를 수 없다 — 하위가 있는 상위는 반복 거래를 안 받는다
                      // (EXPENSE_CATEGORY_NOT_LEAF). 거래 추가와 같다(QA 30 13).
                      items: [
                        for (final child in childrenByParent[selectedParentId]!)
                          _SelectOption<int>(
                            child.rowId as int,
                            child.categoryName as String,
                          ),
                      ],
                      onChanged: (v) => _set(() => c.categoryRowId = v),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: PSpace.x12),
          // 거래처
          PSectionLabel(
            c.type == 'INCOME' ? l.expIncomeSource : l.recurringMerchant,
          ),
          const SizedBox(height: PSpace.x4),
          PTextInput(
            controller: c.merchantCtrl,
            placeholder: c.type == 'INCOME'
                ? l.expIncomeSourcePlaceholder
                : l.recurringMerchantPlaceholder,
          ),
          const SizedBox(height: PSpace.x12),

          // 결제 수단
          PSectionLabel(
            c.type == 'INCOME' ? l.expIncomeMethod : l.expPaymentMethod,
          ),
          const SizedBox(height: PSpace.x4),
          _SelectField<String>(
            value: c.paymentMethod.isEmpty ? null : c.paymentMethod,
            hint: l.recurringSelectNone,
            items: [
              _SelectOption<String>('', l.recurringSelectNone),
              for (final pm in _txPaymentMethodValues)
                _SelectOption<String>(pm, _txPayLabel(l, pm)),
            ],
            onChanged: (v) => _set(() {
              c.paymentMethod = v ?? '';
              if (c.assetRowId != null) {
                final assets = assetsAsync.value ?? const [];
                final cur = assets
                    .where((a) => a.rowId == c.assetRowId)
                    .firstOrNull;
                if (cur != null &&
                    !_allowTxAsset(cur, c.paymentMethod, c.type)) {
                  c.assetRowId = null;
                }
              }
            }),
          ),
          const SizedBox(height: PSpace.x12),

          // 계좌·카드
          PSectionLabel(
            c.type == 'INCOME' ? l.expDepositAccount : l.recurringAssetCard,
          ),
          const SizedBox(height: PSpace.x4),
          assetsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: PCircularProgressIndicator()),
            ),
            error: (e, _) => Text(
              '${l.recurringAssetLoadError}: $e',
              style: PTypo.caption.copyWith(color: t.statusDangerFg),
            ),
            data: (assets) {
              final filtered = assets
                  .where((a) => _allowTxAsset(a, c.paymentMethod, c.type))
                  .toList();
              return _SelectField<int>(
                value: c.assetRowId,
                hint: l.recurringSelectNone,
                items: [
                  _SelectOption<int>(-1, l.recurringSelectNone),
                  for (final a in filtered)
                    _SelectOption<int>(
                      a.rowId,
                      a.institution != null
                          ? '${a.institution} · ${a.assetName}'
                          : a.assetName,
                    ),
                ],
                onChanged: (v) => _set(() => c.assetRowId = v == -1 ? null : v),
              );
            },
          ),
          const SizedBox(height: PSpace.x12),
        ],

        // 반복 시작일 (날짜만 — 웹 정합)
        PSectionLabel(l.recurringStartDateLabel),
        const SizedBox(height: PSpace.x4),
        PDateInput(
          value: c.date,
          onChanged: (d) {
            if (d != null) _set(() => c.date = d);
          },
          firstDate: DateTime(2020),
          lastDate: DateTime(2030, 12, 31),
        ),
        const SizedBox(height: PSpace.x16),

        // 메모
        PSectionLabel(l.navMemo),
        const SizedBox(height: PSpace.x4),
        PTextInput(
          controller: c.memoCtrl,
          maxLines: 2,
          placeholder: l.expMemoPlaceholder,
        ),
      ],
    );
  }
}

class _SelectOption<T> {
  const _SelectOption(this.value, this.label);
  final T value;
  final String label;
}

class _SelectField<T> extends StatelessWidget {
  const _SelectField({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.hint,
  });
  final T? value;
  final List<_SelectOption<T>> items;
  final ValueChanged<T?> onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return PSelect<T>(
      value: items.any((i) => i.value == value) ? value : null,
      placeholder: hint,
      onChanged: onChanged,
      items: [
        for (final opt in items)
          PSelectItem<T>(value: opt.value, label: opt.label),
      ],
    );
  }
}

/// 'HH:mm' 시간 필드 — 타이핑으로도, 시계 아이콘으로도 고친다.
class _TimeField extends StatelessWidget {
  const _TimeField({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  TimeOfDay _parse(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
    return TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
  }

  String _fmt(TimeOfDay tod) =>
      '${tod.hour.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) => PTimeInput(
    value: _parse(value),
    onChanged: (t) {
      if (t != null) onChanged(_fmt(t));
    },
  );
}
