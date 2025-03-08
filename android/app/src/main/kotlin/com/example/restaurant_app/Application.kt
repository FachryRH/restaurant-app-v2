package com.example.restaurant_app

import android.app.Application
import androidx.work.Configuration
import androidx.work.WorkManager

class Application : Application(), Configuration.Provider {
    override fun onCreate() {
        super.onCreate()
        val config = Configuration.Builder()
            .setMinimumLoggingLevel(android.util.Log.INFO)
            .build()
        WorkManager.initialize(this, config)
    }

    override val workManagerConfiguration: Configuration
        get() = Configuration.Builder()
            .setMinimumLoggingLevel(android.util.Log.INFO)
            .build()
} 