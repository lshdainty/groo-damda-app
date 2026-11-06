import 'dart:async';

import 'package:groo_damda_app/app/query_failure/query_failure_observer.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` 는 flutter_riverpod 본체가 아니라 misc 에서 나온다.
import 'package:flutter_riverpod/misc.dart' show Override;

/// 앱의 뿌리 — **로그인한 사람 한 명에 [ProviderScope] 하나.**
///
/// 앱은 로그인한 사람의 데이터만 중계한다. 같은 폰에서 A 가 나가고 B 가 들어왔는데
/// A 앞으로 받아 둔 값이 B 에게 보이면 안 된다 — 증권은 각자의 증권사 키로 받아 온
/// 값이라 더 그렇다.
///
/// ## 왜 비우지 않고 통째로 새로 만드나
///
/// 조회 provider 는 거의 전부 autoDispose 가 아니다. 컨테이너가 살아 있는 한 값을
/// 들고 있고, 누가 비워 주지 않으면 앱을 끌 때까지 그대로다. 그래서 예전엔 A 의
/// 기능권한·보유 종목이 B 의 화면에 그대로 나왔다.
///
/// `ref.invalidate` 로는 못 막는다. riverpod 에서 무효화는 **비우기가 아니라 다시
/// 받기**다 — 다시 받는 동안 이전 값을 `AsyncValue.value` 에 그대로 들고 있고
/// (`isLoading && hasValue`), 새 조회가 실패하면 그 값이 계속 남는다. 그런데 이 앱의
/// 화면은 껌뻑임을 막으려고 "값이 있으면 그대로 그린다" 로 짜여 있다
/// (test/features/tab_stale_while_revalidate_test.dart). 둘이 만나면 B 의 첫 화면에
/// A 의 숫자가 뜬다.
///
/// 비울 목록을 손으로 적는 것도 답이 아니다. 새 provider 를 만들 때마다 목록에 넣는
/// 걸 잊으면 그 값만 조용히 넘어간다.
///
/// 값을 정말로 버리는 방법은 컨테이너를 버리는 것뿐이다. 사람이 바뀌면 [ProviderScope]
/// 의 키를 바꿔 컨테이너를 새로 만든다 — 앞사람 몫은 provider 가 몇 개든, 네트워크를
/// 타든 안 타든 하나도 안 남는다.
///
/// ## 언제 바뀌나
///
/// 판정은 `SessionOwner` 가 하고, 요청은 앱 셸의 auth 리스너가 [sessionRestartProvider]
/// 로 한다. **앞사람과 다른 사람이 로그인했을 때만**이다. 로그아웃만으로는 안 바꾼다 —
/// 로그인 화면은 그 값을 읽지 않고, 같은 사람이 다시 들어오면 그대로 이어 쓴다.
///
/// 새 컨테이너는 앱을 새로 켠 것과 같은 길을 밟는다. 쿠키로 세션을 다시 확인하고
/// (방금 로그인한 사람의 쿠키가 저장돼 있다), 앱 잠금이 켜져 있으면 다시 묻는다.
class SessionScope extends StatefulWidget {
  const SessionScope({
    super.key,
    this.overrides = const [],
    required this.child,
  });

  /// 테스트가 가짜 서버를 끼우는 자리. 컨테이너를 새로 만들 때마다 그대로 다시 건다.
  final List<Override> overrides;

  final Widget child;

  @override
  State<SessionScope> createState() => _SessionScopeState();
}

class _SessionScopeState extends State<SessionScope> {
  /// 몇 번째 컨테이너인가 — 키가 바뀌면 [ProviderScope] 가 통째로 갈린다.
  int _generation = 0;

  /// 조회 실패를 앱 한 자리에서 알린다 — 값이 있는 채 다시 받기 실패 · 참조 실패(I-wrap-b2b 2). 컨테이너가 갈려도 같은 것을 쓴다
  /// (떠 있는 스낵바 · 모으는 시간을 이어 간다).
  final QueryFailureObserver _failureObserver = QueryFailureObserver();

  @override
  void dispose() {
    _failureObserver.dispose();
    super.dispose();
  }

  void _restart() {
    // 한 박자 미룬다. 인증 상태는 서버 응답 뒤에 바뀌므로 보통은 빌드 밖이지만,
    // 빌드 도중에 불리면 setState 가 그 자리에서 던진다. microtask 는 지금 도는 동기
    // 구간(빌드 포함)이 끝난 직후에 돌고, 다음 프레임보다는 늘 먼저다 — 앞사람
    // 컨테이너로 그려지는 프레임이 하나 더 끼지 않는다.
    scheduleMicrotask(() {
      if (!mounted) return;
      // 앞 컨테이너의 실패 · 타이머를 새 계정 화면으로 끌고 가지 않는다(검수 L5)
      _failureObserver.reset();
      setState(() => _generation++);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      key: ValueKey(_generation),
      // Riverpod 의 기본 재시도(최대 10회)는 끈다 — 실패 화면이 열 번 다시 해 본 뒤에야 뜬다. 읽기의 10초 한도 · 1초 · 2초 뒤
      // 두 번 다시 시도는 dio 의 ReadRetryInterceptor 한 곳이 맡는다(skeleton.md "요청 제한 10초").
      retry: appProviderRetry,
      observers: [_failureObserver],
      overrides: [
        ...widget.overrides,
        sessionRestartProvider.overrideWithValue(_restart),
      ],
      child: widget.child,
    );
  }
}

/// 컨테이너를 새로 만들어 달라는 요청.
///
/// [SessionScope] 아래에서만 값이 있다. 맨 `ProviderScope` 로 띄운 화면(위젯 테스트)
/// 에서는 `null` 이고, 그때는 컨테이너를 바꿀 주체가 없다.
final sessionRestartProvider = Provider<VoidCallback?>((ref) => null);

/// 앱의 제공자 재시도 — 하지 않는다. 읽기의 저절로 다시 시도는 네트워크 층(`ReadRetryInterceptor`)이 10초 안에서 맡고, 그 위에서
/// Riverpod 가 또 다시 하면 한도(10초)를 넘기고 쓰기까지 두 번 보낼 수 있다.
Duration? appProviderRetry(int retryCount, Object error) => null;
