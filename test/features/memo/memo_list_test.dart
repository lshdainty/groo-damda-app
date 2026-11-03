// 메모 화면의 셈(I-15 4 · 8) — 거르기 · 정렬 · 칩 차례. 웹 `memo-list.test.ts` 와 같은 규칙이다.
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/features/memo/domain/memo.dart';
import 'package:groo_damda_app/features/memo/domain/memo_list.dart';
import 'package:groo_damda_app/features/memo/domain/memo_meta.dart';
import 'package:groo_damda_app/features/memo/domain/memo_tag.dart';

Memo _m(
  int id,
  String title, {
  String? tag,
  bool pinned = false,
  String? content,
  String? at,
}) => Memo(
  rowId: id,
  title: title,
  content: content,
  tag: tag,
  isPinned: pinned ? 'Y' : 'N',
  modifyAt: at ?? '2026-10-0${id}T00:00:00',
);

MemoTag _t(int id, String name) =>
    MemoTag(rowId: id, tagName: name, userRowId: 1);

void main() {
  memoPreviewTests();
  group('memoTagChips — 설정 태그 차례 → 남은 이름 → 태그 없음(맨 뒤)', () {
    test('서버 목록 차례를 따르고 메모 없는 태그는 칩이 없다', () {
      final chips = memoTagChips(
        [_m(1, 'a', tag: '독서'), _m(2, 'b', tag: '아이디어'), _m(3, 'c', tag: '독서')],
        [_t(1, '아이디어'), _t(2, '여행'), _t(3, '독서')],
      );
      expect(chips.map((c) => c.key), ['아이디어', '독서']);
      expect(chips.map((c) => c.count), [1, 2]);
    });

    test('마스터에 없는 남은 이름은 뒤에 붙고, 태그 없음은 있을 때만 맨 뒤', () {
      final chips = memoTagChips(
        [_m(1, 'a'), _m(2, 'b', tag: '옛태그'), _m(3, 'c', tag: '독서')],
        [_t(1, '독서')],
      );
      expect(chips.map((c) => c.key), ['독서', '옛태그', kMemoNoTagKey]);
    });

    test('태그 없는 메모가 없으면 태그 없음 칩이 없다', () {
      final chips = memoTagChips([_m(1, 'a', tag: '독서')], [_t(1, '독서')]);
      expect(chips.map((c) => c.key), ['독서']);
    });
  });

  group('filterMemos', () {
    final all = [
      _m(1, '장보기', content: '우유', at: '2026-10-01T00:00:00'),
      _m(2, '독서 목록', tag: '독서', pinned: true, at: '2026-10-02T00:00:00'),
      _m(3, '앱 아이디어', tag: '독서', at: '2026-10-03T00:00:00'),
    ];

    test('고정 먼저 → 수정 시각 내림', () {
      expect(filterMemos(all, '', kMemoAllKey).map((m) => m.rowId), [2, 3, 1]);
    });

    test('검색은 제목 + 본문 · 대소문자 무시', () {
      expect(filterMemos(all, '우유', kMemoAllKey).map((m) => m.rowId), [1]);
      expect(filterMemos(all, '  앱 ', kMemoAllKey).map((m) => m.rowId), [3]);
    });

    test('태그 거르기 — 태그 없음 sentinel 도 거른다', () {
      expect(filterMemos(all, '', '독서').map((m) => m.rowId), [2, 3]);
      expect(filterMemos(all, '', kMemoNoTagKey).map((m) => m.rowId), [1]);
    });
  });
}

// 목록 줄 본문 미리보기(웹 `MemoRow.tsx` 의 한 줄 말줄임과 같은 규칙) — 작성만 했다.
void memoPreviewTests() {
  group('memoPreview — 줄바꿈 · 연속 공백을 공백 하나로, 앞뒤 정리', () {
    test('첫 줄이 비어도 둘째 줄이 보인다', () {
      expect(memoPreview('\n\n둘째 줄'), '둘째 줄');
    });
    test('줄바꿈들은 공백 하나로 이어진다', () {
      expect(memoPreview('1. 숲의 시간\n2. 작은 습관의 힘'), '1. 숲의 시간 2. 작은 습관의 힘');
      expect(memoPreview('가\r\n\r\n나   다\t라'), '가 나 다 라');
    });
    test('공백뿐 · null 은 빈 글(줄을 두지 않는다)', () {
      expect(memoPreview('  \n \t '), '');
      expect(memoPreview(null), '');
    });
    test('앞뒤 공백 · 빈 줄은 정리', () {
      expect(memoPreview('  들여쓴 줄\n\n'), '들여쓴 줄');
    });
  });
}
