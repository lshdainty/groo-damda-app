// 실제 글꼴(Pretendard)을 시험에 올리는 도우미 — 배치 · 넘침 · 줄 수를 재는 시험은 `setUpAll(loadRealFonts)` 를 부른다.
//
// 시험 기본 글꼴(FlutterTest · Ahem)은 글자마다 1em 네모라 실제 폭과 다르다 — 200% 넘침 · "한 줄" · 줄 높이 시험이 실제
// 화면에서는 일어나지 않는 넘침을 잰다. 앱에 묶인 글꼴 파일(assets/fonts)을 FontLoader 로 올린다. 'FlutterTest' 에도 같은
// 글꼴을 올려 글꼴을 따로 고르지 않는 위젯도 같은 글자로 잰다. 전역(flutter_test_config.dart)으로 켜지 않는다 — 기본 글꼴에
// 맞춘 다른 배치 시험이 있다.
import 'dart:io';

import 'package:flutter/services.dart';

bool _loaded = false;

/// 실제 글꼴(Pretendard)을 'Pretendard' · 'FlutterTest' 이름으로 올린다(파일마다 한 번).
Future<void> loadRealFonts() async {
  if (_loaded) return;
  final bytes = File('assets/fonts/PretendardVariable.ttf').readAsBytesSync();
  for (final family in ['Pretendard', 'FlutterTest']) {
    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.view(bytes.buffer)));
    await loader.load();
  }
  _loaded = true;
}
