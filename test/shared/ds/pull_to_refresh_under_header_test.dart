// DA-27 — 머리가 목록 위에 겹쳐 서는 화면(가계부)에서 당겨서 새로 고침 원이 머리 뒤에 가려지지 않는다.
// 지시자 칸이 머리 높이만큼 아래에서 시작해야 한다. 당기는 동안 목록 글자는 한 번씩만 그려진다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/shared/ds/pull_to_refresh/p_pull_to_refresh.dart';
import 'package:groo_damda_app/shared/ds/scroll_auto_hide/p_scroll_auto_hide.dart';

const _header = 150.0;

Widget _app({required double inset}) => MaterialApp(
  theme: GrooTheme.light(),
  home: Scaffold(
    body: PScrollAutoHide(
      header: const SizedBox(height: _header, child: Text('머리 합계 -29,430원')),
      builder: (ctx, controller, h) => PPullToRefresh(
        indicatorTopInset: inset == 0 ? 0 : h,
        onRefresh: () async {},
        child: ListView(
          controller: controller,
          padding: EdgeInsets.only(top: h),
          children: [
            for (var i = 0; i < 20; i++)
              SizedBox(
                height: 56,
                child: Text(i == 0 ? '날짜 합계 -29,430원' : '거래 $i'),
              ),
          ],
        ),
      ),
    ),
  ),
);

void main() {
  for (final inset in [0.0, 1.0]) {
    testWidgets('당기는 중 원이 머리 아래에 선다 (inset=$inset)', (tester) async {
      await tester.pumpWidget(_app(inset: inset));
      await tester.pumpAndSettle();
      final circle = find.byKey(const ValueKey('pull-to-refresh-circle'));
      final g = await tester.startGesture(const Offset(100, 400));
      await g.moveBy(const Offset(0, 40));
      await g.moveBy(const Offset(0, 100)); // 당김 = 140 * 0.75 = 105 (문턱 넘김)
      await tester.pump();
      final top = tester.getTopLeft(circle).dy;
      final hidden = top < _header;
      expect(hidden, inset == 0, reason: 'inset=$inset 원 top=$top');
      if (inset != 0) {
        expect(top, greaterThanOrEqualTo(_header));
        expect(find.text('날짜 합계 -29,430원'), findsOneWidget);
        expect(find.text('머리 합계 -29,430원'), findsOneWidget);
      }
      await g.up();
      await tester.pumpAndSettle();
    });
  }
}
