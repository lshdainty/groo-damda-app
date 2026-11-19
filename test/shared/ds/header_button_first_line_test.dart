// 머리 버튼은 제목 첫 줄 가운데 — 바닥 시트의 닫기 원 · ⋮ · ←, 도움말 말풍선의 닫기. 버튼 모양(원 · 아이콘)은 px 그대로이고 자리만
// 제목 글의 실제 줄 높이(글자 배율 × 줄 비율)를 따른다. 100% 는 예전 자리(닫기 원 위 24 · 말풍선 닫기는 오른쪽 위 모서리)와 같다
// (groo-design #263 bottom-sheet · help-bubble 레시피). 100% · 선형 200% · 300% · 안드로이드 200%(비선형).
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/help_bubble/p_help_bubble.dart';

import '../../support/android_font_scale.dart';
import '../../support/plain_text.dart';

const _scalers = <(String, TextScaler)>[
  ('100%', TextScaler.noScaling),
  ('200%', TextScaler.linear(2)),
  ('300%', TextScaler.linear(3)),
  ('안드로이드 200%', AndroidNonlinearTextScaler()),
];

Widget _app(Widget home, TextScaler scaler) => MaterialApp(
  theme: GrooTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('ko'),
  builder: (c, child) => MediaQuery(
    data: MediaQuery.of(c).copyWith(textScaler: scaler),
    child: child!,
  ),
  home: home,
);

Widget _sheetHost({String? eyebrow, required bool back}) => Scaffold(
  body: Builder(
    builder: (context) => Center(
      child: TextButton(
        onPressed: () => PBottomSheet.show<void>(
          context,
          form: true,
          builder: (_) => PBottomSheetContent(
            title: '신용카드 추가',
            eyebrow: eyebrow,
            closeLabel: '닫기',
            onBack: back ? () {} : null,
            backLabel: back ? '뒤로' : null,
            headerAction: PButton.icon(
              key: const ValueKey('test-header-action'),
              icon: LucideIcons.ellipsisVertical,
              semanticLabel: '더보기',
              variant: PButtonVariant.ghost,
              size: PButtonSize.small,
              onPressed: () {},
            ),
            body: const SizedBox(height: 40),
          ),
        ),
        child: const Text('열기'),
      ),
    ),
  ),
);

Future<void> _openSheet(
  WidgetTester tester,
  TextScaler scaler, {
  String? eyebrow,
  bool back = true,
}) async {
  tester.view.physicalSize = const Size(360, 760);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    _app(_sheetHost(eyebrow: eyebrow, back: back), scaler),
  );
  await tester.tap(findText('열기'));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

/// 글 [of] 의 첫 줄 가운데(세로) — 위 끝 + 실제 줄 높이 ÷ 2.
double _firstLineCenter(WidgetTester tester, Finder of) {
  final rp = tester.renderObject<RenderParagraph>(
    find.descendant(of: of, matching: find.byType(RichText), matchRoot: true),
  );
  final style = rp.text.style!;
  final line = rp.textScaler.scale(style.fontSize!) * style.height!;
  return tester.getRect(of).top + line / 2;
}

void main() {
  const title = ValueKey('p-bottom-sheet-title');
  const header = ValueKey('p-bottom-sheet-header');
  const closeCircle = ValueKey('p-bottom-sheet-close-circle');
  const backCircle = ValueKey('p-bottom-sheet-back-circle');
  const action = ValueKey('test-header-action');

  group('바닥 시트', () {
    testWidgets(
      '닫기 원 · ⋮ · ← 는 px 그대로, ← 는 제목 첫 줄 가운데 · 닫기 원 · ⋮ 는 100% 와 같은 간격으로 첫 줄을 따른다',
      (tester) async {
        for (final (name, scaler) in _scalers) {
          await _openSheet(tester, scaler);
          final line = _firstLineCenter(tester, find.byKey(title));
          final close = tester.getRect(find.byKey(closeCircle));
          final back = tester.getRect(find.byKey(backCircle));
          final more = tester.getRect(
            find
                .descendant(
                  of: find.byKey(action),
                  matching: find.byType(Container),
                )
                .first,
          );
          expect(close.size, const Size.square(28), reason: '$name 닫기 원');
          expect(back.size, const Size.square(40), reason: '$name ← 원');
          expect(more.size, const Size.square(36), reason: '$name ⋮');
          // ← 는 첫 줄 가운데, 닫기 원 · ⋮ 는 100% 처럼 첫 줄 가운데보다 1 위(위 24 + 14 = 38 · 첫 줄 가운데 24 + 15 = 39) —
          // 레시피의 top = x6 + 줄 높이 ÷ 2 − 15 와 같은 관계가 어느 배율에서도 그대로다
          expect(close.center.dy, closeTo(line - 1, 0.01), reason: '$name 닫기');
          expect(back.center.dy, closeTo(line, 0.01), reason: '$name ←');
          expect(more.center.dy, closeTo(line - 1, 0.01), reason: '$name ⋮');
          if (scaler == TextScaler.noScaling) {
            // 100% — 예전 자리: 닫기 원 위 24, ⋮ 는 닫기 원 가운데(위 24 + 14)
            final top = tester.getRect(find.byKey(header)).top;
            expect(close.top - top, closeTo(24, 0.01), reason: '100% 닫기 위 24');
            expect(more.center.dy - top, closeTo(38, 0.01), reason: '100% ⋮');
          }
        }
      },
    );

    testWidgets('위 글(eyebrow)이 있으면 ← 는 그 아래 제목 첫 줄 가운데', (tester) async {
      for (final (name, scaler) in _scalers) {
        await _openSheet(tester, scaler, eyebrow: '1 / 2 단계');
        final line = _firstLineCenter(tester, find.byKey(title));
        final back = tester.getRect(find.byKey(backCircle));
        expect(back.center.dy, closeTo(line, 0.01), reason: '$name ←');
      }
    });
  });

  group('도움말 말풍선', () {
    testWidgets('닫기 38 은 px 그대로, 세로 가운데가 제목 첫 줄 가운데 — 100% 는 오른쪽 위 모서리', (
      tester,
    ) async {
      for (final (name, scaler) in _scalers) {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(
          _app(
            Scaffold(
              body: Center(
                child: PHelpBubble(
                  title: '이번 달 남은 예산',
                  description: '예산에서 이번 달 지출을 뺀 금액이에요.',
                  showCloseButton: true,
                  defaultOpen: true,
                  triggerBuilder: (context, toggle, isOpen) =>
                      const SizedBox.square(dimension: 40),
                ),
              ),
            ),
            scaler,
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$name 넘침');
        final bubble = tester.getRect(
          find.byKey(const ValueKey('help-bubble')),
        );
        final box = tester.getRect(
          find.byKey(const ValueKey('help-bubble-close-box')),
        );
        final line = _firstLineCenter(
          tester,
          find.byKey(const ValueKey('help-bubble-title')),
        );
        expect(box.size, const Size.square(38), reason: '$name 닫기 38');
        expect(box.center.dy, closeTo(line, 0.01), reason: '$name 첫 줄');
        expect(box.bottom, lessThanOrEqualTo(bubble.bottom + 0.01));
        if (scaler == TextScaler.noScaling) {
          expect(box.top, closeTo(bubble.top, 0.01), reason: '100% 위 모서리');
          expect(box.right, closeTo(bubble.right, 0.01), reason: '100% 오른쪽');
        }
      }
    });
  });
}
