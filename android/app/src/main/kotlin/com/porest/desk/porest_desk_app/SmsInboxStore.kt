package com.porest.desk.porest_desk_app

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/**
 * 아직 기록하지 않은 결제 문자 보관함.
 *
 * 알림만 띄우면 사용자가 알림을 쓸어 지우는 순간 문자가 사라진다 — 나중에
 * "그거 뭐였지" 하고 찾을 방법이 없어진다. 그래서 받은 문자를 여기 쌓아 두고
 * 앱에서 목록으로 볼 수 있게 한다.
 *
 * Flutter 의 shared_preferences 와 **다른 파일**을 쓴다. 같은 저장소에 네이티브가
 * 직접 쓰면 Flutter 쪽 키 규약(접두사·타입 표기)을 맞춰야 하고, 그 규약이 바뀌면
 * 조용히 깨진다. 읽기는 채널로 넘긴다.
 *
 * 무한정 쌓이지 않게 최근 [MAX_ENTRIES] 건만 남긴다.
 */
object SmsInboxStore {
    private const val PREFS_NAME = "porest_sms_inbox"
    private const val KEY_ENTRIES = "entries"
    private const val MAX_ENTRIES = 50

    /**
     * 최근에 같은 금액이 들어온 적 있는가 — 문자와 앱 알림이 같은 결제를 두 번 물어오는 걸 막는다.
     *
     * <p>카드사가 문자도 보내고 앱 푸시도 보내면 한 결제가 두 줄로 쌓인다. 금액과 시각으로
     * 대략만 가린다 — 같은 금액을 몇 분 안에 두 번 긁는 일(커피 두 잔)이 아주 없진 않지만,
     * 그 경우 사용자가 수신함에서 한 건 더 기록하면 되고, 반대로 중복이 쌓이는 쪽이
     * 훨씬 자주 성가시다.
     */
    fun hasRecentSameAmount(context: Context, text: String, now: Long, windowMillis: Long): Boolean {
        val amount = SmsPaymentFilter.amountOf(text) ?: return false
        val entries = readArray(context)
        for (i in 0 until entries.length()) {
            val o = entries.optJSONObject(i) ?: continue
            if (now - o.optLong("receivedAt") > windowMillis) continue
            if (SmsPaymentFilter.amountOf(o.optString("text")) == amount) return true
        }
        return false
    }

    fun add(context: Context, id: Long, text: String, receivedAt: Long) {
        val entries = readArray(context)
        val entry = JSONObject().apply {
            put("id", id)
            put("text", text)
            put("receivedAt", receivedAt)
        }
        // 최신이 앞으로 — 목록에서 방금 온 문자를 먼저 본다.
        val merged = JSONArray().put(entry)
        for (i in 0 until minOf(entries.length(), MAX_ENTRIES - 1)) {
            merged.put(entries.get(i))
        }
        write(context, merged)
    }

    fun all(context: Context): List<Map<String, Any?>> {
        val entries = readArray(context)
        return (0 until entries.length()).mapNotNull { i ->
            val o = entries.optJSONObject(i) ?: return@mapNotNull null
            mapOf(
                "id" to o.optLong("id"),
                "text" to o.optString("text"),
                "receivedAt" to o.optLong("receivedAt"),
            )
        }
    }

    /** 수신함 항목 하나. */
    data class Entry(val id: Long, val text: String, val receivedAt: Long)

    /**
     * 번호로 항목을 찾는다 — 알림을 눌러 들어올 때 본문을 인텐트가 아니라 여기서 읽는다.
     * 없거나 본문이 비었으면 null.
     */
    fun find(context: Context, id: Long): Entry? =
        findIn(prefs(context).getString(KEY_ENTRIES, null), id)

    /** [find] 의 저장소 없는 몸통 — 저장된 JSON 문자열에서 찾는다(단위 테스트용으로 떼어 둔다). */
    internal fun findIn(raw: String?, id: Long): Entry? {
        val entries = parse(raw)
        for (i in 0 until entries.length()) {
            val o = entries.optJSONObject(i) ?: continue
            if (o.optLong("id", -1L) != id) continue
            val text = o.optString("text")
            if (text.isEmpty()) return null
            return Entry(id, text, o.optLong("receivedAt"))
        }
        return null
    }

    fun remove(context: Context, id: Long) {
        val entries = readArray(context)
        val kept = JSONArray()
        for (i in 0 until entries.length()) {
            val o = entries.optJSONObject(i) ?: continue
            if (o.optLong("id") != id) kept.put(o)
        }
        write(context, kept)
    }

    fun clear(context: Context) {
        write(context, JSONArray())
    }

    private fun readArray(context: Context): JSONArray =
        parse(prefs(context).getString(KEY_ENTRIES, null))

    private fun parse(raw: String?): JSONArray {
        if (raw == null) return JSONArray()
        return runCatching { JSONArray(raw) }.getOrElse { JSONArray() }
    }

    private fun write(context: Context, array: JSONArray) {
        prefs(context).edit().putString(KEY_ENTRIES, array.toString()).apply()
    }

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
}
