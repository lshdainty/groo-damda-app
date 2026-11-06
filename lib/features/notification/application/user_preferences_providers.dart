import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:groo_damda_app/core/format/currency.dart';
import 'package:groo_damda_app/core/network/dio_provider.dart';
import 'package:groo_damda_app/features/notification/data/user_preferences_repository.dart';
import 'package:groo_damda_app/shared/forms/save_failure.dart';

final userPreferencesRepositoryProvider =
    FutureProvider<UserPreferencesRepository>((ref) async {
      final dio = await ref.watch(dioProvider.future);
      return UserPreferencesRepository(dio);
    });

/// 사용자 환경설정 상태 — 낙관적 업데이트(optimistic) Notifier.
///
/// [build] 에서 GET 으로 초기 로드. [patch] 는 호출 즉시 로컬 상태를 갱신해
/// UI 가 바로 반응하고, 그 뒤 PATCH(변경 필드만) 를 보낸다. 실패 시 직전 값으로
/// 조용히 롤백(서버 응답값으로 정정).
/// autoDispose — 화면을 떠나면 상태 폐기, 재진입 시 GET 재조회.
/// (웹 등 다른 클라이언트에서 변경한 값이 다음 진입 때 반영되도록)
final userPreferencesProvider =
    AsyncNotifierProvider.autoDispose<UserPreferencesNotifier, UserPreferences>(
      UserPreferencesNotifier.new,
    );

class UserPreferencesNotifier extends AsyncNotifier<UserPreferences> {
  @override
  Future<UserPreferences> build() async {
    final repo = await ref.watch(userPreferencesRepositoryProvider.future);
    return repo.get();
  }

  /// 부분 갱신 — 낙관적. [optimistic] 으로 즉시 로컬 반영 후 PATCH.
  /// 실패 시 이전 값으로 롤백.
  ///
  /// 돌려주는 값([WriteOutcome]):
  /// - [WriteOutcome.done] — 서버에 들어갔다
  /// - [WriteOutcome.failed] — 닿지 않았거나 거절됐다. 이전 값으로 롤백
  /// - [WriteOutcome.unconfirmed] — 응답을 못 받았다([isUnconfirmedSave]). 들어갔을 수 있으니 **롤백하지 않고** 서버 값을
  ///   다시 받는다(`invalidateSelf`). 알리는 글("바뀌었는지 확인하지 못했어요.")은 부른 쪽 몫(디자인시스템 판단 ②)
  ///
  /// **서버에 실제로 들어갔으면 [WriteOutcome.done].** 이 값을 이 provider 밖에서도 읽는 화면이
  /// 있으면(예산 경고선의 `budgetAlertThresholdProvider`) 저장이 끝난 뒤 그쪽을
  /// 비워야 하는데, 롤백된 저장까지 비우면 바뀌지도 않은 값을 다시 물어보게 된다.
  /// 낙관적 반영은 여기 결과와 무관하게 이미 화면에 나가 있다.
  ///
  /// `await` 뒤의 `state =` 는 **살아 있을 때만** 쓴다. 이 provider 는 autoDispose 라
  /// 설정 화면을 PATCH 도중에 닫으면 마지막 구독자가 사라져 element 가 폐기된다 —
  /// 그 뒤의 `state =` 는 `Ref._throwIfInvalidUsage` 를 타고 `UnmountedRefException`
  /// 을 던진다(riverpod 3.2.1 `core/provider/notifier_provider.dart:89` →
  /// `core/ref.dart:230`). 폐기 여부는 같은 소스가 공개로 내주는 `ref.mounted`
  /// (`core/ref.dart:110`)로 본다.
  ///
  /// **catch 안에서도 본다.** 롤백이 두 번째 예외를 만들면 원래 실패 이유까지 삼킨다.
  /// 어차피 폐기된 상태는 아무도 안 읽고, 재진입 때 `build` 가 다시 GET 한다.
  Future<WriteOutcome> patch(
    Map<String, dynamic> fields, {
    required UserPreferences Function(UserPreferences prev) optimistic,
    bool silent = false,
  }) async {
    final prev = state.value;
    if (prev == null) return WriteOutcome.failed;

    // 낙관적 즉시 반영.
    state = AsyncData(optimistic(prev));
    try {
      final repo = await ref.read(userPreferencesRepositoryProvider.future);
      final updated = await repo.update(fields, silent: silent);
      // 서버엔 들어갔다 — 화면이 사라졌어도 `true` 다. 이 값을 밖에서 읽는
      // 화면(예산 경고선)은 컨테이너로 비우므로 여기 수명과 무관하다.
      if (ref.mounted) state = AsyncData(updated);
      return WriteOutcome.done;
    } catch (e) {
      final outcome = writeOutcomeOf(e);
      if (!ref.mounted) return outcome;
      if (outcome == WriteOutcome.unconfirmed) {
        // 들어갔을 수 있다 — 되돌리지 않고 서버 값을 다시 받는다(받는 동안은 낙관 값이 그대로 보인다)
        ref.invalidateSelf();
      } else {
        // 조용히 롤백.
        state = AsyncData(prev);
      }
      return outcome;
    }
  }
}

/// 새 자산·거래가 처음 고르는 통화 (D7 · QA #124).
///
/// 값의 자리는 계정이다 — `/me/preferences` 의 `defaultCurrency`(desk-back #328).
/// 종전엔 기기에만 있었고 읽는 곳이 하나도 없어서, 고르면 저장된 것처럼만 보였다.
/// 웹도 같은 자리를 읽는다(desk-front #368) — 갈리면 폰에서 고른 값이 브라우저에
/// 안 보인다.
///
/// **아직 안 왔거나 못 읽으면 원화다.** 로그인 전·오프라인·서버가 이 칸을 아직
/// 안 실어 주는 경우 전부 여기로 떨어진다 — 폼이 안 열리는 것보다 낫고, 종전
/// 동작(늘 원화)과 같다.
///
/// `autoDispose` 는 [userPreferencesProvider] 와 같은 수명을 쓰려고 붙였다.
/// 붙이지 않으면 이 provider 가 살아 있는 동안 저쪽도 못 죽어, "화면을 떠나면
/// 폐기하고 재진입 때 다시 읽는다" 는 저쪽 규칙이 조용히 깨진다.
final defaultCurrencyProvider = Provider.autoDispose<String>((ref) {
  return ref.watch(userPreferencesProvider).value?.defaultCurrency ??
      kDefaultCurrency;
});
