import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/l10n/ds_l10n.dart';
import 'package:groo_damda_app/shared/ds/wheel_picker/p_wheel_picker.dart';

/// 시각 — 24시간 시(0 ~ 23) · 분(0 ~ 59). 화면은 12시간이고 값은 24시간이다.
@immutable
class PTimeValue {
  const PTimeValue(this.hour, this.minute);

  /// 지금 시각 — 초는 버린다.
  factory PTimeValue.fromDateTime(DateTime d) => PTimeValue(d.hour, d.minute);

  final int hour;
  final int minute;

  @override
  bool operator ==(Object other) =>
      other is PTimeValue && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() => 'PTimeValue($hour:${minute.toString().padLeft(2, '0')})';
}

/// 분 간격 — 기본 5. 분이 중요한 자리(방해 금지 · 알림)는 1, 느슨한 자리 10 · 15, 근무 · 일정 시간표 30.
const List<int> pMinuteSteps = [1, 5, 10, 15, 30];

/// 글 한 벌 — 문자열은 호출하는 쪽이 넘긴다(앱 언어). [PTimePickerLabels.ko] 는 한국어 한 벌(카탈로그 · 테스트).
@immutable
class PTimePickerLabels {
  const PTimePickerLabels({
    required this.root,
    required this.period,
    required this.hour,
    required this.minute,
    required this.am,
    required this.pm,
  });

  /// 휠 이름 — 칸 라벨이 없을 때("시간 선택").
  final String root;
  final String period;
  final String hour;
  final String minute;
  final String am;
  final String pm;

  /// 지금 로케일의 한 벌 — 로케일이 없는 호스트에서는 한국어([ko]).
  factory PTimePickerLabels.of(BuildContext context) {
    final l = dsL(context);
    if (l == null) return ko;
    return PTimePickerLabels(
      root: l.dsTimeTitle,
      period: l.dsTimePeriod,
      hour: l.dsTimeHour,
      minute: l.dsTimeMinute,
      am: l.dsTimeAm,
      pm: l.dsTimePm,
    );
  }

  static const PTimePickerLabels ko = PTimePickerLabels(
    root: '시간 선택',
    period: '오전/오후',
    hour: '시',
    minute: '분',
    am: '오전',
    pm: '오후',
  );
}

String _pad2(int n) => n.toString().padLeft(2, '0');

/// 분 간격에 맞춰 반올림한다 — 시각 전체 기준(9시 58분 → 10시 00분). 하루를 넘으면 0시로 돈다(23시 58분 → 0시 00분).
PTimeValue roundTimeToStep(PTimeValue time, int step) {
  if (time.minute % step == 0 && time.hour >= 0 && time.hour < 24) return time;
  final total = time.hour * 60 + time.minute;
  final rounded = (((total / step).round() * step) % 1440 + 1440) % 1440;
  return PTimeValue(rounded ~/ 60, rounded % 60);
}

/// [DateTime] 을 분 간격에 맞춰 반올림한다 — 초는 버리고 분으로 셈한다. 하루를 넘으면 다음 날 0시다(날짜 · 시각을 같이 받는 자리).
DateTime roundDateTimeToStep(DateTime d, int step) {
  final total = d.hour * 60 + d.minute;
  final rounded = (total / step).round() * step;
  return DateTime(d.year, d.month, d.day, 0, rounded);
}

/// 칸에 넣는 글 — "오후 3:00"(International Design v106 — 오전 · 오후 12시간, 초 없음). 비었으면 "".
String formatTimeValue(
  PTimeValue? value, {
  PTimePickerLabels labels = PTimePickerLabels.ko,
}) {
  if (value == null) return '';
  final h = value.hour % 12 == 0 ? 12 : value.hour % 12;
  return '${value.hour < 12 ? labels.am : labels.pm} $h:${_pad2(value.minute)}';
}

/// Time Picker — 시각을 고르는 12시간 휠(오전·오후 → 시 → 분). 구조는 SEED Time Picker(2026-10-03), 수치 원본은
/// groo-design `specs/components/time-picker.yaml`(값은 `test/fixtures/design_spec/time-picker.json` — 휠의 크기 · 색 ·
/// 띠 · 안개는 wheel-picker.yaml medium · 5칸). 웹(desk-front `src/shared/ds/time-picker`)과 같은 값 · 규칙이다.
///
/// 값은 쓰는 쪽이 가진다(제어) — [value] 는 24시간 [PTimeValue]. 휠이 멈춘 뒤 [onChanged] 가 불린다(굴리는 동안 칸 값은 그대로
/// — 쓰는 쪽이 draft 에 받고 "완료" 로 칸에 넣는다, input-button.md). [value] 를 주지 않으면 이 부품이 쥐고 따라간다.
///
/// 칼럼(Wheel Picker medium × 5 — 220)
///   오전·오후   두 칸에서 멈춘다(반복 없음), 가운데 정렬. 바깥에서 바뀌면(시 11 ↔ 12) 부드럽게 따라간다
///   시          1 · 2 … 12(0 을 채우지 않는다), 반복, 오른쪽 정렬 — 한 자리 · 두 자리 수의 끝을 맞춘다
///   분          두 자리(00 · 05 …), 분 간격의 분만, 반복, 가운데 정렬
/// 시 · 분 글자는 쓰지 않는다 — 단위는 칼럼 이름("오전/오후" · "시" · "분")과 자리가 알린다("오후 3 00" = 오후 3시 00분).
///
/// 값 규칙(time-picker.md)
///   - 시 휠이 11 ↔ 12 를 넘으면 오전 · 오후가 따라 바뀐다 — 시 칼럼이 멈춘 자리까지 움직인 칸 수(stepDelta)만큼 24시간 값에
///     시를 더한다(오전 11 + 1칸 = 오후 12, 오후 11 + 1칸 = 오전 12)
///   - 분 휠은 55 → 00 을 넘어도 시는 그대로다(10시 55분 → 10시 00분)
///   - 오전 · 오후를 바꾸면 시 · 분은 그대로 12시간을 더하거나 뺀다
///   - 분 간격에 맞지 않는 값은 가장 가까운 칸으로 반올림해 보인다(시각 전체 기준 — 23시 58분은 0시 00분). 그것만으로
///     [onChanged] 를 부르지는 않는다
///   - [value] 가 비었으면 지금([now])을 분 간격에 맞춰 반올림한 자리를 짚기만 한다(고른 것처럼 넣지 않는다 — [onChanged] 를
///     부르지 않는다). "완료" 는 `draft ?? roundDateTimeToStep(now, step)` 을 넣는다
///
/// 읽기 — 휠은 이름 있는 묶음([semanticLabel], 없으면 [PTimePickerLabels.root]), 칼럼은 조절 가능한 값(이름 "오전/오후" ·
/// "시" · "분", 읽는 값 "오후" · "3" · "00"). 열 때 시 칼럼에 초점을 두는 것(웹 autoFocus)은 앱에 없다 — 칼럼의 초점 자리를
/// 부모가 쥐지 못한다(손가락 입력이 기본).
class PTimePicker extends StatefulWidget {
  const PTimePicker({
    super.key,
    this.value,
    this.onChanged,
    this.minuteStep = 1,
    this.disabled = false,
    this.now,
    this.labels,
    this.semanticLabel,
  });

  /// 고르던 시각(24시간) — 비었으면 지금을 분 간격에 맞춰 반올림한 자리를 짚기만 한다.
  final PTimeValue? value;

  /// 휠이 멈춰 값이 정해졌을 때 — 칸이 아니라 draft 에 넣는다.
  final ValueChanged<PTimeValue>? onChanged;

  /// 분 간격 — 1(기본, 2026-11-10 사용자 결정 — 스펙 5 에서 앱이 앞서 바꿈) · 5 · 10 · 15 · 30. 그 밖의 값은 1.
  final int minuteStep;
  final bool disabled;

  /// 지금 — 빈 값을 짚을 때 쓴다(처음 한 번만 잰다. 테스트 · 견본에서 맞춘다).
  final DateTime? now;

  /// 글 한 벌 — 없으면 로케일 문구([PTimePickerLabels.of]).
  final PTimePickerLabels? labels;

  /// 휠의 이름 — 칸 라벨. 없으면 [PTimePickerLabels.root].
  final String? semanticLabel;

  @override
  State<PTimePicker> createState() => _PTimePickerState();
}

class _PTimePickerState extends State<PTimePicker> {
  late final PTimeValue _fallback = PTimeValue.fromDateTime(
    widget.now ?? DateTime.now(),
  );

  // 값을 주지 않고 쓸 때(제어하지 않을 때)의 값
  PTimeValue? _inner;

  // 지금 값 — 칼럼이 잇달아 멈춰도(시 → 오전·오후) 앞 칼럼이 바꾼 값 위에서 셈한다
  late PTimeValue _current;

  int get _step =>
      pMinuteSteps.contains(widget.minuteStep) ? widget.minuteStep : 1;

  PTimeValue _resolve() =>
      roundTimeToStep(widget.value ?? _inner ?? _fallback, _step);

  @override
  void initState() {
    super.initState();
    _current = _resolve();
  }

  @override
  void didUpdateWidget(PTimePicker old) {
    super.didUpdateWidget(old);
    _current = _resolve();
  }

  void _commit(PTimeValue next) {
    if (next == _current) return;
    _current = next;
    if (widget.value == null) setState(() => _inner = next);
    widget.onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.labels ?? PTimePickerLabels.of(context);
    final value = _resolve();
    _current = value;
    final period = value.hour < 12 ? 'am' : 'pm';
    final displayHour = value.hour % 12 == 0 ? 12 : value.hour % 12;

    return PWheelPicker(
      semanticLabel: widget.semanticLabel ?? l.root,
      disabled: widget.disabled,
      children: [
        PWheelPickerColumn<String>(
          semanticLabel: l.period,
          options: [
            PWheelPickerOption(value: 'am', label: l.am),
            PWheelPickerOption(value: 'pm', label: l.pm),
          ],
          value: period,
          align: PWheelPickerAlign.center,
          valueChange: PWheelPickerValueChange.smooth,
          onChanged: (next, _) {
            final cur = _current;
            final curPeriod = cur.hour < 12 ? 'am' : 'pm';
            if (next == curPeriod) return;
            _commit(
              PTimeValue(
                next == 'am' ? cur.hour - 12 : cur.hour + 12,
                cur.minute,
              ),
            );
          },
        ),
        PWheelPickerColumn<int>(
          semanticLabel: l.hour,
          options: [
            for (var i = 1; i <= 12; i++)
              PWheelPickerOption(value: i, label: '$i'),
          ],
          value: displayHour,
          loop: true,
          align: PWheelPickerAlign.right,
          onChanged: (_, stepDelta) {
            final cur = _current;
            _commit(
              PTimeValue(((cur.hour + stepDelta) % 24 + 24) % 24, cur.minute),
            );
          },
          // Home · End — 오전 · 오후를 그대로 두고 1 · 12 로 간다(지나간 칸을 세지 않는다, 03-C 결정 3A)
          onJump: (next) {
            final cur = _current;
            _commit(
              PTimeValue((next % 12) + (cur.hour >= 12 ? 12 : 0), cur.minute),
            );
          },
        ),
        PWheelPickerColumn<int>(
          semanticLabel: l.minute,
          options: [
            for (var i = 0; i < 60 ~/ _step; i++)
              PWheelPickerOption(value: i * _step, label: _pad2(i * _step)),
          ],
          value: value.minute,
          loop: true,
          align: PWheelPickerAlign.center,
          onChanged: (next, _) => _commit(PTimeValue(_current.hour, next)),
        ),
      ],
    );
  }
}
