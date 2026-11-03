#!/usr/bin/env bash
#
# porest-desk-app 릴리스 해석 — Jenkins 의 Resolve 단계에서 실행한다.
#
#   resolve-release.sh <channel: dev|prod> [version: X.Y.Z]
#
# 배포할 버전을 확정하고, 그 릴리스의 version.json 을 실제로 받아 채널·버전이 맞는지
# 대조한다. 여기를 통과해야 deploy.sh 가 불린다.
#
# 버전을 비우면 그 채널의 최신 릴리스를 찾는다. 자동(웹훅) 배포는 항상 버전을 들고
# 오므로 이 조회는 사람이 Jenkins 에서 직접 돌릴 때만 쓰인다.
#
# 성공하면 stdout 에 KEY=VALUE 만 찍는다(사람이 읽을 로그는 전부 stderr):
#
#   VERSION=1.19.0
#   BUILD_NUMBER=2337
#   MIN_BUILD_NUMBER=0
#
# 왜 Jenkinsfile 이 아니라 셸인가 —
#  · Jenkins 컨테이너에 jq · python3 · node 가 없고 readJSON(pipeline-utility-steps)도
#    없다. JSON 을 다룰 손이 셸(perl · curl)밖에 없다.
#  · Groovy 는 잡을 실제로 돌려야만 검증되는데, 이 잡을 돌린다는 건 곧 배포다.
#    셸로 빼 두면 배포하지 않고 여기서 그대로 돌려 확인할 수 있다.
#  · deploy.sh 의 인자 계약(<channel> <version>)은 그대로 둔다. 해석과 배치는 별개다 —
#    해석 결과를 사람이 승인 화면에서 보고 누른 뒤에야 배치가 시작돼야 한다.
#
set -euo pipefail

CHANNEL="${1:?channel(dev|prod) 이 필요합니다}"
REQUESTED="${2-}"

REPO="${APK_REPO:-lshdainty/groo-damda-app}"

log() { printf '%s\n' "$*" >&2; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

case "$CHANNEL" in
  dev|prod) ;;
  *) die "channel 은 dev 또는 prod 여야 합니다: ${CHANNEL}" ;;
esac

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# JSON 을 한 필드씩 정규식으로 뽑는다. 값에 이스케이프가 없는 필드만 이렇게 읽는다 —
# [^"\\]+ 가 역슬래시를 배제하므로, notes 에 커밋 메시지가 통째로 실려 그 안에
# \"version\": \"9.9.9\" 같은 글자가 섞여도 걸리지 않는다.
str_field() { k="$1" perl -0777 -ne 'print $1 if /"\Q$ENV{k}\E"\s*:\s*"([^"\\]+)"/' "$2"; }
num_field() { k="$1" perl -0777 -ne 'print $1 if /"\Q$ENV{k}\E"\s*:\s*(-?\d+)/' "$2"; }

# 받은 게 JSON 이 아닐 때(GitHub 이 HTML 오류 페이지를 준 경우) 원인이 로그에 바로 보이게.
dump() { log "받은 파일 앞 200바이트:"; head -c 200 "$1" >&2 || true; log ""; }

fetch_version_json() {
  curl -fsSL --retry 3 --max-time 60 -o "$2" \
    "https://github.com/${REPO}/releases/download/$1/version.json"
}

# ── 1. 버전 확정 ────────────────────────────────────────────────────────────
VERSION="$REQUESTED"
if [ -n "$VERSION" ]; then
  log "요청한 버전: ${VERSION}"
elif [ "$CHANNEL" = prod ]; then
  # /releases/latest 는 '최신 릴리스' 로 리다이렉트된다. git 태그 목록이 아니라
  # 릴리스 목록이라서 — 릴리스 없는 태그(v1.14.0)도, prerelease 인 dev 도 안 나온다.
  URL="$(curl -fsSL --retry 3 --max-time 60 -o /dev/null -w '%{url_effective}' \
           "https://github.com/${REPO}/releases/latest")" \
    || die "최신 운영 릴리스를 찾지 못했습니다(네트워크 오류이거나 릴리스가 없습니다)"
  case "$URL" in
    */releases/tag/v*) VERSION="${URL##*/tag/v}" ;;
    *) die "최신 릴리스 주소를 해석하지 못했습니다: ${URL}" ;;
  esac
  log "최신 운영 릴리스: ${VERSION}"
else
  # dev 는 태그가 'dev' 로 고정이라 버전을 밖에서 알 수 없다. 그런데 산출물 이름은
  # groo-desk-<version>.apk 라 버전이 반드시 필요하다 — 릴리스에 붙은 version.json 이
  # 유일한 출처다. (git describe 로도 같은 값이 나오지만, 그건 CI 의 계산을 두 번째로
  # 구현하는 셈이라 CI 가 바뀌면 조용히 어긋난다.)
  fetch_version_json dev "${WORK}/dev.json" \
    || die "dev 릴리스의 version.json 을 받지 못했습니다(릴리스가 없거나 네트워크 오류)"
  VERSION="$(str_field version "${WORK}/dev.json")"
  if [ -z "$VERSION" ]; then
    dump "${WORK}/dev.json"
    die "dev version.json 에서 version 필드를 읽지 못했습니다"
  fi
  log "최신 dev 릴리스: ${VERSION}"
fi

# ── 2. 형식 검사 ────────────────────────────────────────────────────────────
# dev 는 git describe 문자열(1.19.0-4-gb650e6b)이 올 수 있고, prod 는 X.Y.Z 만이다.
# prod 쪽 검사가 dev 빌드를 운영 채널로 올리는 길을 구조적으로 막는다.
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9]+-g[0-9a-f]{7,40})?$ ]]; then
  die "버전 형식이 아닙니다: '${VERSION}' (예: 1.19.0 · 1.19.0-4-gb650e6b)"
fi
if [ "$CHANNEL" != dev ] && ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  die "운영 배포는 릴리스 버전(X.Y.Z)만 허용됩니다: '${VERSION}'"
fi

# ── 3. 릴리스 대조 ──────────────────────────────────────────────────────────
# 채널→태그 파생은 deploy.sh 와 같은 규칙이다. 여기서 한 번 더 하는 이유는
# 배치를 시작하기 전에 '그 태그에 진짜 이 채널의 이 버전이 들어 있는지' 를 보기 위해서다.
case "$CHANNEL" in
  dev)  TAG="dev" ;;
  prod) TAG="v${VERSION}" ;;
esac

fetch_version_json "$TAG" "${WORK}/v.json" \
  || die "릴리스 ${TAG} 의 version.json 을 받지 못했습니다. 그 릴리스가 없거나(태그만 있고 릴리스가 없는 경우) version.json 이 붙기 전(v1.9.x 이전)의 릴리스입니다."

J_CHANNEL="$(str_field channel "${WORK}/v.json")"
J_VERSION="$(str_field version "${WORK}/v.json")"
J_BUILD="$(num_field buildNumber "${WORK}/v.json")"
J_MIN="$(num_field minBuildNumber "${WORK}/v.json")"

if [ -z "$J_CHANNEL" ] || [ -z "$J_VERSION" ]; then
  dump "${WORK}/v.json"
  die "릴리스 ${TAG} 의 version.json 에서 channel·version 을 읽지 못했습니다"
fi
if [ "$J_CHANNEL" != "$CHANNEL" ]; then
  die "릴리스 ${TAG} 는 ${J_CHANNEL} 채널 산출물입니다. ${CHANNEL} 로 배포할 수 없습니다."
fi
if [ "$J_VERSION" != "$VERSION" ]; then
  die "릴리스 ${TAG} 에 담긴 버전은 ${J_VERSION} 입니다(요청: ${VERSION}). dev 태그는 최신 하나만 들고 있어서 지난 dev 빌드는 되돌릴 수 없습니다."
fi

log "확인: ${TAG} → channel=${J_CHANNEL} version=${J_VERSION} build=${J_BUILD:-?} minBuild=${J_MIN:-?}"

printf 'VERSION=%s\n' "$VERSION"
printf 'BUILD_NUMBER=%s\n' "${J_BUILD:-unknown}"
printf 'MIN_BUILD_NUMBER=%s\n' "${J_MIN:-unknown}"
