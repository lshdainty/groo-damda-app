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
}

/// 여러 질의를 한 실패 화면이 맡을 때 — 실패한 것 중 하나라도 다시 받는 중이면 진행 원.
bool anyLoadRetrying(Iterable<AsyncValue<Object?>> values) =>
    values.any((v) => v.loadRetrying);
