import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/features/dutch_pay/application/dutch_pay_providers.dart';
import 'package:groo_damda_app/features/dutch_pay/domain/dutch_pay.dart';
import 'package:groo_damda_app/features/dutch_pay/domain/dutch_pay_model.dart';
import 'package:groo_damda_app/features/dutch_pay/presentation/dutch_pay_create_dialog.dart';
import 'package:groo_damda_app/features/dutch_pay/presentation/dutch_pay_detail_sheet.dart';
import 'package:groo_damda_app/features/expense/presentation/tx_detail_rules.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/async/load_failure.dart';
import 'package:groo_damda_app/shared/ds/avatar/p_avatar.dart';
import 'package:groo_damda_app/shared/ds/floating_action_button/p_floating_action_button.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/progress/p_progress.dart';
import 'package:groo_damda_app/shared/ds/pull_to_refresh/p_pull_to_refresh.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/screen_band/p_screen_band.dart';
import 'package:groo_damda_app/shared/ds/segmented_control/p_segmented_control.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/tag_group/p_tag_group.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/ds/text/p_text.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';

/// 더치페이 폰 화면(I-15 25 ~ 31 · 5-B) — 띠 둘: 요약 띠(받을 돈 · 보낼 돈 두 줄) | 8 | 목록 띠(Segmented "진행 중 N · 완료 N · 친구 N" + 그 탭의 줄) +
/// 떠 있는 [+]("정산 만들기"). 띠 안에 카드를 두지 않는다. '보낼 돈' 데이터는 모델에 없어 늘 0(지금 있는 기능만).
class DutchPayScreen extends ConsumerStatefulWidget {
  const DutchPayScreen({super.key});
  @override
  ConsumerState<DutchPayScreen> createState() => _DutchPayScreenState();
}

enum _DutchTab { active, past, friends }

class _DutchPayScreenState extends ConsumerState<DutchPayScreen> {
  _DutchTab _tab = _DutchTab.active;

  Future<void> _refresh() async {
    ref.invalidate(dutchPayListProvider);
    try {
      await ref.read(dutchPayListProvider.future);
    } on Object {
      // 실패는 화면의 실패 상자가 말한다
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final async = ref.watch(dutchPayListProvider);
    final items = async.hasValue ? async.requireValue : null;
    final failed = items == null && async.loadFailed;
    final masked = ref.watch(hideCardProvider('dutchpay.sessions'));
    // 요약 띠는 "더치페이 요약" 스위치를 따로 읽는다
    final maskedSummary = ref.watch(hideCardProvider('dutchpay.summary'));

    final active = items == null
        ? const <DutchPay>[]
        : dutchSorted(items, settled: false);
    final past = items == null
        ? const <DutchPay>[]
        : dutchSorted(items, settled: true);
    final friends = items == null ? const <DutchFriend>[] : dutchFriends(items);
    final recv = dutchReceivable(active);

    Widget content;
    if (failed) {
      content = PResultSection(
        kind: PResultKind.failure,
        title: l.dutchLoadFailedTitle,
        description: l.dutchLoadFailedDesc,
        primaryAction: PResultAction(
          label: l.actionRetry,
          loading: async.loadRetrying,
          onPressed: () => ref.invalidate(dutchPayListProvider),
        ),
      );
    } else if (items == null) {
      content = Column(
        children: [for (var i = 0; i < 3; i++) const _RowSkeleton()],
      );
    } else {
      content = switch (_tab) {
        _DutchTab.active =>
          active.isEmpty
              ? PResultSection(
                  icon: LucideIcons.receipt,
                  title: l.dutchEmptyActiveTitle,
                  description: l.dutchEmptyActiveSub,
                )
              : _rows(active, masked),
        _DutchTab.past =>
          past.isEmpty
              ? PResultSection(
                  icon: LucideIcons.checkCheck,
                  title: l.dutchEmptyPastTitle,
                  description: l.dutchEmptyPastSub,
                )
              : _rows(past, masked),
        _DutchTab.friends =>
          friends.isEmpty
              ? PResultSection(
                  icon: LucideIcons.users,
                  title: l.dutchEmptyFriendsTitle,
                  description: l.dutchEmptyFriendsSub,
                )
              : PList(
                  semanticLabel: l.dutchTabFriends,
                  children: [
                    for (final f in friends)
                      _FriendRow(friend: f, masked: masked),
                  ],
                ),
      };
    }

    // 숫자 자리는 받기 전에는 Skeleton (금액 · 수가 아직 없다)
    final waiting = items == null;
    return Scaffold(
      backgroundColor: context.colors.bgLayerBasement,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(PTopNavigation.heightOf(context)),
        child: PTopNavigation(
          title: l.dutchTitle,
          leading: PTopNavigationIconButton.back(
            label: l.actionBack,
            onPressed: () => context.pop(),
          ),
        ),
      ),
      body: Stack(
        key: const ValueKey('dutch-screen'),
        children: [
          PPullToRefresh(
            onRefresh: _refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // 요약 띠 — 위 16 · 좌우 24 · 아래 20 · 두 줄 사이 12
                SliverToBoxAdapter(
                  child: PScreenSection(
                    padding: const EdgeInsets.fromLTRB(
                      PSpacing.globalGutter,
                      PSpacing.x4,
                      PSpacing.globalGutter,
                      PSpacing.x5,
                    ),
                    child: Column(
                      spacing: PSpacing.x3,
                      children: [
                        _SummaryLine(
                          key: const ValueKey('dutch-receive'),
                          label: l.dutchToReceive,
                          loading: waiting,
                          sub: recv.count == 0
                              ? l.dutchNoReceivable
                              : l.dutchFromPeople(recv.count),
                          amount: txMoney(recv.amount, maskedSummary),
                        ),
                        _SummaryLine(
                          key: const ValueKey('dutch-send'),
                          label: l.dutchToSend,
                          loading: waiting,
                          sub: l.dutchToPeople(0),
                          amount: txMoney(0, maskedSummary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: kScreenBandGap),
                ),
                // 목록 띠 — 화면 끝까지. Segmented 위 12 · 아래 4 는 목록과 한 덩어리
                SliverToBoxAdapter(
                  child: ColoredBox(
                    key: const ValueKey('dutch-list-band'),
                    color: context.colors.bgLayerDefault,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            PSpacing.globalGutter,
                            PSpacing.x3,
                            PSpacing.globalGutter,
                            PSpacing.x1,
                          ),
                          child: PSegmentedControl<_DutchTab>(
                            value: _tab,
                            onChanged: (v) => setState(() => _tab = v),
                            semanticLabel: l.dutchTitle,
                            items: [
                              PSegmentedItem(
                                value: _DutchTab.active,
                                label:
                                    '${l.dutchTabActive}${waiting ? '' : ' ${active.length}'}',
                              ),
                              PSegmentedItem(
                                value: _DutchTab.past,
                                label:
                                    '${l.dutchTabPast}${waiting ? '' : ' ${past.length}'}',
                              ),
                              PSegmentedItem(
                                value: _DutchTab.friends,
                                label:
                                    '${l.dutchTabFriends}${waiting ? '' : ' ${friends.length}'}',
                              ),
                            ],
                          ),
                        ),
                        content,
                        // 떠 있는 [+] 가 마지막 줄을 가리지 않게 96(띠 안)
                        const SizedBox(height: 96),
                      ],
                    ),
                  ),
                ),
                // 줄이 적을 때 띠 바탕만 화면 끝까지 — 줄은 위 Sliver 가 그려 끝까지 스크롤된다
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: ColoredBox(color: context.colors.bgLayerDefault),
                ),
              ],
            ),
          ),
          PFloatingActionButton(
            icon: LucideIcons.plus500,
            label: l.dutchCreate,
            onPressed: () => showDutchPayCreateDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _rows(List<DutchPay> items, bool masked) => PList(
    semanticLabel: AppLocalizations.of(context).dutchTitle,
    children: [
      for (final d in items)
        _SessionRow(
          key: ValueKey('dutch-${d.rowId}'),
          dp: d,
          masked: masked,
          onOpen: () => showDutchPayDetailSheet(context, dpId: d.rowId),
        ),
    ],
  );
}

/// 요약 한 줄 — 왼쪽 이름(t4) + 아래 "{n}명에게서"(t3), 오른쪽 금액(t9 24 / 32 · 700 · 고정폭). 금액은 줄이지 않고 쉼표 뒤에서만 줄바꿈하며,
/// 이름 옆에 안 들어가면 이름 아래 줄로 내려간다.
class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    super.key,
    required this.label,
    required this.sub,
    required this.amount,
    this.loading = false,
  });
  final bool loading;
  final String label;
  final String sub;
  final String amount;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (loading) {
      return Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: PSpacing.x1,
              children: [
                Text(
                  label,
                  style: PTypography.t4.copyWith(color: c.fgNeutralSubtle),
                ),
                PSkeleton.text(PTypography.t3, width: 72),
              ],
            ),
          ),
          PSkeleton.text(PTypography.t9, width: 128),
        ],
      );
    }
    final labelStyle = PTypography.t4.copyWith(color: c.fgNeutralSubtle);
    final subStyle = PTypography.t3.copyWith(color: c.fgNeutralSubtle);
    final amountStyle = PTypography.t9.copyWith(
      color: c.fgNeutral,
      fontWeight: FontWeight.w700,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final name = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(keepAll(label), semanticsLabel: label, style: labelStyle),
        Text(keepAll(sub), semanticsLabel: sub, style: subStyle),
      ],
    );
    final value = Text(
      keepAllAmount(amount),
      semanticsLabel: amount,
      textAlign: TextAlign.end,
      style: amountStyle,
    );
    return LayoutBuilder(
      builder: (context, box) {
        final scaler = MediaQuery.textScalerOf(context);
        final tp = TextPainter(
          text: TextSpan(text: amount, style: amountStyle),
          textDirection: TextDirection.ltr,
          textScaler: scaler,
        )..layout();
        final nameW = ([label, sub].map((t) {
          final p = TextPainter(
            text: TextSpan(text: t, style: labelStyle),
            textDirection: TextDirection.ltr,
            textScaler: scaler,
          )..layout();
          return p.width;
        })).reduce((a, b) => a > b ? a : b);
        // 이름과 금액이 한 줄에 안 들어가면(금액은 줄지 않는다) 금액을 이름 아래 줄로
        if (tp.width + nameW + PSpacing.x3 > box.maxWidth) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              name,
              Align(alignment: Alignment.centerRight, child: value),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: name),
            value,
          ],
        );
      },
    );
  }
}

/// 정산 줄(진행 중 · 완료) — ds List 누르는 줄: 제목(줄바꿈) → 총액(t5 700 · 쉼표 뒤 줄바꿈) → 메타 "{날짜} · {n}명 · 1인당 {금액}"(한 줄 말줄임) →
/// 진행 줄(Avatar Stack 24 + 막대 8 + "{낸 수}/{전체}명 냈어요" · 다 냈으면 "모두 냈어요"). 낸 수 = 결제자 + 낸 사람.
class _SessionRow extends StatelessWidget {
  const _SessionRow({
    super.key,
    required this.dp,
    required this.masked,
    required this.onOpen,
  });
  final DutchPay dp;
  final bool masked;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final n = dp.participants.length;
    final paid = dutchPaidCount(dp);
    final per = dutchPerPerson(dp);
    final date = dutchDateLabel(dp.dutchPayDate);
    final total = txMoney(dp.totalAmount, masked);
    final perText = !per.shown
        ? null
        : per.even
        ? l.dutchPerPersonOf(txMoney(per.each, masked))
        : l.dutchPerPersonRestOf(
            txMoney(per.each, masked),
            txMoney(per.rest, masked),
            per.restName!.isEmpty ? l.dutchNoName : per.restName!,
          );
    final progressText = dp.isSettled || (n > 0 && paid >= n)
        ? l.dutchAllPaid
        : l.dutchPaidProgress(paid, n);
    return PListButtonItem(
      align: PListAlign.top,
      title: dp.title,
      onTap: onOpen,
      detailChild: Padding(
        // 제목 → 총액 6 = 줄 안 사이 4 + 총액 위 2 (이미 2 가 있어 4 를 더한다)
        padding: const EdgeInsets.only(top: PSpacing.x1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: PSpacing.x1,
          children: [
            Text(
              keepAllAmount(total),
              semanticsLabel: total,
              style: PTypography.t5.copyWith(
                color: c.fgNeutral,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            PTagGroup(
              size: PTagGroupSize.t3,
              overflow: PTagGroupOverflow.truncate,
              items: [
                if (date.isNotEmpty) PTag(date),
                PTag(l.dutchNPeople(n)),
                if (perText != null) PTag(perText),
              ],
            ),
            Padding(
              // 위 6 — 위 Column 사이 4 가 이미 있어 2 만 더한다
              padding: const EdgeInsets.only(top: PSpacing.x0_5),
              // 막대는 늘 24 이상 — 글(줄지 않음)에 상한을 둬 200% 에서도 막대 자리를 남긴다
              child: LayoutBuilder(
                builder: (context, box) => Row(
                  spacing: PSpacing.x2_5,
                  children: [
                    PAvatarStack(
                      people: [
                        for (final p in dp.participants)
                          (
                            name: (p.participantName ?? '').trim().isEmpty
                                ? l.dutchNoName
                                : p.participantName!.trim(),
                            image: null,
                          ),
                      ],
                    ),
                    Expanded(
                      child: PProgressBar(
                        value: paid.toDouble(),
                        max: n == 0 ? 1 : n.toDouble(),
                        meaning: PProgressMeaning.goal,
                        semanticsLabel: l.dutchParticipant,
                        semanticsValue: progressText,
                      ),
                    ),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        // 아바타 스택 최대 72(24 + 3 × 16) + 막대 24 + 사이 20
                        maxWidth: (box.maxWidth - 72 - 24 - 2 * PSpacing.x2_5)
                            .clamp(0.0, double.infinity),
                      ),
                      child: Text(
                        progressText,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: PTypography.t3.copyWith(
                          color: c.fgNeutralSubtle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 친구 줄 — 보기만 하는 ds List 줄: 앞 Avatar 36 · 이름(줄바꿈) · "{n}회 함께 정산" · 받을 돈이 있으면 오른쪽에 "받을 돈 {금액}"(지금 그대로).
class _FriendRow extends StatelessWidget {
  const _FriendRow({required this.friend, required this.masked});
  final DutchFriend friend;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    return PListItem(
      title: friend.name,
      detail: l.dutchSettledTogetherCount(friend.sessions),
      prefix: PAvatar(name: friend.name, size: PAvatarSize.s36),
      suffix: friend.net > 0
          ? Text(
              krwSigned(friend.net, masked, sign: '+', unit: true),
              style: PTypography.t5.copyWith(
                color: c.fgNeutral,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            )
          : PText(
              l.dutchSettled,
              style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
            ),
    );
  }
}

/// 첫 진입 — 줄 자리만 Skeleton(제목 · 총액 · 메타 · 진행 줄 높이).
class _RowSkeleton extends StatelessWidget {
  const _RowSkeleton();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: PSpacing.globalGutter,
      vertical: PSpacing.x3,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: PSpacing.x1,
      children: [
        PSkeleton.text(PTypography.t5, width: 160),
        PSkeleton.text(PTypography.t5, width: 110),
        PSkeleton.text(PTypography.t3, width: 200),
        PSkeleton(width: double.infinity, height: PSpacing.x6),
      ],
    ),
  );
}
