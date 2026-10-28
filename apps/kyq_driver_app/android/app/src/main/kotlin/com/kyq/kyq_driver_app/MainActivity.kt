package com.kyq.kyq_driver_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    // Botón físico y burbuja del walkie-talkie (RN-KYQ-012).
    private var handsFree: HandsFreeBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        handsFree = HandsFreeBridge(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        handsFree?.dispose()
        handsFree = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
