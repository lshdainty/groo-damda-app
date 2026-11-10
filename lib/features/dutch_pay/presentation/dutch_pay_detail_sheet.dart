import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/features/dutch_pay/application/dutch_pay_providers.dart';
import 'package:groo_damda_app/features/dutch_pay/domain/dutch_pay.dart';
import 'package:groo_damda_app/features/dutch_pay/domain/dutch_pay_model.dart';
import 'package:groo_damda_app/features/dutch_pay/presentation/dutch_pay_actions.dart';
import 'package:groo_damda_app/features/expense/presentation/tx_detail_rules.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/avatar/p_avatar.dart';
import 'package:groo_damda_app/shared/ds/badge/p_badge.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/callout/p_callout.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/ds/menu_sheet/p_menu_sheet.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';

/// 정산 상세(I-15 38 · 39 · 40) — ds Bottom Sheet 조회. 머리 제목 = 정산 이름(줄바꿈), 본문 = "{날짜 (요일)} · {장소}" · 총액(t9 24 / 32 · 700 ·
/// 쉼표 뒤에서만 줄바꿈) · "1인당 … · {n}명" · 선 · "참여자 · {n}" + ds List 줄(앞 Avatar 36 · 이름 · 설명 · 뒤 Badge 또는 [받음]).
/// 바닥: 진행 중 = [삭제] ghost critical + [모두 받음] · 완료 = [삭제] 하나. [일괄 요청] 은 머리 ⋮ 메뉴(막힘). 송금 요청 · 일괄 요청은 줄만 남기고 막는다
/// (서버에 요청 API 가 없다 — 10-30 결정, 이유 줄 Callout).
///
/// **몫은 저장된 값(`p.amount`)** — 나머지 원이 있는 사람은 그 값이 보인다. 결제자 줄은 몫이 다른 사람과 다를 때만 "· 몫 …" 을 붙인다.
/// 데이터는 목록에서 [dpId] 로 라이브 조회한다 — 받음 뒤 목록이 새로 오면 바로 따라가고, 목록에서 사라지면(삭제) 시트가 한 번만 닫힌다.
Future<void> showDutchPayDetailSheet(
  BuildContext context, {
  required int dpId,
}) {
  return PBottomSheet.show<void>(
    context,
    builder: (_) => _DetailSheet(dpId: dpId),
  );
}

class _DetailSheet extends ConsumerStatefulWidget {
  const _DetailSheet({required this.dpId});
  final int dpId;

  @override
  ConsumerState<_DetailSheet> createState() => _DetailSheetState();
}

class _DetailSheetState extends ConsumerState<_DetailSheet> {
  bool _busy = false;

  /// 돌고 있는 요청의 단추 — 'all' 이면 [모두 받음], 행 번호면 그 줄 [받음]만 진행 중으로 그린다.
  String? _running;
  bool _closed = false;

  void _closeOnce() {
    if (_closed || !mounted) return;
    _closed = true;
    PBottomSheet.of(context).close();
  }

  /// 같은 요청이 도는 동안 다음 누름을 버린다 — await 앞에서 잠근다.
  Future<void> _guard(Future<void> Function() run, {String? key}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _running = key;
    });
    try {
      await run();
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _running = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final masked = ref.watch(hideCardProvider('dutchpay.sessions'));
    final list = ref.watch(dutchPayListProvider).value;
    DutchPay? dp;
    if (list != null) {
      dp = list.where((d) => d.rowId == widget.dpId).firstOrNull;
      if (dp == null) {
        // 목록에서 사라졌다 — 지웠다(다시 시도로 지운 경우 포함)
        WidgetsBinding.instance.addPostFrameCallback((_) => _closeOnce());
      }
    }
    if (dp == null) {
      return PBottomSheetContent(
        title: l.dutchTitle,
        closeLabel: l.actionClose,
        body: const SizedBox(height: 80),
      );
    }
    final d = dp;
    final n = d.participants.length;
    final place = (d.description ?? '').trim();
    final date = dutchDateDowLabel(d.dutchPayDate);
    final meta = [
      if (date.isNotEmpty) date,
      if (place.isNotEmpty) place,
    ].join(' · ');
    final per = dutchPerPerson(d);
    final perText = !per.shown
        ? null
        : per.even
        ? l.dutchPerPersonOf(txMoney(per.each, masked))
        : l.dutchPerPersonRestOf(
            txMoney(per.each, masked),
            txMoney(per.rest, masked),
            per.restName!.isEmpty ? l.dutchNoName : per.restName!,
          );
    final perLine = [?perText, l.dutchNPeople(n)].join(' · ');
    final totalText = txMoney(d.totalAmount, masked);
    final shares = d.participants.map((p) => p.amount).toSet();
    final payerExtra =
        d.participants.any((p) => p.isPayer) && shares.length > 1;

    Widget row(DutchPayParticipant p) {
      final name = (p.participantName ?? '').trim().isEmpty
          ? l.dutchNoName
          : p.participantName!.trim();
      final String detail;
      Widget? suffix;
      if (p.isPayer) {
        // 결제자 몫이 다른 사람과 다를 때만 "· 몫" — 1원이 화면에 보이게(I-15 40)
        detail = payerExtra && p.amount != per.each && per.shown
            ? l.dutchPayerPaidShare(txMoney(p.amount, masked))
            : l.dutchPayerPaid;
        suffix = PBadge(label: l.dutchPayer);
      } else if (p.isPaid) {
        detail = l.dutchShareDone(txMoney(p.amount, masked));
        suffix = PBadge(label: l.dutchBadgePaid, tone: PBadgeTone.positive);
      } else {
        detail = l.dutchShareDue(txMoney(p.amount, masked));
        suffix = PListAction(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: PSpacing.x1,
            children: [
              // 송금 요청은 아직 열리지 않았다 — 단추는 남기고 막는다(10-30 결정). 이유는 위 Callout.
              PButton(
                label: l.dutchSendRequest,
                variant: PButtonVariant.neutralWeak,
                size: PButtonSize.small,
                semanticLabel:
                    '${l.dutchSendRequestOf(name)}. ${l.dutchRequestSoon}',
                onPressed: null,
              ),
              PButton(
                label: l.dutchMarkReceived,
                variant: PButtonVariant.neutralWeak,
                size: PButtonSize.small,
                semanticLabel: l.dutchMarkReceivedOf(name),
                loading: _running == 'row-${p.rowId}',
                onPressed: _busy || d.isSettled
                    ? null
                    : () => _guard(
                        () => markDutchPaid(context, d, p),
                        key: 'row-${p.rowId}',
                      ),
              ),
            ],
          ),
        );
      }
      return PListItem(
        title: name,
        detail: detail,
        prefix: PAvatar(name: name, size: PAvatarSize.s36),
        suffix: suffix,
      );
    }

    final deleteButton = PButton(
      label: l.actionDelete,
      variant: PButtonVariant.ghost,
      ghostColor: PButtonGhostColor.critical,
      size: PButtonSize.large,
      flush: PButtonFlush.left,
      onPressed: _busy
          ? null
          : () => _guard(() async {
              final gone = await deleteDutchWithConfirm(context, d);
              if (gone) _closeOnce();
            }),
    );

    final settleAll = PButton(
      label: l.dutchSettleAll,
      size: PButtonSize.large,
      loading: _running == 'all',
      onPressed: _busy
          ? null
          : () => _guard(() => settleDutch(context, d), key: 'all'),
    );

    return PBottomSheetContent(
      title: d.title,
      closeLabel: l.actionClose,
      // 동작이 여럿이면 머리 ⋮ 하나(bottom-sheet.yaml headerAction) — 바닥은 주 동작 + 왼쪽 [삭제] 만. 진행 중일 때만 [일괄 요청] 이 있다
      headerAction: d.isSettled ? null : _headerAction(l, d),
      // 참여자 수는 사용자 데이터라 늘어나는 목록 — 끝 흐림을 건다
      scrollFog: true,
      flushBody: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PSpacing.globalGutter,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (meta.isNotEmpty)
                  Text(
                    keepAll(meta),
                    semanticsLabel: meta,
                    style: PTypography.t4.copyWith(color: c.fgNeutralSubtle),
                  ),
                Text(
                  keepAllAmount(totalText),
                  key: const ValueKey('dutch-detail-total'),
                  semanticsLabel: totalText,
                  style: PTypography.t9.copyWith(
                    color: c.fgNeutral,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: PSpacing.x1),
                Text(
                  keepAll(perLine),
                  key: const ValueKey('dutch-detail-per'),
                  semanticsLabel: perLine,
                  style: PTypography.t4.copyWith(color: c.fgNeutralSubtle),
                ),
              ],
            ),
          ),
          const SizedBox(height: PSpacing.x4),
          Container(height: 1, color: c.strokeNeutralSubtle),
          PListHeader(title: l.dutchParticipantsHeader(n), headingLevel: 3),
          if (!d.isSettled)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PSpacing.globalGutter,
                0,
                PSpacing.globalGutter,
                PSpacing.x2,
              ),
              child: PCallout(
                tone: PCalloutTone.informative,
                description: l.dutchRequestSoon,
              ),
            ),
          PList(
            semanticLabel: l.dutchParticipant,
            children: [for (final p in d.participants) row(p)],
          ),
        ],
      ),
      // 완료 = [삭제] 하나(받을 것이 없다), 진행 중 = 왼쪽 [삭제] 내용 폭 + 남은 폭 [모두 받음]
      footerRow: d.isSettled
          // 완료 정산의 [삭제] 는 폭 전체가 아니라 왼쪽 · 내용 폭
          ? Row(children: [deleteButton])
          : _footer(context, deleteButton, settleAll),
    );
  }

  /// 머리 ⋮ — [일괄 요청] 은 아직 열리지 않았다(서버에 요청 API 가 없다 — 10-30 결정). 줄은 남기고 막는다, 이유는 설명 줄.
  Widget _headerAction(AppLocalizations l, DutchPay d) {
    return PButton.icon(
      icon: LucideIcons.ellipsisVertical,
      semanticLabel: l.recMoreOf(d.title),
      variant: PButtonVariant.ghost,
      ghostColor: PButtonGhostColor.neutralSubtle,
      size: PButtonSize.small,
      onPressed: _busy
          ? null
          : () => PMenuSheet.show(
              context,
              title: d.title,
              groups: [
                PMenuSheetGroup([
                  PMenuSheetItem(
                    label: l.dutchRequestAll,
                    description: l.dutchRequestSoon,
                    icon: LucideIcons.send,
                    enabled: false,
                  ),
                ]),
              ],
            ),
    );
  }

  /// 바닥 줄 — 왼쪽 [삭제] 내용 폭 + 남은 폭 [모두 받음]. 글자를 크게 키우면 글이 겹치므로 세로로 쌓는다(주 버튼이 위).
  Widget _footer(BuildContext context, Widget deleteButton, Widget settleAll) {
    if (MediaQuery.textScalerOf(context).scale(16) > 22) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: PSpacing.x2,
        children: [
          settleAll,
          Row(children: [deleteButton]),
        ],
      );
    }
    return Row(
      spacing: PSpacing.x2,
      children: [
        deleteButton,
        Expanded(child: settleAll),
      ],
    );
  }
}
