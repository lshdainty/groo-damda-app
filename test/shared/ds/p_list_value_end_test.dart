// List 값은 줄 수와 상관없이 줄 끝 오른쪽 맞춤 — 여러 줄 값의 모든 줄이 한 줄 값과 같은 세로선에 끝난다(list.md suffixText
// textAlign end). 좁은 줄에서 본문 아래로 내려간 값은 왼쪽 맞춤(start).
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import '../../support/plain_text.dart';

const _long = '서울특별시 강남구 테헤란로 427 위워크타워 12층 대회의실 B';

Widget _host(Widget child, {double scale = 1}) => MaterialApp(
  theme: GrooTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('ko'),
  builder: (c, ch) => MediaQuery(
    data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
    child: ch!,
  ),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: 360, child: child),
    ),
  ),
);

/// [f] 가 가리키는 Text 의 문단 — 목록 값 Text 는 semanticsLabel 이 붙어 바로 아래 렌더 객체가 의미 상자다(12979a71).
RenderParagraph _para(WidgetTester t, Finder f) =>
    t.renderObject<RenderParagraph>(
      find.descendant(of: f, matching: find.byType(RichText)).first,
    );

/// 문단의 줄마다 오른쪽 끝(전역 x).
List<double> _lineRights(WidgetTester t, Finder f) {
  final p = _para(t, f);
  final len = p.text.toPlainText().length;
  final rights = <double, double>{};
  for (final b in p.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: len),
  )) {
    final r = b.toRect();
    final y = p.localToGlobal(Offset(0, r.top)).dy.roundToDouble();
    final x = p.localToGlobal(Offset(r.right, 0)).dx;
    if (x > (rights[y] ?? -1)) rights[y] = x;
  }
  return rights.values.toList();
}

void main() {
  testWidgets('두 줄 값 — 모든 줄의 오른쪽 끝이 줄 끝 336(= 360 − 24)', (t) async {
    await t.pumpWidget(
      _host(
        const PList(
          semanticLabel: '값',
          children: [PListItem(title: '장소', suffix: Text(_long))],
        ),
      ),
    );
    final rights = _lineRights(t, findText(_long));
    expect(rights.length, greaterThan(1));
    for (final r in rights) {
      expect(r, closeTo(336, 0.6));
    }
  });

  testWidgets('좁은 줄 — 본문 아래로 내려간 값은 왼쪽 맞춤(첫 줄 왼쪽 24)', (t) async {
    await t.pumpWidget(
      _host(
        const PList(
          semanticLabel: '값',
          children: [PListItem(title: '장소', suffix: Text(_long))],
        ),
        scale: 2,
      ),
    );
    final p = _para(t, findText(_long));
    expect(p.localToGlobal(Offset.zero).dx, closeTo(24, 0.6));
  });

  testWidgets('값은 낱말 단위로 줄을 바꾼다 — 낱말 안에 이음 문자, 읽는 이름은 원래 글', (t) async {
    await t.pumpWidget(
      _host(
        const PList(
          semanticLabel: '값',
          children: [PListItem(title: '장소', suffix: Text(_long))],
        ),
      ),
    );
    final w = t.widget<Text>(
      find.byWidgetPredicate(
        (x) => x is Text && (x.data ?? '').replaceAll('\u2060', '') == _long,
      ),
    );
    expect(w.data!.contains('\u2060'), isTrue);
    expect(w.semanticsLabel, _long);
  });

  testWidgets('공백 없는 긴 값만 칸 끝에서 글자 사이로 끊긴다(넘치지 않음)', (t) async {
    const noSpace = '서울특별시강남구테헤란로427위워크타워12층대회의실B동편엘리베이터앞';
    await t.pumpWidget(
      _host(
        const PList(
          semanticLabel: '값',
          children: [PListItem(title: '장소', suffix: Text(noSpace))],
        ),
      ),
    );
    expect(t.takeException(), isNull);
    final p = _para(
      t,
      find.byWidgetPredicate(
        (x) => x is Text && (x.data ?? '').replaceAll('\u2060', '') == noSpace,
      ),
    );
    expect(p.size.width, lessThanOrEqualTo(360 - 48));
    expect(p.size.height, greaterThan(p.text.style!.fontSize! * 1.5));
  });
}
