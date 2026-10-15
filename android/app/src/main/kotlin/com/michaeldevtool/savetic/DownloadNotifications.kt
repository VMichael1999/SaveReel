package com.michaeldevtool.savetic

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat

/**
 * Notificaciones de las descargas: la de progreso, que acompaña al servicio en
 * primer plano, y la de «terminó» o «falló». Los textos los manda Flutter.
 */
object DownloadNotifications {
    const val PROGRESS_ID = 4101
    private const val PROGRESS_CHANNEL = "descargas_en_curso"
    private const val DONE_CHANNEL = "descargas_terminadas"
    private var nextDoneId = 4200

    fun progress(context: Context, heading: String, detail: String, percent: Int): Notification {
        ensureChannels(context)
        val builder = NotificationCompat.Builder(context, PROGRESS_CHANNEL)
            .setSmallIcon(android.R.drawable.stat_sys_download)
            .setContentTitle(heading)
            .setContentIntent(openApp(context))
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setCategory(NotificationCompat.CATEGORY_PROGRESS)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
        if (detail.isNotEmpty()) builder.setContentText(detail)
        // Sin porcentaje conocido la barra queda indefinida.
        builder.setProgress(100, percent.coerceAtLeast(0), percent < 0)
        return builder.build()
    }

    fun updateProgress(context: Context, heading: String, detail: String, percent: Int) {
        manager(context).notify(PROGRESS_ID, progress(context, heading, detail, percent))
    }

    fun finished(context: Context, heading: String, detail: String, success: Boolean) {
        ensureChannels(context)
        val notification = NotificationCompat.Builder(context, DONE_CHANNEL)
            .setSmallIcon(
                if (success) android.R.drawable.stat_sys_download_done
                else android.R.drawable.stat_notify_error
            )
            .setContentTitle(heading)
            .setContentText(detail)
            .setContentIntent(openApp(context))
            .setAutoCancel(true)
            .build()
        manager(context).notify(nextDoneId++, notification)
    }

    private fun manager(context: Context) =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    private fun openApp(context: Context): PendingIntent {
        val intent = Intent(context, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        return PendingIntent.getActivity(
            context, 0, intent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
    }

    private fun ensureChannels(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = manager(context)
        if (manager.getNotificationChannel(PROGRESS_CHANNEL) == null) {
            manager.createNotificationChannel(
                NotificationChannel(PROGRESS_CHANNEL, "Descargas en curso", NotificationManager.IMPORTANCE_LOW)
            )
        }
        if (manager.getNotificationChannel(DONE_CHANNEL) == null) {
            manager.createNotificationChannel(
                NotificationChannel(DONE_CHANNEL, "Descargas terminadas", NotificationManager.IMPORTANCE_DEFAULT)
            )
        }
    }
}
