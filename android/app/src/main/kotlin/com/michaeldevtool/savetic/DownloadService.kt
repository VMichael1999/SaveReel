package com.michaeldevtool.savetic

import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.content.ContextCompat

/**
 * Servicio en primer plano que mantiene viva la app mientras se descarga, para
 * que el sistema no la cierre al pasar a segundo plano. La descarga misma la
 * hace Flutter; esto solo la sostiene y muestra la notificación de progreso.
 */
class DownloadService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        running = true
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val notification = DownloadNotifications.progress(
            this,
            intent?.getStringExtra(EXTRA_HEADING) ?: "",
            intent?.getStringExtra(EXTRA_DETAIL) ?: "",
            intent?.getIntExtra(EXTRA_PERCENT, -1) ?: -1,
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                DownloadNotifications.PROGRESS_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC,
            )
        } else {
            startForeground(DownloadNotifications.PROGRESS_ID, notification)
        }
        // Si el sistema lo cierra, no se reinicia solo: Flutter ya no estaría.
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        running = false
        super.onDestroy()
    }

    companion object {
        const val EXTRA_HEADING = "heading"
        const val EXTRA_DETAIL = "detail"
        const val EXTRA_PERCENT = "percent"

        @Volatile
        var running = false
            private set

        /**
         * Arranca el servicio, o solo actualiza su notificación si ya corre:
         * arrancarlo desde segundo plano lo prohíbe Android 12 en adelante.
         */
        fun show(context: Context, heading: String, detail: String, percent: Int) {
            if (running) {
                DownloadNotifications.updateProgress(context, heading, detail, percent)
                return
            }
            val intent = Intent(context, DownloadService::class.java)
                .putExtra(EXTRA_HEADING, heading)
                .putExtra(EXTRA_DETAIL, detail)
                .putExtra(EXTRA_PERCENT, percent)
            ContextCompat.startForegroundService(context, intent)
        }

        fun hide(context: Context) {
            context.stopService(Intent(context, DownloadService::class.java))
        }
    }
}
