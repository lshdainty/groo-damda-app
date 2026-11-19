// 시트 바닥 왼쪽 [삭제] + 주 버튼(bottom-sheet.md "머리 · 본문 · 바닥" · "닫기 버튼과 바닥 버튼") — [삭제] 는 글자만큼(좌우 여백 + 글),
// 주 버튼이 남은 폭. 큰 글자 · 긴 라벨로 한 줄에 안 들어가면 짝 버튼 판정대로 쌓고 주 버튼이 위 · 전체 폭, [삭제] 는 아래 왼쪽 글자만큼
// (웹 `ResponsivePair` + `data-fit="content"` 와 같다).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/button/p_responsive_pair.dart';
import 'package:groo_damda_app/shared/forms/form_delete_footer.dart';
import '../../support/real_fonts.dart';

// 390 폭 시트의 바닥 — 좌우 화면 여백 24 를 뺀 342
const _pairWidth = 390.0 - 2 * PSpacing.globalGutter;

Widget _host({
  required double scale,
  String delete = '삭제',
  String primary = '저장',
}) => MaterialApp(
  theme: GrooTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('ko'),
  home: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
    child: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: _pairWidth,
          child: PFormDeleteFooter(
            deleteLabel: delete,
            onDelete: () {},
            save: PButton(
              label: primary,
              size: PButtonSize.large,
              onPressed: () {},
            ),
          ),
        ),
      ),
    ),
  ),
);

Finder _btn(String label) =>
    find.byWidgetPredicate((w) => w is PButton && w.label == label);

double _natural(WidgetTester tester, String label) => tester
    .widget<PButton>(_btn(label))
    .naturalWidth(tester.element(_btn(label)));

void main() {
  setUpAll(loadRealFonts);

  testWidgets('100% — [삭제] 는 글자 + 좌우 여백 20 · 20, [저장] 이 남은 폭(반씩 나누지 않는다)', (
    tester,
  ) async {
    await tester.pumpWidget(_host(scale: 1));
    expect(find.byKey(const ValueKey('pair-row')), findsOneWidget);
    final del = tester.getRect(_btn('삭제'));
    final save = tester.getRect(_btn('저장'));
    final natural = _natural(tester, '삭제');
    // 글자만큼 — 글 폭 + 좌우 여백(large 20 · 20)
    expect(del.width, closeTo(natural, 0.5));
    expect(natural, lessThan(2 * PSpacing.x5 + 40), reason: '"삭제" 두 글자 + 여백');
    expect(del.width, lessThan((_pairWidth - kResponsivePairGap) / 2));
    // 왼쪽 끝은 바닥 여백 그대로 — 음수 이동 · flush 없음
    expect(del.left, 0);
    expect(tester.widget<PButton>(_btn('삭제')).flush, isNull);
    // 주 버튼이 남은 폭 — 간격 8 다음부터 오른쪽 끝까지
    expect(save.left, closeTo(del.right + kResponsivePairGap, 0.5));
    expect(save.right, closeTo(_pairWidth, 0.5));
    expect(save.center.dy, del.center.dy);
    expect(del.height, 48);
    expect(save.height, 48);
  });

  testWidgets(
    '큰 글자 — 두 글이 한 줄에 안 들어가면 쌓는다: 주 버튼이 위 · 전체 폭, [삭제] 는 아래 왼쪽 글자만큼',
    (tester) async {
      await tester.pumpWidget(_host(scale: 2, primary: '저장하고 닫기'));
      final d = _natural(tester, '삭제');
      final p = _natural(tester, '저장하고 닫기');
      // [삭제] 는 반 폭 안이지만 두 글 합이 (폭 − 8) 을 넘는다 — 웹 wrap 판정과 같은 갈래
      expect(d, lessThanOrEqualTo((_pairWidth - kResponsivePairGap) / 2));
      expect(d + p, greaterThan(_pairWidth - kResponsivePairGap));
      expect(find.byKey(const ValueKey('pair-column')), findsOneWidget);
      final del = tester.getRect(_btn('삭제'));
      final save = tester.getRect(_btn('저장하고 닫기'));
      expect(save.top, lessThan(del.top), reason: '주 버튼이 위');
      expect(save.width, closeTo(_pairWidth, 0.5));
      expect(del.left, 0);
      expect(del.width, closeTo(d, 0.5), reason: '쌓여도 [삭제] 는 글자만큼');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('큰 글자 — [삭제] 라벨이 반 폭을 넘으면 쌓는다', (tester) async {
    await tester.pumpWidget(
      _host(scale: 2, delete: '이 항목 모두 삭제', primary: '수정'),
    );
    final d = _natural(tester, '이 항목 모두 삭제');
    expect(d, greaterThan((_pairWidth - kResponsivePairGap) / 2));
    expect(find.byKey(const ValueKey('pair-column')), findsOneWidget);
    expect(
      tester.getRect(_btn('수정')).top,
      lessThan(tester.getRect(_btn('이 항목 모두 삭제')).top),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('200% 짧은 라벨 — 둘이 들어가면 한 줄 그대로(글자만큼 · 남은 폭)', (tester) async {
    await tester.pumpWidget(_host(scale: 2));
    expect(find.byKey(const ValueKey('pair-row')), findsOneWidget);
    final del = tester.getRect(_btn('삭제'));
    final save = tester.getRect(_btn('저장'));
    expect(del.width, closeTo(_natural(tester, '삭제'), 0.5));
    expect(save.right, closeTo(_pairWidth, 0.5));
    expect(tester.takeException(), isNull);
  });

  test('글자만큼 판정 — [삭제] ≤ (폭 − 8) ÷ 2 이고 두 글 합 ≤ 폭 − 8', () {
    // 342 − 8 = 334 → 반 167
    bool fits(double p, double s) =>
        PResponsivePair.fitsInRow(342, p, s, secondaryFitContent: true);
    expect(fits(200, 80), isTrue, reason: '주 버튼은 반 폭을 넘어도 남은 폭 안이면 한 줄');
    expect(fits(254, 80), isTrue);
    expect(fits(255, 80), isFalse, reason: '합이 334 를 넘는다');
    expect(fits(100, 167), isTrue);
    expect(fits(100, 168), isFalse, reason: '[삭제] 가 반 폭을 넘는다');
    // 반씩 나누는 기본 판정과 다르다 — 주 200 은 반 폭(167)을 넘어 기본이면 쌓인다
    expect(PResponsivePair.fitsInRow(342, 200, 80), isFalse);
  });
}
