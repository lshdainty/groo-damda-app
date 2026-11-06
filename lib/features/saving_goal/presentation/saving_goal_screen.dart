import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/chart_palette.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/features/budget/presentation/budget_parts.dart';
import 'package:groo_damda_app/features/saving_goal/application/saving_goal_providers.dart';
import 'package:groo_damda_app/features/saving_goal/domain/saving_goal.dart';
import 'package:groo_damda_app/features/saving_goal/presentation/saving_goal_edit_dialog.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/badge/p_badge.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/ds/progress/p_progress.dart';
import 'package:groo_damda_app/shared/ds/pull_to_refresh/p_pull_to_refresh.dart';
import 'package:groo_damda_app/shared/ds/screen_band/p_screen_band.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/ds/text_button/p_text_button.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';
import 'package:groo_damda_app/shared/icons/lucide_icon_map.dart';
import 'package:groo_damda_app/shared/widgets/p_swipe_actions.dart';

/// 저축 목표 관리 (설정 > 저축 목표) — design GoalManager 미러 (웹 SavingGoalManager 정합).
///
/// 전체 진행률 구역 + 목표 목록(줄 탭 = 편집)이 한 흰 면이다 — 카드 · 줄 사이 선 없음(I-08 24). 자산 화면은 조회 전용.
class SavingGoalScreen extends ConsumerWidget {
  const SavingGoalScreen({super.key});

  /// 스와이프 삭제 — ds 확인창(Alert Dialog)으로 묻고(삭제는 criticalSolid), 확정하면 지운다.
  /// 실패하면 확인창을 닫고 스낵바(critical + 다시 시도)로 알린다 — 다시 시도는 묻지 않고 바로 지운다 —
  /// 이미 확인창에서 한 번 확정한 삭제이고, 띠는 앱 뿌리 호스트에 있어 화면을 나가도 남는다(그때 [context] · [ref] 는
  /// 죽었으므로 미리 잡아 둔 [ProviderContainer] 로 돈다).
  Future<void> _confirmDeleteGoal(
    BuildContext context,
    WidgetRef ref,
    SavingGoal goal,
  ) async {
    final l = AppLocalizations.of(context);
    final container = ProviderScope.containerOf(context);
    final snack = PSnackbar.of(context);
    Object? failure;
    final ok = await PAlertDialog.show(
      context,
      title: l.savingGoalDeleteTitle(goal.title),
      description: l.savingGoalDeleteConfirm,
      cancelLabel: l.actionCancel,
      actionLabel: l.actionDelete,
      destructive: true,
      onAction: () async {
        try {
          await _deleteGoal(container, goal);
        } catch (e) {
          failure = e;
        }
      },
    );
    if (ok && failure != null) {
      snack.show(
        message: l.savingGoalDeleteFailed,
        tone: PSnackbarTone.critical,
        action: PSnackbarAction(
          label: l.actionRetry,
          onPressed: () => _deleteDetached(container, l, snack, goal),
        ),
      );
    }
  }

  /// 삭제 "다시 시도" — 묻지 않고 지우고, 또 실패하면 같은 띠를 다시 띄운다.
  Future<void> _deleteDetached(
    ProviderContainer container,
    AppLocalizations l,
    PSnackbarApi snack,
    SavingGoal goal,
  ) async {
    try {
      await _deleteGoal(container, goal);
    } catch (_) {
      snack.show(
        message: l.savingGoalDeleteFailed,
        tone: PSnackbarTone.critical,
        action: PSnackbarAction(
          label: l.actionRetry,
          onPressed: () => _deleteDetached(container, l, snack, goal),
        ),
      );
    }
  }

  /// 수정 시트의 삭제와 같은 저장소·무효화 경로를 쓴다. 실패하면 던진다.
  /// 실패는 호출한 쪽 스낵바가 알리므로 전역 오류 토스트는 끈다(둘이 같은 아래쪽에서 겹친다).
  Future<void> _deleteGoal(ProviderContainer container, SavingGoal goal) async {
    final repo = await container.read(savingGoalRepositoryProvider.future);
    await repo.delete(goal.rowId, silent: true);
    container.invalidate(savingGoalListProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final listAsync = ref.watch(savingGoalListProvider);
    final masked = ref.watch(hideCardProvider('asset.savingGoals'));

    Widget content;
    final items = listAsync.value;
    if (items == null) {
      content = listAsync.hasError
          ? BudgetSection(
              children: [
                BudgetFailure(
                  title: l.savingGoalFailTitle,
                  retrying: listAsync.isLoading,
                  onRetry: () => ref.invalidate(savingGoalListProvider),
                ),
              ],
            )
          : const _SavingGoalSkeleton();
    } else {
      final totalTarget = items.fold<int>(0, (s, g) => s + g.targetAmount);
      final totalCurrent = items.fold<int>(0, (s, g) => s + g.currentAmount);
      final totalPct = totalTarget > 0
          ? (totalCurrent / totalTarget * 100)
          : 0.0;
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 전체 진행률 — 띠 안 위 4 + 16 에서 라벨, 아래 24
          if (items.isNotEmpty)
            BudgetSection(
              topPadding: PSpacing.x5,
              children: [
                Text(
                  keepAll(l.savingGoalOverallProgress),
                  style: PTypography.t3.copyWith(
                    color: c.fgNeutralSubtle,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const BudgetFull(child: SizedBox(height: PSpacing.x1)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: BudgetBigAmount(
                        amount: budgetWon(totalCurrent, masked),
                        limit: budgetWon(totalTarget, masked),
                      ),
                    ),
                    const SizedBox(width: PSpacing.x2),
                    Text(
                      '${totalPct.toStringAsFixed(0)}%',
                      style: PTypography.t9.copyWith(
                        color: c.fgBrand,
                        fontWeight: FontWeight.w700,
                        fontFeatures: tabularFigures,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          // 목록 제목 위: 앞 구역 아래 24 + 8 + 제목 위 8 = 보이는 40
          const SizedBox(height: PSpacing.x2),
          PListHeader(
            title: l.savingGoalListCount(items.length),
            variant: PListHeaderVariant.boldSolid,
            action: PTextButton(
              label: l.savingGoalAddAction,
              onPressed: () => showSavingGoalEditDialog(context),
            ),
          ),
          if (items.isEmpty)
            BudgetEmptyLine(l.savingGoalEmpty)
          else
            PList(
              children: [
                for (final goal in items)
                  // 밀면 수정·삭제가 바로 나온다. 탭은 그대로 수정으로 —
                  // 스와이프는 지름길이지 유일한 경로가 아니다
                  // (spec swipe-actions.md · WCAG 2.1.1).
                  PSwipeActions(
                    key: ValueKey('saving-goal-${goal.rowId}'),
                    groupTag: 'saving-goal-list',
                    actions: [
                      PSwipeAction(
                        label: l.actionEdit,
                        icon: LucideIcons.pencil,
                        kind: PSwipeKind.primary,
                        onSelect: () =>
                            showSavingGoalEditDialog(context, edit: goal),
                      ),
                      PSwipeAction(
                        label: l.actionDelete,
                        icon: LucideIcons.trash2,
                        kind: PSwipeKind.destructive,
                        // 확인은 ds 확인창이 받는다(같은 삭제는 어디서 불러도 같은 글).
                        onSelect: () => _confirmDeleteGoal(context, ref, goal),
                      ),
                    ],
                    child: _GoalRow(
                      goal: goal,
                      masked: masked,
                      onEdit: () =>
                          showSavingGoalEditDialog(context, edit: goal),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: PSpacing.x3),
        ],
      );
    }

    return Scaffold(
      backgroundColor: c.bgLayerBasement,
      // 머리 = ds 상단 바(← + 제목) — 높이 56, 스크롤해도 선이 없다(I-16 14)
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(PTopNavigation.heightOf(context)),
        child: PTopNavigation(
          title: l.navSavingGoals,
          leading: PTopNavigationIconButton.back(
            label: l.actionBack,
            onPressed: () => context.pop(),
          ),
        ),
      ),
      body: PScreenBandBody(
        child: PPullToRefresh(
          onRefresh: () async {
            ref.invalidate(savingGoalListProvider);
            await ref.read(savingGoalListProvider.future);
          },
          child: ListView(padding: EdgeInsets.zero, children: [content]),
        ),
      ),
    );
  }
}

/// 저축 목표 skeleton — 실제 구역과 같은 틀(전체 진행률 + 목록 제목 + 줄 3).
class _SavingGoalSkeleton extends StatelessWidget {
  const _SavingGoalSkeleton();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BudgetSection(
          topPadding: PSpacing.x5,
          children: [
            PSkeleton.text(PTypography.t3, width: 80),
            const BudgetFull(child: SizedBox(height: PSpacing.x1)),
            PSkeleton.text(PTypography.t9, width: 200),
          ],
        ),
        const SizedBox(height: PSpacing.x2),
        // 목록 제목의 동작은 정적 UI 라 로딩에도 진짜를 쓴다.
        PListHeader(
          title: l.savingGoalListCount(0),
          variant: PListHeaderVariant.boldSolid,
          action: PTextButton(
            label: l.savingGoalAddAction,
            onPressed: () => showSavingGoalEditDialog(context),
          ),
        ),
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PSpacing.x6,
              vertical: PSpacing.x3,
            ),
            child: Column(
              spacing: PSpacing.x3,
              children: [
                Row(
                  spacing: PSpacing.x3,
                  children: [
                    const PSkeleton(
                      width: 40,
                      height: 40,
                      radius: PSkeletonRadius.r12,
                    ),
                    Expanded(child: PSkeleton.text(PTypography.t5)),
                  ],
                ),
                const PSkeleton(
                  height: PProgressBar.height,
                  radius: PSkeletonRadius.full,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// 목표 줄 — 누르면 수정. 앞 타일 40(목표 색 옅은 바탕) · 제목(줄바꿈) + 달성 배지 · 기한, 아래 한 줄 + 막대(fg-brand 한 색).
class _GoalRow extends StatelessWidget {
  const _GoalRow({
    required this.goal,
    required this.masked,
    required this.onEdit,
  });
  final SavingGoal goal;
  final bool masked;
  final VoidCallback onEdit;

  String? _deadlineLabel() {
    final raw = goal.deadlineDate;
    if (raw == null || raw.isEmpty) return null;
    final d = DateTime.tryParse(raw);
    if (d == null) return null;
    return '${d.year}.${d.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    // 목표 색은 타일에만 남는다 — 막대 · % 는 fg-brand 한 색
    final color = resolveChartColor(context, goal.color, fallback: c.fgBrand);
    final pct = (goal.progress * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PListButtonItem(
          title: goal.title,
          detail: _deadlineLabel() ?? l.savingGoalNoDeadline,
          titleSuffix: goal.achieved
              ? [PBadge(label: l.savingGoalAchieved, tone: PBadgeTone.positive)]
              : null,
          prefix: PListTile(
            background: softBg(context, color),
            color: color,
            child: Icon(
              lucideByName(goal.icon, fallback: LucideIcons.piggyBank),
            ),
          ),
          onTap: onEdit,
        ),
        // 줄 아래 10 에 한 줄(좌우 24): 왼쪽 "모은 돈 / 목표", 오른쪽 "{n}%"
        Padding(
          padding: const EdgeInsets.fromLTRB(
            PSpacing.x6,
            0,
            PSpacing.x6,
            PSpacing.x1_5,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  keepAllAmount(
                    '${budgetWon(goal.currentAmount, masked)} / ${budgetWon(goal.targetAmount, masked)}',
                  ),
                  semanticsLabel:
                      '${budgetWon(goal.currentAmount, masked)} / ${budgetWon(goal.targetAmount, masked)}',
                  style: PTypography.t3.copyWith(
                    color: c.fgNeutralSubtle,
                    fontWeight: FontWeight.w500,
                    fontFeatures: tabularFigures,
                  ),
                ),
              ),
              const SizedBox(width: PSpacing.x2),
              Text(
                '$pct%',
                style: PTypography.t4.copyWith(
                  color: c.fgBrand,
                  fontWeight: FontWeight.w700,
                  fontFeatures: tabularFigures,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            PSpacing.x6,
            0,
            PSpacing.x6,
            PSpacing.x3,
          ),
          child: BudgetBar(
            value: goal.currentAmount.toDouble(),
            max: goal.targetAmount.toDouble(),
            meaning: PProgressMeaning.goal,
            label: goal.title,
            valueText: '$pct%',
          ),
        ),
      ],
    );
  }
}
