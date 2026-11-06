// I-10 10-1 에서 가계부 · 검색과 함께 쓰도록 넓힌 공용 부품 — 거래 쪽 겉모습은 그대로이고 할 일이 쓰는 자리만 더해졌다.
//   · PDayHeaderRow — 날짜 글 + 오른쪽 자리(슬롯). 거래는 합계, 할 일은 "2/5 완료"
//   · LedgerMonthNav — 추가 단추 없이 · 거르기 알림 점
//   · LedgerCalendarGrid — 칸 이름(cellLabel)
//   · PBadge.disabled · PTagTone.disabled — 끝낸 줄 안의 모양
//   · PListHeader.headingLevel · PBottomSheetContent.footerRow · PFormDeleteFooter
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/features/expense/presentation/widgets/ledger_header.dart';
import 'package:groo_damda_app/shared/ds/badge/p_badge.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/ds/tag_group/p_tag_group.dart';
import 'package:groo_damda_app/shared/forms/form_delete_footer.dart';
import 'package:groo_damda_app/shared/widgets/p_day_group.dart';
import '../features/todo/todo_test_support.dart';
import '../support/plain_text.dart';

void main() {
  setUpAll(loadRealFonts);

  testWidgets(
    'PDayHeaderRow — 글 t4 500 fg-neutral-subtle · 좌우 24 위아래 8 · 머리말 2 · 오른쪽 자리',
    (tester) async {
      await pumpApp(
        tester,
        const Scaffold(
          body: PDayHeaderRow(text: '10월 21일 (수)', trailing: Text('2/5 완료')),
        ),
      );
      final c = tester.element(find.byType(PDayHeaderRow)).colors;
      final handle = tester.ensureSemantics();
      final text = tester.widget<Text>(findPlain('10월 21일 (수)'));
      expect(text.style!.fontSize, 14);
      expect(text.style!.fontWeight, FontWeight.w500);
      expect(text.style!.color, c.fgNeutralSubtle);
      final box = tester.getRect(find.byType(PDayHeaderRow));
      expect(tester.getTopLeft(findPlain('10월 21일 (수)')).dx, 24);
      expect(tester.getTopRight(findText('2/5 완료')).dx, 360 - 24);
      // 위 8 — 글 줄 높이가 머리 높이의 가운데에 선다
      expect(
        tester.getTopLeft(findPlain('10월 21일 (수)')).dy - box.top,
        closeTo(8, 1.5),
      );
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('10월 21일 (수)'))
            .getSemanticsData()
            .headingLevel,
        2,
      );
      handle.dispose();
    },
  );

  testWidgets(
    'LedgerMonthNav — 가장 나쁜 값 "2026년 12월" 글자 200% 360 에서 넘치지 않는다 · 글이 여백 24 에서 시작',
    (tester) async {
      double? oneLine;
      for (final scale in [1.0, 2.0]) {
        await pumpApp(
          tester,
          Scaffold(
            body: LedgerMonthNav(
              label: '2026년 12월',
              onPick: () {},
              onOpenFilter: () {},
              filterOn: true,
              onAddTx: () {},
            ),
          ),
          textScale: scale,
        );
        expect(tester.takeException(), isNull);
        final text = tester.getRect(findText('2026년 12월'));
        if (scale == 1.0) {
          expect(text.left, 24);
          oneLine = text.height;
        } else {
          // 200% 에서도 한 줄 — 높이가 한 줄(100% 높이)의 2배 안쪽(글자를 줄여 담아도 두 줄이 되지 않는다)
          expect(text.height, lessThan(oneLine! * 2.2));
          // 글자를 크게 줄이지 않는다 — 200% 에서 100% 글자보다 확실히 크다(1.5배 넘게)
          expect(text.height, greaterThan(oneLine * 1.5));
        }
        // [+] 는 늘 오른쪽 끝(화면 여백 24 → 336) — 달 글 바로 뒤에 붙지 않는다
        expect(tester.getRect(find.byIcon(LucideIcons.plus)).right, 336);
        expect(
          tester.getRect(find.byIcon(LucideIcons.slidersHorizontal)).right,
          lessThan(tester.getRect(find.byIcon(LucideIcons.plus)).left),
        );
      }
    },
  );

  testWidgets(
    'LedgerMonthNav — 추가 단추를 비우면 없다 · filterOn 이면 알림 점 하나 · 이름 "필터, 조건 걸림"',
    (tester) async {
      await pumpApp(
        tester,
        Scaffold(
          body: LedgerMonthNav(
            label: '10월',
            onPick: () {},
            onOpenFilter: () {},
            filterOn: true,
          ),
        ),
      );
      final handle = tester.ensureSemantics();
      expect(find.byIcon(LucideIcons.plus), findsNothing);
      expect(find.bySemanticsLabel('필터, 조건 걸림'), findsOneWidget);
      expect(find.byKey(const ValueKey('notification-badge')), findsOneWidget);
      handle.dispose();

      await pumpApp(
        tester,
        Scaffold(
          body: LedgerMonthNav(
            label: '10월',
            onPick: () {},
            onOpenFilter: () {},
            onAddTx: () {},
          ),
        ),
      );
      expect(find.byIcon(LucideIcons.plus), findsOneWidget);
      expect(find.byKey(const ValueKey('notification-badge')), findsNothing);
    },
  );

  testWidgets(
    'LedgerCalendarGrid — cellLabel 을 주면 칸이 그 이름 하나로 읽히고 표시는 읽히지 않는다',
    (tester) async {
      final n = DateTime.now();
      await pumpApp(
        tester,
        Scaffold(
          body: LedgerCalendarGrid(
            month: DateTime(n.year, n.month, 1),
            selected: ymd(n),
            expanded: false,
            onSelect: (_) {},
            onToggleExpand: () {},
            markBuilder: (context, ds) => const SizedBox(height: 15),
            cellLabel: (context, ds) => ds == ymd(n) ? '오늘 칸' : null,
          ),
        ),
      );
      final handle = tester.ensureSemantics();
      expect(find.bySemanticsLabel('오늘 칸'), findsOneWidget);
      handle.dispose();
    },
  );

  testWidgets('PBadge.disabled — bg-disabled · fg-disabled(톤 · 변형은 무시)', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const Scaffold(
        body: PBadge(label: '중요', tone: PBadgeTone.critical, disabled: true),
      ),
    );
    final c = tester.element(find.byType(PBadge)).colors;
    final box = tester.widget<Container>(
      find
          .descendant(of: find.byType(PBadge), matching: find.byType(Container))
          .first,
    );
    expect((box.decoration! as BoxDecoration).color, c.bgDisabled);
    expect(tester.widget<Text>(findText('중요')).style!.color, c.fgDisabled);
  });

  testWidgets('PTagTone.disabled — 항목 글이 fg-disabled', (tester) async {
    await pumpApp(
      tester,
      const Scaffold(
        body: PTagGroup(
          size: PTagGroupSize.t3,
          items: [PTag('업무', tone: PTagTone.disabled)],
        ),
      ),
    );
    final c = tester.element(find.byType(PTagGroup)).colors;
    final t = tester.widget<Text>(find.byType(Text).first);
    final span = (t.textSpan! as TextSpan).children!.first as TextSpan;
    expect(span.style!.color, c.fgDisabled);
  });

  testWidgets('PListHeader.headingLevel — 기본 2 · 3 으로 낮출 수 있다', (tester) async {
    await pumpApp(
      tester,
      const Scaffold(
        body: Column(
          children: [
            PListHeader(title: '둘'),
            PListHeader(title: '셋', headingLevel: 3),
          ],
        ),
      ),
    );
    final handle = tester.ensureSemantics();
    int level(String label) => tester
        .getSemantics(find.bySemanticsLabel(label))
        .getSemanticsData()
        .headingLevel;
    expect(level('둘'), 2);
    expect(level('셋'), 3);
    handle.dispose();
  });

  testWidgets(
    'PBottomSheetContent.footerRow — 바닥 여백(위 12 · 좌우 24) 안에 직접 그린 줄 · footer 와 함께 못 준다',
    (tester) async {
      await pumpApp(
        tester,
        Scaffold(
          body: PBottomSheetContent(
            title: '제목',
            closeLabel: '닫기',
            body: const SizedBox(height: 40),
            footerRow: PFormDeleteFooter(
              deleteLabel: '삭제',
              onDelete: () {},
              save: PButton(
                label: '저장',
                size: PButtonSize.large,
                onPressed: () {},
              ),
            ),
          ),
        ),
      );
      final footer = find.byKey(const ValueKey('p-bottom-sheet-footer'));
      expect(footer, findsOneWidget);
      final del = find.byWidgetPredicate(
        (w) => w is PButton && w.label == '삭제',
      );
      final save = find.byWidgetPredicate(
        (w) => w is PButton && w.label == '저장',
      );
      expect(tester.getRect(del).left, 24);
      expect(tester.getRect(save).right, 360 - 24);
      expect(tester.getSize(del).height, 48);
      expect(tester.getSize(save).height, 48);
      final d = tester.widget<PButton>(del);
      expect(d.ghostColor, PButtonGhostColor.critical);
      expect(d.variant, PButtonVariant.ghost);
      expect(d.flush, isNull);
      expect(
        () => PBottomSheetContent(
          title: '제목',
          closeLabel: '닫기',
          body: const SizedBox(),
          footer: [
            PButton(label: '가', size: PButtonSize.large, onPressed: () {}),
          ],
          footerRow: const SizedBox(),
        ),
        throwsAssertionError,
      );
    },
  );

  testWidgets('PList 제목 색 — 바뀌면 150ms 로 옮겨 가고, 모션 줄이기면 바로 바뀐다', (tester) async {
    final off = ValueNotifier<bool>(false);
    Future<void> pumpRow({bool reduce = false}) => pumpApp(
      tester,
      Scaffold(
        body: ValueListenableBuilder<bool>(
          valueListenable: off,
          builder: (context, v, _) => PList(
            children: [
              PListItem(
                title: '제목',
                titleColor: v ? context.colors.fgDisabled : null,
                titleStrike: v,
              ),
            ],
          ),
        ),
      ),
      disableAnimations: reduce,
    );
    await pumpRow();
    final c = tester.element(find.byType(PList)).colors;
    Color color() => tester.widget<Text>(findPlain('제목')).style!.color!;
    expect(color(), c.fgNeutral);
    off.value = true;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(color(), isNot(c.fgNeutral));
    expect(color(), isNot(c.fgDisabled));
    await tester.pump(const Duration(milliseconds: 200));
    expect(color(), c.fgDisabled);
    // 취소선은 색과 달리 옮겨 가지 않는다(바로)
    expect(
      tester.widget<Text>(findPlain('제목')).style!.decoration,
      TextDecoration.lineThrough,
    );

    off.value = false;
    await pumpRow(reduce: true);
    expect(color(), c.fgNeutral);
    off.value = true;
    await tester.pump();
    expect(color(), c.fgDisabled, reason: '모션 줄이기');
  });

  testWidgets('PList 제목 색 — 처음 그릴 때(새로 만들어진 줄 포함)는 모션 없이 최종 색이다', (
    tester,
  ) async {
    final key = ValueNotifier<int>(0);
    await pumpApp(
      tester,
      Scaffold(
        body: ValueListenableBuilder<int>(
          valueListenable: key,
          builder: (context, k, _) => PList(
            children: [
              // 끝낸 줄처럼 처음부터 비활성 색인 줄 — 줄이 새로 만들어질 때마다(key) 다시 처음 그림이다
              PListItem(
                key: ValueKey(k),
                title: '제목',
                titleColor: context.colors.fgDisabled,
                titleStrike: true,
              ),
            ],
          ),
        ),
      ),
      settle: false,
    );
    final c = tester.element(find.byType(PList)).colors;
    Color color() => tester.widget<Text>(findPlain('제목')).style!.color!;
    // 첫 프레임 == 최종 색(보간 없음)
    expect(color(), c.fgDisabled);
    // 줄이 다시 만들어져도(스크롤로 목록이 새로 들어오는 때와 같다) 첫 프레임이 최종 색이다
    key.value = 1;
    await tester.pump();
    expect(color(), c.fgDisabled);
    await tester.pump(const Duration(milliseconds: 80));
    expect(color(), c.fgDisabled, reason: '깜빡이듯 옮겨 가지 않는다');
  });
}
