import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/amount_input_formatter.dart';
import 'package:groo_damda_app/core/format/chart_palette.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/features/calendar/presentation/calendar_event_form_rows.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/preset/domain/expense_template.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/chip/p_chip.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/ds/scroll_fog/p_scroll_fog.dart';
import 'package:groo_damda_app/shared/ds/text_button/p_text_button.dart';
import 'package:groo_damda_app/shared/icons/lucide_icon_map.dart';
import 'package:groo_damda_app/features/category/presentation/category_tile.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';

/// 칸에 넣을 때(처음 값 · 계산 값) 쉼표를 찍는다.
String groupWon(int v) => v <= 0 ? '' : formatAmountInput(v);

/// 소수 칸(현지 금액 · 환율) — 숫자와 점 하나, 소수 [maxFrac] 자리, 정수 12자리. 쓰는 동안 정수부에 쉼표를 찍고 캐럿은 치던 자리에 둔다.
class DecimalFormatter extends TextInputFormatter {
  const DecimalFormatter({required this.maxFrac});
  final int maxFrac;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text;
    final t = raw.replaceAll(',', '');
    if (t.isEmpty) return newValue;
    if (!RegExp(r'^\d*\.?\d*$').hasMatch(t)) return oldValue;
    final parts = t.split('.');
    if (parts[0].length > 12) return oldValue;
    if (parts.length > 1 && parts[1].length > maxFrac) return oldValue;
    final out = groupDecimal(t);
    final cursor = newValue.selection.isValid
        ? newValue.selection.extentOffset.clamp(0, raw.length)
        : raw.length;
    final before = raw.substring(0, cursor).replaceAll(',', '').length;
    var offset = 0;
    var seen = 0;
    while (offset < out.length && seen < before) {
      if (out.codeUnitAt(offset) != 0x2C) seen++;
      offset++;
    }
    return TextEditingValue(
      text: out,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}

/// "1234567.5" → "1,234,567.5" (쉼표가 이미 있으면 걷고 다시 찍는다).
String groupDecimal(String text) {
  final t = text.replaceAll(',', '');
  final i = t.indexOf('.');
  final head = i < 0 ? t : t.substring(0, i);
  final tail = i < 0 ? '' : t.substring(i);
  final out = StringBuffer();
  for (var k = 0; k < head.length; k++) {
    if (k > 0 && (head.length - k) % 3 == 0) out.write(',');
    out.write(head[k]);
  }
  return '$out$tail';
}

/// 1단계 · 금액 단계의 밑줄 금액 칸(Input underline large 40) — 끝에 통화 칩을 얹을 수 있다. 칸 값은 칠하지 않는다.
class TxUnderlineAmount extends StatelessWidget {
  const TxUnderlineAmount({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.semanticLabel,
    required this.formatters,
    this.suffixText,
    this.decimal = false,
    this.invalid = false,
    this.errorMessage,
    this.hintMessage,
    this.chip,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String semanticLabel;
  final List<TextInputFormatter> formatters;

  /// 뒤 글자(원) — 통화 칩이 있으면 두지 않는다(칩이 통화를 말한다).
  final String? suffixText;
  final bool decimal;
  final bool invalid;
  final String? errorMessage;

  /// 칸 아래 도움말(오류가 없을 때) — 빈 금액 프리셋 안내.
  final String? hintMessage;
  final Widget? chip;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final input = PInput(
      controller: controller,
      focusNode: focusNode,
      variant: PInputVariant.underline,
      semanticLabel: semanticLabel,
      placeholder: '0',
      invalid: invalid,
      // 칩이 있으면 칩 자리만큼 뒤 글자를 비워 둔다 — 밑줄 · 초점 · 오류 선이 칩 아래까지 같은 폭으로 간다(결정 그림 .ul2 가 칩을 품음)
      suffixText: chip == null ? suffixText : _chipSlot,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      textInputAction: TextInputAction.done,
      inputFormatters: formatters,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PSpacing.globalGutter,
        PSpacing.x3,
        PSpacing.globalGutter,
        PSpacing.x4,
      ),
      child: PField(
        invalid: invalid,
        errorMessage: errorMessage,
        description: invalid ? null : hintMessage,
        child: chip == null
            ? input
            // 칩은 칸 끝(값 뒤)에 얹는다 — 값이 칩 밑으로 들어가지 않게 칸 오른쪽을 칩 폭만큼 비운다
            : Stack(
                alignment: Alignment.centerRight,
                children: [
                  input,
                  Positioned(right: 0, top: 4, child: chip!),
                ],
              ),
      ),
    );
  }

  /// 칩 자리 — 글자 크기에 따라 자라는 em 공백(칩도 같은 배율로 자란다).
  static final String _chipSlot = '\u2003' * 5;
}

/// 목록 제목(프리셋) + 오른쪽 글 버튼 "현재 입력값 저장" + 칩 줄 + 끝 "모두 보기".
class TxPresetBlock extends StatelessWidget {
  const TxPresetBlock({
    super.key,
    required this.presets,
    required this.categories,
    required this.appliedId,
    required this.title,
    required this.onTap,
    required this.onSave,
    required this.onShowAll,
    required this.loadFailed,
  });

  /// 지금 종류의 프리셋 전부(사용 많은 순).
  final List<ExpenseTemplate> presets;
  final List<ExpenseCategory> categories;
  final int? appliedId;
  final String title;
  final ValueChanged<ExpenseTemplate> onTap;
  final VoidCallback onSave;
  final VoidCallback onShowAll;
  final bool loadFailed;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final top = presets.take(8).toList();
    final hasMore = presets.length > top.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PListHeader(
          title: title,
          action: PTextButton(label: l.expPresetSaveCurrent, onPressed: onSave),
        ),
        if (loadFailed)
          _note(context, l.txfPresetLoadFailed)
        else if (top.isEmpty)
          _note(context, l.txfNoPresets)
        else
          SizedBox(
            height: 36,
            // 가로 스크롤 줄은 끝 흐림 32(Scroll Fog row) — 칩 필터 바와 같은 방식
            child: PScrollFog(
              key: const ValueKey('tx-preset-chips'),
              use: PScrollFogUse.row,
              child: Row(
                spacing: PSpacing.x2,
                children: [
                  for (final p in top) _chip(context, l, p),
                  if (hasMore)
                    // 칩 묶음은 한 변형(outlineWeak) — "모두 보기" 도 같다
                    PChip(
                      label: l.txfShowAll,
                      variant: PChipVariant.outlineWeak,
                      suffixIcon: LucideIcons.chevronRight,
                      onPressed: onShowAll,
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: PSpacing.x2),
      ],
    );
  }

  Widget _chip(BuildContext context, AppLocalizations l, ExpenseTemplate p) {
    final cat = p.categoryRowId == null
        ? null
        : categories.byRowId(p.categoryRowId!);
    final fixed = (p.lockAmount ?? 'N') == 'Y' && (p.amount ?? 0) > 0;
    return PChip(
      key: ValueKey('tx-preset-chip-${p.rowId}'),
      label: fixed
          ? '${p.templateName}  ${formatChartAxis(p.amount!.toDouble())}'
          : p.templateName,
      variant: PChipVariant.outlineWeak,
      selected: p.rowId == appliedId,
      leading: _chipTile(context, p, cat),
      onPressed: () => onTap(p),
    );
  }

  Widget _note(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: PSpacing.globalGutter),
    child: Text(
      text,
      style: PTypography.t4.copyWith(color: context.colors.fgNeutralSubtle),
    ),
  );

  Widget? _chipTile(
    BuildContext context,
    ExpenseTemplate p,
    ExpenseCategory? cat,
  ) {
    final c = context.colors;
    if (p.expenseType == 'TRANSFER') {
      return _tile(
        context,
        c.bgNeutralWeak,
        c.fgNeutralMuted,
        LucideIcons.arrowRightLeft,
      );
    }
    if (cat == null) return null;
    final fg = resolveChartColor(context, cat.color, fallback: c.fgBrand);
    return _tile(context, softBg(context, fg), fg, lucideByName(cat.icon));
  }

  Widget _tile(BuildContext context, Color bg, Color fg, IconData icon) =>
      Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 12, color: fg),
      );
}

/// 줄 칸 — 앞 아이콘 22 · 제목 · 값(줄 끝 오른쪽 맞춤) · 꺾쇠(치는 값만). 값 없음이면 [placeholder] 를 흐리게.
class TxRow extends StatelessWidget {
  const TxRow({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.value,
    this.placeholder,
    this.dot,
    this.chevron = false,
    this.maxLines,
    this.locked = false,
    this.errorMessage,
    this.focusNode,
  });

  /// 줄의 초점 — 겹친 시트를 닫으면 초점이 이 줄로 돌아온다.
  final FocusNode? focusNode;
  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  final String? value;
  final String? placeholder;
  final Color? dot;
  final bool chevron;
  final int? maxLines;

  /// 막힌 줄 — 값은 보이고 꺾쇠 · 누름이 없다(잠금).
  final bool locked;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final has = value != null && value!.isNotEmpty;
    final shown = has ? value! : placeholder;
    final valueWidget = shown == null
        ? null
        : has
        ? CalendarRowValue(
            text: shown,
            dot: dot,
            maxLines: maxLines,
          ).build(context)
        : Text(
            shown,
            textAlign: TextAlign.end,
            style: TextStyle(color: c.fgPlaceholder),
          );
    final row = PListButtonItem(
      title: title,
      prefix: Icon(icon, size: 22),
      onTap: locked ? null : onTap,
      focusNode: focusNode,
      semanticHint: errorMessage,
      suffix: valueWidget == null && !(chevron && !locked)
          ? null
          : PListSuffix(
              children: [
                ?valueWidget,
                if (chevron && !locked)
                  const ExcludeSemantics(child: Icon(LucideIcons.chevronRight)),
              ],
            ),
    );
    if (errorMessage == null) return row;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row,
        TxFieldError(message: errorMessage!),
      ],
    );
  }
}

/// 칸 · 줄 아래 오류 한 줄(t3 · fg-critical · 아이콘 16).
class TxFieldError extends StatelessWidget {
  const TxFieldError({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PSpacing.globalGutter,
        0,
        PSpacing.globalGutter,
        PSpacing.x2,
      ),
      child: Semantics(
        liveRegion: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                LucideIcons.circleAlert,
                size: 16,
                color: c.fgCritical,
              ),
            ),
            const SizedBox(width: PSpacing.x1),
            Expanded(
              child: Text(
                message,
                style: PTypography.t3.copyWith(color: c.fgCritical),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 날짜 줄 — 날짜 조각 + 시각 조각(일정 폼의 조각 부품과 한 벌). 값은 줄 끝 오른쪽 맞춤.
class TxDateRow extends StatelessWidget {
  const TxDateRow({
    super.key,
    required this.title,
    required this.dayName,
    required this.timeName,
    required this.dayText,
    required this.timeText,
    required this.onDay,
    required this.onTime,
    this.locked = false,
  });

  final String title;
  final String dayName;
  final String timeName;
  final String dayText;
  final String timeText;
  final VoidCallback onDay;
  final VoidCallback onTime;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    if (locked) {
      return TxRow(
        title: title,
        icon: LucideIcons.calendar,
        value: '$dayText $timeText',
        onTap: null,
        locked: true,
      );
    }
    return PListItem(
      title: title,
      prefix: const Icon(LucideIcons.calendar, size: 22),
      suffix: FormPieceGroup(
        children: [
          FormPiece(label: '$dayName, $dayText', text: dayText, onTap: onDay),
          FormPiece(
            label: '$timeName, $timeText',
            text: timeText,
            onTap: onTime,
          ),
        ],
      ),
    );
  }
}

/// 카테고리 고르기 본문의 한 줄 앞 타일.
Widget txCategoryTile(BuildContext context, ExpenseCategory cat) =>
    categoryTile(context, cat);

/// 실패 알림은 폼 본문 맨 위에 서므로 내려가 있으면 안 보인다 — 실패가 그려진 다음 프레임에 본문을 맨 위로 올린다.
void scrollSheetBodyToTop(BuildContext context) {
  final controller = PBottomSheet.maybeOf(context)?.bodyController;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (controller != null && controller.hasClients) controller.jumpTo(0);
  });
}

/// 상세 → 수정 → ← 로 돌아왔을 때 상세 스크롤을 되돌린다(M5) — 단계를 바꿔도 본문 스크롤 컨트롤러는 시트 하나라 위치를 직접 기억한다.
double currentSheetScroll(BuildContext context) {
  final c = PBottomSheet.maybeOf(context)?.bodyController;
  return c != null && c.hasClients ? c.offset : 0;
}

void restoreSheetScroll(BuildContext context, double offset) {
  final c = PBottomSheet.maybeOf(context)?.bodyController;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (c != null && c.hasClients) {
      c.jumpTo(offset.clamp(0.0, c.position.maxScrollExtent));
    }
  });
}
