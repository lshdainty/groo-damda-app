import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:groo_damda_app/core/clock/clock.dart';

/// 상대시각 해상도 — "n분 전" 이 최소 단위라 1분마다만 다시 그리면 충분하다.
///
/// 웹(`useNow`)의 `DEFAULT_INTERVAL_MS = 60_000` 과 **같은 값**이어야 한다.
/// 해상도가 갈리면 같은 알림이 웹에선 "3분 전", 앱에선 "2분 전" 으로 보인다.
const nowTickInterval = Duration(minutes: 1);

/// 벽시계 눈금으로 내림한 "지금" — 웹 `useNow` 의 `alignedNow()` 정합.
///
/// **해상도를 맞추는 것만으로는 부족하다.** 앱은 화면을 연 순간부터, 웹은 페이지를 연
/// 순간부터 1분을 세면 두 시계의 *위상*이 어긋나, 같은 알림이 앱 "2분 전" · 웹 "3분 전" 이
/// 된다(실측 17%). 양쪽 다 절대 시각의 눈금에 내림하면 마운트 시점과 무관하게 같은 값이 된다.
DateTime alignedNow([DateTime Function()? clock]) {
  final step = nowTickInterval.inMilliseconds;
  final ms = (clock ?? DateTime.now)().millisecondsSinceEpoch;
  return DateTime.fromMillisecondsSinceEpoch(ms ~/ step * step);
}

/// 흐르는 "지금" — [nowTickInterval] 마다 갱신되는 현재 시각.
///
/// 상대시각("3분 전")을 그리는 화면에는 기준점이 필요한데, build 안에서
/// [DateTime.now] 를 직접 부르면 그 값은 **화면을 다시 그릴 때만** 바뀐다.
/// 앱에서 알림 목록을 다시 그리게 하는 건 `notificationListProvider` invalidate 뿐이고
/// 그건 새 알림이 실제로 왔을 때만 걸리므로(`notification_stream_service` 의 `fresh`),
/// 화면을 열어 둔 채로는 시계가 "방금" 에 얼어붙는다. 웹은 `useNow()` 로 흐르는데
/// 앱만 멈추면 같은 알림이 두 화면에서 다른 문구로 보인다.
///
/// 기준점을 provider 로 뽑아 둔 건 여러 화면이 **같은 '지금'** 을 보게 하려는 것이다 —
/// 화면마다 각자 타이머를 돌리면 틱 위상이 어긋나 같은 알림이 한쪽에선 "2분 전",
/// 다른 쪽에선 "3분 전" 이 된다.
class NowTick extends Notifier<DateTime> {
  @override
  DateTime build() {
    final clock = ref.read(clockProvider);
    final timer = Timer.periodic(
      nowTickInterval,
      (_) => state = alignedNow(clock),
    );
    // 앱이 백그라운드로 가면 엔진이 이벤트 루프를 세워 타이머가 안 돈다 —
    // 돌아온 직후 최대 1분 동안 나갈 때의 시각이 그대로 보이므로 한 번 더 맞춘다.
    // 웹 `useNow` 의 `visibilitychange` 재동기화와 같은 자리다.
    final lifecycle = AppLifecycleListener(
      onResume: () => state = alignedNow(clock),
    );
    ref.onDispose(() {
      timer.cancel();
      lifecycle.dispose();
    });
    return alignedNow(clock);
  }
}

/// 상대시각의 기준 시각. 보는 화면이 하나도 없으면 타이머까지 정리된다(autoDispose) —
/// 알림 화면을 닫고도 1분마다 깨어나 배터리를 쓰는 일이 없다.
final nowTickProvider = NotifierProvider.autoDispose<NowTick, DateTime>(
  NowTick.new,
);
