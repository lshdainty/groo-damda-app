package com.porest.desk.porest_desk_app

import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/**
 * 알림을 눌러 들어올 때 본문은 인텐트가 아니라 수신함에서 읽는다(보안 점검 CLI-4).
 * 수신함에 없는 번호는 아무것도 돌려주지 않아야 한다 — 외부 앱이 지어낸 번호로 초안을 띄우지 못하게.
 */
class SmsInboxStoreTest {
    private fun stored(vararg entries: Triple<Long, String, Long>): String =
        JSONArray().apply {
            entries.forEach { (id, text, at) ->
                put(JSONObject().put("id", id).put("text", text).put("receivedAt", at))
            }
        }.toString()

    @Test
    fun `수신함에 있는 번호면 저장된 본문을 돌려준다`() {
        val raw = stored(
            Triple(2L, "신한카드 승인 5,500원 스타벅스", 2L),
            Triple(1L, "현대카드 승인 12,000원", 1L),
        )
        assertEquals(
            SmsInboxStore.Entry(1L, "현대카드 승인 12,000원", 1L),
            SmsInboxStore.findIn(raw, 1L),
        )
    }

    @Test
    fun `수신함에 없는 번호는 null 이다`() {
        val raw = stored(Triple(1L, "현대카드 승인 12,000원", 1L))
        assertNull(SmsInboxStore.findIn(raw, 999L))
    }

    @Test
    fun `수신함이 비었거나 깨졌으면 null 이다`() {
        assertNull(SmsInboxStore.findIn(null, 1L))
        assertNull(SmsInboxStore.findIn("", 1L))
        assertNull(SmsInboxStore.findIn("{not json", 1L))
    }

    @Test
    fun `본문이 빈 항목은 열지 않는다`() {
        val raw = stored(Triple(1L, "", 1L))
        assertNull(SmsInboxStore.findIn(raw, 1L))
    }
}
