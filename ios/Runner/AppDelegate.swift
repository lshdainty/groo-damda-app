import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "PorestClipboardHint") {
      ClipboardHintChannel.register(with: registrar)
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "PorestScreenPrivacy") {
      ScreenPrivacyChannel.register(with: registrar)
    }
  }
}

/// 화면 보호 채널(보안 점검 CLI-5) — 앱 잠금 · 금액 가리기 중에는 앱이 백그라운드로 나갈 때
/// 가림막을 덮는다.
///
/// 잠금 화면 · 금액 가리기는 Flutter 가 그리는 덮개라, 백그라운드 진입 직후 iOS 가 찍는
/// 앱 스위처 스냅샷보다 늦게 그려질 수 있다. 그래서 네이티브 뷰를 창 맨 위에 바로 얹는다.
/// iOS 에는 스크린샷을 막는 공개 API 가 없어 여기서는 스냅샷만 가린다.
///
/// 켜고 끄는 판단은 Dart(`screen_protection.dart`)가 한다 — 여기서는 값만 들고 있다.
/// inactive(제어 센터 · Face ID 프롬프트)에는 덮지 않는다 — 잠금 해제 프롬프트 아래가 가려져
/// 깜빡이고, 그 순간에는 스냅샷도 찍히지 않는다.
enum ScreenPrivacyChannel {
  private static let channelName = "porest/screen_privacy"
  private static let coverTag = 0x5EC5C1

  /// Dart 가 마지막으로 알린 값.
  private static var isProtected = false

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: registrar.messenger())

    channel.setMethodCallHandler { call, result in
      guard call.method == "setProtected" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let args = call.arguments as? [String: Any], let on = args["on"] as? Bool else {
        result(FlutterError(code: "bad_args", message: "on is required", details: nil))
        return
      }
      isProtected = on
      result(nil)
    }

    let center = NotificationCenter.default
    center.addObserver(
      forName: UIScene.didEnterBackgroundNotification, object: nil, queue: .main
    ) { note in
      guard isProtected, let scene = note.object as? UIWindowScene else { return }
      scene.windows.forEach(cover)
    }
    // 돌아와 활성이 될 때 걷는다 — 그때는 Flutter 잠금 화면이 이미 그려져 있다.
    center.addObserver(
      forName: UIScene.didActivateNotification, object: nil, queue: .main
    ) { note in
      guard let scene = note.object as? UIWindowScene else { return }
      scene.windows.forEach(uncover)
    }
  }

  private static func cover(_ window: UIWindow) {
    guard window.viewWithTag(coverTag) == nil else { return }
    let view = UIView(frame: window.bounds)
    view.tag = coverTag
    view.backgroundColor = .systemBackground
    view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    window.addSubview(view)
  }

  private static func uncover(_ window: UIWindow) {
    window.viewWithTag(coverTag)?.removeFromSuperview()
  }
}

/// 클립보드를 **읽지 않고** 힌트만 넘겨 주는 채널.
///
/// iOS 는 앱이 클립보드 내용을 읽을 때마다 "○○에서 붙여넣기" 배너를 띄운다.
/// 홈에 들어올 때마다 읽으면 그 배너가 계속 떠 사용자를 괴롭히므로,
/// 여기서는 내용 접근이 없는 두 가지만 본다.
///
/// - `changeCount` — 클립보드가 바뀔 때마다 오르는 정수. 같은 복사본에 대해
///   배너를 다시 띄우지 않으려고 쓴다(사용자가 한 번 닫으면 그 값을 기억한다).
/// - `hasText` — 문자열이 들어 있는가(`hasStrings`). 내용은 넘어오지 않는다.
///
/// 처음에는 `detectPatterns(for: [.number])` 로 "금액이 들어 있는가" 까지 좁히려 했다.
/// 결제 문자에는 금액이 반드시 있으니 더 정확한 신호가 될 줄 알았는데, 실제로 넣어 보니
/// 한국어 결제 문자("5,500원 일시불 08/13 13:22")에서 <b>숫자를 감지하지 못했다</b>
/// (iOS 26 시뮬레이터 실측). 이 패턴은 문장에 섞인 숫자가 아니라 독립된 숫자 값을 찾는 듯하다.
/// 그래서 "텍스트가 있는가" 까지만 보고, 결제 문자인지는 사용자가 배너를 눌러
/// 실제로 읽은 뒤 프리필터로 가린다.
///
/// 실제 읽기는 사용자가 배너를 눌렀을 때 Dart 쪽에서 한 번만 한다.
///
/// (별도 파일로 두려면 Xcode 프로젝트에 파일 참조를 추가해야 해서 여기 함께 둔다.)
enum ClipboardHintChannel {
  private static let channelName = "porest/clipboard_hint"

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: registrar.messenger())

    channel.setMethodCallHandler { call, result in
      guard call.method == "hint" else {
        result(FlutterMethodNotImplemented)
        return
      }
      respondWithHint(result)
    }
  }

  private static func respondWithHint(_ result: @escaping FlutterResult) {
    let board = UIPasteboard.general
    // 둘 다 내용을 읽지 않는다 — 붙여넣기 배너가 뜨지 않는 선까지만 본다.
    result(["changeCount": board.changeCount, "hasText": board.hasStrings])
  }
}
