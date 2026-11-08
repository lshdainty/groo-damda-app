import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/core/format/percent.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/list/list_row.dart'
    show kPListStackBelowEm;
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';

/// 한도 · 목표.
enum PProgressMeaning {
  /// 쓸수록 차는 막대(예산 · 카드 한도) — 넘으면 위험 색 + "N원 초과". 기본
  limit,

  /// 모을수록 차는 막대(저축 목표 · 카드 실적) — 닿으면 글 "달성" 만(색은 그대로)
  goal,
}

/// 막대의 상태 — 스펙의 states.
enum PProgressState { enabled, over, reached }

/// 값 → 상태 · 채움 비율(0 ~ 1). 0 보다 작은 값은 0 으로 본다. 위젯과 테스트가 같은 식을 쓴다.
@visibleForTesting
({double current, PProgressState state, double fill}) measurePProgress(
  double value,
  double max,
  PProgressMeaning meaning,
) {
  final current = math.max(value, 0.0);
  final ratio = max > 0 ? current / max : (current > 0 ? 1.0 : 0.0);
  final state = meaning == PProgressMeaning.limit
      ? (current > max ? PProgressState.over : PProgressState.enabled)
      : (current >= max ? PProgressState.reached : PProgressState.enabled);
  return (current: current, state: state, fill: math.min(ratio, 1.0));
}

String _won(double n) => krwSigned(n.round(), false, unit: true);

/// Progress — "얼마나 찼나" 를 보이는 미터. groo 만의 막대(SEED 에는 선형 막대가 없다 — 2026-10-03), 수치 원본은
/// groo-design `specs/components/progress.yaml`(값은 `test/fixtures/design_spec/progress.json`). 웹(desk-front
/// `src/shared/ds/progress`)과 같은 값이다. 불러오기 · 올리기의 진행에는 쓰지 않는다 — 그건 Progress Circle 이다.
///
/// 모양 — 이름 줄 · 막대 · 금액 줄을 세로로, 사이 6. 이름 줄은 이름(t4 · 500 · fg-neutral)과 오른쪽 글(t3 ·
///   fg-neutral-subtle · 숫자 폭 같게)을 양 끝에 글자 바탕선으로 맞추고 사이는 적어도 8. 막대는 [PProgressBar].
///   금액 줄은 "현재 / 목표"(t2 · fg-neutral-subtle · 숫자 폭 같게).
/// 상태 — 오른쪽 글은 반올림한 정수 비율("88%"). 한도를 넘으면 채움 fg-critical + "20,000원 초과"(fg-critical · 700),
///   목표에 닿으면 "달성"(fg-neutral · 700).
/// 접근성 — 막대가 이름 "{이름} {목표} 중 {현재}" 와 값 글(오른쪽 글과 같은 말)을 읽는다. 보이는 글은 두 번 읽지 않는다.
class PProgress extends StatelessWidget {
  const PProgress({
    super.key,
    required this.label,
    required this.value,
    required this.max,
    this.meaning = PProgressMeaning.limit,
    this.formatValue,
  });

  /// 이름 — 무엇이 얼마나 찼나("식비 예산" · "여행 자금").
  final String label;
  final double value;

  /// 목표 · 한도.
  final double max;
  final PProgressMeaning meaning;

  /// 값의 글 — 기본 "350,000원". 돈이 아니면 그 단위로.
  final String Function(double value)? formatValue;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final format = formatValue ?? _won;
    final m = measurePProgress(value, max, meaning);
    final status = switch (m.state) {
      PProgressState.over => l10n.dsProgressOver(format(m.current - max)),
      PProgressState.reached => l10n.dsProgressReached,
      PProgressState.enabled => formatProgress(m.fill * 100),
    };
    const tabular = [FontFeature.tabularFigures()];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: PSpacing.x1_5,
      children: [
        // 이름 줄 — 막대가 같은 말을 읽으므로 보조 기술에는 숨긴다. 이름은 줄을 바꾸고(progress.md:33) 오른쪽 글은 양 끝에 선다.
        // 줄 안 폭이 글자 16개(16em — List 와 같은 문턱)보다 좁으면 오른쪽 글을 이름 아래 왼쪽으로 내린다(웹 · 앱 한 벌).
        ExcludeSemantics(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final narrow =
                  constraints.maxWidth <
                  kPListStackBelowEm *
                      MediaQuery.textScalerOf(
                        context,
                      ).scale(PTypography.t5.fontSize!);
              final name = Text(
                keepAll(label),
                style: PTypography.t4.copyWith(
                  color: c.fgNeutral,
                  fontWeight: FontWeight.w500,
                ),
              );
              final statusText = Text(
                status,
                style: PTypography.t3.copyWith(
                  fontFeatures: tabular,
                  color: switch (m.state) {
                    PProgressState.over => c.fgCritical,
                    PProgressState.reached => c.fgNeutral,
                    PProgressState.enabled => c.fgNeutralSubtle,
                  },
                  fontWeight: m.state == PProgressState.enabled
                      ? FontWeight.w400
                      : FontWeight.w700,
                ),
              );
              if (narrow) {
                // 이름 ↔ 오른쪽 글 2(list.md:148, 웹 gap-x0_5)
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: PSpacing.x0_5,
                  children: [name, statusText],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                spacing: PSpacing.x2,
                children: [
                  Expanded(child: name),
                  statusText,
                ],
              );
            },
          ),
        ),
        PProgressBar(
          value: value,
          max: max,
          meaning: meaning,
          semanticsLabel: l10n.dsProgressSemantics(
            label,
            format(max),
            format(m.current),
          ),
          semanticsValue: status,
        ),
        ExcludeSemantics(
          child: Text(
            // 쉼표 뒤 · " / " 뒤에서만 줄이 바뀐다(I-06 22 — 금액은 낱말 안에서 끊지 않는다)
            keepAllAmount('${format(m.current)} / ${format(max)}'),
            style: PTypography.t2.copyWith(
              fontFeatures: tabular,
              color: c.fgNeutralSubtle,
            ),
          ),
        ),
      ],
    );
  }
}

/// 막대만 — 이름 · 글을 직접 그릴 때. 이름([semanticsLabel])과 값 글([semanticsValue])을 꼭 준다.
///
/// 높이 8 · 모서리 full · 트랙 bg-neutral-weak, 채움은 브랜드 글자색 fg-brand(넘친 한도는 fg-critical — 채움 색
/// bg-brand-solid 는 다크 트랙에 묻힌다). 채움 폭은 값 ÷ 목표(넘쳐도 끝까지), 값이 0 보다 크면 적어도 높이만큼.
/// 값이 바뀌면 폭이 d6(300ms) · enter 로 따라 찬다 — 처음 그릴 때는 움직이지 않고, 모션 줄이기면 바로.
class PProgressBar extends StatelessWidget {
  const PProgressBar({
    super.key,
    required this.value,
    required this.max,
    this.meaning = PProgressMeaning.limit,
    required this.semanticsLabel,
    required this.semanticsValue,
  });

  final double value;
  final double max;
  final PProgressMeaning meaning;
  final String semanticsLabel;
  final String semanticsValue;

  static const double height = 8;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final m = measurePProgress(value, max, meaning);
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final fillColor = m.state == PProgressState.over ? c.fgCritical : c.fgBrand;

    return Semantics(
      container: true,
      label: semanticsLabel,
      value: semanticsValue,
      child: Container(
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: c.bgNeutralWeak,
          borderRadius: BorderRadius.circular(PRounded.full),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth * m.fill;
            final target = m.current > 0 ? math.max(width, height) : 0.0;
            return Align(
              alignment: Alignment.centerLeft,
              child: TweenAnimationBuilder<double>(
                // 처음 그릴 때는 움직이지 않는다 — 시작값 = 끝값
                tween: Tween(end: target),
                duration: reduceMotion ? Duration.zero : PDuration.d6,
                curve: PEasing.enter,
                builder: (context, w, _) => Container(
                  key: const ValueKey('progress-fill'),
                  width: w,
                  height: height,
                  decoration: BoxDecoration(
                    color: fillColor,
                    borderRadius: BorderRadius.circular(PRounded.full),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
