// Button 라벨 — 한 줄을 지키고, 넘치면 끝을 "…" 로 줄여 버튼 밖으로 나가지 않는다. 나란한 두 버튼(PResponsivePair)은 넘치면
// 세로로 쌓고(주 버튼이 위), 쌓아도 넘치면 "…" 다(button.md "글자 크기 설정" · "짝 버튼", groo-design #263).
// 폭 320 화면(좌우 여백 24 — 칸 272) · 글자 100% · 200% · 300% · 안드로이드 200%(비선형).
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/button/p_responsive_pair.dart';

import '../../support/android_font_scale.dart';

const _scalers = <(String, TextScaler)>[
  ('100%', TextScaler.noScaling),
  ('200%', TextScaler.linear(2)),
  ('300%', TextScaler.linear(3)),
  ('안드로이드 200%', AndroidNonlinearTextScaler()),
];

const _long = '그루 계정으로 로그인하고 시작하기';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  required TextScaler scaler,
}) async {
  tester.view.physicalSize = const Size(320, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    MaterialApp(
      theme: GrooTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      home: MediaQuery(
        data: MediaQueryData(size: const Size(320, 900), textScaler: scaler),
        child: Scaffold(
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Align(alignment: Alignment.topCenter, child: child),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// 버튼 [button] 의 라벨 — 한 줄이고 버튼 상자 안에 든다. 넘치면 "…" 로 줄었다.
RenderParagraph _expectLabelInside(
  WidgetTester tester,
  Finder button,
  String label,
  String reason,
) {
  final text = find.descendant(
    of: button,
    matching: find.byWidgetPredicate((w) => w is Text && w.data == label),
  );
  expect(text, findsOneWidget, reason: reason);
  final rp = tester.renderObject<RenderParagraph>(
    find.descendant(of: text, matching: find.byType(RichText)),
  );
  final style = rp.text.style!;
  final line = rp.textScaler.scale(style.fontSize!) * style.height!;
  expect(rp.size.height, closeTo(line, 0.5), reason: '$reason 한 줄');
  expect(rp.maxLines, 1, reason: reason);
  expect(rp.overflow, TextOverflow.ellipsis, reason: reason);
  final box = tester.getRect(
    find.descendant(of: button, matching: find.byType(Container)).first,
  );
  final r = tester.getRect(text);
  expect(r.left, greaterThanOrEqualTo(box.left - 0.01), reason: '$reason 왼쪽');
  expect(r.right, lessThanOrEqualTo(box.right + 0.01), reason: '$reason 오른쪽');
  // 그린 글 폭이 칸보다 좁다 — 넘친 글이 칸 밖으로 그려지지 않는다
  expect(
    rp.size.width,
    lessThanOrEqualTo(box.width + 0.01),
    reason: '$reason 글 폭',
  );
  return rp;
}

void main() {
  testWidgets('긴 라벨 — 칸 폭 버튼에서 한 줄, 넘치면 "…" 로 줄고 버튼 밖으로 나가지 않는다', (
    tester,
  ) async {
    for (final (name, scaler) in _scalers) {
      await _pump(
        tester,
        SizedBox(
          width: double.infinity,
          child: PButton(
            label: _long,
            size: PButtonSize.large,
            onPressed: () {},
          ),
        ),
        scaler: scaler,
      );
      expect(tester.takeException(), isNull, reason: '$name 넘침');
      final rp = _expectLabelInside(tester, find.byType(PButton), _long, name);
      if (scaler != TextScaler.noScaling) {
        expect(rp.didExceedMaxLines, isTrue, reason: '$name "…" 로 줄었다');
      }
      // 보조 기술은 줄이지 않은 전체 라벨을 읽는다
      expect(find.bySemanticsLabel(_long), findsOneWidget, reason: name);
    }
  });

  testWidgets('아이콘이 있는 긴 라벨 — 아이콘은 크기 그대로 버튼 안, 라벨이 "…" 로 준다', (tester) async {
    for (final (name, scaler) in _scalers) {
      await _pump(
        tester,
        SizedBox(
          width: double.infinity,
          child: PButton(
            label: _long,
            size: PButtonSize.large,
            prefixIcon: LucideIcons.upload,
            onPressed: () {},
          ),
        ),
        scaler: scaler,
      );
      expect(tester.takeException(), isNull, reason: '$name 넘침');
      _expectLabelInside(tester, find.byType(PButton), _long, name);
      final icon = find.descendant(
        of: find.byType(PButton),
        matching: find.byType(Icon),
      );
      final box = tester.getRect(
        find
            .descendant(
              of: find.byType(PButton),
              matching: find.byType(Container),
            )
            .first,
      );
      final ir = tester.getRect(icon);
      expect(ir.size, const Size.square(22), reason: '$name 아이콘 22 px(large)');
      expect(ir.left, greaterThanOrEqualTo(box.left), reason: name);
      expect(ir.right, lessThanOrEqualTo(box.right), reason: name);
    }
  });

  testWidgets('폭을 주지 않은 버튼(줄 안 내용 폭) — 오류 없이 라벨을 다 보인다', (tester) async {
    for (final (name, scaler) in _scalers) {
      await _pump(
        tester,
        Row(
          children: [
            PButton(
              label: '삭제',
              variant: PButtonVariant.ghost,
              size: PButtonSize.large,
              onPressed: () {},
            ),
          ],
        ),
        scaler: scaler,
      );
      expect(tester.takeException(), isNull, reason: '$name 넘침');
      final rp = _expectLabelInside(tester, find.byType(PButton), '삭제', name);
      expect(rp.didExceedMaxLines, isFalse, reason: '$name 줄이지 않는다');
    }
  });

  group('짝 버튼', () {
    Widget pair(String secondary, String primary) => PResponsivePair(
      secondary: PButton(
        label: secondary,
        variant: PButtonVariant.neutralWeak,
        size: PButtonSize.large,
        onPressed: () {},
      ),
      primary: PButton(
        label: primary,
        size: PButtonSize.large,
        onPressed: () {},
      ),
    );

    testWidgets('넘치면 세로로 쌓고(주 버튼이 위) 라벨은 버튼 안 한 줄', (tester) async {
      for (final (name, scaler) in _scalers) {
        await _pump(tester, pair('취소', '저장하기'), scaler: scaler);
        expect(tester.takeException(), isNull, reason: '$name 넘침');
        // 100% 는 한 줄에 반씩, 큰 글자는 "저장하기" 가 반(132)을 넘어 쌓인다
        final stacked = scaler != TextScaler.noScaling;
        expect(
          find.byKey(const ValueKey('pair-column')),
          stacked ? findsOneWidget : findsNothing,
          reason: '$name 쌓임',
        );
        expect(
          find.byKey(const ValueKey('pair-row')),
          stacked ? findsNothing : findsOneWidget,
          reason: '$name 한 줄',
        );
        final save = find.ancestor(
          of: find.text('저장하기'),
          matching: find.byType(PButton),
        );
        final cancel = find.ancestor(
          of: find.text('취소'),
          matching: find.byType(PButton),
        );
        if (stacked) {
          expect(
            tester.getRect(save).top,
            lessThan(tester.getRect(cancel).top),
            reason: '$name 주 버튼이 위',
          );
        }
        _expectLabelInside(tester, save, '저장하기', name);
        _expectLabelInside(tester, cancel, '취소', name);
      }
    });

    testWidgets('쌓아도 버튼 폭을 넘는 라벨은 "…" 로 줄인다', (tester) async {
      for (final (name, scaler) in _scalers) {
        await _pump(tester, pair('취소', _long), scaler: scaler);
        expect(tester.takeException(), isNull, reason: '$name 넘침');
        expect(
          find.byKey(const ValueKey('pair-column')),
          findsOneWidget,
          reason: name,
        );
        final long = find.ancestor(
          of: find.text(_long),
          matching: find.byType(PButton),
        );
        final rp = _expectLabelInside(tester, long, _long, name);
        if (scaler != TextScaler.noScaling) {
          expect(rp.didExceedMaxLines, isTrue, reason: '$name "…"');
        }
      }
    });
  });
}
