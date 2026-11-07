// 전역 오류 토스트를 걷었다(I-28-5-9) — 실패는 화면이 자기 자리에서 자기 글로 말한다.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('전역 오류 토스트 심볼이 lib 에 남아 있지 않다', () {
    const banned = [
      'ErrorToastInterceptor',
      'registerErrorToastMessenger',
      'showGlobalSnack',
      'showPSnackBar(',
    ];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final src = f.readAsStringSync();
      for (final b in banned) {
        expect(src.contains(b), isFalse, reason: '${f.path} : $b');
      }
    }
  });

  test('dio 체인에 서버 글을 띄우는 인터셉터가 없다', () {
    final src = File('lib/core/network/dio_provider.dart').readAsStringSync();
    expect(src.contains('Toast'), isFalse);
  });
}
