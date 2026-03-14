package com.example.locami

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build

class LocamiApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        createNotificationChannels()
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(NotificationManager::class.java)

            // Main tracking channel used by our foreground service
            val trackingChannel = NotificationChannel(
                "locami_tracking_channel",
                "Locami Tracking Service",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Ongoing notification for location tracking"
            }
            notificationManager.createNotificationChannel(trackingChannel)
        }
    }
}
