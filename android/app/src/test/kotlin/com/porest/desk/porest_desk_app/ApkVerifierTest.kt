package com.porest.desk.porest_desk_app

import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * 받은 APK 를 설치 화면에 넘기기 전 대조(보안 점검 CLI-3) — 패키지 이름과 서명 지문이
 * 지금 앱과 같을 때만 통과다.
 */
class ApkVerifierTest {
    private val own = "com.porest.desk.porest_desk_app"
    private val key = setOf("aa11")

    @Test
    fun `패키지 이름과 서명이 같으면 통과다`() {
        assertEquals(ApkVerifier.OK, ApkVerifier.decide(own, own, key, key))
    }

    @Test
    fun `패키지 이름이 다르면 거절한다 — 다른 앱이 새 앱으로 깔리는 길`() {
        assertEquals(
            ApkVerifier.PACKAGE_MISMATCH,
            ApkVerifier.decide("com.evil.app", own, key, key),
        )
    }

    @Test
    fun `서명이 다르면 거절한다`() {
        assertEquals(
            ApkVerifier.SIGNATURE_MISMATCH,
            ApkVerifier.decide(own, own, setOf("bb22"), key),
        )
    }

    @Test
    fun `서명자를 하나 더 얹은 파일도 거절한다 — 겹침이 아니라 같음을 본다`() {
        assertEquals(
            ApkVerifier.SIGNATURE_MISMATCH,
            ApkVerifier.decide(own, own, key + "bb22", key),
        )
    }

    @Test
    fun `APK 로 읽히지 않거나 서명을 못 읽으면 통과시키지 않는다`() {
        assertEquals(ApkVerifier.UNREADABLE, ApkVerifier.decide(null, own, key, key))
        assertEquals(ApkVerifier.UNREADABLE, ApkVerifier.decide(own, own, emptySet(), key))
        assertEquals(ApkVerifier.UNREADABLE, ApkVerifier.decide(own, own, key, emptySet()))
    }

    @Test
    fun `지문은 인증서 바이트의 SHA-256 소문자 16진수다`() {
        assertEquals(
            "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
            ApkVerifier.sha256Hex("abc".toByteArray()),
        )
    }
}
