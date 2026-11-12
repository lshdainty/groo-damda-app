import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/update/apk_installer.dart';
import 'package:groo_damda_app/core/update/auto_blocker_guide.dart';
import 'package:groo_damda_app/core/update/app_update.dart';
import 'package:groo_damda_app/features/update/presentation/release_notes_view.dart';
import 'package:groo_damda_app/features/update/presentation/update_progress.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/callout/p_callout.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/progress_circle/p_progress_circle.dart';
import 'package:groo_damda_app/shared/ds/screen_band/p_screen_band.dart';
import 'package:groo_damda_app/shared/ds/snackbar/p_snackbar.dart';
import 'package:groo_damda_app/shared/ds/text/p_text.dart';
import 'package:groo_damda_app/shared/ds/top_navigation/p_top_navigation.dart';

/// 업데이트 — 설정에서 들어와 지금 상태를 확인하고, 있으면 여기서 받는다.
///
/// 알림은 UpdateGateScreen 이 맡는다(새 버전이 나오면 빌드번호당 한 번 전체 화면으로
/// 가로막는다). 이 화면은 그걸 넘긴 사람이 나중에 스스로 찾아오는 자리다 — 스토어의
/// "업데이트" 탭과 같다. 그래서 뒤로 가기를 막지 않는다.
class UpdateScreen extends ConsumerWidget {
  const UpdateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final statusAsync = ref.watch(updateStatusProvider);

    return Scaffold(
      backgroundColor: context.colors.bgLayerBasement,
      // 머리 = ds 상단 바(← + 제목) — 높이 56, 스크롤해도 선이 없다. ← 는 History(앞 화면이 늘 있다)
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(PTopNavigation.heightOf(context)),
        child: PTopNavigation(
          title: l.updateTitle,
          leading: PTopNavigationIconButton.back(
            label: l.actionBack,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
      ),
      body: PScreenBandBody(
        child: statusAsync.when(
          // 받아 둔 값이 있으면 다시 받기 실패에도 내용을 그린다 — 실패 화면은 값이 없을 때만(검수 M2, result-section.md:53)
          skipError: true,
          loading: () => const Center(child: PProgressCircle()),
          // 서버를 못 읽어도 화면은 뜬다 — 지금 버전만이라도 보여 준다.
          error: (_, _) => const _Body(status: null),
          data: (s) => _Body(status: s),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.status});

  final UpdateStatus? status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = AppLocalizations.of(context);
    final s = status;
    final latest = s?.latest;
    final hasUpdate = s?.hasUpdate ?? false;
    // 서버를 못 읽은 것과 "받을 게 없다" 는 다르다. 예전엔 둘을 같이 취급해서 서버가
    // 죽어 있어도 "최신 버전이에요" 라고 안심시켰다 — 업데이트 안내가 조용히 멈췄다.
    final checkFailed = s == null || s.checkFailed;
    const gutter = EdgeInsets.symmetric(horizontal: PSpacing.x6);

    return ListView(
      padding: const EdgeInsets.only(bottom: PSpacing.x6),
      children: [
        // ── 상태 한 줄 — 최신인지 아닌지가 먼저 보여야 한다(누르지 않는 List 줄).
        PListItem(
          prefix: PListTile(
            background: hasUpdate ? c.bgBrandWeak : c.bgNeutralWeak,
            color: hasUpdate
                ? c.fgBrand
                : checkFailed
                ? c.fgWarning
                : c.fgNeutralMuted,
            child: Icon(
              hasUpdate
                  ? LucideIcons.download
                  : checkFailed
                  ? LucideIcons.triangleAlert
                  : LucideIcons.check,
            ),
          ),
          title: hasUpdate
              ? l.updateAvailable(latest!.version)
              : checkFailed
              ? l.updateCheckFailedTitle
              : l.updateUpToDate,
          // 지금 버전은 서버와 무관하게 알고 있다 — 확인에 실패해도 보여 준다.
          detail: checkFailed
              ? l.updateCheckFailed
              : l.updateCurrentBuild(s.currentBuild.toString()),
        ),

        // ── 바뀐 것
        if (hasUpdate && latest!.notes.trim().isNotEmpty) ...[
          const SizedBox(height: PSpacing.x8),
          Padding(
            padding: gutter,
            // R4 구역 제목
            child: PText(
              l.updateSheetChanges,
              style: PTypography.t5.copyWith(
                color: c.fgNeutral,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: PSpacing.x3),
          Padding(
            padding: gutter,
            child: Container(
              padding: const EdgeInsets.all(PSpacing.x4),
              decoration: BoxDecoration(
                color: c.bgNeutralWeak,
                borderRadius: BorderRadius.circular(PRounded.r3),
              ),
              child: PReleaseNotes(notes: latest.notes),
            ),
          ),
        ],

        // ── 받기
        if (hasUpdate) ...[
          const SizedBox(height: PSpacing.x8),
          // 삼성 기기는 자동 차단을 끄기 전엔 설치가 막힌다 — 받기 전에 알려 준다.
          // 받고 나서 알면 다운로드가 헛수고가 된다.
          const Padding(padding: gutter, child: AutoBlockerNotice()),
          Padding(
            padding: gutter,
            child: _DownloadButton(release: latest!),
          ),
        ],
      ],
    );
  }
}

/// 삼성 "자동 차단" 안내 — 그 기기에서만 나온다.
///
/// One UI 6.0(Android 14)부터 기본으로 켜져 있고 **스토어 밖에서 온 앱의 설치를
/// 통째로 막는다**. 우리 앱이 위험해서가 아니라 사이드로드라는 경로 자체를 막는
/// 것이라, 끄기 전에는 받아도 설치 화면에서 튕긴다.
///
/// 앱이 스스로 풀 방법은 없다 — 설정으로 데려다주는 것까지가 전부다.
class AutoBlockerNotice extends StatefulWidget {
  const AutoBlockerNotice({
    super.key,
    @visibleForTesting this.debugShow = false,
  });

  /// 시험용 — 기기 판정(삼성 + Android 14)을 건너뛰고 안내를 띄운다.
  final bool debugShow;

  @override
  State<AutoBlockerNotice> createState() => _AutoBlockerNoticeState();
}

class _AutoBlockerNoticeState extends State<AutoBlockerNotice> {
  late bool _show = widget.debugShow;

  /// 설정에 다녀온 뒤 안내 문구 — 어디까지 열렸느냐에 따라 남은 걸음이 다르다.
  AutoBlockerTarget? _opened;

  @override
  void initState() {
    super.initState();
    if (!widget.debugShow) _check();
  }

  Future<void> _check() async {
    final blocking = await AutoBlockerGuide.isBlockingDevice();
    if (!mounted) return;
    setState(() => _show = blocking);
  }

  Future<void> _open() async {
    final target = await AutoBlockerGuide.open();
    if (!mounted) return;
    setState(() => _opened = target);
  }

  @override
  Widget build(BuildContext context) {
    if (!_show) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);

    // 자동 차단 화면이 바로 열렸으면 토글만 끄면 되고, 보안 설정까지만 갔으면
    // 목록에서 찾아야 한다. 아무것도 못 열었을 때만 전체 경로를 적어 준다.
    final description = switch (_opened) {
      AutoBlockerTarget.autoBlocker => l.updateAutoBlockerAfterDirect,
      AutoBlockerTarget.security => l.updateAutoBlockerAfterSecurity,
      AutoBlockerTarget.settings ||
      AutoBlockerTarget.none => l.updateAutoBlockerPath,
      null => l.updateAutoBlockerDesc,
    };

    // Callout 의 동작은 링크 하나다(callout.md ⓕ) — "설정 열기" 를 링크로 둔다
    return Padding(
      padding: const EdgeInsets.only(bottom: PSpacing.x4),
      child: PCallout(
        tone: PCalloutTone.warning,
        title: l.updateAutoBlockerTitle,
        description: description,
        link: PCalloutLink(label: l.updateAutoBlockerOpen, onPressed: _open),
      ),
    );
  }
}

/// 받기 버튼 — 안드로이드는 앱 안에서 받아 설치 화면까지, iOS 는 AltStore 로.
class _DownloadButton extends ConsumerWidget {
  const _DownloadButton({required this.release});

  final AppRelease release;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final progress = ref.watch(apkInstallerProvider);

    if (progress.isBusy) {
      return updateProgressRow(
        context,
        label: progress.stage == ApkStage.opening
            ? l.updateSheetOpening
            : l.updateSheetDownloading,
        ratio: progress.ratio,
      );
    }

    return PButton(
      label:
          progress.stage == ApkStage.failed ||
              progress.stage == ApkStage.rejected
          ? l.updateSheetRetry
          : l.updateSheetNow,
      prefixIcon: LucideIcons.download,
      size: PButtonSize.large,
      onPressed: () => _start(context, ref),
    );
  }

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    // iOS 는 앱이 스스로를 설치할 수 없다. AltStore 에 넘긴다.
    if (!Platform.isAndroid) {
      await openReleaseExternally(release);
      return;
    }

    final result = await ref
        .read(apkInstallerProvider.notifier)
        .downloadAndOpen(release);
    if (result == ApkInstallResult.opened || !context.mounted) return;

    final l = AppLocalizations.of(context);
    // 받은 파일이 이 앱이 아니면 설치하지 않고 알리기만 한다 — 브라우저로 넘기면 같은 파일을
    // 받아 깔게 될 뿐이다(보안 점검 CLI-3).
    if (result == ApkInstallResult.rejected) {
      PSnackbar.maybeOf(
        context,
      )?.show(message: l.updateApkRejected, tone: PSnackbarTone.critical);
      return;
    }

    // 앱 안에서 못 받았으면 브라우저에 넘긴다. 거기서는 받아지는 경우가 있다.
    PSnackbar.maybeOf(
      context,
    )?.show(message: l.updateSheetFailed, tone: PSnackbarTone.critical);
    await openReleaseExternally(release);
  }
}
