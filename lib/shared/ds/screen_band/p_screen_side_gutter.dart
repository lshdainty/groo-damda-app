import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';

/// 화면의 **좌우 안전 영역 칸** — groo-design Layout "Safe Area".
///
/// 좌우 안전 영역(가로로 돌린 폰의 노치 · iPhone Duo 처럼 옆에 선 상태 칸)에는 화면의 면(상단 바 · 띠 · 카드 · 탭 줄 ·
/// 배너)을 칠하지 않는다. 그 자리는 뒷배경 `bg-layer-basement` 만 보이고, 화면 전체는 안쪽에 선다. 위 · 아래 안전 영역은
/// 그대로 — 상단 바는 위 상태 표시줄 밑까지, 목록은 홈 표시줄 밑까지 간다.
///
/// 안쪽에서는 좌우 안전 영역을 0 으로 알린다 — 안쪽 부품이 다시 비우지 않는다. 시트 · 확인창은 화면 위에 떠서 이 칸
/// 밖([PopupRoute])이라 지금처럼 스스로 안전 영역을 정한다.
class PScreenSideGutter extends StatelessWidget {
  const PScreenSideGutter({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    if (pad.left <= 0 && pad.right <= 0) return child;
    return ColoredBox(
      key: const ValueKey('screen-side-gutter'),
      color: context.colors.bgLayerBasement,
      child: Padding(
        padding: EdgeInsets.only(left: pad.left, right: pad.right),
        child: MediaQuery.removePadding(
          context: context,
          removeLeft: true,
          removeRight: true,
          child: child,
        ),
      ),
    );
  }
}

/// 모든 화면 라우트가 [PScreenSideGutter] 를 지나게 하는 전환 — 플랫폼 기본 전환([inner])을 그대로 쓰고, 화면만 칸 안에 둔다.
/// 칸은 화면과 함께 움직인다(밀려 들어오는 화면도 같은 칸을 가진다).
class PSideGutterPageTransitionsBuilder extends PageTransitionsBuilder {
  const PSideGutterPageTransitionsBuilder(this.inner);

  final PageTransitionsBuilder inner;

  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      inner.delegatedTransition;

  @override
  Duration get transitionDuration => inner.transitionDuration;

  @override
  Duration get reverseTransitionDuration => inner.reverseTransitionDuration;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => inner.buildTransitions<T>(
    route,
    context,
    animation,
    secondaryAnimation,
    PScreenSideGutter(child: child),
  );
}

/// 플랫폼 기본 전환에 [PScreenSideGutter] 를 씌운 테마 — Flutter 기본 목록과 같은 짝.
const PageTransitionsTheme kSideGutterPageTransitionsTheme =
    PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: PSideGutterPageTransitionsBuilder(
          PredictiveBackPageTransitionsBuilder(),
        ),
        TargetPlatform.iOS: PSideGutterPageTransitionsBuilder(
          CupertinoPageTransitionsBuilder(),
        ),
        TargetPlatform.macOS: PSideGutterPageTransitionsBuilder(
          CupertinoPageTransitionsBuilder(),
        ),
        TargetPlatform.windows: PSideGutterPageTransitionsBuilder(
          ZoomPageTransitionsBuilder(),
        ),
        TargetPlatform.linux: PSideGutterPageTransitionsBuilder(
          ZoomPageTransitionsBuilder(),
        ),
      },
    );
