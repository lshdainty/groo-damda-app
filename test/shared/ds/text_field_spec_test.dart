// 4 텍스트 필드(Field · Input · Textarea)가 스펙 값(test/fixtures/design_spec/{field,input,textarea}.json)대로인지 —
// 조합 × 상태 × 라이트 · 다크를 모두 돈다. 웹은 같은 JSON 을 크로미움에서 잰다(desk-front `npm run ds:check`).
//
// 앱은 늘 large 다 — medium · responsive(1280 이상 데스크톱 웹)는 재지 않는다. 문장으로 된 값은 아래 동작 테스트가
// 본다 — Textarea 의 maxHeight("자리마다") · resize(손잡이 없음). Field 의 form(사이 24 · 16 · 열)은 Field 를 쌓는
// 화면의 값이라 재지 않는다(웹 검사기도 같다).
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import '../../support/line_breaks.dart';
import '../../support/plain_text.dart';
import 'package:groo_damda_app/shared/ds/field/field_demo.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/input/input_demo.dart';
import 'package:groo_damda_app/shared/ds/input/p_input.dart';
import 'package:groo_damda_app/shared/ds/input/text_control.dart';
import 'package:groo_damda_app/shared/ds/textarea/p_textarea.dart';
import 'package:groo_damda_app/shared/ds/textarea/textarea_demo.dart';

import '../../support/design_spec.dart';

final _field = DesignSpec.load('field');
final _input = DesignSpec.load('input');
final _textarea = DesignSpec.load('textarea');

const _light = Brightness.light;
const _transparent = Color(0x00000000);

Widget _host(
  Brightness mode,
  Widget child, {
  MediaQueryData Function(MediaQueryData data)? media,
}) => MaterialApp(
  theme: mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('ko'),
  home: Builder(
    builder: (context) {
      final data = MediaQuery.of(context);
      return MediaQuery(
        data: media?.call(data) ?? data,
        child: Scaffold(
          body: Center(child: SizedBox(width: 320, child: child)),
        ),
      );
    },
  ),
);

/// 실패를 모으는 작은 도우미 — 색 · 수 · 글자를 스펙과 맞춘다.
class _Check {
  _Check(this.mode, this.want, this.where);
  final Brightness mode;
  final Map<String, Object?> want;
  final String where;
  final failures = <String>[];

  void fail(String message) => failures.add('$where — $message');

  void color(String key, Color actual) {
    final w = pickMode(want[key], mode);
    if (w == null) return fail('$key: 스펙에 없다');
    if (!sameColor(specColor(w), actual)) {
      fail('$key: 스펙 $w · 실제 ${colorHex(actual)}');
    }
  }

  void px(String key, num actual) {
    final w = want[key];
    if (w is! num) return fail('$key: 스펙에 수가 없다($w)');
    if ((w - actual).abs() > 0.5) fail('$key: 스펙 $w · 실제 $actual');
  }

  /// "0.375rem" — 1rem = 16(글자 크기 설정 1배).
  void rem(String key, num actual, {double scale = 1}) {
    final m = RegExp(r'^([\d.]+)rem$').firstMatch('${want[key]}');
    if (m == null) return fail('$key: rem 이 아니다(${want[key]})');
    final w = double.parse(m.group(1)!) * 16 * scale;
    if ((w - actual).abs() > 0.5) fail('$key: 스펙 $w · 실제 $actual');
  }

  /// 글자 — 크기 · 줄 높이 · 글꼴, 그리고 그 부위에 굵기가 따로 없으면 typography 의 굵기.
  /// [lineHeightKey] 를 주면 줄 높이는 그 값이 덮는다("선택" — 라벨과 같은 22).
  void typo(String key, TextStyle style, {String? lineHeightKey}) {
    final t = want[key] as Map?;
    if (t == null) return fail('$key: 스펙에 없다');
    final lineHeight = style.fontSize! * (style.height ?? 1);
    final wantLineHeight =
        (lineHeightKey == null ? t['lineHeight'] : want[lineHeightKey]) as num;
    if (t['fontSize'] != style.fontSize ||
        (wantLineHeight - lineHeight).abs() > 0.01) {
      fail(
        '$key: 스펙 ${t['fontSize']}/$wantLineHeight · 실제 ${style.fontSize}/$lineHeight',
      );
    }
    final family = '${t['fontFamily']}'.split(',').first.trim();
    if (style.fontFamily != family) {
      fail('$key: 글꼴 스펙 $family · 실제 ${style.fontFamily}');
    }
    final slot = key.split('.').first;
    if (!want.containsKey('$slot.fontWeight') &&
        style.fontWeight?.value != t['fontWeight']) {
      fail('$key: 굵기 스펙 ${t['fontWeight']} · 실제 ${style.fontWeight}');
    }
  }

  void weight(String key, TextStyle style) {
    final w = want[key];
    if (w is! num) return fail('$key: 스펙에 수가 없다($w)');
    if (style.fontWeight?.value != w) {
      fail('$key: 스펙 $w · 실제 ${style.fontWeight}');
    }
  }

  void exact(String key, Object? actual) {
    if ('${want[key]}' != '$actual') fail('$key: 스펙 ${want[key]} · 실제 $actual');
  }

  /// 상자의 테두리 — 1px 는 늘 있고, 2px 는 덧그린다(포커스 · 오류). 밑줄형은 아래 선만.
  void frame(
    WidgetTester tester,
    Finder control, {
    required bool underline,
    String widthKey = 'root.borderWidth',
  }) {
    final frame = find.descendant(
      of: control,
      matching: find.byType(PTextFrame),
    );
    final boxes = find.descendant(
      of: frame,
      matching: find.byType(DecoratedBox),
    );
    BoxDecoration deco(int i) =>
        tester.widget<DecoratedBox>(boxes.at(i)).decoration as BoxDecoration;
    final background = deco(0);
    final overlay = deco(1);
    final base = deco(2);

    color('root.background', background.color ?? _transparent);
    px(
      'root.radius',
      (background.borderRadius as BorderRadius?)?.topLeft.x ?? 0,
    );
    final w = want[widthKey];
    final side = w == 2
        ? (overlay.border! as Border).bottom
        : (base.border! as Border).bottom;
    color('root.borderColor', side.color);
    px(widthKey, side.width);
    if (w != 2 && (overlay.border! as Border).bottom.color.a != 0) {
      fail('덧그린 2px 가 남아 있다');
    }
    for (final d in [base, overlay]) {
      final b = d.border! as Border;
      if (underline) {
        if (b.top != BorderSide.none ||
            b.left != BorderSide.none ||
            b.right != BorderSide.none) {
          fail('밑줄형은 아래 선만');
        }
      } else if (!b.isUniform) {
        fail('상자형은 네 변이 같은 선');
      }
    }

    // 색 전환 — 덧그린 2px 의 색만
    final motion = tester.widget<TweenAnimationBuilder<Color>>(
      find.descendant(
        of: frame,
        matching: find.byType(TweenAnimationBuilder<Color>),
      ),
    );
    if (motion.duration != specMs(want['root.transitionDuration'])) {
      fail('root.transitionDuration: 실제 ${motion.duration}');
    }
    final cubic = specCubic(want['root.transitionEasing']);
    final curve = motion.curve as Cubic;
    if ([curve.a, curve.b, curve.c, curve.d].toString() != cubic.toString()) {
      fail('root.transitionEasing: 실제 $curve');
    }
    if (want['root.transitionProperty'] != 'border-color') {
      fail('root.transitionProperty: ${want['root.transitionProperty']}');
    }

    // 커서 — text · not-allowed
    final cursor = tester
        .widget<MouseRegion>(
          find
              .descendant(of: control, matching: find.byType(MouseRegion))
              .first,
        )
        .cursor;
    final wantCursor = switch (want['root.cursor']) {
      'text' => SystemMouseCursors.text,
      'not-allowed' => SystemMouseCursors.forbidden,
      final other => throw ArgumentError('커서 $other'),
    };
    if (cursor != wantCursor) fail('root.cursor: 실제 $cursor');
  }
}

EditableText _editable(WidgetTester tester, [Finder? within]) =>
    tester.widget<EditableText>(
      within == null
          ? find.byType(EditableText)
          : find.descendant(of: within, matching: find.byType(EditableText)),
    );

TextStyle _textStyle(WidgetTester tester, Finder within, String text) => tester
    .widget<Text>(find.descendant(of: within, matching: findPlain(text)))
    .style!;

Icon _icon(WidgetTester tester, Finder within, IconData data) => tester
    .widget<Icon>(find.descendant(of: within, matching: find.byIcon(data)));

/// 덧그린 2px(포커스 · 오류)의 선.
BorderSide _overlay(WidgetTester tester, Finder control) {
  final boxes = find.descendant(
    of: find.descendant(of: control, matching: find.byType(PTextFrame)),
    matching: find.byType(DecoratedBox),
  );
  return ((tester.widget<DecoratedBox>(boxes.at(1)).decoration as BoxDecoration)
              .border!
          as Border)
      .bottom;
}

Finder _richText(Pattern text) => find.byWidgetPredicate(
  (w) =>
      w is RichText &&
      // 라벨은 낱말 단위 줄바꿈 글자(U+2060)가 끼어 있다 — 뺀 글로 견준다
      (text is RegExp
          ? text.hasMatch(w.text.toPlainText().replaceAll('\u2060', ''))
          : w.text.toPlainText().replaceAll('\u2060', '') == text),
);

/// 꼬리의 글자 수("4/12").
Finder _count(int max) => _richText(RegExp('^\\d+/$max\$'));

String _countText(WidgetTester tester, int max) =>
    tester.widget<RichText>(_count(max)).text.toPlainText();

/// 쓴 수 · 최대의 글 조각 — Text.rich 는 받은 조각을 한 겹 더 감싼다.
List<TextSpan> _countSpans(WidgetTester tester, int max) {
  final root = tester.widget<RichText>(_count(max)).text as TextSpan;
  return (root.children!.single as TextSpan).children!.cast<TextSpan>();
}

/// 화면 읽기 프로그램에 보낸 알림.
List<String> _listenAnnouncements(WidgetTester tester) {
  final said = <String>[];
  tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(
    SystemChannels.accessibility,
    (message) async {
      final m = message as Map;
      if (m['type'] == 'announce') {
        said.add((m['data'] as Map)['message'] as String);
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger
        .setMockDecodedMessageHandler<dynamic>(
          SystemChannels.accessibility,
          null,
        ),
  );
  return said;
}

void main() {
  group('Input', () {
    const empty = ValueKey('empty');
    const filled = ValueKey('filled');

    Future<void> check(
      WidgetTester tester,
      Brightness mode,
      Map<String, String> combo,
      String state,
      List<String> failures,
    ) async {
      final variant = PInputVariant.values.byName(combo['variant']!);
      final underline = variant == PInputVariant.underline;
      final disabled = state == 'disabled';
      final readOnly = state == 'readonly';
      final invalid = state == 'invalid';
      await tester.pumpWidget(
        _host(
          mode,
          Column(
            key: UniqueKey(),
            mainAxisSize: MainAxisSize.min,
            spacing: 16,
            children: [
              PInput(
                key: empty,
                variant: variant,
                semanticLabel: '금액',
                placeholder: '금액',
                prefixIcon: LucideIcons.search,
                prefixText: '만',
                disabled: disabled,
                readOnly: readOnly,
                invalid: invalid,
              ),
              PInput(
                key: filled,
                variant: variant,
                semanticLabel: '금액',
                initialValue: '12,000',
                suffixText: '원',
                suffixIcon: LucideIcons.calendar,
                clearable: true,
                disabled: disabled,
                readOnly: readOnly,
                invalid: invalid,
              ),
            ],
          ),
        ),
      );
      if (state == 'focused') {
        await tester.showKeyboard(find.byKey(filled));
        // 포커스가 닿는 프레임 — 테두리 색 전환이 여기서 시작한다
        await tester.pump();
      }
      // 색 전환(100ms)이 끝나게
      await tester.pump(const Duration(milliseconds: 300));

      final want = _input.resolve(combo, state);
      final k = _Check(mode, want, '${mode.name} $combo $state');
      final e = find.byKey(empty);
      final f = find.byKey(filled);

      // 상자 — 상태는 값이 있는 칸(포커스를 받은 칸)에서 잰다
      k.frame(
        tester,
        f,
        underline: underline,
        widthKey: underline ? 'root.borderBottomWidth' : 'root.borderWidth',
      );
      for (final control in [e, f]) {
        final frame = find.descendant(
          of: control,
          matching: find.byType(PTextFrame),
        );
        k.px('root.minHeight', tester.getSize(frame).height);
        final padding =
            tester
                    .widget<Padding>(
                      find
                          .descendant(of: frame, matching: find.byType(Padding))
                          .first,
                    )
                    .padding
                as EdgeInsets;
        k.px('root.paddingX', padding.left);
        k.px('root.paddingX', padding.right);
        if (underline) {
          k.px('root.paddingY', padding.top);
          k.px('root.paddingY', padding.bottom);
        } else if (padding.vertical != 0) {
          k.fail('상자형은 위아래 여백이 없다(52 가운데)');
        }
        k.px(
          'root.gap',
          tester
              .widget<Row>(
                find.descendant(of: frame, matching: find.byType(Row)).first,
              )
              .spacing,
        );
      }

      // 값 · 예시 글 · 붙이개
      final editable = _editable(tester, f);
      final value = editable.style;
      k.typo('value.typography', value);
      k.weight('value.fontWeight', value);
      k.color('value.foreground', value.color!);
      // 캐럿은 글자색 — input.yaml value.caretColor(2026-10-08)
      k.color('value.caretColor', editable.cursorColor);
      final placeholder = _textStyle(tester, e, '금액');
      k.typo('placeholder.typography', placeholder);
      k.weight('placeholder.fontWeight', placeholder);
      k.color('placeholder.foreground', placeholder.color!);
      final prefixText = _textStyle(tester, e, '만');
      k.typo('prefixText.typography', prefixText);
      k.weight('prefixText.fontWeight', prefixText);
      k.color('prefixText.foreground', prefixText.color!);
      final suffixText = _textStyle(tester, f, '원');
      k.typo('suffixText.typography', suffixText);
      k.weight('suffixText.fontWeight', suffixText);
      k.color('suffixText.foreground', suffixText.color!);
      final prefixIcon = _icon(tester, e, LucideIcons.search);
      k.px('prefixIcon.size', prefixIcon.size!);
      k.color('prefixIcon.color', prefixIcon.color!);
      final suffixIcon = _icon(tester, f, LucideIcons.calendar);
      k.px('suffixIcon.size', suffixIcon.size!);
      k.color('suffixIcon.color', suffixIcon.color!);

      // 지우기 — 값이 있고 막히지 않았을 때만
      final clear = find.descendant(
        of: f,
        matching: find.byIcon(LucideIcons.circleX),
      );
      if (disabled || readOnly) {
        if (clear.evaluate().isNotEmpty) k.fail('막힌 칸에 지우기 버튼이 있다');
      } else if (clear.evaluate().isEmpty) {
        k.fail('지우기 버튼이 없다');
      } else {
        final icon = tester.widget<Icon>(clear);
        k.px('clearButton.size', icon.size!);
        k.color('clearButton.color', icon.color!);
        if (want['clearButton.radius'] != PRounded.full) {
          k.fail('clearButton.radius: ${want['clearButton.radius']}');
        }
      }
      failures.addAll(k.failures);
    }

    for (final mode in Brightness.values) {
      testWidgets('${mode.name} — 모양 × 크기(large) × 상태가 스펙 값이다', (tester) async {
        final failures = <String>[];
        // 앱은 늘 large — medium · responsive 는 데스크톱 웹 몫
        for (final combo in _input.combos(['variant'])) {
          for (final state in _input.states) {
            await check(
              tester,
              mode,
              {...combo, 'size': 'large'},
              state,
              failures,
            );
          }
        }
        if (failures.isNotEmpty) {
          fail('${failures.length}개가 스펙과 다르다\n${failures.take(30).join('\n')}');
        }
      });
    }

    testWidgets('앱 크기는 웹 large 와 같다 — 반응형은 1280 미만이 large', (tester) async {
      final want = _input.resolve({'size': 'responsive'}, 'enabled');
      expect(want['root.breakpoint'], 1280);
      expect(
        _input.resolve({'size': 'large'}, 'enabled')['root.minHeight'],
        52,
      );
    });

    testWidgets('상자 어디를 눌러도(붙이개 · 여백) 입력으로 포커스가 간다', (tester) async {
      await tester.pumpWidget(
        _host(
          _light,
          const PInput(semanticLabel: '메모 검색', prefixIcon: LucideIcons.search),
        ),
      );
      await tester.tap(find.byIcon(LucideIcons.search));
      await tester.pump();
      expect(_editable(tester).focusNode.hasFocus, isTrue);

      // 왼쪽 여백(16) 안
      await tester.pumpWidget(_host(_light, const SizedBox()));
      await tester.pumpWidget(
        _host(_light, const PInput(semanticLabel: '메모', suffixText: '원')),
      );
      final box = tester.getRect(find.byType(PTextFrame));
      await tester.tapAt(Offset(box.left + 6, box.center.dy));
      await tester.pump();
      expect(_editable(tester).focusNode.hasFocus, isTrue);
    });

    testWidgets('글자를 누르면 그 자리에 캐럿 — 상자가 입력의 누름을 가로채지 않는다', (tester) async {
      await tester.pumpWidget(
        _host(
          _light,
          const PInput(semanticLabel: '메모', initialValue: 'abcdefgh'),
        ),
      );
      final text = tester.getRect(find.byType(EditableText));
      await tester.tapAt(Offset(text.left + 2, text.center.dy));
      await tester.pump(const Duration(milliseconds: 500));
      expect(_editable(tester).focusNode.hasFocus, isTrue);
      expect(_editable(tester).controller.selection.baseOffset, 0);
    });

    testWidgets(
      '지우기 — 값을 비우고 입력에 포커스를 두며 onChanged 에 빈 값을 보낸다. 보이는 22 를 44 까지 받는다',
      (tester) async {
        final changes = <String>[];
        Widget input() => _host(
          _light,
          PInput(
            semanticLabel: '메모 검색',
            initialValue: '회의록',
            clearable: true,
            onChanged: changes.add,
          ),
        );
        await tester.pumpWidget(input());
        await tester.tap(find.byIcon(LucideIcons.circleX));
        await tester.pump();
        expect(_editable(tester).controller.text, '');
        expect(changes, ['']);
        expect(_editable(tester).focusNode.hasFocus, isTrue);
        // 비면 지우기 버튼이 없다
        expect(find.byIcon(LucideIcons.circleX), findsNothing);

        // 넓힌 자리 — 아이콘 오른쪽 10(44 안)은 지우고, 12(44 밖)는 포커스만
        await tester.pumpWidget(_host(_light, const SizedBox()));
        await tester.pumpWidget(input());
        var icon = tester.getRect(find.byIcon(LucideIcons.circleX));
        await tester.tapAt(Offset(icon.right + 12, icon.center.dy));
        await tester.pump();
        expect(_editable(tester).controller.text, '회의록');
        icon = tester.getRect(find.byIcon(LucideIcons.circleX));
        await tester.tapAt(Offset(icon.right + 10, icon.center.dy));
        await tester.pump();
        expect(_editable(tester).controller.text, '');
      },
    );

    testWidgets('입력이 상자를 채운다 — 위아래 여백 · 맨 앞 · 맨 뒤의 좌우 여백을 눌러도 가장 가까운 글자에 캐럿', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          _light,
          const PInput(semanticLabel: '메모', initialValue: 'abcdefgh'),
        ),
      );
      final box = tester.getRect(find.byType(PTextFrame));
      final text = tester.getRect(find.byType(EditableText));
      Future<int> tapAt(Offset at) async {
        await tester.tapAt(at);
        // 두 번 누름으로 이어지지 않게
        await tester.pump(const Duration(milliseconds: 500));
        expect(_editable(tester).focusNode.hasFocus, isTrue);
        return _editable(tester).controller.selection.baseOffset;
      }

      // 글 줄 위(상자의 위쪽 여백) — 첫 글자 위
      expect(await tapAt(Offset(text.left + 2, box.top + 4)), 0);
      // 오른쪽 여백(맨 뒤)
      expect(await tapAt(Offset(box.right - 4, box.center.dy)), 8);
      // 왼쪽 여백(맨 앞)
      expect(await tapAt(Offset(box.left + 4, box.center.dy)), 0);

      // 앞에 붙이개가 있으면 그쪽 여백은 붙이개의 것 — 포커스만 옮기고 캐럿은 그대로
      await tester.pumpWidget(_host(_light, const SizedBox()));
      await tester.pumpWidget(
        _host(
          _light,
          const PInput(
            semanticLabel: '메모',
            prefixIcon: LucideIcons.search,
            initialValue: 'abcdefgh',
          ),
        ),
      );
      final searchBox = tester.getRect(find.byType(PTextFrame));
      expect(await tapAt(Offset(searchBox.right - 4, searchBox.center.dy)), 8);
      expect(await tapAt(Offset(searchBox.left + 4, searchBox.center.dy)), 8);
    });

    testWidgets('지우기는 "지우기" 로 읽고 누를 수 있다 — 키보드 이동 순서에는 없다', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          _light,
          const PInput(
            semanticLabel: '메모 검색',
            initialValue: '회의록',
            clearable: true,
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byIcon(LucideIcons.circleX)),
        matchesSemantics(label: '지우기', isButton: true, hasTapAction: true),
      );
      // 포커스 노드가 없다 — Tab 순서에 없다
      expect(
        find.descendant(
          of: find.byType(PInput),
          matching: find.byWidgetPredicate(
            (w) => w is Focus && w.focusNode != _editable(tester).focusNode,
          ),
        ),
        findsNothing,
      );
      tester.semantics.tap(find.semantics.byLabel('지우기'));
      await tester.pump();
      expect(_editable(tester).controller.text, '');
      semantics.dispose();
    });

    testWidgets('읽기 전용 — 포커스는 되고 포커스 테두리는 없다. 비활성 — 포커스도 받지 않는다', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          _light,
          const PInput(
            semanticLabel: '아이디',
            initialValue: 'groo',
            readOnly: true,
          ),
        ),
      );
      await tester.tap(find.byType(PInput));
      await tester.pump(const Duration(milliseconds: 300));
      expect(_editable(tester).focusNode.hasFocus, isTrue);
      expect(_editable(tester).readOnly, isTrue);
      expect(_overlay(tester, find.byType(PInput)).color.a, 0);
      expect(
        tester.getSemantics(find.byType(EditableText)),
        containsSemantics(isTextField: true, isReadOnly: true),
      );

      await tester.pumpWidget(_host(_light, const SizedBox()));
      await tester.pumpWidget(
        _host(
          _light,
          const PInput(
            semanticLabel: '계좌',
            initialValue: '국민 123-45-6789',
            disabled: true,
          ),
        ),
      );
      await tester.tap(find.byType(PInput), warnIfMissed: false);
      await tester.pump();
      expect(_editable(tester).focusNode.hasFocus, isFalse);
      expect(
        tester.getSemantics(find.byType(EditableText)),
        containsSemantics(
          isTextField: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      semantics.dispose();
    });

    testWidgets('테두리 — 2px 는 바로, 색만 d2 · easing 으로 그 색 그대로 진해진다. 모션 줄이기면 바로', (
      tester,
    ) async {
      final c = PColors.light;
      await tester.pumpWidget(_host(_light, const PInput(semanticLabel: '메모')));
      await tester.showKeyboard(find.byType(PInput));
      await tester.pump(const Duration(milliseconds: 50));
      final mid = _overlay(tester, find.byType(PInput));
      expect(mid.width, 2);
      expect(mid.color.a, inExclusiveRange(0, 1));
      // 투명한 검정을 거치지 않는다 — 색은 그대로, 진하기만 바뀐다(CSS 처럼)
      expect(
        sameColor(
          c.strokeNeutralContrast.withValues(alpha: mid.color.a),
          mid.color,
        ),
        isTrue,
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        sameColor(
          c.strokeNeutralContrast,
          _overlay(tester, find.byType(PInput)).color,
        ),
        isTrue,
      );

      await tester.pumpWidget(_host(_light, const SizedBox()));
      await tester.pumpWidget(
        _host(
          _light,
          const PInput(semanticLabel: '메모'),
          media: (d) => d.copyWith(disableAnimations: true),
        ),
      );
      expect(
        tester
            .widget<TweenAnimationBuilder<Color>>(
              find.byType(TweenAnimationBuilder<Color>),
            )
            .duration,
        Duration.zero,
      );
    });

    testWidgets('예시 글 · 붙이개 글은 입력의 설명으로 읽는다 — 아이콘은 읽지 않는다', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          _light,
          const PInput(
            semanticLabel: '금액',
            placeholder: '0',
            prefixIcon: LucideIcons.wallet,
            suffixText: '원',
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(EditableText)),
        containsSemantics(label: '금액', hint: '0\n원', isTextField: true),
      );
      expect(find.bySemanticsLabel('원'), findsNothing);
      // 값이 생기면 예시 글은 빠진다
      await tester.enterText(find.byType(PInput), '12,000');
      await tester.pump();
      expect(
        tester.getSemantics(find.byType(EditableText)),
        containsSemantics(label: '금액', hint: '원', value: '12,000'),
      );
      semantics.dispose();
    });

    testWidgets('가린 칸은 자격증명 — 키보드 사전 · 추천 · 학습에 남기지 않는다', (tester) async {
      await tester.pumpWidget(
        _host(
          _light,
          const PInput(
            semanticLabel: '비밀번호',
            variant: PInputVariant.underline,
            obscureText: true,
          ),
        ),
      );
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.obscureText, isTrue);
      expect(field.autocorrect, isFalse);
      expect(field.enableSuggestions, isFalse);
      expect(field.enableIMEPersonalizedLearning, isFalse);
    });
  });

  group('Textarea', () {
    const empty = ValueKey('empty');
    const filled = ValueKey('filled');
    const reason = '가족 행사 참석으로 연차를 씁니다.\n결재 뒤 인수인계 문서를 공유할게요.';

    Future<void> check(
      WidgetTester tester,
      Brightness mode,
      Map<String, String> combo,
      String state,
      List<String> failures,
    ) async {
      final autoSize = combo['autoSize'] == 'on';
      final want = _textarea.resolve(combo, state);
      final minHeight = want['value.minHeight']! as num;
      PTextarea textarea(Key key, {String? placeholder, String? value}) =>
          PTextarea(
            key: key,
            autoSize: autoSize,
            // 고정 높이는 자리마다 — 가장 낮은 2줄로 둔다
            height: autoSize ? null : minHeight.toDouble(),
            semanticLabel: '휴가 사유',
            placeholder: placeholder,
            initialValue: value,
            disabled: state == 'disabled',
            readOnly: state == 'readonly',
            invalid: state == 'invalid',
          );
      await tester.pumpWidget(
        _host(
          mode,
          Column(
            key: UniqueKey(),
            mainAxisSize: MainAxisSize.min,
            spacing: 16,
            children: [
              textarea(empty, placeholder: '예: 가족 행사 참석'),
              textarea(filled, value: reason),
            ],
          ),
        ),
      );
      if (state == 'focused') {
        await tester.showKeyboard(find.byKey(filled));
        // 포커스가 닿는 프레임 — 테두리 색 전환이 여기서 시작한다
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 300));

      final k = _Check(mode, want, '${mode.name} $combo $state');
      final e = find.byKey(empty);
      final f = find.byKey(filled);
      k.frame(tester, f, underline: false);

      final frame = find.descendant(of: e, matching: find.byType(PTextFrame));
      // 빈 칸의 높이 — 자동 높이 3줄 · 고정 높이 2줄
      k.px('value.minHeight', tester.getSize(frame).height);
      final padding =
          tester
                  .widget<Padding>(
                    find
                        .descendant(of: frame, matching: find.byType(Padding))
                        .first,
                  )
                  .padding
              as EdgeInsets;
      k.px('value.paddingX', padding.left);
      k.px('value.paddingX', padding.right);
      k.px('value.paddingY', padding.top);
      k.px('value.paddingY', padding.bottom);

      final editable = _editable(tester, f);
      final value = editable.style;
      k.typo('value.typography', value);
      k.weight('value.fontWeight', value);
      k.color('value.foreground', value.color!);
      // 캐럿은 글자색 — textarea.yaml value.caretColor(Input 과 같다, 2026-10-08)
      k.color('value.caretColor', editable.cursorColor);
      final placeholder = _textStyle(tester, e, '예: 가족 행사 참석');
      k.typo('placeholder.typography', placeholder);
      k.weight('placeholder.fontWeight', placeholder);
      k.color('placeholder.foreground', placeholder.color!);
      failures.addAll(k.failures);
    }

    for (final mode in Brightness.values) {
      testWidgets('${mode.name} — 크기(large) × 높이 × 상태가 스펙 값이다', (tester) async {
        final failures = <String>[];
        for (final combo in _textarea.combos(['autoSize'])) {
          for (final state in _textarea.states) {
            await check(
              tester,
              mode,
              {...combo, 'size': 'large'},
              state,
              failures,
            );
          }
        }
        if (failures.isNotEmpty) {
          fail('${failures.length}개가 스펙과 다르다\n${failures.take(30).join('\n')}');
        }
      });
    }

    testWidgets('자동 높이 — 3줄에서 쓴 만큼 바로 자라고, 최대 높이에서 멈춰 칸 안에서 스크롤한다', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          _light,
          PTextarea(
            controller: controller,
            semanticLabel: '메모',
            maxHeight: 160,
          ),
        ),
      );
      Size box() => tester.getSize(find.byType(PTextFrame));
      expect(box().height, 94);
      controller.text = '1\n2\n3\n4\n5';
      await tester.pump();
      // 움직임 없이 바로 — 줄 높이 22 × 5 + 위아래 14
      expect(box().height, 22 * 5 + 28);
      controller.text = '1\n2\n3\n4\n5\n6\n7\n8';
      await tester.pump();
      expect(box().height, 160);
      final scrollable = tester.state<ScrollableState>(
        find.descendant(
          of: find.byType(PTextarea),
          matching: find.byType(Scrollable),
        ),
      );
      expect(scrollable.position.maxScrollExtent, greaterThan(0));
    });

    testWidgets('고정 높이 — 정한 높이를 지키고 넘치면 칸 안에서 스크롤, 글자가 커져도 2줄보다 낮아지지 않는다', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          _light,
          const PTextarea(
            autoSize: false,
            height: 100,
            semanticLabel: '공지 본문',
            initialValue: '1\n2\n3\n4\n5\n6',
          ),
        ),
      );
      expect(tester.getSize(find.byType(PTextFrame)).height, 100);
      final scrollable = tester.state<ScrollableState>(
        find.descendant(
          of: find.byType(PTextarea),
          matching: find.byType(Scrollable),
        ),
      );
      expect(scrollable.position.maxScrollExtent, greaterThan(0));

      await tester.pumpWidget(
        _host(
          _light,
          const PTextarea(autoSize: false, height: 72, semanticLabel: '공지 본문'),
          media: (d) => d.copyWith(textScaler: const TextScaler.linear(2)),
        ),
      );
      expect(tester.getSize(find.byType(PTextFrame)).height, 28 + 44 * 2);
    });

    testWidgets('입력이 상자를 채운다 — 여백을 눌러도 가장 가까운 글자에 캐럿', (tester) async {
      await tester.pumpWidget(
        _host(
          _light,
          const PTextarea(semanticLabel: '메모', initialValue: 'abc\ndef'),
        ),
      );
      final box = tester.getRect(find.byType(PTextFrame));
      await tester.tapAt(Offset(box.left + 4, box.top + 4));
      await tester.pump(const Duration(milliseconds: 500));
      expect(_editable(tester).focusNode.hasFocus, isTrue);
      expect(_editable(tester).controller.selection.baseOffset, 0);
      // 아래 여백 · 오른쪽 — 마지막 줄 끝
      await tester.tapAt(Offset(box.right - 4, box.bottom - 4));
      await tester.pump(const Duration(milliseconds: 500));
      expect(_editable(tester).controller.selection.baseOffset, 7);
    });

    testWidgets('Enter 는 줄바꿈 — 폼을 제출하지 않는다', (tester) async {
      await tester.pumpWidget(
        _host(_light, const PTextarea(semanticLabel: '메모')),
      );
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.keyboardType, TextInputType.multiline);
      expect(field.textInputAction, TextInputAction.newline);
      expect(field.maxLines, isNull);
    });

    testWidgets('Field 안 — 글자 수는 자소로 세고 최대에서 멈춘다', (tester) async {
      await tester.pumpWidget(
        _host(
          _light,
          const PField(label: '탈퇴 사유', maxGraphemeCount: 3, child: PTextarea()),
        ),
      );
      await tester.enterText(find.byType(PTextarea), '가나다라');
      await tester.pump();
      expect(_editable(tester).controller.text, '가나다');
      expect(_countText(tester, 3), '3/3');
    });
  });

  group('Field', () {
    const label = '카테고리 이름';
    const description = '목록과 통계에 이 이름으로 보여요.';
    const error = '이미 쓰고 있는 아이디예요.';

    for (final mode in Brightness.values) {
      testWidgets('${mode.name} — 라벨 굵기 × 상태가 스펙 값이다', (tester) async {
        final failures = <String>[];
        for (final combo in _field.combos(['labelWeight'])) {
          final weight = PFieldLabelWeight.values.byName(combo['labelWeight']!);
          for (final state in _field.states) {
            final invalid = state == 'invalid';
            await tester.pumpWidget(
              _host(
                mode,
                PField(
                  key: UniqueKey(),
                  label: label,
                  labelWeight: weight,
                  indicator: PFieldIndicator.required,
                  headerAction: PFieldAction(label: '예시 보기', onPressed: () {}),
                  description: description,
                  descriptionIcon: LucideIcons.info,
                  maxGraphemeCount: 12,
                  invalid: invalid,
                  errorMessage: invalid ? error : null,
                  child: const PInput(initialValue: '반려동물'),
                ),
              ),
            );
            final k = _Check(
              mode,
              _field.resolve(combo, state),
              '${mode.name} $combo $state',
            );
            final field = tester.getRect(find.byType(PField));
            final labelText = _richText(RegExp('^$label'));
            final labelRect = tester.getRect(labelText);
            final action = tester.getRect(find.byType(PButton));
            final control = tester.getRect(find.byType(PInput));
            final footerRow = find.ancestor(
              of: _count(12),
              matching: find.byType(Row),
            );
            final footer = tester.getRect(footerRow.first);

            // 쌓기 — 머리(22) · 입력 · 꼬리, 사이 8
            k.exact('root.direction', 'column');
            k.px('root.gap', control.top - labelRect.bottom);
            k.px('root.gap', footer.top - control.bottom);

            // 머리 — 좌우 2, 라벨 ↔ 액션 10, 가운데 맞춤, 액션은 위아래로 5 넘친다
            k.px('header.paddingX', labelRect.left - field.left);
            k.px('header.paddingX', field.right - action.right);
            final labelMax = tester
                .renderObject<RenderBox>(labelText)
                .constraints
                .maxWidth;
            k.px(
              'header.gap',
              field.width - 2 * PSpacing.x0_5 - action.width - labelMax,
            );
            k.exact('header.alignItems', 'center');
            if ((labelRect.center.dy - action.center.dy).abs() > 0.5) {
              k.fail('header.alignItems: 라벨과 액션의 가운데가 다르다');
            }
            k.px('headerAction.marginY', action.top - field.top);
            k.px('headerAction.marginY', labelRect.bottom - action.bottom);

            // 라벨
            final labelStyle = tester.widget<RichText>(labelText).text.style!;
            k.typo('label.typography', labelStyle);
            k.weight('label.fontWeight', labelStyle);
            k.color('label.foreground', labelStyle.color!);

            // 필수 점 — 6 · 위 4 · 앞 2(rem)
            final dot = find.descendant(
              of: find.byType(PField),
              matching: find.byWidgetPredicate(
                (w) =>
                    w is DecoratedBox &&
                    (w.decoration as BoxDecoration).shape == BoxShape.circle,
              ),
            );
            final dotRect = tester.getRect(dot);
            k.rem('requiredIndicator.size', dotRect.width);
            k.rem('requiredIndicator.size', dotRect.height);
            k.color(
              'requiredIndicator.color',
              (tester.widget<DecoratedBox>(dot).decoration as BoxDecoration)
                  .color!,
            );
            k.rem('requiredIndicator.marginTop', dotRect.top - labelRect.top);
            final dotPadding =
                tester
                        .widget<Padding>(
                          find
                              .ancestor(of: dot, matching: find.byType(Padding))
                              .first,
                        )
                        .padding
                    as EdgeInsetsDirectional;
            k.rem('requiredIndicator.marginLeft', dotPadding.start);
            k.rem('requiredIndicator.marginTop', dotPadding.top);

            // 꼬리 — 좌우 2, 설명 · 오류 ↔ 글자 수 8, 위 맞춤
            k.px('footer.paddingX', footer.left - field.left);
            k.px('footer.paddingX', field.right - footer.right);
            final row = tester.widget<Row>(footerRow.first);
            k.px('footer.gap', row.spacing);
            k.exact(
              'footer.alignItems',
              row.crossAxisAlignment == CrossAxisAlignment.start
                  ? 'flex-start'
                  : row.crossAxisAlignment.name,
            );

            // 설명 또는 오류 — 아이콘 16 · 사이 6 · 첫 줄 가운데(위 1.5)
            final (slot, iconSlot, text, iconData) = invalid
                ? ('errorMessage', 'errorIcon', error, LucideIcons.circleAlert)
                : (
                    'description',
                    'descriptionIcon',
                    description,
                    LucideIcons.info,
                  );
            if (invalid &&
                findText(keepAll(description)).evaluate().isNotEmpty) {
              k.fail('오류가 설명을 대신하지 않았다');
            }
            final message = findText(keepAll(text));
            final messageStyle = tester.widget<Text>(message).style!;
            k.typo('$slot.typography', messageStyle);
            k.color('$slot.foreground', messageStyle.color!);
            final icon = find.byIcon(iconData);
            k.px('$iconSlot.size', tester.widget<Icon>(icon).size!);
            k.color('$iconSlot.color', tester.widget<Icon>(icon).color!);
            final messageRow = tester.widget<Row>(
              find.ancestor(of: message, matching: find.byType(Row)).first,
            );
            k.px('$iconSlot.gap', messageRow.spacing);
            final iconTop =
                tester.getRect(icon).top - tester.getRect(message).top;
            if ((iconTop - (19 - 16) / 2).abs() > 0.01) {
              k.fail('$iconSlot: 첫 줄 가운데가 아니다(위 $iconTop)');
            }

            // 글자 수 — "4/12", 숫자 폭 고정
            final spans = _countSpans(tester, 12);
            k.typo('characterCount.typography', spans[0].style!);
            k.color('characterCount.foreground', spans[0].style!.color!);
            k.typo('maxCharacterCount.typography', spans[1].style!);
            k.color('maxCharacterCount.foreground', spans[1].style!.color!);
            if (!(spans[0].style!.fontFeatures ?? const []).contains(
              const FontFeature.tabularFigures(),
            )) {
              k.fail('characterCount: 숫자 폭 고정(tabular-nums)이 아니다');
            }
            failures.addAll(k.failures);
          }

          // "선택" — t4 · 줄 높이 22(라벨과 같다) · 앞 4(rem)
          await tester.pumpWidget(
            _host(
              mode,
              PField(
                key: UniqueKey(),
                label: '메모',
                labelWeight: weight,
                indicator: PFieldIndicator.optional,
                child: const PInput(),
              ),
            ),
          );
          final k = _Check(
            mode,
            _field.resolve(combo, 'enabled'),
            '${mode.name} $combo 선택',
          );
          final optional = findText('선택');
          final optionalStyle = tester.widget<Text>(optional).style!;
          // 줄 높이는 라벨과 같은 22 가 t4 의 19 를 덮는다
          k.typo(
            'optionalIndicator.typography',
            optionalStyle,
            lineHeightKey: 'optionalIndicator.lineHeight',
          );
          k.px(
            'optionalIndicator.lineHeight',
            optionalStyle.fontSize! * optionalStyle.height!,
          );
          k.px(
            'optionalIndicator.lineHeight',
            tester
                .getSize(
                  find
                      .ancestor(of: optional, matching: find.byType(SizedBox))
                      .first,
                )
                .height,
          );
          k.color('optionalIndicator.foreground', optionalStyle.color!);
          final optionalPadding =
              tester
                      .widget<Padding>(
                        find
                            .ancestor(
                              of: optional,
                              matching: find.byType(Padding),
                            )
                            .first,
                      )
                      .padding
                  as EdgeInsetsDirectional;
          k.rem('optionalIndicator.paddingLeft', optionalPadding.start);
          failures.addAll(k.failures);
        }
        if (failures.isNotEmpty) {
          fail('${failures.length}개가 스펙과 다르다\n${failures.take(30).join('\n')}');
        }
      });
    }

    testWidgets('typography 의 굵기는 400 — 라벨만 굵기를 덮는다', (tester) async {
      final want = _field.resolve({}, 'enabled');
      for (final slot in [
        'description',
        'errorMessage',
        'characterCount',
        'maxCharacterCount',
        'optionalIndicator',
      ]) {
        expect((want['$slot.typography']! as Map)['fontWeight'], 400);
      }
    });

    testWidgets(
      '라벨은 입력의 이름 — 설명 · 글자 수는 입력의 설명, 필수 · 오류는 입력이 알린다. 라벨 · 점은 따로 읽지 않는다',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          _host(
            _light,
            const PField(
              label: label,
              indicator: PFieldIndicator.required,
              description: description,
              maxGraphemeCount: 12,
              child: PInput(initialValue: '반려동물'),
            ),
          ),
        );
        expect(
          tester.getSemantics(find.byType(EditableText)),
          containsSemantics(
            label: label,
            value: '반려동물',
            hint: '$description\n12자 중 4자',
            isTextField: true,
            hasRequiredState: true,
            isRequired: true,
            validationResult: SemanticsValidationResult.none,
          ),
        );
        // 이름은 입력 하나에만 — 보이는 라벨 · 점은 따로 읽지 않는다
        expect(find.bySemanticsLabel(label), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp('^$label.+')), findsNothing);
        // 설명 · 글자 수는 꼬리의 글로도 닿는다
        expect(find.bySemanticsLabel(description), findsOneWidget);
        expect(find.bySemanticsLabel('12자 중 4자'), findsOneWidget);

        // 오류 — 설명 자리를 대신하고, 입력은 오류임을 알린다(새 칸 — initialValue 는 처음에만 쓴다)
        await tester.pumpWidget(_host(_light, const SizedBox()));
        await tester.pumpWidget(
          _host(
            _light,
            const PField(
              label: '아이디',
              description: '영문 · 숫자 20자까지',
              maxGraphemeCount: 20,
              invalid: true,
              errorMessage: error,
              child: PInput(initialValue: 'groo'),
            ),
          ),
        );
        expect(
          tester.getSemantics(find.byType(EditableText)),
          containsSemantics(
            label: '아이디',
            hint: '$error\n20자 중 4자',
            validationResult: SemanticsValidationResult.invalid,
          ),
        );
        expect(find.bySemanticsLabel(error), findsOneWidget);

        // "선택" 은 이름에 붙는다
        await tester.pumpWidget(_host(_light, const SizedBox()));
        await tester.pumpWidget(
          _host(
            _light,
            const PField(
              label: '메모',
              indicator: PFieldIndicator.optional,
              child: PInput(),
            ),
          ),
        );
        expect(
          tester.getSemantics(find.byType(EditableText)),
          containsSemantics(label: '메모 선택', isTextField: true),
        );
        semantics.dispose();
      },
    );

    testWidgets('라벨을 누르면 입력으로 포커스가 간다', (tester) async {
      await tester.pumpWidget(
        _host(_light, const PField(label: '메모', child: PInput())),
      );
      await tester.tap(_richText('메모'));
      await tester.pump();
      expect(_editable(tester).focusNode.hasFocus, isTrue);
    });

    testWidgets(
      '오류가 생길 때 한 번 알린다 — 같은 오류는 다시 알리지 않고, 바뀌거나 다시 생기면 알린다. 처음부터 있던 오류는 알리지 않는다',
      (tester) async {
        final said = _listenAnnouncements(tester);
        Widget field(String? e) => _host(
          _light,
          PField(
            label: '이름',
            invalid: e != null,
            errorMessage: e,
            child: const PInput(),
          ),
        );
        await tester.pumpWidget(field(null));
        await tester.pumpWidget(field('이름을 입력해주세요.'));
        await tester.pumpWidget(field('이름을 입력해주세요.'));
        await tester.pumpWidget(field('이름은 20자까지예요.'));
        await tester.pumpWidget(field(null));
        await tester.pumpWidget(field('이름을 입력해주세요.'));
        expect(said, ['이름을 입력해주세요.', '이름은 20자까지예요.', '이름을 입력해주세요.']);

        said.clear();
        await tester.pumpWidget(_host(_light, const SizedBox()));
        await tester.pumpWidget(field('이름을 입력해주세요.'));
        expect(said, isEmpty);
      },
    );

    testWidgets('알림을 지원하지 않는 플랫폼은 오류 글이 live region — 따로 알리지 않는다', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final said = _listenAnnouncements(tester);
      Widget field(String? e) => _host(
        _light,
        PField(
          label: '이름',
          invalid: e != null,
          errorMessage: e,
          child: const PInput(),
        ),
        media: (d) => d.copyWith(supportsAnnounce: false),
      );
      await tester.pumpWidget(field(null));
      await tester.pumpWidget(field('이름을 입력해주세요.'));
      expect(said, isEmpty);
      expect(
        tester.getSemantics(findText(keepAll('이름을 입력해주세요.'))),
        containsSemantics(label: '이름을 입력해주세요.', isLiveRegion: true),
      );
      semantics.dispose();
    });

    testWidgets('글자 수 — 자소 단위로 센다(국기 이모지도 한 글자) · 비면 최대와 같은 색 · 최대에서 멈춘다', (
      tester,
    ) async {
      final c = PColors.light;
      await tester.pumpWidget(
        _host(
          _light,
          const PField(label: label, maxGraphemeCount: 3, child: PInput()),
        ),
      );
      expect(_countText(tester, 3), '0/3');
      expect(_countSpans(tester, 3)[0].style!.color, c.fgNeutralSubtle);

      await tester.enterText(find.byType(PInput), '🇰🇷가');
      await tester.pump();
      expect(_countText(tester, 3), '2/3');
      expect(_countSpans(tester, 3)[0].style!.color, c.fgNeutral);

      await tester.enterText(find.byType(PInput), '🇰🇷가나다라');
      await tester.pump();
      expect(_editable(tester).controller.text, '🇰🇷가나');
      expect(_countText(tester, 3), '3/3');
    });

    testWidgets('최대 글자 수 — 한글을 조합하는 동안은 자르지 않고, 조합이 끝나면 잘라 onChanged 로 보낸다', (
      tester,
    ) async {
      final changes = <String>[];
      await tester.pumpWidget(
        _host(
          _light,
          PField(
            label: '이름',
            maxGraphemeCount: 2,
            child: PInput(onChanged: changes.add),
          ),
        ),
      );
      await tester.showKeyboard(find.byType(PInput));
      Future<void> type(TextEditingValue value) async {
        tester.testTextInput.updateEditingValue(value);
        await tester.pump();
      }

      await type(
        const TextEditingValue(
          text: '가',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
      await type(
        const TextEditingValue(
          text: '가낟',
          selection: TextSelection.collapsed(offset: 2),
          composing: TextRange(start: 1, end: 2),
        ),
      );
      // "나" 다음 "ㅏ" — "다" 를 조합하는 중에는 최대를 넘어도 자르지 않는다
      await type(
        const TextEditingValue(
          text: '가나다',
          selection: TextSelection.collapsed(offset: 3),
          composing: TextRange(start: 2, end: 3),
        ),
      );
      expect(_editable(tester).controller.text, '가나다');
      // 조합이 끝나면 자르고 onChanged 로 보낸다
      await type(
        const TextEditingValue(
          text: '가나다',
          selection: TextSelection.collapsed(offset: 3),
        ),
      );
      expect(_editable(tester).controller.text, '가나');
      expect(changes.last, '가나');
      expect(_countText(tester, 2), '2/2');
      // 최대에서는 더 들어가지 않는다
      await type(
        const TextEditingValue(
          text: '가나라',
          selection: TextSelection.collapsed(offset: 3),
        ),
      );
      expect(_editable(tester).controller.text, '가나');
    });

    testWidgets(
      '보조 액션 — Button ghost · neutralSubtle · xsmall · 오른쪽 flush. 위아래로 넘친 자리와 누르는 영역 44 도 받는다',
      (tester) async {
        var taps = 0;
        await tester.pumpWidget(
          _host(
            _light,
            // 위에 자리가 있다 — 넘친 자리는 부모 상자 안에서만 받는다
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: PField(
                label: label,
                headerAction: PFieldAction(
                  label: '예시 보기',
                  onPressed: () => taps++,
                ),
                child: const PInput(),
              ),
            ),
          ),
        );
        final button = tester.widget<PButton>(find.byType(PButton));
        expect(button.variant, PButtonVariant.ghost);
        expect(button.ghostColor, PButtonGhostColor.neutralSubtle);
        expect(button.size, PButtonSize.xsmall);
        expect(button.flush, PButtonFlush.right);

        final field = tester.getRect(find.byType(PField));
        final action = tester.getRect(find.byType(PButton));
        expect(action.top, field.top - 5);
        // Field 위로 넘친 자리(보이는 버튼의 위 5)
        await tester.tapAt(Offset(action.center.dx, field.top - 3));
        // 누르는 영역 44 — 보이는 버튼 위 6 까지
        await tester.tapAt(Offset(action.center.dx, action.top - 5));
        // 아래로 넘친 자리(머리와 입력 사이)
        await tester.tapAt(Offset(action.center.dx, action.bottom - 2));
        await tester.pump(const Duration(milliseconds: 400));
        expect(taps, 3);
        // 44 밖은 받지 않는다
        await tester.tapAt(Offset(action.center.dx, action.top - 8));
        await tester.pump(const Duration(milliseconds: 400));
        expect(taps, 3);
      },
    );

    testWidgets(
      '머리 오른쪽에 위젯(headerTrailing — Slider 머리 값) — 머리 22 를 넘치지 않고 오른쪽 끝에 서며 버튼과 함께 둘 수 없다(Q-015)',
      (tester) async {
        await tester.pumpWidget(
          _host(
            _light,
            const PField(
              label: '알림 기준',
              headerTrailing: Text(
                '80%',
                key: ValueKey('trailing'),
                style: TextStyle(fontSize: 16, height: 22 / 16),
              ),
              child: PInput(),
            ),
          ),
        );
        final field = tester.getRect(find.byType(PField));
        final trailing = tester.getRect(find.byKey(const ValueKey('trailing')));
        final labelRect = tester.getRect(_richText(RegExp('^알림 기준')));
        expect(
          trailing.right,
          field.right - PSpacing.x0_5,
          reason: '머리 오른쪽 끝(좌우 2)',
        );
        expect(
          trailing.top,
          field.top,
          reason: '위아래로 넘치지 않는다(버튼의 −5 는 버튼일 때만)',
        );
        expect(trailing.height, 22);
        expect(labelRect.center.dy, closeTo(trailing.center.dy, 0.5));
        expect(
          tester.getRect(find.byType(PInput)).top - labelRect.bottom,
          PSpacing.x2,
          reason: '머리 높이 22 그대로 — 입력까지 8',
        );
        expect(
          () => PField(
            headerAction: PFieldAction(label: '예시', onPressed: () {}),
            headerTrailing: const SizedBox(),
            child: const PInput(),
          ),
          throwsAssertionError,
        );
      },
    );

    testWidgets('글자 2배에서 머리 오른쪽 값이 길면 라벨 아래 오른쪽 끝으로 내려가고 라벨은 글자마다 깨지지 않는다', (
      tester,
    ) async {
      MediaQueryData twice(MediaQueryData d) =>
          d.copyWith(textScaler: const TextScaler.linear(2));
      await tester.pumpWidget(
        _host(
          _light,
          const SizedBox(
            width: 328,
            child: PField(
              label: '보유 종목',
              headerTrailing: Text(
                '합계 123,456,789원',
                key: ValueKey('trailing'),
                style: TextStyle(fontSize: 16, height: 22 / 16),
              ),
              child: PInput(),
            ),
          ),
          media: twice,
        ),
      );
      expect(tester.takeException(), isNull);
      final field = tester.getRect(find.byType(PField));
      final trailing = tester.getRect(find.byKey(const ValueKey('trailing')));
      final label = tester.getRect(_richText(RegExp('^보유')));
      // 라벨은 한 줄(22 × 2) — 한 글자씩 줄이 바뀌면 네 줄이 된다
      expect(label.height, closeTo(44, 0.5), reason: '낱말 단위 — 글자마다 깨지지 않는다');
      expect(
        trailing.top,
        greaterThanOrEqualTo(label.bottom),
        reason: '자리가 모자라 값이 다음 줄로 내려간다',
      );
      expect(trailing.right, closeTo(field.right - PSpacing.x0_5, 0.5));
      expect(
        tester.getRect(find.byType(PInput)).top,
        greaterThanOrEqualTo(trailing.bottom),
      );
      // 자리가 넉넉하면(1배) 종전처럼 한 줄 — 값이 라벨과 같은 줄
      await tester.pumpWidget(
        _host(
          _light,
          const SizedBox(
            width: 328,
            child: PField(
              label: '보유 종목',
              headerTrailing: Text(
                '80%',
                key: ValueKey('trailing'),
                style: TextStyle(fontSize: 16, height: 22 / 16),
              ),
              child: PInput(),
            ),
          ),
        ),
      );
      final one = tester.getRect(find.byKey(const ValueKey('trailing')));
      final oneLabel = tester.getRect(_richText(RegExp('^보유')));
      expect(one.center.dy, closeTo(oneLabel.center.dy, 0.5));
    });

    testWidgets('필수 점 · "선택" 은 글자 크기 설정을 따라 커진다(rem) — 라벨 줄 위에서 4rem 아래', (
      tester,
    ) async {
      final want = _field.resolve({}, 'enabled');
      final k = _Check(_light, want, '글자 2배');
      MediaQueryData twice(MediaQueryData d) =>
          d.copyWith(textScaler: const TextScaler.linear(2));
      await tester.pumpWidget(
        _host(
          _light,
          const PField(
            label: '이름',
            indicator: PFieldIndicator.required,
            child: PInput(),
          ),
          media: twice,
        ),
      );
      final dot = find.descendant(
        of: find.byType(PField),
        matching: find.byWidgetPredicate(
          (w) =>
              w is DecoratedBox &&
              (w.decoration as BoxDecoration).shape == BoxShape.circle,
        ),
      );
      final dotRect = tester.getRect(dot);
      final labelRect = tester.getRect(_richText(RegExp('^이름')));
      k.rem('requiredIndicator.size', dotRect.width, scale: 2);
      k.rem(
        'requiredIndicator.marginTop',
        dotRect.top - labelRect.top,
        scale: 2,
      );

      await tester.pumpWidget(
        _host(
          _light,
          const PField(
            label: '메모',
            indicator: PFieldIndicator.optional,
            child: PInput(),
          ),
          media: twice,
        ),
      );
      // 보이는 크기 — 자리째 라벨 배율로 커진다(앞 4 → 8 · 줄 높이 22 → 44). 글자는 한 번만 커진다(두 번이면 88)
      final optional = findText('선택');
      final slot = find
          .ancestor(of: optional, matching: find.byType(SizedBox))
          .first;
      final padded = find
          .ancestor(of: optional, matching: find.byType(Padding))
          .first;
      k.rem(
        'optionalIndicator.paddingLeft',
        tester.getRect(slot).left - tester.getRect(padded).left,
        scale: 2,
      );
      expect(tester.getRect(slot).height, 44);
      expect(tester.getRect(optional).height, 44);
      if (k.failures.isNotEmpty) fail(k.failures.join('\n'));
    });

    testWidgets('비활성 · 읽기 전용 · 오류는 Field 에 주면 입력이 받는다 — 입력에 직접 준 값이 이긴다', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          _light,
          const PField(
            label: '계좌',
            disabled: true,
            child: PInput(initialValue: '국민 123-45-6789'),
          ),
        ),
      );
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
      // 라벨을 눌러도 포커스가 가지 않는다
      await tester.tap(_richText('계좌'));
      await tester.pump();
      expect(_editable(tester).focusNode.hasFocus, isFalse);

      await tester.pumpWidget(
        _host(
          _light,
          const PField(
            label: '아이디',
            readOnly: true,
            child: PInput(initialValue: 'groo'),
          ),
        ),
      );
      expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);

      await tester.pumpWidget(
        _host(
          _light,
          const PField(
            label: '이름',
            invalid: true,
            child: PInput(key: ValueKey('a')),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        sameColor(
          PColors.light.strokeCriticalSolid,
          _overlay(tester, find.byType(PInput)).color,
        ),
        isTrue,
      );
      await tester.pumpWidget(
        _host(
          _light,
          const PField(
            label: '이름',
            invalid: true,
            child: PInput(key: ValueKey('b'), invalid: false),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(_overlay(tester, find.byType(PInput)).color.a, 0);
    });
  });

  group('카탈로그 견본', () {
    // 카탈로그(/dev/ds)와 같은 자리 — 폰 폭(390), 목록 여백 16 + 판 여백 20
    for (final (name, demo) in [
      ('Field', const FieldDemo()),
      ('Input', const InputDemo()),
      ('Textarea', const TextareaDemo()),
    ]) {
      testWidgets('$name 견본이 폰 폭에서 라이트 · 다크로 그려진다', (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final semantics = tester.ensureSemantics();
        for (final theme in [GrooTheme.light(), GrooTheme.dark()]) {
          await tester.pumpWidget(
            MaterialApp(
              theme: theme,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('ko'),
              home: Scaffold(
                body: ListView(
                  padding: const EdgeInsets.all(PSpacing.x4 + PSpacing.x5),
                  children: [demo],
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 1100));
          expect(tester.takeException(), isNull, reason: theme.brightness.name);
        }
        await tester.pumpWidget(const SizedBox());
        semantics.dispose();
      });
    }

    testWidgets('제출 시 검증 — 누르면 비어 있는 칸마다 오류, 첫 오류 칸으로 포커스', (tester) async {
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: GrooTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: const Scaffold(body: SingleChildScrollView(child: FieldDemo())),
        ),
      );
      final submit = findWidgetWithText(PButton, '신청');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pump(const Duration(milliseconds: 400));
      expect(findText(keepAll('제목을 입력해주세요.')), findsOneWidget);
      expect(findText(keepAll('휴가 사유를 입력해주세요.')), findsOneWidget);
      final title = find.ancestor(
        of: findText(keepAll('제목을 입력해주세요.')),
        matching: find.byType(PField),
      );
      expect(_editable(tester, title).focusNode.hasFocus, isTrue);
    });
  });

  testWidgets(
    'Field 메시지(도움말 · 오류)는 낱말 단위로 줄을 바꾼다 — 글자 200% 에서도 낱말 중간에서 끊기지 않는다',
    (tester) async {
      tester.view.physicalSize = const Size(360, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const help = '교통 아래에 만들고 거래를 모두 그리로 옮겨요. 그러면 다른 하위도 만들 수 있어요.';
      const error = '같은 자리에 같은 이름의 카테고리가 있어요.';
      for (final invalid in [false, true]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: GrooTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            builder: (c, child) => MediaQuery(
              data: MediaQuery.of(
                c,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(24),
                child: PField(
                  label: '이름',
                  description: help,
                  invalid: invalid,
                  errorMessage: error,
                  child: const PInput(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final shown = invalid ? error : help;
        final finder = findText(keepAll(shown));
        expect(finder, findsOneWidget);
        expect(tester.widget<Text>(finder).semanticsLabel, shown);
        final lines = tester.renderObject<RenderParagraph>(
          find.descendant(of: finder, matching: find.byType(RichText)).first,
        );
        expect(lines.size.height, greaterThan(40), reason: '200% 에서 여러 줄');
        expect(midWordBreaks(tester, finder), isEmpty);
      }
    },
  );

  testWidgets('낱말 중간 줄바꿈 점검기가 keepAll 없는 글은 잡는다(음성 대조)', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 200,
            child: Text(
              '교통 아래에 만들고 거래를 모두 그리로 옮겨요. 그러면 다른 하위도 만들 수 있어요.',
              key: ValueKey('plain'),
              style: TextStyle(fontSize: 20),
            ),
          ),
        ),
      ),
    );
    expect(
      midWordBreaks(tester, find.byKey(const ValueKey('plain'))),
      isNotEmpty,
    );
  });
}
