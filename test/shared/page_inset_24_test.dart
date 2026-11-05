// 페이지 좌우 인셋은 **24** 다 (QA #163 · #164, 사용자 확정).
//
// 본문은 24 인데 오류·로딩 상태만 16/20 이라 문구가 8px 안쪽에 서 있었다. 화면을
// 띄워도 오류를 내야 보이는 자리라 눈으로는 잘 안 걸린다 — 소스를 읽어 잠근다.
//
// **카드 안쪽은 다른 값이 맞다.** PCard 의 padding 은 그 카드의 내부 여백이고,
// 실제 카드와 스켈레톤이 같기만 하면 된다(예산 히어로 18, 반복 카드 16). 여기서
// 보는 것은 **페이지가 쥐는 좌우**뿐이다.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 화면 전체를 감싸는 스크롤러의 좌우 인셋이 24 여야 하는 파일들.
const _screens = <String>[
  'lib/features/sms/presentation/sms_paste_screen.dart',
  'lib/features/category/presentation/category_screen.dart',
  'lib/features/preset/presentation/preset_screen.dart',
  'lib/features/settings/presentation/hide_amounts_screen.dart',
  'lib/features/notification/presentation/notification_screen.dart',
  'lib/features/constellation/presentation/forest_report_screen.dart',
  'lib/features/dutch_pay/presentation/dutch_pay_screen.dart',
  'lib/features/memo/presentation/memo_screen.dart',
  'lib/features/recurring/presentation/recurring_screen.dart',
  'lib/features/todo/presentation/todo_screen.dart',
  'lib/features/asset/presentation/asset_screen.dart',
];

/// `error:`/로딩 분기 바로 아래에 오는 스크롤러의 padding 줄.
final _stateScroller = RegExp(
  r'(error: \(e, _\) =>|\? ) *(ListView|Padding|SingleChildScrollView)\(\s*\n'
  r'\s*padding: const (EdgeInsets\.[^\n]+)',
);

void main() {
  test('오류·로딩 상태의 좌우 인셋이 16/20 으로 남아 있지 않다', () {
    final bad = <String>[];
    for (final path in _screens) {
      final src = File(path).readAsStringSync();
      for (final m in _stateScroller.allMatches(src)) {
        final pad = m.group(3)!;
        // all(x16)·all(x20) 은 좌우까지 16/20 이 된다 — 본문(24)과 어긋난다.
        if (RegExp(r'all\(PSpace\.x(16|20)\)').hasMatch(pad) ||
            RegExp(r'all\((16|20)\)').hasMatch(pad)) {
          bad.add('$path → $pad');
        }
      }
    }
    expect(bad, isEmpty, reason: '오류·로딩만 본문보다 안쪽에 선다:\n${bad.join('\n')}');
  });

  test('신고된 네 화면에 x20 좌우 인셋이 남아 있지 않다', () {
    // 카테고리 관리 · 금액 가리기는 본문 전체가 20 이었다.
    for (final path in const [
      'lib/features/category/presentation/category_screen.dart',
      'lib/features/settings/presentation/hide_amounts_screen.dart',
    ]) {
      expect(
        File(path).readAsStringSync().contains('PSpace.x20'),
        isFalse,
        reason: '$path 에 x20 이 남았다',
      );
    }
  });
}
