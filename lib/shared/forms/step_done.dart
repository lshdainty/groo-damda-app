import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/shared/ds/button/p_button.dart';

/// 폼 시트 안 한 단계의 머리 오른쪽 "완료" — 친 글을 넣고 줄 칸으로 돌아간다(I-09 29 · I-20 C 19). 닫기 원 자리에 선다
/// ([PBottomSheetContent.headerAction] 에 넣고 `showCloseButton: false`). 글 버튼 36 이 닫기 원 오른쪽 끝(화면 여백 24)에 맞게
/// 4 만큼 오른쪽으로 민다.
class StepDoneButton extends StatelessWidget {
  const StepDoneButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OverflowBox(
      maxWidth: 160,
      alignment: Alignment.centerRight,
      child: Transform.translate(
        offset: const Offset(4, 0),
        child: PButton(
          label: label,
          variant: PButtonVariant.ghost,
          ghostColor: PButtonGhostColor.neutral,
          size: PButtonSize.small,
          onPressed: onPressed,
        ),
      ),
    );
  }
}
