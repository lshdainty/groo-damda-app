import 'package:flutter/material.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/callout/p_callout.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/ds/text_button/p_text_button.dart';

/// 캘린더 관리·공유 · 라벨 화면이 함께 쓰는 흰 면 부품(I-09 09-3 — 37 ~ 49).
///
/// 두 화면은 상단 바 아래가 흰 면 하나다 — 카드 · 줄 사이 선 · 구역 사이 틈이 없다. 안내(Callout)는 흰 면 위
/// 예외이고, 목록 제목과 줄이 제 좌우 24 를 갖는다.

/// 안내 — ds Callout informative. 좌우 24 · 위 16 · 아래 8, 제목 없이 본문 한 문단(38 · 45).
class CalendarSurfaceCallout extends StatelessWidget {
  const CalendarSurfaceCallout(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      PSpacing.globalGutter,
      PSpacing.x4,
      PSpacing.globalGutter,
      PSpacing.x2,
    ),
    child: PCallout(tone: PCalloutTone.informative, description: text),
  );
}

/// 빈 목록 한 줄 — R9(14/19 · 옅은 색 · 가운데 · 해요체).
class CalendarSurfaceEmptyLine extends StatelessWidget {
  const CalendarSurfaceEmptyLine(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: PSpacing.globalGutter,
      vertical: PSpacing.x6,
    ),
    child: Center(
      child: Text(
        keepAll(text),
        textAlign: TextAlign.center,
        style: PTypography.t4.copyWith(color: context.colors.fgNeutralSubtle),
      ),
    ),
  );
}

/// 질의 하나가 실패한 구역 — Result Section failure 로 알리고 그 질의만 다시 받는다. 오류 원문은 그리지 않는다(42 · 49).
class CalendarSurfaceFailure extends StatelessWidget {
  const CalendarSurfaceFailure({
    super.key,
    required this.title,
    required this.onRetry,
  });

  final String title;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PResultSection(
      kind: PResultKind.failure,
      size: PResultSize.medium,
      title: title,
      description: l.dashFailDesc,
      primaryAction: PResultAction(label: l.actionRetry, onPressed: onRetry),
    );
  }
}

/// 목록 제목 자리의 스켈레톤 — 개수를 아직 모른다. 오른쪽 동작은 있으면 진짜를 둔다(정적 UI).
class CalendarSurfaceHeaderSkeleton extends StatelessWidget {
  const CalendarSurfaceHeaderSkeleton({super.key, this.action});

  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      PSpacing.globalGutter,
      action == null ? PSpacing.x2 : 0,
      PSpacing.globalGutter,
      action == null ? PSpacing.x2 : 0,
    ),
    child: SizedBox(
      height: action == null ? null : 36,
      child: Row(
        children: [
          PSkeleton.text(PTypography.t4, width: 96),
          const Spacer(),
          if (action != null)
            Transform.translate(
              offset: const Offset(kTextButtonPaddingX, 0),
              child: action,
            ),
        ],
      ),
    ),
  );
}

/// 줄 하나의 스켈레톤 — 앞 타일 40 + 제목 · 설명 두 줄(List 줄 모양 그대로, 카드 없이).
class CalendarSurfaceRowSkeleton extends StatelessWidget {
  const CalendarSurfaceRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: PSpacing.globalGutter,
      vertical: PSpacing.x3,
    ),
    child: Row(
      children: [
        const PSkeleton(width: 40, height: 40, radius: PSkeletonRadius.r12),
        const SizedBox(width: PSpacing.x3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: PSpacing.x0_5,
            children: [
              PSkeleton.text(PTypography.t5, width: 140),
              PSkeleton.text(PTypography.t3, width: 72),
            ],
          ),
        ),
      ],
    ),
  );
}
