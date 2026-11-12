# 앱 배포

스토어를 쓰지 않고 **서버에서 직접 받아 설치**한다. 안드로이드가 주 경로이고, iOS 는
서명 없이 빌드한 IPA 를 올려 두되 설치는 받는 사람이 직접 서명해야 한다.

**빌드는 GitHub Actions, 배포는 Jenkins.** 다른 groo 레포와 같다 — 운영에 무엇이
언제 올라가는지는 Jenkins 한 곳에서만 통제한다.

## 흐름

```
main 머지        → 검증 → 빌드 → dev 릴리스   → Jenkins 호출 → dev 로 배포 (자동)
태그 vX.Y.Z 푸시 → 검증 → 빌드 → 정식 릴리스  → Jenkins 호출 → [승인] → prod 로 배포
```

Actions 는 **서버로 아무것도 밀지 않는다.** 빌드 결과를 GitHub Release 에 붙이고
Jenkins 에 "새 게 나왔다" 고 알릴 뿐이다. 파일을 서버에 놓는 건 Jenkins 가 한다.

그래서 Actions 에는 서버 주소도, SSH 키도 없다. 서명 키 4개면 된다.

### 왜 밀지 않고 가져가나

밀어넣는 방식이면 GitHub 이 내 서버에 로그인할 수 있어야 해서 SSH 개인키를 통째로
넘겨야 한다. 가져가는 방식이면 그럴 이유가 없고, 승인 지점이 Actions 와 Jenkins 로
갈리지도 않는다.

Actions **artifact** 는 공개 레포라도 받으려면 토큰이 필요하지만 **Release** 는 아니다.
그래서 artifact 가 아니라 Release 로 넘긴다. 덤으로 artifact 의 7일 만료도 없어진다.

## 버전

`versionCode` 가 단조 증가해야 재설치 없이 업데이트된다.

| | version name | versionCode | 릴리스 태그 |
|---|---|---|---|
| dev | pubspec 의 `X.Y.Z` | Actions 실행번호 | `dev` (프리릴리스, 매번 덮어씀) |
| prod | 태그에서 딴 `X.Y.Z` | Actions 실행번호 | `vX.Y.Z` |

실행번호는 레포 전역으로 늘어나므로 dev/prod 가 번갈아 나가도 역전이 없다.

`dev` 태그는 빌드마다 지웠다 다시 만든다 — 최신 하나만 남기려는 것이다.

## Flutter 버전

워크플로의 `FLUTTER_VERSION` 은 로컬(`.fvmrc`)과 **같은 값으로 고정**한다. CI 만
최신 stable 을 따라가면 SDK 가 올라갈 때마다 로컬은 통과하는데 CI 만 깨진다
(`flutter analyze` 는 deprecation info 도 실패로 친다).

SDK 를 올릴 때는 두 곳을 함께 바꾼다.

고정만 하면 반대 문제가 생긴다 — 뒤처진 걸 아무도 모른 채 시간이 간다. 실제로
3.41.9 에 넉 달 머물렀다. 그래서 별도 워크플로 `sdk-drift.yml` 이 **고정 버전이
아니라 그 시점의 최신 stable** 로 `analyze` · `test` 를 돌린다.

`ci-main.yml` 안에 두지 않는다. 최신 stable 에서 깨지는 건 상수라 PR 마다 빨간
체크가 상시로 붙고, 버전을 올리지도 않는데 계속 빨가면 진짜 실패와 구분이 안 된다.

도는 시점은 둘뿐이다.

- 매달 1일 09:00 KST (`cron: '0 0 1 * *'`)
- Actions 탭에서 손으로 (SDK 를 올릴지 판단할 때)

이 워크플로는 아무것도 막지 않는다 — 빨개져도 배포와 무관하다. 빨간 로그가 곧
다음 업그레이드의 작업 목록이다. 올릴 때는 `FLUTTER_VERSION` 과 `.fvmrc` 를 같이
올리면서 그 목록을 처리한다.

## 준비 (한 번만)

### 1. 서명 키

**한 번 정하면 앱 수명 내내 바꿀 수 없다.** 키가 달라지면 기존 설치본 위에 업데이트가
안 되고, 지우고 새로 깔아야 한다(데이터도 사라진다).

```bash
keytool -genkey -v -keystore groo-desk.jks -keyalg RSA \
  -keysize 2048 -validity 10000 -alias groo-desk
```

**jks 파일은 안전한 곳에 백업할 것.**

Secrets 에 4개 등록. 값을 셸 히스토리에 남기지 않으려면 `gh secret set` 을 인자 없이
불러 프롬프트에 입력한다.

```bash
R=lshdainty/groo-damda-app
# 줄바꿈이 섞이면 base64 디코드가 깨진다 — -w0 로 한 줄로 만든다
base64 -w0 groo-desk.jks | gh secret set ANDROID_KEYSTORE_BASE64 -R "$R"
gh secret set ANDROID_KEYSTORE_PASSWORD -R "$R"   # keystore 비밀번호
gh secret set ANDROID_KEY_PASSWORD      -R "$R"   # key 비밀번호
echo -n groo-desk | gh secret set ANDROID_KEY_ALIAS -R "$R"
```

키가 없어도 빌드는 된다 — 디버그 키로 서명될 뿐이다. 채우는 순간부터 릴리스 키로 바뀐다.

### 2. Jenkins 호출용 Secret

| 이름 | 값 |
|---|---|
| `JENKINS_URL` | 다른 groo 레포에 등록해 둔 값과 같다 |
| `JENKINS_DEPLOY_TOKEN` | 이 잡의 Generic Webhook Trigger 토큰(Jenkins 잡 설정에 넣은 값과 같다) |

`JENKINS_URL` 이 비어 있으면 릴리스까지만 하고 호출은 건너뛴다 — CI 가 빨간불이 되지는 않는다.
URL 은 있는데 `JENKINS_DEPLOY_TOKEN` 이 비어 있으면 CI 가 실패한다(릴리스는 이미 올라간 뒤다).

토큰은 **인증 없이 배포를 거는 열쇠**다 — Jenkins 는 인터넷에서 열려 있다. 그래서 레포 어디에도
적지 않고 Jenkins 잡 설정과 이 Secret 두 곳에만 둔다. 새로 만들 때는 추측하기 어려운 임의 값
(`openssl rand -hex 32` 등)을 쓰고, 레포 이름 같은 짐작 가능한 값을 쓰지 않는다.

### 3. Jenkins job

**job 은 하나다.** dev/prod 를 job 으로 가르지 않고 파라미터로 가른다 — 다른 groo
레포와 같은 방식이고, 배포 절차가 한 벌만 있어야 두 곳이 어긋나지 않는다.

**파이프라인은 레포의 [Jenkinsfile](../Jenkinsfile) 이 SoT 다.** 다른 groo 레포와 같다 —
job 설정에서 **Pipeline script from SCM** 을 고르고 이 레포를 가리키면 된다. Jenkins 화면에
groovy 를 붙여넣으면 고칠 때마다 두 곳을 맞춰야 하고, 한쪽만 고쳐진 채로 흘러간다.

| 항목 | 값 |
|---|---|
| Definition | Pipeline script from SCM |
| SCM | Git — `https://github.com/lshdainty/groo-damda-app.git` |
| Branch | `*/main` |
| Script Path | `Jenkinsfile` |

웹훅 트리거(Generic Webhook Trigger)는 **Jenkinsfile 이 아니라 job 설정(Jenkins UI)에 둔다.**
Jenkinsfile 의 `triggers` 블록은 빌드마다 잡 설정을 덮어써서, 파일에서 지우면 잡의 트리거도
통째로 사라진다(PR #287). 그리고 토큰을 레포에 평문으로 둘 수 없다. job 설정에서 켜고 아래를 넣는다.

| 항목 | 값 |
|---|---|
| Token | 위 `JENKINS_DEPLOY_TOKEN` Secret 과 같은 값 |
| Post content parameters | `CHANNEL` = `$.channel`, `VERSION` = `$.version` (JSONPath) |
| 위 두 변수의 Default value | **비워 둔다** — 채우면 수동 실행도 웹훅으로 오판해 `Resolve` 단계가 거부한다 |

예전 문서는 토큰을 레포에 적힌 고정 이름으로 안내했다. 그 값은 이미 바꿨고 다시 쓰지 않는다.

값은 플러그인이 **환경변수**로 넣는다. `parameters` 를 선언하면 같은 이름끼리 부딪히므로
`params.CHANNEL` 이 아니라 `env.CHANNEL` 로 읽는다. 표현식이 안 맞아 값이 비어 오면
`Resolve` 단계가 멈춘다 — 잘못 배포되느니 실패하는 게 낫다.

job 설정에서 **"필요한 경우 동시 빌드 실행"** 을 켜 둔다. 안 켜면 운영 승인을 기다리는
동안 main 머지로 들어온 dev 배포가 그 뒤에 줄을 선다.

배포 절차 자체는 [.github/jenkins/deploy.sh](jenkins/deploy.sh) 한 벌뿐이다. dev·prod 가
같은 길을 걸어야 한쪽만 고쳐져 어긋나지 않는다.

경로를 바꾸려면 job 환경변수 `APK_BASE_PATH` 를 준다 (기본 `/home/groo/groo/apk`).

서버에 디렉토리를 만들어 둔다.

```bash
mkdir -p /home/groo/groo/apk/{dev,prod}
```

### 4. nginx

정적 파일만 내보낸다. 업로드·실행 경로는 두지 않는다.

**`damda.hangroo.io` 서버 블록 안**에 넣는다. `location` 은 `server` 안에만 올 수 있어서
`http` 직속에 두면 `"location" directive is not allowed here` 로 기동 자체가 막힌다.

```nginx
# APK/IPA 배포 — 파일명을 정규식으로 묶어 경로 탈출을 원천 차단한다.
location ~ ^/download/(?<f>[A-Za-z0-9._-]+\.(apk|ipa|json))$ {
    alias /srv/apk/prod/$f;
    autoindex off;
    limit_rate 3m;
    add_header X-Content-Type-Options nosniff;
}
# 위 패턴에 안 맞는 /download/ 요청은 전부 막는다(목록 노출·탐색 방지).
location /download/ { return 404; }
```

경로가 `/srv/apk` 인 이유는 nginx 가 컨테이너라서다. 호스트의 apk 디렉토리를 넣어 준다.

```yaml
    volumes:
      - /home/groo/groo/apk:/srv/apk:ro   # 앱이 받아 가기만 하면 되니 읽기 전용
```

볼륨 추가는 컨테이너를 다시 만들어야 붙는다(`docker compose up -d nginx-prod`).
설정 파일만 고쳤을 때는 무중단 reload 로 충분하다.

### 반영할 때 `-c` 를 빠뜨리지 말 것

컨테이너가 `nginx -c /etc/nginx/prod/nginx.conf` 로 뜬다. `-c` 없이 부르면 손도 안 댄
기본 설정을 검사해서 **문법이 틀려도 "syntax is ok" 가 나온다.** 그 상태로 두면 다음
재시작 때 nginx 가 안 뜬다.

```bash
docker exec nginx-prod nginx -t -c /etc/nginx/prod/nginx.conf
docker exec nginx-prod nginx -s reload -c /etc/nginx/prod/nginx.conf
```

`docker restart` 는 커넥션이 끊긴다. `-s reload` 는 기존 요청을 다 처리한 뒤 워커만 바꾼다.

### 잘 걸렸는지 확인

파일이 아직 없어도 404 는 정상이다. 다만 **왜 404 인지**는 에러 로그로 갈린다.

```bash
docker logs nginx-prod --since 5m 2>&1 | grep /srv/apk
```

`open() "/srv/apk/prod/version.json" failed` 가 보이면 location 이 제대로 잡혀 경로까지
들어간 것이다 — 설정이 안 걸렸으면 여기까지 오지도 않는다.

## iOS

`groo-desk-X.Y.Z.ipa` 는 **서명이 없다.** 받는 사람이 자기 Apple ID 로 서명해 넣어야
하고, 무료 Apple ID 로 서명하면 **7일마다 다시 서명**해야 한다. 개발자 계정은 필요 없지만
각자 PC 가 필요하다 — 일반 사용자에게 권할 경로는 아니고, 웹으로 안내하는 편이 낫다.

### 업데이트는 AltStore 로만 이어진다

아이폰은 스토어 밖 앱이 스스로를 업데이트할 수 없다. 앱 안 배너가 IPA 주소를 열어 줘도
서명이 없어 설치되지 않는다 — 파일만 받아지고 끝난다. 안드로이드처럼 "받아서 덮어쓰기"
가 되는 경로가 애초에 없다.

그래서 CI 가 IPA 와 함께 **AltStore 소스**(`altstore.json`)를 만든다. 쓰는 쪽은:

1. Mac 에 **AltServer**(`cdn.altstore.io/file/altstore/altserver.zip`, macOS 11+)를 깔고
   메뉴바 아이콘 → **Install AltStore** → 기기 선택 → Apple ID 로 아이폰에 AltStore 설치
2. AltStore → Sources → **＋** → `https://damda.hangroo.io/download/altstore.json`
3. 이후 새 버전은 AltStore 안에서 받는다. 앱 배너를 누르면 이 소스로 바로 넘어간다
   (`altstore://source?url=…`, AltStore 가 없으면 다운로드 페이지로 떨어진다)

설치된 앱은 AltStore 의 **My Apps** 에 남은 일수와 함께 뜬다. 거기 보여야 자동 갱신
대상이다 — 따로 깔아 둔 것(Xcode 로 올린 빌드 등)은 AltStore 가 관리하지 않는다.

**7일 만료도 여기서 풀린다.** AltServer 가 켜져 있고 아이폰이 같은 Wi-Fi 에 있으면
백그라운드로 다시 서명한다. USB 로 꽂을 필요도, 7일마다 손댈 일도 없어진다.

dev·prod 가 각자 소스를 가진다. 서버 블록마다 `/download/` 가 자기 채널 디렉토리를
열어 주므로(`alias /srv/apk/{dev,prod}/$f`) 주소도 채널을 따라가야 한다. CI 는 도메인을
직접 적지 않고 `config/{dev,prod}.json` 의 `WEB_BASE_URL` 을 읽는다 — 앱이 API 주소로
쓰는 그 값이라 한쪽만 바뀌어 어긋날 일이 없다.

    dev   https://damda-dev.hangroo.io/download/altstore.json
    prod  https://damda.hangroo.io/download/altstore.json

`iconURL` 은 `{WEB_BASE_URL}/app-icon.png` 다. 웹 프론트의 `public/app-icon.png` 라서
웹만 배포되면 따라 올라간다. nginx 의 `/download/` 패턴은 `apk|ipa|json` 만 받으므로
아이콘을 그쪽에 두면 404 가 난다 — 웹에 두는 이유다. **운영 태그 전에 웹을 먼저 배포**
해야 AltStore 목록에서 아이콘이 빈칸으로 뜨지 않는다.

### 걸리는 자리들

전부 한 번씩 밟아 본 것들이다.

**소스의 `version` 은 IPA 안의 값과 글자까지 같아야 한다.** 다르면 AltStore 가 16MB 를
다 받아 놓고 되돌린다 — `The downloaded version does not match the version specified by
the source`. iOS 의 `CFBundleShortVersionString` 은 숫자 마디만 받아서 IPA 에는 직전
태그의 숫자(`1.9.2`)만 들어간다. `git describe` 문자열(`1.9.2-50-g6f4a880`)은 여기 쓸 수
없고, 표시 전용 필드인 `marketingVersion` 으로 넘긴다. 업데이트 판정은 `buildVersion`
(= `CFBundleVersion` = CI run number)이 하므로 dev 빌드끼리도 구분된다.

**AltStore 는 bundle ID 뒤에 팀 ID 를 붙인다.** `com.porest.desk.porestDeskApp.78ZAZ4T43G`
같은 식이다(무료 계정의 App ID 한도를 아끼려는 것). iOS 는 이걸 다른 앱으로 보므로
Xcode 로 깔아 둔 게 있으면 **홈 화면에 아이콘이 두 개 생긴다.** 옛 것을 지우면 된다.
`altstore.json` 에는 원본 ID 를 적는다 — 접미사는 AltStore 가 설치 시점에 붙인다.

**개발자 모드 항목은 처음엔 설정에 없다.** 개발자 도구가 기기에 접근을 시도한 뒤에야
나타난다(iOS 16+). Xcode 로 Run 하거나 Devices 창을 열면 아이폰에 알림이 뜨고, 그때부터
`설정 → 개인정보 보호 및 보안 → 개발자 모드` 가 보인다. 켜고 재부팅해야 `flutter devices`
에도 기기가 잡힌다 — 꺼져 있으면 아예 목록에 안 나와서 연결이 안 된 것처럼 보인다.

**Wi-Fi 동기화를 켜야 7일 갱신이 자동으로 돈다.** Finder → 기기 → 일반 → "Wi-Fi에
연결되어 있을 때 이 iPhone 보기". 안 켜면 AltServer 가 USB 로 꽂을 때만 갱신한다.

**서버에 파일이 놓였는지는 Content-Type 으로 본다.** SPA 프록시가 `/download/` 를 받아
가면 없는 파일에도 `200` 이 돌아온다 — 내용은 `index.html` 이다. `200 application/json`
이어야 진짜다.

    curl -sk -o /dev/null -w "%{http_code} %{content_type}\n" \
      https://damda-dev.hangroo.io/download/version.json
