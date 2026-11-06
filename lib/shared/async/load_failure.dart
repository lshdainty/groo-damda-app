import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 불러오기 실패 판정 — 실패 화면(Result Section failure + [다시 시도])을 그릴지 · 그 단추에 진행 원을 걸지를 한 곳에서 정한다.
///
/// - [loadFailed] — 값이 없고 오류가 있다. 이미 받은 값이 있으면 실패가 아니다(가진 내용을 그대로 둔다 — result-section.md:53).
/// - [loadRetrying] — 실패 화면에서 [다시 시도] 를 눌러 다시 받는 중. Riverpod 3 은 다시 받는 동안 앞 오류를 남겨 두므로
///   ([AsyncLoading] + `hasError`) 실패 화면은 그대로 두고 단추만 진행 원으로 바꾼다(skeleton.md:139 · result-section.md:163 —
///   "다시 시도를 누르면 그동안 버튼에 로딩을 건다"). 처음 받는 중(오류 없음)은 실패가 아니다.
extension AsyncLoadFailure<T> on AsyncValue<T> {
  /// 값 없이 실패했다 — 그 자리를 실패 화면으로 그린다.
  bool get loadFailed => !hasValue && hasError;

  /// 실패 화면에서 다시 받는 중 — [다시 시도] 를 loading 으로.
  bool get loadRetrying => loadFailed && isLoading;

  /// 받아 둔 값이 있는 채 다시 받기에 실패했다(riverpod 3 은 앞 값을 든 채 오류가 된다). 폴링 자리는 숫자를 두고 그 자리에
  /// 실패 띠 한 줄을 둔다 — 다음 받기가 성공하면 오류가 걷혀 띠도 사라진다(I-wrap-b2b 4).
  bool get refreshFailed => hasValue && hasError;

  /// 받아 둔 값이 있든 없든 지금 실패 상태다 — 폴링 자리의 실패 띠 조건(처음 실패 · 다시 받기 실패 모두).
  bool get pollFailed => hasError;
}

/// 여러 질의를 한 실패 화면이 맡을 때 — 실패한 것 중 하나라도 다시 받는 중이면 진행 원.
bool anyLoadRetrying(Iterable<AsyncValue<Object?>> values) =>
    values.any((v) => v.loadRetrying);
