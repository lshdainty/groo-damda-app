import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/chart_palette.dart';
import 'package:groo_damda_app/core/format/color_parse.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart_values.dart';
import 'package:groo_damda_app/shared/ds/color_swatch/p_color_swatch.dart';

/// 폼 "색상" 줄의 고르기 — 저장된 hex 와 팔레트 칸을 잇는다(저축 목표 · 카테고리 폼이 함께 쓴다).
///
/// 저장 값(라이트 hex)은 그대로다. 팔레트 밖 색(#9E9E9E 등)은 "지금 색" 칸이 되고, 그 칸을 고르면 저장된 값을 바꾸지 않는다.

/// 팔레트 색의 저장 hex(라이트 base).
String chartHexOf(PChartColor color) =>
    kChartPairs.firstWhere((p) => p.key == color.name).baseHex;

/// 저장 hex 가 팔레트 색이면 그 색, 아니면 null(팔레트 밖).
PChartColor? chartColorOfHex(String? hex) {
  final key = chartKeyOfHex(hex);
  return key == null ? null : PChartColor.values.byName(key);
}

/// 같은 목록이 아직 쓰지 않은 첫 색의 저장 hex(v110 배정 순서).
String firstUnusedHex(Iterable<String?> usedHexes) => chartHexOf(
  pFirstUnusedColor([for (final h in usedHexes) chartColorOfHex(h)]),
);

/// 색 줄의 값 글 — 팔레트 색은 색 이름, 팔레트 밖은 "지금 색".
String colorPickName(BuildContext context, String hex) {
  final color = chartColorOfHex(hex);
  return color == null
      ? AppLocalizations.of(context).dsColorCurrent
      : pColorSwatchNamesOf(context)[color]!;
}

/// 색 고르기 시트 — 폼 위에 뜨는 고르기 시트. 고르면 바로 닫히고 새 저장 hex 를 돌려준다(닫기만 하면 null).
/// [hex] 가 팔레트 밖이면 [foreignHex] 가 "지금 색" 칸이 된다 — 그 칸을 고르면 [foreignHex] 그대로 돌려준다.
Future<String?> showColorPickSheet(
  BuildContext context, {
  required String title,
  required String hex,
  String? foreignHex,
}) async {
  final picked = await PBottomSheet.show<PColorSwatchValue>(
    context,
    builder: (sheetContext) {
      final l = AppLocalizations.of(sheetContext);
      final current = chartColorOfHex(hex);
      return PBottomSheetContent(
        title: title,
        closeLabel: l.actionClose,
        body: Padding(
          // 위 4 — 고른 고리가 칸 바깥 4 까지 나오므로 머리 아래에 닿지 않게(웹 `ColorPickerRow` 의 pt-x1). 아래는 바닥 없는 시트의
          // 본문 아래 16 뿐이다 — 여기서 더 두면 웹보다 16 낮아진다
          padding: const EdgeInsets.only(top: PSpacing.x1),
          child: PColorSwatchGroup(
            value: current == null
                ? const PColorSwatchValue.current()
                : PColorSwatchValue.color(current),
            semanticLabel: title,
            currentColor: foreignHex == null
                ? null
                : parseColor(foreignHex, fallback: const Color(0xFF9E9E9E)),
            onChanged: (v) => PBottomSheet.of(sheetContext).close(v),
          ),
        ),
      );
    },
  );
  if (picked == null) return null;
  // 지금 색 칸을 고르면 저장된 값을 그대로 둔다 — 몰래 바꾸지 않는다
  return picked.isCurrent ? (foreignHex ?? hex) : chartHexOf(picked.color!);
}
