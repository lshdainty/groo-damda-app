// 거래 행 위젯은 **앱에 하나뿐**이어야 한다(사용자 결정 2026-09-14 —
// "가계부의 리스트는 동일 레이아웃으로 사용해놔: 검색, 가계부리스트, 상세행, 홈").
//
// 한동안 둘이었다. 2026-05-06 에 만든 ExpenseRow 를 2026-05-20 에 공용
// PExpenseRow 로 옮기려던 리팩터가 **홈 하나까지만 가고 멈췄고**, 그 뒤 결정들이
// 원본에만 들어갔다 — 행 금액 색 중립화(2026-07-27 `73449cf`), 날짜 헤더와의
// 정렬(2026-08-19). 그래서 "공용" 이라는 이름을 단 쪽이 오히려 낡아 있었고,
// 검색을 거기에 맞췄다가 홈·검색만 금액이 지출/수입 색으로 칠해졌다.
//
// 이 파일은 그 재발을 막는다. 소스를 읽어 **다른 행 위젯이 다시 생기지 않았는지**
// 와 **네 화면이 모두 같은 것을 쓰는지**를 본다. 위젯을 띄우는 대신 소스를 보는
// 이유는, 화면 넷을 각각 띄우려면 네트워크·라우터·프로바이더를 전부 흉내내야
// 하는데 그건 여기서 보려는 것(어느 위젯을 쓰는가)과 무관하기 때문이다.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _rowWidget = 'lib/features/expense/presentation/widgets/expense_row.dart';

/// 거래 목록을 그리는 네 화면.
const _screens = {
  // 날짜 묶음(머리 + 줄)은 I-07 에서 expense_screen 밖 ledger_day_group.dart 로 나갔다.
  '가계부': 'lib/features/expense/presentation/widgets/ledger_day_group.dart',
  '검색': 'lib/features/search/presentation/search_screen.dart',
  '거래상세': 'lib/features/expense/presentation/tx_detail_body.dart',
  '홈': 'lib/features/dashboard/presentation/dashboard_screen.dart',
};

void main() {
  test('행 위젯은 하나뿐이다 — 두 번째가 생기면 갈라진다', () {
    expect(
      File(_rowWidget).existsSync(),
      isTrue,
      reason: '$_rowWidget 이 없다 — 옮겼다면 이 파일도 같이 고쳐야 한다',
    );
    // 예전 공용 사본. 되살아나면 안 된다.
    expect(
      File('lib/shared/widgets/p_expense_row.dart').existsSync(),
      isFalse,
      reason: 'PExpenseRow 가 다시 생겼다 — 결정이 한쪽에만 들어가 갈라진다',
    );
  });

  test('네 화면이 모두 같은 행 위젯을 쓴다', () {
    for (final entry in _screens.entries) {
      final src = File(entry.value).readAsStringSync();
      expect(
        src.contains("widgets/expense_row.dart"),
        isTrue,
        reason: '${entry.key}(${entry.value}) 가 공용 행 위젯을 안 쓴다',
      );
      // 이름이 **주석에** 남는 건 괜찮다(왜 합쳤는지가 거기 적혀 있다).
      // 막는 것은 실제 사용 — import 와 생성자 호출이다.
      expect(
        src.contains('p_expense_row.dart'),
        isFalse,
        reason: '${entry.key} 가 옛 공용 행을 import 한다',
      );
      expect(
        src.contains('PExpenseRow('),
        isFalse,
        reason: '${entry.key} 가 옛 공용 행을 그린다',
      );
    }
  });

  test('행 위젯은 탭 동작을 호출부에서 받는다 — 홈은 상세 대신 이동한다', () {
    final src = File(_rowWidget).readAsStringSync();
    // 홈이 갈라져 나갔던 이유가 이것이다. 하드코딩으로 되돌리면 또 갈라진다.
    expect(src.contains('final VoidCallback? onTap'), isTrue);
    expect(
      File(_screens['홈']!).readAsStringSync().contains('onTap:'),
      isTrue,
      reason: '홈이 탭 동작을 안 준다 — 상세 시트가 열려 버린다',
    );
  });
}
