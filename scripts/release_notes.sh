#!/usr/bin/env bash
#
# 릴리스 노트 — 커밋을 사용자가 읽는 목록으로 정리한다.
#
# 앱 업데이트 화면과 GitHub 릴리스 본문이 같은 글을 쓴다.
#
# 글은 두 군데서 온다.
#
#   0. `release_notes/<태그>.md` — 있으면 그 파일이 전부다. 커밋은 안 본다.
#
#      노트는 커밋을 만들 때만 달 수 있다. 규칙이 생기기 전에 머지된 커밋이나,
#      여러 커밋이 서로 상쇄돼(값을 바꿨다 되돌렸다) 목록으로는 뜻이 안 통하는
#      릴리스는 소급할 방법이 없다 — main 히스토리를 다시 쓰지 않는 한.
#      그때 사람이 직접 쓴다. PR 로 리뷰되고 CI 가 그대로 재현한다.
#
#      상시 수단이 아니다. 노트를 성실히 달면 이 파일은 안 생긴다.
#
#   1. 커밋 메시지 본문의 `Release-Note:` 줄 — 있으면 이것을 그대로 쓴다.
#
#        fix(recurring): 스냅 임계값 단위를 트레이 기준으로 환산한다
#
#        Release-Note: 반복 거래 행이 어중간하게 열리던 문제를 고쳤어요
#        Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
#
#      커밋 제목은 `git log`·`blame`·리뷰에서 개발자가 읽는 자리다. 거기를 사용자
#      말투로 바꾸면 그쪽이 망가진다. 그래서 사용자용 문장을 따로 단다.
#
#      **트레일러 블록이 아니라 본문 전체에서 줄머리를 찾는다.** git 은 메시지의
#      마지막 문단만 트레일러로 보므로, `%(trailers:key=Release-Note)` 로 읽으면
#      `Release-Note:` 뒤에 빈 줄 하나가 있고 그 아래 `Co-Authored-By:` 가 붙는
#      순간 앞 문단이 트레일러가 아니게 되어 빈 값이 돌아온다. 문장은 제대로 썼는데
#      노트에서 통째로 사라졌다(v1.23.1 e027765·9def50b — QA #7). 그래서 `%B` 를
#      받아 `^Release-Note:` 줄을 직접 읽는다 — 빈 줄이 있든 없든 같은 결과다.
#      (빈 줄 없이 붙여 쓰는 게 여전히 옳다. `git interpret-trailers` 나 GitHub
#      UI 는 이 스크립트가 아니라 git 의 트레일러 판정을 쓴다.)
#
#      **대소문자는 안 가린다.** PR 경고(`ci-main.yml` release-note)가 `grep -i` 로
#      존재를 보므로, 여기서만 가리면 CI 는 "달았다" 는데 노트에서는 빠지는 어긋남이
#      생긴다 — 두 술어가 갈리는 게 #7 의 뿌리였다.
#
#      여러 줄이면 `; ` 로 잇는다.
#
#      `Release-Note: skip` 이면 그 커밋은 아예 뺀다(`none` · `없음` 도 같다) — feat·fix 로 찍혔지만 쓰는
#      사람 눈에는 아무 일도 안 일어난 변경(내부 정리, 테스트 보강 등)에 쓴다.
#
# 노트가 없는 feat·fix 는 **목록에서 빠진다.** 제목 폴백은 없다 — 개발자 말투
# ("…동기적으로 막는다")가 그대로 앱 업데이트 화면에 나가느니 빠지는 게 낫다.
# 빠뜨렸는지는 PR 에서 CI 가 알려 준다(ci-main.yml `release-note` 잡).
#
# 그리고 feat·fix 만 남겨 타입별로 묶는다(ci·docs·test·chore·refactor 는 우리 사정).
# 남는 게 하나도 없으면 `이번 업데이트는 내부 개선만 담았어요` 한 줄을 낸다.
#
# 사용: scripts/release_notes.sh <git-range> [태그]
#   예: scripts/release_notes.sh v1.12.0..HEAD
#       scripts/release_notes.sh v1.12.0..HEAD v1.13.0   # 손으로 쓴 노트가 있으면 그것
#
# 태그를 안 주면 손으로 쓴 노트는 찾지 않는다 — CI 는 GITHUB_REF_NAME 을 넘긴다.
# 브랜치 빌드(dev)면 그 값이 `main` 이라 파일이 없고, 자연히 커밋에서 뽑는다.
#
# 범위 대신 `-` 를 주면 커밋 제목을 stdin 으로 한 줄씩 받는다 — 손으로 확인해 볼 때
# 쓴다. 제목 바로 아래에 `Release-Note:` 줄을 붙이면 그 제목의 노트로 읽는다.
#   예: printf 'fix(a): 가\nRelease-Note: 가가 고쳐졌어요\nchore: 나\n' \
#         | scripts/release_notes.sh -
#
# 회귀 테스트: scripts/release_notes_test.sh
set -euo pipefail

RANGE="${1:?usage: release_notes.sh <git-range> [tag]}"
TAG="${2:-}"

# 손으로 쓴 노트가 이긴다. 있으면 커밋은 아예 안 읽는다 — 섞으면 어느 줄이 어디서
# 왔는지 알 수 없고, 사람이 뺀 줄이 되살아난다.
if [ -n "${TAG}" ] && [ -f "release_notes/${TAG}.md" ]; then
  cat "release_notes/${TAG}.md"
  exit 0
fi

# 한 릴리스에 담을 최대 줄 수. 넘치면 화면이 스크롤만 길어지고 아무도 안 읽는다.
MAX_LINES="${RELEASE_NOTES_MAX:-40}"

# 레코드: 제목 US 메시지전문 RS.
#
# 메시지 전문(`%B`)은 여러 줄이지만 레코드·필드 구분자가 제어문자라 구조는 안
# 깨진다 — 레코드 안의 개행은 그대로 둘째 필드에 들어온다.
US=$'\037'
RS=$'\036'

if [ "${RANGE}" = "-" ]; then
  # 제목 한 줄이 레코드 하나. 뒤따르는 `Release-Note:` 줄은 그 제목에 붙인다.
  RAW=$(awk -v us="${US}" -v rs="${RS}" '
    function flush() {
      if (subj != "") printf "%s%s%s%s", subj, us, msg, rs
      subj = ""; msg = ""
    }
    /^[[:space:]]*$/ { next }
    tolower($0) ~ /^release-note:/ { msg = (msg == "") ? $0 : msg "\n" $0; next }
    { flush(); subj = $0 }
    END { flush() }
  ')
else
  RAW=$(git log --no-merges --pretty="format:%s${US}%B${RS}" "${RANGE}")
fi

printf '%s' "${RAW}" | awk -v RS="${RS}" -v FS="${US}" -v max="${MAX_LINES}" '
  {
    subject = $1
    message = $2
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", subject)
    if (subject == "") next

    # feat·fix 만. 타입은 제목에서 읽는다 — 노트는 문장일 뿐 분류를 모른다.
    if (subject !~ /^(feat|fix)(\([^)]*\))?!?:/) next
    type = substr(subject, 1, 3) == "fix" ? "fix" : "feat"

    # 본문 어디에 있든 `Release-Note:` 로 시작하는 줄을 모은다. 트레일러 블록에
    # 속했는지는 안 본다 — 그게 이 스크립트가 빈 줄에 걸려 넘어지지 않는 이유다.
    # 대소문자는 안 가린다(CI 경고와 같은 술어). 접두사는 ASCII 13 글자라 gawk 의
    # 글자 단위 substr 과 mawk 의 바이트 단위 substr 이 같은 자리를 가리킨다.
    note = ""
    cnt = split(message, lines, "\n")
    for (i = 1; i <= cnt; i++) {
      line = lines[i]
      sub(/\r$/, "", line)
      if (tolower(substr(line, 1, 13)) != "release-note:") continue
      value = substr(line, 14)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      if (value == "") continue
      note = (note == "") ? value : note "; " value
    }

    # 노트가 없으면 뺀다. `skip` 과 같은 취급이다 — 제목 폴백은 없다.
    # "없음" 도 같다 — 한국어로 "노트 없음" 을 뜻하려고 쓴 값이 업데이트 화면에 "· 없음" 으로
    # 실린 적이 있다(2026-11-17, 720ec280).
    if (note == "" || tolower(note) == "skip" || tolower(note) == "none" || note == "없음") next

    key = type "\034" note
    if (key in seen) next        # 같은 문장이 두 번(리버트·재적용) 나오면 한 번만
    seen[key] = 1
    if (++n > max) next
    if (type == "feat") feats[++fc] = note
    else                fixes[++xc] = note
  }
  END {
    # 남은 게 없다 — 노트에 실릴 커밋이 없었거나, 있던 것을 전부 뺐다(skip·노트
    # 누락). 어느 쪽이든 사용자에게 할 말은 하나다.
    if (!fc && !xc) {
      print "이번 업데이트는 내부 개선만 담았어요"
      exit
    }

    out = 0
    if (fc) {
      print "새 기능"
      for (i = 1; i <= fc; i++) print "- " feats[i]
      out = 1
    }
    if (xc) {
      if (out) print ""
      print "버그 수정"
      for (i = 1; i <= xc; i++) print "- " fixes[i]
    }
  }
'
