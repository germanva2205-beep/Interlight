package com.helpme.help_me

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(ctx: Context, intent: Intent) {
        val id = intent.getIntExtra("id", 0)
        val label = intent.getStringExtra("label").orEmpty()
        val nm = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val sound = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
        val open = PendingIntent.getActivity(
            ctx, 0, Intent(ctx, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val b: Notification.Builder
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val ch = NotificationChannel("hm_alarm", "Будильники Help Me", NotificationManager.IMPORTANCE_HIGH)
            ch.setSound(
                sound,
                AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_ALARM).build()
            )
            nm.createNotificationChannel(ch)
            b = Notification.Builder(ctx, "hm_alarm")
        } else {
            @Suppress("DEPRECATION")
            b = Notification.Builder(ctx).setSound(sound)
        }
        b.setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle("Будильник")
            .setContentText(if (label.isEmpty()) "Пора!" else label)
            .setContentIntent(open)
            .setAutoCancel(true)
        nm.notify(id, b.build())
        ctx.getSharedPreferences("hm_alarms", Context.MODE_PRIVATE).edit().remove(id.toString()).apply()
    }
}
