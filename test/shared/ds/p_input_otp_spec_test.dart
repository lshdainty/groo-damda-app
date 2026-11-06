// Input OTP 가 스펙 값대로인지 — 다시 받기의 때 × 상태 × 라이트 · 다크. 값은 test/fixtures/design_spec/input-otp.json,
// 웹은 같은 JSON 을 크로미움에서 잰다. 앱은 늘 large(52)다 — medium · responsive(1280 이상 데스크톱 웹)는 재지 않는다.
// 아래 동작 묶음은 웹 input-otp.test.tsx 가 잡는 것(숫자만 · 붙여넣기 · 다시 받기 · 초점 · 접근성)을 앱 위젯으로 같이 잡는다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/app/theme/tokens.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/input/text_control.dart';
import 'package:groo_damda_app/shared/ds/input_otp/p_input_otp.dart';

import '../../support/design_spec.dart';
import '../../support/spec_check.dart';
import '../../support/plain_text.dart';

const _description = '10분 안에 입력해주세요 · 5번 틀리면 다시 받아요.';
const _error = '코드가 맞지 않거나 시간이 지났어요. 확인하거나 다시 받아주세요.';

Widget _host(Brightness mode, Widget child, {double width = 320}) =>
    MaterialApp(
      theme: mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.only(top: 40),
            child: SizedBox(width: width, child: child),
          ),
        ),
      ),
    );

String _cooldown(int n) => '다시 받기($n초)';

/// 시계를 손으로 돌린다 — 테스트의 pump 는 DateTime.now() 를 움직이지 않는다.
class _Clock {
  DateTime now = DateTime(2026, 10, 15, 12);
  void advance(Duration d) => now = now.add(d);
}

/// 칸 · 설명 · 다시 받기 한 벌.
class _Sample extends StatefulWidget {
  const _Sample({
    required this.clock,
    this.initialValue,
    this.sentAgo,
    this.invalid = false,
    this.disabled = false,
    this.onResend,
    this.onChanged,
    this.controller,
    this.focusNode,
  });

  final _Clock clock;
  final String? initialValue;
  final Duration? sentAgo;
  final bool invalid;
  final bool disabled;
  final VoidCallback? onResend;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final FocusNode? focusNode;

  @override
  State<_Sample> createState() => _SampleState();
}

class _SampleState extends State<_Sample> {
  late DateTime? sentAt = widget.sentAgo == null
      ? null
      : widget.clock.now.subtract(widget.sentAgo!);
  late final FocusNode own = FocusNode();
  int resends = 0;

  @override
  void dispose() {
    own.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      PField(
        label: '인증 코드',
        description: _description,
        invalid: widget.invalid,
        errorMessage: _error,
        disabled: widget.disabled,
        child: PInputOtp(
          controller: widget.controller,
          initialValue: widget.controller == null ? widget.initialValue : null,
          focusNode: widget.focusNode ?? own,
          placeholder: '6자리 숫자',
          onChanged: widget.onChanged,
        ),
      ),
      PInputOtpResend(
        key: const ValueKey('resend'),
        sentAt: sentAt,
        now: () => widget.clock.now,
        codeFocusNode: widget.focusNode ?? own,
        firstLabel: '코드 받기',
        readyLabel: '다시 받기',
        cooldownLabel: _cooldown,
        onResend: () {
          resends++;
          widget.onResend?.call();
          setState(() => sentAt = widget.clock.now);
        },
      ),
    ],
  );
}

final _frame = find.byType(PTextFrame);
final _editable = find.byType(EditableText);

/// 상자의 세 겹 — 바탕 · 덧그린 2px · 늘 있는 1px.
List<BoxDecoration> _layers(WidgetTester tester) {
  final boxes = find.descendant(
    of: _frame,
    matching: find.byType(DecoratedBox),
  );
  return [
    for (var i = 0; i < 3; i++)
      tester.widget<DecoratedBox>(boxes.at(i)).decoration as BoxDecoration,
  ];
}

void main() {
  final spec = DesignSpec.load('input-otp');

  group('스펙 값 — 다시 받기의 때 × 상태', () {
    for (final mode in Brightness.values) {
      for (final resend in ['first', 'ready', 'cooldown']) {
        for (final state in spec.states) {
          testWidgets('${mode.name} · large · $resend · $state', (
            tester,
          ) async {
            final combo = {'size': 'large', 'resend': resend};
            final want = spec.resolve(combo, state);
            final k = SpecCheck(mode, want, '${mode.name} $combo $state');
            final clock = _Clock();
            await tester.pumpWidget(
              _host(
                mode,
                _Sample(
                  clock: clock,
                  initialValue: '123456',
                  sentAgo: switch (resend) {
                    'first' => null,
                    'ready' => const Duration(seconds: 120),
                    _ => const Duration(seconds: 8),
                  },
                  invalid: state == 'invalid',
                  disabled: state == 'disabled',
                ),
              ),
            );
            if (state == 'focused') {
              await tester.showKeyboard(_editable);
            }
            await tester.pump(const Duration(milliseconds: 400));

            // 칸 — 상자 52 · 모서리 12 · 좌우 16, 테두리 · 바탕은 상태
            final box = tester.getRect(_frame);
            k.px('field.minHeight', box.height);
            final layers = _layers(tester);
            k.px(
              'field.radius',
              (layers[0].borderRadius! as BorderRadius).topLeft.x,
            );
            final edit = tester.getRect(_editable);
            k.px('field.paddingX', edit.left - box.left);
            final bgWant = want['field.background'];
            k.color(
              'field.background',
              layers[0].color ?? const Color(0x00000000),
            );
            if (bgWant == null) k.fail('field.background: 스펙이 없다');
            final wide = state == 'focused' || state == 'invalid';
            final line = wide
                ? (layers[1].border! as Border).bottom
                : (layers[2].border! as Border).bottom;
            k.color('field.borderColor', line.color);
            // 폭 — 늘 있는 1px, 포커스 · 오류는 덧그린 2px
            if (line.width != (wide ? 2 : 1)) {
              k.fail('테두리 폭: 기대 ${wide ? 2 : 1} · 실제 ${line.width}');
            }
            k.m([
              'field.variant',
              'field.width',
              'description.content',
              'resend.label',
            ]);

            // 값 — 글자 · 색 · 고정폭 숫자
            final editable = tester.widget<EditableText>(_editable);
            k.typo('value.typography', editable.style);
            k.color('value.foreground', editable.style.color!);
            final tnum = (editable.style.fontFeatures ?? const []).any(
              (f) => f.feature == 'tnum' && f.value == 1,
            );
            if (want['value.numerals'] == 'tabular-nums' && !tnum) {
              k.fail('value.numerals: 고정폭 숫자가 아니다');
            }
            k.m(['value.numerals']);
            expect(editable.keyboardType, TextInputType.number);
            expect(editable.autofillHints, contains(AutofillHints.oneTimeCode));
            k.m(['value.inputMode', 'value.autoComplete']);

            // 설명 줄 — 오류가 대신한다
            final text = state == 'invalid' ? _error : _description;
            if (want['description.content'] != text) {
              k.fail('description.content: 스펙 ${want['description.content']}');
            }
            final desc = tester.widget<Text>(findText(keepAll(text))).style!;
            k.typo('description.typography', desc);
            k.color('description.foreground', desc.color!);
            expect(
              findText(keepAll(state == 'invalid' ? _description : _error)),
              findsNothing,
            );

            // 다시 받기 — 단추 40 · 칸 아래 12 · 때마다의 글
            final button = find.byType(PButton);
            final b = tester.getRect(button);
            k.px('resend.height', b.height);
            final fieldBottom = tester.getRect(find.byType(PField)).bottom;
            k.px('resend.marginTop', b.top - fieldBottom);
            final label = want['resend.label'] as String;
            final shown = label.replaceAll('{n}', '52');
            if (findText(shown).evaluate().isEmpty) {
              k.fail('resend.label: 기대 "$shown"');
            }
            expect(
              tester.widget<PButton>(button).variant,
              PButtonVariant.neutralWeak,
            );
            expect(tester.widget<PButton>(button).size, PButtonSize.medium);
            k.m(['resend.variant']);
            if (resend == 'cooldown') {
              expect(tester.widget<PButton>(button).onPressed, isNull);
              final deco =
                  tester
                          .widget<DecoratedBox>(
                            find
                                .descendant(
                                  of: button,
                                  matching: find.byType(DecoratedBox),
                                )
                                .first,
                          )
                          .decoration
                      as BoxDecoration;
              k.color('resend.background', deco.color!);
              final style = tester
                  .widget<Text>(
                    find.descendant(of: button, matching: find.byType(Text)),
                  )
                  .style!;
              k.color('resend.foreground', style.color!);
              final mouse = tester
                  .widget<MouseRegion>(
                    find
                        .descendant(
                          of: button,
                          matching: find.byType(MouseRegion),
                        )
                        .first,
                  )
                  .cursor;
              k.cursor('resend.cursor', mouse);
            } else {
              expect(tester.widget<PButton>(button).onPressed, isNotNull);
            }
            k.coverage({
              'field.breakpoint', // responsive 는 1280 이상 데스크톱 웹만
              'value.textAlign', // start — 칸이 왼쪽부터 쓴다(동작 묶음)
              'value.filter', // 숫자만 · 앞 6자리 — 동작 묶음
              'value.autoSubmit', // 없음 — 동작 묶음
              'placeholder.content', // 아래 placeholder 묶음
              'placeholder.foreground',
              'resend.cooldown', // 60초 — 동작 묶음
              'resend.focus', // 보내면 칸으로 — 동작 묶음
            });
            expect(k.failures, isEmpty);
          });
        }
      }
    }

    for (final mode in Brightness.values) {
      testWidgets('${mode.name} — 빈 칸의 글 "6자리 숫자"', (tester) async {
        final want = spec.resolve({'size': 'large'}, 'enabled');
        final k = SpecCheck(mode, want, 'placeholder ${mode.name}');
        await tester.pumpWidget(_host(mode, _Sample(clock: _Clock())));
        expect(findText('${want['placeholder.content']}'), findsOneWidget);
        final style = tester.widget<Text>(findText('6자리 숫자')).style!;
        k.color('placeholder.foreground', style.color!);
        expect(k.failures, isEmpty);
      });
    }

    // 01T-013 — 막혀도 자리 글은 fg-placeholder 다(Input 의 fg-disabled 를 덮는다)
    for (final mode in Brightness.values) {
      testWidgets('${mode.name} — 막혀도 빈 칸의 글은 fg-placeholder', (tester) async {
        final want = spec.resolve({'size': 'large'}, 'disabled');
        final k = SpecCheck(mode, want, 'placeholder disabled ${mode.name}');
        await tester.pumpWidget(
          _host(mode, _Sample(clock: _Clock(), disabled: true)),
        );
        final style = tester.widget<Text>(findText('6자리 숫자')).style!;
        k.color('placeholder.foreground', style.color!);
        expect(k.failures, isEmpty);
        final tokens = mode == Brightness.dark
            ? GrooTokens.dark
            : GrooTokens.light;
        expect(style.color, tokens.fgPlaceholder);
        // 다크는 두 역할이 같은 값(#838997)이라 라이트에서만 갈린다
        if (mode == Brightness.light) {
          expect(style.color, isNot(tokens.fgDisabled));
        }
      });
    }
  });

  group('숫자만 받는다', () {
    test('글에서 숫자만 — 띄어쓰기 · 붙임표 · 문장 · 전각 숫자', () {
      expect(otpDigitsOf('123 456'), '123456');
      expect(otpDigitsOf('123-456'), '123456');
      expect(otpDigitsOf(' 123456'), '123456');
      expect(otpDigitsOf('인증 코드: 123456'), '123456');
      expect(otpDigitsOf('１２３４５６'), '123456');
      expect(otpDigitsOf('abc'), '');
    });

    Future<TextEditingController> pump(
      WidgetTester tester, {
      String? initial,
      List<String>? changes,
    }) async {
      final controller = TextEditingController(text: initial);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _Sample(
            clock: _Clock(),
            controller: controller,
            onChanged: changes?.add,
          ),
        ),
      );
      return controller;
    }

    testWidgets('치면 숫자만 들어가고 6자리에서 멈춘다', (tester) async {
      final changes = <String>[];
      final c = await pump(tester, changes: changes);
      await tester.enterText(_editable, '1');
      await tester.enterText(_editable, '12a');
      expect(c.text, '12');
      await tester.enterText(_editable, '1234567');
      expect(c.text, '123456');
      expect(changes.last, '123456');
      // 6자리를 채워도 아무것도 보내지 않는다 — 값이 바뀐 알림뿐
      expect(find.byType(PButton), findsOneWidget);
    });

    testWidgets('붙여넣기 — "123 456" · "인증 코드: 654321" 은 통째로 코드가 된다', (
      tester,
    ) async {
      final c = await pump(tester, initial: '12');
      await tester.enterText(_editable, '12123 456');
      expect(c.text, '123456'); // 칸의 "12" 와 섞이지 않는다
      await tester.enterText(_editable, '인증 코드: 654321');
      expect(c.text, '654321');
      await tester.enterText(_editable, '654321１２３');
      expect(c.text, '654321');
    });

    testWidgets('짧은 붙여넣기는 커서 자리에 넣고 숫자만 남긴다', (tester) async {
      final c = await pump(tester, initial: '12');
      await tester.enterText(_editable, '1-2');
      expect(c.text, '12');
      await tester.enterText(_editable, '12 34');
      expect(c.text, '1234');
    });

    testWidgets('값이 그대로면 알리지 않는다', (tester) async {
      final changes = <String>[];
      await pump(tester, initial: '12', changes: changes);
      await tester.enterText(_editable, '12a');
      expect(changes, isEmpty);
    });

    testWidgets('걸러져 글이 바뀌면 커서는 그 앞 숫자 뒤에 둔다', (tester) async {
      final c = await pump(tester, initial: '12');
      await tester.showKeyboard(_editable);
      // "1" 과 "2" 사이에 "a" 를 치면 — "a" 는 걸러지고 커서는 "1" 뒤
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '1a2',
          selection: TextSelection.collapsed(offset: 2),
        ),
      );
      await tester.pump();
      expect(c.text, '12');
      expect(c.selection, const TextSelection.collapsed(offset: 1));
    });

    test('자릿수는 length — 4자리 코드', () {
      const f = PInputOtpFormatter(length: 4);
      final v = f.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '1234567'),
      );
      expect(v.text, '1234');
    });
  });

  group('다시 받기', () {
    testWidgets('보내기 전 "코드 받기" → 누르면 "다시 받기(60초)" 로 막히고 초가 준다', (tester) async {
      final clock = _Clock();
      var sent = 0;
      await tester.pumpWidget(
        _host(Brightness.light, _Sample(clock: clock, onResend: () => sent++)),
      );
      expect(findText('코드 받기'), findsOneWidget);
      await tester.tap(find.byType(PButton));
      await tester.pump();
      expect(sent, 1);
      expect(findText('다시 받기(60초)'), findsOneWidget);
      expect(tester.widget<PButton>(find.byType(PButton)).onPressed, isNull);
      // 1초마다 줄어든다
      clock.advance(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(findText('다시 받기(59초)'), findsOneWidget);
      clock.advance(const Duration(seconds: 58));
      await tester.pump(const Duration(seconds: 58));
      expect(findText('다시 받기(1초)'), findsOneWidget);
      // 0 이 되면 풀린다
      clock.advance(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(findText('다시 받기'), findsOneWidget);
      expect(tester.widget<PButton>(find.byType(PButton)).onPressed, isNotNull);
    });

    testWidgets('남은 초는 60 을 넘지 않고 올림한다', (tester) async {
      expect(
        otpRemainingOf(DateTime(2026), 60, DateTime(2026, 1, 1, 0, 0, 0, 1)),
        60,
      );
      expect(
        otpRemainingOf(DateTime(2026), 60, DateTime(2026, 1, 1, 0, 0, 7, 500)),
        53,
      );
      expect(otpRemainingOf(DateTime(2026), 60, DateTime(2026, 1, 1, 0, 1)), 0);
      expect(otpRemainingOf(null, 60, DateTime(2026)), 0);
    });

    testWidgets('누르면 초점이 코드 칸으로 간다 — 막히는 단추에 남지 않는다', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _Sample(
            clock: _Clock(),
            sentAgo: const Duration(seconds: 120),
            focusNode: node,
          ),
        ),
      );
      expect(node.hasFocus, isFalse);
      await tester.tap(find.byType(PButton));
      await tester.pump();
      expect(node.hasFocus, isTrue);
    });

    testWidgets('막힌 동안은 눌러도 보내지 않는다', (tester) async {
      var sent = 0;
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _Sample(
            clock: _Clock(),
            sentAgo: const Duration(seconds: 8),
            onResend: () => sent++,
          ),
        ),
      );
      await tester.tap(find.byType(PButton), warnIfMissed: false);
      await tester.pump();
      expect(sent, 0);
    });

    testWidgets('남은 초는 단추 이름에 들어 있다 — 1초마다 알리지 않는다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _Sample(clock: _Clock(), sentAgo: const Duration(seconds: 8)),
        ),
      );
      expect(find.bySemanticsLabel('다시 받기(52초)'), findsOneWidget);
      handle.dispose();
    });
  });

  group('접근성 · 가장 나쁜 값', () {
    testWidgets('칸 하나 — 이름은 Field 라벨, 설명은 이어 읽힌다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(Brightness.light, _Sample(clock: _Clock())),
      );
      expect(find.bySemanticsLabel(RegExp('인증 코드')), findsWidgets);
      // 칸을 자릿수만큼 나누지 않는다 — 입력이 하나뿐이다
      expect(find.byType(EditableText), findsOneWidget);
      handle.dispose();
    });

    for (final mode in Brightness.values) {
      testWidgets('${mode.name} · 폭 360 · 6자리 꽉 찬 값 · 남은 초 한 자리 — 넘치지 않는다', (
        tester,
      ) async {
        await tester.pumpWidget(
          _host(
            mode,
            _Sample(
              clock: _Clock(),
              initialValue: '000000',
              sentAgo: const Duration(seconds: 55),
              invalid: true,
            ),
            width: 360,
          ),
        );
        expect(tester.takeException(), isNull);
        expect(findText('다시 받기(5초)'), findsOneWidget);
        expect(tester.getSize(_frame).height, 52);
      });
    }
  });
}
