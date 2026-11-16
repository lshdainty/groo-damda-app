import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// 넓은 화면의 시작 폭 — groo-design `breakpoint-md`.
const double kWideScreenMinWidth = 768;

/// 넓은 화면에서 본문이 멈추는 폭 — groo-design `layout-max-low`.
const double kContentMaxWidth = 720;

/// 넓은 화면에서 혼자 서는 폼(로그인 등)이 멈추는 폭 — 시트 폭과 같다.
const double kFormMaxWidth = 480;

/// 화면 본문의 **내용 자리**.
///
/// groo-design Layout "Safe Area" · "콘텐츠 폭 — 밀도" 를 한 자리에서 지킨다.
/// - 좌우 안전 영역(가로로 돌린 폰의 노치 · 옆에 상태 칸이 있는 폴더블)을 비운다. 안전 영역은 늘 지금 값을
///   읽으므로 접기 · 펴기 · 돌리기에도 따라간다.
/// - 화면 폭이 [kWideScreenMinWidth] 이상이면 내용을 [maxWidth] 에서 멈추고 가운데에 둔다.
///
/// 바탕은 바깥(띠 · Scaffold)이 화면 끝까지 칠하고, 이 위젯은 내용만 들인다. 이미 처리한 자리 안에서는
/// 다시 들이지 않는다 — 띠 안의 띠, 시트 안의 띠가 두 번 들어가지 않는다.
class PScreenContent extends StatelessWidget {
  const PScreenContent({
    super.key,
    required this.child,
    this.maxWidth = kContentMaxWidth,
  });

  final Widget child;

  /// 넓은 화면에서 내용이 멈추는 폭 — 본문은 [kContentMaxWidth], 혼자 서는 폼은 [kFormMaxWidth].
  final double maxWidth;

  /// 이 아래는 이미 안전 영역 · 폭을 처리했다고 알린다 — 시트처럼 스스로 폭과 안전 영역을 정하는 표면이 쓴다.
  static Widget handled({required Widget child}) =>
      _PScreenContentScope(child: child);

  /// 폭 [availableWidth] 자리에서 내용을 얼마나 들이는지 — 안에서 폭을 먼저 재는 위젯(탭 등)이 같은 값을 뺀다.
  ///
  /// 넓은 화면인지는 화면 폭으로 가르고, 멈추는 폭은 지금 받은 자리 폭에서 잰다 — 이미 좁은 자리를 다시 줄이지 않는다.
  static EdgeInsets insetsOf(
    BuildContext context,
    double availableWidth, {
    double maxWidth = kContentMaxWidth,
  }) {
    if (_PScreenContentScope.of(context)) return EdgeInsets.zero;
    final pad = MediaQuery.paddingOf(context);
    final screen = MediaQuery.sizeOf(context).width;
    final inner = availableWidth - pad.left - pad.right;
    final side =
        availableWidth.isFinite &&
            screen >= kWideScreenMinWidth &&
            inner > maxWidth
        ? (inner - maxWidth) / 2
        : 0.0;
    return EdgeInsets.only(
      left: math.max(0, pad.left + side),
      right: math.max(0, pad.right + side),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_PScreenContentScope.of(context)) return child;
    final inner = _PScreenContentScope(
      child: MediaQuery.removePadding(
        context: context,
        removeLeft: true,
        removeRight: true,
        child: child,
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final insets = insetsOf(
          context,
          constraints.maxWidth,
          maxWidth: maxWidth,
        );
        if (insets == EdgeInsets.zero) return inner;
        return Padding(padding: insets, child: inner);
      },
    );
  }
}

class _PScreenContentScope extends InheritedWidget {
  const _PScreenContentScope({required super.child});

  static bool of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_PScreenContentScope>() != null;

  @override
  bool updateShouldNotify(_PScreenContentScope oldWidget) => false;
}
