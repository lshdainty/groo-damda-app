import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/bottom_sheet_parts.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/bottom_sheet_route.dart';
import 'package:groo_damda_app/shared/ds/overlay/p_overlay.dart';

export 'package:groo_damda_app/shared/ds/bottom_sheet/bottom_sheet_parts.dart';
export 'package:groo_damda_app/shared/ds/bottom_sheet/bottom_sheet_route.dart'
    show kSheetCloseFraction, kSheetCloseVelocity, kSheetDragDelay;

/// Bottom Sheet — 화면 아래에서 올라오는 모달. `PBottomSheet.show(context, builder: …)`.
///
/// 구조는 SEED Bottom Sheet(2026-10-02), 수치 원본은 groo-design `specs/components/bottom-sheet.yaml`(값은
/// `test/fixtures/design_spec/bottom-sheet.json`). 웹(desk-front `src/shared/ds/bottom-sheet`)과 같은 값이다.
///
/// ```dart
/// // 고르기 — 바깥 누르기 · 끌어내리기로 닫힌다
/// await PBottomSheet.show<void>(
///   context,
///   builder: (context) => PBottomSheetContent(
///     title: '기간',
///     description: '고른 기간의 거래만 보여요.',
///     closeLabel: '닫기',
///     flushBody: true,
///     body: PList(children: […]),
///     footer: [PButton(label: '적용', size: PButtonSize.large, onPressed: …)],
///   ),
/// );
///
/// // 입력 폼 — 바깥 · 끌기로 닫히지 않고, 값이 있으면 닫기 전에 묻는다
/// await PBottomSheet.show<bool>(
///   context,
///   form: true,
///   isDirty: () => memo.text.isNotEmpty,
///   leaveCopy: const PLeaveConfirmCopy(…),
///   builder: (context) => PBottomSheetContent(…),
/// );
/// ```
///
/// 첫 초점 — 처음 초점은 시트에 가지만 내용이 첫 자리를 정하면([initialFocus] — 검색 시트의 검색칸) 시트가 그리로 넘겨준다.
/// 내용이 스스로 한 프레임 뒤에 다시 잡지 않는다(시트를 읽던 낭독기가 끊기지 않게). 노드의 주인은 부르는 쪽이다.
///
/// 닫는 길 — 닫기 버튼 · 뒤로 가기 · `Esc` 는 늘 닫고 [isDirty] 가 참이면 먼저 "작성한 내용이 사라져요" 를 묻는다.
/// 바깥(딤) 누르기 · 아래로 끌기는 조회 · 고르기 시트만 닫는다(입력 폼 [form] 은 무시, 손잡이도 없다). 끌기는 놓을 때
/// 0.4px/ms 보다 빠르거나 높이의 25% 이상 내려왔으면 닫고 아니면 200ms exit 로 제자리 — 열린 뒤 0.5초와 본문이 스크롤된
/// 동안은 끌리지 않는다.
///
/// 안의 한 단계 — 시트 안에서 한 단계 들어가 있는 동안([interceptClose])은 닫기 청이 시트를 닫지 않고 그 단계를 닫는 쪽으로 쓰인다.
///
/// 단계마다 규칙이 갈릴 때 — [isForm] 이 있으면 바깥 누르기 · 끌기를 그 순간의 단계로 가른다(일정 목록 · 상세 = 조회, 수정 폼 = 입력).
/// 바깥 누르기 · 끌기 · 닫기 원은 한 단계가 아니라 시트 전체를 닫고, 뒤로 가기 · `Esc` 만 한 단계 뒤로 간다.
///
/// 높이 — 내용만큼, 화면 높이의 90% 를 넘지 않는다(그보다 긴 내용은 페이지로). 키보드가 올라오면 그 위에 서고, 안전
/// 영역은 키보드가 없을 때만 더한다. 손잡이는 [snapPoints] 가 있을 때만 — 누르면 다음(더 높은) 스냅 높이로, 가장 높은
/// 높이에서 누르면 닫는다.
///
/// 모션 — 열림 300ms enter-expressive(딤 300ms enter), 닫힘 200ms exit. 모션 줄이기면 150ms 서서히 나타나고 사라진다.
abstract final class PBottomSheet {
  /// 시트를 띄운다. [builder] 가 [PBottomSheetContent] 를 돌려준다. 닫으면 [PBottomSheetController.close] 에 준 결과
  /// (없으면 null).
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool form = false,
    bool Function()? isDirty,
    PLeaveConfirmCopy? leaveCopy,
    bool Function()? interceptClose,
    bool Function()? isForm,
    List<double>? snapPoints,
    FocusNode? initialFocus,
    bool useRootNavigator = true,
  }) {
    assert(
      isDirty == null || leaveCopy != null,
      '바뀐 값을 살피면(isDirty) 묻는 글(leaveCopy)이 있어야 한다',
    );
    assert(
      snapPoints == null ||
          snapPoints.every((p) => p > 0 && p <= 1) &&
              snapPoints.indexed.every(
                (e) => e.$1 == 0 || e.$2 > snapPoints[e.$1 - 1],
              ),
      '스냅 높이는 화면 높이 비율(0 초과 1 이하)이고 낮은 것부터 늘어난다',
    );
    final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
    return navigator.push<T>(
      PBottomSheetRoute<T>(
        themes: captureOverlayThemes(context, navigator),
        reduceMotion: MediaQuery.maybeDisableAnimationsOf(context) ?? false,
        builder: builder,
        form: form,
        isDirty: isDirty,
        leaveCopy: leaveCopy,
        interceptClose: interceptClose,
        isForm: isForm,
        snapPoints: form ? null : snapPoints,
        initialFocus: initialFocus,
      ),
    );
  }

  /// 시트 안에서 시트를 닫는 길 — 바닥 버튼 · 직접 만든 닫기. 시트 밖이면 오류.
  static PBottomSheetController of(BuildContext context) {
    final controller = maybeOf(context);
    assert(
      controller != null,
      'PBottomSheet.of 는 PBottomSheet.show 의 builder 안에서 쓴다',
    );
    return controller!;
  }

  static PBottomSheetController? maybeOf(BuildContext context) =>
      PBottomSheetScope.maybeOf(context);
}
