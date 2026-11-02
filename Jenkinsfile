// porest-desk-app 배포 — 다른 groo 레포와 같이 Jenkinsfile 을 레포에 둔다.
//
// 다른 레포와 다른 점이 하나 있다. 앱은 여기서 빌드하지 않는다.
// APK 는 안드로이드 SDK, IPA 는 macOS 러너가 필요해서 GitHub Actions 가 빌드하고
// Release 에 붙여 둔다. Jenkins 는 그걸 받아 서버에 놓기만 한다.
//
// 그래서 Docker 이미지도, 컨테이너도 없다. 정적 파일을 nginx 가 내보낼 자리에
// 옮기는 게 전부다(.github/jenkins/deploy.sh).
//
// ── 실행 경로가 둘이다 ────────────────────────────────────────────────────────
//
//  ① 웹훅(자동)  — Actions 가 릴리스를 올린 뒤 POST 로 건다. 값은 Generic Webhook
//     Trigger 플러그인이 본문에서 뽑아 환경변수 CHANNEL · VERSION 으로 넣어 준다.
//  ② 사람(수동)  — Jenkins 의 [Build with Parameters]. 값은 파라미터
//     DEPLOY_ENV · DEPLOY_VERSION 으로 들어온다.
//
// ── 두 경로가 섞이지 않게 하는 규칙 ──────────────────────────────────────────
//
// **우선순위를 정하지 않는다. 두 값이 동시에 존재하는 상태 자체를 없앤다.**
// `params.X ?: env.Y` 같은 표현식을 쓰고 싶어질 텐데, 그러지 마라 — 한 줄 방향이
// 뒤집히면 운영 릴리스가 dev 로 가거나 dev 빌드가 운영으로 간다. 그리고 그 사고는
// 빌드가 초록불이라 아무도 눈치채지 못한다. 대신 세 가지를 건다.
//
//  1. 이름을 세 벌로 완전히 분리한다.
//       웹훅   CHANNEL · VERSION                (env, 잡 설정이 소유)
//       파라미터 DEPLOY_ENV · DEPLOY_VERSION
//       해석 결과 RESOLVED_CHANNEL · RESOLVED_VERSION (env)
//     파라미터를 CHANNEL 로 지으면 파라미터 기본값과 플러그인이 넣은 변수가 같은
//     build environment 에 들어가고, 어느 쪽이 이기는지는 core · 플러그인 버전에
//     달린 미문서화 동작이다. 어떤 이름도 두 출처를 겸하지 않는다.
//  2. DEPLOY_ENV 의 기본값은 유효한 채널이 아니라 센티널 '(webhook)' 이다.
//     choice 는 빈 기본값을 못 가지므로 '미지정' 을 이렇게 표현한다. 덕분에 웹훅
//     실행에서 dev · prod 와 경쟁하는 파라미터 값이 애초에 존재하지 않는다.
//  3. XOR — 둘 다 지정이거나 둘 다 미지정이면 실패한다. 웹훅 POST 는 파라미터를
//     싣지 않고 사람은 웹훅 본문을 못 만든다. 둘 다 채워진 상태는 정상 경로로
//     도달할 수 없으므로 '의도' 가 아니라 '설정이 망가졌다' 는 신호다.
//
// 해석은 Resolve 단계에서 딱 한 번 한다. 그 뒤로는 승인 조건 · 승인 메시지 · 배포
// 인자가 **RESOLVED_* 만** 읽는다. when 절에서 params.* 나 env.CHANNEL 을 직접 읽지
// 마라 — 승인 단계와 배포 단계가 서로 다른 변수를 보는 순간, 운영 배포가 승인 없이
// 나가는 길이 열린다. 그래서 게이트도 == 'prod' 가 아니라 != 'dev' 로 쓴다.
// 값이 비었거나 예상 밖이면 승인을 건너뛰는 쪽이 아니라 요구하는 쪽으로 무너진다.
//
// ── 잡 설정에 있어야 하는 것(이 파일이 아니라 Jenkins UI) ────────────────────
//
// 여기에 triggers 블록을 되살리지 마라. Declarative 의 triggers 디렉티브는 빌드가
// 돌 때마다 잡 설정에 다시 적용되고, 파일에서 지우면 잡에서도 지워진다(PR #287 에서
// 실제로 트리거가 통째로 날아갔다). 그리고 그 토큰은 인증 없이 배포를 거는 열쇠라
// 레포에 평문으로 둘 수 없다(Jenkins 는 인터넷에서 열려 있다).
//
//   · Generic Webhook Trigger 의 토큰
//   · genericVariables 두 줄 — CHANNEL = $.channel · VERSION = $.version
//   · 그 두 줄의 defaultValue 는 **반드시 비워 둔다.** 값을 채우면 수동 실행에서도
//     env.CHANNEL 이 비어 있지 않게 되어, 아래 XOR 이 모든 수동 빌드를 '웹훅+수동'
//     으로 오판하고 거부한다.
pipeline {
    agent any

    options {
        // 수동 실행이 파일을 놓는 중에 dev 웹훅이 도착해 같은 디렉토리에 겹쳐 쓰는 걸 막는다.
        // abortPrevious 는 쓰지 않는다 — 승인 대기 중인 운영 빌드를 죽인다.
        disableConcurrentBuilds()
    }

    parameters {
        // 이름 · 값은 다른 groo 레포와 같게 간다(사람이 8개 잡을 오가며 쓰는 자리다).
        // 다른 건 첫 항목뿐이다 — 이 잡만 입력 출처가 둘이라 '미지정' 을 표현해야 한다.
        choice(
            name: 'DEPLOY_ENV',
            choices: ['(webhook)', 'dev', 'prod'],
            description: '수동 배포 환경. (webhook) 그대로면 이 실행은 웹훅 전용으로 취급한다.'
        )
        // 버전이지 태그가 아니다 — v 접두는 deploy.sh 가 채널을 보고 붙인다.
        // 여기서 태그를 받으면 v 규칙이 두 군데로 갈라진다.
        //
        // GIT_REF 는 만들지 않는다. 이 잡은 소스를 체크아웃해 빌드하지 않으므로
        // '배포할 ref' 라는 개념이 없다 — 두면 아무 효과 없는 조작 장치가 생기고
        // 누군가 v1.14.0 을 골라 놓고 그 버전을 배포했다고 믿는다.
        string(
            name: 'DEPLOY_VERSION',
            defaultValue: '',
            description: '배포할 릴리스 버전(v 없이). 비우면 해당 채널의 최신 릴리스를 찾는다. 예) 1.18.0'
        )
    }

    environment {
        // 다른 레포와 같은 전역변수를 쓴다. Jenkins 전역 설정에서 한 번만 정한다.
        APK_BASE_PATH = "${env.POREST_BASE_DIR}/apk"
        APK_REPO = 'lshdainty/groo-damda-app'
    }

    stages {
        stage('Resolve') {
            steps {
                script {
                    def sentinel = '(webhook)'

                    // 파라미터를 추가한 첫 빌드에서는 잡에 아직 파라미터가 등록되지
                    // 않아 params.* 가 null 일 수 있다. null 은 언제나 '미지정' 이다 —
                    // 여기서 정규화하지 않으면 그 전환 빌드의 자동 dev 배포가 실패한다.
                    def pEnv = (params.DEPLOY_ENV ?: sentinel).trim()
                    def pVersion = (params.DEPLOY_VERSION ?: '').trim()
                    def wChannel = (env.CHANNEL ?: '').trim()
                    def wVersion = (env.VERSION ?: '').trim()

                    def manual = (pEnv != sentinel)
                    def webhook = (wChannel != '' || wVersion != '')

                    if (manual && webhook) {
                        error "웹훅 값과 수동 파라미터가 함께 왔습니다. 정상 경로로는 생길 수 없는 조합이라 잡 설정이 망가진 것으로 보고 멈춥니다 (CHANNEL='${wChannel}', VERSION='${wVersion}', DEPLOY_ENV='${pEnv}'). 잡 설정의 genericVariables 에 defaultValue 가 채워져 있는지 확인하세요 — 비어 있어야 합니다."
                    }
                    if (!manual && !webhook) {
                        error "배포할 대상이 없습니다. 수동으로 돌리려면 [Build with Parameters] 에서 DEPLOY_ENV 를 dev 또는 prod 로 고르세요. 웹훅으로 왔다면 잡 설정의 genericVariables 두 줄(CHANNEL = \$.channel · VERSION = \$.version)이 빠졌습니다."
                    }
                    if (webhook && pVersion != '') {
                        error "웹훅 실행에는 DEPLOY_VERSION 을 지정할 수 없습니다 (DEPLOY_VERSION='${pVersion}'). 버전은 웹훅이 들고 옵니다."
                    }

                    def channel
                    def requested
                    if (webhook) {
                        // 웹훅 표현식이 안 맞으면 값이 통째로 비어 온다. 승인을 받기 전에
                        // 막는다 — 잘못 배포되느니 여기서 실패하는 게 낫다.
                        if (!wChannel || !wVersion) {
                            error "웹훅에서 CHANNEL·VERSION 을 못 읽었습니다 (CHANNEL='${wChannel}', VERSION='${wVersion}')"
                        }
                        channel = wChannel
                        requested = wVersion
                    } else {
                        channel = pEnv
                        requested = pVersion
                    }

                    if (!(channel in ['dev', 'prod'])) {
                        error "CHANNEL 은 dev 또는 prod 여야 합니다: ${channel}"
                    }

                    // 이후 모든 단계가 읽는 단 하나의 이름. 여기서만 쓴다.
                    env.RESOLVED_CHANNEL = channel
                    env.REQUESTED_VERSION = requested
                    echo "실행 경로: ${webhook ? '웹훅(자동)' : '수동'} / 채널: ${channel} / 요청 버전: ${requested ?: '(최신)'}"

                    // 버전 확정 + 릴리스 대조. 홑따옴표라 Groovy 가 아니라 셸이 값을 푼다.
                    def out = sh(
                        script: './.github/jenkins/resolve-release.sh "$RESOLVED_CHANNEL" "$REQUESTED_VERSION"',
                        returnStdout: true
                    )
                    def kv = [:]
                    for (String line : out.split('\n')) {
                        int i = line.indexOf('=')
                        if (i > 0) {
                            kv[line.substring(0, i).trim()] = line.substring(i + 1).trim()
                        }
                    }

                    env.RESOLVED_VERSION = kv['VERSION'] ?: ''
                    env.RESOLVED_BUILD = kv['BUILD_NUMBER'] ?: 'unknown'
                    env.RESOLVED_MIN_BUILD = kv['MIN_BUILD_NUMBER'] ?: 'unknown'

                    // 스크립트가 이미 같은 검사를 한다. 여기서 한 번 더 하는 건 스크립트와
                    // 파이프라인 사이(stdout 파싱)에서 값이 뭉개지는 경우까지 막기 위해서다 —
                    // ==~ 는 전체 매치라 앞뒤 공백·개행도 걸린다.
                    if (!env.RESOLVED_VERSION) {
                        error "버전 해석에 실패했습니다. resolve-release.sh 출력을 확인하세요."
                    }
                    if (!(env.RESOLVED_VERSION ==~ /\d+\.\d+\.\d+(-\d+-g[0-9a-f]{7,40})?/)) {
                        error "해석된 버전이 형식에 안 맞습니다: '${env.RESOLVED_VERSION}'"
                    }
                    if (env.RESOLVED_CHANNEL != 'dev' && !(env.RESOLVED_VERSION ==~ /\d+\.\d+\.\d+/)) {
                        error "운영 배포는 릴리스 버전(X.Y.Z)만 허용됩니다: '${env.RESOLVED_VERSION}'"
                    }

                    echo "배포 대상: ${env.RESOLVED_CHANNEL} ${env.RESOLVED_VERSION} (build ${env.RESOLVED_BUILD}, 하한 ${env.RESOLVED_MIN_BUILD})"
                }
            }
        }

        stage('Approval for Prod') {
            // dev 가 아니면 무조건 멈춘다. == 'prod' 로 쓰면 값이 예상 밖일 때
            // 승인을 건너뛰는 쪽으로 무너진다.
            when { expression { env.RESOLVED_CHANNEL != 'dev' } }
            options {
                // 무응답은 진행이 아니라 중단으로 끝낸다. 승인 대기 빌드가 executor 를
                // 붙잡는 것도, 며칠 뒤 옛 선택이 뒤늦게 나가는 것도 막는다.
                timeout(time: 30, unit: 'MINUTES')
            }
            steps {
                script {
                    // 운영만 멈춘다. 누르기 전에는 서버에 아무것도 놓이지 않는다.
                    //
                    // 하한(minBuildNumber)을 같이 보여 준다 — 옛 버전으로 되돌리면 그
                    // 릴리스의 version.json 이 통째로 돌아가서 강제 업데이트 하한도 함께
                    // 바뀐다. 올라가면 사용자가 앱 밖에 갇히고, 내려가면 막고 있던 옛
                    // 빌드가 풀린다. 배포 자체는 성공하므로 여기서 보지 않으면 티가 안 난다.
                    input(
                        id: 'DeployToProd',
                        message: "운영에 ${env.RESOLVED_VERSION} 배포하시겠습니까? (build ${env.RESOLVED_BUILD} · 강제 업데이트 하한 ${env.RESOLVED_MIN_BUILD})",
                        ok: '배포'
                    )
                }
            }
        }

        stage('Deploy') {
            steps {
                // 배포 절차는 deploy.sh 한 벌뿐이다. dev·prod 가 같은 길을 걷게 해서
                // 한쪽만 고쳐져 어긋나는 일을 없앤다.
                //
                // 홑따옴표라 Groovy 가 아니라 셸이 값을 푼다 — 웹훅이나 텍스트 상자로
                // 들어온 값을 스크립트 문자열에 그대로 박아 넣지 않는다. 자유입력
                // 파라미터가 생긴 뒤로 이건 스타일이 아니라 보안 문제다.
                sh './.github/jenkins/deploy.sh "$RESOLVED_CHANNEL" "$RESOLVED_VERSION"'
            }
        }
    }
}
