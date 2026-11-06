import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:groo_damda_app/core/settings/hide_amounts_cards.dart';
import 'package:groo_damda_app/core/storage/prefs_provider.dart';
import 'package:groo_damda_app/core/settings/hide_cards_repository.dart';
import 'package:groo_damda_app/core/settings/user_locale.dart';
import 'package:groo_damda_app/shared/forms/save_failure.dart';

/// 사용자 표시 설정 모음.
class AppSettings {
  const AppSettings({
    required this.themeMode,
    required this.hideCards,
    required this.locale,
    required this.appLock,
  });

  final ThemeMode themeMode;

  /// 앱을 열 때 생체인증(Face ID·지문)으로 잠글지. 기기 로컬 설정이다 —
  /// 잠금은 이 기기의 생체 등록에 묶이므로 서버·다른 클라이언트와 공유하지 않는다.
  final bool appLock;

  /// 지금 가려 둔 카드들. 비어 있으면 아무것도 안 가린 상태다.
  /// 카드 목록은 [kHideCards] 에 있다.
  final Set<String> hideCards;

  /// 하나라도 가려져 있는가 — 눈 아이콘처럼 "지금 가린 게 있나" 만 보는 자리용.
  bool get hasHidden => hideCards.isNotEmpty;

  bool isHidden(String card) => hideCards.contains(card);

  /// `null` = 시스템 로케일 따름. 그 외 'ko'/'en'.
  final Locale? locale;

  static const defaults = AppSettings(
    themeMode: ThemeMode.system,
    hideCards: <String>{},
    locale: null,
    appLock: false,
  );

  AppSettings copyWith({
    ThemeMode? themeMode,
    Set<String>? hideCards,
    Object? locale = _sentinel,
    bool? appLock,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      hideCards: hideCards ?? this.hideCards,
      locale: identical(locale, _sentinel) ? this.locale : locale as Locale?,
      appLock: appLock ?? this.appLock,
    );
  }
}

const _sentinel = Object();

/// 저장된 카드 목록을 읽는다.
///
/// 예전 사용자는 "전부 가림" 상태였다 — 켜져 있었으면 그대로 전부 켠 채로 옮긴다.
/// 안 그러면 업데이트하자마자 금액이 통째로 드러난다.
Set<String> _loadHideCards(SharedPreferences prefs) {
  final legacy = prefs.getBool(PrefsKeys.hideAmounts);
  if (legacy != null) {
    prefs.remove(PrefsKeys.hideAmounts);
    final migrated = legacy ? kAllHideCards.toSet() : <String>{};
    prefs.setStringList(PrefsKeys.hideCards, migrated.toList());
    return migrated;
  }
  final saved = prefs.getStringList(PrefsKeys.hideCards) ?? const <String>[];
  // 없어진 카드 키는 버린다 — 남겨 두면 영영 못 지우는 유령이 된다.
  return saved.where(kHideCards.containsKey).toSet();
}

/// 이 카드가 가려져 있는가. 화면에서 `masked:` 에 그대로 넘긴다.
final hideCardProvider = Provider.family<bool, String>((ref, card) {
  return ref.watch(settingsProvider).value?.isHidden(card) ?? false;
});

/// 하나라도 가려져 있는가 — 눈 아이콘 표시용.
final anyHiddenProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).value?.hasHidden ?? false;
});

/// SharedPreferences 와 양방향 sync 되는 표시 설정 Notifier.
final settingsProvider = AsyncNotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    final prefs = await ref.watch(prefsProvider.future);
    final loc = _parseLocale(prefs.getString(PrefsKeys.locale));
    UserLocale.current = loc;
    // 숫자·날짜 포맷터가 참조하는 전역 로케일 배선. 미선택(시스템)이면 ko 로 폴백
    // → 기존 출력 회귀 0. 명시적으로 en 을 고른 경우에만 영어 포맷.
    Intl.defaultLocale = loc?.languageCode ?? 'ko';
    return AppSettings(
      themeMode: _parseTheme(prefs.getString(PrefsKeys.themeMode)),
      hideCards: _loadHideCards(prefs),
      locale: loc,
      appLock: prefs.getBool(PrefsKeys.appLock) ?? AppSettings.defaults.appLock,
    );
  }

  /// 켜는 쪽은 호출 전에 생체인증을 한 번 통과시킬 것(화면 책임) — 인증 수단이
  /// 없는 기기에서 켜지면 다음 실행부터 앱을 못 연다.
  Future<void> setAppLock(bool on) async {
    final prefs = await ref.read(prefsProvider.future);
    await prefs.setBool(PrefsKeys.appLock, on);
    state = AsyncData(_current.copyWith(appLock: on));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await ref.read(prefsProvider.future);
    await prefs.setString(PrefsKeys.themeMode, _serializeTheme(mode));
    state = AsyncData(_current.copyWith(themeMode: mode));
  }

  /// 가리기 — 인증 없이 자유롭게 켠다. 푸는 쪽만 인증을 받는다(화면 책임).
  ///
  /// 금액 가리기를 바꾸는 호출은 모두 **서버가 받아야 로컬에 반영**되고, 결과([WriteOutcome])를 돌려준다
  /// ([WriteOutcome.failed] 면 로컬도 그대로다 — 호출한 쪽이 자기 자리에서 알린다. [WriteOutcome.unconfirmed] 면 서버 값을
  /// 다시 받아 로컬을 맞췄다 — 받지 못하면 로컬 그대로).
  Future<WriteOutcome> hideCards(Iterable<String> cards) =>
      _writeHideCards({..._current.hideCards, ...cards});

  /// 풀기 — 호출 전에 인증을 거칠 것.
  Future<WriteOutcome> revealCards(Iterable<String> cards) =>
      _writeHideCards({..._current.hideCards}..removeAll(cards));

  /// 고른 결과를 통째로 반영한다 — 화면에서 여러 장을 조정한 뒤 한 번에 저장하는 경로.
  ///
  /// 푸는 카드가 섞여 있으면 호출 전에 인증을 거칠 것(화면 책임). 한 장씩 켜고 끄는
  /// [hideCards]/[revealCards] 와 달리 이전 상태를 남기지 않고 그대로 덮는다.
  Future<WriteOutcome> setHideCards(Set<String> next) =>
      _writeHideCards({...next});

  Future<WriteOutcome> hideAllCards() => hideCards(kAllHideCards);

  Future<WriteOutcome> revealAllCards() => _writeHideCards(<String>{});

  /// 서버에 먼저 올리고, **받아졌을 때만** 로컬에 반영한다.
  ///
  /// 예전에는 로컬을 먼저 바꾸고 서버 저장을 기다리지 않았다 — 저장이 실패하면 이 기기에만 반영돼, 다음 동기화
  /// ([syncHideCardsFromServer])가 서버의 옛 값으로 로컬을 덮어 가려 둔 금액이 사용자 모르게 다시 드러났다.
  /// 실패하면 로컬을 건드리지 않으므로 서버와 로컬이 어긋나지 않고, 알리는 일은 호출한 쪽이 맡는다.
  ///
  /// 응답을 못 받았으면([WriteOutcome.unconfirmed]) 서버가 받았을 수 있다 — 짐작으로 로컬을 바꾸지 않고 서버 값을 다시 받아
  /// 맞춘다([_resyncHideCards]). 받지 못하면 로컬 그대로다(가림을 풀었을지 모르는 값으로 드러내지 않는다).
  Future<WriteOutcome> _writeHideCards(Set<String> next) async {
    final outcome = await _putToServer(next);
    switch (outcome) {
      case WriteOutcome.done:
        await _writeHideCardsLocal(next);
      case WriteOutcome.unconfirmed:
        await _resyncHideCards();
      case WriteOutcome.failed:
        break;
    }
    return outcome;
  }

  /// 서버 값을 받아 로컬에 덮는다 — 응답을 못 받은 저장 뒤. 받지 못하거나 아직 한 번도 안 올렸으면(`null`) 그대로 둔다.
  Future<void> _resyncHideCards() async {
    List<String>? server;
    try {
      final repo = await ref.read(hideCardsRepositoryProvider.future);
      server = await repo.fetch();
    } catch (_) {
      return;
    }
    if (server == null) return;
    await _writeHideCardsLocal(server.where(kHideCards.containsKey).toSet());
  }

  /// 로컬에만 반영한다. 서버에서 받아온 값을 되쏘지 않으려고 갈라 뒀다.
  Future<void> _writeHideCardsLocal(Set<String> next) async {
    final prefs = await ref.read(prefsProvider.future);
    await prefs.setStringList(PrefsKeys.hideCards, next.toList());
    state = AsyncData(_current.copyWith(hideCards: next));
  }

  /// 서버로 올린다(조용한 요청 — 실패를 이 함수가 알리지 않고 결과로 돌려준다).
  Future<WriteOutcome> _putToServer(Set<String> next) async {
    try {
      final repo = await ref.read(hideCardsRepositoryProvider.future);
      await repo.put(next);
      return WriteOutcome.done;
    } catch (e) {
      return writeOutcomeOf(e);
    }
  }

  /// 로그인 직후 서버와 맞춘다.
  ///
  /// **서버가 `null` 이면 내려받지 않고 로컬을 올린다.** `null` 은 "아직 한 번도 안 올림"
  /// 이라 그걸 빈 목록으로 받아 덮으면, 이 기능이 나가는 순간 **가려 뒀던 금액이 통째로
  /// 드러난다.** 사용자가 실제로 다 푼 상태는 `[]` 로 따로 온다.
  ///
  /// 다른 사용자가 쓰던 기기면 로컬을 올리지 않는다 — 남의 가림 설정이 내 계정에 붙는다.
  Future<void> syncHideCardsFromServer(String userId) async {
    final prefs = await ref.read(prefsProvider.future);
    final mine = prefs.getString(PrefsKeys.hideCardsOwner) == userId;

    List<String>? server;
    try {
      final repo = await ref.read(hideCardsRepositoryProvider.future);
      server = await repo.fetch();
    } catch (_) {
      // 못 받아왔으면 로컬 그대로 둔다 — 여기서 비우면 금액이 드러난다.
      return;
    }

    await prefs.setString(PrefsKeys.hideCardsOwner, userId);

    if (server == null) {
      // 첫 동기화는 **업로드**다. 단, 남의 기기 캐시는 올리지 않는다.
      final local = mine ? _current.hideCards : <String>{};
      if (!mine) await _writeHideCardsLocal(local);
      // 여기서는 기다린다 — 부팅 중 한 번뿐이고, 동기화가 끝났는지 호출부가 알 수 있어야 한다.
      // **의도된 무음**: 이 첫 올리기가 실패해도 알리지 않는다 — 사용자가 한 일이 아니고, 서버가 계속 null 이라
      // 다음 부팅의 동기화가 같은 값을 다시 올린다(그 사이 덮어쓸 서버 값이 없어 드러나는 금액도 없다).
      await _putToServer(local);
      return;
    }

    // 서버에서 받은 값은 되쏘지 않는다 — 부르자마자 PUT 이 나가는 왕복이 생긴다.
    // 모르는 카드 키는 버린다(로컬 규칙과 같다).
    await _writeHideCardsLocal(server.where(kHideCards.containsKey).toSet());
  }

  /// [locale] = `null` 이면 시스템 로케일을 따른다.
  Future<void> setLocale(Locale? locale) async {
    final prefs = await ref.read(prefsProvider.future);
    if (locale == null) {
      await prefs.remove(PrefsKeys.locale);
    } else {
      await prefs.setString(PrefsKeys.locale, locale.languageCode);
    }
    UserLocale.current = locale;
    Intl.defaultLocale = locale?.languageCode ?? 'ko';
    state = AsyncData(_current.copyWith(locale: locale));
  }

  AppSettings get _current => state.value ?? AppSettings.defaults;

  static ThemeMode _parseTheme(String? raw) => switch (raw) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
  static String _serializeTheme(ThemeMode m) => switch (m) {
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
    ThemeMode.system => 'system',
  };
  static Locale? _parseLocale(String? raw) => switch (raw) {
    'ko' => const Locale('ko'),
    'en' => const Locale('en'),
    _ => null,
  };
}
