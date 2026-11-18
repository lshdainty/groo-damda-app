// 안드로이드 14+ 의 비선형 글자 크기를 시험에서 흉내 낸다.
//
// 안드로이드는 글자 크기 설정(font_scale)을 글자마다 같은 배율로 곱하지 않는다 — 작은 글은 설정만큼 커지고 큰 글은 덜 커진다
// (AOSP `FontScaleConverterFactory`). Flutter 는 이 셈을 `MediaQuery.textScalerOf` 로 그대로 받는다
// (`platformDispatcher.scaleFontSize`). 그래서 `scale(108)` 같은 상자 셈은 글자보다 덜 커져, iOS · 선형 시험에서는 맞던 상자가
// 안드로이드 큰 글자에서만 글을 못 담는다. QA 조건 "안드로이드 글자 200%" 를 재현할 때 쓴다.
import 'package:flutter/widgets.dart';

/// 안드로이드 font_scale 2.0 의 sp → dp 표(AOSP `FontScaleConverterFactory`). 표 밖은 끝 점의 비율(100 → 100, 1배)을 잇는다.
const _from2 = [8.0, 10.0, 12.0, 14.0, 18.0, 20.0, 24.0, 30.0, 100.0];
const _to2 = [16.0, 20.0, 24.0, 26.0, 30.0, 34.0, 36.0, 38.0, 100.0];

/// 안드로이드 글자 200%(font_scale 2.0) 비선형 배율.
class AndroidNonlinearTextScaler extends TextScaler {
  const AndroidNonlinearTextScaler();

  @override
  double scale(double fontSize) {
    if (fontSize <= 0) return fontSize;
    if (fontSize < _from2.first) return fontSize * _to2.first / _from2.first;
    if (fontSize >= _from2.last) return fontSize * _to2.last / _from2.last;
    for (var i = 1; i < _from2.length; i++) {
      if (fontSize <= _from2[i]) {
        final t = (fontSize - _from2[i - 1]) / (_from2[i] - _from2[i - 1]);
        return _to2[i - 1] + t * (_to2[i] - _to2[i - 1]);
      }
    }
    return fontSize;
  }

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => 2.0;

  @override
  bool operator ==(Object other) => other is AndroidNonlinearTextScaler;

  @override
  int get hashCode => (AndroidNonlinearTextScaler).hashCode;
}
