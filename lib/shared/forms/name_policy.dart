import 'package:groo_damda_app/shared/ds/field/p_field.dart'
    show countGraphemes;

/// 이름 칸에서 날 수 있는 문제 — 웹 `shared/lib/groo/name-policy.ts` 의 `nameIssue` 와 같은 판정이다.
enum NameIssue { required, tooLong, duplicate }

/// 이름 판정. [taken] 에는 **자기 자신을 뺀** 기존 이름을 넘긴다(고칠 때 자기 이름과 부딪히면 저장이 영영 막힌다).
///
/// 비교는 앞뒤 공백을 뗀 뒤 완전 일치다 — 서버의 중복 판정이 대소문자를 어떻게 보는지 확인 전이라 더 넓게 잡으면 거짓 차단이 된다.
/// 서버가 더 넓게 막는 경우는 요청 실패로 화면이 받는다. 글자 수는 자소(글자 모양) 단위로 센다.
NameIssue? nameIssue(String raw, int max, [Iterable<String> taken = const []]) {
  final name = raw.trim();
  if (name.isEmpty) return NameIssue.required;
  if (countGraphemes(name) > max) return NameIssue.tooLong;
  if (taken.any((t) => t.trim() == name)) return NameIssue.duplicate;
  return null;
}
