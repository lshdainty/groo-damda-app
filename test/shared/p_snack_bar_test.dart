import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/app/theme/tokens.dart';
import 'package:groo_damda_app/shared/widgets/p_button.dart';
import 'package:groo_damda_app/shared/widgets/p_snack_bar.dart';
import '../support/plain_text.dart';

/// 스낵바는 화면을 띄워 봐야 깨지는 게 보인다 — Material 은 behavior/padding/margin
/// 조합에 assert 가 걸려 있어 analyze 로는 안 잡힌다.
///
/// 색 자체보다 "severity 색으로 배경을 칠하지 않는다" 를 못 박는다. 예전엔 성공 한 번에
/// 화면 하단이 통째로 초록 막대가 됐다.
Widget _host(void Function(BuildContext) onTap, {Brightness? brightness}) {
  return MaterialApp(
    theme: brightness == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () => onTap(context),
            child: const Text('show'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  for (final severity in PSnackSeverity.values) {
    testWidgets('$severity — 예외 없이 뜨고 메시지가 보인다', (tester) async {
      await tester.pumpWidget(
        _host((c) => showPSnackBar(c, '테스트 메시지', severity: severity)),
      );
      await tester.tap(findText('show'));
      await tester.pump(); // 스낵바 삽입
      await tester.pump(const Duration(milliseconds: 400)); // 등장 애니메이션

      expect(findText('테스트 메시지'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('severity 색이 배경이 아니라 아이콘에만 쓰인다', (tester) async {
    await tester.pumpWidget(
      _host((c) => showPSnackBar(c, '저장했어요', severity: PSnackSeverity.success)),
    );
    await tester.tap(findText('show'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Material SnackBar 자체는 투명 — 색은 우리가 그린 컨테이너가 쥔다.
    final bar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(bar.backgroundColor, Colors.transparent);

    // 아이콘이 붙어야 성공을 알아볼 수 있다(neutral 만 아이콘 없음).
    expect(
      find.descendant(of: find.byType(SnackBar), matching: find.byType(Icon)),
      findsOneWidget,
    );
  });

  testWidgets('neutral 은 아이콘 없이 글만', (tester) async {
    await tester.pumpWidget(_host((c) => showPSnackBar(c, '그냥 알림')));
    await tester.tap(findText('show'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.descendant(of: find.byType(SnackBar), matching: find.byType(Icon)),
      findsNothing,
    );
  });

  testWidgets('다크 모드에서도 예외 없이 뜬다', (tester) async {
    await tester.pumpWidget(
      _host(
        (c) => showPSnackBar(c, '다크', severity: PSnackSeverity.error),
        brightness: Brightness.dark,
      ),
    );
    await tester.tap(findText('show'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(findText('다크'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // 토스트 면은 불투명한 surface-raised 다(sonner.md ⓐ). 예전 `PToast` 는 severity 색
  // 12% 를 깔아 목록 위에 뜨면 아래 글자("7월 이용 내역 보기")가 토스트 글자와 겹쳐 보였다.
  for (final brightness in Brightness.values) {
    testWidgets('$brightness — 면이 불투명한 surface-raised 이고 그림자가 잘리지 않는다', (
      tester,
    ) async {
      late GrooTokens t;
      await tester.pumpWidget(
        _host((c) {
          t = c.tokens;
          showPSnackBar(c, '안내', severity: PSnackSeverity.info);
        }, brightness: brightness),
      );
      await tester.tap(findText('show'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final card = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(SnackBar),
              matching: find.byType(Container),
            )
            .first,
      );
      final deco = card.decoration! as BoxDecoration;
      expect(deco.color, t.bgSurfaceRaised);
      expect(deco.color!.a, 1.0, reason: '비치는 면이면 아래 내용이 겹쳐 보인다');
      expect(deco.border, isNull, reason: '테두리 없음(sonner.md 2026-08-21)');
      expect(deco.boxShadow, t.shadowMd);
      // SnackBar 기본 Clip.hardEdge 는 카드 밖에 그리는 그림자를 잘라 버린다.
      expect(
        tester.widget<SnackBar>(find.byType(SnackBar)).clipBehavior,
        Clip.none,
      );
    });
  }

  testWidgets('버튼은 카드 안 글 아래 줄 오른쪽 끝의 SM primary 이고, 누르면 닫히며 콜백이 돈다', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        (c) => showPSnackBar(
          c,
          '이미 결제가 끝난 회차예요. 기록만 바뀌고 계좌 잔액은 그대로예요.',
          severity: PSnackSeverity.info,
          duration: const Duration(seconds: 6),
          actionLabel: '잔액 고치기',
          onAction: () => taps++,
        ),
      ),
    );
    await tester.tap(findText('show'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final button = findWidgetWithText(PButton, '잔액 고치기');
    expect(button, findsOneWidget);
    final pb = tester.widget<PButton>(button);
    expect(pb.size, PButtonSize.sm);
    expect(pb.variant, PButtonVariant.primary);
    // 카드(면을 그리는 Container) 안에 있다 — SnackBar.action 처럼 카드 밖 투명한 자리에
    // 뜨지 않는다.
    final card = find
        .descendant(of: find.byType(SnackBar), matching: find.byType(Container))
        .first;
    expect(find.descendant(of: card, matching: button), findsOneWidget);
    final cardRect = tester.getRect(card);
    final buttonRect = tester.getRect(button);
    expect(cardRect.contains(buttonRect.center), isTrue);
    // 글 옆이 아니라 아래 줄(sonner.md 2026-09-22) — 옆에 두면 글 폭이 버튼만큼 줄어
    // 같은 문구가 한 줄 더 접힌다.
    final textRect = tester.getRect(findTextContaining('이미 결제가'));
    expect(buttonRect.top, greaterThanOrEqualTo(textRect.bottom));
    // 오른쪽 끝 — 카드 안쪽 여백(16) 에 붙는다.
    expect(
      buttonRect.right,
      moreOrLessEquals(cardRect.right - 16, epsilon: 0.5),
    );

    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('버튼 이름만 있고 콜백이 없으면 버튼을 그리지 않는다', (tester) async {
    await tester.pumpWidget(
      _host((c) => showPSnackBar(c, '안내', actionLabel: '잔액 고치기')),
    );
    await tester.tap(findText('show'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(findText('잔액 고치기'), findsNothing);
  });

  testWidgets('replace 는 액션 띠까지 걷고 바로 띄운다', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(_host((c) => ctx = c));
    await tester.tap(findText('show'));

    showPSnackBar(
      ctx,
      '액션 띠',
      duration: const Duration(seconds: 10),
      actionLabel: '되돌리기',
      onAction: () {},
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    showPSnackBar(ctx, '바로', replace: true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(findText('액션 띠'), findsNothing);
    expect(findText('바로'), findsOneWidget);
  });

  // ── 액션 띠는 끝날 때까지 지킨다(알림 결정 1B, I-04 19) ──
  testWidgets('액션이 없는 띠끼리는 바로 바뀐다', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(_host((c) => ctx = c));
    await tester.tap(findText('show'));
    showPSnackBar(ctx, '먼저', duration: const Duration(seconds: 10));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    showPSnackBar(ctx, '다음', duration: const Duration(seconds: 10));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(findText('먼저'), findsNothing);
    expect(findText('다음'), findsOneWidget);
  });

  testWidgets('액션 띠가 떠 있으면 새 띠는 그 띠가 끝난 뒤(시간)에 온다', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(_host((c) => ctx = c));
    await tester.tap(findText('show'));
    showPSnackBar(
      ctx,
      '삭제했어요',
      duration: const Duration(seconds: 6),
      actionLabel: '되돌리기',
      onAction: () {},
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    showPSnackBar(ctx, '새 띠');
    await tester.pump(const Duration(milliseconds: 400));
    expect(findText('삭제했어요'), findsOneWidget, reason: '액션 띠를 지킨다');
    expect(findText('새 띠'), findsNothing);
    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(milliseconds: 600));
    expect(findText('삭제했어요'), findsNothing);
    expect(findText('새 띠'), findsOneWidget);
  });

  testWidgets('액션을 누르면 그 띠가 끝나고 기다리던 띠가 뜬다', (tester) async {
    late BuildContext ctx;
    var undone = 0;
    await tester.pumpWidget(_host((c) => ctx = c));
    await tester.tap(findText('show'));
    showPSnackBar(
      ctx,
      '삭제했어요',
      duration: const Duration(seconds: 6),
      actionLabel: '되돌리기',
      onAction: () => undone++,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    showPSnackBar(ctx, '새 띠');
    await tester.pump();
    await tester.tap(findText('되돌리기'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(undone, 1);
    expect(findText('새 띠'), findsOneWidget);
  });

  testWidgets('기다리는 띠는 하나 — 기다리는 사이 또 오면 마지막 것만', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(_host((c) => ctx = c));
    await tester.tap(findText('show'));
    showPSnackBar(
      ctx,
      '삭제했어요',
      duration: const Duration(seconds: 6),
      actionLabel: '되돌리기',
      onAction: () {},
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    showPSnackBar(ctx, '둘째');
    showPSnackBar(ctx, '셋째');
    await tester.pump(const Duration(seconds: 7));
    await tester.pump(const Duration(milliseconds: 600));
    expect(findText('둘째'), findsNothing);
    expect(findText('셋째'), findsOneWidget);
  });
}
