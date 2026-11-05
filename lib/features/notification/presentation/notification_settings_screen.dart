import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/auth/auth_notifier.dart';
import 'package:groo_damda_app/core/format/date.dart';
import 'package:groo_damda_app/features/budget/application/budget_providers.dart';
import 'package:groo_damda_app/shared/forms/time_sheet.dart';
import 'package:groo_damda_app/features/notification/application/user_preferences_providers.dart';
import 'package:groo_damda_app/features/notification/data/user_preferences_repository.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/list/list_row.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/slider/p_slider.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/ds/time_picker/p_time_picker.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';
import 'package:groo_damda_app/shared/forms/pick_list.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';

/// 알림 "설정" 화면(I-15 48 ~ 54) — 흰 면 하나: 푸시 알림 스위치 줄 → "알림 종류" + 스위치 줄 일곱 → "예산 알림 기준" +
/// Slider → "방해 금지 시간" → "소리 · 진동" → "이메일 알림". 묶음 제목은 목록 제목(boldSolid), 줄은 ds List.
/// 각 컨트롤은 누르는 순간 적용(낙관적 PATCH)하고, 저장하지 못하면 되돌리고 critical 스낵바 고정 글을 띄운다
/// (요청은 전역 오류 알림을 끈다 · [다시 시도] 는 두지 않는다 — 스위치는 다시 누르는 것이 재시도다).
///
/// 헤더는 고정, content 만 스크롤. 알림 "목록"(/notifications)과 별개.
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final prefsAsync = ref.watch(userPreferencesProvider);
    final email = ref.watch(authProvider).value?.userEmail ?? '';

    return Scaffold(
      backgroundColor: context.colors.bgLayerDefault,
      // 머리 = ds 상단 바(← + 제목) — 높이 56, 스크롤해도 선이 없다(I-16 14)
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(PTopNavigation.heightOf(context)),
        child: PTopNavigation(
          title: l.notiSettings,
          leading: PTopNavigationIconButton.back(
            label: l.actionBack,
            onPressed: () => context.pop(),
          ),
        ),
      ),
      body: prefsAsync.when(
        loading: () => const _PrefsSkeleton(),
        error: (e, _) => ListView(
          children: [
            PResultSection(
              kind: PResultKind.failure,
              title: l.notiSettingsLoadError,
              description: l.notiSettingsLoadFailedDesc,
              primaryAction: PResultAction(
                label: l.actionRetry,
                onPressed: () => ref.invalidate(userPreferencesProvider),
              ),
            ),
          ],
        ),
        data: (prefs) => _Content(prefs: prefs, email: email),
      ),
    );
  }
}

/// 시각 값 글 — 오른쪽 값("오후 10:00" · "기본" · "매주"), 막히면 비활성 색.
Widget _valueText(BuildContext context, String text, {bool enabled = true}) {
  final c = context.colors;
  return Text(
    text,
    style: PTypography.t5.copyWith(
      color: enabled ? c.fgNeutralMuted : c.fgDisabled,
    ),
  );
}

/// "HH:mm" → 화면 글 "오후 10:00"(`a h:mm`).
String _clockLabel(String hhmm) {
  final v = _parseHm(hhmm);
  return timeOfDay12(DateTime(2000, 1, 1, v.hour, v.minute));
}

PTimeValue _parseHm(String hhmm) {
  final parts = hhmm.split(':');
  final h = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0;
  final m = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
  return PTimeValue(h.clamp(0, 23), m.clamp(0, 59));
}

String _fmtHm(PTimeValue v) =>
    '${v.hour.toString().padLeft(2, '0')}:${v.minute.toString().padLeft(2, '0')}';

class _Content extends ConsumerWidget {
  const _Content({required this.prefs, required this.email});
  final UserPreferences prefs;
  final String email;

  /// 부분 저장(낙관적) — 못 저장하면 알림 설정 저장 실패 글을 띄운다(critical · 고정 글 · [다시 시도] 없음).
  /// 띠는 앱 뿌리 호스트에 있어 화면을 닫아도 남으므로 호스트 · 글을 await 앞에서 잡는다.
  Future<bool> _patch(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> fields,
    UserPreferences Function(UserPreferences prev) optimistic,
  ) async {
    final snack = PSnackbar.maybeOf(context);
    final l = AppLocalizations.of(context);
    final saved = await ref
        .read(userPreferencesProvider.notifier)
        .patch(fields, optimistic: optimistic, silent: true);
    if (!saved) {
      snack?.show(message: l.notiPrefsSaveFailed, tone: PSnackbarTone.critical);
    }
    return saved;
  }

  /// 예산 알림 기준만 저장 뒤 한 곳을 더 비운다.
  ///
  /// 이 화면이 저장하는 값 중 **밖에서도 읽히는 건 이것 하나**다. 홈·예산의 게이지
  /// 경고선은 `userPreferences` 가 아니라 [budgetAlertThresholdProvider] 에서 온다 —
  /// 같은 `/users/me/preferences` 를 따로 GET 하는 별개 조회다. 여기서 안 비우면
  /// 방금 내가 민 눈금이 게이지에는 60초 신선도 규칙이 돌 때까지 안 선다.
  /// **무효화는 내가 한 것, 시계는 남이 한 것** — 내 손으로 바꾼 값을 남의 시계로
  /// 기다리게 두지 않는다.
  ///
  /// **저장이 끝난 뒤**에 비운다. 먼저 비우면 새 GET 이 PATCH 를 앞질러 옛 값을
  /// 물어 와, 게이지가 오히려 옛 눈금에 굳는다.
  ///
  /// 컨테이너를 미리 잡아 두는 이유 — 슬라이더를 놓자마자 뒤로 가면 PATCH 가
  /// 끝나기 전에 이 위젯이 사라진다. `WidgetRef` 는 unmount 뒤에 쓰면 던지지만
  /// 컨테이너는 `ProviderScope` 의 것이라 화면보다 오래 산다.
  Future<void> _patchThreshold(
    ProviderContainer container,
    PSnackbarApi? snack,
    AppLocalizations l,
    int v,
  ) async {
    final saved = await container
        .read(userPreferencesProvider.notifier)
        .patch(
          {'budgetAlertThreshold': v},
          optimistic: (p) => p.copyWith(budgetAlertThreshold: v),
          silent: true,
        );
    if (saved) {
      container.invalidate(budgetAlertThresholdProvider);
    } else {
      snack?.show(message: l.notiPrefsSaveFailed, tone: PSnackbarTone.critical);
    }
  }

  /// 스위치 줄 — 앞 아이콘 22 · 제목 · 설명 · 오른쪽 Switch 32. [enabled] 가 거짓이면 막힌 줄(켜진 모양 그대로 회색).
  Widget _switchRow(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String title,
    required String desc,
    required bool value,
    required String field,
    required UserPreferences Function(UserPreferences p, bool v) apply,
    bool enabled = true,
  }) {
    return PListSwitchItem(
      prefix: Icon(icon),
      title: title,
      detail: desc,
      checked: value,
      onChanged: enabled
          ? (v) => _patch(context, ref, {field: v}, (p) => apply(p, v))
          : null,
    );
  }

  /// 고르기 시트 — 누르면 바로 넣고 닫힌다, 바닥 버튼 없음. 닫으면 null.
  Future<String?> _pick(
    BuildContext context, {
    required String title,
    required String selected,
    required List<(String, String)> options,
  }) {
    return PBottomSheet.show<String>(
      context,
      builder: (ctx) {
        final l = AppLocalizations.of(ctx);
        return PBottomSheetContent(
          title: title,
          closeLabel: l.actionClose,
          flushBody: true,
          body: PickList<String>(
            label: title,
            selected: selected,
            items: [
              for (final o in options) PickItem(value: o.$1, title: o.$2),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final pushOn = prefs.pushEnabled;
    // [_patchThreshold] 가 화면이 사라진 뒤에도 비울 수 있게 지금 잡아 둔다.
    final container = ProviderScope.containerOf(context, listen: false);
    final snack = PSnackbar.maybeOf(context);
    final quietOn = pushOn && prefs.quietHoursEnabled;

    String soundLabel(String v) => switch (v) {
      NotificationSound.chime => l.notiSoundChime,
      NotificationSound.none => l.notiSoundNone,
      _ => l.notiSoundDefault,
    };
    String freqLabel(String v) => switch (v) {
      EmailFrequency.daily => l.notiEmailDaily,
      EmailFrequency.monthly => l.notiEmailMonthly,
      _ => l.notiEmailWeekly,
    };

    Future<void> pickTime(String title, String current, String field) async {
      final picked = await showTimeSheet(
        context,
        title: title,
        value: _parseHm(current),
        // 방해 금지 시작 · 끝은 1분 간격(time-picker.md)
        minuteStep: 1,
      );
      if (picked == null || !context.mounted) return;
      final hm = _fmtHm(picked);
      await _patch(
        context,
        ref,
        {field: hm},
        (p) => field == 'quietHoursStart'
            ? p.copyWith(quietHoursStart: hm)
            : p.copyWith(quietHoursEnd: hm),
      );
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // 1) 푸시 알림 (맨 위 · 묶음 제목 없음)
        PList(
          semanticLabel: l.notiPush,
          children: [
            _switchRow(
              context,
              ref,
              icon: LucideIcons.bell,
              title: l.notiPush,
              desc: pushOn ? l.notiPushOn : l.notiPushOff,
              value: pushOn,
              field: 'pushEnabled',
              apply: (p, v) => p.copyWith(pushEnabled: v),
            ),
          ],
        ),

        // 2) 알림 종류 — 푸시를 끄면 막는다
        PListHeader(
          title: l.notiKindTitle,
          variant: PListHeaderVariant.boldSolid,
          topInset: 16,
        ),
        PList(
          semanticLabel: l.notiKindTitle,
          children: [
            _switchRow(
              context,
              ref,
              icon: LucideIcons.creditCard,
              title: l.notiPayment,
              desc: l.notiPaymentDesc,
              value: prefs.notifyPayment,
              field: 'notifyPayment',
              apply: (p, v) => p.copyWith(notifyPayment: v),
              enabled: pushOn,
            ),
            _switchRow(
              context,
              ref,
              icon: LucideIcons.target,
              title: l.notiTypeBudgetAlert,
              // DB(budget_alert_threshold) 기반 — 아래 기준 값과 같다.
              desc: l.notiBudgetDesc(prefs.budgetAlertThreshold),
              value: prefs.notifyBudget,
              field: 'notifyBudget',
              apply: (p, v) => p.copyWith(notifyBudget: v),
              enabled: pushOn,
            ),
            _switchRow(
              context,
              ref,
              icon: LucideIcons.zap,
              title: l.notiAutoRecord,
              desc: l.notiAutoRecordDesc,
              value: prefs.notifyAutoRecord,
              field: 'notifyAutoRecord',
              apply: (p, v) => p.copyWith(notifyAutoRecord: v),
              enabled: pushOn,
            ),
            _switchRow(
              context,
              ref,
              icon: LucideIcons.users,
              title: l.notiDutchPay,
              desc: l.notiDutchPayDesc,
              value: prefs.notifyDutchPay,
              field: 'notifyDutchPay',
              apply: (p, v) => p.copyWith(notifyDutchPay: v),
              enabled: pushOn,
            ),
            _switchRow(
              context,
              ref,
              icon: LucideIcons.calendarClock,
              title: l.notiTypeEventReminder,
              desc: l.notiCalendarDesc,
              value: prefs.notifyCalendar,
              field: 'notifyCalendar',
              apply: (p, v) => p.copyWith(notifyCalendar: v),
              enabled: pushOn,
            ),
            _switchRow(
              context,
              ref,
              icon: LucideIcons.barChart3,
              title: l.notiWeeklyReport,
              desc: l.notiWeeklyReportDesc,
              value: prefs.notifyWeeklyReport,
              field: 'notifyWeeklyReport',
              apply: (p, v) => p.copyWith(notifyWeeklyReport: v),
              enabled: pushOn,
            ),
            _switchRow(
              context,
              ref,
              icon: LucideIcons.fileBarChart,
              title: l.notiMonthlyReport,
              desc: l.notiMonthlyReportDesc,
              value: prefs.notifyMonthlyReport,
              field: 'notifyMonthlyReport',
              apply: (p, v) => p.copyWith(notifyMonthlyReport: v),
              enabled: pushOn,
            ),
          ],
        ),

        // 3) 예산 알림 기준 — 예산 · 홈 경고에도 쓰여 푸시를 꺼도 남긴다(Q1 C)
        PListHeader(
          title: l.notiThresholdTitle,
          variant: PListHeaderVariant.boldSolid,
          topInset: 16,
        ),
        _ThresholdBlock(
          value: prefs.budgetAlertThreshold,
          onSave: (v) => _patchThreshold(container, snack, l, v),
        ),

        // 4) 방해 금지 시간
        PListHeader(
          title: l.notiQuietTitle,
          variant: PListHeaderVariant.boldSolid,
          topInset: 16,
        ),
        PList(
          semanticLabel: l.notiQuietTitle,
          children: [
            _switchRow(
              context,
              ref,
              icon: LucideIcons.moon,
              title: l.notiQuietToggle,
              desc: l.notiQuietToggleDesc,
              value: prefs.quietHoursEnabled,
              field: 'quietHoursEnabled',
              apply: (p, v) => p.copyWith(quietHoursEnabled: v),
              enabled: pushOn,
            ),
            // 시작 · 종료 — 들인 줄(앞 아이콘 자리만큼), 방해 금지가 꺼져 있으면 막힘(값은 그대로 보인다)
            PListButtonItem(
              prefix: const SizedBox(width: kPListIconSize),
              title: l.notiQuietStart,
              suffix: _valueText(
                context,
                _clockLabel(prefs.quietHoursStart),
                enabled: quietOn,
              ),
              onTap: quietOn
                  ? () => pickTime(
                      l.notiQuietStart,
                      prefs.quietHoursStart,
                      'quietHoursStart',
                    )
                  : null,
            ),
            PListButtonItem(
              prefix: const SizedBox(width: kPListIconSize),
              title: l.notiQuietEnd,
              suffix: _valueText(
                context,
                _clockLabel(prefs.quietHoursEnd),
                enabled: quietOn,
              ),
              onTap: quietOn
                  ? () => pickTime(
                      l.notiQuietEnd,
                      prefs.quietHoursEnd,
                      'quietHoursEnd',
                    )
                  : null,
            ),
          ],
        ),

        // 5) 소리 · 진동
        PListHeader(
          title: l.notiSoundTitle,
          variant: PListHeaderVariant.boldSolid,
          topInset: 16,
        ),
        PList(
          semanticLabel: l.notiSoundTitle,
          children: [
            PListButtonItem(
              prefix: const Icon(LucideIcons.volume2),
              title: l.notiSound,
              detail: l.notiSoundDesc,
              suffix: _valueText(
                context,
                soundLabel(prefs.notificationSound),
                enabled: pushOn,
              ),
              onTap: pushOn
                  ? () async {
                      final v = await _pick(
                        context,
                        title: l.notiSound,
                        selected: prefs.notificationSound,
                        options: [
                          (NotificationSound.chime, l.notiSoundChime),
                          (NotificationSound.defaultSound, l.notiSoundDefault),
                          (NotificationSound.none, l.notiSoundNone),
                        ],
                      );
                      if (v == null || !context.mounted) return;
                      await _patch(context, ref, {
                        'notificationSound': v,
                      }, (p) => p.copyWith(notificationSound: v));
                    }
                  : null,
            ),
            _switchRow(
              context,
              ref,
              icon: LucideIcons.vibrate,
              title: l.notiVibration,
              desc: l.notiVibrationDesc,
              value: prefs.vibrationEnabled,
              field: 'vibrationEnabled',
              apply: (p, v) => p.copyWith(vibrationEnabled: v),
              enabled: pushOn,
            ),
          ],
        ),

        // 6) 이메일 알림 — 푸시와 따로라 푸시를 꺼도 그대로
        PListHeader(
          title: l.notiEmailTitle,
          variant: PListHeaderVariant.boldSolid,
          topInset: 16,
        ),
        PList(
          semanticLabel: l.notiEmailTitle,
          children: [
            _switchRow(
              context,
              ref,
              icon: LucideIcons.mail,
              title: l.notiEmailToggle,
              // 긴 이메일은 줄바꿈(말줄임 없음)
              desc: email.isNotEmpty ? email : l.notiEmailNone,
              value: prefs.emailEnabled,
              field: 'emailEnabled',
              apply: (p, v) => p.copyWith(emailEnabled: v),
            ),
            if (prefs.emailEnabled)
              PListButtonItem(
                prefix: const SizedBox(width: kPListIconSize),
                title: l.notiEmailFreq,
                suffix: _valueText(context, freqLabel(prefs.emailFrequency)),
                onTap: () async {
                  final v = await _pick(
                    context,
                    title: l.notiEmailFreq,
                    selected: prefs.emailFrequency,
                    options: [
                      (EmailFrequency.daily, l.notiEmailDaily),
                      (EmailFrequency.weekly, l.notiEmailWeekly),
                      (EmailFrequency.monthly, l.notiEmailMonthly),
                    ],
                  );
                  if (v == null || !context.mounted) return;
                  await _patch(context, ref, {
                    'emailFrequency': v,
                  }, (p) => p.copyWith(emailFrequency: v));
                },
              ),
          ],
        ),

        // 흰 면 끝 여백 24
        const SizedBox(height: 24),
      ],
    );
  }
}

// ── 예산 알림 기준 ────────────────────────────────────────────────────────────

/// 예산 알림 기준 — 머리 줄 "경고로 표시할 사용률" + 오른쪽 값 "80%", ds Slider(눈금 없이 양 끝 "50%" · "100%"), 설명.
/// 값 50 ~ 100 · 5 단위 · 손을 뗄 때 한 번 저장 · 요청 중에도 막지 않는다. 끄는 동안 값은 이 상태가 쥔다.
class _ThresholdBlock extends StatefulWidget {
  const _ThresholdBlock({required this.value, required this.onSave});
  final int value;
  final Future<void> Function(int v) onSave;

  @override
  State<_ThresholdBlock> createState() => _ThresholdBlockState();
}

class _ThresholdBlockState extends State<_ThresholdBlock> {
  // 끄는 동안의 값 — 손을 떼면 저장하고 서버 값(prefs)이 돌아오면 그쪽을 따른다
  int? _drag;

  @override
  void didUpdateWidget(covariant _ThresholdBlock old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _drag = null;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final shown = (_drag ?? widget.value).clamp(50, 100);
    return Padding(
      // 좌우 24 · 위 4 · 아래 16
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  keepAll(l.notiThresholdLabel),
                  style: PTypography.t4.copyWith(
                    color: c.fgNeutral,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // 머리 값 — 보조 기술에는 숨긴다(값은 손잡이가 읽는다)
              PSliderValue('$shown%'),
            ],
          ),
          // 머리 줄 아래 ~ 손잡이 위 21 (웹과 같다) — 말풍선 자리를 뺀 만큼 8 을 둔다
          const SizedBox(height: 8),
          PSlider(
            value: shown.toDouble(),
            min: 50,
            max: 100,
            step: 5,
            label: l.notiThresholdLabel,
            bubbleSpace: false,
            formatValue: (v) => '${v.round()}%',
            onChanged: (v) => setState(() => _drag = v.round()),
            onChangeEnd: (v) => widget.onSave(v.round()),
          ),
          const SizedBox(height: 8),
          Text(
            keepAll(l.notiThresholdDesc),
            style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
          ),
        ],
      ),
    );
  }
}

// ── skeleton ──────────────────────────────────────────────────────────────────

/// 불러오는 동안 — 틀(묶음 제목 · 줄 제목 · 아이콘)은 그리고 스위치 · 값 · 이메일 자리만 Skeleton.
class _PrefsSkeleton extends StatelessWidget {
  const _PrefsSkeleton();

  static const _switchSlot = PSkeleton(
    width: 52,
    height: 32,
    radius: PSkeletonRadius.full,
  );

  Widget _row(
    IconData icon,
    String title, {
    String? detail,
    Widget? detailChild,
  }) => PListItem(
    prefix: Icon(icon),
    title: title,
    detail: detail,
    detailChild: detailChild,
    suffix: _switchSlot,
  );

  /// 시작 · 종료 · 발송 주기 — 들인 줄, 값 자리만 Skeleton.
  Widget _valueRow(String title) => PListItem(
    prefix: const SizedBox(width: kPListIconSize),
    title: title,
    suffix: const PSkeleton(width: 64, height: 16),
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return ListView(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        PList(children: [_row(LucideIcons.bell, l.notiPush)]),
        PListHeader(
          title: l.notiKindTitle,
          variant: PListHeaderVariant.boldSolid,
          topInset: 16,
        ),
        PList(
          children: [
            _row(
              LucideIcons.creditCard,
              l.notiPayment,
              detail: l.notiPaymentDesc,
            ),
            _row(LucideIcons.target, l.notiTypeBudgetAlert),
            _row(
              LucideIcons.zap,
              l.notiAutoRecord,
              detail: l.notiAutoRecordDesc,
            ),
            _row(LucideIcons.users, l.notiDutchPay, detail: l.notiDutchPayDesc),
            _row(
              LucideIcons.calendarClock,
              l.notiTypeEventReminder,
              detail: l.notiCalendarDesc,
            ),
            _row(
              LucideIcons.barChart3,
              l.notiWeeklyReport,
              detail: l.notiWeeklyReportDesc,
            ),
            _row(
              LucideIcons.fileBarChart,
              l.notiMonthlyReport,
              detail: l.notiMonthlyReportDesc,
            ),
          ],
        ),
        PListHeader(
          title: l.notiThresholdTitle,
          variant: PListHeaderVariant.boldSolid,
          topInset: 16,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      keepAll(l.notiThresholdLabel),
                      style: PTypography.t4.copyWith(color: c.fgNeutral),
                    ),
                  ),
                  const PSkeleton(width: 36, height: 16),
                ],
              ),
              const SizedBox(height: 12),
              const PSkeleton(
                width: double.infinity,
                height: 4,
                radius: PSkeletonRadius.full,
              ),
            ],
          ),
        ),
        PListHeader(
          title: l.notiQuietTitle,
          variant: PListHeaderVariant.boldSolid,
          topInset: 16,
        ),
        PList(
          children: [
            _row(
              LucideIcons.moon,
              l.notiQuietToggle,
              detail: l.notiQuietToggleDesc,
            ),
            _valueRow(l.notiQuietStart),
            _valueRow(l.notiQuietEnd),
          ],
        ),
        PListHeader(
          title: l.notiSoundTitle,
          variant: PListHeaderVariant.boldSolid,
          topInset: 16,
        ),
        PList(
          children: [
            _row(LucideIcons.volume2, l.notiSound, detail: l.notiSoundDesc),
            _row(
              LucideIcons.vibrate,
              l.notiVibration,
              detail: l.notiVibrationDesc,
            ),
          ],
        ),
        PListHeader(
          title: l.notiEmailTitle,
          variant: PListHeaderVariant.boldSolid,
          topInset: 16,
        ),
        PList(
          children: [
            _row(
              LucideIcons.mail,
              l.notiEmailToggle,
              detailChild: const PSkeleton(width: 160, height: 14),
            ),
            _valueRow(l.notiEmailFreq),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
