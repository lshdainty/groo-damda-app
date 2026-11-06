import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/callout/p_callout.dart';

/// 보이는 값이 지금 값이 아니다 — 섹션 머리 아래 Callout critical · actionable(상자 전체가 다시 시도). 좌우 화면 여백 24 ·
/// 아래 12. 나중에 나타나는 실패라 보조 기술에 알린다(alert).
class StaleValueCallout extends StatelessWidget {
  const StaleValueCallout({
    super.key,
    required this.title,
    required this.description,
    required this.onRetry,
    this.retrying = false,
    this.gutter = true,
  });

  /// 화면 여백 24 를 스스로 둔다 — 이미 여백 안(머리 칸)에 놓이면 끈다(위 8 만 둔다).
  final bool gutter;

  final String title;
  final String description;
  final VoidCallback onRetry;
  final bool retrying;

  @override
  Widget build(BuildContext context) => Padding(
    padding: gutter
        ? const EdgeInsets.fromLTRB(PSpacing.x6, 0, PSpacing.x6, PSpacing.x3)
        : const EdgeInsets.only(top: PSpacing.x2),
    child: PCallout(
      tone: PCalloutTone.critical,
      interaction: PCalloutInteraction.actionable,
      alert: true,
      title: title,
      description: description,
      onPressed: () {
        // 다시 받는 동안은 다시 누름을 무시한다(Callout 에는 로딩 상태가 없다)
        if (!retrying) onRetry();
      },
    ),
  );
}
