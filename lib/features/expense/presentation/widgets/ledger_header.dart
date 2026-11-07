import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/core/settings/hide_amounts_cards.dart';
import 'package:groo_damda_app/core/settings/mask_flags.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/chip/press_area.dart';
import 'package:groo_damda_app/shared/ds/divider/p_divider.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/notification_badge/p_notification_badge.dart';
import 'package:groo_damda_app/shared/ds/overflow_center/p_overflow_center.dart';
import 'package:groo_damda_app/shared/ds/scroll_auto_hide/p_scroll_auto_hide.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/ds/skeleton/loading_region.dart';

/// 가계부 원장 머리 — 달 이동 · 합계 · 인사이트 · 소비 요약 · 주 달력(I-07 7 · 8 · 11).
///
/// ds Scroll Auto Hide 로 내리면 총액 · 지난달 비교 · 소비 요약만 숨고, 달 이동 줄([LedgerMonthNav]) · 주 달력 · 펼침 꺾쇠 ·
/// 구분선은 남는다(12 — 페이지 전체를 조절하는 줄은 한 덩어리로 둔다). 할 일 원장도 같다.

/// 남는 머리(주 달력 · 꺾쇠 · 구분선)의 아래 끝 — 목록 맨 위 기준 y. 원장의 스크롤 스파이는 이 선 아래(+28)를 지난 날짜 묶음을
/// 고른 날로 삼는다. 남는 머리가 없으면(필터) `null`.
double? pinnedHeaderBottom(GlobalKey key, double listTop) {
  final box = key.currentContext?.findRenderObject();
  if (box is! RenderBox || !box.hasSize || !box.attached) return null;
  return box.localToGlobal(Offset(0, box.size.height)).dy - listTop;
}

/// 펼친 월 달력을 연 채 목록을 [threshold] 이상 내리면 고른 날이 든 주로 접는다 — 월 달력은 날짜를 고르는 도구이고, 내린다는 건
/// 고르기를 마치고 목록을 본다는 뜻이다. 맨 위에서 펼친 채 있는 건 그대로, 다시 펴려면 꺾쇠. 날을 눌러 옮겨 가는 동안(스파이
/// 잠금)은 기준을 그 자리로 옮길 뿐 접지 않는다. 가계부 · 할 일 원장이 같이 쓴다.
///
/// 접힐 때 목록이 튀지 않게 — 남는 머리가 줄어든 만큼 목록 위 여백도 줄어 맨 위 묶음은 머리 바로 아래에 그대로 남는다. 다만 그
/// 여백은 다음 프레임에야 잰다(`PScrollAutoHide`) — 그 한 프레임 동안 묶음이 줄어든 높이만큼 아래에 떠 보이지 않게
/// [PScrollAutoHideState.holdListThroughShrink] 로 스크롤을 잠깐 맞춘다. 높이는 애니메이션 없이 바로 바뀐다(모션 줄이기도 같다).
class LedgerAutoCollapse {
  LedgerAutoCollapse({
    required this.controller,
    required this.pinKey,
    required this.autoHideKey,
  });

  final ScrollController controller;

  /// 남는 아래 줄(주 달력 · 꺾쇠 · 선).
  final GlobalKey pinKey;
  final GlobalKey<PScrollAutoHideState> autoHideKey;

  /// 접기 시작하는 내린 거리.
  static const double threshold = 20;

  double? _anchor;
  double _collapsedHeight = 0;

  double _pinHeight() {
    final box = pinKey.currentContext?.findRenderObject();
    return box is RenderBox && box.hasSize ? box.size.height : 0;
  }

  /// 펼치기 직전(접힌 상태)에 부른다 — 접힌 높이와 지금 스크롤을 기억한다.
  void willExpand() {
    _collapsedHeight = _pinHeight();
    _anchor = controller.hasClients ? controller.offset : 0;
  }

  /// 스크롤마다 — 펼친 뒤 가장 위였던 자리에서 [threshold] 이상 내려왔으면 true.
  bool shouldCollapse({required bool locked}) {
    if (!controller.hasClients) return false;
    final p = controller.offset;
    final a = _anchor ?? p;
    if (locked || p < a) {
      _anchor = p;
      return false;
    }
    _anchor = a;
    if (p - a < threshold) return false;
    _anchor = null;
    return true;
  }

  /// 접는 `setState` 바로 앞에 부른다.
  void hold() {
    final shrink = _pinHeight() - _collapsedHeight;
    autoHideKey.currentState?.holdListThroughShrink(shrink);
  }
}

String ledgerYmd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// 달 줄 — 달 글 + 아래 꺾쇠(누르면 연 | 월 휠) + 오른쪽 거르기 · 거래 추가(오른쪽 끝). 단추는 Button ghost medium iconOnly(보이는 40 · 아이콘 18 · 누르는 44).
///
/// 할 일도 같이 쓴다 — 추가는 떠 있는 [+] 가 맡아 [onAddTx] 를 비우고, 걸린 조건은 개수 대신 거르기 단추의 알림 점([filterOn])이 말한다.
class LedgerMonthNav extends StatelessWidget {
  const LedgerMonthNav({
    super.key,
    required this.label,
    required this.onPick,
    required this.onOpenFilter,
    this.onAddTx,
    this.showMonth = true,
    this.filterOn = false,
  });

  final String label;
  final bool showMonth;

  /// 달 글을 누르면 — 연 | 월 휠 시트(‹ › 는 없다, 10-29).
  final VoidCallback onPick;
  final VoidCallback onOpenFilter;

  /// 오른쪽 [+] — 비우면 두지 않는다(할 일은 떠 있는 [+] 가 맡는다).
  final VoidCallback? onAddTx;

  /// 걸린 조건이 있다 — 거르기 단추에 알림 점 하나(숫자 없음). 이름은 "필터, 조건 걸림".
  final bool filterOn;

  // 달 글 상자 안 여백(10)만큼 덜어 글이 화면 여백 24 에 선다(오른쪽 단추는 40 안 아이콘 18 → 11).
  static const double _bleedStart = PSpacing.x2_5;
  static const double _bleedEnd = (PSpacing.x10 - PSpacing.x4_5) / 2;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        left: PSpacing.globalGutter - _bleedStart,
        right: PSpacing.globalGutter - _bleedEnd,
      ),
      child: Row(
        children: [
          if (showMonth)
            // 남는 폭은 모두 이 자리(Expanded)가 받고 달 글은 왼쪽에 붙는다 — 거르기 · [+] 가 늘 오른쪽 끝에 선다.
            // 달 글이 길면(큰 글자) 이 폭 안에서만 줄여 담는다.
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: PressArea(
                  enabled: true,
                  onTap: onPick,
                  touchMin: 0,
                  semantics: (child, enabled, onTap) => Semantics(
                    container: true,
                    button: true,
                    label: label,
                    onTap: onTap,
                    excludeSemantics: true,
                    child: child,
                  ),
                  builder: (context, pressed, size) => Container(
                    constraints: const BoxConstraints(minHeight: PTouch.min),
                    padding: const EdgeInsets.symmetric(
                      horizontal: PSpacing.x2_5,
                    ),
                    decoration: BoxDecoration(
                      color: pressed
                          ? c.bgLayerDefaultPressed
                          : c.bgLayerDefaultPressed.withValues(alpha: 0),
                      borderRadius: BorderRadius.circular(PRounded.r2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: PSpacing.x1,
                      children: [
                        // 큰 글자에서도 한 줄 — 글자 가운데에서 줄이 바뀌지 않게 모자라면 조금 줄여 담는다
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              label,
                              maxLines: 1,
                              style: PTypography.t6.copyWith(
                                color: c.fgNeutral,
                                fontWeight: FontWeight.w700,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Icon(
                          LucideIcons.chevronDown,
                          size: 16,
                          color: c.fgNeutralMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else
            const Spacer(),
          // 걸린 조건의 개수는 배지로 말하지 않는다 — 가계부는 아래 칩 줄이, 할 일은 알림 점 하나가 말한다.
          Stack(
            alignment: Alignment.center,
            children: [
              PButton.icon(
                icon: LucideIcons.slidersHorizontal,
                semanticLabel: filterOn ? l.tdmFilterOn : l.expFilter,
                variant: PButtonVariant.ghost,
                onPressed: onOpenFilter,
              ),
              if (filterOn)
                const Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: PNotificationBadge(
                        child: SizedBox.square(dimension: PSpacing.x4_5),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (onAddTx != null)
            PButton.icon(
              icon: LucideIcons.plus,
              semanticLabel: l.expAdd,
              variant: PButtonVariant.ghost,
              onPressed: onAddTx,
            ),
        ],
      ),
    );
  }
}

/// 이달 지출 합계(R13 지표 t9) + 인사이트 한 줄 + [소비 요약] 단추. 할 일은 "오늘 할 일 3개" + 별빛 한 줄 + [밤하늘] 로 같이 쓴다.
class LedgerTotalRow extends StatelessWidget {
  const LedgerTotalRow({
    super.key,
    required this.total,
    required this.insight,
    required this.summaryOpen,
    required this.onToggleSummary,
    this.loading = false,
    this.failed = false,
    this.buttonLabel,
    this.buttonIcon,
  });

  /// 오른쪽 단추 글 — 비우면 "소비 요약"(가계부). 할 일은 "밤하늘".
  final String? buttonLabel;

  /// 오른쪽 단추 앞 아이콘 — 할 일 [밤하늘] 의 sparkles.
  final IconData? buttonIcon;

  /// 합계 글 — 로딩 중이면 null.
  final String? total;

  /// 인사이트 한 줄 — 없으면 null.
  final Widget? insight;
  final bool summaryOpen;
  final VoidCallback onToggleSummary;

  /// 숫자 자리만 기다린다(틀은 그대로 그린다).
  final bool loading;

  /// 실패 — 숫자를 그리지 않고 [소비 요약] 은 막는다(자리의 안내는 목록 자리 Result Section 이 맡는다).
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PSpacing.globalGutter,
        PSpacing.x2,
        PSpacing.globalGutter,
        0,
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final label = buttonLabel ?? l.txmSpendSummary;
          final button = Semantics(
            container: true,
            expanded: summaryOpen,
            child: PButton(
              label: label,
              prefixIcon: buttonIcon,
              size: PButtonSize.small,
              variant: PButtonVariant.neutralOutline,
              onPressed: (loading || failed) ? null : onToggleSummary,
            ),
          );
          final figures = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (loading)
                loadingRegionWithText(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PSkeleton.text(PTypography.t9, width: 160),
                      const SizedBox(height: PSpacing.x1_5),
                      PSkeleton.text(PTypography.t4, width: 200),
                    ],
                  ),
                )
              else if (!failed) ...[
                Text(
                  // 금액은 쉼표 뒤에서만 줄을 바꾼다 — 큰 글자에서 숫자 가운데가 끊기지 않게
                  keepAllAmount(total ?? ''),
                  semanticsLabel: total,
                  style: PTypography.t9.copyWith(
                    color: c.fgNeutral,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (insight != null)
                  Padding(
                    padding: const EdgeInsets.only(top: PSpacing.x1_5),
                    child: insight,
                  ),
              ],
            ],
          );
          // 단추가 폭의 절반을 넘게 차지하면(큰 글자 · 영어) 합계가 글자 하나씩 꺾이므로 단추를 아래 줄로 내린다(웹 flex-wrap).
          final wide = PButton(
            label: label,
            prefixIcon: buttonIcon,
            size: PButtonSize.small,
            onPressed: null,
          ).naturalWidth(context);
          if (wide > box.maxWidth * 0.5) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: PSpacing.x3,
              children: [figures, button],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: PSpacing.x3,
            children: [
              Expanded(child: figures),
              button,
            ],
          );
        },
      ),
    );
  }
}

/// 펼친 소비 요약 — 카드 없이 보기만 하는 List 줄 셋(수입 · 지출 · 합계). 흰 화면 위 테두리 카드를 두지 않는다.
class LedgerSummaryList extends StatelessWidget {
  const LedgerSummaryList({
    super.key,
    required this.income,
    required this.expense,
    required this.flags,
  });

  final int income;
  final int expense;
  final MaskFlags flags;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    TextStyle value(Color color) => TextStyle(
      color: color,
      fontWeight: FontWeight.w700,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final net = income - expense;
    return Padding(
      padding: const EdgeInsets.only(top: PSpacing.x2),
      child: PList(
        semanticLabel: l.txmSpendSummary,
        children: [
          PListItem(
            title: l.expSummaryIncome,
            suffix: PListValue.amount(
              krwSigned(
                income,
                flags.of(MaskKind.income),
                sign: '+',
                unit: true,
              ),
              style: value(c.fgBrand),
            ),
          ),
          PListItem(
            title: l.expSummaryExpense,
            suffix: PListValue.amount(
              krwSigned(
                expense,
                flags.of(MaskKind.expense),
                sign: '−',
                unit: true,
              ),
              style: value(c.fgNeutral),
            ),
          ),
          PListItem(
            title: l.expTotal,
            // 합계 줄 제목만 700(지시서 8 — 화면 값)
            titleWeight: FontWeight.w700,
            suffix: PListValue.amount(
              krwSigned(
                net.abs(),
                flags.of(MaskKind.net),
                sign: net >= 0 ? '+' : '−',
                unit: true,
              ),
              style: value(c.fgNeutral),
            ),
          ),
        ],
      ),
    );
  }
}

/// 접이식 캘린더 — 가계부 칸 아래는 금액(t1)이다. 격자는 [LedgerCalendarGrid] 가 그린다.
class LedgerCalendar extends StatelessWidget {
  const LedgerCalendar({
    super.key,
    required this.month,
    required this.selected,
    required this.expanded,
    required this.byDay,
    required this.flags,
    required this.onSelect,
    required this.onToggleExpand,
    this.loading = false,
  });

  final DateTime month;
  final String? selected;
  final bool expanded;
  final Map<String, ({int out, int inn})> byDay;

  /// 화면 카드 + 종류 카드 — 금액마다 자기 종류로 판정한다.
  final MaskFlags flags;
  final ValueChanged<String> onSelect;
  final VoidCallback onToggleExpand;

  /// 칸 금액 자리만 기다린다(요일 · 날 숫자는 그대로).
  final bool loading;

  /// 날 숫자 원 — 눈금 36.
  static const double dayCircle = LedgerCalendarGrid.dayCircle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    TextStyle amountStyle(Color color) => PTypography.t1.copyWith(
      fontWeight: FontWeight.w700,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return LedgerCalendarGrid(
      month: month,
      selected: selected,
      expanded: expanded,
      onSelect: onSelect,
      onToggleExpand: onToggleExpand,
      // 칸 하나가 "11월 4일 (수), 지출 −1,234,567원, 수입 +400,000원" 한 이름으로 읽힌다(웹 cellName 과 한 꼴) —
      // 칸 금액이 점이어도 원까지 읽힌다. 금액 없는 날(불러오는 중 포함)은 날짜만. 가린 금액은 "금액 가림" 으로
      // 말해 거래가 없는 날처럼 들리지 않게 한다.
      cellLabel: (context, ds) {
        final l = AppLocalizations.of(context);
        final date = monthDayDow(DateTime.parse(ds));
        final data = loading ? null : byDay[ds];
        if (data == null) return date;
        final hideOut = data.out > 0 && flags.of(MaskKind.expense);
        final hideIn = data.inn > 0 && flags.of(MaskKind.income);
        final parts = <String>[
          if (data.out > 0 && !hideOut)
            l.expCellOutPart(krwSigned(data.out, false, sign: '−', unit: true)),
          if (data.inn > 0 && !hideIn)
            l.expCellInPart(krwSigned(data.inn, false, sign: '+', unit: true)),
          if (hideOut || hideIn) l.expCellHidden,
        ];
        return parts.isEmpty ? date : l.expCellLabel(date, parts.join(', '));
      },
      markBuilder: (context, ds) {
        if (loading) return PSkeleton.text(PTypography.t1, width: 32);
        final data = byDay[ds];
        if (data == null) return const SizedBox(height: PSpacing.x3);
        // 칸 글이 좁아 안 들어가는 금액은 말줄임 없이 점 "•" 으로 바꾼다(결정 2026-11-07 2A) — 전액은 날을 누르면
        // 그날 묶음 머리에, 화면 낭독은 칸 이름에 있다. 들어가는지는 실제 칸 폭 · 글자 배율로 잰다.
        return LayoutBuilder(
          builder: (context, box) {
            final scaler = MediaQuery.textScalerOf(context);
            final base = DefaultTextStyle.of(context).style;
            Widget line(String text, Color color) {
              final style = amountStyle(color);
              final fits = ledgerCellAmountFits(
                text,
                base.merge(style),
                scaler,
                box.maxWidth,
              );
              if (fits) {
                return Text(text, maxLines: 1, softWrap: false, style: style);
              }
              return ExcludeSemantics(
                child: Text(
                  ledgerCellDot,
                  key: const ValueKey('ledger-cell-dot'),
                  maxLines: 1,
                  softWrap: false,
                  style: style,
                ),
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (data.out > 0)
                  line(
                    '−${flags.of(MaskKind.expense) ? '••' : krw(data.out)}',
                    c.fgNeutral,
                  ),
                if (data.inn > 0)
                  line(
                    '+${flags.of(MaskKind.income) ? '••' : krw(data.inn)}',
                    c.fgBrand,
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

/// 칸 금액이 안 들어갈 때 대신 쓰는 점.
const String ledgerCellDot = '•';

/// [text] 가 [style] · [scaler] 로 한 줄에 [maxWidth] 안에 들어가는가 — 자리수가 아니라 실제 폭으로 잰다.
bool ledgerCellAmountFits(
  String text,
  TextStyle style,
  TextScaler scaler,
  double maxWidth,
) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    textScaler: scaler,
    maxLines: 1,
  )..layout();
  final w = painter.width;
  painter.dispose();
  return w <= maxWidth;
}

/// 접이식 캘린더의 격자 — 접힘: 선택 주 1줄 / 펼침: 월 전체. 요일 t2 · 날 숫자 t5. 칸 아래 표시는 쓰는 화면이 채운다
/// ([markBuilder] — 가계부 = 금액, 할 일 = 남은 수 · ★ · 구름 · ✓). 가계부 · 할 일 폰 원장이 같이 쓴다.
///
/// [cellLabel] 을 주면 칸 하나가 그 이름 하나로 읽힌다(표시는 장식이 되어 읽지 않는다) — 할 일은 "10월 22일, 남은 할 일 3개".
class LedgerCalendarGrid extends StatelessWidget {
  const LedgerCalendarGrid({
    super.key,
    required this.month,
    required this.selected,
    required this.expanded,
    required this.onSelect,
    required this.onToggleExpand,
    required this.markBuilder,
    this.cellLabel,
  });

  final DateTime month;
  final String? selected;
  final bool expanded;
  final ValueChanged<String> onSelect;
  final VoidCallback onToggleExpand;

  /// 날 숫자 아래 표시 — 없으면 빈 자리를 돌려준다.
  final Widget Function(BuildContext context, String ds) markBuilder;

  /// 칸의 읽는 이름 — 없으면 이름을 달지 않는다(할 일의 표시 없는 날).
  final String? Function(BuildContext context, String ds)? cellLabel;

  /// 날 숫자 원 — 눈금 36.
  static const double dayCircle = PSpacing.x9;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final today = DateTime.now();
    final todayStr = ledgerYmd(today);
    final firstDow = DateTime(month.year, month.month, 1).weekday % 7;
    final dim = DateTime(month.year, month.month + 1, 0).day;
    final cells = <({int d, String ds})?>[];
    for (var i = 0; i < firstDow; i++) {
      cells.add(null);
    }
    for (var d = 1; d <= dim; d++) {
      cells.add((
        d: d,
        ds: '${month.year}-${month.month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}',
      ));
    }
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    final weeks = <List<({int d, String ds})?>>[];
    for (var i = 0; i < cells.length; i += 7) {
      weeks.add(cells.sublist(i, i + 7));
    }
    var selWeek = weeks.indexWhere(
      (w) => w.any((c) => c != null && c.ds == selected),
    );
    if (selWeek < 0) {
      selWeek = weeks.indexWhere(
        (w) => w.any((c) => c != null && c.ds == todayStr),
      );
    }
    if (selWeek < 0) selWeek = 0;

    Widget cell(({int d, String ds})? cellData, int i) {
      if (cellData == null) {
        return const Expanded(child: SizedBox(height: PSpacing.x14));
      }
      final isSel = cellData.ds == selected;
      final future = cellData.ds.compareTo(todayStr) > 0;
      // 오는 날은 불투명도로 흐리지 않고 옅은 글자색 역할로 말한다(v106).
      // 일 = 치명 · 토 = 브랜드(옛 뜻 그대로 — 색 이름만 새것)
      final isToday = cellData.ds == todayStr;
      final numColor = isSel
          ? c.fgNeutralInverted
          : future
          ? c.fgNeutralSubtle
          : (i % 7 == 0
                ? c.fgCritical
                : (i % 7 == 6 ? c.fgBrand : c.fgNeutral));
      final label = cellLabel?.call(context, cellData.ds);
      // 누르는 자리 — ds PressArea. 누르는 동안 칸 바탕 bg-layer-default-pressed · 모서리 12(웹 `LedgerCell`
      // active:bg-bg-layer-default-pressed · rounded-r3). Material 물결은 두지 않고, 날짜 칸이라 줄지 않는다(date-picker.md).
      Widget inner = PressArea(
        enabled: true,
        onTap: () => onSelect(cellData.ds),
        touchMin: 0,
        // 이름이 있으면 아래에서 칸 하나로 묶어 읽는다 — 여기서는 누름만 맡는다
        semantics: (child, enabled, tap) => label != null
            ? child
            : Semantics(button: true, onTap: tap, child: child),
        builder: (context, pressed, _) => DecoratedBox(
          decoration: BoxDecoration(
            color: pressed ? c.bgLayerDefaultPressed : const Color(0x00000000),
            borderRadius: BorderRadius.circular(PRounded.r3),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, PSpacing.x1, 0, PSpacing.x2),
            child: Column(
              children: [
                // 원이 칸보다 넓어지면(글자 200%) 가운데 기준으로 이웃 쪽으로 넘친다 — 글자는 줄이지 않고(웹 `LedgerCellNum` 과 같다)
                // 숫자는 한 줄로 둔다(maxLines 1 · softWrap false)
                POverflowCenter(
                  child: Container(
                    // 최소 36 · 좌우 4 — 글자 200% 에서 두 자리 날이 잘리지 않게 글을 따라 늘어난다(웹 `min-w-x9 px-x1`)
                    constraints: const BoxConstraints(
                      minWidth: dayCircle,
                      minHeight: dayCircle,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: PSpacing.x1,
                    ),
                    // 고른 날 = 짙은 원(bg-neutral-inverted), 오늘 = 옅은 원(bg-neutral-weak) + 700 (date-picker.md)
                    decoration: isSel
                        ? BoxDecoration(
                            color: c.bgNeutralInverted,
                            borderRadius: BorderRadius.circular(PRounded.full),
                          )
                        : isToday
                        ? BoxDecoration(
                            color: c.bgNeutralWeak,
                            borderRadius: BorderRadius.circular(PRounded.full),
                          )
                        : null,
                    child: Center(
                      widthFactor: 1,
                      heightFactor: 1,
                      child: Text(
                        '${cellData.d}',
                        maxLines: 1,
                        softWrap: false,
                        style: PTypography.t5.copyWith(
                          fontWeight: isSel || isToday
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: numColor,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: PSpacing.x1),
                markBuilder(context, cellData.ds),
              ],
            ),
          ),
        ),
      );
      if (label != null) {
        inner = Semantics(
          container: true,
          button: true,
          label: label,
          excludeSemantics: true,
          onTap: () => onSelect(cellData.ds),
          child: inner,
        );
      }
      return Expanded(child: inner);
    }

    final dows = weekdayLabels();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PSpacing.x4,
        PSpacing.x3,
        PSpacing.x4,
        0,
      ),
      child: Column(
        children: [
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      0,
                      PSpacing.x1_5,
                      0,
                      PSpacing.x2,
                    ),
                    child: Text(
                      dows[i],
                      textAlign: TextAlign.center,
                      // 일 = 치명 · 토 = 브랜드 · 평일 = 옅은 중립 (뜻은 그대로, 색 역할 이름만)
                      style: PTypography.t2.copyWith(
                        fontWeight: FontWeight.w400,
                        color: i == 0
                            ? c.fgCritical
                            : i == 6
                            ? c.fgBrand
                            : c.fgNeutralSubtle,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          for (final w in expanded ? weeks : [weeks[selWeek]])
            Row(
              // 표시 줄 수가 달라도 날짜 숫자 y 고정.
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [for (var i = 0; i < 7; i++) cell(w[i], i)],
            ),
          // 펼침 단추 바로 아래에서 머리 틀이 끝난다(웹 `LedgerExpand` 와 같다 — 아래 여백 없음, I-29b 4).
          Center(
            child: Semantics(
              container: true,
              expanded: expanded,
              child: PButton.icon(
                icon: expanded
                    ? LucideIcons.chevronUp
                    : LucideIcons.chevronDown,
                // 이름은 늘 "월 달력" — 펼침 여부는 expanded 가 말한다
                semanticLabel: AppLocalizations.of(context).txmCalendarToggle,
                variant: PButtonVariant.ghost,
                onPressed: onToggleExpand,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 남는 덩어리의 끝 — 필터 중 칩 줄 아래 여백 `x3`(12) 다음에 [LedgerHeaderDivider]. 주 달력 덩어리는 꺾쇠 단추(보이는 40 ·
/// 아이콘 18)가 선 바로 위까지 차 꺾쇠 아이콘 아래가 선까지 11 이다 — 칩 줄은 테두리가 보이는 상자라 가까운 토큰 12 로 둔다.
const double kLedgerKeepBottom = PSpacing.x3;

/// 머리 아래 선 — Divider 1px `stroke-neutral-subtle` 화면 폭.
class LedgerHeaderDivider extends StatelessWidget {
  const LedgerHeaderDivider({super.key});

  @override
  Widget build(BuildContext context) => const PDivider();
}
