// 시트 footer 위에 토스트가 뜬다 — footer([삭제][수정]·[취소][저장])를 가리지 않는다(QA 26, #388 후속).
//
// 토스트는 시트의 투명 Scaffold 에 floating SnackBar 로 그려진다. footer 가 본문 Column 의
// 마지막 줄이던 동안에는 Scaffold 가 footer 를 몰라 토스트를 시트 맨 아래에 띄웠고, 상세에서
// 환불한 뒤 6초짜리 토스트가 [삭제][수정] 을 가렸다. footer 를 Scaffold 의 하단 막대 자리로
// 옮기면 floating 토스트는 그 위에 선다.
//
// 옮겨도 footer 모양·본문 높이·키보드 처리는 그대로여야 한다 — 이 파일이 그걸 붙잡는다.
// shrinkWrap 형은 층이 없으니 그대로다(아래 마지막 테스트).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/spacing.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/widgets/p_modal.dart';
import 'package:groo_damda_app/shared/widgets/p_snack_bar.dart';
import '../support/plain_text.dart';

const _footerKey = ValueKey('sheet-footer-row');
const _bodyKey = ValueKey('sheet-body');

late BuildContext _sheetCtx;
int _deleteTaps = 0;

Future<void> _openSheet(WidgetTester tester, {bool shrinkWrap = false}) async {
  _deleteTaps = 0;
  // 폰 폭 — 넓은 뷰포트에선 Material 이 시트 폭을 잘라 가운데 둔다.
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: GrooTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      home: Scaffold(
        body: Builder(
          builder: (ctx) => TextButton(
            onPressed: () => showPSheet<void>(
              ctx,
              title: '지출 상세',
              shrinkWrap: shrinkWrap,
              contentBuilder: (c, _) {
                _sheetCtx = c;
                return const SizedBox(key: _bodyKey, height: 200);
              },
              footerBuilder: (c) => Row(
                key: _footerKey,
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => _deleteTaps++,
                      child: const Text('삭제'),
                    ),
                  ),
                  const Expanded(
                    child: TextButton(onPressed: null, child: Text('수정')),
                  ),
                ],
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(findText('open'));
  await tester.pumpAndSettle();
}

Finder _inSheet(Finder f) =>
    find.descendant(of: find.byType(DraggableScrollableSheet), matching: f);

void main() {
  testWidgets('토스트가 footer 위에 뜨고 footer 버튼이 그대로 눌린다', (tester) async {
    await _openSheet(tester);
    showPSnackBar(
      _sheetCtx,
      '미리 낸 돈 중 5,000원이 계좌로 돌아왔어요',
      actionLabel: '잔액 고치기',
      onAction: () {},
      duration: const Duration(seconds: 6),
    );
    await tester.pumpAndSettle();

    final toast = tester.getRect(
      _inSheet(findText('미리 낸 돈 중 5,000원이 계좌로 돌아왔어요')),
    );
    final footer = tester.getRect(find.byKey(_footerKey));
    expect(
      toast.bottom,
      lessThanOrEqualTo(footer.top),
      reason: '토스트가 footer 위다',
    );

    // 토스트가 떠 있어도 [삭제] 가 눌린다 — 가려져 있으면 토스트가 탭을 먹는다.
    await tester.tap(findText('삭제'));
    await tester.pump();
    expect(_deleteTaps, 1);

    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();
  });

  testWidgets('footer 모양 그대로 — 좌우 24·위 12·아래 16, 시트 바닥에 붙는다', (tester) async {
    await _openSheet(tester);

    final sheet = tester.getRect(find.byType(DraggableScrollableSheet));
    final footer = tester.getRect(find.byKey(_footerKey));

    expect(footer.left, closeTo(sheet.left + PSpace.xl, 0.5));
    expect(footer.right, closeTo(sheet.right - PSpace.xl, 0.5));
    expect(footer.bottom, closeTo(sheet.bottom - PSpace.lg, 0.5));
    // 본문(스크롤 영역)은 footer 바로 위에서 끝난다 — 위 여백 12 만큼 떨어져.
    final body = tester.getRect(
      find.ancestor(of: find.byKey(_bodyKey), matching: find.byType(Expanded)),
    );
    expect(body.bottom, closeTo(footer.top - PSpace.md, 0.5));
    expect(sheet.height, closeTo(844 * 0.85, 2));
  });

  testWidgets('키보드가 올라오면 footer 도 그 위로 함께 올라온다', (tester) async {
    await _openSheet(tester);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300 * 3);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();

    final footer = tester.getRect(find.byKey(_footerKey));
    expect(footer.bottom, closeTo(844 - 300 - PSpace.lg, 0.5));
  });

  testWidgets('shrinkWrap 시트는 그대로 — footer 가 본문 바로 아래에 붙는다', (tester) async {
    await _openSheet(tester, shrinkWrap: true);

    final body = tester.getRect(find.byKey(_bodyKey));
    final footer = tester.getRect(find.byKey(_footerKey));
    expect(footer.top, closeTo(body.bottom + PSpace.md, 0.5));
    expect(find.byType(DraggableScrollableSheet), findsNothing);
  });
}
