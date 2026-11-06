// riverpod 덮개 겹침 도우미 — riverpod 3 은 같은 provider 를 두 번 덮으면 단언으로 멈춘다.
//
// 공용 기본 덮개(`_base()` 등)가 이미 덮는 provider 를 시험 하나가 다른 값으로 덮어야 할 때 [withOverrides] 로 잇는다 —
// 뒤 목록([extra])이 이긴다. 같은 provider 인지는 `Override.origin`(provider 또는 family)으로 가른다.
import 'package:flutter_riverpod/misc.dart' show Override;

/// [base] 에서 [extra] 가 덮는 provider 를 빼고 [extra] 를 붙인다.
List<Override> withOverrides(List<Override> base, List<Override> extra) {
  // ignore: invalid_use_of_visible_for_testing_member
  final taken = {for (final o in extra) o.origin};
  return [
    // ignore: invalid_use_of_visible_for_testing_member
    for (final o in base)
      if (!taken.contains(o.origin)) o,
    ...extra,
  ];
}

/// 같은 provider 를 덮은 것이 여럿이면 **뒤의 것만** 남긴다 — `[..._base(), x.overrideWith(…)]` 꼴로 기본 덮개 뒤에 시험의
/// 덮개를 붙이는 하네스가 그대로 쓸 수 있게.
List<Override> lastOverrideWins(List<Override> overrides) {
  final seen = <Object>{};
  final kept = <Override>[];
  for (final o in overrides.reversed) {
    // ignore: invalid_use_of_visible_for_testing_member
    if (seen.add(o.origin)) kept.add(o);
  }
  return kept.reversed.toList();
}
