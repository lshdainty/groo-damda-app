// 구역 머리의 오른쪽 링크는 구역 끝에 붙는다 — 제목 · 꼬리가 어떤 길이여도.
//
// 제목을 Flexible 로 감싼 채 Spacer 를 두면 둘이 남은 폭을 반씩 나눠 링크가 가운데로 오고 긴 제목은 반 폭에서
// 잘렸다(I-01 보정 렌더 — 홈 "자세히" · 자산 그룹 합계 · 예산 "최근 6개월 예산 이…").
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/shared/widgets/p_flat_section.dart';
import '../support/plain_text.dart';

Future<void> _pump(WidgetTester t, PFlatSection section) async {
  await t.pumpWidget(
    MaterialApp(
      theme: GrooTheme.light(),
      home: Scaffold(
        body: Center(child: SizedBox(width: 342, child: section)),
      ),
    ),
  );
}

void main() {
  const trailingKey = ValueKey('trailing');
  const cases = {
    '짧은 제목': PFlatSection(
      title: '예산',
      trailing: Text('전체', key: trailingKey),
      child: SizedBox(),
    ),
    '제목 + 꼬리': PFlatSection(
      title: '오늘 쓴 돈',
      titleSuffix: Text('−13,450원'),
      trailing: Text('전체', key: trailingKey),
      child: SizedBox(),
    ),
    '긴 제목': PFlatSection(
      title: '최근 6개월 예산 이행률 아주 긴 제목이 들어가는 자리',
      trailing: Text('한도 대비 지출 %', key: trailingKey),
      child: SizedBox(),
    ),
  };

  cases.forEach((name, section) {
    testWidgets('$name — 링크 끝 = 구역 끝', (t) async {
      await _pump(t, section);
      final sectionRight = t.getTopRight(find.byType(PFlatSection)).dx;
      final trailingRight = t.getTopRight(find.byKey(trailingKey)).dx;
      expect(trailingRight, moreOrLessEquals(sectionRight));
    });
  });

  testWidgets('짧은 제목은 잘리지 않는다', (t) async {
    await _pump(t, cases['짧은 제목']!);
    final title = t.renderObject<RenderParagraph>(findText('예산'));
    expect(title.didExceedMaxLines, isFalse);
  });
}
