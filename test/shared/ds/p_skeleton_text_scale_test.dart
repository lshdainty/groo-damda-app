// Skeleton 크기 — 글 자리는 올 글의 줄 높이를 따라 커지고(글자 크기 설정 · 안드로이드 비선형도 그려지는 글과 같은 셈), 틀 안 글
// 자리(달력 칸 · 7일 띠 · 차트)는 그대로, 글이 아닌 모양(아바타 · 그림 · 아이콘 · 막대)은 px 그대로다(skeleton.md "크기 — 글은
// 글줄 높이" · "글자 크기 설정"). 글 안(WidgetSpan)에 둔 글 자리는 Flutter 가 자리째 키우므로 한 번만 커진다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/ds/skeleton/p_skeleton.dart';

import '../../support/android_font_scale.dart';

const _scalers = <(String, TextScaler)>[
  ('100%', TextScaler.noScaling),
  ('200%', TextScaler.linear(2)),
  ('300%', TextScaler.linear(3)),
  ('안드로이드 200%', AndroidNonlinearTextScaler()),
];

Future<void> _pump(WidgetTester tester, Widget child, TextScaler s) async {
  tester.view.physicalSize = const Size(400, 900);
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
        data: MediaQueryData(textScaler: s, disableAnimations: true),
        child: Scaffold(
          body: Align(alignment: Alignment.topLeft, child: child),
        ),
      ),
    ),
  );
  await tester.pump();
  expect(tester.takeException(), isNull);
}

double _line(TextScaler s, TextStyle t) => s.scale(t.fontSize!) * t.height!;

void main() {
  testWidgets('글 자리는 올 글의 줄 높이를 따라 커지고, 틀 안 글 · 모양은 그대로', (tester) async {
    for (final (name, s) in _scalers) {
      await _pump(
        tester,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PSkeleton.text(
              PTypography.t4,
              width: 96,
              key: const ValueKey('text-t4'),
            ),
            PSkeleton.text(
              PTypography.t9,
              width: 160,
              key: const ValueKey('text-t9'),
            ),
            PSkeleton.staticText(
              PTypography.t1,
              width: 32,
              key: const ValueKey('static-t1'),
            ),
            const PSkeleton(
              width: 40,
              height: 40,
              radius: PSkeletonRadius.r12,
              key: ValueKey('tile'),
            ),
            const PSkeleton(
              width: 120,
              height: 8,
              radius: PSkeletonRadius.full,
              key: ValueKey('bar'),
            ),
          ],
        ),
        s,
      );
      void sized(String k, double w, double h) {
        final got = tester.getSize(find.byKey(ValueKey(k)));
        expect(got.width, closeTo(w, 0.01), reason: '$name $k 폭');
        expect(got.height, closeTo(h, 0.01), reason: '$name $k 높이');
      }

      // 글 — 그 글자의 줄 높이(글자 배율을 건 글자 크기 × 줄 비율), 폭은 준 값
      sized('text-t4', 96, _line(s, PTypography.t4));
      sized('text-t9', 160, _line(s, PTypography.t9));
      // 틀 안 글 · 모양 — 100% 와 같다
      sized('static-t1', 32, 15);
      sized('tile', 40, 40);
      sized('bar', 120, 8);
    }
  });

  testWidgets('글 안(WidgetSpan)의 글 자리는 한 번만 커진다 — 목록 머리 제목 뒤 수 자리', (
    tester,
  ) async {
    for (final (name, s) in _scalers) {
      await _pump(
        tester,
        SizedBox(
          width: 400,
          child: PListHeader(
            title: '숨긴 화면 · ',
            titleSuffix: SizedBox(
              width: 40,
              child: PSkeleton.text(
                PTypography.t4,
                scaled: false,
                key: const ValueKey('span'),
              ),
            ),
          ),
        ),
        s,
      );
      // 자리째 키우는 배율은 머리 글자(t4 14)의 배율이다 — 그린 높이(페인트 배율 포함)로 잰다
      final spanScale = s.scale(14) / 14;
      expect(
        tester.getRect(find.byKey(const ValueKey('span'))).height,
        closeTo(19 * spanScale, 0.01),
        reason: name,
      );
    }
  });
}
