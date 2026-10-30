import 'package:flutter/material.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/chart_palette.dart';

/// 색이 없는 메모의 색 — 파랑(차트 색 base hex). 저장 값은 라이트 hex 그대로다.
const String kMemoDefaultColor = '#2c70bf';

/// 메모 color 값 — null · 빈값이면 파랑. **팔레트 밖 hex 는 그대로 둔다**(폼의 "지금 색" 칸이 지키고, 고르지 않으면 바꾸지 않는다).
String memoColorOrDefault(String? raw) {
  final v = raw?.trim();
  return (v == null || v.isEmpty) ? kMemoDefaultColor : v;
}

/// 줄 앞 점 · 메타 점의 색 — 그 메모 색의 차트 색(라이트 · 다크 자동). 팔레트 밖 hex 도 그린다.
Color memoSwatch(BuildContext context, String? color) => resolveChartColor(
  context,
  memoColorOrDefault(color),
  fallback: context.colors.fgBrand,
);
