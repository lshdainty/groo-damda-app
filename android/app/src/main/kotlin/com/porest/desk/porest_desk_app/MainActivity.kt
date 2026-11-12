package com.porest.desk.porest_desk_app

import android.Manifest
import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import android.view.WindowManager
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * 결제 문자 수신 기능의 안드로이드 창구.
 *
 * 문자 수신·알림은 [SmsReceiver] 가 앱과 무관하게 처리하고(앱이 꺼져 있어도 온다),
 * 여기서는 Flutter 가 필요로 하는 것만 넘긴다 — 권한 상태·보관함·알림으로 들어온 문자.
 *
 * FlutterFragmentActivity 인 이유: 앱 잠금의 생체인증(local_auth)이 androidx
 * BiometricPrompt 를 쓰는데, 이 API 가 FragmentActivity 를 요구한다.
 */
class MainActivity : FlutterFragmentActivity() {

    /**
     * 알림을 눌러 들어왔을 때의 수신함 번호. Flutter 가 가져가면 비운다.
     *
     * <p>본문은 인텐트로 받지 않는다 — 이 화면은 런처라 외부에 열려 있어, 다른 앱이 아무 글이나
     * 실어 보낼 수 있다(보안 점검 CLI-4). 번호만 받고 본문은 알림 리스너가 앱 저장소
     * ([SmsInboxStore])에 남긴 것을 읽는다. 수신함에 없는 번호는 버린다.
     */
    private var pendingSmsId: Long? = null

    private var permissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result -> handle(call, result) }
        // 설치 차단 안내는 결제 감지와 무관해 채널을 따로 둔다.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DEVICE_CHANNEL)
            .setMethodCallHandler { call, result -> handleDevice(call, result) }
        // 화면 보호(보안 점검 CLI-5) — 앱 잠금 · 금액 가리기 중에는 캡처 · 녹화 · 최근 앱 미리보기를 막는다.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PRIVACY_CHANNEL)
            .setMethodCallHandler { call, result -> handlePrivacy(call, result) }
        // 앱 업데이트 — 받은 APK 를 설치 화면에 넘기기 전에 이 앱인지 대조한다(보안 점검 CLI-3).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, UPDATE_CHANNEL)
            .setMethodCallHandler { call, result -> handleUpdate(call, result) }
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        capturePending(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // singleTop 이라 앱이 이미 떠 있으면 여기로 들어온다.
        setIntent(intent)
        capturePending(intent)
    }

    /**
     * 알림에서 들어온 수신함 번호를 붙잡아 둔다.
     *
     * Flutter 가 아직 붙기 전에 도착할 수 있어 바로 넘기지 못한다 —
     * 들고 있다가 Dart 가 물어볼 때 건넨다. 본문은 그때 수신함에서 읽는다.
     */
    private fun capturePending(intent: Intent?) {
        if (intent == null) return
        // 옛 알림(본문을 싣던 빌드)이나 외부 앱이 실은 본문은 읽지 않고 지운다.
        intent.removeExtra(LEGACY_EXTRA_SMS_TEXT)
        if (!intent.hasExtra(EXTRA_SMS_ID)) return
        pendingSmsId = intent.getLongExtra(EXTRA_SMS_ID, -1L).takeIf { it >= 0 }
        // 화면 회전 등으로 같은 인텐트가 다시 오면 이미 처리한 문자가 되살아난다.
        intent.removeExtra(EXTRA_SMS_ID)
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "hasPermissions" -> result.success(hasPermissions())
            "requestPermissions" -> requestPermissions(result)
            "inbox" -> result.success(SmsInboxStore.all(this))
            "removeFromInbox" -> {
                val id = (call.argument<Number>("id"))?.toLong()
                if (id == null) {
                    result.error("bad_args", "id is required", null)
                } else {
                    SmsInboxStore.remove(this, id)
                    result.success(null)
                }
            }
            "clearInbox" -> {
                SmsInboxStore.clear(this)
                result.success(null)
            }
            "hasNotificationAccess" -> result.success(hasNotificationAccess())
            "openNotificationAccessSettings" -> {
                openNotificationAccessSettings()
                result.success(null)
            }
            "consumePendingSms" -> {
                val id = pendingSmsId
                pendingSmsId = null
                // 알림 리스너가 저장한 항목만 쓴다 — 없는 번호(지운 항목 · 지어낸 번호)는 아무것도 열지 않는다.
                val entry = id?.let { SmsInboxStore.find(this, it) }
                result.success(entry?.let { mapOf("text" to it.text, "id" to it.id) })
            }
            else -> result.notImplemented()
        }
    }

    /**
     * 창에 FLAG_SECURE 를 걸거나 푼다.
     *
     * <p>잠금 화면 · 금액 가리기는 Flutter 가 그리는 덮개라, 앱이 나가는 순간 시스템이 찍는
     * 최근 앱 미리보기보다 늦을 수 있다. FLAG_SECURE 가 걸린 창은 미리보기 · 스크린샷 ·
     * 화면 녹화에 내용이 나가지 않는다. 켜고 끄는 판단은 Dart(screen_protection.dart)가 한다.
     */
    private fun handlePrivacy(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "setProtected" -> {
                val on = call.argument<Boolean>("on")
                if (on == null) {
                    result.error("bad_args", "on is required", null)
                    return
                }
                if (on) {
                    window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                } else {
                    window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                }
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    /**
     * 받은 APK 대조. APK 를 풀고 인증서를 해시하느라 수백 ms 가 걸릴 수 있어 UI 스레드 밖에서
     * 하고, 결과만 UI 스레드에서 돌려준다.
     */
    private fun handleUpdate(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "verifyApk" -> {
                val path = call.argument<String>("path")
                if (path.isNullOrEmpty()) {
                    result.error("bad_args", "path is required", null)
                    return
                }
                val app = applicationContext
                Thread {
                    val verdict = ApkVerifier.verify(app, path)
                    runOnUiThread { result.success(verdict) }
                }.start()
            }
            else -> result.notImplemented()
        }
    }

    /** 기기 특성 안내 — 지금은 삼성 자동 차단뿐이다. */
    private fun handleDevice(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isAutoBlockerDevice" -> result.success(AutoBlockerGuide.isSupported())
            "openAutoBlockerSettings" -> result.success(AutoBlockerGuide.open(this))
            else -> result.notImplemented()
        }
    }

    /**
     * 알림을 띄울 수 있는가 (Android 13+ 의 POST_NOTIFICATIONS).
     *
     * <p>결제 감지 자체와는 별개다 — 이게 없어도 알림 접근만 켜져 있으면 보관함에는
     * 쌓인다. 알림으로 바로 기록하러 가는 동선만 빠질 뿐이다.
     */
    private fun hasPermissions(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return true
        return ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
    }

    private fun requestPermissions(result: MethodChannel.Result) {
        if (hasPermissions()) {
            result.success(true)
            return
        }
        // 앞선 요청이 아직 안 끝났으면 그것부터 끝내게 둔다 — 대화상자를 겹쳐 띄우지 않는다.
        if (permissionResult != null) {
            result.success(false)
            return
        }
        permissionResult = result
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            REQUEST_CODE,
        )
    }

    /**
     * 알림 접근이 켜져 있는가 — <b>이 값 하나가 결제 감지의 on/off 다.</b>
     *
     * <p>카드사·은행 앱 푸시는 물론 문자까지 전부 이 경로로 읽는다.
     */
    private fun hasNotificationAccess(): Boolean =
        NotificationManagerCompat.getEnabledListenerPackages(this).contains(packageName)

    /**
     * 설정의 알림 접근 화면을 연다.
     *
     * <p>이 권한은 런타임 팝업으로 받을 수 없다 — 사용자가 설정에서 직접 켜야 한다.
     * 안드로이드 11부터는 <b>우리 앱 항목의 상세 화면</b>으로 바로 보낼 수 있어서
     * 목록에서 앱을 찾아 헤맬 필요가 없다. 그 이전 버전은 목록 화면까지만 데려다준다.
     */
    private fun openNotificationAccessSettings() {
        val component = ComponentName(this, PaymentNotificationListener::class.java)
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Intent(Settings.ACTION_NOTIFICATION_LISTENER_DETAIL_SETTINGS).putExtra(
                Settings.EXTRA_NOTIFICATION_LISTENER_COMPONENT_NAME,
                component.flattenToString(),
            )
        } else {
            Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
        }
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        runCatching { startActivity(intent) }.onFailure {
            // 제조사 롬에 그 화면이 없을 수 있다 — 목록 화면으로 물러선다.
            runCatching {
                startActivity(
                    Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                )
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != REQUEST_CODE) return
        val pending = permissionResult ?: return
        permissionResult = null
        val index = permissions.indexOf(Manifest.permission.POST_NOTIFICATIONS)
        val granted = index >= 0 &&
            grantResults.getOrNull(index) == PackageManager.PERMISSION_GRANTED
        pending.success(granted)
    }

    companion object {
        private const val CHANNEL = "porest/sms_android"
        private const val DEVICE_CHANNEL = "porest/device_guide"
        private const val PRIVACY_CHANNEL = "porest/screen_privacy"
        private const val UPDATE_CHANNEL = "porest/app_update"
        private const val REQUEST_CODE = 6301

        const val EXTRA_SMS_ID = "porest.sms.id"

        /** 예전 알림이 본문을 싣던 키. 이제 읽지 않고 들어오면 지우기만 한다. */
        private const val LEGACY_EXTRA_SMS_TEXT = "porest.sms.text"
    }
}
