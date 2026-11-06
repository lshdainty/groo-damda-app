// 의미 이름 찾기 — ds 목록 · 표는 값을 줄 이름에 합친다(03-D 결정 4 A, list_row MergeSemantics). 그래서 "안 읽음" 같은 조각은
// 따로 된 노드가 아니라 줄 이름("오늘 알림⏎안 읽음⏎…") 안에 있다. 보조 기술은 그 줄을 읽을 때 조각도 읽는다.
import 'package:flutter_test/flutter_test.dart';

/// 이름에 [part] 가 **한 줄로** 들어 있는 의미 노드 — 합친 이름은 조각마다 줄을 바꾼다.
Finder findSemanticsContaining(String part) =>
    find.bySemanticsLabel(RegExp('(^|\\n)${RegExp.escape(part)}(\\n|\$)'));
