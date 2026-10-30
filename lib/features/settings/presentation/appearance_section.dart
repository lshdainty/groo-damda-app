import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/settings/regions.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/features/notification/application/user_preferences_providers.dart';
import 'package:groo_damda_app/features/notification/data/user_preferences_repository.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/card/p_card_parts.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';
import 'package:groo_damda_app/shared/ds/text_button/p_text_button.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';
import 'package:groo_damda_app/shared/forms/list_bleed_target.dart';
import 'package:groo_damda_app/shared/widgets/p_snack_bar.dart';

/// 표시 설정 화면 — 흰 화면 하나(I-14 4-C · 14-1). 머리 = ds 상단 바(← + 제목).
class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      // 흰 화면 하나 — 띠 · 회색 바닥이 없다(T8 · T9)
      backgroundColor: context.colors.bgLayerDefault,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(PTopNavigation.heightOf(context)),
        child: PTopNavigation(
          title: l.appearanceTitle,
          leading: PTopNavigationIconButton.back(
            label: l.actionBack,
            onPressed: () => context.pop(),
          ),
        ),
      ),
      body: ListView(
        key: const ValueKey('appearance-body'),
        // 상단 바 ↔ 첫 줄 12(T8) · 끝 24 + 안전 영역
        padding: EdgeInsets.only(
          top: PSpacing.x3,
          bottom: PSpacing.x6 + MediaQuery.paddingOf(context).bottom,
        ),
        children: const [AppearanceSection()],
      ),
    );
  }
}

/// 고를 수 있는 통화는 서버 `SupportedCurrency` 와 같은 넷이다(웹과 같다).
const _kCurrencies = [('KRW', '₩'), ('USD', r'$'), ('EUR', '€'), ('JPY', '¥')];

/// 표시 설정 — 값 줄 넷(테마 · 언어 · 기준 지역 · 기본 통화). 줄은 지금 값을 보이고, 누르면 고르기 시트가 열려
/// 고르는 순간 바뀌고 닫힌다(꺾쇠 없음 — 화면을 옮기지 않는다). 웹 `AppearanceSection` 의 폰 갈래와 같은 줄 · 같은 글이다.
///
/// 테마 · 언어는 이 기기 값이라 기다림이 없다. 지역 · 통화는 서버 값이라 받는 동안 값 자리 Skeleton + 누름 막힘,
/// 실패하면 설명 자리 안내 + [다시 시도](원화로 그리지 않는다). 바꾸기 실패는 고정 글 알림이고 값은 이전으로 돌아간다.
///
/// 개인정보 보호(앱 잠금·금액 가리기)는 계정 > 보안에 있다 — 인증·잠금은 한자리에.
class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key});

  static String _themeName(AppLocalizations l, ThemeMode m) => switch (m) {
    ThemeMode.light => l.appearanceThemeLight,
    ThemeMode.dark => l.appearanceThemeDark,
    ThemeMode.system => l.appearanceThemeSystem,
  };

  static String _currencyName(AppLocalizations l, String code) =>
      switch (code) {
        'KRW' => l.appearanceCurrencyKrw,
        'USD' => l.appearanceCurrencyUsd,
        'EUR' => l.appearanceCurrencyEur,
        'JPY' => l.appearanceCurrencyJpy,
        _ => code,
      };

  /// 고르기 시트 — 제목 = 줄 제목 · 위 닫기 원 · 바닥 버튼 없음 · 바깥 누름 · 끌어내림으로 닫힌다.
  Future<void> _sheet(
    BuildContext context,
    String title,
    Widget Function(BuildContext sheetContext) body, {
    bool scrollFog = false,
  }) {
    final l = AppLocalizations.of(context);
    return PBottomSheet.show<void>(
      context,
      builder: (ctx) => PBottomSheetContent(
        title: title,
        closeLabel: l.actionClose,
        flushBody: true,
        // 넘치는 목록(지역 18)만 끝 흐림 — 위 20 · 아래 80. 줄이 셋 · 넷인 고르기는 끈다
        scrollFog: scrollFog,
        body: Builder(builder: body),
      ),
    );
  }

  Future<void> _savePref(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> fields,
    UserPreferences Function(UserPreferences prev) optimistic,
  ) async {
    final l = AppLocalizations.of(context);
    final ok = await ref
        .read(userPreferencesProvider.notifier)
        .patch(fields, optimistic: optimistic);
    if (!ok && context.mounted) {
      showPSnackBar(
        context,
        l.appearanceSaveFailed,
        severity: PSnackSeverity.error,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider).value ?? AppSettings.defaults;
    final prefsAsync = ref.watch(userPreferencesProvider);
    final prefs = prefsAsync.value;
    final loading = prefsAsync.isLoading && prefs == null;
    final failed = prefsAsync.hasError && prefs == null;
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    final langChoice = settings.locale?.languageCode ?? 'system';
    final langName = switch (langChoice) {
      'ko' => l.languageKorean,
      'en' => l.languageEnglish,
      _ => l.languageSystem,
    };
    final regionOptions = regionOptionsWith(prefs?.timezone);
    String? regionName;
    for (final o in regionOptions) {
      if (o.value == prefs?.timezone) regionName = isEn ? o.en : o.ko;
    }
    void retry() => ref.invalidate(userPreferencesProvider);

    return PList(
      semanticLabel: l.appearanceTitle,
      children: [
        // 테마
        _ChoiceRow(
          icon: LucideIcons.sun,
          title: l.appearanceTheme,
          value: _themeName(l, settings.themeMode),
          onTap: () => _sheet(
            context,
            l.appearanceTheme,
            (ctx) => PListRadioGroup<ThemeMode>(
              semanticLabel: l.appearanceTheme,
              value: settings.themeMode,
              onChanged: (m) {
                PBottomSheet.of(ctx).close();
                ref.read(settingsProvider.notifier).setThemeMode(m);
              },
              children: [
                for (final (m, icon, label, desc) in [
                  (
                    ThemeMode.light,
                    LucideIcons.sun,
                    l.appearanceThemeLight,
                    l.appearanceThemeLightDesc,
                  ),
                  (
                    ThemeMode.dark,
                    LucideIcons.moon,
                    l.appearanceThemeDark,
                    l.appearanceThemeDarkDesc,
                  ),
                  (
                    ThemeMode.system,
                    LucideIcons.monitor,
                    l.appearanceThemeSystem,
                    l.appearanceThemeSystemDesc,
                  ),
                ])
                  PListRadioItem<ThemeMode>(
                    value: m,
                    prefix: ExcludeSemantics(child: Icon(icon)),
                    title: label,
                    detail: desc,
                  ),
              ],
            ),
          ),
        ),
        // 언어
        _ChoiceRow(
          icon: LucideIcons.globe,
          title: l.settingsLanguage,
          value: langName,
          onTap: () => _sheet(
            context,
            l.settingsLanguage,
            (ctx) => PListRadioGroup<String>(
              semanticLabel: l.settingsLanguage,
              value: langChoice,
              onChanged: (v) {
                PBottomSheet.of(ctx).close();
                final n = ref.read(settingsProvider.notifier);
                switch (v) {
                  case 'ko':
                    n.setLocale(const Locale('ko'));
                  case 'en':
                    n.setLocale(const Locale('en'));
                  default:
                    n.setLocale(null);
                }
              },
              children: [
                PListRadioItem<String>(
                  value: 'system',
                  title: l.languageSystem,
                ),
                PListRadioItem<String>(value: 'ko', title: l.languageKorean),
                PListRadioItem<String>(value: 'en', title: l.languageEnglish),
              ],
            ),
          ),
        ),
        // 기준 지역 — 서버에 저장한다: 서버가 이 값으로 "오늘"을 판단하므로 로컬에만 두면 표기와 계산이 어긋난다.
        _ChoiceRow(
          icon: LucideIcons.mapPin,
          title: l.appearanceRegion,
          detail: l.appearanceRegionDesc,
          value: regionName,
          loading: loading,
          failed: failed,
          failedText: l.appearanceRegionLoadError,
          retryLabel: l.actionRetry,
          onRetry: retry,
          onTap: prefs == null
              ? null
              : () => _sheet(
                  context,
                  l.appearanceRegion,
                  (ctx) => PListRadioGroup<String>(
                    semanticLabel: l.appearanceRegion,
                    value: prefs.timezone,
                    onChanged: (tz) {
                      PBottomSheet.of(ctx).close();
                      if (tz == prefs.timezone) return;
                      _savePref(context, ref, {
                        'timezone': tz,
                      }, (prev) => prev.copyWith(timezone: tz));
                    },
                    children: [
                      for (final o in regionOptions)
                        PListRadioItem<String>(
                          value: o.value,
                          title: isEn ? o.en : o.ko,
                        ),
                    ],
                  ),
                  scrollFog: true,
                ),
        ),
        // 기본 통화 — 서버에 보관한다(D7 · QA #124). 받기 전에는 값 글을 비워 둔다(원화로 그리지 않는다).
        _ChoiceRow(
          icon: LucideIcons.coins,
          title: l.appearanceCurrency,
          detail: l.appearanceCurrencyDesc,
          value: prefs == null ? null : _currencyName(l, prefs.defaultCurrency),
          loading: loading,
          failed: failed,
          failedText: l.appearanceCurrencyLoadError,
          retryLabel: l.actionRetry,
          onRetry: retry,
          onTap: prefs == null
              ? null
              : () => _sheet(
                  context,
                  l.appearanceCurrency,
                  (ctx) => PListRadioGroup<String>(
                    semanticLabel: l.appearanceCurrency,
                    value: prefs.defaultCurrency,
                    onChanged: (code) {
                      PBottomSheet.of(ctx).close();
                      if (code == prefs.defaultCurrency) return;
                      _savePref(context, ref, {
                        'defaultCurrency': code,
                      }, (prev) => prev.copyWith(defaultCurrency: code));
                    },
                    children: [
                      for (final (code, symbol) in _kCurrencies)
                        PListRadioItem<String>(
                          value: code,
                          // 앞 = 22 칸 기호 글자(t5 · 700)
                          prefix: ExcludeSemantics(
                            child: SizedBox.square(
                              dimension: 22,
                              child: Center(
                                child: Text(
                                  symbol,
                                  style: PTypography.t5.copyWith(
                                    color: context.colors.fgNeutral,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          title: _currencyName(l, code),
                          detail: code,
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

/// 값 줄 하나 — 아이콘 22 · 제목 · (설명) · 지금 값(줄 끝 오른쪽 맞춤). 줄 전체가 버튼이고 꺾쇠가 없다.
/// 설명이 있는 줄은 위에 맞춘다(줄마다 내용이 달라 그림대로). 막힌 줄([onTap] 없음)은 값 자리에 Skeleton.
class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.detail,
    this.value,
    this.loading = false,
    this.failed = false,
    this.failedText,
    this.retryLabel,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String? detail;
  final String? value;
  final bool loading;
  final bool failed;
  final String? failedText;
  final String? retryLabel;
  final VoidCallback? onRetry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final prefix = ExcludeSemantics(child: Icon(icon));
    if (failed) {
      // 실패 — 설명 자리에 안내 + [다시 시도]. 줄은 누르지 않는다.
      return PTouchTargetScope(
        child: PListItem(
          align: PListAlign.top,
          prefix: prefix,
          title: title,
          detail: failedText,
          suffix: PListAction(
            child: ListBleedTarget(
              bleed: kTextButtonPaddingX,
              child: Semantics(
                container: true,
                button: true,
                excludeSemantics: true,
                label: retryLabel,
                onTap: onRetry,
                child: PButton(
                  label: retryLabel!,
                  variant: PButtonVariant.neutralWeak,
                  size: PButtonSize.small,
                  onPressed: onRetry,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return PListButtonItem(
      align: detail != null ? PListAlign.top : PListAlign.center,
      prefix: prefix,
      title: title,
      detail: detail,
      suffix: loading
          ? SizedBox(width: 64, child: PSkeleton.text(PTypography.t5))
          : value == null
          ? null
          : Text(value!, textAlign: TextAlign.end),
      onTap: loading ? null : onTap,
    );
  }
}
