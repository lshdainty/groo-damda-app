import 'package:flutter/widgets.dart';

/// 줄을 눌러 겹친 시트(카테고리 · 결제 수단 · 날짜 …)를 열기 직전에 입력 초점을 푼다 — 키보드가 내려간다.
///
/// `FocusScope.of(context).unfocus()` 는 시트 자신의 범위가 아니라 **바깥** 범위에서 초점을 풀어서, 시트 범위가 "마지막에
/// 초점이 있던 칸"(거래처)을 기억한 채 남는다. 겹친 시트를 닫으면 그 칸으로 초점이 돌아와 키보드가 다시 올라왔다
/// (시험 2026-11-11 DA-03 6). 여기서는 지금 초점 노드를 직접 풀어 그 기억을 지운다.
///
/// [returnTo](연 줄의 초점 노드)를 주면 초점을 그 줄로 옮겨 둔다 — 시트를 닫았을 때 초점이 연 줄로 돌아온다(키보드 없이).
void releaseFocusForSheet(BuildContext context, {FocusNode? returnTo}) {
  final primary = FocusManager.instance.primaryFocus;
  if (returnTo != null && returnTo.canRequestFocus) {
    returnTo.requestFocus();
    return;
  }
  if (primary != null && primary is! FocusScopeNode) {
    primary.unfocus();
  } else {
    FocusScope.of(context).unfocus();
  }
}
