// Card Art 카드 면의 글 — 회사 · 카드 이름은 카드 그림 안 글이라 글자 크기 설정을 따르지 않는다(card-art.yaml issuer · name
// `-static`, 앱 TextScaler.noScaling — groo-design #264, 사용자 결정 2026-11-19). 면 모양은 틀의 폭으로만 가른다 — 폭 96 미만은
// 회사 첫 글자, 그 이상은 회사 · 카드 이름이다. 100% · 선형 200% · 300% · 안드로이드 200%(비선형)에서 같은 면이다.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/shared/ds/image_frame/p_card_art.dart';
import 'package:groo_damda_app/shared/ds/institution_colors/institution_colors.dart';

import '../../support/android_font_scale.dart';

const _fake = PInstitutionColor(
  name: '숲길',
  category: 'card',
  aliases: [],
  color: Color(0xFF2E7D5B),
  text: PInstitutionText.white,
);

const _scalers = <(String, TextScaler)>[
  ('100%', TextScaler.noScaling),
  ('200%', TextScaler.linear(2)),
  ('300%', TextScaler.linear(3)),
  ('안드로이드 200%', AndroidNonlinearTextScaler()),
];

Widget _host(
  double width,
  TextScaler scaler, {
  Brightness mode = Brightness.light,
}) => MaterialApp(
  theme: mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
  home: MediaQuery(
    data: MediaQueryData(textScaler: scaler),
    child: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        // 지어낸 카드사 — 기관 색 표에 없으므로 면(PCardFace)을 지어낸 기관 값으로 직접 그린다
        child: SizedBox(
          width: width,
          height: width / 1.586,
          child: const PCardFace(
            issuer: '숲길카드',
            name: '새싹 체크',
            institution: _fake,
          ),
        ),
      ),
    ),
  ),
);

Finder _text(String s) => find.byWidgetPredicate(
  (w) => w is Text && (w.data ?? '').replaceAll('⁠', '') == s,
);

void main() {
  test('면 크기는 폭으로만 — 96 미만 small · 240 미만 medium · 그 위 large', () {
    expect(cardArtSizeFor(95.9), PCardArtSize.small);
    expect(cardArtSizeFor(96), PCardArtSize.medium);
    expect(cardArtSizeFor(239.9), PCardArtSize.medium);
    expect(cardArtSizeFor(240), PCardArtSize.large);
  });

  for (final mode in Brightness.values) {
    for (final width in const [60.0, 95.0, 96.0, 110.0, 123.0, 160.0, 240.0]) {
      final initial = width < 96;
      testWidgets('${mode.name} 폭 $width — ${initial ? '첫 글자' : '회사 · 카드 이름'}, '
          '글자 크기와 상관없이 같은 면', (tester) async {
        final base = <String, Size>{};
        for (final (name, scaler) in _scalers) {
          await tester.pumpWidget(_host(width, scaler, mode: mode));
          expect(tester.takeException(), isNull, reason: '$name 넘침');
          expect(
            _text('숲길카드'),
            initial ? findsNothing : findsOneWidget,
            reason: name,
          );
          expect(
            _text('새싹 체크'),
            initial ? findsNothing : findsOneWidget,
            reason: name,
          );
          expect(
            _text('숲'),
            initial ? findsOneWidget : findsNothing,
            reason: name,
          );
          final shown = initial ? ['숲'] : ['숲길카드', '새싹 체크'];
          for (final s in shown) {
            final rp = tester.renderObject<RenderParagraph>(
              find.descendant(of: _text(s), matching: find.byType(RichText)),
            );
            expect(rp.textScaler, TextScaler.noScaling, reason: '$name $s');
            final size = rp.size;
            base.putIfAbsent(s, () => size);
            expect(size, base[s], reason: '$name $s 크기 = 100%');
          }
          if (initial) {
            // 작은 면 — 면 높이의 40%
            final t = tester.widget<Text>(_text('숲'));
            expect(t.style!.fontSize, cardArtInitialSize(width / 1.586));
          }
        }
      });
    }
  }
}
