package com.porest.desk.porest_desk_app

import android.content.Context
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.content.pm.Signature
import android.os.Build
import java.security.MessageDigest

/**
 * 받은 APK 가 이 앱의 새 빌드인지 대조한다(보안 점검 CLI-3).
 *
 * <p>앱 업데이트는 버전 파일과 APK 를 HTTPS 로 받을 뿐 "누가 만든 파일인가" 는 보지 않았다.
 * 배포 경로가 장악되면 업데이트 화면에서 다른 앱을 깔게 할 수 있다. 같은 패키지에 다른
 * 서명은 시스템이 설치에서 막아 주지만, **패키지 이름이 다르면 새 앱으로 깔린다.** 그래서
 * 설치 화면을 열기 전에 [PackageManager.getPackageArchiveInfo] 로 받은 파일을 읽어
 * 패키지 이름과 서명 인증서(SHA-256 지문)를 지금 깔린 앱과 맞춘다.
 *
 * <p>서명 키를 돌리면(키 교체) 지문이 달라 여기서 막힌다 — 키를 바꿀 일이 생기면 이 대조부터
 * 손봐야 한다.
 */
object ApkVerifier {
    const val OK = "ok"
    const val PACKAGE_MISMATCH = "packageMismatch"
    const val SIGNATURE_MISMATCH = "signatureMismatch"
    const val UNREADABLE = "unreadable"

    fun verify(context: Context, path: String): String {
        val pm = context.packageManager
        val archive = runCatching { archiveInfo(pm, path) }.getOrNull()
        val installed = runCatching { installedInfo(pm, context.packageName) }.getOrNull()
        return decide(
            archivePackage = archive?.packageName,
            ownPackage = context.packageName,
            archiveSigners = orFallback(archive?.let(::signerDigests).orEmpty()) {
                legacyArchiveSigners(pm, path)
            },
            ownSigners = installed?.let(::signerDigests).orEmpty(),
        )
    }

    /**
     * 첫 값이 비었을 때만 대체 경로를 읽는다.
     *
     * <p>안드로이드 9(API 28)는 **아카이브 파일**에 `GET_SIGNING_CERTIFICATES` 를 줘도
     * `signingInfo` 를 채우지 않는다(설치된 앱은 채운다, API 29 부터 아카이브도 채운다).
     * 그대로 두면 정상 APK 도 [UNREADABLE] 로 거절돼 그 기기는 앱 안에서 업데이트할 길이
     * 없어진다. 그래서 비었으면 옛 `GET_SIGNATURES`(`info.signatures`)로 한 번 더 읽는다.
     * 키 교체를 쓰지 않으므로 두 방식이 같은 인증서를 돌려준다.
     */
    internal fun orFallback(primary: Set<String>, fallback: () -> Set<String>): Set<String> =
        primary.ifEmpty { runCatching(fallback).getOrNull().orEmpty() }

    @Suppress("DEPRECATION")
    private fun legacyArchiveSigners(pm: PackageManager, path: String): Set<String> {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) return emptySet() // 이미 GET_SIGNATURES 로 읽었다
        val info = pm.getPackageArchiveInfo(path, PackageManager.GET_SIGNATURES) ?: return emptySet()
        return info.signatures?.map { sha256Hex(it.toByteArray()) }?.toSet().orEmpty()
    }

    /**
     * 판정의 몸통 — 플랫폼 없이 단위 테스트할 수 있게 떼어 둔다.
     *
     * <p>서명은 집합이 **같을 때만** 통과다. 하나라도 겹치면 통과로 보면, 서명자를 하나 더 얹은
     * 파일이 지나간다.
     */
    internal fun decide(
        archivePackage: String?,
        ownPackage: String,
        archiveSigners: Set<String>,
        ownSigners: Set<String>,
    ): String {
        if (archivePackage == null) return UNREADABLE
        if (archivePackage != ownPackage) return PACKAGE_MISMATCH
        if (archiveSigners.isEmpty() || ownSigners.isEmpty()) return UNREADABLE
        return if (archiveSigners == ownSigners) OK else SIGNATURE_MISMATCH
    }

    /** 인증서 바이트의 SHA-256 지문(소문자 16진수). */
    internal fun sha256Hex(bytes: ByteArray): String =
        MessageDigest.getInstance("SHA-256").digest(bytes)
            .joinToString("") { "%02x".format(it) }

    private fun signerDigests(info: PackageInfo): Set<String> =
        signers(info).map { sha256Hex(it.toByteArray()) }.toSet()

    @Suppress("DEPRECATION")
    private fun signers(info: PackageInfo): List<Signature> =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            // 지금 APK 내용에 서명한 인증서들 — 키 교체 이력(옛 인증서)은 넣지 않는다.
            info.signingInfo?.apkContentsSigners?.toList().orEmpty()
        } else {
            info.signatures?.toList().orEmpty()
        }

    @Suppress("DEPRECATION")
    private fun signatureFlag(): Int =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            PackageManager.GET_SIGNING_CERTIFICATES
        } else {
            PackageManager.GET_SIGNATURES
        }

    @Suppress("DEPRECATION")
    private fun archiveInfo(pm: PackageManager, path: String): PackageInfo? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.getPackageArchiveInfo(
                path,
                PackageManager.PackageInfoFlags.of(signatureFlag().toLong()),
            )
        } else {
            pm.getPackageArchiveInfo(path, signatureFlag())
        }

    @Suppress("DEPRECATION")
    private fun installedInfo(pm: PackageManager, packageName: String): PackageInfo =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.getPackageInfo(
                packageName,
                PackageManager.PackageInfoFlags.of(signatureFlag().toLong()),
            )
        } else {
            pm.getPackageInfo(packageName, signatureFlag())
        }
}
