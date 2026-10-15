package com.michaeldevtool.savetic

import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Recibe el texto que otra app comparte hacia SaveReel (por ejemplo el enlace de
 * un video desde «Compartir») y se lo pasa a Flutter por el canal `savetic/share`.
 * También responde por el canal `savetic/network` si la red actual es de pago.
 */
class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null

    /** Texto con el que se abrió la app; se entrega una sola vez. */
    private var initialText: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        initialText = sharedText(intent)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NETWORK_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isMetered" -> result.success(isMetered())
                    else -> result.notImplemented()
                }
            }
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).also {
            it.setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialText" -> {
                        result.success(initialText)
                        initialText = null
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    /** La app ya estaba abierta y el usuario compartió otro enlace. */
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        sharedText(intent)?.let { channel?.invokeMethod("onSharedText", it) }
    }

    private fun sharedText(intent: Intent?): String? {
        if (intent?.action != Intent.ACTION_SEND) return null
        if (intent.type?.startsWith("text/") != true) return null
        return intent.getStringExtra(Intent.EXTRA_TEXT)
    }

    /** Datos móviles, o un Wi-Fi que el sistema marca como de pago. */
    private fun isMetered(): Boolean {
        val manager = getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
        return manager?.isActiveNetworkMetered ?: false
    }

    private companion object {
        const val CHANNEL = "savetic/share"
        const val NETWORK_CHANNEL = "savetic/network"
    }
}
