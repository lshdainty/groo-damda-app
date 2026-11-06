// 시트 헤더의 좌우 여백을 고정한다.
//
// showPSheet 는 본문 여백을 주지 않고 호출처가 헤더와 같은 24 를 직접 물린다.
// 헤더 쪽 24 가 조용히 바뀌면 이미 24 를 물려 둔 ~50개 호출처가 전부 어긋나므로
// 그 값을 여기서 붙잡아 둔다. (본문을 안 물린 시트가 화면 끝에 붙어 나간 적이 있다)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/spacing.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/shared/widgets/p_modal.dart';
import '../support/plain_text.dart';

void main() {
  testWidgets('시트 제목은 좌 24 에서 시작한다', (tester) async {
    // 폰 폭으로 고정 — 넓은 뷰포트에서는 Material 이 시트 폭을 640 으로 잘라
    // 가운데 정렬해서 좌표가 화면 기준과 어긋난다.
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: GrooTheme.light(),
        home: Builder(
          builder: (ctx) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showPSheet<void>(
                  ctx,
                  title: '기간 선택',
                  shrinkWrap: true,
                  contentBuilder: (_, _) => const Padding(
                    // 호출처가 물리는 표준 본문 여백 — 헤더와 같은 24.
                    padding: EdgeInsets.fromLTRB(
                      PSpace.xl,
                      0,
                      PSpace.xl,
                      PSpace.x16,
                    ),
                    child: Text('본문'),
                  ),
                ),
                child: const Text('열기'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(findText('열기'));
    await tester.pumpAndSettle();

    final titleLeft = tester.getTopLeft(findText('기간 선택')).dx;
    expect(titleLeft, closeTo(PSpace.xl, 0.5));

    // 본문도 같은 지점에서 시작해야 제목과 한 줄로 맞는다.
    final bodyLeft = tester.getTopLeft(findText('본문')).dx;
    expect(bodyLeft, closeTo(titleLeft, 0.5));
  });
}
