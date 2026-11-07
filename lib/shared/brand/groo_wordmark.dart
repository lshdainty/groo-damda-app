import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/brand/groo_tree.dart';
import 'package:groo_damda_app/shared/ds/text/p_text.dart';

/// 서비스 이름 글 — 32 / 40 · 700 · `fg-neutral`. 로그인 · 첫 화면 마크가 같이 쓴다(I-05 85 · 86, 화면 값).
TextStyle grooNameStyle(BuildContext context) => PTypography.t12.copyWith(
  height: 40 / 32,
  fontWeight: FontWeight.w700,
  letterSpacing: -0.32,
  color: context.colors.fgNeutral,
);

/// 나무 + 서비스 이름 묶음.
///
/// 가로(로그인): 나무 56 + 8 + 이름. 세로(첫 화면): 나무 96 + 16 + 이름 — 묶음 높이 152.
/// 이름은 실제 글(`l.appTitle`)이고 나무는 장식이다. [asHeading] 이면 화면 제목(머리말 1단계)이다.
class GrooWordmark extends StatelessWidget {
  const GrooWordmark.horizontal({super.key, this.asHeading = false})
    : vertical = false,
      treeHeight = 56,
      gap = PSpacing.x2;

  const GrooWordmark.vertical({super.key, this.asHeading = false})
    : vertical = true,
      treeHeight = 96,
      gap = PSpacing.x4;

  final bool vertical;
  final double treeHeight;
  final double gap;
  final bool asHeading;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    Widget name = PText(
      l.appTitle,
      textAlign: vertical ? TextAlign.center : TextAlign.start,
      style: grooNameStyle(context),
    );
    if (asHeading) {
      name = Semantics(header: true, headingLevel: 1, child: name);
    }
    final tree = GrooTree(height: treeHeight);
    if (vertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          tree,
          SizedBox(height: gap),
          name,
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        tree,
        SizedBox(width: gap),
        Flexible(child: name),
      ],
    );
  }
}
