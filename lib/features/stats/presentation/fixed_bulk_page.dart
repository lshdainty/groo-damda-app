import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/core/sync/keep_alive_refresh.dart';
import 'package:groo_damda_app/features/budget/presentation/budget_parts.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/fixed_groups.dart';
import 'package:groo_damda_app/features/expense/presentation/closed_cycle_notice.dart'
    show hostContextOf;
import 'package:groo_damda_app/features/stats/application/stats_providers.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import 'package:groo_damda_app/shared/forms/form_error_callout.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/segmented_control/p_segmented_control.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';
import 'package:groo_damda_app/shared/scroll/reveal_below_fog.dart';
import 'package:groo_damda_app/shared/ds/skeleton/loading_region.dart';

/// 거래를 고정으로 정리하는 페이지(I-08 Q5-A) — 기간 안 거래 묶음이 처음부터 길어 시트가 아니라 페이지다.
/// 위 상단 바(← + 제목), 가운데 스크롤(설명 · 종류 · 방향 · 묶음 줄), 아래 바닥 [N건 적용] 하나. 앞 화면은 그대로 아래에 남는다.
///
/// 같은 이름으로 나가는 거래를 한 줄로 묶어 한 번에 고른다 — 돈 · 잔액은 안 움직이고 통계의 분류만 바뀐다.
/// 되돌리기는 같은 페이지에서 "변동으로 되돌리기" 를 고르면 된다.
Future<void> openFixedBulkPage(BuildContext context, DateRange range) =>
    Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(builder: (_) => FixedBulkPage(range: range)),
    );

class FixedBulkPage extends ConsumerStatefulWidget {
  const FixedBulkPage({super.key, required this.range});

  final DateRange range;

  @override
  ConsumerState<FixedBulkPage> createState() => _FixedBulkPageState();
}

class _FixedBulkPageState extends ConsumerState<FixedBulkPage> {
  String _type = 'EXPENSE';
  bool _toFixed = true;
  Set<int> _picked = {};
  bool _submitting = false;
  bool _failed = false;
  final _errorKey = GlobalKey();

  Future<void> _apply() async {
    if (_picked.isEmpty || _submitting) return;
    // 페이지가 닫힌 뒤에도 토스트를 띄워야 하므로 await 전에 오래 사는 것을 쥔다.
    final l = AppLocalizations.of(context);
    final host = hostContextOf(context);
    final nav = Navigator.of(context);
    setState(() {
      _failed = false;
      _submitting = true;
    });
    final container = ProviderScope.containerOf(context, listen: false);
    try {
      final repo = await container.read(expenseRepositoryProvider.future);
      final updated = await repo.bulkMarkFixed(
        _picked.toList(),
        isFixed: _toFixed,
        silent: true,
      );
      // 합계가 아니라 분류가 바뀌지만 통계(고정/변동)·목록이 모두 달라진다.
      invalidateAfterExpenseChangeIn(container);
      container.invalidate(rangeSummaryProvider(widget.range));
      container.invalidate(monthlyTrendProvider(6));
      if (!mounted) return;
      nav.pop();
      if (!host.mounted) return;
      // 저장 · 바꿈은 neutral(D1) — 호스트가 없는 자리(시험)는 조용히 건너뛴다.
      PSnackbar.maybeOf(host)?.show(
        message: _toFixed
            ? l.statsFixedBulkDoneFixed(updated)
            : l.statsFixedBulkDoneVariable(updated),
      );
    } on ApiException {
      // 요청은 silent 라 서버 글이 안 뜬다 — 페이지는 그대로 두고 폼 맨 위 Callout 한 문장(우리 글)이 말한다.
      // 다시 시도는 [적용] 이 한다(웹 useFixedBulk 와 같다).
      if (!mounted) return;
      setState(() => _failed = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _errorKey.currentContext;
        if (ctx != null && ctx.mounted) revealBelowFog(ctx);
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final expensesAsync = ref.watch(rangeExpensesProvider(widget.range));
    final masked = ref.watch(hideCardProvider('stats.fixed'));
    final expenses = expensesAsync.value;
    final groups = groupForFixed(
      expenses ?? const [],
      _type,
      l.statsFixedBulkUntitled,
    );

    Widget body;
    if (expenses == null && expensesAsync.hasError) {
      // 실패는 빈 목록이 아니다 — 불러오지 못했다고 말하고 다시 시도
      body = Padding(
        padding: const EdgeInsets.symmetric(horizontal: PSpacing.x6),
        child: BudgetFailure(
          title: l.statsFixedBulkLoadFailed,
          retrying: expensesAsync.isLoading,
          onRetry: () => ref.invalidate(rangeExpensesProvider(widget.range)),
        ),
      );
    } else if (expenses == null) {
      body = loadingRegion(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: PSpacing.x6),
          child: Column(
            spacing: PSpacing.x2,
            children: [
              for (var i = 0; i < 4; i++)
                const PSkeleton(
                  width: double.infinity,
                  height: 52,
                  radius: PSkeletonRadius.r12,
                ),
            ],
          ),
        ),
      );
    } else if (groups.isEmpty) {
      body = BudgetEmptyLine(l.statsFixedBulkEmpty);
    } else {
      body = PListCheckGroup(
        semanticLabel: l.statsFixedBulkTitle,
        children: [
          for (final g in groups)
            () {
              final allFixed = g.fixedCount == g.count;
              final someFixed = g.fixedCount > 0 && !allFixed;
              final badge = allFixed
                  ? l.statsFixedBulkBadgeAll
                  : someFixed
                  ? l.statsFixedBulkBadgeSome(g.fixedCount, g.count)
                  : null;
              return PListCheckItem(
                title: g.name,
                detailChild: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text:
                            '${l.statsFixedBulkGroupSub(g.count)} · ${budgetWon(g.total, masked)}',
                      ),
                      if (badge != null)
                        TextSpan(
                          text: ' · $badge',
                          style: TextStyle(
                            color: c.fgBrand,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                  style: TextStyle(
                    color: c.fgNeutralSubtle,
                    fontFeatures: tabularFigures,
                  ),
                ),
                checked: groupCheck(g, _picked),
                onChanged: (on) =>
                    setState(() => _picked = toggleGroup(g, _picked, on)),
              );
            }(),
        ],
      );
    }

    return Scaffold(
      backgroundColor: c.bgLayerDefault,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(PTopNavigation.heightOf(context)),
        child: PTopNavigation(
          title: l.statsFixedBulkTitle,
          leading: PTopNavigationIconButton.back(
            label: l.actionBack,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: PSpacing.x4),
        children: [
          if (_failed)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PSpacing.x6,
                PSpacing.x2,
                PSpacing.x6,
                0,
              ),
              child: FormErrorCallout(
                key: _errorKey,
                message: l.statsFixedBulkFailed,
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PSpacing.x6,
              PSpacing.x2,
              PSpacing.x6,
              0,
            ),
            child: Text(
              keepAll(l.statsFixedBulkDesc(_rangeText(widget.range))),
              style: PTypography.t3.copyWith(color: c.fgNeutralMuted),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PSpacing.x6,
              PSpacing.x4,
              PSpacing.x6,
              PSpacing.x3,
            ),
            child: Column(
              spacing: PSpacing.x2_5,
              children: [
                PSegmentedControl<String>(
                  value: _type,
                  semanticLabel: l.statsFixedTrendKindAria,
                  onChanged: (v) => setState(() {
                    _type = v;
                    _picked = {};
                  }),
                  items: [
                    PSegmentedItem(
                      value: 'EXPENSE',
                      label: l.statsFixedKindExpense,
                    ),
                    PSegmentedItem(
                      value: 'INCOME',
                      label: l.statsFixedKindIncome,
                    ),
                  ],
                ),
                PSegmentedControl<bool>(
                  value: _toFixed,
                  semanticLabel: l.statsFixedBulkTargetAria,
                  onChanged: (v) => setState(() => _toFixed = v),
                  items: [
                    PSegmentedItem(value: true, label: l.statsFixedBulkToFixed),
                    PSegmentedItem(
                      value: false,
                      label: l.statsFixedBulkToVariable,
                    ),
                  ],
                ),
              ],
            ),
          ),
          body,
        ],
      ),
      // 바닥 버튼 하나 — 안전 영역 위에
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            PSpacing.x6,
            PSpacing.x3,
            PSpacing.x6,
            PSpacing.x4,
          ),
          child: SizedBox(
            width: double.infinity,
            child: PButton(
              label: l.statsFixedBulkApply(_picked.length),
              size: PButtonSize.large,
              loading: _submitting,
              onPressed: _picked.isEmpty ? null : _apply,
            ),
          ),
        ),
      ),
    );
  }
}

/// 설명 줄의 기간 — 날짜 규칙 + 구간 기호는 붙여 로케일 문구(ko "10월 1일~10월 31일" · en "Oct 1–31"). 못 읽으면 서버 값 그대로.
String _rangeText(DateRange r) {
  final a = DateTime.tryParse(r.startDate);
  final b = DateTime.tryParse(r.endDate);
  if (a == null || b == null) {
    return '${r.startDate}${rangeSeparator()}${r.endDate}';
  }
  return dateRange(a, b);
}
