package com.michaeldevtool.savetic

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Recibe el texto que otra app comparte hacia SaveTic (por ejemplo el enlace de
 * un video desde «Compartir») y se lo pasa a Flutter por el canal `savetic/share`.
 */
class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null

    /** Texto con el que se abrió la app; se entrega una sola vez. */
    private var initialText: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        initialText = sharedText(intent)
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

    private companion object {
        const val CHANNEL = "savetic/share"
    }
}
