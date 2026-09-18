package app.schedulr.schedulr

import android.os.Bundle
import android.webkit.CookieManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "schedulr/bitc_cookie"
    private val allowedSuffix = ".bitc.edu.cn"
    private val allowedHost = "bitc.edu.cn"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "readCookies" -> result.success(readCookies())
                    "writeCookies" -> {
                        try {
                            writeCookies(call.argument<List<*>>("cookies") ?: emptyList<Any>())
                            result.success(null)
                        } catch (error: IllegalArgumentException) {
                            result.error("invalid_cookies", error.message, null)
                        }
                    }
                    "clearCookies" -> {
                        clearCookies()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun readCookies(): List<Map<String, Any?>> {
        val manager = CookieManager.getInstance()
        val result = mutableListOf<Map<String, Any?>>()
        for (host in listOf("https://vpn.bitc.edu.cn/", "https://jwxt.vpn.bitc.edu.cn/")) {
            val header = manager.getCookie(host) ?: continue
            for (part in header.split(";")) {
                val pair = part.trim().split("=", limit = 2)
                if (pair.size != 2 || pair[0].isBlank()) continue
                result += mapOf(
                    "name" to pair[0],
                    "value" to pair[1],
                    "domain" to host.removePrefix("https://").removeSuffix("/"),
                    "path" to "/",
                    "secure" to true,
                )
            }
        }
        return result.distinctBy { "${it["name"]}|${it["domain"]}|${it["path"]}" }
    }

    private fun writeCookies(rawCookies: List<*>) {
        val manager = CookieManager.getInstance()
        for (raw in rawCookies) {
            val map = raw as? Map<*, *> ?: throw IllegalArgumentException("cookie must be an object")
            val name = map["name"] as? String ?: throw IllegalArgumentException("cookie name missing")
            val value = map["value"] as? String ?: throw IllegalArgumentException("cookie value missing")
            val domain = (map["domain"] as? String)?.removePrefix(".")
                ?: throw IllegalArgumentException("cookie domain missing")
            require(isAllowedHost(domain)) { "cookie domain is not allowed" }
            val path = map["path"] as? String ?: "/"
            manager.setCookie(domainToUrl(domain), "$name=$value; Path=$path; Secure")
        }
        manager.flush()
    }

    private fun clearCookies() {
        val manager = CookieManager.getInstance()
        val hosts = listOf("https://vpn.bitc.edu.cn/", "https://jwxt.vpn.bitc.edu.cn/")
        for (host in hosts) {
            val header = manager.getCookie(host) ?: continue
            for (part in header.split(";")) {
                val name = part.trim().substringBefore("=").trim()
                if (name.isNotEmpty()) manager.setCookie(host, "$name=; Max-Age=0; Path=/")
            }
        }
        manager.flush()
    }

    private fun domainToUrl(domain: String): String = "https://$domain/"

    private fun isAllowedHost(host: String): Boolean =
        host == allowedHost || host.endsWith(allowedSuffix)
}
