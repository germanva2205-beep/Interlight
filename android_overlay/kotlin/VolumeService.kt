package com.helpme.help_me

import android.accessibilityservice.AccessibilityService
import android.app.KeyguardManager
import android.content.Intent
import android.view.KeyEvent
import android.view.accessibility.AccessibilityEvent

class VolumeService : AccessibilityService() {
    private var lastDown = 0L

    override fun onServiceConnected() {
        super.onServiceConnected()
        running = true
    }

    override fun onUnbind(intent: Intent?): Boolean {
        running = false
        return super.onUnbind(intent)
    }

    override fun onKeyEvent(event: KeyEvent): Boolean {
        val code = event.keyCode
        if ((code == KeyEvent.KEYCODE_VOLUME_DOWN || code == KeyEvent.KEYCODE_VOLUME_UP) &&
            event.action == KeyEvent.ACTION_DOWN && event.repeatCount == 0
        ) {
            val now = event.eventTime
            if (now - lastDown in 1..400) {
                lastDown = 0
                launch()
            } else {
                lastDown = now
            }
        }
        return false
    }

    private fun launch() {
        val km = getSystemService(KEYGUARD_SERVICE) as KeyguardManager
        if (km.isKeyguardLocked) return
        val i = Intent(this, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            .putExtra(MainActivity.EXTRA_LISTEN, true)
        startActivity(i)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {}
    override fun onInterrupt() {}

    companion object {
        @Volatile
        var running = false
    }
}
