#!/usr/bin/env bash
#
# `release_notes.sh` 회귀 테스트 — 의존성 0(bash + git + awk).
#
# 이 스크립트가 생긴 이유: 릴리스 노트 파이프라인에 테스트가 하나도 없었고,
# 그래서 `Release-Note:` 가 **빈 줄 하나** 때문에 통째로 안 읽히는 상태로 네 릴리스가
# 나갔다(QA #7). 앱 업데이트 화면에 개발자 말투가 그대로 떴는데 아무도 못 막았다.
# 케이스 2가 그 회귀 게이트다.
#
# 임시 git 레포를 만들어 케이스별 커밋을 심고, 출력 전문을 기대값과 비교한다.
#
# 사용: scripts/release_notes_test.sh
#   AWK=mawk scripts/release_notes_test.sh   # CI 러너의 기본 awk 로도 돌려 본다
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
NOTES="${SCRIPT_DIR}/release_notes.sh"

TMPROOT=$(mktemp -d)
trap 'rm -rf "${TMPROOT}"' EXIT

# awk 를 갈아 끼울 수 있게 해 둔다 — 로컬은 gawk, GitHub 러너는 mawk 다. 둘이
# 다르게 동작하면 여기서 잡힌다.
if [ -n "${AWK:-}" ]; then
  mkdir -p "${TMPROOT}/bin"
  ln -sf "$(command -v "${AWK}")" "${TMPROOT}/bin/awk"
  PATH="${TMPROOT}/bin:${PATH}"
  export PATH
fi

FAILED=0
REPO=""

new_repo() {
  REPO=$(mktemp -d "${TMPROOT}/repo.XXXXXX")
  git -C "${REPO}" init -q -b main
  git -C "${REPO}" config user.email tester@example.com
  git -C "${REPO}" config user.name Tester
  git -C "${REPO}" config commit.gpgsign false
  git -C "${REPO}" commit -q --allow-empty -m 'chore: base'
  git -C "${REPO}" tag base
}

# 커밋 메시지를 stdin 으로 받는다 — 빈 줄까지 그대로 보존해야 이 테스트가 뜻이 있다.
commit() { git -C "${REPO}" commit -q --allow-empty --cleanup=verbatim -F -; }

notes() { (cd "${REPO}" && bash "${NOTES}" "$@"); }

# expect <이름> <실제출력>  <<'EOF' 기대출력 EOF
expect() {
  local name="$1" actual="$2" expected
  expected=$(cat)
  if [ "${actual}" = "${expected}" ]; then
    printf 'ok   %s\n' "${name}"
  else
    printf 'FAIL %s\n' "${name}"
    diff -u <(printf '%s\n' "${expected}") <(printf '%s\n' "${actual}") | sed 's/^/     /' || true
    FAILED=$((FAILED + 1))
  fi
}

pass() { printf 'ok   %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1"; shift; printf '     %s\n' "$@"; FAILED=$((FAILED + 1)); }

# ── 1. 노트 바로 다음 줄에 서명 — git 이 트레일러로 읽는 형태.
new_repo
commit <<'EOF'
fix(sheet): 시트 푸터의 따닥 탭을 동기적으로 막는다

Release-Note: 저장 버튼을 빠르게 두 번 눌러도 한 번만 처리돼요
Co-Authored-By: Someone <a@b.c>
EOF
expect '노트 다음 줄이 서명' "$(notes base..HEAD)" <<'EOF'
버그 수정
- 저장 버튼을 빠르게 두 번 눌러도 한 번만 처리돼요
EOF

# ── 2. 노트와 서명 사이에 빈 줄 — QA #7 그 자체. git 트레일러로는 안 읽힌다.
new_repo
commit <<'EOF'
feat(ui): 토글에 항목별 진행 상태를 붙인다

본문 문단.

Release-Note: 토글을 누르면 그 자리에 표시가 떠요

Co-Authored-By: Someone <a@b.c>
EOF
# 전제 확인 — git 트레일러 파서로는 정말 안 잡히는 상황인가.
if [ -n "$(git -C "${REPO}" log -1 --format='%(trailers:key=Release-Note,valueonly)')" ]; then
  fail '전제: 빈 줄이면 git 트레일러로 안 잡힌다' '잡혔다 — 이 케이스가 #7 을 재현하지 못한다'
else
  pass '전제: 빈 줄이면 git 트레일러로 안 잡힌다'
fi
expect '빈 줄이 있어도 노트를 읽는다 (#7 회귀 게이트)' "$(notes base..HEAD)" <<'EOF'
새 기능
- 토글을 누르면 그 자리에 표시가 떠요
EOF

# ── 3. 노트가 본문 한가운데 있고 뒤에 문단이 여럿.
new_repo
commit <<'EOF'
fix(a): 가

Release-Note: 가가 고쳐졌어요

왜 그랬는지 설명하는 문단.

또 다른 문단.

Co-Authored-By: Someone <a@b.c>
EOF
expect '노트가 본문 한가운데' "$(notes base..HEAD)" <<'EOF'
버그 수정
- 가가 고쳐졌어요
EOF

# ── 4. skip 은 목록에서 빠진다.
new_repo
commit <<'EOF'
fix(a): 내부 정리

Release-Note: skip
Co-Authored-By: Someone <a@b.c>
EOF
commit <<'EOF'
feat(b): 나

Release-Note: 나를 쓸 수 있어요
EOF
expect 'skip 은 빠진다' "$(notes base..HEAD)" <<'EOF'
새 기능
- 나를 쓸 수 있어요
EOF

# ── 4-1. "없음" 도 skip 과 같이 빠진다(업데이트 화면에 "· 없음" 이 실린 일, 2026-11-17).
new_repo
commit <<'EOF'
fix(a): 내부 정리

Release-Note: 없음
Co-Authored-By: Someone <a@b.c>
EOF
commit <<'EOF'
fix(b): 다

Release-Note: 다가 고쳐졌어요
EOF
expect '없음 은 빠진다' "$(notes base..HEAD)" <<'EOF'
버그 수정
- 다가 고쳐졌어요
EOF

# ── 5. 노트 없는 feat 은 빠지고, 제목은 **절대** 출력에 없다.
new_repo
commit <<'EOF'
feat(net): 요청에 User-Agent 를 붙인다
EOF
commit <<'EOF'
fix(a): 가

Release-Note: 가가 고쳐졌어요
Co-Authored-By: Someone <a@b.c>
EOF
OUT=$(notes base..HEAD)
expect '노트 없는 feat 은 목록에서 빠진다' "${OUT}" <<'EOF'
버그 수정
- 가가 고쳐졌어요
EOF
if printf '%s' "${OUT}" | grep -q 'User-Agent'; then
  fail '제목 폴백이 없다' '커밋 제목이 출력에 새어 나왔다'
else
  pass '제목 폴백이 없다'
fi

# ── 6. feat·fix 는 있었지만 남는 게 없다 → 한 줄.
new_repo
commit <<'EOF'
feat(net): 요청에 User-Agent 를 붙인다
EOF
commit <<'EOF'
fix(a): 내부 정리

Release-Note: skip
EOF
expect '전부 빠지면 한 줄' "$(notes base..HEAD)" <<'EOF'
이번 업데이트는 내부 개선만 담았어요
EOF

# ── 7. 애초에 feat·fix 가 없는 범위 → 같은 한 줄.
new_repo
commit <<'EOF'
chore: 정리
EOF
commit <<'EOF'
docs: 문서
EOF
expect 'chore·docs 만 있으면 한 줄' "$(notes base..HEAD)" <<'EOF'
이번 업데이트는 내부 개선만 담았어요
EOF

# ── 8. 노트 두 줄은 `; ` 로 잇는다.
new_repo
commit <<'EOF'
feat(a): 가

Release-Note: 첫째 문장이에요
Release-Note: 둘째 문장이에요
Co-Authored-By: Someone <a@b.c>
EOF
expect '노트 두 줄은 세미콜론으로 잇는다' "$(notes base..HEAD)" <<'EOF'
새 기능
- 첫째 문장이에요; 둘째 문장이에요
EOF

# ── 9. 손으로 쓴 `release_notes/<태그>.md` 가 이긴다 — 커밋은 아예 안 읽는다.
new_repo
commit <<'EOF'
feat(a): 가

Release-Note: 커밋에서 온 문장이에요
EOF
mkdir -p "${REPO}/release_notes"
printf '손으로 쓴 노트예요\n' > "${REPO}/release_notes/v9.9.9.md"
expect '손으로 쓴 노트가 이긴다' "$(notes base..HEAD v9.9.9)" <<'EOF'
손으로 쓴 노트예요
EOF

# ── 10. 같은 문장이 두 번(리버트·재적용) 나오면 한 번만.
new_repo
commit <<'EOF'
fix(a): 가

Release-Note: 같은 문장이에요
EOF
commit <<'EOF'
fix(a): 가를 되돌린다

Release-Note: 같은 문장이에요
EOF
expect '같은 문장은 한 번만' "$(notes base..HEAD)" <<'EOF'
버그 수정
- 같은 문장이에요
EOF

# ── 11. MAX_LINES 상한.
new_repo
for i in 1 2 3; do
  commit <<EOF
fix(a): 가 ${i}

Release-Note: ${i}번 문장이에요
EOF
done
expect 'MAX_LINES 가 줄 수를 막는다' "$(cd "${REPO}" && RELEASE_NOTES_MAX=2 bash "${NOTES}" base..HEAD)" <<'EOF'
버그 수정
- 3번 문장이에요
- 2번 문장이에요
EOF

# ── 12. stdin(`-`) 모드 — 제목 아래 붙인 노트를 읽는다.
new_repo
expect 'stdin 모드' "$(printf 'fix(a): 가\nRelease-Note: 가가 고쳐졌어요\nchore: 나\n' | bash "${NOTES}" -)" <<'EOF'
버그 수정
- 가가 고쳐졌어요
EOF

# ── 13. stdin 에 제목만 주면 — 노트가 없으니 한 줄.
expect 'stdin 제목만' "$(printf 'fix(a): 가\nchore: 나\n' | bash "${NOTES}" -)" <<'EOF'
이번 업데이트는 내부 개선만 담았어요
EOF

# ── 14. 빈 범위도 빈 출력이 아니다.
new_repo
expect '빈 범위' "$(notes base..HEAD)" <<'EOF'
이번 업데이트는 내부 개선만 담았어요
EOF

# ── 15. 대소문자를 안 가린다 — CI 경고(`grep -i`)와 같은 술어여야 한다.
#         갈리면 CI 는 "달았다" 는데 노트에서만 조용히 빠진다 — #7 과 같은 모양이다.
new_repo
commit <<'EOF'
fix(a): 가

RELEASE-NOTE: 대문자로 썼어요
Co-Authored-By: Someone <a@b.c>
EOF
expect '대소문자를 안 가린다' "$(notes base..HEAD)" <<'EOF'
버그 수정
- 대문자로 썼어요
EOF
# CI 경고가 쓰는 술어도 같은 답을 내는지 — 둘이 갈리면 이 테스트는 무의미하다.
if git -C "${REPO}" log -1 --format='%B' HEAD \
     | grep -qiE '^Release-Note:[[:space:]]*[^[:space:]]'; then
  pass 'CI 경고 술어도 같은 답'
else
  fail 'CI 경고 술어도 같은 답' 'ci-main.yml 은 없다고 본다 — 술어가 갈렸다'
fi

echo
if [ "${FAILED}" -gt 0 ]; then
  echo "${FAILED}건 실패"
  exit 1
fi
echo "전부 통과"
