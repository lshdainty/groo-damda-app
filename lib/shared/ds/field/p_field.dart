import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';
import 'package:groo_damda_app/shared/ds/card/p_card_parts.dart'
    show PTouchTargetScope;

/// 라벨 굵기 — 한 폼 안에서 섞지 않는다.
enum PFieldLabelWeight {
  /// 500 — 기본
  medium,

  /// 700 — 칸 이름이 그 구역의 제목 노릇을 할 때(칸 하나를 크게 받는 단계 화면)
  bold,
}

/// 라벨 뒤 표시 — 한 화면 칸의 2/3 이상이 필수면 선택 칸에만 [optional], 아니면 필수 칸에만 [required].
/// 한 폼 안에서 둘을 섞지 않고, 칸이 하나뿐이면 아무것도 붙이지 않는다(field.md › 필수 입력 표시하기).
enum PFieldIndicator {
  /// 표시 없음 — 기본
  none,

  /// 빨간 점 — 필수로 본다. 점은 읽지 않고 필수는 입력이 알린다
  required,

  /// "선택" 글 — 글은 정해져 있다
  optional,
}

/// 머리 오른쪽 보조 액션 — 칸을 채우는 데 돕는 작은 텍스트 버튼(예시 보기 · 전체 선택).
/// Field 가 Button ghost · neutralSubtle · xsmall · 오른쪽 flush 로 그린다.
@immutable
class PFieldAction {
  const PFieldAction({required this.label, required this.onPressed});

  final String label;

  /// 없으면 비활성.
  final VoidCallback? onPressed;
}

/// 입력이 Field 에서 받는 값(웹 useFieldControl) — [PFieldScope] 로 내려간다. 입력에 직접 준 값이 이긴다.
@immutable
class PFieldControlData {
  const PFieldControlData({
    this.label,
    this.message,
    this.invalid = false,
    this.required = false,
    this.disabled = false,
    this.readOnly = false,
    this.maxGraphemeCount,
    this.counterMax,
    this.edgeInset = 0,
  });

  /// 칸 이름 — 라벨(+ "선택"). 입력의 이름이 된다(웹 `<label for>`).
  final String? label;

  /// 설명 자리의 글 — 오류가 보이면 오류, 아니면 설명. 입력의 설명으로 잇는다(웹 aria-describedby).
  final String? message;

  /// 오류 — 입력의 테두리가 빨간 2px 가 되고 입력이 오류임을 알린다(aria-invalid).
  final bool invalid;

  /// 필수 — 입력이 알린다(aria-required). 점은 보이는 표시일 뿐이다.
  final bool required;
  final bool disabled;
  final bool readOnly;

  /// 최대 글자 수(자소) — 입력은 최대에서 멈춘다(한글은 조합이 끝난 뒤 자른다).
  final int? maxGraphemeCount;

  /// 세는 줄 분모 — 없으면 [maxGraphemeCount].
  final int? counterMax;

  /// 머리 · 꼬리가 입력 양옆에서 들어온 만큼 — 입력이 화면 폭을 다 쓰는 칸(첨부)이 줄 안쪽 여백으로 읽는다.
  final double edgeInset;

  @override
  bool operator ==(Object other) =>
      other is PFieldControlData &&
      other.label == label &&
      other.message == message &&
      other.invalid == invalid &&
      other.required == required &&
      other.disabled == disabled &&
      other.readOnly == readOnly &&
      other.maxGraphemeCount == maxGraphemeCount &&
      other.counterMax == counterMax &&
      other.edgeInset == edgeInset;

  @override
  int get hashCode => Object.hash(
    label,
    message,
    invalid,
    required,
    disabled,
    readOnly,
    maxGraphemeCount,
    counterMax,
    edgeInset,
  );
}

/// Field 와 입력을 잇는 자리 — 입력이 포커스 노드를 맡기고(라벨을 누르면 그리로 간다) 쓴 글자 수를 알린다.
abstract interface class PFieldLink {
  void attach(FocusNode focusNode);

  void detach(FocusNode focusNode);

  /// 지금 쓴 글자 수(자소) — 꼬리의 글자 수가 이 값을 보인다.
  void reportGraphemeCount(int count);
}

/// Field 문맥 — [PField] 가 두고 입력(PInput · PTextarea)이 읽는다.
class PFieldScope extends InheritedWidget {
  const PFieldScope({
    super.key,
    required this.data,
    required this.link,
    required super.child,
  });

  final PFieldControlData data;
  final PFieldLink link;

  static PFieldScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PFieldScope>();

  @override
  bool updateShouldNotify(PFieldScope oldWidget) =>
      data != oldWidget.data || link != oldWidget.link;
}

/// 자소(사용자가 보는 글자) 수 — 국기 · 가족 이모지도 한 글자다(웹 Intl.Segmenter 와 같은 셈).
int countGraphemes(String value) => value.characters.length;

// field.yaml 의 값 — 토큰이 있는 값은 토큰으로 적는다.
const double _gap = PSpacing.x2; // root.gap — 머리 ↔ 입력 ↔ 꼬리
const double _headerPaddingX = PSpacing.x0_5;
const double _headerGap = PSpacing.x2_5; // 라벨 ↔ 보조 액션
const double _actionMarginY = -5; // 버튼일 때 — 머리 높이 22 를 지키게 위아래로 넘친다(머리 값 글은 0)
const double _footerPaddingX = PSpacing.x0_5;
const double _footerGap = PSpacing.x2; // 설명 · 오류 ↔ 글자 수
const double _messageIconSize = 16; // descriptionIcon · errorIcon
const double _messageIconGap = PSpacing.x1_5;

// 필수 점 · "선택" — 스펙은 rem(1rem = 16)이다. 라벨 글 안(WidgetSpan)에 두면 Flutter 가 라벨 글자의 배율
// (글자 크기 설정 — textScaler.scale(16) ÷ 16)로 통째로 키운다 — 그래서 여기는 1배 값을 적는다.
const double _dotSize = 6; // 0.375rem
const double _dotMarginTop = 4; // 0.25rem — 라벨 첫 줄 위쪽에 붙는다
const double _dotMarginStart = 2; // 0.125rem — 라벨 끝 바로 뒤
const double _optionalPaddingStart = 4; // 0.25rem

/// "선택" 의 줄 높이 — 라벨(t5)과 같은 22.
const double _optionalLineHeight = 22;

/// Field — 입력 하나를 감싸는 둘레. 머리(라벨 · 필수 점 또는 "선택" · 보조 액션) · 입력 · 꼬리(설명 또는 오류 · 글자 수)를
/// 사이 8 로 쌓는다. 구조는 SEED Field(2026-10-01), 수치 원본은 groo-design `specs/components/field.yaml`(값은
/// `test/fixtures/design_spec/field.json`). 웹(desk-front `src/shared/ds/field`)과 같은 값 · 동작이다.
///
/// 입력([child] — PInput · PTextarea)은 [PFieldScope] 로 이름 · 설명 · 오류 · 필수 · 막힘 · 최대 글자 수를 받는다.
///   라벨 — 입력의 이름이 된다(보이는 라벨을 따로 읽지 않는다). 누르면 입력으로 포커스가 간다.
///   필수 점 · "선택" — 크기 · 여백이 라벨과 함께 글자 크기 설정을 따라 커진다(rem). 점은 읽지 않고 필수는 입력이
///     알린다.
///   보조 액션 — 머리 높이 22 를 바꾸지 않게 위아래로 5 넘친다. 누르는 영역은 버튼 그대로(44) — Field 밖으로 넘친
///     자리도 받는다. 다만 부모 상자 안에서만이다(Flutter 는 부모 안에서만 자식에게 묻는다 — 폼의 첫 칸이 부모 맨
///     위에 붙어 있으면 위로 넘친 자리는 받지 못한다. 폼 위에 여백을 두면 받는다).
///   오류([invalid] + [errorMessage]) — 설명 자리를 대신하고 글자 수도 빨개진다. 라벨은 그대로다. 오류가 생기거나
///     바뀌면 화면 읽기 프로그램에 한 번 알린다(polite — 알림을 지원하지 않는 플랫폼은 오류 글이 live region 이다).
///     처음부터 있던 오류는 알리지 않는다(웹 aria-live 와 같다).
///   글자 수 — [maxGraphemeCount] 가 있는 칸에만 "쓴 수/최대". 자소 단위로 세고 입력은 최대에서 멈춘다.
/// 설명 · 오류 · 글자 수는 입력의 설명으로도 읽힌다. 비활성 · 읽기 전용은 Field 에 주면 입력이 받는다.
/// 폭은 부모가 정한다(늘 꽉 채운다).
class PField extends StatefulWidget {
  const PField({
    super.key,
    this.label,
    this.labelWeight = PFieldLabelWeight.medium,
    this.required = false,
    this.indicator = PFieldIndicator.none,
    this.headerAction,
    this.headerTrailing,
    this.description,
    this.descriptionIcon,
    this.errorMessage,
    this.invalid = false,
    this.disabled = false,
    this.readOnly = false,
    this.maxGraphemeCount,
    this.counterMax,
    this.edgeInset = 0,
    required this.child,
  }) : assert(
         maxGraphemeCount == null || maxGraphemeCount > 0,
         '최대 글자 수는 1 이상',
       ),
       assert(
         headerAction == null || headerTrailing == null,
         '머리 오른쪽은 버튼(headerAction) 하나 또는 머리 값(headerTrailing) 하나다 — 함께 두지 않는다',
       );

  /// 칸 이름 — 명사형 · 마침표 없이("휴대폰 번호"). 한 줄이 좋고, 길어도 두 줄까지.
  final String? label;
  final PFieldLabelWeight labelWeight;

  /// 필수 — 입력이 알린다. 점은 [indicator] 로 따로 켠다(2/3 규칙 — 필수 칸이 많은 화면은 점 없이 이것만).
  final bool required;

  /// 라벨 뒤 표시 — 필수 점이면 필수로 본다.
  final PFieldIndicator indicator;

  /// 머리 오른쪽 보조 액션 — 작은 글 버튼 하나. [headerTrailing] 과 함께 두지 않는다.
  final PFieldAction? headerAction;

  /// 머리 오른쪽에 두는 위젯 — Slider 의 머리 값(`PSliderValue`, 줄 높이 22 라 머리를 넘치지 않는다 — 위아래 넘침 0)처럼
  /// 버튼이 아닌 것. 늘 보이는 값 글이다(눌리지 않는다). [headerAction] 과 함께 두지 않는다(field.yaml headerAction 자리).
  final Widget? headerTrailing;

  /// 설명 — 칸을 채우는 데 필요한 안내. 오류가 보이면 오류가 대신한다.
  final String? description;

  /// 설명 앞 아이콘(16).
  final IconData? descriptionIcon;

  /// 오류 글 — [invalid] 일 때 설명 자리에. 행동 지시형으로 짧게("이름을 입력해주세요.").
  final String? errorMessage;
  final bool invalid;
  final bool disabled;
  final bool readOnly;

  /// 최대 글자 수(자소) — 있으면 꼬리 오른쪽에 "쓴 수/최대" 를 보이고 입력은 최대에서 멈춘다.
  final int? maxGraphemeCount;

  /// 세는 줄 분모 — 기본 null 이면 [maxGraphemeCount] 가 분모다(지금 그대로). 값이 있으면 "쓴 수/[counterMax]" 로 보이고 쓴 수가
  /// 이를 넘으면 오류 색이다. 입력 상한은 [maxGraphemeCount] 가 따로 정한다 — 규칙(12자)보다 긴 옛 값을 고칠 때 입력이 잘려 글이
  /// 사라지지 않게 상한만 넓히고 분모는 규칙 값으로 둔다.
  final int? counterMax;

  /// 머리 · 꼬리의 좌우 안쪽 여백(기본 0) — 입력이 Field 폭을 다 쓰는 자리에서 쓴다. 입력은 화면 폭 그대로이고 라벨 · 설명 ·
  /// 오류 · 글자 수만 이만큼 들어와 다른 칸과 같은 자리에 선다(첨부 칸의 줄이 화면 끝까지 가는 길 — attachment-input.yaml
  /// bleedX, Q-016-2). 보통 `PSpacing.globalGutter`(24) 를 주고, 입력은 [PFieldControlData.edgeInset] 으로 이 값을 읽는다.
  final double edgeInset;

  /// 입력 — PInput · PTextarea.
  final Widget child;

  @override
  State<PField> createState() => _PFieldState();
}

class _PFieldState extends State<PField> implements PFieldLink {
  final _GraphemeCount _count = _GraphemeCount();
  FocusNode? _control;

  /// 마지막으로 보인 오류 — 같은 오류는 다시 알리지 않는다.
  String? _shownError;
  bool _supportsAnnounce = true;

  String? get _error {
    final message = widget.errorMessage;
    return widget.invalid && message != null && message.isNotEmpty
        ? message
        : null;
  }

  @override
  void initState() {
    super.initState();
    // 처음부터 있던 오류는 알리지 않는다 — 생기거나 바뀔 때만
    _shownError = _error;
  }

  @override
  void didUpdateWidget(PField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final error = _error;
    if (error != null && error != _shownError && _supportsAnnounce) {
      // 알림을 지원하지 않는 플랫폼은 오류 글이 live region 이라 저절로 읽힌다 — 두 번 읽지 않게 여기선 건너뛴다
      unawaited(
        SemanticsService.sendAnnouncement(
          View.of(context),
          error,
          Directionality.of(context),
        ),
      );
    }
    _shownError = error;
  }

  @override
  void dispose() {
    _count.dispose();
    super.dispose();
  }

  @override
  void attach(FocusNode focusNode) => _control = focusNode;

  @override
  void detach(FocusNode focusNode) {
    if (_control == focusNode) _control = null;
  }

  @override
  void reportGraphemeCount(int count) => _count.value = count;

  void _focusControl() {
    final node = _control;
    if (node == null || !node.canRequestFocus || node.hasFocus) return;
    node.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    _supportsAnnounce = MediaQuery.supportsAnnounceOf(context);
    final error = _error;
    final description = error == null && (widget.description ?? '') != ''
        ? widget.description
        : null;
    final max = widget.maxGraphemeCount;
    final label = widget.label;
    final action = widget.headerAction;

    final data = PFieldControlData(
      label: label == null
          ? null
          : widget.indicator == PFieldIndicator.optional
          ? '$label ${l10n.dsFieldOptional}'
          : label,
      message: error ?? description,
      invalid: widget.invalid,
      required: widget.required || widget.indicator == PFieldIndicator.required,
      disabled: widget.disabled,
      readOnly: widget.readOnly,
      maxGraphemeCount: max,
      counterMax: widget.counterMax,
      edgeInset: widget.edgeInset,
    );

    Widget? footer;
    if (error != null || description != null || max != null) {
      footer = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: _footerGap,
        children: [
          if (error != null)
            Expanded(
              child: _FooterMessage(
                text: error,
                icon: LucideIcons.circleAlert,
                color: c.fgCritical,
                liveRegion: !_supportsAnnounce,
              ),
            )
          else if (description != null)
            Expanded(
              child: _FooterMessage(
                text: description,
                icon: widget.descriptionIcon,
                color: c.fgNeutralSubtle,
              ),
            )
          else
            const Spacer(),
          if (max != null)
            _CharacterCount(
              count: _count,
              max: widget.counterMax ?? max,
              invalid: widget.invalid,
            ),
        ],
      );
    }

    // 묶음(체크 · 라디오)의 맨 위 · 맨 아래 줄은 Field 안의 여백까지 44 로 눌린다(03A-010)
    return PTouchTargetScope(
      child: PFieldScope(
        data: data,
        link: this,
        child: _FieldLayout(
          edgeInset: widget.edgeInset,
          label: label == null
              ? null
              : _FieldLabel(
                  text: label,
                  weight: widget.labelWeight,
                  indicator: widget.indicator,
                  onTap: _focusControl,
                ),
          actionIsButton: widget.headerTrailing == null,
          action:
              widget.headerTrailing ??
              (action == null
                  ? null
                  : PButton(
                      label: action.label,
                      onPressed: action.onPressed,
                      variant: PButtonVariant.ghost,
                      ghostColor: PButtonGhostColor.neutralSubtle,
                      size: PButtonSize.xsmall,
                      flush: PButtonFlush.right,
                    )),
          control: widget.child,
          footer: footer,
        ),
      ),
    );
  }
}

/// 쓴 글자 수 — 입력이 알리고 꼬리가 보인다.
///
/// 그리는 중(입력의 initState · didChangeDependencies · didUpdateWidget)에 바뀌면 값만 고치고 그 프레임이 끝난 뒤
/// 알린다 — 꼬리는 입력 뒤에 그려지므로 처음 그릴 때부터 맞는 수를 본다.
class _GraphemeCount extends ChangeNotifier implements ValueListenable<int> {
  int _value = 0;
  bool _pending = false;
  bool _disposed = false;

  @override
  int get value => _value;

  set value(int next) {
    if (_value == next) return;
    _value = next;
    final scheduler = SchedulerBinding.instance;
    if (scheduler.schedulerPhase != SchedulerPhase.persistentCallbacks) {
      notifyListeners();
      return;
    }
    if (_pending) return;
    _pending = true;
    scheduler.addPostFrameCallback((_) {
      _pending = false;
      if (!_disposed) notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// 라벨 — t5 · 500(bold 700) · fg-neutral. 뒤에 필수 점(6, 위 4 · 앞 2) 또는 "선택"(t4 · 줄 높이 22 · 앞 4).
/// 점 · "선택" 은 라벨 줄 상자(22)와 같은 높이의 자리에 두어 줄 가운데에 맞춘다 — 줄 상자와 꼭 겹친다(웹의
/// vertical-align top · bottom 과 같은 자리). 라벨 글 안(WidgetSpan)이라 라벨 글자의 배율로 함께 커진다(rem).
/// 보이는 라벨은 읽지 않는다 — 입력의 이름이 된다.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel({
    required this.text,
    required this.weight,
    required this.indicator,
    required this.onTap,
  });

  final String text;
  final PFieldLabelWeight weight;
  final PFieldIndicator indicator;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final style = PTypography.t5.copyWith(
      color: c.fgNeutral,
      fontWeight: weight == PFieldLabelWeight.bold
          ? FontWeight.w700
          : FontWeight.w500,
    );
    // 라벨 줄 상자 — t5 22(1배. 배율은 Flutter 가 곱한다)
    final lineHeight = style.fontSize! * style.height!;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTap: onTap,
      child: ExcludeSemantics(
        child: Text.rich(
          TextSpan(
            // 낱말 단위로만 줄을 바꾼다(v114) — 머리 오른쪽에 값이 있어 좁아져도 라벨이 글자마다 깨지지 않는다
            text: keepAll(text),
            children: [
              if (indicator == PFieldIndicator.required)
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(
                      start: _dotMarginStart,
                      top: _dotMarginTop,
                      bottom: math.max(
                        0,
                        lineHeight - _dotMarginTop - _dotSize,
                      ),
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: c.fgCritical,
                        shape: BoxShape.circle,
                      ),
                      child: const SizedBox.square(dimension: _dotSize),
                    ),
                  ),
                ),
              if (indicator == PFieldIndicator.optional)
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: _optionalPaddingStart,
                    ),
                    child: SizedBox(
                      height: _optionalLineHeight,
                      child: Center(
                        widthFactor: 1,
                        child: Text(
                          l10n.dsFieldOptional,
                          // 자리째 라벨 배율로 커진다 — 글자가 따로 한 번 더 커지지 않게
                          textScaler: TextScaler.noScaling,
                          style: PTypography.t4.copyWith(
                            height:
                                _optionalLineHeight / PTypography.t4.fontSize!,
                            color: c.fgNeutralSubtle,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          style: style,
        ),
      ),
    );
  }
}

/// 꼬리 왼쪽 — 설명 또는 오류(t4) + 앞 아이콘 16(첫 줄 가운데, 사이 6). 아이콘은 읽지 않는다.
class _FooterMessage extends StatelessWidget {
  const _FooterMessage({
    required this.text,
    required this.color,
    this.icon,
    this.liveRegion = false,
  });

  final String text;
  final Color color;
  final IconData? icon;

  /// 오류 글 — 알림을 지원하지 않는 플랫폼에서 생기거나 바뀌면 저절로 읽힌다.
  final bool liveRegion;

  @override
  Widget build(BuildContext context) {
    final style = PTypography.t4.copyWith(
      color: color,
      fontWeight: FontWeight.w400,
    );
    final lineHeight =
        MediaQuery.textScalerOf(context).scale(style.fontSize!) * style.height!;
    return Semantics(
      container: true,
      liveRegion: liveRegion,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: _messageIconGap,
        children: [
          if (icon != null)
            ExcludeSemantics(
              child: Padding(
                padding: EdgeInsets.only(
                  top: math.max(0, (lineHeight - _messageIconSize) / 2),
                ),
                child: Icon(icon, size: _messageIconSize, color: color),
              ),
            ),
          // 낱말 단위 줄바꿈(v114) — 읽는 글은 원래 글
          Flexible(
            child: Text(keepAll(text), semanticsLabel: text, style: style),
          ),
        ],
      ),
    );
  }
}

/// 꼬리 오른쪽 — "쓴 수/최대"(t4 · 숫자 폭 고정). 쓴 수는 fg-neutral(비면 fg-neutral-subtle), 최대는
/// fg-neutral-subtle, 오류면 둘 다 fg-critical. "12자 중 4자" 처럼 읽는다.
class _CharacterCount extends StatelessWidget {
  const _CharacterCount({
    required this.count,
    required this.max,
    required this.invalid,
  });

  final ValueListenable<int> count;
  final int max;
  final bool invalid;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final style = PTypography.t4.copyWith(
      fontWeight: FontWeight.w400,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return ValueListenableBuilder<int>(
      valueListenable: count,
      builder: (context, n, _) => Semantics(
        container: true,
        label: l10n.dsFieldCountSemantics(n, max),
        child: ExcludeSemantics(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: _groupThousands(n),
                  style: style.copyWith(
                    color: invalid || n > max
                        ? c.fgCritical
                        : n == 0
                        ? c.fgNeutralSubtle
                        : c.fgNeutral,
                  ),
                ),
                TextSpan(
                  text: '/${_groupThousands(max)}',
                  style: style.copyWith(
                    color: invalid || n > max
                        ? c.fgCritical
                        : c.fgNeutralSubtle,
                  ),
                ),
              ],
            ),
            style: style,
          ),
        ),
      ),
    );
  }
}

/// 천 단위 쉼표 — 글자 수 칸이 "10,000/10,000" 으로 읽힌다(1,000 미만은 그대로 "4/200").
String _groupThousands(int n) {
  final digits = n.abs().toString();
  final out = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      out.write(',');
    }
    out.write(digits[i]);
  }
  return out.toString();
}

enum _FieldSlot { label, control, footer, action }

/// 머리 · 입력 · 꼬리를 쌓는 자리. 머리는 라벨(왼쪽) · 보조 액션(오른쪽)을 가운데 맞춤으로 두고, 액션은 위아래로
/// 5 넘친다. 넘친 자리 · 버튼의 누르는 영역(44)도 받는다 — 그래서 Column · Row 대신 직접 놓는다
/// (Flutter 는 부모 상자 안에서만 자식에게 누름을 묻는다).
class _FieldLayout
    extends SlottedMultiChildRenderObjectWidget<_FieldSlot, RenderBox> {
  const _FieldLayout({
    required this.label,
    required this.action,
    required this.actionIsButton,
    required this.edgeInset,
    required this.control,
    required this.footer,
  });

  final Widget? label;
  final Widget? action;

  /// 머리 오른쪽이 버튼인가 — 버튼이면 위아래 5 넘치고 누르는 영역이 44 다. 머리 값 글이면 둘 다 아니다.
  final bool actionIsButton;

  /// 머리 · 꼬리를 입력 양옆에서 들이는 만큼(기본 0).
  final double edgeInset;
  final Widget control;
  final Widget? footer;

  // 입력이 꼬리보다 먼저 붙는다 — 꼬리의 글자 수가 처음부터 맞는다
  @override
  Iterable<_FieldSlot> get slots => _FieldSlot.values;

  @override
  Widget? childForSlot(_FieldSlot slot) => switch (slot) {
    _FieldSlot.label => label,
    _FieldSlot.control => control,
    _FieldSlot.footer => footer,
    _FieldSlot.action => action,
  };

  @override
  _RenderFieldLayout createRenderObject(BuildContext context) =>
      _RenderFieldLayout(
        textDirection: Directionality.of(context),
        actionIsButton: actionIsButton,
        edgeInset: edgeInset,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderFieldLayout renderObject,
  ) {
    renderObject
      ..textDirection = Directionality.of(context)
      ..actionIsButton = actionIsButton
      ..edgeInset = edgeInset;
  }
}

typedef _FieldGeometry = ({
  Size size,
  Offset? label,
  BoxConstraints? labelConstraints,
  Offset? action,
  Offset control,
  BoxConstraints controlConstraints,
  Offset? footer,
});

class _RenderFieldLayout extends RenderBox
    with SlottedContainerRenderObjectMixin<_FieldSlot, RenderBox> {
  _RenderFieldLayout({
    required TextDirection textDirection,
    required bool actionIsButton,
    required double edgeInset,
  }) : _textDirection = textDirection,
       _actionIsButton = actionIsButton,
       _edgeInset = edgeInset;

  bool get actionIsButton => _actionIsButton;
  bool _actionIsButton;
  set actionIsButton(bool value) {
    if (_actionIsButton == value) return;
    _actionIsButton = value;
    markNeedsLayout();
  }

  double get edgeInset => _edgeInset;
  double _edgeInset;
  set edgeInset(double value) {
    if (_edgeInset == value) return;
    _edgeInset = value;
    markNeedsLayout();
  }

  /// 머리 · 꼬리의 좌우 안쪽 여백 — 기본 2 에 [edgeInset] 을 더한다(입력은 [edgeInset] 만큼 넓은 폭 그대로).
  double get _hx => _headerPaddingX + _edgeInset;
  double get _fx => _footerPaddingX + _edgeInset;

  /// 머리 오른쪽의 위아래 넘침 — 버튼 −5, 머리 값 글 0.
  double get _marginY => _actionIsButton ? _actionMarginY : 0;

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection == value) return;
    _textDirection = value;
    markNeedsLayout();
  }

  RenderBox? get _label => childForSlot(_FieldSlot.label);
  RenderBox? get _action => childForSlot(_FieldSlot.action);
  RenderBox? get _control => childForSlot(_FieldSlot.control);
  RenderBox? get _footer => childForSlot(_FieldSlot.footer);

  /// 보조 액션이 누름을 받는 자리 — 보이는 상자를 44 까지 넓힌 것(Button 과 같다). 머리 · Field 밖으로 넘친다.
  Rect? _actionTouchRect;

  _FieldGeometry _compute(
    BoxConstraints constraints,
    ChildLayouter layoutChild,
  ) {
    assert(constraints.hasBoundedWidth, 'Field 는 폭이 정해진 자리에 둔다(늘 꽉 채운다)');
    final width = constraints.maxWidth;
    final ltr = textDirection == TextDirection.ltr;
    final label = _label;
    final action = _action;
    final control = _control;
    final footer = _footer;

    var y = 0.0;
    Offset? labelOffset;
    Offset? actionOffset;
    BoxConstraints? labelConstraints;
    if (label != null || action != null) {
      final inner = math.max(0.0, width - 2 * _hx);
      final actionSize = action == null
          ? Size.zero
          : layoutChild(action, BoxConstraints(maxWidth: inner));
      // 액션이 머리에서 차지하는 높이 — 버튼(32)에서 위아래 5 를 뺀 22
      final actionSlot = action == null
          ? 0.0
          : math.max(0.0, actionSize.height + 2 * _marginY);
      // 라벨이 절반을 지키고도 오른쪽 값이 한 줄에 드나 — 안 들면 값이 라벨 아래 오른쪽 끝으로 내려간다(Header Row 와 같은 규칙)
      final stacked =
          label != null && action != null && _stacks(inner, actionSize.width);
      var labelSize = Size.zero;
      if (label != null) {
        labelConstraints = BoxConstraints(
          maxWidth: math.max(
            0.0,
            action == null || stacked
                ? inner
                : inner - actionSize.width - _headerGap,
          ),
        );
        labelSize = layoutChild(label, labelConstraints);
      }
      final header = stacked
          ? labelSize.height + actionSlot
          : math.max(labelSize.height, actionSlot);
      if (label != null) {
        labelOffset = Offset(
          ltr ? _hx : width - _hx - labelSize.width,
          stacked ? 0.0 : (header - labelSize.height) / 2,
        );
      }
      if (action != null) {
        actionOffset = Offset(
          ltr ? width - _hx - actionSize.width : _hx,
          stacked
              ? labelSize.height + _marginY
              : (header - actionSlot) / 2 + _marginY,
        );
      }
      y = header + _gap;
    }

    final controlConstraints = BoxConstraints.tightFor(width: width);
    final controlOffset = Offset(0, y);
    if (control != null) y += layoutChild(control, controlConstraints).height;

    Offset? footerOffset;
    if (footer != null) {
      y += _gap;
      final footerSize = layoutChild(
        footer,
        BoxConstraints.tightFor(width: math.max(0.0, width - 2 * _fx)),
      );
      footerOffset = Offset(_fx, y);
      y += footerSize.height;
    }

    return (
      size: constraints.constrain(Size(width, y)),
      label: labelOffset,
      labelConstraints: labelConstraints,
      action: actionOffset,
      control: controlOffset,
      controlConstraints: controlConstraints,
      footer: footerOffset,
    );
  }

  /// 머리를 두 줄로 쌓나 — 라벨이 머리 폭의 절반을 지키고도 오른쪽 값이 한 줄에 들어가지 않으면 쌓는다.
  bool _stacks(double inner, double actionWidth) =>
      actionWidth + _headerGap + inner * 0.5 > inner + 0.01;

  static void _place(RenderBox? child, Offset? offset) {
    if (child == null || offset == null) return;
    (child.parentData! as BoxParentData).offset = offset;
  }

  @override
  void performLayout() {
    final g = _compute(constraints, ChildLayoutHelper.layoutChild);
    size = g.size;
    _place(_label, g.label);
    _place(_action, g.action);
    _place(_control, g.control);
    _place(_footer, g.footer);
    final action = _action;
    if (action == null) {
      _actionTouchRect = null;
    } else {
      final visible = g.action! & action.size;
      final dx = _actionIsButton
          ? math.max(0.0, (PTouch.min - visible.width) / 2)
          : 0.0;
      final dy = _actionIsButton
          ? math.max(0.0, (PTouch.min - visible.height) / 2)
          : 0.0;
      _actionTouchRect = Rect.fromLTRB(
        visible.left - dx,
        visible.top - dy,
        visible.right + dx,
        visible.bottom + dy,
      );
    }
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _compute(constraints, ChildLayoutHelper.dryLayoutChild).size;

  @override
  double? computeDryBaseline(
    BoxConstraints constraints,
    TextBaseline baseline,
  ) {
    final g = _compute(constraints, ChildLayoutHelper.dryLayoutChild);
    final label = _label;
    if (label != null) {
      final distance = label.getDryBaseline(g.labelConstraints!, baseline);
      return distance == null ? null : distance + g.label!.dy;
    }
    final control = _control;
    if (control == null) return null;
    final distance = control.getDryBaseline(g.controlConstraints, baseline);
    return distance == null ? null : distance + g.control.dy;
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    final child = _label ?? _control;
    if (child == null) return null;
    final distance = child.getDistanceToActualBaseline(baseline);
    return distance == null
        ? null
        : distance + (child.parentData! as BoxParentData).offset.dy;
  }

  double _intrinsicWidth(double Function(RenderBox child) of) {
    final label = _label;
    final action = _action;
    final control = _control;
    final footer = _footer;
    var header = 0.0;
    if (label != null || action != null) {
      header =
          2 * _hx +
          (label == null ? 0 : of(label)) +
          (action == null ? 0 : of(action)) +
          (label != null && action != null ? _headerGap : 0);
    }
    return [
      header,
      control == null ? 0.0 : of(control),
      footer == null ? 0.0 : 2 * _fx + of(footer),
    ].reduce(math.max);
  }

  double _intrinsicHeight(
    double width,
    double Function(RenderBox child, double width) of,
  ) {
    final label = _label;
    final action = _action;
    final control = _control;
    final footer = _footer;
    var height = 0.0;
    if (label != null || action != null) {
      final inner = math.max(0.0, width - 2 * _hx);
      final actionWidth = action == null
          ? 0.0
          : math.min(inner, action.getMaxIntrinsicWidth(double.infinity));
      final actionSlot = action == null
          ? 0.0
          : math.max(0.0, of(action, actionWidth) + 2 * _marginY);
      final stacked =
          label != null && action != null && _stacks(inner, actionWidth);
      final labelHeight = label == null
          ? 0.0
          : of(
              label,
              math.max(
                0.0,
                action == null || stacked
                    ? inner
                    : inner - actionWidth - _headerGap,
              ),
            );
      height +=
          (stacked
              ? labelHeight + actionSlot
              : math.max(labelHeight, actionSlot)) +
          _gap;
    }
    if (control != null) height += of(control, width);
    if (footer != null) {
      height += _gap + of(footer, math.max(0.0, width - 2 * _fx));
    }
    return height;
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      _intrinsicWidth((child) => child.getMinIntrinsicWidth(double.infinity));

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _intrinsicWidth((child) => child.getMaxIntrinsicWidth(double.infinity));

  @override
  double computeMinIntrinsicHeight(double width) => _intrinsicHeight(
    width,
    (child, width) => child.getMinIntrinsicHeight(width),
  );

  @override
  double computeMaxIntrinsicHeight(double width) => _intrinsicHeight(
    width,
    (child, width) => child.getMaxIntrinsicHeight(width),
  );

  @override
  void paint(PaintingContext context, Offset offset) {
    // 액션은 맨 위에 — 머리 밖으로 넘친다
    for (final child in [_label, _control, _footer, _action]) {
      if (child == null) continue;
      context.paintChild(
        child,
        offset + (child.parentData! as BoxParentData).offset,
      );
    }
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // 제 상자 밖이어도 보조 액션의 누르는 영역이면 받는다
    if (!size.contains(position) &&
        !(_actionTouchRect?.contains(position) ?? false)) {
      return false;
    }
    if (hitTestChildren(result, position: position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    // 보이는 입력이 액션의 넓힌 영역(보이지 않는 여백)보다 먼저다
    for (final child in [_control, _footer, _action, _label]) {
      if (child == null) continue;
      final hit = result.addWithPaintOffset(
        offset: (child.parentData! as BoxParentData).offset,
        position: position,
        hitTest: (result, transformed) =>
            child.hitTest(result, position: transformed),
      );
      if (hit) return true;
    }
    return false;
  }
}
