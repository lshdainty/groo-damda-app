// 기관 색은 표 하나(institution-colors.yaml)다 — 앱의 옛 표 둘(bank_colors · card_brand)을 걷고 ds 표 위에 얹은 길이
// 그 표와 같은 값을 돌려주는지, 모든 기관의 글자가 4.5:1 을 넘는지 본다(03E-010).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/presentation/widgets/asset_logo.dart';
import 'package:groo_damda_app/shared/brand/bank_colors.dart';
import 'package:groo_damda_app/shared/ds/avatar/p_avatar.dart';
import 'package:groo_damda_app/shared/ds/institution_colors/institution_colors.dart';
import 'package:groo_damda_app/shared/ds/logo_tile/p_logo_tile.dart';

double _ratio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (la > lb ? la + 0.05 : lb + 0.05) / (la > lb ? lb + 0.05 : la + 0.05);
}

Widget _host(Brightness mode, Widget child) => MaterialApp(
  theme: mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

Asset _asset({String? institution, String name = '월급 통장', String? color}) =>
    Asset(
      rowId: 1,
      assetName: name,
      assetType: 'BANK_ACCOUNT',
      institution: institution,
      color: color,
    );

void main() {
  final spec =
      jsonDecode(
            File(
              'test/fixtures/design_spec/institution-colors.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final entries = ((spec['data'] as Map)['entries'] as List).cast<Map>();

  test('자산 추가 목록은 표에서 "카드사" 묶음만 뺀 것이다 — 표의 차례 · 이름 · 별칭 · 색 그대로', () {
    final expected = [
      for (final e in entries)
        if (e['category'] != '카드사') e,
    ];
    expect(bankEntries.length, expected.length);
    expect(expected.length, 70);
    for (var i = 0; i < expected.length; i++) {
      final want = expected[i];
      final got = bankEntries[i];
      expect(got.name, want['name'], reason: 'i=$i');
      expect(got.category.label, want['category'], reason: got.name);
      expect(got.aliases, ((want['aliases'] as List?) ?? const []));
      expect(
        got.color.bg.toARGB32() & 0xFFFFFF,
        int.parse((want['color'] as String).substring(1), radix: 16),
        reason: got.name,
      );
      expect(got.color.text.name, want['text'], reason: got.name);
    }
    // 묶음 열 가지가 모두 있고(카드사 제외) 투자 묶음은 증권사 · 상품거래소 · 가상자산이다
    expect(bankEntriesByCategory.keys.toSet(), BankCategory.values.toSet());
    expect(bankEntriesByCategory[BankCategory.brokerage]!.length, 26);
  });

  test('모든 기관의 글자는 면 색 위에서 4.5:1 이상이다 — 라이트 · 다크 모두', () {
    for (final mode in Brightness.values) {
      final colors = mode == Brightness.dark ? PColors.dark : PColors.light;
      for (final e in PInstitutionColors.table.entries) {
        final fg = switch (e.text) {
          PInstitutionText.white => colors.staticWhite,
          PInstitutionText.dark =>
            mode == Brightness.dark
                ? colors.fgNeutralInverted
                : colors.fgNeutral,
        };
        expect(
          _ratio(fg, e.color),
          greaterThanOrEqualTo(4.5),
          reason: '${e.name} ${mode.name}',
        );
      }
    }
  });

  test('getBrandColor — 이름 · 별칭 · 포함 일치를 표에서 찾고 없으면 null', () {
    expect(getBrandColor(['신한은행'])!.bg, PInstitutionColors.find('신한')!.color);
    expect(
      getBrandColor([null, '  ', 'KB 국민은행'])!.bg,
      PInstitutionColors.find('KB국민')!.color,
    );
    expect(getBrandColor(['알 수 없는 곳']), isNull);
    // 첫 후보가 없으면 다음 후보로
    expect(
      getBrandColor(['없는 기관', '신한'])!.bg,
      PInstitutionColors.find('신한')!.color,
    );
  });

  for (final mode in Brightness.values) {
    testWidgets(
      '${mode.name} — AssetLogo 는 Logo Tile 이다: 기관 색 표 · 없으면 이름 색, 저장된 자산 색은 읽지 않는다',
      (tester) async {
        final colors = mode == Brightness.dark ? PColors.dark : PColors.light;
        // 기관이 표에 있다 → 표의 색(저장 색 #FF00FF 는 무시)
        await tester.pumpWidget(
          _host(
            mode,
            AssetLogo(
              asset: _asset(institution: '신한', color: '#FF00FF'),
            ),
          ),
        );
        final tile = tester.widget<PLogoTile>(find.byType(PLogoTile));
        expect(tile.face, PLogoTileFace.institution);
        expect(tile.name, '신한');
        expect(tile.size, PLogoTileSize.s40);
        expect(
          tester
              .widget<ColoredBox>(
                find
                    .descendant(
                      of: find.byType(PLogoTile),
                      matching: find.byType(ColoredBox),
                    )
                    .first,
              )
              .color,
          PInstitutionColors.find('신한')!.color,
        );
        // 기관이 없다 → 사용자가 지은 이름이라 표를 보지 않고 이름 색
        await tester.pumpWidget(
          _host(mode, AssetLogo(asset: _asset(name: '우리 아이 적금'), size: 48)),
        );
        final named = tester.widget<PLogoTile>(find.byType(PLogoTile));
        expect(named.face, PLogoTileFace.name);
        expect(named.size, PLogoTileSize.s48);
        expect(
          tester
              .widget<ColoredBox>(
                find
                    .descendant(
                      of: find.byType(PLogoTile),
                      matching: find.byType(ColoredBox),
                    )
                    .first,
              )
              .color,
          avatarHueColor(colors, '우리 아이 적금'),
        );
      },
    );
  }
}
