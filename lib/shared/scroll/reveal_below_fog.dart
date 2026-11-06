import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/shared/ds/scroll_fog/p_scroll_fog.dart';

/// [context] 의 요소를 가장 가까운 스크롤 상자의 위쪽으로 올린다 — **위 끝 흐림이 켜진 상자면 흐림 아래**에 놓는다.
///
/// `Scrollable.ensureVisible` 은 흐림을 모르고 요소를 상자 맨 위에 붙여, 위 흐림(시트 본문 20)이 그 윗부분을 가린다
/// (저장 실패 Callout 이 흐려 보이던 것, 2026-10-31). 흐림이 없는 상자에서는 `ensureVisible(alignment: 0)` 과 같다.
/// 맨 위보다 더 올리지 않고(0 으로 맞춘다) 이미 그 자리면 움직이지 않는다.
void revealBelowFog(
  BuildContext context, {
  Duration duration = const Duration(milliseconds: 200),
  Curve curve = Curves.ease,
}) {
  final object = context.findRenderObject();
  final scrollable = Scrollable.maybeOf(context);
  if (object == null || scrollable == null) return;
  final viewport = RenderAbstractViewport.maybeOf(object);
  if (viewport == null) return;
  final fog = PScrollFogInset.topOf(context);
  final position = scrollable.position;
  final target = (viewport.getOffsetToReveal(object, 0).offset - fog).clamp(
    position.minScrollExtent,
    position.maxScrollExtent,
  );
  if ((target - position.pixels).abs() < 0.5) return;
  // 0 이면 바로 옮긴다 — animateTo 는 0 길이를 받지 않는다
  if (duration == Duration.zero) {
    position.jumpTo(target);
  } else {
    position.animateTo(target, duration: duration, curve: curve);
  }
}
