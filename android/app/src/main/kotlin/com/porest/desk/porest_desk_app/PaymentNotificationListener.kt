package com.porest.desk.porest_desk_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat

/**
 * 카드사 앱이 띄운 결제 알림을 읽어 기록 대상으로 삼는다.
 *
 * <p><b>왜 필요한가</b> — 카드사들이 승인 내역을 문자 대신 자사 앱 푸시로 보내는 쪽으로
 * 옮겨 갔다. 문자만 보면 카드에 따라 아무것도 안 잡힌다. 체크카드는 한 술 더 떠서
 * 발급 주체가 은행이라 결제 알림이 <b>은행 앱</b>으로 온다(토스·카카오뱅크·케이뱅크).
 *
 * <p><b>문자도 여기서 읽는다.</b> 예전에는 {@code RECEIVE_SMS} 로 직접 받았는데, 그
 * 권한이 붙은 앱을 브라우저·메신저로 설치하면 Play Protect 가 자동 차단한다 —
 * 금융사기 악성앱이 쓰는 조합이라서다. 사이드로드로 배포하는 우리에겐 설치 자체가
 * 막히는 문제라, 기본 메시지 앱의 알림을 읽는 쪽으로 옮겨 권한을 하나로 합쳤다.
 * 파서는 출처를 가리지 않으므로 결과는 같다.
 *
 * <p><b>권한의 무게</b> — 알림 접근은 기기의 <b>모든 알림</b>을 볼 수 있는 특수 권한이다
 * (사용자가 설정에서 직접 켜야 하고, 런타임 팝업으로는 받을 수 없다). 그래서
 * {@link PaymentAppPackages} 에 적힌 앱이 보낸 것만 들여다보고 나머지는 즉시 버린다 —
 * 메신저 내용이 우리 코드에 잠깐이라도 머무르지 않게 한다.
 *
 * <p>은행 앱은 결제 말고도 입금·이체·잔액 알림을 훨씬 많이 보낸다. 카드사 앱과 같은
 * 잣대로 걸렀다간 계좌이체 출금이 지출로 둔갑하므로 소스를 나눠 더 엄격하게 본다.
 *
 * <p>여기서도 지출을 만들지 않는다. 문자 경로와 똑같이 수신함에 적어 두고, 사용자가
 * 확인 화면에서 저장한다.
 */
class PaymentNotificationListener : NotificationListenerService() {

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        val sbnSafe = sbn ?: return
        val source = PaymentAppPackages.sourceOf(sbnSafe.packageName) ?: return

        // "메시지 3개" 같은 묶음 알림에는 본문이 없다 — 개별 알림만 본다.
        if (sbnSafe.notification?.flags?.and(Notification.FLAG_GROUP_SUMMARY) != 0) return

        val body = mergeText(sbnSafe) ?: return
        val isPayment = when (source) {
            // 문자는 카드사가 보낸 승인 내역 그대로라 카드사 앱과 같은 잣대로 본다.
            PaymentAppPackages.Source.CARD_APP,
            PaymentAppPackages.Source.MESSAGING_APP -> SmsPaymentFilter.looksLikePayment(body)
            PaymentAppPackages.Source.BANK_APP -> SmsPaymentFilter.looksLikeCardPaymentFromBank(body)
        }
        if (!isPayment) return

        val now = System.currentTimeMillis()
        // 같은 결제를 문자로도 받았을 수 있다 — 몇 분 안의 같은 금액이면 접는다.
        if (SmsInboxStore.hasRecentSameAmount(this, body, now, DEDUPE_WINDOW_MILLIS)) return

        SmsInboxStore.add(this, now, body, now)
        notifyQuietly(now, body)
    }

    /**
     * 알림에서 읽을 수 있는 텍스트를 한 덩어리로 모은다.
     *
     * <p>제목·본문·펼친 본문이 제각각이라(어떤 앱은 제목에 금액, 어떤 앱은 본문에 가맹점)
     * 전부 이어 붙여 서버 파서에 넘긴다. 파서가 필드별로 알아서 골라낸다.
     *
     * <p>카드사 이름이 본문에 없는 경우가 있어(앱 알림은 보낸 앱이 곧 카드사라 생략한다)
     * 앞에 붙여 준다 — 없으면 어느 카드인지 매칭할 단서가 사라진다.
     */
    private fun mergeText(sbn: StatusBarNotification): String? {
        val extras = sbn.notification?.extras ?: return null
        val title = extras.getCharSequence(NotificationCompat.EXTRA_TITLE)?.toString()?.trim()
        val text = extras.getCharSequence(NotificationCompat.EXTRA_TEXT)?.toString()?.trim()
        val bigText = extras.getCharSequence(NotificationCompat.EXTRA_BIG_TEXT)?.toString()?.trim()

        // 본문은 bigText 를 우선한다 — 펼친 본문은 짧은 text 를 <b>포함</b>하는 확장판이라
        // 둘 다 넣으면 "…승인 2,500원…" 이 통째로 두 번 찍힌다(현대카드 실측).
        // 전체 동등성만 보는 distinct 로는 이 포함 관계를 못 걸러 낸다.
        val bodyLine = bigText?.takeIf { it.isNotEmpty() } ?: text
        val parts = listOfNotNull(title, bodyLine)
            .filter { it.isNotEmpty() }.distinct()

        if (parts.isEmpty()) return null
        val body = parts.joinToString(separator = "\n")

        val issuer = PaymentAppPackages.issuerOf(sbn.packageName)
        return if (issuer != null && !body.contains(issuer)) "$issuer\n$body" else body
    }

    /**
     * 조용한 알림 — 소리·진동 없이 목록에만 남긴다.
     *
     * <p>카드사 앱이 이미 소리를 냈다. 같은 결제로 한 번 더 울리면 성가시기만 하다.
     * 그래도 알림을 띄우는 건 탭 한 번으로 기록 화면까지 가기 위해서다.
     */
    private fun notifyQuietly(id: Long, body: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ContextCompat.checkSelfPermission(this, android.Manifest.permission.POST_NOTIFICATIONS)
            != PackageManager.PERMISSION_GRANTED
        ) {
            return
        }
        ensureChannel()

        val launch = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            // 수신함 번호만 싣는다 — 본문은 앱이 수신함에서 읽는다(보안 점검 CLI-4).
            putExtra(MainActivity.EXTRA_SMS_ID, id)
        }
        val pending = PendingIntent.getActivity(
            this,
            id.toInt(),
            launch,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_groo)
            .setContentTitle(getString(R.string.sms_notification_title))
            .setContentText(SmsPaymentFilter.summarize(body))
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setSilent(true)
            .setAutoCancel(true)
            .setContentIntent(pending)
            .build()

        NotificationManagerCompat.from(this).notify(id.toInt(), notification)
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java) ?: return
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return

        val channel = NotificationChannel(
            CHANNEL_ID,
            getString(R.string.card_noti_channel),
            // 카드사 앱이 이미 울렸다 — 우리는 목록에만 남긴다.
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = getString(R.string.card_noti_channel_desc)
            setShowBadge(true)
        }
        manager.createNotificationChannel(channel)
    }

    companion object {
        private const val CHANNEL_ID = "porest_card_app_payment"

        /** 문자와 앱 알림이 같은 결제를 물어오는 간격 — 넉넉히 잡아도 오탐이 적다. */
        private const val DEDUPE_WINDOW_MILLIS = 5 * 60 * 1000L
    }
}
