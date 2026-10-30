import 'package:groo_damda_app/features/memo/domain/memo.dart';
import 'package:groo_damda_app/features/memo/domain/memo_meta.dart';
import 'package:groo_damda_app/features/memo/domain/memo_tag.dart';

/// 메모 화면의 셈(I-15 4) — 거르기 · 정렬 · 칩 차례. 웹 `pages/memo/model/memo-list.ts` 와 같은 규칙이다.

/// 칩 줄의 "전체" 를 가리키는 거르기 값 — '태그 없음' sentinel([kMemoNoTagKey])과 겹치지 않는 비문자(U+FFFE)다.
const kMemoAllKey = '\u{FFFE}';

/// 칩 하나 — [key] 는 거르기 값([kMemoNoTagKey] 가 "태그 없음"), [count] 는 늘 전체 기준.
class MemoTagChip {
  const MemoTagChip({required this.key, required this.count});
  final String key;
  final int count;

  @override
  bool operator ==(Object other) =>
      other is MemoTagChip && other.key == key && other.count == count;

  @override
  int get hashCode => Object.hash(key, count);

  @override
  String toString() => 'MemoTagChip($key, $count)';
}

/// 편집기 · 칩 줄에 놓을 태그 이름 — **서버 마스터 ∪ 메모에 남은 이름**. 둘 다 비면 빈 목록이다(이름을 지어내지 않는다 — QA #105).
///
/// 순서는 서버가 준 순서를 먼저 두고, 마스터에 없는 이름을 뒤에 붙인다.
List<String> memoTagOptions(
  Iterable<MemoTag>? serverTags,
  Iterable<Memo> memos,
) {
  final names = <String>[
    for (final t in serverTags ?? const <MemoTag>[]) t.tagName,
  ];
  for (final m in memos) {
    final v = m.tag?.trim();
    if (v != null && v.isNotEmpty && !names.contains(v)) names.add(v);
  }
  return names;
}

/// 칩 줄 차례 — **설정 태그 차례**(서버 목록) → 메모에만 남은 이름 → **"태그 없음"(그런 메모가 있을 때만, 맨 뒤)**.
/// 메모가 하나도 없는 태그는 칩을 만들지 않는다(거르면 0건이 되는 칩을 두지 않는다). "전체" 는 부르는 쪽이 맨 앞에 둔다.
List<MemoTagChip> memoTagChips(
  Iterable<Memo> memos,
  Iterable<MemoTag>? serverTags,
) {
  final counts = <String, int>{};
  for (final m in memos) {
    counts.update(memoTagKey(m), (n) => n + 1, ifAbsent: () => 1);
  }
  final named = [
    for (final name in memoTagOptions(serverTags, memos))
      if (counts.containsKey(name))
        MemoTagChip(key: name, count: counts[name]!),
  ];
  final none = counts[kMemoNoTagKey];
  return [
    ...named,
    if (none != null) MemoTagChip(key: kMemoNoTagKey, count: none),
  ];
}

/// 검색(제목 + 본문, 대소문자 무시) + 태그 거르기 → 고정 먼저 → 수정 시각 내림.
List<Memo> filterMemos(Iterable<Memo> memos, String query, String tagFilter) {
  final q = query.trim().toLowerCase();
  final out = <Memo>[
    for (final m in memos)
      if ((tagFilter == kMemoAllKey || memoTagKey(m) == tagFilter) &&
          (q.isEmpty ||
              '${m.title ?? ''}\n${m.content ?? ''}'.toLowerCase().contains(q)))
        m,
  ];
  out.sort((a, b) {
    if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
    return (b.modifyAt ?? '').compareTo(a.modifyAt ?? '');
  });
  return out;
}
