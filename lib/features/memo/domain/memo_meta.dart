import 'package:groo_damda_app/features/memo/domain/memo.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';

/// 메모 태그 표기 — 할 일(`features/todo/domain/todo_meta.dart`)과
/// **같은 규칙을 같은 모양으로** 둔다.
///
/// 두 화면은 사용자에겐 같은 개념이다("태그를 지우면 태그 없음으로 남아요").
/// 한쪽만 고치면 메모는 '태그 없음' 이라 하고 할 일은 '개인' 이라고 하는 상태가
/// 된다 — 실제로 그랬고 그게 QA #103 이다. 이름이 두 벌인 건 담는 필드가 다르기
/// 때문이다(메모 `tag` · 할 일 `category`). 로직은 한 줄도 다르지 않게 유지한다.
/// 웹도 `pages/memo/lib/memo-tags.ts` · `pages/todo/lib/todo-tags.ts` 로 같이 둔다.

/// '태그 없음' 묶음을 가리키는 sentinel — 칩 필터 값과 표시에만 쓰고 **서버로는
/// 나가지 않는다**(편집기는 이 값을 쓰지 않고 `null` 을 싣는다).
///
/// 값은 U+FFFF(비문자)로 할 일 쪽 `kTodoNoTagKey` 와 같다. 태그 이름은 사용자가 치는
/// 글자라 어떤 평범한 문자열도 sentinel 로 쓸 수 없다.
const kMemoNoTagKey = '\u{FFFF}';

/// 칩 필터·집계에서 이 메모가 속할 묶음 키. 태그가 없으면 '태그 없음' 묶음이다.
///
/// 종전엔 빈 태그를 '개인' 으로 채웠다 — 서버가 태그 삭제 때 메모의 태그를 실제로
/// 비우므로(`MemoTagServiceImpl.deleteTag`), 화면이 이름을 지어내면 '개인' 태그를
/// 지운 사용자가 여전히 '개인' 칩을 본다.
String memoTagKey(Memo memo) {
  final v = memo.tag?.trim();
  return (v == null || v.isEmpty) ? kMemoNoTagKey : v;
}

/// 목록 줄 본문 미리보기(I-15 9 · 웹 `MemoRow.tsx:43-48` 의 `block truncate`) — 줄바꿈 · 연속 공백을 공백 하나로 잇고 앞뒤를 정리해 한 줄로 만든다.
/// 웹은 본문 글을 그대로 `white-space: nowrap` 한 줄에 그리므로 브라우저가 공백 · 줄바꿈 덩어리를 공백 하나로 접는다 — 같은 규칙이다.
/// 비었는지(공백뿐)도 이 결과로 본다. 첫 줄만 보이거나 첫 줄이 비면 빈 줄이 되는 것을 막는다.
String memoPreview(String? content) =>
    (content ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();

/// 묶음 키 → 화면 라벨. sentinel 은 번역 문구로 바꿔 그린다 — U+FFFF 를 그대로
/// 그리면 안 보이는 글자 하나가 태그 이름 자리에 남는다.
String memoTagLabel(AppLocalizations l, String key) =>
    key == kMemoNoTagKey ? l.memoTagNone : key;
