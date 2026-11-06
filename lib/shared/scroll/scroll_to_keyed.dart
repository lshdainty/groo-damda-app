import 'package:flutter/widgets.dart';

/// 목록 안의 특정 항목으로 스크롤한다 — **화면 밖이어도 간다.**
///
/// `Scrollable.ensureVisible` 하나로는 안 된다. `ListView` 는 children 을 미리 만들어
/// 두는 것처럼 보이지만 실제 element 는 보이는 범위(+cacheExtent)에만 생긴다. 그래서 멀리
/// 있는 항목의 [GlobalKey.currentContext] 는 **null** 이고, 거기 기대는 호출은 조용히
/// 아무 일도 안 한다 — 사용자 눈에는 "눌러도 반응이 없다" 로 보인다(가계부 달력에서
/// 오래된 날짜를 눌렀을 때 실제로 그랬다, 2026-09-17).
///
/// 그래서 두 단계로 간다.
/// 1. 아직 안 만들어졌으면 **목록에서의 순번 비율**로 대략 위치까지 뛴다. 그러면 그 부근이
///    만들어진다(추정 높이라 정확하지 않아도 된다 — 다음 단계가 맞춘다).
/// 2. 만들어진 뒤 `ensureVisible` 로 정확히 맞춘다.
///
/// 항목 높이가 제각각이라 한 번에 못 닿을 수 있어 [maxHops] 번까지 되풀이한다. 못 닿으면
/// 조용히 포기한다 — 화면이 어디든 멈춰 있는 것이 예외로 죽는 것보다 낫다.
///
/// [targetOf] 를 주면 마지막 맞추기를 `ensureVisible` 대신 그 함수가 돌려준 스크롤 값으로 한다 — 목록 위에 남는 머리가 겹쳐
/// 있으면(원장의 주 달력) 화면 맨 위가 아니라 그 머리 바로 아래에 맞춰야 한다. `null` 을 돌려주면 그대로 둔다.
///
/// **프레임을 `await` 하지 않는다.** 다음 시도를 post-frame 콜백으로 이어 붙인다.
/// `await WidgetsBinding.instance.endOfFrame` 로 쓰면 위젯 테스트에서 교착에 빠진다 —
/// 테스트는 `pump` 로 프레임을 돌리는데, 그 `pump` 를 부르는 쪽이 이 함수를 기다리고 있어
/// 아무도 프레임을 못 돌린다. 호출부는 이 함수를 기다릴 일이 없으므로 반환값도 없다.
void scrollToKeyedItem({
  required ScrollController controller,
  required GlobalKey? key,
  required int index,
  required int count,
  double alignment = 0.02,
  Duration duration = const Duration(milliseconds: 300),
  int maxHops = 8,
  double? Function(BuildContext context)? targetOf,
}) {
  if (key == null || index < 0 || index >= count) return;

  void attempt(int hop) {
    final ctx = key.currentContext;
    if (ctx != null) {
      _settle(ctx, alignment, duration, targetOf);
      return;
    }
    if (hop >= maxHops || !controller.hasClients) return;

    final p = controller.position;
    // `maxScrollExtent` 는 이미 잰 항목들의 평균으로 낸 **추정치**다. 스크롤할수록
    // 정확해지므로, 한 번에 못 닿아도 되풀이하면서 가까워진다.
    final span = p.maxScrollExtent - p.minScrollExtent;
    if (span <= 0) return;
    final ratio = count == 1 ? 0.0 : index / (count - 1);
    final target = (p.minScrollExtent + span * ratio).clamp(
      p.minScrollExtent,
      p.maxScrollExtent,
    );
    // 이미 그 자리인데도 항목이 안 만들어졌다면 더 해 봐야 같은 자리다.
    if ((target - p.pixels).abs() < 1) return;
    p.jumpTo(target);
    // 뛴 자리에서 화면이 한 번 그려져야 그 부근 항목의 element 가 생긴다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!controller.hasClients) return;
      attempt(hop + 1);
    });
  }

  attempt(0);
}

/// 곧 만들어질 항목을 맞춘다 — **몇 프레임 기다려 준다.**
///
/// [scrollToKeyedItem] 과 다르다. 저쪽은 "어디 있는지 모르는 것을 찾아간다" 이고 이쪽은
/// "이미 그 부근까지 왔으니, 만들어지기만 기다린다" 다. 그래서 순번도 컨트롤러도 필요 없다.
///
/// 앞선 그룹 이동이 **여러 프레임에 걸쳐** 끝난다(뛴다 → 다음 프레임 → 다시 시도).
/// 그런데 호출부는 한 프레임 뒤에 한 번만 봤다 — 그 그룹 이동이 두 홉 이상 걸리면 행이
/// 아직 안 만들어져 있고, `Scrollable.ensureVisible` 은 조용히 아무 일도 안 한다.
/// 알림에서 들어온 거래가 화면에 안 걸리는 경우가 그것이다(QA 22차 추정).
///
/// [scrollToKeyedItem] 과 같은 이유로 프레임을 `await` 하지 않는다 — 위젯 테스트가
/// 교착에 빠진다.
void ensureVisibleWhenReady({
  required GlobalKey? key,
  double alignment = 0.2,
  Duration duration = const Duration(milliseconds: 300),
  int maxFrames = 8,
  double? Function(BuildContext context)? targetOf,
}) {
  if (key == null) return;

  void attempt(int frame) {
    final ctx = key.currentContext;
    if (ctx != null) {
      _settle(ctx, alignment, duration, targetOf);
      return;
    }
    if (frame >= maxFrames) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => attempt(frame + 1));
  }

  attempt(0);
}

/// 만들어진 항목을 맞춘다 — [targetOf] 가 있으면 그 값으로, 없으면 `ensureVisible`.
void _settle(
  BuildContext ctx,
  double alignment,
  Duration duration,
  double? Function(BuildContext context)? targetOf,
) {
  if (targetOf == null) {
    Scrollable.ensureVisible(ctx, duration: duration, alignment: alignment);
    return;
  }
  final target = targetOf(ctx);
  if (target == null) return;
  final position = Scrollable.of(ctx).position;
  if ((target - position.pixels).abs() < 0.5) return;
  position.animateTo(target, duration: duration, curve: Curves.ease);
}
