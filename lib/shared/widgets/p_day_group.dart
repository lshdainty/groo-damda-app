import 'package:flutter/material.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/core/settings/hide_amounts_cards.dart';
import 'package:groo_damda_app/core/settings/mask_flags.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/expense/domain/expense_aggregates.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/header_row/p_header_row.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart' as ds;

/// 날짜 묶음 머리의 틀 — 글 + 오른쪽 자리(슬롯). 가계부 · 검색([PDayHeader])과 할 일(날짜 오른쪽 "2/5 완료")이 같이 쓴다.
///
/// List Header `mediumWeak`(t4 14 / 19 · 500 · `fg-neutral-subtle` · 좌우 24 · 위아래 8 · gap 10). 오른쪽 자리가 머리 폭의 절반을
/// 넘으면 제목 아래 줄 오른쪽 끝으로 내려간다([PHeaderRow]). 머리말 `headingLevel: 2`.
class PDayHeaderRow extends StatelessWidget {
  const PDayHeaderRow({
    super.key,
    required this.text,
    this.trailing,
    this.gutter,
  });

  /// 날짜 글 — `"10월 22일 (목) · 오늘"` · `"2025년 10월 25일 (토)"`.
  final String text;

  /// 오른쪽 자리 — 합계(거래) · "2/5 완료"(할 일). 없으면 비운다.
  final Widget? trailing;

  /// **임시 인자** — 좌우 여백 기본 24. 바깥 24 를 아직 쥔 호스트(검색)만 0 을 준다.
  final double? gutter;

  /// 머리 글자 — t4 · 500 · `fg-neutral-subtle` · 고정폭. 오른쪽 자리 글도 이 모양에서 색만 바꾼다.
  static TextStyle textStyle(PColors c) => PTypography.t4.copyWith(
    color: c.fgNeutralSubtle,
    fontWeight: FontWeight.w500,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      key: const ValueKey('day-header'),
      padding: EdgeInsets.symmetric(
        horizontal: gutter ?? PSpacing.globalGutter,
        vertical: PSpacing.x2,
      ),
      child: PHeaderRow(
        gap: PSpacing.x2_5,
        expandTitle: true,
        title: Semantics(
          header: true,
          headingLevel: 2,
          container: true,
          label: text,
          child: ExcludeSemantics(child: Text(text, style: textStyle(c))),
        ),
        action: trailing,
      ),
    );
  }
}

/// 날짜 묶음 머리 — List Header `mediumWeak`(t4 14 / 19 · 500 · `fg-neutral-subtle` · 좌우 24 · 위아래 8 · gap 10) 값이다(I-07 14).
///
/// 글 `"10월 22일 (목) · 오늘"`(다른 해 `"2025년 10월 25일 (토)"`) + 그날 합계(지출 `fg-neutral` · 수입 `fg-brand` + "+" · t4 500 고정폭). 합계가 머리 폭의 절반을
/// 넘으면 제목 아래 줄 오른쪽 끝으로 내려간다(`PHeaderRow` — List Header 와 같은 판정). 머리말 `headingLevel: 2`.
///
/// 가계부 · 검색이 함께 쓴다 — 두 화면이 각자 그리면 반드시 갈라진다. 합계는 월 헤더와 같은 규칙(환불 상계 + 예정 제외 —
/// `expenseSum`/`incomeSum`)이고 이체는 순자산 증감이 0 이라 호출부가 빼고 넘긴다.
class PDayHeader extends StatelessWidget {
  const PDayHeader({
    super.key,
    required this.date,
    required this.items,
    required this.flags,
    this.gutter,
  });

  final DateTime date;

  /// 그날의 거래 — 합계 계산에만 쓴다.
  final List<Expense> items;

  /// 금액마다 자기 종류로 가림 판정을 한다.
  final MaskFlags flags;

  /// **임시 인자** — 좌우 여백 기본 24(List Header). 바깥 24 를 아직 쥔 호스트(검색)만 0 을 준다 — 호스트가 바깥 24 를 걷을 때
  /// 함께 걷는다(I-06 의 List 줄 `gutter` 와 같은 뜻).
  final double? gutter;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final ds = _ymd(date);
    final now = DateTime.now();
    final rel = ds == _ymd(now)
        ? l.txmToday
        : ds == _ymd(now.subtract(const Duration(days: 1)))
        ? l.txmYesterday
        : null;
    // 날짜 규칙(DESIGN "날짜" 표 — 요일): 올해 "10월 25일 (일)", 다른 해 "2025년 10월 25일 (토)", 영어 "Sun, Oct 25" — 할 일
    // 원장 머리와 같은 함수
    final text =
        '${monthDayDow(date)}${rel == null ? '' : '\u00A0·\u00A0$rel'}';
    final style = PDayHeaderRow.textStyle(c);
    final dayExpense = expenseSum(items);
    final dayIncome = incomeSum(items);
    final sums = (dayExpense > 0 || dayIncome > 0)
        ? Row(
            mainAxisSize: MainAxisSize.min,
            spacing: PSpacing.x2,
            children: [
              if (dayExpense > 0)
                Text(
                  krwSigned(
                    dayExpense,
                    flags.of(MaskKind.expense),
                    sign: '−',
                    unit: true,
                  ),
                  style: style.copyWith(color: c.fgNeutral),
                ),
              if (dayIncome > 0)
                Text(
                  krwSigned(
                    dayIncome,
                    flags.of(MaskKind.income),
                    sign: '+',
                    unit: true,
                  ),
                  style: style.copyWith(color: c.fgBrand),
                ),
            ],
          )
        : null;
    return PDayHeaderRow(text: text, trailing: sums, gutter: gutter);
  }

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

/// 날짜 그룹 한 덩어리의 로딩 자리표시 — 머리 한 줄 + 행 [rows] 개.
///
/// 실제 [PDayHeader](좌우 24 · 위아래 8) · 거래 줄(좌우 24 · 위아래 12 · 타일 40)과 **같은 여백**을 쓴다 — 다르면 데이터가 오는
/// 순간 줄이 튄다. 바깥 24 를 아직 쥔 호스트(검색)는 [gutter] 0 을 준다([PDayHeader] 와 같은 임시 인자).
class PDayGroupSkeleton extends StatelessWidget {
  const PDayGroupSkeleton({
    super.key,
    required this.rows,
    this.gutter,
    this.headerGap = 0,
  });

  final int rows;
  final double? gutter;

  /// 머리와 첫 줄 사이 — 검색은 실제 화면이 6 을 둔다.
  final double headerGap;

  @override
  Widget build(BuildContext context) {
    final x = gutter ?? PSpacing.globalGutter;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: x, vertical: PSpacing.x2),
          child: Row(
            children: [
              ds.PSkeleton.text(PTypography.t4, width: 96),
              const Spacer(),
              ds.PSkeleton.text(PTypography.t4, width: 72),
            ],
          ),
        ),
        if (headerGap > 0) SizedBox(height: headerGap),
        for (int i = 0; i < rows; i++)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: x, vertical: PSpacing.x3),
            child: Row(
              children: [
                const ds.PSkeleton(
                  width: PSpacing.x10,
                  height: PSpacing.x10,
                  radius: ds.PSkeletonRadius.r12,
                ),
                const SizedBox(width: PSpacing.x3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: PSpacing.x0_5,
                    children: [
                      ds.PSkeleton.text(PTypography.t5, width: 120),
                      ds.PSkeleton.text(PTypography.t3, width: 80),
                    ],
                  ),
                ),
                const SizedBox(width: PSpacing.x2),
                ds.PSkeleton.text(PTypography.t5, width: 80),
              ],
            ),
          ),
      ],
    );
  }
}
