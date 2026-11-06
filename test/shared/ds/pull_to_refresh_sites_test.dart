// 당겨서 새로 고침 호출부는 새로 받기가 끝날 때까지 기다려야 한다 — invalidate 만 하고 바로 끝나면 원이 0.5초 만에 사라지고
// 실패해도 예외가 안 올라와 알림이 안 뜬다(progress-circle.md "끝날 때까지"). 모든 호출부를 훑는다.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PPullToRefresh 호출부 모두 onRefresh 가 await 하거나 Future 를 돌려준다', () {
    final bad = <String>[];
    var sites = 0;
    for (final f in Directory('lib/features').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final s = f.readAsStringSync();
      var i = s.indexOf('PPullToRefresh(');
      while (i >= 0) {
        sites++;
        final end = s.indexOf('child:', i);
        final seg = s.substring(i, end);
        final awaits = seg.contains('await ');
        final returnsFuture = RegExp(
          // 함수를 그대로 넘긴 것(`_reload` · `refresh`)은 Future 를 돌려준다
          r'onRefresh:\s*(\w+|\(\)\s*=>\s*\w+\(\))\s*,',
        ).hasMatch(seg);
        if (!awaits && !returnsFuture)
          bad.add('${f.path}: ${seg.split('\n').take(3).join(' ')}');
        i = s.indexOf('PPullToRefresh(', i + 1);
      }
    }
    expect(sites, 21);
    expect(bad, isEmpty);
  });
}
