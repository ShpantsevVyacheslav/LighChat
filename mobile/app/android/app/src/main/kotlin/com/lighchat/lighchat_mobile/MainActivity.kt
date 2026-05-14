package com.lighchat.lighchat_mobile

import android.app.PictureInPictureParams
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import android.util.Rational
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "lighchat/pip"
        private const val VIRTUAL_BG_CHANNEL = "lighchat/virtual_background"
        private const val VIRTUAL_BG_TAG = "LighChatVirtualBg"
    }

    // Состояние виртуального фона; реальный pixel-pipeline (CameraX -> ML Kit
    // Selfie-Segmentation -> GLES compositor -> flutter_webrtc VideoCapturer)
    // подключается отдельным native-PR. См. docs/mobile/meetings-virtual-background.md.
    private var virtualBgMode: String = "none"
    private var virtualBgImageAssetPath: String? = null

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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VIRTUAL_BG_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setMode" -> {
                        val mode = call.argument<String>("mode") ?: "none"
                        val path = call.argument<String>("imageAssetPath")
                        if (mode !in listOf("none", "blur", "image")) {
                            result.error(
                                "invalid_mode",
                                "unknown virtual background mode: $mode",
                                null,
                            )
                            return@setMethodCallHandler
                        }
                        virtualBgMode = mode
                        virtualBgImageAssetPath = path
                        // TODO(native-bg): подключить CameraX -> ML Kit Selfie-Segmentation
                        // -> GLES/Vulkan compositor -> flutter_webrtc capturer.
                        // Сейчас канал только хранит состояние и логирует его, чтобы Dart и
                        // UI были полностью готовы к native-pipeline без их правок.
                        Log.i(VIRTUAL_BG_TAG, "setMode mode=$mode imagePath=$path (native pipeline TBD)")
                        result.success(null)
                    }

                    "dispose" -> {
                        virtualBgMode = "none"
                        virtualBgImageAssetPath = null
                        Log.i(VIRTUAL_BG_TAG, "dispose")
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }

        VoiceTranscriberBridge(applicationContext)
            .register(flutterEngine.dartExecutor.binaryMessenger)
        TextToSpeechBridge(applicationContext)
            .register(flutterEngine.dartExecutor.binaryMessenger)
        HapticsBridge(applicationContext)
            .register(flutterEngine.dartExecutor.binaryMessenger)
    }
}
