import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart'
    show ProviderBase, ProviderException;

import 'package:groo_damda_app/app/query_failure/query_failure_marks.dart';
import 'package:groo_damda_app/core/lifecycle/screen_visibility.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/pull_to_refresh/p_pull_to_refresh.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';

/// 같은 순간 여러 조회가 함께 실패해도(망 끊김) 한 번만 알리려고 모으는 시간 — 웹 ReferenceFailureNotice GATHER_MS 와 같다.
const Duration kQueryFailureGather = Duration(milliseconds: 300);

/// 조회 실패를 앱 한 자리에서 알리는 관찰자(`ProviderScope.observers`, `app/session_scope.dart`).
///
/// 1. 받아 둔 값이 있는 채 다시 받기에 실패했다 → 보던 내용은 그대로 두고 [RefreshFailureNotice] 가 critical 스낵바
///    "새로 고치지 못했어요." 한 문장([다시 시도] 없음)을 띄운다(result-section.md:53 · skeleton.md:167, I-wrap-b2b 2-1).
///    빼는 것:
///    - 폴링([isPollingProvider] — 그 자리가 알린다, 단계 4)
///    - 구독자 없는 조회(화면을 떠났거나 가려진 탭 — 웹 `getObserversCount() === 0`): riverpod 3 은 지켜보는 화면이 없는
///      조회를 멈춰 두어(paused) 비워도 다시 받지 않는다 — 그래서 그런 조회의 다시 받기 실패가 나지 않는다. 구독자 수를 묻는
///      공개 API 는 없다(`getAllProviderElements` · `ProviderElement.isActive` 는 @internal) — 따로 세지 않는다. 남는 틈은
///      다시 받는 도중에 화면을 떠난 경우뿐이다
///    - 401(로그인 흐름이 맡는다). 403 · 404 는 빼지 않는다 — 다른 기기에서 지운 경우라 보는 내용이 낡았다는 걸 알린다
///    - 참조 조회([isReferenceProvider] — 아래 2 가 맡는다, 둘이 함께 뜨지 않게)
/// 2. 참조 조회가 값 없이 실패했다 → [ReferenceFailureNotice] 가 "일부 정보를 불러오지 못했어요." + [다시 시도].
///
/// 값 없는 처음 받기 실패(참조가 아닌 것)는 여기서 말하지 않는다 — 그 자리 Result Section 이 맡는다.
///
/// 같은 조회(provider · family 인자 단위)가 연달아 실패하면 첫 실패만 알린다 — 한 번 성공하면 다시 센다(디자인시스템 판단 가,
/// 웹과 같은 규칙). 폴링은 지금처럼 빠진다(단계 4 띠가 맡는다).
///
/// 한 조회의 실패를 받아 만드는 조회(`ref.watch(x.future)`)는 같은 오류를 [ProviderException] 으로 감싸 한 번 더 실패한다 —
/// 감싼 원래 오류로 보고, 원래 조회가 폴링 · 참조였으면 그 갈래를 따른다(폴링 값으로 만든 평가액이 스낵바를 띄우지 않게).
final class QueryFailureObserver extends ProviderObserver {
  QueryFailureObserver({
    RefreshFailureNotice? refresh,
    ReferenceFailureNotice? reference,
  }) : refresh = refresh ?? RefreshFailureNotice(),
       reference = reference ?? ReferenceFailureNotice() {
    // 장애 한 번에 critical 스낵바 둘이 잇따르지 않게 — 참조 알림이 떴거나 뜨려는 4초 창 안에서는 새로 고침 스낵바를 띄우지
    // 않는다(웹 검수 L9, 웹과 같다)
    this.refresh.quietWhen = () => this.reference.announcing;
  }

  final RefreshFailureNotice refresh;
  final ReferenceFailureNotice reference;

  /// 폴링 · 참조 조회가 낸 오류 — 그 값을 받아 만드는 조회가 같은 오류로 실패하면 같은 갈래로 본다.
  final Expando<bool> _quietErrors = Expando<bool>('query-failure-quiet');

  /// 지금 실패해 있는 조회 — 한 번 알린 조회는 성공할 때까지 다시 알리지 않는다(판단 가).
  final Set<ProviderBase<Object?>> _failing = {};

  /// 컨테이너를 갈 때(계정 전환 · 세션 재생성) — 떠 있는 타이머 · 붙잡은 실패를 끊는다(검수 L5).
  void reset() {
    _failing.clear();
    refresh.cancel();
    reference.cancel();
  }

  void dispose() {
    refresh.cancel();
    reference.dispose();
  }

  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    // 탭(화면)이 바뀌었다 — 앞 화면에서 붙잡은 참조 실패를 버린다(검수 M1: 지켜보는 조회만 다시 알린다, 구독자 수를 묻는
    // 공개 API 가 없어 화면이 바뀌는 때로 대신한다)
    if (identical(context.provider, activeShellRouteProvider)) {
      reference.clearPending();
      return;
    }
    if (newValue is! AsyncValue<Object?>) return;
    final provider = context.provider;
    // 성공하면 다시 센다(판단 가)
    if (!newValue.hasError && !newValue.isLoading) _failing.remove(provider);
    final error = newValue.hasError ? _origin(newValue.error) : null;
    if (isReferenceProvider(provider)) {
      _markQuiet(newValue);
      // 401 은 로그인 흐름이 맡는다 — 참조 알림도 거른다(검수 L1)
      if (error is ApiException && error.isUnauthorized) {
        reference.forget(provider);
        return;
      }
      reference.update(context.container, provider, newValue);
      return;
    }
    if (newValue.isLoading || !newValue.hasError) return;
    if (isPollingProvider(provider)) {
      _markQuiet(newValue);
      return;
    }
    if (error != null && (_quietErrors[error] ?? false)) return;
    // 값이 없는 처음 받기 실패는 그 자리 Result Section 이 맡는다
    if (!newValue.hasValue) return;
    if (error is ApiException && error.isUnauthorized) return;
    // 같은 조회가 연달아 실패하면 첫 실패만(판단 가)
    if (!_failing.add(provider)) return;
    refresh.notify();
  }

  // didDisposeProvider 는 쓰지 않는다 — riverpod 3 은 invalidate(다시 받기)에도 부른다. 거기서 비우면 "연달아 실패" 를 세지
  // 못한다(판단 가). 붙잡은 실패는 성공 · 탭 이동 · 컨테이너 교체(reset)로 비운다.

  void _markQuiet(AsyncValue<Object?> value) {
    if (!value.hasError) return;
    final error = _origin(value.error);
    if (error != null && _canExpando(error)) _quietErrors[error] = true;
  }

  static Object? _origin(Object? error) {
    var e = error;
    while (e is ProviderException) {
      e = e.exception;
    }
    return e;
  }

  // Expando 는 문자열 · 숫자 · bool · null 에 걸 수 없다
  static bool _canExpando(Object e) =>
      e is! String && e is! num && e is! bool && e is! Record;
}

/// "새로 고치지 못했어요." — 보던 내용이 있는 채 다시 받기에 실패했을 때 critical 스낵바 한 문장([다시 시도] 없음).
///
/// 여러 조회가 함께 실패해도 하나 — [kQueryFailureGather] 동안 모아 한 번 띄우고, 떠 있는 동안([PSnackbar.duration])은
/// 다시 띄우지 않는다.
///
/// 당겨서 새로 고침이 도는 동안([pPullToRefreshInFlight])의 실패는 그 자리가 같은 글 + [다시 시도] 로 알린다 — 여기서는 띄우지
/// 않는다.
class RefreshFailureNotice {
  RefreshFailureNotice({
    GlobalKey<PSnackbarHostState>? host,
    ValueListenable<int>? pullToRefresh,
  }) : _host = host ?? PSnackbar.appHostKey,
       _pullToRefresh = pullToRefresh ?? pPullToRefreshInFlight;

  final GlobalKey<PSnackbarHostState> _host;
  final ValueListenable<int> _pullToRefresh;
  Timer? _gather;
  Timer? _shown;

  /// 참이면 띄우지 않는다 — 같은 장애로 참조 알림이 막 떴거나 뜨려는 때(관찰자가 잇는다).
  bool Function() quietWhen = _never;
  static bool _never() => false;

  void notify() {
    if (_pullToRefresh.value > 0 || quietWhen()) return;
    if (_gather != null || _shown != null) return;
    _gather = Timer(kQueryFailureGather, _show);
  }

  /// 떠 있는 타이머를 끊는다(컨테이너를 갈 때 · 끝낼 때).
  void cancel() {
    _gather?.cancel();
    _gather = null;
    _shown?.cancel();
    _shown = null;
  }

  void _show() {
    _gather = null;
    if (quietWhen()) return;
    final host = _host.currentState;
    final ctx = _host.currentContext;
    if (host == null || ctx == null || !ctx.mounted) return;
    _shown = Timer(PSnackbar.duration, () => _shown = null);
    host.show(
      message: AppLocalizations.of(ctx).queryRefreshFailed,
      tone: PSnackbarTone.critical,
    );
  }
}

/// "일부 정보를 불러오지 못했어요." + [다시 시도] — 참조 조회가 값 없이 실패했을 때(웹 `ReferenceFailureNotice` 의 짝).
///
/// 규칙은 웹과 같다.
/// - [kQueryFailureGather] 동안 모아 한 번. 그사이 다시 받아 성공한 것은 알리지 않는다.
/// - 떠 있는 동안([PSnackbar.durationWithAction] 6초)은 다시 띄우지 않는다. 그 창 안에 새 실패가 있었으면 창이 닫힐 때 한 번
///   다시 판단한다.
/// - 시트가 열려 있거나 화면에 실패 Result Section 이 보이면 쉰다(그 자리가 맡는다) — 모두 사라지면 그동안 들어온 새 실패가
///   있을 때만 띄운다. 탭(화면)이 바뀌면 붙잡은 실패를 버린다(검수 M1).
/// - 같은 조회가 연달아 실패하면 첫 실패만(판단 가). 401 은 거른다(검수 L1).
/// - [다시 시도] 는 값 없이 실패해 있는 참조 조회만 다시 받는다(지켜보는 화면이 없는 것은 비워 두기만 하고 다음에 읽을 때 받는다).
class ReferenceFailureNotice {
  ReferenceFailureNotice({
    GlobalKey<PSnackbarHostState>? host,
    ValueListenable<int>? openSheets,
    ValueListenable<int>? shownFailures,
  }) : _host = host ?? PSnackbar.appHostKey,
       _openSheets = openSheets ?? pBottomSheetOpenCount,
       _shownFailures = shownFailures ?? pResultFailureShown {
    _openSheets.addListener(_onSheetsChanged);
    _shownFailures.addListener(_onSheetsChanged);
  }

  final GlobalKey<PSnackbarHostState> _host;
  final ValueListenable<int> _openSheets;

  /// 화면에 보이는 실패 Result Section 수 — 그 화면이 이미 실패를 말하는 동안은 쉰다(중간 검수 1).
  final ValueListenable<int> _shownFailures;

  /// 값 없이 실패해 있는 참조 조회 → 그 컨테이너.
  final Map<ProviderBase<Object?>, ProviderContainer> _failed = {};

  /// 아직 알리지 않은 새 실패 — 알리면 비운다. 보류가 풀릴 때 · 6초 창이 닫힐 때 이것이 있을 때만 다시 띄운다(검수 M1 —
  /// 앞서 알린 · 다른 화면의 실패로 시트를 닫을 때마다 다시 뜨지 않게). 같은 조회가 연달아 실패해도 처음 한 번만 들어온다
  /// (판단 가 — 성공하면 [_failed] 에서 빠져 다시 센다).
  final Set<ProviderBase<Object?>> _pending = {};
  Timer? _gather;
  Timer? _shown;

  bool get _held => _openSheets.value > 0 || _shownFailures.value > 0;

  /// 막 띄웠거나(4초 창) 띄우려고 모으는 중 — 그동안 공용 새로 고침 스낵바는 쉰다(웹 검수 L9).
  bool get announcing => _gather != null || _recent != null;
  Timer? _recent;

  void update(
    ProviderContainer container,
    ProviderBase<Object?> provider,
    AsyncValue<Object?> value,
  ) {
    if (value.hasValue) {
      _failed.remove(provider);
      _pending.remove(provider);
      return;
    }
    if (!value.hasError) return;
    // 다시 받는 중(앞 오류를 든 로딩)은 새 실패가 아니다
    if (value.isLoading) {
      _failed[provider] = container;
      return;
    }
    // 이미 실패해 있던 조회가 또 실패했다 — 첫 실패만 알린다(판단 가)
    if (_failed.containsKey(provider)) return;
    _failed[provider] = container;
    _pending.add(provider);
    if (_shown != null || _held) return;
    _gather ??= Timer(kQueryFailureGather, _show);
  }

  void forget(ProviderBase<Object?> provider) {
    _failed.remove(provider);
    _pending.remove(provider);
  }

  /// 화면(탭)이 바뀌었다 — 앞 화면의 실패는 다시 알리지 않는다(검수 M1).
  void clearPending() {
    _pending.clear();
    _failed.clear();
    _gather?.cancel();
    _gather = null;
  }

  void _show() {
    _gather = null;
    if (_shown != null || _held || _pending.isEmpty) return;
    final host = _host.currentState;
    final ctx = _host.currentContext;
    if (host == null || ctx == null || !ctx.mounted) return;
    _pending.clear();
    _recent?.cancel();
    _recent = Timer(PSnackbar.duration, () => _recent = null);
    _shown = Timer(PSnackbar.durationWithAction, () {
      _shown = null;
      // 창 안에 새 실패가 있었으면 창이 닫힐 때 한 번 다시 판단한다
      if (_pending.isNotEmpty && _gather == null) {
        _gather = Timer(kQueryFailureGather, _show);
      }
    });
    final l = AppLocalizations.of(ctx);
    host.show(
      message: l.queryReferenceFailed,
      tone: PSnackbarTone.critical,
      action: PSnackbarAction(label: l.actionRetry, onPressed: _retry),
    );
  }

  void _retry() {
    for (final e in _failed.entries.toList()) {
      e.value.invalidate(e.key);
    }
  }

  void _onSheetsChanged() {
    if (_held || _gather != null || _shown != null || _pending.isEmpty) return;
    _gather = Timer(kQueryFailureGather, _show);
  }

  /// 타이머 · 붙잡은 실패를 끊는다(컨테이너를 갈 때, 검수 L5).
  void cancel() {
    _gather?.cancel();
    _gather = null;
    _shown?.cancel();
    _shown = null;
    _recent?.cancel();
    _recent = null;
    _failed.clear();
    _pending.clear();
  }

  void dispose() {
    _openSheets.removeListener(_onSheetsChanged);
    _shownFailures.removeListener(_onSheetsChanged);
    cancel();
  }
}
