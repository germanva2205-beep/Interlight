package com.helpme.help_me

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent

object Alarms {
    private const val PREFS = "hm_alarms"

    private fun pi(ctx: Context, id: Int, label: String): PendingIntent {
        val i = Intent(ctx, AlarmReceiver::class.java)
            .putExtra("id", id).putExtra("label", label)
        return PendingIntent.getBroadcast(
            ctx, id, i, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    fun schedule(ctx: Context, id: Int, millis: Long, label: String, save: Boolean = true) {
        val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val show = PendingIntent.getActivity(
            ctx, 0, Intent(ctx, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        am.setAlarmClock(AlarmManager.AlarmClockInfo(millis, show), pi(ctx, id, label))
        if (save) {
            ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
                .putString(id.toString(), "$millis|$label").apply()
        }
    }

    fun cancel(ctx: Context, id: Int) {
        val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        am.cancel(pi(ctx, id, ""))
        ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().remove(id.toString()).apply()
    }

    fun restore(ctx: Context) {
        val p = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val now = System.currentTimeMillis()
        for ((k, v) in p.all) {
            val s = v as? String ?: continue
            val idx = s.indexOf('|')
            val millis = s.substring(0, idx).toLongOrNull() ?: continue
            if (millis > now) schedule(ctx, k.toInt(), millis, s.substring(idx + 1), false)
            else p.edit().remove(k).apply()
        }
    }
}
