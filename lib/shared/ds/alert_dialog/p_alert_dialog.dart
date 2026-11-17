import 'dart:async';

import 'package:flutter/material.dart' show Scaffold;
import 'package:flutter/rendering.dart' show SemanticsRole;
import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/button/p_responsive_pair.dart';
import 'package:groo_damda_app/shared/ds/overlay/p_overlay.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';

/// 확인창 폭 — 최대 272, 좌우 32 를 남긴다(화면이 336 보다 좁으면 화면 폭 − 64).
const double _maxWidth = 272;

/// 작성 중 나가기 확인의 글 — 문자열은 부르는 쪽이 넘긴다(앱이 지역화한다).
///
/// 스펙의 글: 제목 "작성한 내용이 사라져요" · 설명 "나가면 입력한 내용이 저장되지 않아요." · 버튼 "계속 작성" · "나가기".
class PLeaveConfirmCopy {
  const PLeaveConfirmCopy({
    required this.title,
    required this.description,
    required this.stayLabel,
    required this.leaveLabel,
  });

  final String title;
  final String description;

  /// 취소 — 계속 작성한다.
  final String stayLabel;

  /// 확정(Critical) — 나간다.
  final String leaveLabel;
}

/// Alert Dialog 의 모습 — 라우트 없이 확인창 표면만 그린다(카탈로그의 정지한 견본 · 테스트). 실제로는
/// [PAlertDialog.show] 가 이것을 라우트에 띄운다.
///
/// 구조는 SEED Alert Dialog(2026-10-02), 수치 원본은 groo-design `specs/components/alert-dialog.yaml`(값은
/// `test/fixtures/design_spec/alert-dialog.json`). 웹(desk-front `src/shared/ds/alert-dialog`)과 같은 값이다.
///
/// 확인창 — 화면 정중앙, 최대 272 에 좌우 32 를 남긴다. 안쪽 20 · 모서리 20 · 그림자 없음(딤과 표면 색으로 뜬다).
/// 제목 20 / 27 · 700, 설명 16 / 22 · 짙은 `fg-neutral`(꼭 읽어야 할 말이다), 제목 아래 6(제목이 없으면 0).
/// 바닥은 위 16 · 버튼 사이 8 · Button medium 40(폰) — 취소는 neutralWeak, 확정은 일을 하면 잃는 게 있을 때만
/// criticalSolid([destructive]), 아니면 neutralSolid. 닫기 버튼이 없다.
///
/// 배치 — 취소 · 확정을 반씩 나란히, 한쪽 글이 반 폭을 넘으면 세로(확정이 위), 알리기([cancelLabel] 없음)는 버튼 하나.
/// 처음 초점은 확인창(컨테이너)이고 버튼이 아니다([requestFocus]). `Esc` 는 취소와 같다([onCancel]).
/// 읽기 — 알림 대화상자(role) · 이름은 제목(없으면 [semanticLabel]).
class PAlertDialogView extends StatelessWidget {
  const PAlertDialogView({
    super.key,
    this.title,
    required this.description,
    this.cancelLabel,
    required this.actionLabel,
    this.destructive = false,
    this.onCancel,
    this.onAction,
    this.actionLoading = false,
    this.semanticLabel,
    this.requestFocus = false,
  }) : assert(
         title != null || semanticLabel != null,
         '제목이 없으면 semanticLabel 로 묻는 말을 단다(예: "거래를 삭제할까요?")',
       ),
       assert(
         title == null || semanticLabel == null,
         '제목과 semanticLabel 을 함께 주지 않는다 — 제목이 이름이다',
       );

  /// 묻는 말. 없어도 된다 — 없으면 [semanticLabel].
  final String? title;

  /// 무엇이 어떻게 되는지 · 되돌릴 수 없다는 사실. 늘 둔다.
  final String description;

  /// 취소 버튼 글 — 없으면 알리기(버튼 하나).
  final String? cancelLabel;

  /// 확정 버튼 글 — 동작 이름("삭제" · "나가기"). "확인" 으로 뭉뚱그리지 않는다.
  final String actionLabel;

  /// 확정이 되돌릴 수 없는 일(지우기 · 잃기)이면 criticalSolid, 아니면 neutralSolid.
  final bool destructive;

  /// 취소 버튼 · `Esc`. 없으면 눌러도 일이 없다(견본).
  final VoidCallback? onCancel;
  final FutureOr<void> Function()? onAction;

  /// 확정 버튼 로딩 — 서버 응답을 기다릴 때(누르기를 삼킨다).
  final bool actionLoading;

  /// 제목이 없을 때의 이름.
  final String? semanticLabel;

  /// 열 때 확인창이 초점을 받는다 — 라우트가 켠다.
  final bool requestFocus;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final media = MediaQuery.of(context);
    final maxHeight = (media.size.height - media.padding.vertical)
        .clamp(0.0, double.infinity)
        .toDouble();
    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: c.bgLayerFloating,
        borderRadius: BorderRadius.circular(PRounded.r5),
      ),
      // 넘치면 제목 · 설명 · 버튼이 함께 스크롤한다(끝 흐림 없음) — alert-dialog.yaml maxHeight · overflowY
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(PSpacing.x5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 제목은 확인창의 이름이 읽는다 — 다시 읽지 않는다
              if (title != null)
                ExcludeSemantics(
                  child: Text(
                    keepAll(title!),
                    style: PTypography.t7.copyWith(
                      color: c.fgNeutral,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.only(
                  top: title == null ? 0 : PSpacing.x1_5,
                ),
                child: Text(
                  keepAll(description),
                  semanticsLabel: description,
                  style: PTypography.t5.copyWith(color: c.fgNeutral),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: PSpacing.x4),
                child: _footer(),
              ),
            ],
          ),
        ),
      ),
    );

    Widget out = Padding(
      padding: const EdgeInsets.symmetric(horizontal: PSpacing.x8),
      child: ConstrainedBox(
        // 높이는 안전 영역 안 화면까지
        constraints: BoxConstraints(maxWidth: _maxWidth, maxHeight: maxHeight),
        child: card,
      ),
    );
    // 이름 — 제목(또는 semanticLabel)
    out = Semantics(
      container: true,
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      role: SemanticsRole.alertDialog,
      label: title ?? semanticLabel,
      child: out,
    );
    // 처음 초점 — 확인창(컨테이너). 버튼에 가지 않는다
    out = Focus(
      autofocus: requestFocus,
      debugLabel: 'PAlertDialog',
      skipTraversal: true,
      child: out,
    );
    // Esc = 취소(WidgetsApp 의 기본 단축키가 DismissIntent 로 보낸다)
    out = Actions(
      actions: {
        DismissIntent: CallbackAction<DismissIntent>(
          onInvoke: (_) {
            onCancel?.call();
            return null;
          },
        ),
      },
      child: out,
    );
    // 좌우 안전 영역을 뺀 자리의 가운데 — 옆 상태 칸이 있는 폴더블에서도 본문과 같은 세로 줄에 선다
    return Padding(
      padding: EdgeInsets.only(
        left: media.padding.left,
        right: media.padding.right,
      ),
      child: Center(child: out),
    );
  }

  Widget _footer() {
    final action = PButton(
      label: actionLabel,
      variant: destructive
          ? PButtonVariant.criticalSolid
          : PButtonVariant.neutralSolid,
      loading: actionLoading,
      onPressed: onAction ?? () {},
    );
    if (cancelLabel == null) {
      return Row(children: [Expanded(child: action)]);
    }
    // 짝 버튼 — 한 줄에 반씩, 한 라벨이 반 폭을 넘으면 세로(확정이 위). 시트 · 확인창 바닥은 이 부품(button.md)
    return PResponsivePair(
      primary: action,
      secondary: PButton(
        label: cancelLabel!,
        variant: PButtonVariant.neutralWeak,
        onPressed: onCancel ?? () {},
      ),
    );
  }
}

/// Alert Dialog 를 띄우는 길 — `PAlertDialog.show(context, …)`.
///
/// ```dart
/// final ok = await PAlertDialog.show(
///   context,
///   title: '거래를 삭제할까요?',
///   description: '삭제한 거래는 되돌릴 수 없어요.',
///   cancelLabel: '취소',
///   actionLabel: '삭제',
///   destructive: true,
/// );
/// if (ok) await remove();
/// ```
///
/// 딤 위 화면 정중앙에 뜬다. 바깥(딤)을 눌러도 닫히지 않는다 — 고르지 않고 지나가지 못하게. 뒤로 가기 · `Esc` 는
/// 취소와 같다. 버튼을 누르면 닫힌다. 확정이 끝날 때까지 닫지 않으려면 [onAction] 에 `async` 함수를 준다 — 끝날 때까지
/// 확정 버튼이 로딩이고 다음 누름을 버린다(끝나면 닫는다, 던지면 그대로 두고 오류를 넘긴다).
///
/// 모션 — 열림 200ms(enter-expressive)로 1.3 → 1 크게 나타나고 딤은 100ms, 닫힘은 100ms 로 줄지 않고 사라진다.
/// 모션 줄이기면 150ms 서서히 나타난다. 시트 · 다른 라우트 위에서도 연 순서대로 그 위에 뜬다.
abstract final class PAlertDialog {
  /// 확인창을 띄우고 확정을 눌렀으면 true, 취소 · 뒤로 가기 · `Esc` 면 false 를 돌려준다.
  static Future<bool> show(
    BuildContext context, {
    String? title,
    required String description,
    String? cancelLabel,
    required String actionLabel,
    bool destructive = false,
    FutureOr<void> Function()? onAction,
    String? semanticLabel,
    bool useRootNavigator = true,
    void Function(Object error)? onActionError,
  }) async {
    final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
    final route = _PAlertDialogRoute(
      themes: captureOverlayThemes(context, navigator),
      reduceMotion: MediaQuery.maybeDisableAnimationsOf(context) ?? false,
      builder: (_) => _AlertHost(
        title: title,
        description: description,
        cancelLabel: cancelLabel,
        actionLabel: actionLabel,
        destructive: destructive,
        onAction: onAction,
        onActionError: onActionError,
        semanticLabel: semanticLabel,
      ),
    );
    return await navigator.push<bool>(route) ?? false;
  }

  /// 작성 중 나가기 — 바뀐 값이 있을 때 닫기 전에 묻는다. 나가면 true, 계속 작성하면 false.
  static Future<bool> confirmLeave(
    BuildContext context,
    PLeaveConfirmCopy copy, {
    bool useRootNavigator = true,
  }) => show(
    context,
    title: copy.title,
    description: copy.description,
    cancelLabel: copy.stayLabel,
    actionLabel: copy.leaveLabel,
    destructive: true,
    useRootNavigator: useRootNavigator,
  );
}

/// 확인창 라우트 — 딤은 직접 그린다(시간 · 곡선이 확인창과 다르다).
class _PAlertDialogRoute extends PopupRoute<bool> {
  _PAlertDialogRoute({
    required this.themes,
    required this.reduceMotion,
    required this.builder,
  });

  final CapturedThemes themes;
  final bool reduceMotion;
  final WidgetBuilder builder;

  // 바깥은 무시한다 — 라우트 장벽은 막기만 하고(딤은 아래에서 따로 그린다) 눌러도 닫지 않는다
  @override
  bool get barrierDismissible => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  // 열림 200ms(모션 줄이기면 150ms) · 닫힘 100ms
  @override
  Duration get transitionDuration => reduceMotion ? PDuration.d3 : PDuration.d4;

  @override
  Duration get reverseTransitionDuration => PDuration.d2;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => themes.wrap(
    DefaultTextStyle.merge(
      style: const TextStyle(decoration: TextDecoration.none),
      // 확인창 위에도 스낵바가 보이게 하는 층 — 투명 Scaffold 로 감싼다(DESIGN Z-index: 스낵바가 확인창 위). 라우트에
      // Scaffold 가 없으면 전역 ScaffoldMessenger 의 띠가 아래 페이지에 그려져 딤에 덮인다. 시트의 `_SheetToastLayer`
      // (`p_modal.dart`)와 같은 방법이다 — 새 messenger 를 두지 않으므로 확인창을 닫아도 페이지 쪽 띠는 남는다.
      child: Scaffold(
        backgroundColor: const Color(0x00000000),
        resizeToAvoidBottomInset: false,
        body: Builder(builder: builder),
      ),
    ),
  );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // 딤 — 열림 100ms enter · 닫힘 100ms exit(확인창 열림이 200ms 라 앞쪽 절반에 끝낸다)
    final dimEnd =
        (PDuration.d2.inMicroseconds / transitionDuration.inMicroseconds).clamp(
          0.0,
          1.0,
        );
    final dim = CurvedAnimation(
      parent: animation,
      curve: Interval(0, dimEnd, curve: PEasing.enter),
      reverseCurve: PEasing.exit.flipped,
    );
    // 확인창 — 열림은 enter-expressive 로 크게 나타나며 줄어든다(모션 줄이기면 enter 로 서서히). 닫힘은 줄지 않고 사라진다
    final card = CurvedAnimation(
      parent: animation,
      curve: reduceMotion ? PEasing.enter : PEasing.enterExpressive,
      reverseCurve: PEasing.exit.flipped,
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        PDimLayer.animated(opacity: dim),
        FadeTransition(
          opacity: card,
          child: AnimatedBuilder(
            animation: card,
            builder: (context, child) {
              final scale =
                  reduceMotion || animation.status == AnimationStatus.reverse
                  ? 1.0
                  : 1.3 - 0.3 * card.value;
              return Transform.scale(scale: scale, child: child);
            },
            child: child,
          ),
        ),
      ],
    );
  }
}

/// 확정이 끝날 때까지 기다리는 상태를 가진 쪽 — 라우트 안에서 [PAlertDialogView] 를 그린다.
class _AlertHost extends StatefulWidget {
  const _AlertHost({
    required this.title,
    required this.description,
    required this.cancelLabel,
    required this.actionLabel,
    required this.destructive,
    required this.onAction,
    required this.onActionError,
    required this.semanticLabel,
  });

  final String? title;
  final String description;
  final String? cancelLabel;
  final String actionLabel;
  final bool destructive;
  final FutureOr<void> Function()? onAction;
  final void Function(Object error)? onActionError;
  final String? semanticLabel;

  @override
  State<_AlertHost> createState() => _AlertHostState();
}

class _AlertHostState extends State<_AlertHost> {
  bool _loading = false;

  Future<void> _action() async {
    final run = widget.onAction;
    if (run != null) {
      setState(() => _loading = true);
      try {
        await run();
      } catch (e) {
        // [PAlertDialog.show] 의 onActionError 가 있으면 오류를 그리로 넘기고 창은 그대로 둔다(알림은 그쪽이 띄운다).
        // 없으면 지금까지처럼 그대로 던진다.
        final handler = widget.onActionError;
        if (handler == null) rethrow;
        handler(e);
        return;
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return PAlertDialogView(
      title: widget.title,
      description: widget.description,
      cancelLabel: widget.cancelLabel,
      actionLabel: widget.actionLabel,
      destructive: widget.destructive,
      semanticLabel: widget.semanticLabel,
      actionLoading: _loading,
      requestFocus: true,
      onCancel: () => Navigator.of(context).pop(false),
      onAction: _action,
    );
  }
}
