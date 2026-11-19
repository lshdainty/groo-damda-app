import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/button/p_responsive_pair.dart';

/// 수정 폼 · 상세 시트의 바닥 줄 — 왼쪽 [삭제](ghost critical large 48, 빨간 글 · 글자만큼의 폭 — bottom-sheet.md 바닥 · button.md 시트 바닥) + 나머지 폭 주 버튼
/// [저장] · [수정](large 48). 새로 만드는 폼에는 [삭제] 가 없다(이 줄 대신 평소 바닥 버튼 하나를 쓴다).
///
/// 짝 버튼([PResponsivePair])의 글자만큼 꼴이다(웹 `ResponsivePair` + `data-fit="content"`) — 큰 글자 · 긴 라벨로 [삭제] 가 반 폭을
/// 넘거나 두 글이 한 줄에 안 들어가면 세로로 쌓고, 주 버튼이 위 · 전체 폭, [삭제] 는 아래 왼쪽 글자만큼이다. [삭제] 를 화면 여백에
/// 붙이려고 안쪽 여백만큼 옮기지 않는다(음수 이동 · flush 없이 바닥 여백 24 에서 버튼이 시작한다).
///
/// 삭제는 확인 창이 따로 묻는다 — 이 줄의 [onDelete] 는 시트를 닫고 확인으로 넘기는 일만 한다. `flush` 를 주지 않는다(ghost 의
/// 빨간 글이 flush 에서는 회색으로 덮인다 — button.md). 웹 `shared/ui/groo/form-footer.tsx` 의 폰 모양과 같다.
///
/// [PBottomSheetContent.footerRow] 에 넣는다.
class PFormDeleteFooter extends StatelessWidget {
  PFormDeleteFooter({
    super.key,
    required this.deleteLabel,
    required this.onDelete,
    required this.save,
    this.deleteLoading = false,
  }) : assert(save.size == PButtonSize.large, '저장은 large 48 이다');

  final String deleteLabel;

  /// [PButton.onPressed] 와 같다 — [Future] 를 돌려주면 끝날 때까지 다음 누름을 버린다.
  final FutureOr<void> Function()? onDelete;

  /// [삭제] 가 지우는 중 — 확인 뒤 바로 지우는 상세 시트(일정)의 누름 색 위 로딩 원.
  final bool deleteLoading;

  /// 오른쪽 주 버튼 — Button large.
  final PButton save;

  @override
  Widget build(BuildContext context) {
    return PResponsivePair(
      secondaryFitContent: true,
      secondary: PButton(
        label: deleteLabel,
        variant: PButtonVariant.ghost,
        ghostColor: PButtonGhostColor.critical,
        size: PButtonSize.large,
        loading: deleteLoading,
        onPressed: onDelete,
      ),
      primary: save,
    );
  }
}
