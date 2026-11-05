/// 상세 시트 안 한 단계(나누기 · 더치페이 · 반복으로 만들기)가 시트의 닫는 길에 알리는 자리 — 단계의 주인은 단계 위젯이라
/// 시트 밖에서 이 줄로 닿는다.
class StepProbe {
  /// 바뀐 값이 있는가(처음 값과 견줘).
  bool Function() dirty = () => false;

  /// 한 단계가 열려 있거나 이 단계를 닫는 중이면 그 일을 하고 참 — 시트는 닫지 않는다. 뒤로 가기 · Esc 한 번 = 한 단계 뒤.
  bool Function() interceptClose = () => false;
}
