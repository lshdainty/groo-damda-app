import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/ds/text_button/p_text_button.dart';

/// 결과 — empty(비어 있음 · 처음, 기본 — 회색 아이콘) · failure(불러오기 실패 · 화면 오류 — 위험 색 느낌표, 첫 버튼은
/// "다시 시도") · done(완료 — 성공 색 체크).
enum PResultKind { empty, failure, done }

/// 크기 — large(기본, 화면 전체를 차지하는 결과: 제목 22/30 · 설명 16/22 · 사이 12 · 버튼 위 28) · medium(카드 · 섹션 ·
/// 시트 안의 결과: 제목 16/22 · 설명 14/19 · 사이 8 · 버튼 위 24).
enum PResultSize { large, medium }

/// 놓인 자리 — 좌우 여백이 갈린다. screen(기본 48) · card(카드 안 0 — 카드의 안 여백 24 가 가장자리를 맡는다, 둘 다 두면
/// 72 가 되어 좁은 카드에서 제목이 두 줄로 넘어간다) · listCard(목록 카드에 바로 둔 것 24 — 목록 카드는 줄마다 24 를
/// 가져 카드 여백이 없다). 웹은 카드 안인지를 CSS 조상 선택자로 알아내고, 앱은 놓는 쪽이 고른다(2026-10-09 사용자 결정).
enum PResultPlacement { screen, card, listCard }

/// 버튼 — 동작 이름("다시 시도" · "홈으로" · "거래 추가"). [loading] 은 누른 일이 끝날 때까지(다시 시도 하는 동안).
class PResultAction {
  const PResultAction({
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  final String label;

  /// 앞 아이콘 — 새로 만드는 동작("프리셋 추가" + plus)에만.
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
}

/// 크기마다의 값(result-section.yaml 크기).
class _SizeSpec {
  const _SizeSpec({
    required this.title,
    required this.description,
    required this.descriptionGap,
    required this.actionsGap,
  });

  final TextStyle title;
  final TextStyle description;
  final double descriptionGap;
  final double actionsGap;
}

const Map<PResultSize, _SizeSpec> _sizes = {
  PResultSize.large: _SizeSpec(
    title: PTypography.t8,
    description: PTypography.t5,
    descriptionGap: PSpacing.x3,
    actionsGap: PSpacing.x7,
  ),
  PResultSize.medium: _SizeSpec(
    title: PTypography.t5,
    description: PTypography.t4,
    descriptionGap: PSpacing.x2,
    actionsGap: PSpacing.x6,
  ),
};

const double _paddingY = PSpacing.x4;
const double _assetSize = 40;
const double _assetGap = PSpacing.x4;

/// 첫 버튼과 둘째 버튼 사이 — 둘째 버튼이 위아래로 8 블리드해 상자 사이는 12(SEED 와 같다).
const double _actionsGap = PSpacing.x5;
const double _secondaryBleed = PSpacing.x2;

/// 색 — 아이콘은 결과마다, 제목 · 설명은 늘 같다. 위젯과 테스트가 같은 표를 본다.
@visibleForTesting
({Color asset, Color title, Color description}) resolvePResultColors(
  PColors c,
  PResultKind kind,
) => (
  asset: switch (kind) {
    PResultKind.empty => c.fgNeutralSubtle,
    PResultKind.failure => c.fgCritical,
    PResultKind.done => c.fgPositive,
  },
  title: c.fgNeutral,
  description: c.fgNeutralMuted,
);

@visibleForTesting
double resultSectionPaddingX(PResultPlacement placement) => switch (placement) {
  PResultPlacement.screen => PSpacing.x12,
  PResultPlacement.card => 0,
  PResultPlacement.listCard => PSpacing.x6,
};

/// Result Section — 화면이나 그 영역 가운데에 놓는 결과(비어 있음 · 불러오기 실패 · 완료 · 찾을 수 없는 페이지 · 화면
/// 오류)를 한 틀로 그린다. 불러오기 실패를 "내역이 없어요" 처럼 비어 있음으로 보이지 않는다 — failure 로, 무엇을
/// 불러오지 못했는지와 "다시 시도" 를 둔다. 이미 불러온 내용이 있으면 지우지 않고 다시 불러오기 실패는 Snackbar 로
/// 가볍게 알린다. 구조는 SEED Result Section(2026-10-02), 수치 원본은 groo-design
/// `specs/components/result-section.yaml`(값은 `test/fixtures/design_spec/result-section.json`). 웹(desk-front
/// `src/shared/ds/result-section`)과 같은 값이다.
///
///   [kind]            empty(기본 — 무엇이 비었는지 말하는 [icon] 을 꼭 준다) · failure · done
///   [size]            large(기본) · medium
///   [icon]            아이콘 40 · 아래 16 — lucide 300 굵기(선 1.5)를 쓴다(`LucideIcons.receiptText300`).
///                     failure · done 은 주지 않으면 circle-alert · circle-check
///   [title]           무슨 상태인지 한 줄(큰 글씨라 마침표 없이)
///   [description]     왜 · 무엇을 하면 되는지, 해요체 + 마침표, 최대 두 줄을 권한다(서버가 보낸 글 · 예외 · 영어는 쓰지 않는다)
///   [primaryAction]   첫 버튼 — 해결 · 다음 동작. PButton neutralWeak medium(40)
///   [secondaryAction] 둘째 버튼 — 보조 동작. PTextButton(글 버튼 D2 — t4 · 700 · fg-neutral-muted · 36), 위아래로 8 블리드 — 글 자리만 차지한다
///   [headingLevel]    제목 단계(웹 `as` — 기본 2). 화면 전체 결과면 그 화면의 제목 단계로
///
/// 묶음 — 좌우 48(놓인 자리가 카드면 [placement]) · 위아래 16, 놓인 자리의 가운데에 서고(부모가 높이를 주면 남는 높이를
/// 채운다) 글은 가운데 정렬이다. 결과로 바뀌면 150ms 로 투명도가 올라온다(모션 줄이기면 바로). 묶음은 라이브 영역이라
/// 불러오는 중에서 결과로 바뀌면 보조 기술이 읽는다. 아이콘은 읽지 않는다 — 상태는 제목이 말한다.
///
/// 둘째 버튼의 아래 블리드 8 은 누르는 자리가 부모 상자 밖으로 못 나가는 Flutter 의 제약으로 레이아웃에서만 줄이고
/// (그리는 것은 36 그대로), 그 아래 8 은 누르지 못한다(웹은 블리드 안도 누른다).
class PResultSection extends StatelessWidget {
  const PResultSection({
    super.key,
    required this.title,
    this.kind = PResultKind.empty,
    this.size = PResultSize.large,
    this.icon,
    this.description,
    this.moreDescriptions = const [],
    this.primaryAction,
    this.secondaryAction,
    this.headingLevel = 2,
    this.placement = PResultPlacement.screen,
  }) : assert(
         kind != PResultKind.empty || icon != null,
         'empty 는 무엇이 비었는지 말하는 아이콘(icon)을 꼭 준다',
       ),
       assert(headingLevel >= 1 && headingLevel <= 6);

  final PResultKind kind;
  final PResultSize size;
  final IconData? icon;
  final String title;
  final String? description;

  /// [description] 뒤에 이어지는 문단들 — 문단 사이는 8(웹 `mt-x2`). `\n\n` 으로 이으면 줄 높이 한 줄(22)이 된다.
  final List<String> moreDescriptions;
  final PResultAction? primaryAction;
  final PResultAction? secondaryAction;
  final int headingLevel;
  final PResultPlacement placement;

  IconData get _icon =>
      icon ??
      switch (kind) {
        PResultKind.failure => LucideIcons.circleAlert300,
        PResultKind.done => LucideIcons.circleCheck300,
        PResultKind.empty => LucideIcons.info300,
      };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = _sizes[size]!;
    final colors = resolvePResultColors(c, kind);
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final primary = primaryAction;
    final secondary = secondaryAction;

    Widget content = Padding(
      key: const ValueKey('result-section-content'),
      padding: EdgeInsets.symmetric(
        horizontal: resultSectionPaddingX(placement),
        vertical: _paddingY,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 장식 — 상태는 제목이 말한다
          ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.only(bottom: _assetGap),
              child: Icon(
                _icon,
                key: const ValueKey('result-section-asset'),
                size: _assetSize,
                color: colors.asset,
              ),
            ),
          ),
          Semantics(
            header: true,
            headingLevel: headingLevel,
            child: Text(
              keepAll(title),
              key: const ValueKey('result-section-title'),
              semanticsLabel: title,
              textAlign: TextAlign.center,
              style: s.title.copyWith(
                color: colors.title,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (description != null)
            Padding(
              padding: EdgeInsets.only(top: s.descriptionGap),
              child: Text(
                keepAll(description!),
                key: const ValueKey('result-section-description'),
                semanticsLabel: description,
                textAlign: TextAlign.center,
                style: s.description.copyWith(
                  color: colors.description,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          if (description != null)
            for (final more in moreDescriptions)
              Padding(
                padding: const EdgeInsets.only(top: PSpacing.x2),
                child: Text(
                  keepAll(more),
                  textAlign: TextAlign.center,
                  style: s.description.copyWith(
                    color: colors.description,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
          if (primary != null || secondary != null)
            Padding(
              padding: EdgeInsets.only(top: s.actionsGap),
              child: _actions(primary, secondary),
            ),
        ],
      ),
    );

    // 결과로 바뀌면 투명도로 나타난다(150ms enter) — 모션 줄이기면 바로
    if (!reduceMotion) {
      content = TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: PDuration.d3,
        curve: PEasing.enter,
        builder: (context, opacity, child) =>
            Opacity(opacity: opacity, child: child),
        child: content,
      );
    }

    return Semantics(
      container: true,
      liveRegion: true,
      child: Center(child: content),
    );
  }

  /// 버튼 묶음 — 위아래로, 사이 20. 둘째 버튼이 위아래로 8 블리드해 상자 사이는 12 다.
  Widget _actions(PResultAction? primary, PResultAction? secondary) {
    PButton button(
      PResultAction action,
      PButtonVariant variant,
      PButtonSize size,
    ) => PButton(
      label: action.label,
      onPressed: action.onPressed,
      variant: variant,
      size: size,
      loading: action.loading,
      prefixIcon: action.icon,
    );

    // 첫 버튼 아래 사이 20 − 블리드 8 = 12 만 띄우고, 둘째 버튼은 36 그대로 그리되 레이아웃은 위아래 8 을 뺀다
    // (첫 버튼이 있으면 위 8 은 그 12 안에 이미 들어 있어 아래 8 만 뺀다)
    final secondaryButton = secondary == null
        ? null
        // 글 버튼(D2 — SEED Text Button: t4 · 700 · fg-neutral-muted · 36)
        : PTextButton(
            label: secondary.label,
            onPressed: secondary.loading ? null : secondary.onPressed,
          );
    const secondaryHeight = 36.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (primary != null)
          KeyedSubtree(
            key: const ValueKey('result-section-primary'),
            child: button(
              primary,
              PButtonVariant.neutralWeak,
              PButtonSize.medium,
            ),
          ),
        if (primary != null && secondaryButton != null)
          const SizedBox(height: _actionsGap - _secondaryBleed),
        if (secondaryButton != null)
          Align(
            key: const ValueKey('result-section-secondary'),
            alignment: primary != null ? Alignment.topCenter : Alignment.center,
            heightFactor: primary != null
                ? (secondaryHeight - _secondaryBleed) / secondaryHeight
                : (secondaryHeight - _secondaryBleed * 2) / secondaryHeight,
            child: secondaryButton,
          ),
      ],
    );
  }
}
