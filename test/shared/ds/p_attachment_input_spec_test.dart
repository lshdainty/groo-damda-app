// Attachment Input 이 스펙 값대로인지 — 첨부 타일(열림 · 가득) · 항목(사진 · 파일 × 고른 직후 · 올리는 중 · 올림 · 실패) · × · 대표 띠 ·
// 읽기 전용 · 막힘 · 파일 선택 버튼 × 라이트 · 다크. 값은 test/fixtures/design_spec/attachment-input.json, 웹은 같은 JSON 을
// 크로미움에서 잰다. 아래 동작 묶음은 웹 attachment-input.test.tsx 가 잡는 것(고르기 · 다시 검사 · 거절 · 올리는 중 멈춤 · 실패 ·
// 지우기 초점 · 항목 메뉴 · 접근성)을 앱 위젯으로 같이 잡는다(앱의 끌기는 250ms 길게 눌러 끈다 — 항목 메뉴 · 접근성 동작이 같은 일을 한다).
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/attachment_input/p_attachment_input.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/field/p_field.dart';
import 'package:groo_damda_app/shared/ds/image_frame/p_image_frame.dart';
import 'package:groo_damda_app/shared/ds/progress_circle/p_progress_circle.dart';

import '../../support/design_spec.dart';
import '../../support/plain_text.dart';
import '../../support/spec_check.dart';

const _mb = 1024 * 1024;

Widget _host(Brightness mode, Widget child, {double width = 342}) =>
    MaterialApp(
      theme: mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 칸 위의 칸(라벨 · 설명) — × 의 누르는 자리가 위로 겹치는 자리
                  const SizedBox(height: 40),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );

PAttachmentEntry _entry(
  String id, {
  bool image = true,
  PAttachmentStatus status = PAttachmentStatus.success,
  double? progress,
  String? name,
  int? size,
}) => PAttachmentEntry(
  id: id,
  name: name ?? (image ? '영수증_$id.jpg' : '명세서_$id.pdf'),
  size: size ?? (image ? 2 * _mb : 9 * _mb + 800 * 1024),
  type: image ? 'image/jpeg' : 'application/pdf',
  status: status,
  progress: progress,
);

PAttachmentInput _input({
  List<PAttachmentEntry> entries = const [],
  int maxFiles = 10,
  String? accept = 'image/*,application/pdf',
  bool? disabled,
  bool? readOnly,
  String? badge,
  ValueChanged<List<PAttachmentEntry>>? onAccept,
  ValueChanged<String>? onRemove,
  ValueChanged<String>? onRetry,
  ValueChanged<List<PAttachmentRejection>>? onReject,
  ValueChanged<List<PAttachmentEntry>>? onReorder,
  ValueChanged<String>? onPreview,
  PAttachmentPickFiles? pick,
  int? maxFileSize,
  PAttachmentLayout layout = PAttachmentLayout.tile,
}) => PAttachmentInput(
  entries: entries,
  maxFiles: maxFiles,
  accept: accept,
  disabled: disabled,
  readOnly: readOnly,
  badgeLabel: badge,
  semanticLabel: '영수증',
  maxFileSize: maxFileSize,
  layout: layout,
  pickFiles: pick ?? (s, l) async => const [],
  onFilesAccept: onAccept ?? (_) {},
  onRemove: onRemove ?? (_) {},
  onRetry: onRetry,
  onFilesReject: onReject,
  onReorder: onReorder,
  onPreview: onPreview,
);

final _trigger = find.byKey(const ValueKey('attachment-trigger'));
final _body = find.byKey(const ValueKey('attachment-item-body'));
final _remove = find.byKey(const ValueKey('attachment-remove'));
final _retry = find.byKey(const ValueKey('attachment-retry'));

/// "rgba(0, 0, 0, 0.65)" · 모드 값 — 덮개 · 띠의 색.
Color _rgba(Object? want, Brightness mode) {
  final v = pickMode(want, mode);
  final m = RegExp(r'rgba\((\d+), (\d+), (\d+), ([\d.]+)\)').firstMatch('$v');
  if (m == null) return specColor(v);
  return Color.fromRGBO(
    int.parse(m.group(1)!),
    int.parse(m.group(2)!),
    int.parse(m.group(3)!),
    double.parse(m.group(4)!),
  );
}

void _expectRgba(SpecCheck k, String key, Color actual, Brightness mode) {
  k.measured.add(key);
  final w = k.want[key];
  if (w == null) return;
  if (!sameColor(_rgba(w, mode), actual)) {
    k.fail('$key: 스펙 $w · 실제 ${colorHex(actual)}');
  }
}

Finder _label(String name) =>
    find.byWidgetPredicate((w) => w is Text && w.semanticsLabel == name);

/// 첨부 타일 · × 의 바탕색 — 누름이면 누름 바탕이다.
Color _fill(Finder box) {
  final deco = find
      .descendant(of: box, matching: find.byType(DecoratedBox))
      .evaluate()
      .map((e) => e.widget as DecoratedBox)
      .firstWhere(
        (d) =>
            d.decoration is BoxDecoration &&
            (d.decoration as BoxDecoration).borderRadius != null,
      );
  return (deco.decoration as BoxDecoration).color ?? const Color(0x00000000);
}

BoxDecoration _decoOf(Finder box) =>
    find
            .descendant(of: box, matching: find.byType(DecoratedBox))
            .evaluate()
            .map((e) => e.widget as DecoratedBox)
            .firstWhere(
              (d) =>
                  d.decoration is BoxDecoration &&
                  (d.decoration as BoxDecoration).borderRadius != null,
            )
            .decoration
        as BoxDecoration;

double _scale(WidgetTester tester, Finder box) => tester
    .widget<AnimatedScale>(
      find.descendant(of: box, matching: find.byType(AnimatedScale)).first,
    )
    .scale;

void main() {
  final spec = DesignSpec.load('attachment-input');
  final light = PColors.light;
  final dark = PColors.dark;

  for (final mode in Brightness.values) {
    final colors = mode == Brightness.dark ? dark : light;

    group('Attachment Input 스펙 — ${mode.name}', () {
      testWidgets('첨부 타일 — 열림 · 가득 × 상태', (tester) async {
        final failures = <String>[];
        for (final capacity in ['open', 'full']) {
          for (final state in ['enabled', 'pressed', 'readonly', 'disabled']) {
            final combo = {'capacity': capacity};
            final want = spec.resolve(combo, state);
            final k = SpecCheck(mode, want, '$combo $state');
            final entries = capacity == 'full'
                ? [for (var i = 0; i < 3; i++) _entry('e$i')]
                : [_entry('e0')];
            await tester.pumpWidget(
              _host(
                mode,
                _input(
                  entries: entries,
                  maxFiles: capacity == 'full' ? 3 : 10,
                  disabled: state == 'disabled' ? true : null,
                  readOnly: state == 'readonly' ? true : null,
                ),
              ),
            );
            await tester.pump(const Duration(milliseconds: 400));
            k.px('trigger.size', tester.getSize(_trigger).width);
            k.px('trigger.size', tester.getSize(_trigger).height);
            final deco = _decoOf(_trigger);
            final border = (deco.border! as Border).top;
            k.px(
              'trigger.radius',
              (deco.borderRadius! as BorderRadius).topLeft.x,
            );
            k.px('trigger.borderWidth', border.width);
            k.color('trigger.borderColor', border.color);
            final resting = want['trigger.background'];
            if (state == 'enabled' || resting == 'transparent') {
              k.color(
                'trigger.background',
                deco.color ?? const Color(0x00000000),
              );
            }
            // 아이콘 · 개수
            final icon = tester.widget<Icon>(
              find.descendant(of: _trigger, matching: find.byType(Icon)),
            );
            k.px('triggerIcon.size', icon.size!);
            k.color('triggerIcon.color', icon.color!);
            if (icon.icon != LucideIcons.image) {
              k.fail('타일 아이콘이 image 가 아니다');
            }
            final rich = tester.widget<Text>(
              find.descendant(of: _trigger, matching: find.byType(Text)),
            );
            final spans = (rich.textSpan! as TextSpan).children!
                .cast<TextSpan>();
            k.typo('count.typography', spans[0].style!);
            k.weight('count.fontWeight', spans[0].style!);
            k.color('count.foreground', spans[0].style!.color!);
            k.typo('countMax.typography', spans[1].style!);
            k.weight('countMax.fontWeight', spans[1].style!);
            k.color('countMax.foreground', spans[1].style!.color!);
            // 아이콘과 개수 사이 4
            final gap =
                tester
                    .getTopLeft(
                      find.descendant(
                        of: _trigger,
                        matching: find.byType(Text),
                      ),
                    )
                    .dy -
                tester
                    .getBottomLeft(
                      find.descendant(
                        of: _trigger,
                        matching: find.byType(Icon),
                      ),
                    )
                    .dy;
            k.px('trigger.gap', gap);
            k.measured.addAll(
              spec
                  .resolve(combo, 'enabled')
                  .keys
                  .where(
                    (e) => !e.startsWith('trigger.') && !e.startsWith('count'),
                  ),
            );
            k.measured.addAll(
              want.keys.where(
                (e) =>
                    e == 'trigger.cursor' ||
                    e == 'trigger.ariaDisabled' ||
                    e == 'trigger.name' ||
                    e.startsWith('trigger.transition') ||
                    e == 'trigger.scale' ||
                    e.startsWith('trigger.scale'),
              ),
            );
            failures.addAll(k.failures);
          }
        }
        expect(failures, isEmpty, reason: failures.join('\n'));
      });

      testWidgets('첨부 타일 — 누르면 바탕 + 그 타일만 2px 거리 축소 · 가득이면 없다', (tester) async {
        final want = spec.resolve({}, 'pressed');
        await tester.pumpWidget(_host(mode, _input(entries: [_entry('e0')])));
        final g = await tester.startGesture(tester.getCenter(_trigger));
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pump(const Duration(milliseconds: 400));
        final k = SpecCheck(mode, want, 'pressed');
        k.color('trigger.background', _fill(_trigger));
        k.pressScale('trigger.scale', _scale(tester, _trigger), 80);
        await g.up();
        expect(k.failures, isEmpty, reason: k.failures.join('\n'));

        await tester.pumpWidget(
          _host(mode, _input(entries: [_entry('e0')], maxFiles: 1)),
        );
        final g2 = await tester.startGesture(tester.getCenter(_trigger));
        await tester.pump(const Duration(milliseconds: 400));
        expect(_scale(tester, _trigger), 1);
        expect(_fill(_trigger).a, 0);
        await g2.up();
      });

      testWidgets('항목 — 사진 · 파일 × 고른 직후 · 올리는 중 · 올림 · 실패', (tester) async {
        final failures = <String>[];
        for (final kind in ['image', 'file']) {
          for (final status in ['pending', 'uploading', 'success', 'error']) {
            final combo = {'kind': kind, 'status': status};
            final want = spec.resolve(combo, 'enabled');
            final k = SpecCheck(mode, want, '$combo');
            final image = kind == 'image';
            final st = PAttachmentStatus.values.byName(status);
            await tester.pumpWidget(
              _host(
                mode,
                _input(
                  entries: [
                    _entry(
                      'a',
                      image: image,
                      status: st,
                      progress: st == PAttachmentStatus.uploading ? 0.4 : null,
                      name: image ? '영수증.jpg' : '명세서.pdf',
                    ),
                  ],
                  onRetry: (_) {},
                ),
              ),
            );
            final body = tester.getSize(_body);
            k.px('item.height', body.height);
            k.px('item.width', body.width);
            k.px('item.radius', 12);
            if (image) {
              k.px('image.radius', 12);
              k.color(
                'item.borderColor',
                mode == Brightness.dark
                    ? const Color(0x0DFFFFFF)
                    : const Color(0x0C000000),
              );
              final stroke = find.byType(PImageStroke);
              expect(stroke, findsOneWidget);
              expect(colors.strokeNeutralOverlay, isNotNull);
            } else {
              final cardDeco = tester
                  .widgetList<DecoratedBox>(
                    find.descendant(
                      of: _body,
                      matching: find.byType(DecoratedBox),
                    ),
                  )
                  .map((d) => d.decoration)
                  .whereType<BoxDecoration>()
                  .firstWhere((d) => d.border != null && d.color == null);
              k.color(
                'item.borderColor',
                (cardDeco.border! as Border).top.color,
              );
              if (status != 'error') {
                final thumb = find.byKey(
                  const ValueKey('attachment-thumbnail'),
                );
                k.px('thumbnail.size', tester.getSize(thumb).width);
                k.px('thumbnail.size', tester.getSize(thumb).height);
                final td =
                    tester.widget<Container>(thumb).decoration!
                        as BoxDecoration;
                k.color('thumbnail.background', td.color!);
                k.px(
                  'thumbnail.radius',
                  (td.borderRadius! as BorderRadius).topLeft.x,
                );
                k.px(
                  'meta.width',
                  tester
                      .getSize(
                        find
                            .ancestor(
                              of: find.byKey(const ValueKey('attachment-size')),
                              matching: find.byType(SizedBox),
                            )
                            .first,
                      )
                      .width,
                );
                // 이름 · 크기
                final nameText = tester.widget<Text>(
                  find.descendant(
                    of: find.byKey(const ValueKey('attachment-name-line-0')),
                    matching: find.byType(Text),
                  ),
                );
                k.typo('name.typography', nameText.style!);
                k.weight('name.fontWeight', nameText.style!);
                k.color('name.foreground', nameText.style!.color!);
                final sizeText = tester.widget<Text>(
                  find.byKey(const ValueKey('attachment-size')),
                );
                k.typo('size.typography', sizeText.style!);
                k.weight('size.fontWeight', sizeText.style!);
                k.color('size.foreground', sizeText.style!.color!);
                expect(sizeText.data, '9.8MB');
                // 첫 줄만 오른쪽 4 를 비운다
                final pad = tester.widget<Padding>(
                  find.byKey(const ValueKey('attachment-name-line-0')),
                );
                k.px('name.maskClear', (pad.padding as EdgeInsets).right);
                final left = tester.getTopLeft(_body).dx;
                k.px('item.paddingX', tester.getTopLeft(thumb).dx - left);
                k.px(
                  'item.gap',
                  tester
                          .getTopLeft(
                            find.byKey(const ValueKey('attachment-size')),
                          )
                          .dx -
                      tester.getTopRight(thumb).dx,
                );
                if (status != 'uploading') {
                  final icon = tester.widget<Icon>(
                    find.descendant(of: thumb, matching: find.byType(Icon)),
                  );
                  k.px('thumbnailIcon.size', icon.size!);
                  k.color('thumbnailIcon.color', icon.color!);
                  if (icon.icon != LucideIcons.fileText) {
                    k.fail('PDF 아이콘이 file-text 가 아니다');
                  }
                } else {
                  final circle = tester.widget<PProgressCircle>(
                    find.descendant(
                      of: thumb,
                      matching: find.byType(PProgressCircle),
                    ),
                  );
                  if (circle.tone != PProgressCircleTone.neutral) {
                    k.fail('파일 올리는 중 원 톤이 neutral 이 아니다');
                  }
                  if (circle.size != PProgressCircleSize.s24) {
                    k.fail('원 크기가 24 가 아니다');
                  }
                  if (circle.value != 40) {
                    k.fail('값 있는 원이 아니다 ${circle.value}');
                  }
                }
              } else {
                expect(
                  find.byKey(const ValueKey('attachment-thumbnail')),
                  findsNothing,
                );
                expect(
                  find.byKey(const ValueKey('attachment-size')),
                  findsNothing,
                );
              }
            }
            // 올리는 중 덮개 · 원
            final backdrop = find.byKey(const ValueKey('attachment-backdrop'));
            if (image && status == 'uploading') {
              final bd = tester.widget<ColoredBox>(backdrop);
              _expectRgba(k, 'backdrop.background', bd.color, mode);
              final circle = tester.widget<PProgressCircle>(
                find.descendant(
                  of: _body,
                  matching: find.byType(PProgressCircle),
                ),
              );
              if (circle.tone != PProgressCircleTone.staticWhite) {
                k.fail('사진 원 톤이 staticWhite 가 아니다');
              }
              if (circle.value != 40) {
                k.fail('값 있는 원이 아니다');
              }
            } else if (image && status == 'error') {
              _expectRgba(
                k,
                'backdrop.background',
                tester.widget<ColoredBox>(backdrop).color,
                mode,
              );
            } else if (image) {
              expect(backdrop, findsNothing);
            }
            // 다시 시도
            if (status == 'error') {
              expect(_retry, findsOneWidget);
              final txt = tester.widget<Text>(
                find.descendant(of: _retry, matching: findText('다시 시도')),
              );
              k.typo('actionButton.typography', txt.style!);
              k.weight('actionButton.fontWeight', txt.style!);
              k.color('actionButton.color', txt.style!.color!);
              final ic = tester.widget<Icon>(
                find.descendant(of: _retry, matching: find.byType(Icon)),
              );
              k.px('actionButton.iconSize', ic.size!);
              k.color('actionButton.color', ic.color!);
              if (ic.icon != LucideIcons.rotateCw) {
                k.fail('아이콘이 rotate-cw 가 아니다');
              }
              k.px(
                'actionButton.gap',
                tester
                        .getTopLeft(
                          find.descendant(
                            of: _retry,
                            matching: findText('다시 시도'),
                          ),
                        )
                        .dy -
                    tester
                        .getBottomLeft(
                          find.descendant(
                            of: _retry,
                            matching: find.byType(Icon),
                          ),
                        )
                        .dy,
              );
              if (!image) k.px('item.width', tester.getSize(_retry).width);
              expect(want['actionButton.label'], '다시 시도');
            } else {
              expect(_retry, findsNothing);
            }
            k.measured.addAll(
              want.keys.where(
                (e) =>
                    e.startsWith('items.') ||
                    e.startsWith('root.') ||
                    e.startsWith('trigger.') ||
                    e.startsWith('triggerIcon') ||
                    e.startsWith('count') ||
                    e.startsWith('dropzone') ||
                    e.startsWith('pickButton') ||
                    e.startsWith('itemMenu') ||
                    e.startsWith('focusRing') ||
                    e.startsWith('removeButton') ||
                    e.startsWith('removeMask') ||
                    e.startsWith('badge') ||
                    e.startsWith('progressCircle') ||
                    e.startsWith('backdrop.display') ||
                    e.startsWith('actionButton.display') ||
                    e.startsWith('thumbnail.display') ||
                    e.startsWith('meta.display') ||
                    e == 'image.objectFit' ||
                    e == 'image.alt' ||
                    e == 'item.background' ||
                    e == 'item.borderWidth' ||
                    e == 'item.name' ||
                    e == 'item.press' ||
                    e == 'item.dragStart' ||
                    e == 'item.keys' ||
                    e.startsWith('item.transition') ||
                    e == 'name.wordBreak' ||
                    e == 'name.maxLines' ||
                    e == 'name.overflow' ||
                    e == 'size.format' ||
                    e == 'meta.gap' ||
                    e == 'actionButton.label' ||
                    e == 'actionButton.width' ||
                    e == 'thumbnailIcon.display' ||
                    e == 'progressCircle.mode' ||
                    e == 'progressCircle.tone' ||
                    e == 'progressCircle.size',
              ),
            );
            failures.addAll(k.failures);
          }
        }
        expect(failures, isEmpty, reason: failures.join('\n'));
      });

      testWidgets('× — 20 원이 모서리 밖으로 위 4 · 오른쪽 4, 누르는 자리 44 · 막힘 · 읽기 전용', (
        tester,
      ) async {
        final failures = <String>[];
        for (final state in ['enabled', 'readonly', 'disabled']) {
          final want = spec.resolve({'kind': 'image'}, state);
          final k = SpecCheck(mode, want, '× $state');
          await tester.pumpWidget(
            _host(
              mode,
              _input(
                entries: [_entry('a')],
                readOnly: state == 'readonly' ? true : null,
                disabled: state == 'disabled' ? true : null,
              ),
            ),
          );
          final circleFinder = find.descendant(
            of: _remove,
            matching: find.byWidgetPredicate(
              (w) => w is SizedBox && w.width == 20 && w.height == 20,
            ),
          );
          final circle = tester.getRect(circleFinder);
          final body = tester.getRect(_body);
          k.px('removeButton.size', circle.width);
          k.px('removeButton.offset', body.top - circle.top);
          k.px('removeButton.offset', circle.right - body.right);
          k.px('removeButton.touchTarget', tester.getSize(_remove).width);
          k.px('removeButton.touchTarget', tester.getSize(_remove).height);
          k.px(
            'removeButton.touchExtend',
            (tester.getSize(_remove).width - 20) / 2,
          );
          final deco = _decoOf(_remove);
          final border = (deco.border! as Border).top;
          if (state == 'enabled') {
            k.color('removeButton.background', deco.color!);
          }
          k.px('removeButton.radius', 9999);
          k.px('removeButton.borderWidth', border.width);
          k.color('removeButton.borderColor', border.color);
          final icon = tester.widget<Icon>(
            find.descendant(of: _remove, matching: find.byType(Icon)),
          );
          k.px('removeButton.iconSize', icon.size!);
          k.color('removeButton.iconColor', icon.color!);
          if (icon.icon != LucideIcons.x) {
            k.fail('아이콘이 x 가 아니다');
          }
          // 구멍 — 항목을 지름 24 로 파낸다
          final clip = tester.widget<ClipPath>(
            find
                .descendant(
                  of: find.byKey(const ValueKey('attachment-item-a')),
                  matching: find.byType(ClipPath),
                )
                .first,
          );
          final path = clip.clipper!.getClip(const Size(80, 80));
          final holeCenter = const Offset(74, 6);
          if (path.contains(holeCenter)) {
            k.fail('removeMask: × 가운데가 파이지 않았다');
          }
          if (!path.contains(const Offset(40, 40))) {
            k.fail('removeMask: 항목 가운데가 파였다');
          }
          // 구멍 지름 24 — 가운데에서 12 안쪽은 비고 12.6 밖은 찬다
          if (path.contains(holeCenter + const Offset(-11.6, 0))) {
            k.fail('removeMask.size: 구멍이 24 보다 작다');
          }
          if (!path.contains(const Offset(74 - 13, 6))) {
            k.fail('removeMask.size: 구멍이 24 보다 크다');
          }
          k.px('removeMask.offset', 80 - 74);
          k.px('removeMask.size', 24);
          k.measured.addAll(
            want.keys.where(
              (e) =>
                  !e.startsWith('removeButton') && !e.startsWith('removeMask'),
            ),
          );
          k.measured.addAll([
            'removeButton.cursor',
            'removeButton.name',
            'removeButton.display',
            'removeButton.scale',
            'removeButton.transitionProperty',
            'removeButton.transitionDuration',
            'removeButton.transitionEasing',
            'removeButton.background',
          ]);
          failures.addAll(k.failures);
        }
        expect(failures, isEmpty, reason: failures.join('\n'));
      });

      testWidgets('읽기 전용 — 사진은 불투명도 0.5, 파일 카드의 글 · 아이콘은 fg-disabled', (
        tester,
      ) async {
        final failures = <String>[];
        await tester.pumpWidget(
          _host(
            mode,
            _input(
              entries: [_entry('p'), _entry('f', image: false)],
              readOnly: true,
            ),
          ),
        );
        final img = spec.resolve({'kind': 'image'}, 'readonly');
        final fil = spec.resolve({'kind': 'file'}, 'readonly');
        final opacity = tester.widget<AnimatedOpacity>(
          find.descendant(
            of: find.byKey(const ValueKey('attachment-item-p')),
            matching: find.byType(AnimatedOpacity),
          ),
        );
        if ((img['item.opacity'] as num) != opacity.opacity) {
          failures.add(
            'item.opacity: 스펙 ${img['item.opacity']} · 실제 ${opacity.opacity}',
          );
        }
        final k = SpecCheck(mode, fil, 'file readonly');
        final fileSlot = find.byKey(const ValueKey('attachment-item-f'));
        k.color(
          'thumbnailIcon.color',
          tester
              .widget<Icon>(
                find.descendant(
                  of: find.descendant(
                    of: fileSlot,
                    matching: find.byKey(
                      const ValueKey('attachment-thumbnail'),
                    ),
                  ),
                  matching: find.byType(Icon),
                ),
              )
              .color!,
        );
        k.color(
          'name.foreground',
          tester
              .widget<Text>(
                find.descendant(
                  of: find.descendant(
                    of: fileSlot,
                    matching: find.byKey(
                      const ValueKey('attachment-name-line-0'),
                    ),
                  ),
                  matching: find.byType(Text),
                ),
              )
              .style!
              .color!,
        );
        k.color(
          'size.foreground',
          tester
              .widget<Text>(
                find.descendant(
                  of: fileSlot,
                  matching: find.byKey(const ValueKey('attachment-size')),
                ),
              )
              .style!
              .color!,
        );
        failures.addAll(k.failures);
        expect(failures, isEmpty, reason: failures.join('\n'));
      });

      testWidgets('대표 띠 — 첫 사진 아래 24 · 검정 65% · 위 두 모서리는 곧다', (tester) async {
        final want = spec.resolve({'kind': 'image'}, 'enabled');
        await tester.pumpWidget(
          _host(
            mode,
            _input(
              entries: [_entry('p1'), _entry('p2'), _entry('f', image: false)],
              badge: '대표',
            ),
          ),
        );
        final badge = find.byKey(const ValueKey('attachment-badge'));
        expect(badge, findsOneWidget, reason: '첫 사진 하나에만');
        final k = SpecCheck(mode, want, 'badge');
        k.px('badge.height', tester.getSize(badge).height);
        final deco =
            tester.widget<DecoratedBox>(badge).decoration as BoxDecoration;
        _expectRgba(k, 'badge.background', deco.color!, mode);
        final r = deco.borderRadius! as BorderRadius;
        expect(r.topLeft, Radius.zero);
        expect(r.bottomLeft.x, 12);
        expect(r.bottomRight.x, 12);
        final text = tester.widget<Text>(
          find.descendant(of: badge, matching: find.byType(Text)),
        );
        k.typo('badge.typography', text.style!);
        k.weight('badge.fontWeight', text.style!);
        k.color('badge.foreground', text.style!.color!);
        expect(text.data, want['badge.label']);
        k.px('badge.paddingX', 4);
        expect(
          tester.getBottomLeft(badge).dy,
          tester
              .getBottomLeft(
                find.descendant(
                  of: find.byKey(const ValueKey('attachment-item-p1')),
                  matching: _body,
                ),
              )
              .dy,
        );
        expect(k.failures, isEmpty, reason: k.failures.join('\n'));
      });

      testWidgets('파일 선택 버튼 — large · 칸 폭 · 앞 아이콘 upload(드롭존 없이)', (
        tester,
      ) async {
        final want = spec.resolve({
          'layout': 'dropzone',
          'screen': 'narrow',
        }, 'enabled');
        await tester.pumpWidget(
          _host(
            mode,
            _input(
              layout: PAttachmentLayout.dropzone,
              maxFiles: 1,
              accept: '.csv',
            ),
          ),
        );
        final pick = find.byKey(const ValueKey('attachment-pick'));
        final button = tester.widget<PButton>(pick);
        expect(button.size, PButtonSize.large);
        expect(button.variant, PButtonVariant.neutralWeak);
        expect(button.prefixIcon, LucideIcons.upload);
        expect(button.label, want['pickButton.label']);
        expect(tester.getSize(pick).width, 342, reason: '칸 폭');
        expect(want['pickButton.width'], '칸 폭');
        // 가득 차면 막힌다
        await tester.pumpWidget(
          _host(
            mode,
            _input(
              layout: PAttachmentLayout.dropzone,
              maxFiles: 1,
              accept: '.csv',
              entries: [_entry('a', image: false, name: 'a.csv')],
            ),
          ),
        );
        expect(tester.widget<PButton>(pick).onPressed, isNull);
      });
    });
  }

  group('이름 줄바꿈 — 글자 단위 · 네 줄 · 확장자는 남긴다', () {
    final style = PTypography.t2.copyWith(fontWeight: FontWeight.w500);
    List<String> lines(String n) => attachmentNameLines(n, style: style);

    test('짧은 이름은 그대로', () {
      expect(lines('가.pdf'), ['가.pdf']);
    });

    test('띄어쓰기 없이 이어진 이름도 글자 단위로 나뉜다(첫 줄은 66, 나머지 70)', () {
      // 시험용 글꼴(Ahem)은 글자마다 12 — 첫 줄 5자 · 나머지 5자
      final out = lines('abcdefghijklmnopqr');
      expect(out, ['abcde', 'fghij', 'klmno', 'pqr']);
      for (var i = 0; i < out.length; i++) {
        final p = TextPainter(
          text: TextSpan(text: out[i], style: style),
          textDirection: TextDirection.ltr,
        )..layout();
        expect(p.width, lessThanOrEqualTo(i == 0 ? 66 : 70), reason: '$i 줄');
      }
    });

    test('네 줄을 넘으면 셋째 줄 끝을 "…" 로 줄이고 넷째 줄에 확장자를 남긴다', () {
      final out = lines('2026년_9월_카드_이용대금_명세서_최종_수정본_v3(사본)_두번째_보내는_파일.xlsx');
      expect(out.length, 4);
      expect(out[2].endsWith('…'), isTrue);
      expect(out[3], '.xlsx');
    });

    test('확장자가 없으면 넷째 줄 끝을 줄인다', () {
      final out = lines('가'.padRight(80, '나'));
      expect(out.length, 4);
      expect(out.last.endsWith('…'), isTrue);
    });
  });

  group('고르기 · 다시 검사', () {
    testWidgets('받는 형식에 사진과 파일이 있으면 메뉴 시트 — 사진 찍기 · 앨범에서 고르기 · 파일 고르기', (
      tester,
    ) async {
      PAttachmentSource? asked;
      List<PAttachmentEntry>? accepted;
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _input(
            onAccept: (a) => accepted = a,
            pick: (s, limit) async {
              asked = s;
              return const [
                PAttachmentPicked(
                  name: '사진.jpg',
                  size: 1000,
                  type: 'image/jpeg',
                ),
              ];
            },
          ),
        ),
      );
      await tester.tap(_trigger);
      await tester.pumpAndSettle();
      expect(_label('사진 찍기'), findsOneWidget);
      expect(_label('앨범에서 고르기'), findsOneWidget);
      expect(_label('파일 고르기'), findsOneWidget);
      await tester.tap(_label('앨범에서 고르기'));
      await tester.pumpAndSettle();
      expect(asked, PAttachmentSource.gallery);
      expect(accepted!.single.name, '사진.jpg');
      expect(accepted!.single.status, PAttachmentStatus.pending);
    });

    testWidgets('받는 형식에 없는 줄은 뺀다 — 사진만이면 파일 고르기가 없고, 파일만이면 시트 없이 바로', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(Brightness.light, _input(accept: 'image/*')),
      );
      await tester.tap(_trigger);
      await tester.pumpAndSettle();
      expect(_label('사진 찍기'), findsOneWidget);
      expect(_label('파일 고르기'), findsNothing);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      PAttachmentSource? asked;
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _input(
            accept: '.csv,.xlsx',
            pick: (s, l) async {
              asked = s;
              return const [];
            },
          ),
        ),
      );
      await tester.tap(_trigger);
      await tester.pumpAndSettle();
      expect(asked, PAttachmentSource.files);
      expect(_label('파일 고르기'), findsNothing);
    });

    test('attachmentSources — accept 별 길', () {
      expect(attachmentSources(null).length, 3);
      expect(attachmentSources('image/*'), [
        PAttachmentSource.camera,
        PAttachmentSource.gallery,
      ]);
      expect(attachmentSources('application/pdf'), [PAttachmentSource.files]);
      expect(attachmentSources('image/*,application/pdf').length, 3);
    });

    testWidgets('형식 · 크기 · 개수를 다시 검사한다 — 통과가 먼저, 거절은 모아서 뒤에, 남은 자리만큼은 붙인다', (
      tester,
    ) async {
      final order = <String>[];
      List<PAttachmentEntry>? accepted;
      List<PAttachmentRejection>? rejected;
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _input(
            entries: [_entry('a'), _entry('b')],
            maxFiles: 4,
            maxFileSize: 5 * _mb,
            onAccept: (a) {
              order.add('accept');
              accepted = a;
            },
            onReject: (r) {
              order.add('reject');
              rejected = r;
            },
            pick: (s, l) async => [
              const PAttachmentPicked(
                name: '하나.jpg',
                size: 1000,
                type: 'image/jpeg',
              ),
              PAttachmentPicked(
                name: '큰사진.jpg',
                size: 12 * _mb,
                type: 'image/jpeg',
              ),
              const PAttachmentPicked(
                name: '메모.txt',
                size: 10,
                type: 'text/plain',
              ),
              const PAttachmentPicked(
                name: '둘.pdf',
                size: 1000,
                type: 'application/pdf',
              ),
              const PAttachmentPicked(
                name: '셋.png',
                size: 1000,
                type: 'image/png',
              ),
            ],
          ),
        ),
      );
      await tester.tap(_trigger);
      await tester.pumpAndSettle();
      await tester.tap(_label('파일 고르기'));
      await tester.pumpAndSettle();
      expect(order, ['accept', 'reject']);
      expect(accepted!.map((e) => e.name), ['하나.jpg', '둘.pdf']);
      final codes = {for (final r in rejected!) r.file.name: r.codes};
      expect(codes['큰사진.jpg'], [PAttachmentRejectionCode.fileTooLarge]);
      expect(codes['메모.txt'], [PAttachmentRejectionCode.invalidType]);
      expect(codes['셋.png'], [PAttachmentRejectionCode.tooManyFiles]);
    });

    test('formatFileSize — B · KB · MB(소수 한 자리)', () {
      expect(formatFileSize(512), '512B');
      expect(formatFileSize(84 * 1024), '84KB');
      expect(formatFileSize(9 * _mb + 800 * 1024), '9.8MB');
    });

    testWidgets('다 차면 타일이 막힌다 — 눌러도 아무 일이 없고 초점은 남는다', (tester) async {
      var picks = 0;
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _input(
            entries: [_entry('a')],
            maxFiles: 1,
            pick: (s, l) async {
              picks++;
              return const [];
            },
          ),
        ),
      );
      await tester.tap(_trigger);
      await tester.pumpAndSettle();
      expect(picks, 0);
      expect(_label('사진 찍기'), findsNothing);
      final s = tester.getSemantics(_trigger);
      expect(s.label, '영수증 첨부, 1/1');
      expect(s.flagsCollection.isEnabled, ui.Tristate.isFalse);
      expect(s.flagsCollection.isFocused, isNot(ui.Tristate.none));
      handle.dispose();
    });

    testWidgets('막힘은 타일이 초점에서도 빠진다 · 읽기 전용은 새로 고르지 못한다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(Brightness.light, _input(disabled: true, entries: [_entry('a')])),
      );
      expect(
        tester.getSemantics(_trigger).flagsCollection.isFocused,
        ui.Tristate.none,
      );
      await tester.pumpWidget(
        _host(Brightness.light, _input(readOnly: true, entries: [_entry('a')])),
      );
      await tester.tap(_trigger);
      await tester.pumpAndSettle();
      expect(_label('사진 찍기'), findsNothing);
      handle.dispose();
    });

    testWidgets('최대 없음이면 개수를 그리지 않고 타일 이름도 "첨부" 만이다', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _input(maxFiles: PAttachmentInput.unlimited, accept: '.csv'),
        ),
      );
      expect(
        find.descendant(of: _trigger, matching: find.byType(Text)),
        findsNothing,
      );
      expect(tester.getSemantics(_trigger).label, '영수증 첨부');
      final icon = tester.widget<Icon>(
        find.descendant(of: _trigger, matching: find.byType(Icon)),
      );
      expect(icon.icon, LucideIcons.paperclip, reason: '파일만 받으면 paperclip');
      handle.dispose();
    });
  });

  group('올리는 중 · 실패', () {
    testWidgets('진행이 10초 멈추면 실패로 보이고, 진행이 바뀌면 다시 센다', (tester) async {
      Widget build(double p) => _host(
        Brightness.light,
        _input(
          entries: [
            _entry('a', status: PAttachmentStatus.uploading, progress: p),
          ],
          onRetry: (_) {},
        ),
      );
      await tester.pumpWidget(build(0.3));
      expect(_retry, findsNothing);
      await tester.pump(const Duration(seconds: 9));
      expect(_retry, findsNothing);
      await tester.pumpWidget(build(0.5)); // 진행이 바뀌었다 — 다시 센다
      await tester.pump(const Duration(seconds: 9));
      expect(_retry, findsNothing);
      await tester.pump(const Duration(seconds: 2));
      expect(_retry, findsOneWidget);
    });

    testWidgets('값 없는 원은 멈췄다고 보지 않는다', (tester) async {
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _input(entries: [_entry('a', status: PAttachmentStatus.uploading)]),
        ),
      );
      await tester.pump(const Duration(seconds: 30));
      expect(_retry, findsNothing);
      final circle = tester.widget<PProgressCircle>(
        find.byType(PProgressCircle),
      );
      expect(circle.value, isNull);
    });

    testWidgets('다시 시도 — 덮개 전체가 단추다(onRetry)', (tester) async {
      final retried = <String>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _input(
            entries: [
              _entry('a', status: PAttachmentStatus.error),
              _entry('f', image: false, status: PAttachmentStatus.error),
            ],
            onRetry: retried.add,
          ),
        ),
      );
      await tester.tapAt(
        tester.getCenter(_retry.first) + const Offset(-20, 20),
      );
      await tester.pump();
      expect(retried, ['a']);
      await tester.tap(_retry.last);
      await tester.pump();
      expect(retried, ['a', 'f']);
    });
  });

  group('지우기', () {
    testWidgets('× 는 묻지 않고 지운다(onRemove)', (tester) async {
      final removed = <String>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _input(entries: [_entry('a'), _entry('b')], onRemove: removed.add),
        ),
      );
      await tester.tap(_remove.first);
      await tester.pump();
      expect(removed, ['a']);
    });

    testWidgets('× 의 누르는 자리 44 — 보이는 원 밖 12 에서도 눌린다(위 · 오른쪽)', (tester) async {
      final removed = <String>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _input(entries: [_entry('a')], onRemove: removed.add),
        ),
      );
      final body = tester.getRect(_body);
      // 원의 가운데에서 위로 11 · 오른쪽으로 11(원 반지름 10 밖)
      final center = Offset(body.right - 6, body.top + 6 - 4 + 4);
      await tester.tapAt(center + const Offset(11, -11));
      await tester.pump();
      expect(removed, ['a'], reason: '원 밖 위 · 오른쪽 11');
    });

    testWidgets('읽기 전용 · 막힘이면 × 가 막힌다', (tester) async {
      final removed = <String>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _input(entries: [_entry('a')], readOnly: true, onRemove: removed.add),
        ),
      );
      await tester.tap(_remove);
      await tester.pump();
      expect(removed, isEmpty);
    });

    testWidgets('지운 뒤 초점은 다음 항목의 × → 앞 항목의 × → 첨부 타일', (tester) async {
      final list = [_entry('a'), _entry('b'), _entry('c')];
      late StateSetter set;
      var entries = list;
      await tester.pumpWidget(
        _host(
          Brightness.light,
          StatefulBuilder(
            builder: (context, setState) {
              set = setState;
              return _input(
                entries: entries,
                onRemove: (id) => setState(
                  () => entries = entries.where((e) => e.id != id).toList(),
                ),
              );
            },
          ),
        ),
      );
      // 가운데 × 를 지우면 다음(c)의 ×
      await tester.tap(_remove.at(1));
      await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'remove-c');
      // 마지막 × 를 지우면 앞(a)의 ×
      await tester.tap(_remove.at(1));
      await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'remove-a');
      await tester.tap(_remove.at(0));
      await tester.pumpAndSettle();
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'attachment-trigger',
      );
      set(() {});
    });
  });

  group('항목 메뉴 · 순서 바꾸기', () {
    Widget app(
      List<PAttachmentEntry> entries,
      void Function(List<PAttachmentEntry>) onReorder, {
      String? badge = '대표',
      ValueChanged<String>? onPreview,
      ValueChanged<String>? onRemove,
    }) => _host(
      Brightness.light,
      _input(
        entries: entries,
        badge: badge,
        onReorder: onReorder,
        onPreview: onPreview,
        onRemove: onRemove,
      ),
    );

    testWidgets(
      '항목을 누르면 Menu Sheet(머리 = 전체 파일 이름) — 크게 보기 · 대표로 정하기 · 앞으로 · 뒤로 옮기기 | 지우기',
      (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          app(
            [
              _entry('a'),
              _entry('b', name: '둘째_사진_아주_긴_이름이_이어지는_파일.jpg'),
              _entry('c'),
            ],
            (_) {},
            onPreview: (_) {},
          ),
        );
        await tester.tap(find.byKey(const ValueKey('attachment-item-b')));
        await tester.pumpAndSettle();
        expect(
          find.bySemanticsLabel(RegExp('둘째_사진_아주_긴_이름이_이어지는_파일.jpg')),
          findsWidgets,
        );
        for (final line in ['크게 보기', '대표로 정하기', '앞으로 옮기기', '뒤로 옮기기', '지우기']) {
          expect(_label(line), findsOneWidget, reason: line);
        }
        handle.dispose();
      },
    );

    testWidgets('파일 카드는 "열기" · 대표 줄이 없다(사진만)', (tester) async {
      await tester.pumpWidget(
        app(
          [_entry('a'), _entry('f', image: false)],
          (_) {},
          onPreview: (_) {},
        ),
      );
      await tester.tap(find.byKey(const ValueKey('attachment-item-f')));
      await tester.pumpAndSettle();
      expect(_label('열기'), findsOneWidget);
      expect(_label('크게 보기'), findsNothing);
      expect(_label('대표로 정하기'), findsNothing);
      expect(_label('앞으로 옮기기'), findsOneWidget);
    });

    testWidgets('badgeLabel 을 안 쓰면 대표로 정하기를 뺀다 · 크게 보기는 onPreview 가 있을 때만', (
      tester,
    ) async {
      await tester.pumpWidget(
        app([_entry('a'), _entry('b')], (_) {}, badge: null),
      );
      await tester.tap(find.byKey(const ValueKey('attachment-item-b')));
      await tester.pumpAndSettle();
      expect(_label('대표로 정하기'), findsNothing);
      expect(_label('크게 보기'), findsNothing);
      expect(_label('앞으로 옮기기'), findsOneWidget);
    });

    testWidgets('앞으로 · 뒤로 옮기기는 한 칸씩 · 대표로 정하기는 맨 앞으로, 옮긴 뒤 초점은 새 자리의 항목', (
      tester,
    ) async {
      var entries = [_entry('a'), _entry('b'), _entry('c')];
      final calls = <List<String>>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          StatefulBuilder(
            builder: (context, setState) => _input(
              entries: entries,
              badge: '대표',
              onReorder: (next) {
                calls.add([for (final e in next) e.id]);
                setState(() => entries = next);
              },
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('attachment-item-b')));
      await tester.pumpAndSettle();
      await tester.tap(_label('뒤로 옮기기'));
      await tester.pumpAndSettle();
      expect(calls.last, ['a', 'c', 'b']);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'item-b');

      await tester.tap(find.byKey(const ValueKey('attachment-item-b')));
      await tester.pumpAndSettle();
      await tester.tap(_label('대표로 정하기'));
      await tester.pumpAndSettle();
      expect(calls.last, ['b', 'a', 'c']);
      // 대표 띠는 새 첫 사진으로 옮겨 간다
      final badge = find.byKey(const ValueKey('attachment-badge'));
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('attachment-item-b')),
          matching: badge,
        ),
        findsOneWidget,
      );
    });

    testWidgets('끝에 닿으면 그 방향 줄이 막힌다 — 맨 앞은 앞으로 · 대표, 맨 끝은 뒤로', (tester) async {
      final calls = <List<String>>[];
      await tester.pumpWidget(
        app([
          _entry('a'),
          _entry('b'),
        ], (next) => calls.add([for (final e in next) e.id])),
      );
      await tester.tap(find.byKey(const ValueKey('attachment-item-a')));
      await tester.pumpAndSettle();
      await tester.tap(_label('앞으로 옮기기'));
      await tester.pumpAndSettle();
      expect(calls, isEmpty, reason: '막힌 줄은 실행하지 않는다');
      expect(_label('앞으로 옮기기'), findsOneWidget, reason: '시트도 닫히지 않는다');
      await tester.tap(_label('대표로 정하기'));
      await tester.pumpAndSettle();
      expect(calls, isEmpty);
      await tester.tap(_label('뒤로 옮기기'));
      await tester.pumpAndSettle();
      expect(calls.single, ['b', 'a']);

      calls.clear();
      await tester.pumpWidget(
        app([
          _entry('a'),
          _entry('b'),
        ], (next) => calls.add([for (final e in next) e.id])),
      );
      await tester.tap(find.byKey(const ValueKey('attachment-item-b')));
      await tester.pumpAndSettle();
      await tester.tap(_label('뒤로 옮기기'));
      await tester.pumpAndSettle();
      expect(calls, isEmpty);
    });

    testWidgets('지우기는 위험 묶음 — 묻지 않고 지운다', (tester) async {
      final removed = <String>[];
      await tester.pumpWidget(
        app([_entry('a'), _entry('b')], (_) {}, onRemove: removed.add),
      );
      await tester.tap(find.byKey(const ValueKey('attachment-item-b')));
      await tester.pumpAndSettle();
      await tester.tap(_label('지우기'));
      await tester.pumpAndSettle();
      expect(removed, ['b']);
    });

    testWidgets('크게 보기는 onPreview', (tester) async {
      final seen = <String>[];
      await tester.pumpWidget(app([_entry('a')], (_) {}, onPreview: seen.add));
      await tester.tap(find.byKey(const ValueKey('attachment-item-a')));
      await tester.pumpAndSettle();
      await tester.tap(_label('크게 보기'));
      await tester.pumpAndSettle();
      expect(seen, ['a']);
    });

    testWidgets('읽기 전용이면 메뉴 없이 바로 크게 보기 · onReorder 도 열리지 않는다', (tester) async {
      final seen = <String>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _input(
            entries: [_entry('a')],
            readOnly: true,
            onReorder: (_) {},
            onPreview: seen.add,
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('attachment-item-a')));
      await tester.pumpAndSettle();
      expect(seen, ['a']);
      expect(_label('앞으로 옮기기'), findsNothing);
    });

    testWidgets('onReorder · onPreview 가 없으면 항목은 눌리지 않는다(메뉴가 없다)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(Brightness.light, _input(entries: [_entry('a')])),
      );
      await tester.tap(find.byKey(const ValueKey('attachment-item-a')));
      await tester.pumpAndSettle();
      expect(_label('지우기'), findsNothing);
    });

    testWidgets('실패한 항목은 누르면 메뉴가 아니라 다시 시도다', (tester) async {
      final retried = <String>[];
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _input(
            entries: [_entry('a', status: PAttachmentStatus.error)],
            onReorder: (_) {},
            onRetry: retried.add,
          ),
        ),
      );
      await tester.tap(_retry);
      await tester.pumpAndSettle();
      expect(retried, ['a']);
      expect(_label('앞으로 옮기기'), findsNothing);
    });

    testWidgets('항목에 앞으로 · 뒤로 옮기기 접근성 동작이 있다(끝에서는 그 방향이 없다)', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        app([_entry('a'), _entry('b'), _entry('c')], (_) {}),
      );
      Set<String> actions(String id) {
        final node = tester.getSemantics(
          find.descendant(
            of: find.byKey(ValueKey('attachment-item-$id')),
            matching: _body,
          ),
        );
        final data = node.getSemanticsData();
        return {
          for (final k in (data.customSemanticsActionIds ?? const <int>[]))
            ?CustomSemanticsAction.getAction(k)?.label,
        };
      }

      expect(actions('b'), {'앞으로 옮기기', '뒤로 옮기기', '지우기'});
      expect(actions('a'), {'뒤로 옮기기', '지우기'});
      expect(actions('c'), {'앞으로 옮기기', '지우기'});
      handle.dispose();
    });
  });

  group('길게 눌러 끌기 · × 먼저 · 위 16(Q-016)', () {
    Widget reorderable(
      List<PAttachmentEntry> entries,
      ValueChanged<List<PAttachmentEntry>> onReorder, {
      ValueChanged<String>? onRemove,
      ValueChanged<String>? onPreview,
      bool? readOnly,
      String? badge,
    }) => _host(
      Brightness.light,
      _input(
        entries: entries,
        onReorder: onReorder,
        onRemove: onRemove,
        onPreview: onPreview,
        readOnly: readOnly,
        badge: badge,
      ),
    );

    final ghost = find.byKey(const ValueKey('attachment-drag-ghost'));

    testWidgets(
      '250ms 길게 누르면 끌기 — 2px 줄어든 채 손가락을 따라가고(사진 불투명도 0.5 · × 와 구멍 없음), 놓은 자리로 옮긴다',
      (tester) async {
        final calls = <List<String>>[];
        await tester.pumpWidget(
          reorderable(
            [_entry('a'), _entry('b'), _entry('c')],
            (next) => calls.add([for (final e in next) e.id]),
            badge: '대표',
          ),
        );
        final a = tester.getRect(
          find.descendant(
            of: find.byKey(const ValueKey('attachment-item-a')),
            matching: _body,
          ),
        );
        final c = tester.getRect(
          find.descendant(
            of: find.byKey(const ValueKey('attachment-item-c')),
            matching: _body,
          ),
        );
        final finger = await tester.startGesture(a.center);
        // 문턱 전에는 끌기가 아니다
        await tester.pump(const Duration(milliseconds: 200));
        expect(ghost, findsNothing);
        await tester.pump(const Duration(milliseconds: 100));
        expect(ghost, findsOneWidget, reason: '250ms 지나면 끌기');
        // 모습 — 2px 줄어듦(78 / 80) · 사진 불투명도 0.5 · × 없음
        final scale = tester.widget<Transform>(ghost);
        expect(scale.transform.storage[0], closeTo(78 / 80, 1e-6));
        expect(
          find.descendant(of: ghost, matching: find.byType(Opacity)),
          findsOneWidget,
        );
        expect(
          tester
              .widget<Opacity>(
                find.descendant(of: ghost, matching: find.byType(Opacity)),
              )
              .opacity,
          0.5,
        );
        expect(find.descendant(of: ghost, matching: _remove), findsNothing);
        // 손가락을 따라간다
        await finger.moveTo(a.center + const Offset(60, 0));
        await tester.pump();
        expect(
          tester.getRect(ghost).center.dx,
          closeTo(a.center.dx + 60, 1),
          reason: '손가락 가로를 따라간다',
        );
        await finger.moveTo(c.center);
        await tester.pump();
        // 이웃이 비켜서 있다 — 끄는 항목의 자리가 마지막으로
        await finger.up();
        await tester.pump();
        expect(ghost, findsNothing);
        expect(calls, [
          ['b', 'c', 'a'],
        ]);
      },
    );

    testWidgets('문턱 전에 움직이면 끌기가 아니다 — 그냥 떼면 누르기(메뉴)', (tester) async {
      final calls = <List<String>>[];
      await tester.pumpWidget(
        reorderable([_entry('a'), _entry('b')], (next) => calls.add([])),
      );
      final a = tester.getCenter(
        find.descendant(
          of: find.byKey(const ValueKey('attachment-item-a')),
          matching: _body,
        ),
      );
      final quick = await tester.startGesture(a);
      await tester.pump(const Duration(milliseconds: 100));
      await quick.up();
      await tester.pumpAndSettle();
      expect(ghost, findsNothing);
      expect(calls, isEmpty);
      expect(_label('뒤로 옮기기'), findsOneWidget, reason: '메뉴 시트가 열렸다');
      // 같은 자리에 두면 순서는 그대로
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      final held = await tester.startGesture(a);
      await tester.pump(const Duration(milliseconds: 300));
      expect(ghost, findsOneWidget);
      await held.up();
      await tester.pump();
      expect(calls, isEmpty, reason: '제자리에 놓으면 바뀌지 않는다');
    });

    testWidgets('읽기 전용 · onReorder 없음이면 끌리지 않는다', (tester) async {
      await tester.pumpWidget(
        reorderable([_entry('a'), _entry('b')], (_) {}, readOnly: true),
      );
      final a = tester.getCenter(
        find.descendant(
          of: find.byKey(const ValueKey('attachment-item-a')),
          matching: _body,
        ),
      );
      final g = await tester.startGesture(a);
      await tester.pump(const Duration(milliseconds: 400));
      expect(ghost, findsNothing);
      await g.up();
      await tester.pumpWidget(
        _host(Brightness.light, _input(entries: [_entry('a'), _entry('b')])),
      );
      final h = await tester.startGesture(a);
      await tester.pump(const Duration(milliseconds: 400));
      expect(ghost, findsNothing);
      await h.up();
    });

    testWidgets('이웃과 겹친 8 × 28 에서는 × 가 먼저 받는다 — 옆 사진 메뉴가 열리지 않는다', (
      tester,
    ) async {
      final removed = <String>[];
      await tester.pumpWidget(
        reorderable([_entry('a'), _entry('b')], (_) {}, onRemove: removed.add),
      );
      final a = tester.getRect(
        find.descendant(
          of: find.byKey(const ValueKey('attachment-item-a')),
          matching: _body,
        ),
      );
      final b = tester.getRect(
        find.descendant(
          of: find.byKey(const ValueKey('attachment-item-b')),
          matching: _body,
        ),
      );
      expect(b.left - a.right, 8, reason: '항목 사이 8');
      // a 의 × 가운데는 a 오른쪽 위 모서리 안쪽 6 — 누르는 44 는 오른쪽으로 16 나가 b 의 왼쪽 8 위로 겹친다
      final overlap = Offset(b.left + 4, b.top + 14);
      expect(b.contains(overlap), isTrue, reason: 'b 사진 위의 점');
      await tester.tapAt(overlap);
      await tester.pumpAndSettle();
      expect(removed, ['a'], reason: '× 가 먼저 받는다');
      expect(_label('뒤로 옮기기'), findsNothing, reason: 'b 의 메뉴는 열리지 않는다');
      // 겹침 밖(b 의 안쪽)은 b 가 받는다
      await tester.tapAt(Offset(b.left + 30, b.top + 40));
      await tester.pumpAndSettle();
      expect(removed, ['a']);
      expect(_label('앞으로 옮기기'), findsOneWidget, reason: 'b 의 메뉴');
    });

    testWidgets('칸이 맨 위여도(라벨 없음) × 의 위 16 이 잘리지 않는다', (tester) async {
      final removed = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: GrooTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 342,
                child: _input(entries: [_entry('a')], onRemove: removed.add),
              ),
            ),
          ),
        ),
      );
      final body = tester.getRect(_body);
      // × 가운데(오른쪽 위 모서리 안쪽 6)에서 위로 11 — 보이는 원 밖 · 누르는 44 안
      final point = Offset(body.right - 6, body.top + 6 - 11);
      expect(point.dy, greaterThan(0), reason: '화면 안에 남는다');
      await tester.tapAt(point);
      await tester.pump();
      expect(removed, ['a']);
    });

    testWidgets(
      'Field(edgeInset 24) 안 — 입력은 화면 폭 그대로, 머리 · 꼬리만 24 들어오고 줄 안쪽 여백이 24 다(bleed)',
      (tester) async {
        await tester.pumpWidget(
          _host(
            Brightness.light,
            PField(
              label: '영수증',
              description: '사진 · PDF 를 10MB 까지 올려요.',
              edgeInset: 24,
              child: _input(entries: [_entry('a')]),
            ),
            width: 360,
          ),
        );
        final field = tester.getRect(find.byType(PField));
        // 입력(줄)은 Field 폭 전체
        expect(
          tester.getSize(find.byType(SingleChildScrollView)).width,
          field.width,
        );
        // 첫 타일은 다른 칸과 같은 자리(24)에서 시작한다
        expect(tester.getRect(_trigger).left - field.left, 24);
        // 머리 · 꼬리는 24 들어온 자리(2 + 24)
        final label = tester.getRect(
          find
              .byWidgetPredicate(
                (w) =>
                    w is RichText &&
                    plainOf(w.text.toPlainText()).startsWith('영수증'),
              )
              .first,
        );
        expect(label.left - field.left, 26);
        final description = tester.getRect(
          findText(keepAll('사진 · PDF 를 10MB 까지 올려요.')),
        );
        expect(description.left - field.left, 26);
      },
    );
  });

  group('접근성', () {
    testWidgets('항목 이름은 전체 파일 이름 + 크기 + 상태 · × · 다시 시도 이름 · 타일 이름', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Brightness.light,
          _input(
            entries: [
              _entry(
                'a',
                name: '아주_긴_파일_이름_전체가_읽혀야_한다.pdf',
                image: false,
                status: PAttachmentStatus.error,
              ),
              _entry(
                'b',
                status: PAttachmentStatus.uploading,
                progress: 0.4,
                name: '사진.jpg',
              ),
            ],
            onRetry: (_) {},
            badge: '대표',
          ),
        ),
      );
      expect(
        find.bySemanticsLabel('아주_긴_파일_이름_전체가_읽혀야_한다.pdf, 9.8MB, 올리지 못했어요'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('사진.jpg, 2.0MB, 대표, 올리는 중 40%'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('아주_긴_파일_이름_전체가_읽혀야_한다.pdf 지우기'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('아주_긴_파일_이름_전체가_읽혀야_한다.pdf 다시 시도'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('영수증 첨부, 2/10'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('붙음 · 올림 · 실패를 한 번씩 읽는다(polite)', (tester) async {
      final handle = tester.ensureSemantics();
      var entries = <PAttachmentEntry>[];
      late StateSetter set;
      await tester.pumpWidget(
        _host(
          Brightness.light,
          StatefulBuilder(
            builder: (context, setState) {
              set = setState;
              return _input(entries: entries);
            },
          ),
        ),
      );
      String live() {
        final nodes = find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.liveRegion == true &&
              (w.properties.label ?? '').isNotEmpty,
        );
        return tester.widget<Semantics>(nodes.first).properties.label!;
      }

      set(
        () => entries = [
          _entry('a', status: PAttachmentStatus.uploading, progress: 0.2),
          _entry('b'),
        ],
      );
      await tester.pump();
      expect(live().trim(), '사진 2장을 붙였어요.');
      set(
        () => entries = [
          entries[0].copyWith(status: PAttachmentStatus.success),
          entries[1],
        ],
      );
      await tester.pump();
      expect(live().trim(), '1개를 올렸어요.');
      set(
        () => entries = [
          entries[0],
          entries[1].copyWith(status: PAttachmentStatus.error),
        ],
      );
      await tester.pump();
      expect(live().trim(), '1개는 올리지 못했어요.');
      handle.dispose();
    });

    testWidgets('Field 안이면 라벨이 칸 이름 · 설명 · 오류가 묶음 설명 · 막힘 · 읽기 전용을 받는다', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Brightness.light,
          PField(
            label: '영수증',
            description: '사진 · PDF 를 10MB 까지 올려요.',
            readOnly: true,
            child: PAttachmentInput(
              entries: [_entry('a')],
              maxFiles: 10,
              pickFiles: (s, l) async => const [],
              onFilesAccept: (_) {},
              onRemove: (_) {},
            ),
          ),
        ),
      );
      expect(find.bySemanticsLabel('영수증 첨부, 1/10'), findsOneWidget);
      // 읽기 전용을 받아 사진이 흐리다
      expect(
        tester
            .widget<AnimatedOpacity>(
              find.descendant(
                of: find.byKey(const ValueKey('attachment-item-a')),
                matching: find.byType(AnimatedOpacity),
              ),
            )
            .opacity,
        0.5,
      );
      handle.dispose();
    });
  });

  group('가장 나쁜 값 — 폭 360 · 20개 · 다크', () {
    testWidgets('파일 20개 · 긴 이름이 넘치지 않고 줄이 가로로 스크롤한다', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final entries = [
        for (var i = 0; i < 20; i++)
          _entry(
            'e$i',
            image: i.isEven,
            name: i.isEven
                ? '사진_$i.jpg'
                : '2026년_9월_카드_이용대금_명세서_최종_수정본_v${i}_사본.pdf',
          ),
      ];
      await tester.pumpWidget(
        _host(
          Brightness.dark,
          _input(entries: entries, maxFiles: 20),
          width: 312,
        ),
      );
      expect(tester.takeException(), isNull);
      final scroll = find.byType(SingleChildScrollView);
      await tester.drag(scroll, const Offset(-2000, 0));
      await tester.pump();
      expect(tester.takeException(), isNull);
      // 파일 카드의 이름은 네 줄 안에서 끝난다
      final lines = find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey &&
            '${(w.key! as ValueKey).value}'.startsWith('attachment-name-line-'),
      );
      expect(lines, findsWidgets);
    });
  });

  group('큰 글자 — 상자도 글자 배율을 따른다(03-B 결정 3 A)', () {
    Widget scaled(double factor, Widget child) => MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(factor)),
      child: child,
    );

    testWidgets(
      '200% 에서 타일 · 사진 160, 파일 카드 320 × 160, 썸네일 96, × 40(누르는 88), 아이콘 48',
      (tester) async {
        tester.view.physicalSize = const Size(900, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        for (final factor in [1.0, 2.0]) {
          await tester.pumpWidget(
            scaled(
              factor,
              _host(
                Brightness.light,
                _input(
                  entries: [_entry('p'), _entry('f', image: false)],
                  onRemove: (_) {},
                ),
                width: 800,
              ),
            ),
          );
          expect(tester.takeException(), isNull, reason: 'x$factor 넘침');
          expect(
            tester.getSize(_trigger),
            Size.square(80 * factor),
            reason: 'x$factor 타일',
          );
          final bodies = tester.widgetList(_body).length;
          expect(bodies, 2);
          expect(
            tester.getSize(_body.at(0)),
            Size.square(80 * factor),
            reason: 'x$factor 사진',
          );
          expect(
            tester.getSize(_body.at(1)),
            Size(160 * factor, 80 * factor),
            reason: 'x$factor 파일 카드',
          );
          expect(
            tester.getSize(find.byKey(const ValueKey('attachment-thumbnail'))),
            Size.square(48 * factor),
            reason: 'x$factor 썸네일',
          );
          // × — 누르는 자리 44, 보이는 원 20
          expect(
            tester.getSize(_remove.first),
            Size.square(44 * factor),
            reason: 'x$factor × 누르는 자리',
          );
          final circle = find
              .ancestor(
                of: find.descendant(
                  of: _remove.first,
                  matching: find.byType(Icon),
                ),
                matching: find.byType(SizedBox),
              )
              .first;
          expect(
            tester.getSize(circle),
            Size.square(20 * factor),
            reason: 'x$factor × 원',
          );
          // 아이콘 24 · × 아이콘 10
          final triggerIcon = tester.widget<Icon>(
            find.descendant(of: _trigger, matching: find.byType(Icon)),
          );
          expect(triggerIcon.size, 24 * factor);
          final xIcon = tester.widget<Icon>(
            find.descendant(of: _remove.first, matching: find.byType(Icon)),
          );
          expect(xIcon.size, 10 * factor);
        }
      },
    );

    testWidgets('200% 파일 카드 — 이름 폭이 카드를 따라 넓어져 이름 네 줄 + 크기가 모두 보인다', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        scaled(
          2,
          _host(
            Brightness.light,
            _input(
              entries: [
                _entry(
                  'f',
                  image: false,
                  name: '2026년_9월_카드_이용대금_명세서_최종_수정본_사본_프린트용.pdf',
                ),
              ],
            ),
            width: 800,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final card = tester.getRect(_body.first);
      expect(card.size, const Size(320, 160));
      final lines = find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey &&
            '${(w.key! as ValueKey).value}'.startsWith('attachment-name-line-'),
      );
      expect(lines, findsAtLeastNWidgets(1));
      expect(lines.evaluate().length, lessThanOrEqualTo(4));
      final size = tester.getRect(
        find.byKey(const ValueKey('attachment-size')),
      );
      // 크기까지 카드 안에 든다
      expect(size.bottom, lessThanOrEqualTo(card.bottom));
      for (final line in lines.evaluate()) {
        final r = tester.getRect(find.byElementPredicate((e) => e == line));
        expect(r.bottom, lessThanOrEqualTo(card.bottom));
        expect(r.right, lessThanOrEqualTo(card.right));
      }
      // 이름 폭 = 카드 − 좌우 여백 16 × 2 − 썸네일 96 − 사이 10
      final meta = tester.getSize(
        find
            .ancestor(
              of: find.byKey(const ValueKey('attachment-size')),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(meta.width, 320 - 32 - 96 - 10);
    });

    testWidgets('200% 실패한 사진 — "다시 시도" 가 잘리지 않고 × 의 누르는 자리가 배율을 따른다', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var retried = 0;
      await tester.pumpWidget(
        scaled(
          2,
          _host(
            Brightness.light,
            _input(
              entries: [_entry('p', status: PAttachmentStatus.error)],
              onRetry: (_) => retried++,
            ),
            width: 800,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final retry = tester.getRect(_retry);
      expect(retry.size, const Size.square(160));
      final label = tester.getRect(findText('다시 시도'));
      expect(label.left, greaterThanOrEqualTo(retry.left));
      expect(label.right, lessThanOrEqualTo(retry.right));
      // × 의 누르는 자리 = 44 × 2, 가운데는 오른쪽 위 모서리에서 안쪽 12
      final x = tester.getRect(_remove);
      expect(x.size, const Size.square(88));
      expect(x.center.dx, closeTo(retry.right - 12, 0.01));
      expect(x.center.dy, closeTo(retry.top + 12, 0.01));
      await tester.tapAt(retry.center);
      expect(retried, 1);
    });
  });
}
