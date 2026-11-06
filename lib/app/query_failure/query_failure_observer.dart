import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart'
    show ProviderBase, ProviderException;

import 'package:groo_damda_app/app/query_failure/query_failure_marks.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
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
/// 한 조회의 실패를 받아 만드는 조회(`ref.watch(x.future)`)는 같은 오류를 [ProviderException] 으로 감싸 한 번 더 실패한다 —
/// 감싼 원래 오류로 보고, 원래 조회가 폴링 · 참조였으면 그 갈래를 따른다(폴링 값으로 만든 평가액이 스낵바를 띄우지 않게).
final class QueryFailureObserver extends ProviderObserver {
  QueryFailureObserver({
    RefreshFailureNotice? refresh,
    ReferenceFailureNotice? reference,
  }) : refresh = refresh ?? RefreshFailureNotice(),
       reference = reference ?? ReferenceFailureNotice();

  final RefreshFailureNotice refresh;
  final ReferenceFailureNotice reference;

  /// 폴링 · 참조 조회가 낸 오류 — 그 값을 받아 만드는 조회가 같은 오류로 실패하면 같은 갈래로 본다.
  final Expando<bool> _quietErrors = Expando<bool>('query-failure-quiet');

  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    if (newValue is! AsyncValue<Object?>) return;
    final provider = context.provider;
    if (isReferenceProvider(provider)) {
      _markQuiet(newValue);
      reference.update(context.container, provider, newValue);
      return;
    }
    if (newValue.isLoading || !newValue.hasError) return;
    if (isPollingProvider(provider)) {
      _markQuiet(newValue);
      return;
    }
    final error = _origin(newValue.error);
    if (error != null && (_quietErrors[error] ?? false)) return;
    // 값이 없는 처음 받기 실패는 그 자리 Result Section 이 맡는다
    if (!newValue.hasValue) return;
    if (error is ApiException && error.isUnauthorized) return;
    refresh.notify();
  }

  @override
  void didDisposeProvider(ProviderObserverContext context) {
    reference.forget(context.provider);
  }

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
class RefreshFailureNotice {
  RefreshFailureNotice({GlobalKey<PSnackbarHostState>? host})
    : _host = host ?? PSnackbar.appHostKey;

  final GlobalKey<PSnackbarHostState> _host;
  Timer? _gather;
  Timer? _shown;

  void notify() {
    if (_gather != null || _shown != null) return;
    _gather = Timer(kQueryFailureGather, _show);
  }

  void _show() {
    _gather = null;
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
/// - 시트가 열려 있으면 쉰다(그 안이 맡는다) — 모두 닫히면 한 번 다시 판단한다.
/// - [다시 시도] 는 값 없이 실패해 있는 참조 조회만 다시 받는다(지켜보는 화면이 없는 것은 비워 두기만 하고 다음에 읽을 때 받는다).
class ReferenceFailureNotice {
  ReferenceFailureNotice({
    GlobalKey<PSnackbarHostState>? host,
    ValueListenable<int>? openSheets,
  }) : _host = host ?? PSnackbar.appHostKey,
       _openSheets = openSheets ?? pBottomSheetOpenCount {
    _openSheets.addListener(_onSheetsChanged);
  }

  final GlobalKey<PSnackbarHostState> _host;
  final ValueListenable<int> _openSheets;

  /// 값 없이 실패해 있는 참조 조회 → 그 컨테이너.
  final Map<ProviderBase<Object?>, ProviderContainer> _failed = {};
  Timer? _gather;
  Timer? _shown;
  bool _missed = false;

  bool get _held => _openSheets.value > 0;

  void update(
    ProviderContainer container,
    ProviderBase<Object?> provider,
    AsyncValue<Object?> value,
  ) {
    if (value.hasValue) {
      _failed.remove(provider);
      return;
    }
    if (!value.hasError) return;
    _failed[provider] = container;
    // 다시 받는 중(앞 오류를 든 로딩)은 새 실패가 아니다
    if (value.isLoading) return;
    if (_shown != null) {
      _missed = true;
      return;
    }
    _gather ??= Timer(kQueryFailureGather, _show);
  }

  void forget(ProviderBase<Object?> provider) => _failed.remove(provider);

  void _show() {
    _gather = null;
    if (_shown != null || _held || _failed.isEmpty) return;
    final host = _host.currentState;
    final ctx = _host.currentContext;
    if (host == null || ctx == null || !ctx.mounted) return;
    _shown = Timer(PSnackbar.durationWithAction, () {
      _shown = null;
      if (_missed && _gather == null) {
        _missed = false;
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
    if (_held || _gather != null || _shown != null || _failed.isEmpty) return;
    _gather = Timer(kQueryFailureGather, _show);
  }

  void dispose() {
    _openSheets.removeListener(_onSheetsChanged);
    _gather?.cancel();
    _shown?.cancel();
  }
}
