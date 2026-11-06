import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/widgets/p_swipe_actions.dart';
import '../support/plain_text.dart';

/// 스와이프는 제스처라 눈으로만 확인하기 어렵다. 특히 <b>안 일어나야 하는 일</b>이
/// 중요하다 — 끝까지 밀어도 지워지지 않고, 확인을 거치지 않으면 실행되지 않는다.
/// 이게 무너지면 사용자가 밀다가 데이터를 잃는다.
Widget _host(List<PSwipeAction> actions, {String label = '행'}) {
  return MaterialApp(
    theme: GrooTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('ko'),
    home: Scaffold(
      body: SlidableAutoCloseBehavior(
        child: ListView(
          children: [
            PSwipeActions(
              actions: actions,
              child: SizedBox(height: 64, child: Center(child: Text(label))),
            ),
          ],
        ),
      ),
    ),
  );
}

/// 트레이가 열릴 만큼 왼쪽으로 민다.
Future<void> _swipeOpen(WidgetTester tester, String label) async {
  await tester.drag(findText(label), const Offset(-250, 0));
  await tester.pumpAndSettle();
}

/// 실제 반복 거래 행 높이(패딩 12×2 + 내용 ~38).
Widget _hostTight(List<PSwipeAction> actions) => MaterialApp(
  theme: GrooTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('ko'),
  home: Scaffold(
    body: SlidableAutoCloseBehavior(
      child: ListView(
        children: [
          PSwipeActions(
            actions: actions,
            child: const SizedBox(height: 62, child: Center(child: Text('행'))),
          ),
        ],
      ),
    ),
  ),
);

void main() {
  testWidgets('액션 3개 — 라벨이 줄바꿈되지 않는다', (tester) async {
    // 반복 거래에 '일시정지'(4글자)를 넣었더니 48px 슬롯 안에서 줄바꿈돼 트레이가
    // 세로로 넘쳤다(BOTTOM OVERFLOWED, 실측). 액션을 빼는 대신 라벨을 두 글자로
    // 줄였다 — 위젯 문서가 "한글 두 글자 권장" 이라고 이미 적어 둔 그대로다.
    await tester.pumpWidget(
      _hostTight([
        PSwipeAction(label: '정지', kind: PSwipeKind.neutral, onSelect: () {}),
        PSwipeAction(label: '수정', kind: PSwipeKind.primary, onSelect: () {}),
        PSwipeAction(
          label: '삭제',
          kind: PSwipeKind.destructive,
          confirmMessage: '지울까요?',
          onSelect: () {},
        ),
      ]),
    );

    await _swipeOpen(tester, '행');

    expect(findText('정지'), findsOneWidget);
    expect(findText('수정'), findsOneWidget);
    expect(findText('삭제'), findsOneWidget);

    // 셋 다 한 줄이어야 한다. 하나라도 접히면 그 슬롯만 키가 커진다.
    final h = tester.getSize(findText('삭제')).height;
    expect(tester.getSize(findText('정지')).height, h);
    expect(tester.getSize(findText('수정')).height, h);
  });

  testWidgets('밀면 액션이 드러난다', (tester) async {
    await tester.pumpWidget(
      _host([
        PSwipeAction(label: '편집', kind: PSwipeKind.primary, onSelect: () {}),
      ]),
    );

    expect(findText('편집'), findsNothing); // 접혀 있을 땐 안 보인다
    await _swipeOpen(tester, '행');
    expect(findText('편집'), findsOneWidget);
  });

  testWidgets('확인 문구가 없는 액션은 바로 실행된다', (tester) async {
    var ran = false;
    await tester.pumpWidget(
      _host([
        PSwipeAction(
          label: '편집',
          kind: PSwipeKind.primary,
          onSelect: () => ran = true,
        ),
      ]),
    );

    await _swipeOpen(tester, '행');
    await tester.tap(findText('편집'));
    await tester.pumpAndSettle();

    expect(ran, isTrue);
  });

  testWidgets('삭제는 확인을 받는다 — 누르는 즉시 실행되지 않는다', (tester) async {
    var deleted = false;
    await tester.pumpWidget(
      _host([
        PSwipeAction(
          label: '삭제',
          kind: PSwipeKind.destructive,
          confirmMessage: '정말 지울까요?',
          onSelect: () => deleted = true,
        ),
      ]),
    );

    await _swipeOpen(tester, '행');
    await tester.tap(findText('삭제'));
    await tester.pumpAndSettle();

    // 다이얼로그가 떴을 뿐 아직 안 지워졌다
    expect(findText('정말 지울까요?'), findsOneWidget);
    expect(deleted, isFalse);
  });

  testWidgets('확인을 취소하면 실행되지 않는다', (tester) async {
    var deleted = false;
    await tester.pumpWidget(
      _host([
        PSwipeAction(
          label: '삭제',
          kind: PSwipeKind.destructive,
          confirmMessage: '정말 지울까요?',
          onSelect: () => deleted = true,
        ),
      ]),
    );

    await _swipeOpen(tester, '행');
    await tester.tap(findText('삭제'));
    await tester.pumpAndSettle();
    await tester.tap(findText('취소'));
    await tester.pumpAndSettle();

    expect(deleted, isFalse);
  });

  testWidgets('확인하면 실행된다', (tester) async {
    var deleted = false;
    await tester.pumpWidget(
      _host([
        PSwipeAction(
          label: '삭제',
          kind: PSwipeKind.destructive,
          confirmMessage: '정말 지울까요?',
          onSelect: () => deleted = true,
        ),
      ]),
    );

    await _swipeOpen(tester, '행');
    await tester.tap(findText('삭제'));
    await tester.pumpAndSettle();
    // 확인 버튼 라벨은 액션 이름이라 트레이의 '삭제' 와 같다 — 다이얼로그 안의 것을 고른다.
    // 다이얼로그 안에도 제목 "삭제" 와 단추 "삭제" 둘이다 — 단추(PButton)를 누른다.
    await tester.tap(
      find.descendant(
        of: find.byType(PAlertDialogView),
        matching: findWidgetWithText(PButton, '삭제'),
      ),
    );
    await tester.pumpAndSettle();

    expect(deleted, isTrue);
  });

  testWidgets('끝까지 밀어도 실행되지 않는다 — 되돌리기가 없다', (tester) async {
    var deleted = false;
    await tester.pumpWidget(
      _host([
        PSwipeAction(
          label: '삭제',
          kind: PSwipeKind.destructive,
          confirmMessage: '정말 지울까요?',
          onSelect: () => deleted = true,
        ),
      ]),
    );

    // 화면 밖까지 크게 민다 — DismissiblePane 을 썼다면 여기서 지워진다
    await tester.drag(findText('행'), const Offset(-2000, 0));
    await tester.pumpAndSettle();

    expect(deleted, isFalse);
    expect(findText('행'), findsOneWidget); // 행이 사라지지도 않았다
  });

  testWidgets('enabled=false 면 감싸지 않고 행을 그대로 통과시킨다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: GrooTheme.light(),
        home: Scaffold(
          body: PSwipeActions(
            enabled: false,
            actions: [PSwipeAction(label: '삭제', onSelect: () {})],
            child: const Text('행'),
          ),
        ),
      ),
    );

    // 데스크톱·태블릿에서 래핑 자체를 걷어내는 경로
    expect(find.byType(Slidable), findsNothing);
    expect(findText('행'), findsOneWidget);
  });

  testWidgets('액션이 없으면 감싸지 않는다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: GrooTheme.light(),
        home: const Scaffold(
          body: PSwipeActions(actions: [], child: Text('행')),
        ),
      ),
    );

    expect(find.byType(Slidable), findsNothing);
  });

  testWidgets('한 번에 한 행만 열린다 — 다른 행을 밀면 먼저 열린 행이 닫힌다', (tester) async {
    // 이 보장은 SlidableAutoCloseBehavior 조상에 기댄다. 앱은 루트에 한 번 두는데,
    // 없으면 행이 여러 개 열린 채로 남는다(실제로 가계부에서 그렇게 나갔다).
    await tester.pumpWidget(
      MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(
          body: SlidableAutoCloseBehavior(
            child: ListView(
              children: [
                for (final name in ['첫째', '둘째'])
                  PSwipeActions(
                    key: ValueKey(name),
                    groupTag: 'same-list',
                    actions: [
                      PSwipeAction(
                        label: '삭제$name',
                        kind: PSwipeKind.destructive,
                        onSelect: () {},
                      ),
                    ],
                    child: SizedBox(
                      height: 64,
                      child: Center(child: Text(name)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    await _swipeOpen(tester, '첫째');
    expect(findText('삭제첫째'), findsOneWidget);

    await _swipeOpen(tester, '둘째');
    expect(findText('삭제둘째'), findsOneWidget);
    // 먼저 연 행은 닫혀 있어야 한다
    expect(findText('삭제첫째'), findsNothing);
  });
}
