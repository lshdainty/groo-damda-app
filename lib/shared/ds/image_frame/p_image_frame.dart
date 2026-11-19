import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/aspect_ratio/p_aspect_ratio.dart';
import 'package:groo_damda_app/shared/ds/content_placeholder/p_content_placeholder.dart';
import 'package:groo_damda_app/shared/ds/image_frame/image_loader.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';

/// 그림 맞춤 — cover(기본, 사진 · 카드 그림: 가운데를 남겨 자른다) · contain(로고 · 글이 든 그림: 잘리지 않게, 둘레는 흰 판).
enum PImageFit { cover, contain }

/// 그림 위 자리 — 네 모서리. 한 자리에 하나.
enum PImageFramePlacement { topStart, topEnd, bottomStart, bottomEnd }

/// 그림 위 요소가 서는 틀의 짧은 변 하한 — 이보다 작은 틀에서는 그리지 않는다.
const double kImageFrameFloaterMinSide = 80;

/// 틀 하나에 둘 수 있는 그림 위 요소 수.
const int kImageFrameMaxFloaters = 2;

/// 폭 → 모서리(SEED) — 24 이하 4 · 48 이하 6 · 그 위 8. 폭을 모르면(부모 폭을 채운다) 8. 폭 기준이라 작은 그림일수록 줄인다.
double imageFrameRadius(double? width) {
  if (width == null || width.isNaN) return PRounded.r2;
  if (width <= 24) return PRounded.r1;
  if (width <= 48) return PRounded.r1_5;
  return PRounded.r2;
}

/// 안쪽 1px 투명 윤곽 — 그림 · 스켈레톤 · 대체 그림 위에 늘 그린다. 크기를 바꾸지 않고 누르기를 막지 않는다.
/// Image Frame · Logo Tile 이 같이 쓴다.
class PImageStroke extends StatelessWidget {
  const PImageStroke({super.key, required this.radius});

  final double radius;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: context.colors.strokeNeutralOverlay,
              width: 1,
            ),
          ),
        ),
      ),
    );
  }
}

/// 그림 위 자리 하나 — 위치와 내용(배지 solid 또는 [PImageFrameIndicator]).
@immutable
class PImageFrameFloater {
  const PImageFrameFloater({required this.placement, required this.child});

  final PImageFramePlacement placement;
  final Widget child;
}

/// 장수 · 길이 글(Indicator) — "1 / 12" · "+9". 상태 · 강조에는 쓰지 않는다(그건 배지). 보이는 글은 보조 기술에 숨기고
/// [label]("사진 12장 중 1번째")만 읽는다. 검정 65%(두 모드 같다) · 흰 11/15 500(글자 크기 설정을 따르지 않는다) · 좌우 6 ·
/// 위아래 2 · 높이 19 이상 · 알약.
class PImageFrameIndicator extends StatelessWidget {
  const PImageFrameIndicator({
    super.key,
    required this.text,
    required this.label,
  });

  /// 보이는 글.
  final String text;

  /// 읽는 글 — 무엇의 수인지.
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          // 그림은 모드를 따르지 않는다 — 두 모드 모두 overlay-dim-dark(65%)
          color: PColors.dark.overlayDim,
          borderRadius: BorderRadius.circular(PRounded.full),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 19),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PSpacing.x1_5,
              vertical: PSpacing.x0_5,
            ),
            // 사진 위 표식이라 글자 크기 설정을 따르지 않는다(image-frame.yaml indicator text-t1-static, groo-design #263) —
            // 같은 수는 [label] 로 읽는다
            child: Text(
              text,
              maxLines: 1,
              softWrap: false,
              textScaler: TextScaler.noScaling,
              style: PTypography.t1.copyWith(
                fontWeight: FontWeight.w500,
                color: context.colors.staticWhite,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Image Frame — 그림 한 장을 보이는 틀. 구조는 SEED Image Frame(2026-10-04), 수치 원본은 groo-design
/// `specs/components/image-frame.yaml`(값은 `test/fixtures/design_spec/image-frame.json`). 웹(desk-front
/// `src/shared/ds/image-frame`)과 같은 값 · 같은 규칙이다.
///
/// 비율 상자에 그림을 꽉 채우고(cover) 그림 위에 안쪽 1px 투명 윤곽을 늘 그린다(끄는 속성이 없다). 폭은 부르는 쪽,
/// 높이는 폭 ÷ 비율이라 그림이 오기 전에 자리를 잡는다. 모서리는 **폭으로** 고른다(24 이하 4 · 48 이하 6 · 그 위 8 ·
/// [bleed] 0 — [width] 가 없으면 부모 폭을 채우고 8).
///
/// - 받는 중 — 같은 모서리의 Skeleton. 다 받으면 그림이 투명도로 나타난다(150ms, 모션 줄이기면 바로. 붙을 때 이미 받아 둔
///   그림은 그대로 보인다).
/// - 없음 · 실패 · 10초 — 대체 그림(Content Placeholder). 10초는 틀이 화면에 들어온 때부터 잰다. 실패로 바뀐 뒤에는
///   그림이 와도 다시 바꾸지 않는다. [fallback] 으로 통째로 바꾼다(카드 면).
/// - 카드 비율의 세로 그림 — 다 받아 원래 크기를 안 뒤에만 시계 방향 90° 돌려 채운다(그 전엔 돌리지 않는다). 가로 · 정사각은
///   그대로다.
/// - [floaters] — 네 모서리에 하나씩, 둘까지, 틀의 짧은 변이 80 이상일 때만. 누르지 않는다.
///
/// 이름 — 틀은 역할이 없다. [alt] 가 비어 있지 않으면 그림이 이름을 가지고, 대체 그림이 그 이름을 이어받는다. ""(이름 옆
/// 그림 · 장식)이면 읽지 않는다. 누르지 않는다 — 누르는 자리는 감싼 버튼.
class PImageFrame extends StatelessWidget {
  const PImageFrame({
    super.key,
    required this.alt,
    this.image,
    this.ratio = PAspectRatioValue.r4x3,
    this.width,
    this.bleed = false,
    this.fit = PImageFit.cover,
    this.fallbackIcon = LucideIcons.image300,
    this.fallback,
    this.floaters = const [],
    this.timeout = PLoadingTiming.timeout,
  });

  /// 필수 — 이름 옆 · 장식 그림은 "", 혼자인 그림은 무엇인지.
  final String alt;

  /// 그림 — 없으면 처음부터 대체 그림.
  final ImageProvider? image;

  /// 비율 — 기본 4:3. card(1.586)는 세로 그림을 돌린다.
  final PAspectRatioValue ratio;

  /// 고정 폭(px) — 모서리를 고른다. 없으면 부모 폭을 채우고 모서리 8.
  final double? width;

  /// 화면 폭 — 좌우가 화면 끝에 닿는 그림, 모서리 0(윤곽은 그대로).
  final bool bleed;

  final PImageFit fit;

  /// 대체 그림 아이콘 — 기본 image.
  final IconData fallbackIcon;

  /// 대체 그림을 통째로 바꿀 때(카드 면). 틀을 채운다.
  final Widget? fallback;

  /// 그림 위 요소 — 자리마다 하나 · 둘까지(앞에서부터).
  final List<PImageFrameFloater> floaters;

  /// 받기를 포기하는 시간 — 틀이 화면에 들어온 때부터. 기본 10초.
  final Duration timeout;

  /// 그림 위 요소를 자리마다 하나 · 둘까지(앞에서부터) 거른다. 걸러 낸 수는 개발 중 알린다.
  @visibleForTesting
  static List<PImageFrameFloater> pickFloaters(
    List<PImageFrameFloater> floaters,
  ) {
    final picked = <PImageFrameFloater>[];
    final taken = <PImageFramePlacement>{};
    for (final f in floaters) {
      if (picked.length == kImageFrameMaxFloaters ||
          taken.contains(f.placement)) {
        continue;
      }
      taken.add(f.placement);
      picked.add(f);
    }
    return picked;
  }

  @override
  Widget build(BuildContext context) {
    final radius = bleed ? 0.0 : imageFrameRadius(width);
    final picked = pickFloaters(floaters);
    if (kDebugMode && picked.length != floaters.length) {
      debugPrint(
        '[PImageFrame] 그림 위 요소는 네 모서리에 하나씩, 틀 하나에 둘까지다 — '
        '${floaters.length - picked.length}개를 그리지 않았다.',
      );
    }

    Widget frame(Widget content) {
      final box = PAspectRatio(
        ratio: ratio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            content,
            if (picked.isNotEmpty) _Floaters(floaters: picked),
            PImageStroke(radius: radius),
          ],
        ),
      );
      // 모서리로 그림 · 스켈레톤 · 대체 그림을 자른다
      final clipped = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: box,
      );
      return width == null ? clipped : SizedBox(width: width, child: clipped);
    }

    final source = image;
    if (source == null) return frame(_fallbackLayer());
    return PImageLoader(
      image: source,
      timeout: timeout,
      builder: (context, status, portrait, reveal) {
        switch (status) {
          case PImageStatus.error:
            return frame(_fallbackLayer());
          case PImageStatus.loading:
            // 그림은 받는 동안 보이지 않는다 — 스켈레톤이 자리를 채운다(스켈레톤은 읽지 않는다)
            return frame(const SizedBox.expand(child: _FrameSkeleton()));
          case PImageStatus.loaded:
            return frame(_pictureLayer(context, source, portrait, reveal));
        }
      },
    );
  }

  Widget _pictureLayer(
    BuildContext context,
    ImageProvider source,
    bool portrait,
    bool reveal,
  ) {
    final rotate = ratio == PAspectRatioValue.card && portrait;
    Widget picture = Image(
      image: source,
      fit: fit == PImageFit.cover ? BoxFit.cover : BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
    );
    // 세로 카드 그림 — 틀의 높이 × 폭 상자에 채워 시계 방향으로 90° 돌린다
    if (rotate) picture = RotatedBox(quarterTurns: 1, child: picture);
    if (fit == PImageFit.contain) {
      picture = ColoredBox(
        color: context.colors.staticWhite,
        child: SizedBox.expand(child: picture),
      );
    }
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reveal && !reduceMotion) {
      picture = TweenAnimationBuilder<double>(
        key: ValueKey(source),
        tween: Tween(begin: 0, end: 1),
        duration: PDuration.d3,
        curve: PEasing.enter,
        builder: (context, opacity, child) =>
            Opacity(opacity: opacity, child: child),
        child: picture,
      );
    }
    final named = alt.trim().isNotEmpty;
    return named
        ? Semantics(
            image: true,
            label: alt,
            excludeSemantics: true,
            child: picture,
          )
        : ExcludeSemantics(child: picture);
  }

  Widget _fallbackLayer() {
    final named = alt.trim().isNotEmpty;
    final content = SizedBox.expand(
      key: const ValueKey('image-frame-fallback'),
      child: fallback ?? PContentPlaceholder(icon: fallbackIcon),
    );
    // 대체 그림이 alt 를 이름으로 이어받는다 — "" 이면 숨긴다
    return named
        ? Semantics(
            image: true,
            label: alt,
            excludeSemantics: true,
            child: content,
          )
        : ExcludeSemantics(child: content);
  }
}

class _FrameSkeleton extends StatelessWidget {
  const _FrameSkeleton();

  @override
  Widget build(BuildContext context) =>
      const PSkeleton(radius: PSkeletonRadius.r0);
}

/// 그림 위 자리 — 틀의 짧은 변이 80 이상일 때만 선다. 가장자리 → 요소 6. 누르지 않는다.
class _Floaters extends StatelessWidget {
  const _Floaters({required this.floaters});

  final List<PImageFrameFloater> floaters;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, box) {
          if (box.biggest.shortestSide < kImageFrameFloaterMinSide) {
            return const SizedBox.shrink();
          }
          return IgnorePointer(
            child: Stack(
              children: [
                for (final f in floaters)
                  Positioned(
                    top:
                        f.placement == PImageFramePlacement.topStart ||
                            f.placement == PImageFramePlacement.topEnd
                        ? PSpacing.x1_5
                        : null,
                    bottom:
                        f.placement == PImageFramePlacement.bottomStart ||
                            f.placement == PImageFramePlacement.bottomEnd
                        ? PSpacing.x1_5
                        : null,
                    left:
                        f.placement == PImageFramePlacement.topStart ||
                            f.placement == PImageFramePlacement.bottomStart
                        ? PSpacing.x1_5
                        : null,
                    right:
                        f.placement == PImageFramePlacement.topEnd ||
                            f.placement == PImageFramePlacement.bottomEnd
                        ? PSpacing.x1_5
                        : null,
                    child: f.child,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
