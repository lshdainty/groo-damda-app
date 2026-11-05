import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemNavigator;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/update/apk_installer.dart';
import 'package:groo_damda_app/core/update/app_update.dart';
import 'package:groo_damda_app/features/update/presentation/release_notes_view.dart';
import 'package:groo_damda_app/features/update/presentation/update_progress.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/callout/p_callout.dart';
import 'package:groo_damda_app/shared/ds/progress_circle/p_progress_circle.dart';
import 'package:groo_damda_app/shared/ds/scroll_fog/p_scroll_fog.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/button/p_responsive_pair.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';

/// 새 버전이 나왔을 때 앞을 막고 알리는 화면.
///
/// 스토어를 쓰지 않아 자동 업데이트가 없다. 알리지 않으면 구버전이 계속 남고, 서버가
/// 앞서 나가면 잘못된 값을 주고받게 된다.
///
/// 예전에도 전체 화면으로 알린 적이 있는데 열 때마다 떠서 "받을 생각이 없는 사람에게는
/// 매번 걷어내야 하는 벽" 이 됐고, 그래서 걷어냈다. 이번엔 <b>빌드번호당 한 번</b>만
/// 띄운다 — [취소]를 누르면 그 빌드는 다시 묻지 않고, 다음 버전이 나와야 또 뜬다.
/// 이 조건이 빠지면 예전과 같은 벽이 되어 또 걷어내게 된다.
///
/// 강제([UpdateStatus.mustUpdate])면 이야기가 다르다. 건너뛰기를 무시하고 매번 막는다.
/// 취소하면 왜 못 넘어가는지 알리고 안드로이드는 앱을 닫는다. iOS 는 닫지 않는다 — §종료 참고.
class UpdateGateScreen extends ConsumerWidget {
  const UpdateGateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(updateStatusProvider).value;
    final release = status?.latest;

    // 게이트는 라우터가 shouldGate 로 열어 준다. 그 사이 상태가 바뀌어 볼 게 없어지면
    // 조용히 빠져나간다(취소 직후 재평가가 늦게 도는 찰나 등).
    if (release == null) {
      return Scaffold(
        // 셸 밖 화면은 흰 면 하나(Q11 11B)
        backgroundColor: context.colors.bgLayerDefault,
        body: const Center(child: PProgressCircle()),
      );
    }

    final forced = status!.mustUpdate;

    return PopScope(
      // 강제면 시스템 뒤로가기로도 못 빠져나간다. 일반이면 뒤로가기 = 취소와 같다.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _cancel(context, ref, status: status, forced: forced);
      },
      child: Scaffold(
        backgroundColor: context.colors.bgLayerDefault,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(PSpacing.x6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: PSpacing.x6),
                _Header(release: release, currentBuild: status.currentBuild),
                if (forced) ...[
                  const SizedBox(height: PSpacing.x6),
                  PCallout(
                    tone: PCalloutTone.warning,
                    description: AppLocalizations.of(
                      context,
                    ).updateRequiredDesc,
                  ),
                ],
                const SizedBox(height: PSpacing.x8),
                // 바뀐 내용은 길 수 있어 남는 공간을 다 쓰고 그 안에서 스크롤한다.
                // 노트가 비어 있으면(옛 version.json) 섹션 자체를 숨긴다.
                Expanded(child: _Changes(notes: release.notes)),
                const SizedBox(height: PSpacing.x6),
                _Actions(
                  release: release,
                  forced: forced,
                  onCancel: () =>
                      _cancel(context, ref, status: status, forced: forced),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 취소 — 일반이면 이 빌드를 기억하고 물러난다, 강제면 왜 못 넘어가는지 알린다.
  Future<void> _cancel(
    BuildContext context,
    WidgetRef ref, {
    required UpdateStatus status,
    required bool forced,
  }) async {
    if (forced) {
      await _confirmForcedExit(context);
      return;
    }

    // 기억시킨 뒤 라우터가 다시 평가하면 shouldGate 가 거짓이 되어 저절로 풀린다.
    // pop 이 아니라 go 인 이유: 게이트는 리다이렉트로 들어와 돌아갈 스택이 없을 수 있다.
    await ref
        .read(skippedBuildProvider.notifier)
        .skip(status.latest!.buildNumber);
    if (context.mounted) context.go('/home');
  }

  /// 강제인데 취소를 눌렀을 때. 안드로이드는 확인 즉시 앱을 닫는다.
  ///
  /// iOS 는 닫지 않는다. 프로그램으로 앱을 끝내는 건 애플이 권하지 않고
  /// `SystemNavigator.pop()` 도 동작이 보장되지 않는다 — `exit(0)` 은 사용자에게
  /// 크래시처럼 보인다. 대신 이 화면에 그대로 둔다. 어차피 여기서 못 나가므로
  /// 구버전을 못 쓰게 한다는 목적은 똑같이 이룬다.
  Future<void> _confirmForcedExit(BuildContext context) async {
    final l = AppLocalizations.of(context);
    // 고를 것이 없는 결과 알림이라 "확인" 하나다(P1 B-3). 제목이 없으니 묻는 말로 이름을 단다.
    await PAlertDialog.show(
      context,
      semanticLabel: l.updateTitle,
      description: l.updateGateForcedCancelBody,
      actionLabel: l.actionConfirm,
      // 확인창은 onAction 이 끝나면 늘 닫힌다. 안드로이드는 그 안에서 앱을 끝내고(닫기 전에 앱이
      // 꺼진다), iOS 는 아무것도 안 하고 확인창만 닫혀 게이트 화면으로 돌아간다.
      onAction: () {
        if (Platform.isAndroid) SystemNavigator.pop();
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.release, required this.currentBuild});

  final AppRelease release;
  final int currentBuild;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ds 부품이 없는 자리 — 모양은 두고 색 이름만 새 이름으로
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: c.bgBrandWeak,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(LucideIcons.download, size: 24, color: c.fgBrand),
        ),
        const SizedBox(width: PSpacing.x4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // R1 폰 들어간 화면 제목 — 화면 제목이라 머리말 1단계
              Semantics(
                header: true,
                headingLevel: 1,
                child: Text(
                  l.updateGateTitle(release.version),
                  style: PTypography.t6.copyWith(
                    color: c.fgNeutral,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: PSpacing.x1),
              // R9 메타
              Text(
                l.updateCurrentBuild(currentBuild.toString()),
                style: PTypography.t3.copyWith(color: c.fgNeutralSubtle),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Changes extends StatelessWidget {
  const _Changes({required this.notes});

  final String notes;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    if (!PReleaseNotes.hasContent(notes)) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // R4 구역 제목
        Text(
          l.updateSheetChanges,
          style: PTypography.t5.copyWith(
            color: c.fgNeutral,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: PSpacing.x3),
        Expanded(
          // 회색 상자는 ds 부품이 없다 — 모양은 두고 이름만. 흰 면 위라 라이트에서도 보인다(76)
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: PSpacing.x4),
            decoration: BoxDecoration(
              color: c.bgNeutralWeak,
              borderRadius: BorderRadius.circular(PRounded.r3),
            ),
            // 상자 안이 스크롤된다 — 넘치면 끝 흐림
            child: PScrollFog(child: PReleaseNotes(notes: notes)),
          ),
        ),
      ],
    );
  }
}

/// [취소] [설치] — 안드로이드는 앱 안에서 받아 설치까지, iOS 는 AltStore 로 넘긴다.
class _Actions extends ConsumerWidget {
  const _Actions({
    required this.release,
    required this.forced,
    required this.onCancel,
  });

  final AppRelease release;
  final bool forced;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final progress = ref.watch(apkInstallerProvider);

    // 받는 중에는 버튼 대신 진행 상태를 보여 준다 — 두 번 누르는 걸 막는다.
    if (progress.isBusy) {
      return updateProgressRow(
        context,
        label: progress.stage == ApkStage.opening
            ? l.updateSheetOpening
            : l.updateSheetDownloading,
        ratio: progress.ratio,
      );
    }

    // 화면 바닥의 Dismiss + CTA — 3:7(button.md). 라벨이 자기 몫을 넘으면 쌓는다.
    return PResponsivePair(
      secondaryFlex: 3,
      primaryFlex: 7,
      secondary: PButton(
        label: l.actionCancel,
        size: PButtonSize.large,
        variant: PButtonVariant.neutralWeak,
        onPressed: onCancel,
      ),
      primary: PButton(
        label: progress.stage == ApkStage.failed
            ? l.updateSheetRetry
            : l.updateGateInstall,
        size: PButtonSize.large,
        onPressed: () => _install(context, ref),
      ),
    );
  }

  Future<void> _install(BuildContext context, WidgetRef ref) async {
    // iOS 는 앱이 스스로를 설치할 수 없다. AltStore 에 넘긴다 — 설치가 끝나면
    // 프로세스가 교체되므로 게이트는 저절로 사라진다. 그 전에 돌아오면 다시 보인다.
    if (!Platform.isAndroid) {
      await openReleaseExternally(release);
      return;
    }

    final ok = await ref
        .read(apkInstallerProvider.notifier)
        .downloadAndOpen(release);
    if (ok || !context.mounted) return;

    // 앱 안에서 못 받았으면 브라우저에 넘긴다. 거기서는 받아지는 경우가 있다.
    final l = AppLocalizations.of(context);
    PSnackbar.maybeOf(
      context,
    )?.show(message: l.updateSheetFailed, tone: PSnackbarTone.critical);
    await openReleaseExternally(release);
  }
}
