package com.lighchat.lighchat_mobile

import android.app.PictureInPictureParams
import android.content.pm.PackageManager
import android.os.Build
import android.util.Rational
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "lighchat/pip"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isSupported" -> {
                        val supported =
                            Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                                packageManager.hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE)
                        result.success(supported)
                    }

                    "enter" -> {
                        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        val aspectW = call.argument<Int>("aspectW") ?: 0
                        val aspectH = call.argument<Int>("aspectH") ?: 0
                        val paramsBuilder = PictureInPictureParams.Builder()
                        if (aspectW > 0 && aspectH > 0) {
                            paramsBuilder.setAspectRatio(Rational(aspectW, aspectH))
                        }
                        return@setMethodCallHandler try {
                            enterPictureInPictureMode(paramsBuilder.build())
                            result.success(true)
                        } catch (_: Throwable) {
                            result.success(false)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
