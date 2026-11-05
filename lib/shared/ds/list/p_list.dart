import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/checkbox/p_checkbox.dart';
import 'package:groo_damda_app/shared/ds/list/list_row.dart';
import 'package:groo_damda_app/shared/ds/radio/p_radio.dart';
import 'package:groo_damda_app/shared/ds/switch/p_switch.dart';

export 'package:groo_damda_app/shared/ds/list/list_row.dart'
    show PListAction, PListAlign, PListNest, PListSuffix, PListValue;

/// List — 가로 줄로 된 내용을 세로로 잇는다(설정 · 메뉴 · 선택 · 키-값 줄과 거래 · 할 일 · 알림 같은 내용 줄). 구조는 SEED
/// List(2026-10-01), 수치 원본은 groo-design `specs/components/list.yaml` · `list-header.yaml`(값은
/// `test/fixtures/design_spec/list.json` · `list-header.json` — 테스트가 위젯이 그 값과 같은지 본다). 웹(desk-front
/// `src/shared/ds/list`)과 같은 값이다.
///
/// 줄의 종류 — 하는 일에 따라 나뉜다.
///   [PListItem]          보기만 하는 줄 — 누르지 않는다(키-값 · 안내). 눌림 · 포커스가 없다.
///   [PListButtonItem]    누르는 줄 — 줄 전체가 버튼. 화면을 옮기면 뒤에 오른쪽 화살표를 단다. onTap 이 없으면 막힌 줄.
///   [PListLinkItem]      링크 줄 — 줄 전체가 링크. 막지 않는다(갈 수 없는 곳이면 줄을 빼거나 누르는 줄로 막는다).
///   [PListParentItem]    하위 줄을 접는 부모 줄(p_list_parent_item.dart).
///   [PListSwitchItem] · [PListCheckItem] · [PListRadioItem]  컨트롤 줄 — 줄 전체가 라벨이라 줄 어디를 눌러도 끼운
///     스위치 · 체크 · 라디오가 바뀐다. 따로 누르는 버튼을 같이 넣지 않는다(뒤 붙이개를 받지 않는다).
/// 묶음 — [PList](줄을 세로로 잇는다) · [PListRadioGroup](하나 고르기) · [PListCheckGroup](여럿 고르기). 묶음은 이름이
/// 필수다. 한 묶음에서 라디오와 체크를 섞지 않고, 하나 고르기는 두 줄 이상으로 둔다(부르는 쪽 규칙).
/// 그 밖 — [PListHeader](목록 제목, p_list_header.dart) · [PListDivider](줄 사이 선) · [PListTile](앞 타일) ·
/// [PListSuffix](뒤 붙이개를 여럿 이을 때) · [PListAction](줄 안의 작은 버튼을 감싼다).
///
/// 한 줄은 두 층이다 — 바탕 층(누름 · 강조 바탕, 줄지 않는다)과 콘텐츠 층(앞 · 본문 · 뒤, 누르면 세로 2px 거리 줄어든다).
/// 누르는 줄만 눌림이 있다. 막힌 줄은 제목 · 설명 · 앞뒤 아이콘이 모두 비활성 색, 타일은 비활성 바탕이고 흐리게 하지
/// 않는다. 강조(`highlighted`)는 바탕만 바뀐다. 올림(hovered) · 포커스 링(focused)은 웹 상태라 앱에는 없다 — 키보드
/// 포커스는 받고(Enter · Space 로 누른다) 링은 그리지 않는다.
/// 글 — 제목은 글(String)로 준다(낱말 단위로 줄을 바꾸고 말줄임이 없다). 설명은 글이거나 위젯([detailChild] — Tag Group ·
/// 배지 줄). 앞 · 뒤 붙이개는 위젯이고 줄이 아이콘(앞 22 · 뒤 화살표 18) · 글(뒤 16 · 옅은 색)의 모습을 입힌다.
///
/// 읽기 — 누르는 줄은 본문(제목 + 설명)이 버튼(링크 줄은 링크)이고 뒤 붙이개는 따로 읽는다. 컨트롤 줄은 줄 전체가 컨트롤
/// 하나이고 제목 + 설명이 이름이다. 웹의 `aria-labelledby`(목록 제목 → 목록 이름)는 [PList.semanticLabel] 에 제목 글만
/// 줘서 잇는다(제목 오른쪽 버튼 글이 섞이지 않는다).
class PList extends StatelessWidget {
  const PList({
    super.key,
    required this.children,
    this.semanticLabel,
    this.itemRadius = PRounded.r2_5,
  });

  final List<Widget> children;

  /// 목록의 이름(웹 aria-label · aria-labelledby) — 목록 제목이 있으면 그 제목 글.
  final String? semanticLabel;

  /// 누름 바탕의 모서리 — 기본 10. 카드 안에서는 카드 모서리 − 카드 가장자리에서 바탕까지 거리(동심 모서리, 모서리
  /// 16 카드에 줄을 바로 넣으면 16 − 6).
  final double itemRadius;

  @override
  Widget build(BuildContext context) {
    return _PListColumn(
      semanticLabel: semanticLabel,
      itemRadius: itemRadius,
      children: children,
    );
  }
}

/// 목록의 짜임 — 줄을 세로로 잇는다(줄 사이 간격 없음). 묶음이 함께 쓴다.
class _PListColumn extends StatelessWidget {
  const _PListColumn({
    required this.children,
    required this.itemRadius,
    this.semanticLabel,
    this.mergeLabel = false,
  });

  final List<Widget> children;
  final String? semanticLabel;
  final double itemRadius;

  /// 이름을 바깥 노드(RadioGroup 의 radio group)에 합친다 — 묶음 하나가 이름 + 역할을 함께 갖는다.
  final bool mergeLabel;

  @override
  Widget build(BuildContext context) {
    return PListScope(
      itemRadius: itemRadius,
      nest: PListNest.none,
      child: Semantics(
        container: !mergeLabel,
        explicitChildNodes: !mergeLabel,
        label: semanticLabel,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

/// 줄이 함께 갖는 값 — 제목 · 설명 · 강조 · 맞춤.
abstract class PListItemBase extends StatelessWidget {
  const PListItemBase({
    super.key,
    required this.title,
    this.detail,
    this.detailChild,
    this.titleColor,
    this.highlighted = false,
    this.align = PListAlign.center,
    this.titleSuffix,
    this.titleStrike = false,
    this.gutter,
    this.verticalPadding,
    this.endInset,
  }) : assert(
         detail == null || detailChild == null,
         '설명은 글(detail)이나 위젯(detailChild) 하나만 준다',
       );

  /// 제목 — 16 · 400. 무엇인지 한 줄로. 길면 낱말 단위로 줄을 바꾼다(말줄임 · 줄 수 제한 없음).
  final String title;

  /// 설명 — 13 · 옅은 색. 제목만으로 모자랄 때만. 두 줄까지, 그 이상이면 [align] 을 top 으로.
  final String? detail;

  /// 설명 자리에 글 대신 두는 위젯 — 분류 · 자산 · 시각처럼 여러 메타를 잇는 설명 줄(Tag Group `t3`)이나 배지 줄.
  final Widget? detailChild;

  /// 제목 색을 덮는다 — 합계에 안 드는 줄(예정 · 환불)은 제목 · 금액만 `fg-neutral-subtle`. 막힌 줄은 비활성 색이 이긴다.
  final Color? titleColor;

  /// 새 알림처럼 주목이 필요한 줄 — 바탕만 옅은 브랜드 색(점 · 막대 없음). 누르는 동안 설명 · 값 글자만 한 단계 짙다.
  final bool highlighted;

  /// 맞춤 — 기본 가운데. 제목이 두 줄을 넘거나 설명이 길면 위. 한 목록 안에서는 줄마다 섞지 않는다.
  final PListAlign align;

  /// 제목 글 뒤에 이어 붙는 배지들(제목과 함께 줄을 바꾼다).
  final List<Widget>? titleSuffix;

  /// 제목 취소선(완료한 할 일).
  final bool titleStrike;

  /// **임시 인자** — 줄 좌우 여백(기본 24). 좌우 24 를 쥔 옛 호스트 안에서만 0, 호스트가 바깥 24 를 걷을 때 함께 걷는다.
  final double? gutter;

  /// 줄 위아래 여백 — 기본 12. 키-값 줄(예산 · 페이스 · 현황 — I-08)이 8 을 준다.
  final double? verticalPadding;

  /// 줄 오른쪽 끝 여백 — 줄 끝 조작 요소(⋮)를 화면 끝 16 에 세울 때. 기본은 [gutter].
  final double? endInset;
}

/// 보기만 하는 줄 — 누르지 않는다(눌림 · 포커스가 없다). 키-값 · 안내 줄.
class PListItem extends PListItemBase {
  const PListItem({
    super.key,
    required super.title,
    super.detail,
    super.detailChild,
    super.titleColor,
    super.highlighted,
    super.align,
    super.titleSuffix,
    super.titleStrike,
    super.gutter,
    super.verticalPadding,
    super.endInset,
    this.titleWeight,
    this.prefix,
    this.suffix,
  });

  /// 제목 굵기 덮개 — 화면 값(합계 줄만 700).
  final FontWeight? titleWeight;

  /// 앞 붙이개 — 아이콘 22 · [PListTile] · 로고 타일 · 아바타.
  final Widget? prefix;

  /// 뒤 붙이개 — 값 글자 · 금액.
  final Widget? suffix;

  @override
  Widget build(BuildContext context) => PListRowFrame(
    title: title,
    detail: detail,
    detailChild: detailChild,
    titleColor: titleColor,
    titleWeight: titleWeight,
    titleSuffix: titleSuffix,
    titleStrike: titleStrike,
    gutter: gutter,
    verticalPadding: verticalPadding,
    endInset: endInset,
    prefix: prefix,
    suffix: suffix,
    highlighted: highlighted,
    align: align,
  );
}

/// 누르는 줄 — 줄 전체가 버튼. 화면을 옮기면 뒤 붙이개에 오른쪽 화살표를 둔다. 뒤 붙이개의 작은 버튼은 [PListAction] 으로
/// 감싸 따로 누른다.
///
/// [onTap] 이 없으면 막힌 줄 — 눌리지 않고 포커스에서 빠진다(값은 그대로 보인다).
class PListButtonItem extends PListItemBase {
  const PListButtonItem({
    super.key,
    required super.title,
    required this.onTap,
    super.detail,
    super.detailChild,
    super.titleColor,
    super.highlighted,
    super.align,
    super.titleSuffix,
    super.titleStrike,
    super.gutter,
    super.endInset,
    this.prefix,
    this.suffix,
    this.focusNode,
    this.semanticHint,
  });

  final VoidCallback? onTap;
  final Widget? prefix;
  final Widget? suffix;
  final FocusNode? focusNode;

  /// 줄을 읽을 때 이름 뒤에 붙는 설명 — 폼의 고르는 줄이 오류 글을 잇는다(웹 aria-describedby).
  final String? semanticHint;

  @override
  Widget build(BuildContext context) => PListRowFrame(
    title: title,
    detail: detail,
    detailChild: detailChild,
    titleColor: titleColor,
    titleSuffix: titleSuffix,
    titleStrike: titleStrike,
    gutter: gutter,
    endInset: endInset,
    prefix: prefix,
    suffix: suffix,
    highlighted: highlighted,
    align: align,
    interactive: true,
    onActivate: onTap,
    focusNode: focusNode,
    semantics: PListRowSemantics(button: true, hint: semanticHint),
  );
}

/// 링크 줄 — 줄 전체가 링크. 다른 페이지 · 바깥 주소로 간다([onTap] 에서 연다). 링크 줄은 막지 않는다 — 갈 수 없는
/// 곳이면 줄을 빼거나 누르는 줄([PListButtonItem])로 바꿔 막는다.
class PListLinkItem extends PListItemBase {
  const PListLinkItem({
    super.key,
    required super.title,
    required VoidCallback this.onTap,
    super.detail,
    super.detailChild,
    super.titleColor,
    super.highlighted,
    super.align,
    this.prefix,
    this.suffix,
    this.focusNode,
  });

  final VoidCallback? onTap;
  final Widget? prefix;
  final Widget? suffix;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) => PListRowFrame(
    title: title,
    detail: detail,
    detailChild: detailChild,
    titleColor: titleColor,
    prefix: prefix,
    suffix: suffix,
    highlighted: highlighted,
    align: align,
    interactive: true,
    onActivate: onTap,
    focusNode: focusNode,
    semantics: const PListRowSemantics(link: true),
  );
}

// ── 컨트롤 줄 ───────────────────────────────────────────────

/// 마크 자리 — 앞 붙이개 자리(prefix) · 뒤 붙이개 자리(suffix). 앞에 두면 그 자리를 차지하므로 prefix 를 같이 줄 수
/// 없다. 체크는 앞(기본) · 뒤, 라디오는 뒤(기본) · 앞.
enum PListMarkPosition { prefix, suffix }

/// 눌린 줄에서 마크가 누름 색을 받는다 — 줄이 라벨이라 눌림이 마크에 닿는다(웹 `:active` 가 라벨에서 컨트롤로).
class _PressedMark extends StatelessWidget {
  const _PressedMark(this.builder);

  final Widget Function(bool pressed) builder;

  @override
  Widget build(BuildContext context) =>
      builder(PListRowScope.pressedOf(context));
}

/// 스위치 줄 — 스위치는 뒤에, 제목 16 줄이라 32(Switch 스펙). 줄 어디를 눌러도 바뀌고 바로 적용되는 설정에만 쓴다.
/// 줄이 줄 때 스위치는 따로 줄지 않는다. [onChanged] 가 없으면 막힌 줄.
class PListSwitchItem extends PListItemBase {
  const PListSwitchItem({
    super.key,
    required super.title,
    required this.checked,
    required this.onChanged,
    super.detail,
    super.detailChild,
    super.titleColor,
    super.highlighted,
    super.align,
    this.prefix,
    this.tone = PSwitchTone.neutral,
    this.focusNode,
  });

  final bool checked;

  /// 누르면 다음 값(!checked). 없으면 막힌 줄.
  final ValueChanged<bool>? onChanged;
  final Widget? prefix;
  final PSwitchTone tone;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    final enabled = onChanged != null;
    return PListRowFrame(
      title: title,
      detail: detail,
      detailChild: detailChild,
      titleColor: titleColor,
      prefix: prefix,
      // 스위치는 줄이 줄 때 따로 줄지 않는다 — pressed 를 주지 않는다
      suffix: PSwitchmark(
        checked: checked,
        size: PSwitchSize.s32,
        tone: tone,
        enabled: enabled,
      ),
      highlighted: highlighted,
      align: align,
      interactive: true,
      onActivate: enabled ? () => onChanged(!checked) : null,
      activateOnEnter: true,
      focusNode: focusNode,
      semantics: PListRowSemantics(wholeRow: true, toggled: checked),
    );
  }
}

/// 체크 줄 — 여럿 고르기. 체크 24 를 앞(기본)이나 뒤에. 저장해야 적용되는 선택에 쓴다. 줄 어디를 눌러도 바뀐다(Enter 는
/// 누르지 않는다 — 폼 제출에 둔다). [onChanged] 가 없으면 막힌 줄.
///
/// 체크를 앞에 두고 [prefix] 를 같이 주면 체크 → 앞 붙이개(점 · 타일 · 아이콘) 차례로 서고 사이는 12(웹 ListCheckItem 과 같다).
class PListCheckItem extends PListItemBase {
  const PListCheckItem({
    super.key,
    required super.title,
    required this.checked,
    required this.onChanged,
    super.detail,
    super.detailChild,
    super.titleColor,
    super.highlighted,
    super.align,
    super.titleSuffix,
    this.prefix,
    this.markPosition = PListMarkPosition.prefix,
    this.suffixValue,
    this.tone = PCheckboxTone.neutral,
    this.locked = false,
    this.focusNode,
  }) : assert(
         markPosition == PListMarkPosition.suffix || suffixValue == null,
         '뒤 값은 체크를 뒤(suffix)에 둘 때만 — 값 → 체크 순으로 한 덩어리로 선다',
       );

  /// true 선택 · false 선택 안 됨 · null 일부 선택.
  final bool? checked;

  /// 누르면 다음 값 — 선택이면 false, 선택 안 됨 · 일부 선택이면 true. 없으면 막힌 줄.
  final ValueChanged<bool>? onChanged;
  final Widget? prefix;
  final PListMarkPosition markPosition;

  /// 체크 앞의 값(개수 · 금액) — 글([Text]) 또는 기다리는 자리([PSkeleton])를 준다. 값 → 체크 순으로 한 덩어리로 서고
  /// 사이는 [PListSuffix] 의 4(list.yaml suffix.gap). 글은 값 글자(뒤 16 · 옅은 색)를 줄이 입힌다. 웹 `suffixValue` 와 같은 이름.
  final Widget? suffixValue;
  final PCheckboxTone tone;

  /// 끌 수 없는 켬(숨길 수 없는 기본 캘린더) — 칸만 막힌 켬(선택 + 막힘, 포커스에서 빠진다)이고 줄은 누르지 못하지만 제목 ·
  /// 앞 붙이개(색 점 · 타일) · 배지는 보통 색 그대로다. 줄 전체를 막는 것([onChanged] 없음)과 달리 "꺼진 것" 으로 읽히지 않는다.
  /// 끌 수 없는 까닭은 배지가 말한다. 켠 채([checked] true)로 쓴다.
  final bool locked;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final onChanged = locked ? null : this.onChanged;
    final enabled = onChanged != null;
    final mark = _PressedMark(
      (pressed) => PCheckmark(
        checked: checked,
        size: PCheckboxSize.large,
        tone: tone,
        enabled: enabled,
        pressed: pressed,
        // 줄이 이미 줄어든다 — 칸은 누름 색만
        scaleOnPress: false,
      ),
    );
    return PListRowFrame(
      title: title,
      detail: detail,
      detailChild: detailChild,
      titleColor: titleColor,
      titleSuffix: titleSuffix,
      prefix: markPosition == PListMarkPosition.prefix
          ? (prefix == null
                ? mark
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: PSpacing.x3,
                    children: [mark, prefix!],
                  ))
          : prefix,
      suffix: markPosition == PListMarkPosition.suffix
          ? (suffixValue == null
                ? mark
                : PListSuffix(
                    children: [
                      suffixValue is Text
                          ? PListValue(child: suffixValue!)
                          : suffixValue!,
                      mark,
                    ],
                  ))
          : null,
      highlighted: highlighted,
      align: align,
      interactive: true,
      onActivate: enabled ? () => onChanged(checked != true) : null,
      // 체크 줄의 Enter 는 폼 제출에 둔다 — 누르지 않는다(Space 만)
      activateOnEnter: false,
      locked: locked,
      focusNode: focusNode,
      semantics: PListRowSemantics(
        wholeRow: true,
        checked: checked ?? false,
        mixed: checked == null,
      ),
    );
  }
}

/// 여럿 고르기 묶음 — 체크 줄을 담는다. 묶음의 이름([semanticLabel])이 필수다(보조 기술이 묶음을 무엇으로 읽는지).
class PListCheckGroup extends StatelessWidget {
  const PListCheckGroup({
    super.key,
    required this.semanticLabel,
    required this.children,
    this.itemRadius = PRounded.r2_5,
  }) : assert(semanticLabel != '', '묶음의 이름이 필수다');

  final String semanticLabel;
  final List<Widget> children;
  final double itemRadius;

  @override
  Widget build(BuildContext context) => _PListColumn(
    semanticLabel: semanticLabel,
    itemRadius: itemRadius,
    children: children,
  );
}

/// 하나 고르기 묶음 — 라디오 줄을 담는다. 묶음의 이름([semanticLabel])이 필수다. 값을 쥐고, 이미 고른 줄을 다시 눌러도
/// 풀리지 않는다. [onChanged] 가 없으면 묶음 전체가 막힌다(고른 줄은 채운 원 그대로 색만 바뀐다).
///
/// 키보드 — 묶음에 들어오면 고른 줄(없으면 첫 줄)로 간다. 화살표로 이전 · 다음 줄을 고르고(막힌 줄은 건너뛴다), Space 로
/// 포커스된 줄을 고른다. Enter 는 고르지 않는다(폼 제출에 둔다). Flutter 의 RadioGroup 이 맡는다.
class PListRadioGroup<T> extends StatelessWidget {
  const PListRadioGroup({
    super.key,
    required this.semanticLabel,
    required this.value,
    required this.onChanged,
    required this.children,
    this.itemRadius = PRounded.r2_5,
  }) : assert(semanticLabel != '', '묶음의 이름이 필수다');

  final String semanticLabel;

  /// 고른 값 — 없으면 아무것도 고르지 않았다.
  final T? value;

  /// 다른 줄을 고르면 그 값. 없으면 묶음 전체가 막힌다.
  final ValueChanged<T>? onChanged;

  /// 줄 — [PListRadioItem] 들(같은 값 타입).
  final List<Widget> children;
  final double itemRadius;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    return _PListRadioGroupScope(
      enabled: onChanged != null,
      child: RadioGroup<T>(
        groupValue: value,
        onChanged: (next) {
          if (onChanged == null || next == null || next == value) return;
          onChanged(next);
        },
        child: _PListColumn(
          semanticLabel: semanticLabel,
          itemRadius: itemRadius,
          mergeLabel: true,
          children: children,
        ),
      ),
    );
  }
}

/// 묶음이 막혔는지 — [PListRadioItem] 이 읽는다.
class _PListRadioGroupScope extends InheritedWidget {
  const _PListRadioGroupScope({required this.enabled, required super.child});

  final bool enabled;

  static bool enabledOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_PListRadioGroupScope>()
          ?.enabled ??
      true;

  @override
  bool updateShouldNotify(_PListRadioGroupScope oldWidget) =>
      enabled != oldWidget.enabled;
}

/// 라디오 줄 — 하나 고르기. 라디오 24 를 뒤(기본)에 — 앞에도 둔다. [PListRadioGroup] 안에서만 쓴다(같은 값 타입). 줄 어디를
/// 눌러도 고른다. 고른 줄 · 안 고른 줄이 모두 보인다. [enabled] 가 false 면 이 줄만 막힌다.
///
/// 라디오를 앞에 두면 그 자리를 차지해 [prefix] 를 같이 줄 수 없다.
class PListRadioItem<T> extends StatefulWidget {
  const PListRadioItem({
    super.key,
    required this.value,
    required this.title,
    this.detail,
    this.detailChild,
    this.titleColor,
    this.highlighted = false,
    this.align = PListAlign.center,
    this.prefix,
    this.titleSuffix,
    this.markPosition = PListMarkPosition.suffix,
    this.tone = PRadioTone.neutral,
    this.enabled = true,
    this.focusNode,
  }) : assert(
         detail == null || detailChild == null,
         '설명은 글(detail)이나 위젯(detailChild) 하나만 준다',
       ),
       assert(
         markPosition == PListMarkPosition.suffix || prefix == null,
         '라디오를 앞에 두면 앞 붙이개를 같이 쓸 수 없다 — 라디오를 뒤(suffix)에 두거나 앞 붙이개를 뺀다',
       );

  /// 이 줄의 값 — 묶음의 값과 같으면 선택이다.
  final T value;
  final String title;
  final String? detail;
  final Widget? detailChild;
  final Color? titleColor;
  final bool highlighted;
  final PListAlign align;
  final Widget? prefix;

  /// 제목 뒤에 붙는 배지 줄("예정") — 제목과 한 덩어리로 줄이 바뀐다.
  final List<Widget>? titleSuffix;
  final PListMarkPosition markPosition;
  final PRadioTone tone;

  /// false 면 이 줄만 막힌다.
  final bool enabled;
  final FocusNode? focusNode;

  @override
  State<PListRadioItem<T>> createState() => _PListRadioItemState<T>();
}

class _PListRadioItemState<T> extends State<PListRadioItem<T>>
    with RadioClient<T> {
  FocusNode? _ownFocusNode;
  bool _groupEnabled = true;

  @override
  FocusNode get focusNode =>
      widget.focusNode ??
      (_ownFocusNode ??= FocusNode(
        debugLabel: 'PListRadioItem ${widget.title}',
      ));

  @override
  T get radioValue => widget.value;

  @override
  bool get tristate => false;

  // 화살표가 건너뛸 줄 — 이 줄 또는 묶음이 막혔다
  @override
  bool get enabled => widget.enabled && _groupEnabled && registry != null;

  bool get _selected =>
      registry != null && registry!.groupValue == widget.value;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    registry = RadioGroup.maybeOf<T>(context);
    _groupEnabled = _PListRadioGroupScope.enabledOf(context);
  }

  @override
  void dispose() {
    registry = null;
    _ownFocusNode?.dispose();
    super.dispose();
  }

  void _select() {
    // 이미 고른 줄을 다시 눌러도 풀리지 않는다
    if (_selected) return;
    registry?.onChanged(widget.value);
  }

  @override
  Widget build(BuildContext context) {
    assert(
      registry != null,
      'PListRadioItem 은 같은 값 타입(T)의 PListRadioGroup 안에서만 쓴다 — PListRadioItem<$T>',
    );
    final enabled = this.enabled;
    final selected = _selected;
    // iOS 의 VoiceOver 는 선택을 selected 로 읽는다 — 고르지 않은 줄은 "선택되지 않음" 을 덧붙인다(RawRadio 와 같다)
    final apple = switch (defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.macOS => true,
      _ => false,
    };
    final mark = _PressedMark(
      (pressed) => PRadiomark(
        checked: selected,
        size: PRadioSize.large,
        tone: widget.tone,
        enabled: enabled,
        pressed: pressed,
        // 줄이 이미 줄어든다 — 동그라미는 누름 색만
        scaleOnPress: false,
      ),
    );
    return PListRowFrame(
      title: widget.title,
      detail: widget.detail,
      detailChild: widget.detailChild,
      titleColor: widget.titleColor,
      titleSuffix: widget.titleSuffix,
      prefix: widget.markPosition == PListMarkPosition.prefix
          ? mark
          : widget.prefix,
      suffix: widget.markPosition == PListMarkPosition.suffix ? mark : null,
      highlighted: widget.highlighted,
      align: widget.align,
      interactive: true,
      onActivate: enabled ? _select : null,
      // 라디오 줄의 Enter 는 고르지 않는다(폼 제출에 둔다) — 고르기는 Space · 화살표
      activateOnEnter: false,
      focusNode: focusNode,
      semantics: PListRowSemantics(
        wholeRow: true,
        checked: selected,
        inMutuallyExclusiveGroup: true,
        selected: apple ? selected : null,
        hint: apple && !selected
            ? WidgetsLocalizations.of(context).radioButtonUnselectedLabel
            : null,
      ),
    );
  }
}

// ── 선 · 타일 · 뒤 붙이개 ────────────────────────────────────

/// 줄 사이 선(ListDivider) — 필요할 때만(기본은 선 없음 — 줄의 위아래 여백이 줄을 가른다). 1px · `stroke-neutral-subtle`.
/// 줄 폭 전체가 기본이고, 앞 붙이개가 있는 목록은 [inset] 으로 좌우 24 들인다. 장식이라 읽지 않는다(줄 수에 들지 않는다).
class PListDivider extends StatelessWidget {
  const PListDivider({super.key, this.inset = false});

  final bool inset;

  static const double thickness = 1;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        key: const ValueKey('plist-divider'),
        height: thickness,
        margin: inset
            ? const EdgeInsets.symmetric(horizontal: PSpacing.globalGutter)
            : null,
        color: context.colors.strokeNeutralSubtle,
      ),
    );
  }
}

/// 내용 줄의 앞 타일 — 40 · 모서리 12(크기 × 0.3) · 아이콘 20. 바탕 · 아이콘 색은 부르는 쪽이 카테고리 색
/// (`chart-{색}-weak` · `chart-{색}`)으로 준다 — 이체 줄은 회색(`chart-gray-weak` + `chart-gray`)이고, 아이콘이 없는
/// 카테고리는 태그 아이콘 하나로 그린다(빈 칸 · 첫 글자를 넣지 않는다). 막힌 줄 안에서는 바탕 · 아이콘이 비활성 색이다.
class PListTile extends StatelessWidget {
  const PListTile({
    super.key,
    required this.child,
    required this.background,
    required this.color,
  });

  /// 아이콘 — 크기 20 · 색은 타일이 입힌다.
  final Widget child;
  final Color background;
  final Color color;

  /// 타일의 한 변.
  static const double size = PSpacing.x10;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final disabled = PListRowScope.disabledOf(context);
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        key: const ValueKey('plist-tile'),
        decoration: BoxDecoration(
          color: disabled ? c.bgDisabled : background,
          borderRadius: BorderRadius.circular(PRounded.r3),
        ),
        child: Center(
          child: IconTheme(
            data: IconThemeData(
              size: PSpacing.x5,
              color: disabled ? c.fgDisabled : color,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
