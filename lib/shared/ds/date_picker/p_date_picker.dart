import 'dart:math' as math;

import 'package:flutter/rendering.dart' show SemanticsRole;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/date.dart'
    show fitWeekdayRowLabels, weekdayRowScaler;
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/chip/p_chip.dart';
import 'package:groo_damda_app/shared/ds/date_picker/date_picker_dates.dart';
import 'package:groo_damda_app/shared/ds/date_picker/p_date_picker_day.dart';
import 'package:groo_damda_app/shared/ds/focus_ring/p_focus_ring.dart'
    show keyboardHighlight;
import 'package:groo_damda_app/shared/ds/wheel_picker/p_wheel_picker.dart';

export 'package:groo_damda_app/shared/ds/date_picker/date_picker_dates.dart';
export 'package:groo_damda_app/shared/ds/date_picker/p_date_picker_day.dart';

/// 고르기 — 하루 · 기간 · 여러 날.
enum PDateSelection { single, range, multiple }

/// 보이는 범위 — 한 달(`month` — 하루 · 여러 날) · 달이 위아래로 이어진다(`continuous` — 시트의 기간).
/// 1280 이상 팝오버의 두 달 나란히(`twoMonths`)는 앱에 없다 — 앱은 시트로만 연다(팝오버 없음).
enum PDateVisibleRange { month, continuous }

// date-picker.yaml — 머리 · 요일 줄 · 날짜 줄은 최소 48(글이 크면 그만큼만 늘어난다, 03-C 1B), 이어지는 달: 달 이름 + 주 × 칸 +
// 아래 16, 아래 안개 96, 연 · 월 휠 자리 = 요일 줄 + 6주(100% 에서 336).
const double _monthGap = PSpacing.x4;
const double _fogHeight = 96;
const double _titleIcon = 20;
const int _weeks = 6;

/// Date Picker — 날짜 · 기간 · 여러 날을 고르는 달력. 구조는 SEED Date Picker(2026-10-03), 수치 원본은 groo-design
/// `specs/components/date-picker.yaml`(값은 `test/fixtures/design_spec/date-picker.json` — 테스트가 위젯이 그 값과 같은지
/// 본다). 웹(desk-front `src/shared/ds/date-picker`)과 같은 값 · 규칙이다.
///
///   [PDatePicker.single] — 하루(`DateTime`) · [PDatePicker.range] — 기간([PDateRange]) · [PDatePicker.multiple] — 여러 날
///
/// 값은 쓰는 쪽이 가진다(제어) — 달력은 고르던 값(draft)을 보이고 고르면 `onChanged` 로 알린다. "완료" 로 칸에 넣는 것은 쓰는
/// 쪽이다(input-button.md — 고르는 동안 칸 값은 그대로, 닫으면 버림). 날짜를 치는 칸은 두지 않는다. 날짜는 로컬 시간대의 그
/// 날 0시로 다룬다(시간은 보지 않는다).
///
/// 모양 — 날짜 칸은 높이 48 · 폭 = 달력 폭 ÷ 7, 칸 전체가 누르는 자리, 원 42(칸이 44 보다 좁으면 칸 폭 − 2) · 숫자 16 / 22 ·
/// 500. 달력 폭은 놓인 자리 폭에서 좌우 [inset](시트 24)을 뺀 폭이다 — 시트에서는 본문 좌우 여백을 빼고([PBottomSheetContent]
/// 의 `flushBody`) 이 부품이 둔다(빠른 기간 칩 줄이 화면 끝까지 가야 해서).
///
/// 보이는 범위
///   month       머리 48(왼쪽 연 · 월 제목 + 셰브론 20, 오른쪽 이전 · 다음 Button ghost 40) · 요일 줄 48 · 늘 6주(앞뒤 달 날짜를
///               흐리게 — 누르지 못한다). 제목을 누르면 요일 줄 · 날짜 자리에 연 | 월 휠(Wheel Picker medium 7칸, 연 120 오른쪽 ·
///               월 96 왼쪽 반복)이 뜨고 셰브론이 위로 돈다. 휠이 열린 동안 이전 · 다음은 막힌다. 다시 누르면 고른 달로 옮긴다
///   continuous  머리 · 휠이 없고 달이 위아래로 이어진다 — 요일 줄이 위에 붙고 달마다 왼쪽 달 이름 · 그 달의 주 수(앞뒤 달 날짜는
///               비운다) · 아래 16. 아래 끝 안개 96. 놓인 자리가 정한 높이를 채운다(높이가 있어야 한다 — 시트는 [sheetBodyHeight])
///
/// 빠른 기간(range) — 달력 위 칩 한 줄(Chip outlineStrong medium, 하나 고르기). 누르면 그 기간을 칠하고 시작이 든 달로 옮긴다.
/// 달력에서 날을 누르면 칩 고름이 풀린다. 고를 수 있는 범위 밖에 걸친 칩은 막는다(잘라서 넣지 않는다).
///
/// 읽기 — 달력은 표(table)·줄(row)·칸(cell)이고 칸 안에 이름 있는 버튼이 든다("2026년 10월 15일 목요일", 오늘은 끝에
/// ", 오늘", 고른 날 · 기간 사이는 선택됨, 막힌 날 · 읽기 전용은 비활성, 읽기 전용 시작일은 이름 끝에 말이 붙는다). 요일은
/// 열 머리(columnHeader), 앞뒤 달 숫자는 숨긴다. 보이는 달이 바뀌면 "2026년 11월" 을 읽는다.
///
/// 키보드(하드웨어 키보드 · 스위치 접근, 03-C 결정 4A) — 웹 WAI-ARIA Grid 와 같다. 날짜 하나만 Tab 순서에 들고 ← → 하루,
/// ↑ ↓ 한 주, Home · End 그 주의 일 · 토, PageUp · PageDown 한 달, Shift + PageUp · PageDown 한 해, Enter · Space 고름. 열 때
/// 초점은 고른 날(없으면 오늘)이고, 링은 키보드로 옮길 때만(`FocusHighlightMode.traditional`) 원 둘레 안쪽 2px 로 그린다.
/// 보이는 달 밖으로 옮기면 달이 따라 넘어가고(이어지는 달은 초점 날이 보이게 스크롤한다), 제목 · 이전 · 다음 · 휠로 달을 바꾸면
/// 그 달 1일이 다음 Tab 자리다.
class PDatePicker extends StatefulWidget {
  const PDatePicker.single({
    super.key,
    required this.labels,
    DateTime? value,
    ValueChanged<DateTime>? onChanged,
    this.visibleRange = PDateVisibleRange.month,
    this.min,
    this.max,
    this.isDateDisabled,
    this.yearRange,
    this.today,
    this.inset = PSpacing.globalGutter,
    this.semanticLabel,
    this.defaultWheelOpen = false,
  }) : selection = PDateSelection.single,
       singleValue = value,
       onSingle = onChanged,
       rangeValue = null,
       onRange = null,
       multipleValue = const [],
       onMultiple = null,
       presets = const [],
       readOnlyStart = false,
       maxSelectionCount = null;

  /// 기간 — 첫 탭이 시작, 시작 뒤의 날은 끝(같은 날이면 하루짜리), 시작 앞의 날은 새 시작(둘을 바꾸지 않는다), 완성된 뒤 누르면
  /// 새로 시작. [onChanged] 는 `{start}` 다음 `{start, end}`. [readOnlyStart] 면 시작은 그대로이고 시작 뒤의 날만 끝이 된다.
  const PDatePicker.range({
    super.key,
    required this.labels,
    PDateRange? value,
    ValueChanged<PDateRange>? onChanged,
    this.presets = const [],
    this.readOnlyStart = false,
    this.visibleRange = PDateVisibleRange.month,
    this.min,
    this.max,
    this.isDateDisabled,
    this.yearRange,
    this.today,
    this.inset = PSpacing.globalGutter,
    this.semanticLabel,
    this.defaultWheelOpen = false,
  }) : selection = PDateSelection.range,
       singleValue = null,
       onSingle = null,
       rangeValue = value,
       onRange = onChanged,
       multipleValue = const [],
       onMultiple = null,
       maxSelectionCount = null;

  /// 여러 날 — 누를 때마다 고르고 풀린다(늘 날짜 순 · 겹침 없음). [maxSelectionCount] 에 닿으면 고르지 않은 날이 막힌 날이 된다.
  const PDatePicker.multiple({
    super.key,
    required this.labels,
    List<DateTime> value = const [],
    ValueChanged<List<DateTime>>? onChanged,
    this.maxSelectionCount,
    this.visibleRange = PDateVisibleRange.month,
    this.min,
    this.max,
    this.isDateDisabled,
    this.yearRange,
    this.today,
    this.inset = PSpacing.globalGutter,
    this.semanticLabel,
    this.defaultWheelOpen = false,
  }) : selection = PDateSelection.multiple,
       singleValue = null,
       onSingle = null,
       rangeValue = null,
       onRange = null,
       multipleValue = value,
       onMultiple = onChanged,
       presets = const [],
       readOnlyStart = false;

  final PDateSelection selection;
  final DateTime? singleValue;
  final ValueChanged<DateTime>? onSingle;
  final PDateRange? rangeValue;
  final ValueChanged<PDateRange>? onRange;
  final List<DateTime> multipleValue;
  final ValueChanged<List<DateTime>>? onMultiple;

  /// 빠른 기간 칩 — 기간 달력 위. date-picker.md 의 한 벌에서 고른다.
  final List<PDatePreset> presets;

  /// 확정된 시작일 — 시작은 그대로, 시작 뒤의 날만 끝이 된다(진행 중인 기간 늘리기).
  final bool readOnlyStart;
  final int? maxSelectionCount;
  final PDateVisibleRange visibleRange;

  /// 고를 수 있는 첫날 · 마지막 날 — 그 밖은 막힌 날. 그 날 단위로 비교한다(시각은 보지 않는다).
  final DateTime? min;
  final DateTime? max;

  /// 그 밖의 막힌 날.
  final bool Function(DateTime date)? isDateDisabled;

  /// 옮기고 고를 수 있는 연도(양끝 포함) — 기본 오늘 ± 100년.
  final ({int start, int end})? yearRange;

  /// 오늘 — 기본 지금(테스트 · 견본에서 맞출 때).
  final DateTime? today;

  /// 달력 좌우 여백 — 시트 24. 놓인 자리 폭에서 이만큼씩 빼고 달력을 그린다(칩 줄만 화면 끝까지).
  final double inset;
  final PDatePickerLabels labels;

  /// 달력의 이름(웹 aria-label) — 칸 라벨. 없으면 [PDatePickerLabels.root].
  final String? semanticLabel;

  /// 연 · 월 휠이 열린 채 시작한다(견본 · 테스트 전용 — 스펙의 모양이 아니라 처음 상태만 정한다).
  final bool defaultWheelOpen;

  /// 시트 본문의 높이 — 이어지는 달을 [PBottomSheet] 에 넣을 때 본문 높이로 준다. 시트는 화면 높이의 90% 이고, 머리(위 24 ·
  /// 제목 30 · 아래 16)와 바닥(위 12 · 버튼 48 · 아래 16)과 안전 영역을 뺀 자리다.
  ///
  /// 시트가 낮아(320 보다 좁은 화면에서 바닥 버튼이 위아래로 쌓일 때 · 낮은 화면 · 큰 글자) 이어지는 달이 요일 줄 + 2주보다
  /// 낮아지면 그 높이에서 멈춘다 — 빠른 기간 칩 줄 + 요일 줄 + 2주([sheetBodyMinHeight]). 시트 본문이 스크롤하고 머리 · 바닥은
  /// 그대로 보인다(date-picker.md Visible Range · Layout "지원 폭").
  static double sheetBodyHeight(BuildContext context) {
    final media = MediaQuery.of(context);
    const header = PSpacing.x6 + 30 + PSpacing.x4;
    const footer = PSpacing.x3 + 48 + PSpacing.x4;
    final safeBottom = math.max(
      0.0,
      media.viewPadding.bottom - media.viewInsets.bottom,
    );
    return math.max(
      sheetBodyMinHeight(media.textScaler),
      media.size.height * 0.9 - header - footer - safeBottom,
    );
  }

  /// 시트 본문이 멈추는 높이 — 빠른 기간 칩 줄(칩 medium + 아래 12) + 요일 줄 + 2주. 글자 배율을 따라 칩 · 요일 줄 · 칸이
  /// 커지는 만큼 커진다. 빠른 기간이 없는 달력(하루)도 같은 값이다 — 그때는 2주보다 조금 더 남는다.
  static double sheetBodyMinHeight(TextScaler scaler) =>
      chipHeight(PChipSize.medium, scaler) +
      PSpacing.x3 +
      datePickerRowHeight(weekdayRowScaler(scaler), lineHeight: 19) +
      2 * datePickerCellHeight(scaler);

  @override
  State<PDatePicker> createState() => _PDatePickerState();
}

class _PDatePickerState extends State<PDatePicker> {
  late final DateTime _autoToday = startOfDay(DateTime.now());
  late DateTime _view;

  // 키보드 — 날짜 하나만 Tab 순서에 든다(격자 전체가 초점 하나, 어느 날인지는 _focusDate)
  late DateTime _focusDate;
  final FocusNode _gridFocus = FocusNode(debugLabel: 'PDatePicker grid');
  bool _revealing = false;
  bool _wheelOpen = false;
  late int _wheelYear;
  late int _wheelMonth;
  PDatePreset? _presetPick;

  // 이어지는 달 — 달마다 높이 · 위치(달이 몇 주인지로 정해져 있다)
  ScrollController? _scroll;
  List<double> _heights = const [];
  List<double> _offsets = const [];
  ({int start, int end})? _layoutYears;
  double _cellH = kDatePickerCellHeight;
  double _labelH = kDatePickerCellHeight;

  DateTime get _today =>
      widget.today == null ? _autoToday : startOfDay(widget.today!);
  int get _yearStart => widget.yearRange?.start ?? _today.year - 100;
  int get _yearEnd => widget.yearRange?.end ?? _today.year + 100;
  DateTime get _firstDay => DateTime(_yearStart);
  DateTime get _lastDay => DateTime(_yearEnd, 12, 31);
  int get _firstMonth => _yearStart * 12;
  int get _lastViewMonth => _yearEnd * 12 + 11;
  bool get _continuous => widget.visibleRange == PDateVisibleRange.continuous;

  DateTime _clampView(DateTime d) =>
      fromMonthNumber(monthNumber(d).clamp(_firstMonth, _lastViewMonth));

  // ── 값 — 안에서는 한 꼴로 ──
  DateTime? get _single =>
      widget.singleValue == null ? null : startOfDay(widget.singleValue!);
  DateTime? get _rangeStart => widget.rangeValue?.start == null
      ? null
      : startOfDay(widget.rangeValue!.start!);
  DateTime? get _rangeEnd =>
      widget.rangeValue?.end == null || _rangeStart == null
      ? null
      : startOfDay(widget.rangeValue!.end!);
  List<DateTime> get _multiple {
    final list = widget.multipleValue.map(startOfDay).toList()
      ..sort(compareDay);
    final out = <DateTime>[];
    for (final d in list) {
      if (out.isEmpty || !sameDay(out.last, d)) out.add(d);
    }
    return out;
  }

  bool get _readOnlyStartActive =>
      widget.selection == PDateSelection.range &&
      widget.readOnlyStart &&
      _rangeStart != null;
  bool get _maxReached =>
      widget.selection == PDateSelection.multiple &&
      widget.maxSelectionCount != null &&
      _multiple.length >= widget.maxSelectionCount!;

  DateTime? get _anchor => switch (widget.selection) {
    PDateSelection.single => _single,
    PDateSelection.range => _rangeStart,
    PDateSelection.multiple => _multiple.isEmpty ? null : _multiple.first,
  };

  @override
  void initState() {
    super.initState();
    _view = _clampView(monthStart(_anchor ?? _today));
    _focusDate = clampDay(_anchor ?? _today, _firstDay, _lastDay);
    _wheelYear = _view.year;
    _wheelMonth = _view.month;
    _wheelOpen = widget.defaultWheelOpen && !_continuous;
    _presetPick = _presetMatching();
    _gridFocus.addListener(_onGridFocus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncContinuous();
  }

  @override
  void didUpdateWidget(PDatePicker old) {
    super.didUpdateWidget(old);
    _syncContinuous();
  }

  // 이어지는 달이면 달 위치를 글자 배율로 재고 스크롤을 만든다(글이 커지면 칸 · 달 이름 줄이 커진다)
  void _syncContinuous() {
    if (_continuous) {
      final changed = _ensureLayout(MediaQuery.textScalerOf(context));
      if (_scroll == null) {
        _scroll = ScrollController(initialScrollOffset: _offsetOf(_view))
          ..addListener(_onScroll);
      } else if (changed) {
        // 배율이 바뀌었다 — 보던 달을 다시 맨 위로(빌드 중에는 스크롤을 건드리지 않는다)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final c = _scroll;
          if (!mounted || c == null || !c.hasClients) return;
          _revealing = true;
          c.jumpTo(math.min(_offsetOf(_view), c.position.maxScrollExtent));
          _revealing = false;
        });
      }
    } else if (_scroll != null) {
      _scroll!.dispose();
      _scroll = null;
    }
  }

  @override
  void dispose() {
    _gridFocus.removeListener(_onGridFocus);
    _gridFocus.dispose();
    _scroll?.dispose();
    super.dispose();
  }

  void _onGridFocus() {
    if (mounted) setState(() {});
  }

  // ── 이어지는 달: 달 위치 ──
  bool _ensureLayout(TextScaler scaler) {
    final years = (start: _yearStart, end: _yearEnd);
    final cell = datePickerCellHeight(scaler);
    final label = datePickerRowHeight(scaler);
    if (_layoutYears == years && _cellH == cell && _labelH == label) {
      return false;
    }
    _layoutYears = years;
    _cellH = cell;
    _labelH = label;
    final count = (years.end - years.start + 1) * 12;
    final heights = <double>[];
    final offsets = <double>[];
    var total = 0.0;
    for (var i = 0; i < count; i++) {
      final d = fromMonthNumber(_firstMonth + i);
      final h = label + weeksInMonth(d.year, d.month) * cell + _monthGap;
      offsets.add(total);
      heights.add(h);
      total += h;
    }
    _heights = heights;
    _offsets = offsets;
    return true;
  }

  double _offsetOf(DateTime d) {
    final i = monthNumber(d) - _firstMonth;
    return i >= 0 && i < _offsets.length ? _offsets[i] : 0;
  }

  void _onScroll() {
    final c = _scroll;
    if (c == null || !c.hasClients) return;
    final index = monthAt(_offsets, _heights, c.offset);
    final month = fromMonthNumber(_firstMonth + index);
    if (monthNumber(month) != monthNumber(_view)) {
      setState(() {
        _view = month;
        if (!_revealing) _alignFocus();
      });
    }
  }

  // 보이는 달이 바뀌면(스크롤 · 이전 · 다음 · 휠 · 빠른 기간) 그 달 1일이 다음 Tab 자리다. 키보드로 옮긴 것은 건드리지 않는다
  void _alignFocus() {
    if (monthNumber(_focusDate) != monthNumber(_view)) {
      _focusDate = clampDay(_view, _firstDay, _lastDay);
    }
  }

  // 보이는 달을 바꾼다 — 이어지는 달이면 그 달을 맨 위로
  void _showMonth(DateTime month) {
    final next = _clampView(month);
    setState(() {
      _view = next;
      _alignFocus();
    });
    final c = _scroll;
    if (_continuous && c != null && c.hasClients) {
      c.jumpTo(math.min(_offsetOf(next), c.position.maxScrollExtent));
    }
  }

  // ── 고를 수 없는 날 ──
  bool _isDisabled(DateTime d) =>
      compareDay(d, _firstDay) < 0 ||
      compareDay(d, _lastDay) > 0 ||
      (widget.min != null && compareDay(d, startOfDay(widget.min!)) < 0) ||
      (widget.max != null && compareDay(d, startOfDay(widget.max!)) > 0) ||
      (widget.isDateDisabled?.call(d) ?? false) ||
      (_readOnlyStartActive && compareDay(d, _rangeStart!) < 0) ||
      (_maxReached && !_multiple.any((x) => sameDay(x, d)));

  PDatePickerDayState _cellState(DateTime d) {
    final complete = _rangeStart != null && _rangeEnd != null;
    var selected = false;
    var isStart = false;
    var isEnd = false;
    var inRange = false;
    switch (widget.selection) {
      case PDateSelection.single:
        selected = sameDay(d, _single);
      case PDateSelection.multiple:
        selected = _multiple.any((x) => sameDay(x, d));
      case PDateSelection.range:
        final start = _rangeStart;
        if (start != null) {
          isStart = sameDay(d, start);
          isEnd = sameDay(d, _rangeEnd);
          inRange =
              complete &&
              compareDay(d, start) > 0 &&
              compareDay(d, _rangeEnd!) < 0;
          selected = isStart || isEnd;
        }
    }
    return PDatePickerDayState(
      today: sameDay(d, _today),
      selected: selected,
      rangeStart: isStart,
      rangeEnd: isEnd,
      inRange: inRange,
      complete: complete,
      singleDayRange: complete && sameDay(_rangeStart, _rangeEnd),
      disabled: _isDisabled(d),
      readOnly: _readOnlyStartActive && isStart,
    );
  }

  void _selectDate(DateTime d) {
    final state = _cellState(d);
    if (state.disabled || state.readOnly) return;
    setState(() => _presetPick = null);
    switch (widget.selection) {
      case PDateSelection.single:
        if (!sameDay(d, _single)) widget.onSingle?.call(d);
      case PDateSelection.multiple:
        final list = _multiple;
        final exists = list.any((x) => sameDay(x, d));
        widget.onMultiple?.call(
          exists
              ? [
                  for (final x in list)
                    if (!sameDay(x, d)) x,
                ]
              : ([...list, d]..sort(compareDay)),
        );
      case PDateSelection.range:
        final start = _rangeStart;
        final end = _rangeEnd;
        if (_readOnlyStartActive && start != null) {
          if (compareDay(d, start) <= 0 || sameDay(d, end)) return;
          widget.onRange?.call(PDateRange(start: start, end: d));
        } else if (start == null || end != null) {
          widget.onRange?.call(PDateRange(start: d));
        } else if (compareDay(d, start) < 0) {
          widget.onRange?.call(PDateRange(start: d));
        } else {
          widget.onRange?.call(PDateRange(start: start, end: d));
        }
    }
  }

  // ── 빠른 기간 ──
  bool _presetAvailable(PDatePreset name) {
    final r = getPresetRange(name, _today);
    if (compareDay(r.start, _firstDay) < 0 || compareDay(r.end, _lastDay) > 0) {
      return false;
    }
    if ((widget.min != null &&
            compareDay(r.start, startOfDay(widget.min!)) < 0) ||
        (widget.max != null &&
            compareDay(r.end, startOfDay(widget.max!)) > 0)) {
      return false;
    }
    if ((widget.isDateDisabled?.call(r.start) ?? false) ||
        (widget.isDateDisabled?.call(r.end) ?? false)) {
      return false;
    }
    if (_readOnlyStartActive && !sameDay(r.start, _rangeStart)) return false;
    return true;
  }

  bool _presetMatches(PDatePreset name) {
    final r = getPresetRange(name, _today);
    return sameDay(r.start, _rangeStart) && sameDay(r.end, _rangeEnd);
  }

  PDatePreset? _presetMatching() {
    for (final p in widget.presets) {
      if (_presetMatches(p)) return p;
    }
    return null;
  }

  // 고른 칩은 값이 그 범위일 때만 — 초기화 등으로 값이 바뀌면 풀린다
  PDatePreset? get _activePreset {
    final pick = _presetPick;
    return pick != null && _presetMatches(pick) ? pick : null;
  }

  void _choosePreset(PDatePreset name) {
    if (!widget.presets.contains(name)) return;
    final r = getPresetRange(name, _today);
    setState(() => _presetPick = name);
    widget.onRange?.call(PDateRange(start: r.start, end: r.end));
    // 시작이 든 달로
    _showMonth(monthStart(r.start));
  }

  // ── 연 · 월 휠 — 열 때 지금 달에서, 닫을 때 고른 달로 옮긴다 ──
  void _toggleWheel() {
    if (!_wheelOpen) {
      setState(() {
        _wheelYear = _view.year;
        _wheelMonth = _view.month;
        _wheelOpen = true;
      });
      return;
    }
    final picked = _clampView(DateTime(_wheelYear, _wheelMonth));
    setState(() {
      _wheelOpen = false;
      _view = picked;
      _alignFocus();
    });
  }

  void _step(int dir) {
    setState(() {
      _view = _clampView(fromMonthNumber(monthNumber(_view) + dir));
      _alignFocus();
    });
  }

  // ── 키보드(WAI-ARIA Grid) ──
  KeyEventResult _onGridKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final hw = HardwareKeyboard.instance;
    if (hw.isAltPressed || hw.isControlPressed || hw.isMetaPressed) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final shift = hw.isShiftPressed;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final d = _focusDate;

    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.space) {
      if (event is KeyDownEvent) _selectDate(d);
      return KeyEventResult.handled;
    }
    DateTime? next;
    if (key == LogicalKeyboardKey.pageUp ||
        key == LogicalKeyboardKey.pageDown) {
      final dir = key == LogicalKeyboardKey.pageUp ? -1 : 1;
      next = addMonths(d, shift ? dir * 12 : dir);
    } else if (shift) {
      return KeyEventResult.ignored;
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      next = addDays(d, rtl ? 1 : -1);
    } else if (key == LogicalKeyboardKey.arrowRight) {
      next = addDays(d, rtl ? -1 : 1);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      next = addDays(d, -7);
    } else if (key == LogicalKeyboardKey.arrowDown) {
      next = addDays(d, 7);
    } else if (key == LogicalKeyboardKey.home) {
      next = weekStart(d);
    } else if (key == LogicalKeyboardKey.end) {
      next = weekEnd(d);
    } else {
      return KeyEventResult.ignored;
    }
    _moveFocus(next);
    return KeyEventResult.handled;
  }

  // 초점 날을 옮긴다 — 고를 수 있는 연도 안에서, 보이는 달 밖이면 달이 따라 넘어간다(이어지는 달은 스크롤)
  void _moveFocus(DateTime to) {
    final next = clampDay(to, _firstDay, _lastDay);
    setState(() {
      _focusDate = next;
      if (!_continuous && monthNumber(next) != monthNumber(_view)) {
        _view = _clampView(monthStart(next));
      }
    });
    if (_continuous) _reveal(next);
  }

  // 이어지는 달에서 초점 날이 보이게 — 안개 밖까지만 올린다
  void _reveal(DateTime d) {
    final c = _scroll;
    if (c == null || !c.hasClients) return;
    final i = monthNumber(d) - _firstMonth;
    if (i < 0 || i >= _offsets.length) return;
    final week = (weekdayIndex(DateTime(d.year, d.month)) + d.day - 1) ~/ 7;
    final top = _offsets[i] + _labelH + week * _cellH;
    final bottom = top + _cellH;
    final viewport = c.position.viewportDimension;
    final usable = viewport > _fogHeight + 2 * _cellH
        ? viewport - _fogHeight
        : viewport;
    var target = c.offset;
    if (top < c.offset) {
      target = top;
    } else if (bottom > c.offset + usable) {
      target = bottom - usable;
    }
    if (target == c.offset) return;
    _revealing = true;
    c.jumpTo(target.clamp(0.0, c.position.maxScrollExtent));
    _revealing = false;
  }

  // ── 그리기 ──
  Widget _weekdayRow(double cellW) {
    final c = context.colors;
    final l = widget.labels;
    // 요일 글은 글자 크기 200% 에서 멈춘다(날짜 숫자도 같다 — groo-design #258, 제목은 그 위로도 커진다)
    final scaler = weekdayRowScaler(MediaQuery.textScalerOf(context));
    final style = PTypography.t4.copyWith(
      color: c.fgNeutralSubtle,
      fontWeight: FontWeight.w500,
    );
    // 영어 두 글자가 칸에 들지 않는 폭 · 글자 크기에서만 한 글자로 — 요일 글은 줄을 바꾸지 않는다
    final labels = fitWeekdayRowLabels(
      cellW,
      style,
      scaler,
      labels: l.weekdays,
      narrow: l.weekdaysNarrow ?? l.weekdays,
    );
    return Semantics(
      container: true,
      explicitChildNodes: true,
      role: SemanticsRole.row,
      child: SizedBox(
        key: const ValueKey('date-weekdays'),
        height: datePickerRowHeight(scaler, lineHeight: 19),
        child: Row(
          children: [
            for (var i = 0; i < 7; i++)
              Semantics(
                container: true,
                role: SemanticsRole.columnHeader,
                label: l.weekdaysLong[i],
                excludeSemantics: true,
                child: SizedBox(
                  width: cellW,
                  child: Center(
                    child: Text(
                      labels[i],
                      maxLines: 1,
                      softWrap: false,
                      textScaler: scaler,
                      style: style,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 한 달 — fixed 는 늘 6주(앞뒤 달은 흐리게), natural 은 그 달의 주 수(앞뒤 달은 비운다)
  Widget _grid(
    DateTime month,
    double cellW, {
    required bool fixed,
    Widget? weekdays,
  }) {
    final y = month.year;
    final m = month.month;
    final first = weekStart(DateTime(y, m));
    final weeks = fixed ? _weeks : weeksInMonth(y, m);
    final label = widget.labels.month(y, m);
    final ringOn = _gridFocus.hasFocus && keyboardHighlight();
    return Semantics(
      container: true,
      explicitChildNodes: true,
      role: SemanticsRole.table,
      label: label,
      child: Column(
        children: [
          ?weekdays,
          Column(
            key: ValueKey('date-grid-$y-${pad2(m)}'),
            children: [
              for (var w = 0; w < weeks; w++)
                Semantics(
                  container: true,
                  explicitChildNodes: true,
                  role: SemanticsRole.row,
                  child: Row(
                    children: [
                      for (var i = 0; i < 7; i++)
                        Builder(
                          builder: (context) {
                            final d = addDays(first, w * 7 + i);
                            if (d.month != m) {
                              return PDatePickerOutsideCell(
                                key: ValueKey('date-outside-${dayKey(d)}'),
                                date: d,
                                width: cellW,
                                show: fixed,
                              );
                            }
                            final s = _cellState(d);
                            var name = s.readOnly
                                ? '${widget.labels.day(d)}, '
                                      '${widget.labels.readOnlyRangeStart}'
                                : widget.labels.day(d);
                            if (s.today) name = '$name, ${widget.labels.today}';
                            final cell = PDatePickerDayCell(
                              key: ValueKey('date-${dayKey(d)}'),
                              date: d,
                              state: s,
                              label: name,
                              width: cellW,
                              focused: ringOn && sameDay(d, _focusDate),
                              onTap: () {
                                // 눌러도 키보드가 이어진다 — 그 날이 초점 자리(링은 터치 모드에서 그리지 않는다)
                                setState(() => _focusDate = d);
                                _gridFocus.requestFocus();
                                _selectDate(d);
                              },
                            );
                            // 격자의 칸(cell) 안에 이름 있는 버튼 — 표(table) · 줄(row) · 칸(cell)로 읽힌다
                            return Semantics(
                              container: true,
                              explicitChildNodes: true,
                              role: SemanticsRole.cell,
                              child: cell,
                            );
                          },
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget? _presetRow() {
    if (widget.presets.isEmpty || widget.selection != PDateSelection.range) {
      return null;
    }
    final l = widget.labels;
    final active = _activePreset;
    return PChipRadioGroup<PDatePreset>(
      semanticLabel: l.presets,
      layout: _continuous ? PChipGroupLayout.scroll : PChipGroupLayout.wrap,
      value: active,
      onChanged: _choosePreset,
      children: [
        for (final name in widget.presets)
          PChipRadio<PDatePreset>(
            value: name,
            label: l.presetNames[name]!,
            variant: PChipVariant.outlineStrong,
            size: PChipSize.medium,
            enabled: _presetAvailable(name),
          ),
      ],
    );
  }

  Widget _monthBody() {
    final c = context.colors;
    final l = widget.labels;
    final viewNumber = monthNumber(_view);
    final canPrev = !_wheelOpen && viewNumber > _firstMonth;
    final canNext = !_wheelOpen && viewNumber < _lastViewMonth;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final title = l.month(_view.year, _view.month);
    final scaler = MediaQuery.textScalerOf(context);
    // 요일 줄은 글자 크기 200% 에서 멈춘다 — 줄 높이도 멈춘 글로 잰다
    final weekdayH = datePickerRowHeight(
      weekdayRowScaler(scaler),
      lineHeight: 19,
    );
    final cellH = datePickerCellHeight(scaler);

    final header = SizedBox(
      key: const ValueKey('date-header'),
      height: datePickerRowHeight(scaler),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Semantics(
                button: true,
                expanded: _wheelOpen,
                liveRegion: true,
                label: title,
                onTap: _toggleWheel,
                excludeSemantics: true,
                child: GestureDetector(
                  key: const ValueKey('date-title'),
                  behavior: HitTestBehavior.opaque,
                  onTap: _toggleWheel,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: PSpacing.x1),
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: PTypography.t5.copyWith(
                            color: c.fgNeutral,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: PSpacing.x1),
                      AnimatedRotation(
                        key: const ValueKey('date-title-icon'),
                        turns: _wheelOpen ? 0.5 : 0,
                        duration: reduceMotion ? Duration.zero : PDuration.d3,
                        curve: PEasing.easing,
                        child: Icon(
                          LucideIcons.chevronDown,
                          size: _titleIcon,
                          color: c.fgNeutral,
                        ),
                      ),
                      const SizedBox(width: PSpacing.x1),
                    ],
                  ),
                ),
              ),
            ),
          ),
          PButton.icon(
            icon: LucideIcons.chevronLeft,
            semanticLabel: l.previousMonth,
            variant: PButtonVariant.ghost,
            size: PButtonSize.medium,
            onPressed: canPrev ? () => _step(-1) : null,
          ),
          PButton.icon(
            icon: LucideIcons.chevronRight,
            semanticLabel: l.nextMonth,
            variant: PButtonVariant.ghost,
            size: PButtonSize.medium,
            onPressed: canNext ? () => _step(1) : null,
          ),
        ],
      ),
    );

    Widget area;
    if (_wheelOpen) {
      final years = [
        for (var y = _yearStart; y <= _yearEnd; y++)
          PWheelPickerOption<int>(value: y, label: l.yearOption(y)),
      ];
      final months = [
        for (var m = 1; m <= 12; m++)
          PWheelPickerOption<int>(value: m, label: l.monthOption(m)),
      ];
      area = SizedBox(
        key: const ValueKey('date-wheel'),
        height: weekdayH + _weeks * cellH,
        child: Center(
          child: PWheelPicker(
            semanticLabel: l.month(_wheelYear, _wheelMonth),
            visibleItems: 7,
            children: [
              PWheelPickerColumn<int>(
                semanticLabel: l.yearWheel,
                options: years,
                value: _wheelYear,
                align: PWheelPickerAlign.right,
                width: 120,
                onChanged: (value, _) => setState(() => _wheelYear = value),
              ),
              PWheelPickerColumn<int>(
                semanticLabel: l.monthWheel,
                options: months,
                value: _wheelMonth,
                align: PWheelPickerAlign.left,
                width: 96,
                loop: true,
                onChanged: (value, _) => setState(() => _wheelMonth = value),
              ),
            ],
          ),
        ),
      );
    } else {
      area = LayoutBuilder(
        builder: (context, constraints) {
          final cellW = constraints.maxWidth / 7;
          return Focus(
            focusNode: _gridFocus,
            autofocus: true,
            onKeyEvent: _onGridKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _grid(_view, cellW, fixed: true, weekdays: _weekdayRow(cellW)),
              ],
            ),
          );
        },
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: widget.inset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [header, area],
      ),
    );
  }

  Widget _continuousBody() {
    final c = context.colors;
    final l = widget.labels;
    final fade = context.gradients.fadeMask;
    final fog = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        for (final color in fade.colors)
          c.bgLayerFloating.withValues(alpha: c.bgLayerFloating.a * color.a),
      ],
      stops: fade.stops,
    );
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellW = (constraints.maxWidth - 2 * widget.inset) / 7;
          return Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: widget.inset),
                    // 이어지는 달은 요일 줄이 달 밖에 붙는다 — 줄 하나짜리 표
                    child: Semantics(
                      container: true,
                      explicitChildNodes: true,
                      role: SemanticsRole.table,
                      child: _weekdayRow(cellW),
                    ),
                  ),
                  Expanded(
                    child: Focus(
                      focusNode: _gridFocus,
                      autofocus: true,
                      onKeyEvent: _onGridKey,
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(
                          context,
                        ).copyWith(scrollbars: false),
                        child: ListView.builder(
                          key: const ValueKey('date-scroll'),
                          controller: _scroll,
                          padding: EdgeInsets.zero,
                          physics: const ClampingScrollPhysics(),
                          itemCount: _heights.length,
                          itemExtentBuilder: (index, _) => _heights[index],
                          itemBuilder: (context, index) {
                            final month = fromMonthNumber(_firstMonth + index);
                            return _ContinuousMonth(
                              key: ValueKey('date-month-${monthNumber(month)}'),
                              inset: widget.inset,
                              title: l.month(month.year, month.month),
                              grid: _grid(month, cellW, fixed: false),
                              labelHeight: _labelH,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: _fogHeight,
                child: IgnorePointer(
                  child: DecoratedBox(
                    key: const ValueKey('date-fog'),
                    decoration: BoxDecoration(gradient: fog),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final presets = _presetRow();
    final presetBox = presets == null
        ? null
        : Padding(
            padding: EdgeInsets.only(
              bottom: PSpacing.x3,
              left: _continuous ? 0 : widget.inset,
              right: _continuous ? 0 : widget.inset,
            ),
            child: presets,
          );
    final live = _continuous
        ? Semantics(
            liveRegion: true,
            label: widget.labels.month(_view.year, _view.month),
            child: const SizedBox.shrink(),
          )
        : null;

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: widget.semanticLabel ?? widget.labels.root,
      child: ColoredBox(
        key: const ValueKey('date-root'),
        color: c.bgLayerFloating,
        child: Column(
          mainAxisSize: _continuous ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ?live,
            ?presetBox,
            if (_continuous) _continuousBody() else _monthBody(),
          ],
        ),
      ),
    );
  }
}

/// 이어지는 달의 한 달 — 왼쪽 달 이름 48(좌우 4) · 그 달의 주 · 아래 16.
class _ContinuousMonth extends StatelessWidget {
  const _ContinuousMonth({
    super.key,
    required this.inset,
    required this.title,
    required this.grid,
    required this.labelHeight,
  });

  final double inset;
  final String title;
  final Widget grid;

  /// 달 이름 줄 높이 — 최소 48, 글자 배율에 따라 커진다.
  final double labelHeight;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: EdgeInsets.fromLTRB(inset, 0, inset, _monthGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            key: const ValueKey('date-month-label'),
            height: labelHeight,
            padding: const EdgeInsets.symmetric(horizontal: PSpacing.x1),
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              maxLines: 1,
              softWrap: false,
              style: PTypography.t5.copyWith(
                color: c.fgNeutral,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          grid,
        ],
      ),
    );
  }
}
