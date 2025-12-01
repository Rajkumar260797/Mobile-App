package com.thirvusoft.homegeniecom

import io.flutter.embedding.android.FlutterActivity
import android.content.Intent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.audioapp/record"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> {
                    val intent = Intent(this, RecordingService::class.java)
                    startForegroundService(intent)
                    result.success("Service started")
                }

                "stopService" -> {
                    val intent = Intent(this, RecordingService::class.java)
                    stopService(intent)
                    result.success("Service stopped")
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}

