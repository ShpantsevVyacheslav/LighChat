package com.lighchat.lighchat_mobile

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Богатые haptic-паттерны через Android `VibrationEffect` API. Семантика
 * совпадает с iOS Core Haptics — те же `event`-ключи дают похожие ощущения.
 */
class HapticsBridge(private val context: Context) {

    companion object {
        private const val CHANNEL = "lighchat/haptics"
    }

    private val vibrator: Vibrator? by lazy {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vm = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE)
                as? VibratorManager
            vm?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }
    }

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isAvailable" -> result.success(vibrator?.hasVibrator() == true)
                "play" -> {
                    handlePlay(call)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun handlePlay(call: MethodCall) {
        val v = vibrator ?: return
        if (!v.hasVibrator()) return
        val event = call.argument<String>("event") ?: "light"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val effect = effectFor(event) ?: return
            v.vibrate(effect)
        } else {
            // Старые Android — простой импульс.
            @Suppress("DEPRECATION")
            v.vibrate(when (event) {
                "longPress", "warning" -> 25L
                "error", "reactionBurst" -> 50L
                else -> 10L
            })
        }
    }

    @android.annotation.TargetApi(Build.VERSION_CODES.O)
    private fun effectFor(event: String): VibrationEffect? {
        return when (event) {
            "sendMessage" -> VibrationEffect.createOneShot(
                12L, VibrationEffect.DEFAULT_AMPLITUDE)
            "receiveMessage" -> VibrationEffect.createWaveform(
                longArrayOf(0, 10, 40, 8),
                intArrayOf(0, 100, 0, 80),
                -1)
            "longPress" -> VibrationEffect.createOneShot(
                22L, VibrationEffect.DEFAULT_AMPLITUDE)
            "success" -> VibrationEffect.createWaveform(
                longArrayOf(0, 8, 30, 12, 30, 16),
                intArrayOf(0, 80, 0, 120, 0, 200),
                -1)
            "warning" -> VibrationEffect.createWaveform(
                longArrayOf(0, 18, 40, 18),
                intArrayOf(0, 180, 0, 180),
                -1)
            "error" -> VibrationEffect.createWaveform(
                longArrayOf(0, 30, 40, 30, 40, 30),
                intArrayOf(0, 220, 0, 220, 0, 220),
                -1)
            "tick" -> VibrationEffect.createOneShot(
                6L, VibrationEffect.DEFAULT_AMPLITUDE)
            "selectionChanged" -> VibrationEffect.createOneShot(
                8L, 100)
            "reactionBurst" -> {
                val timings = LongArray(16) { if (it % 2 == 0) 0L else 18L }
                timings[0] = 0L
                val amps = IntArray(16) {
                    if (it % 2 == 0) 0 else (60..240).random()
                }
                VibrationEffect.createWaveform(timings, amps, -1)
            }
            else -> VibrationEffect.createOneShot(
                10L, VibrationEffect.DEFAULT_AMPLITUDE)
        }
    }
}
