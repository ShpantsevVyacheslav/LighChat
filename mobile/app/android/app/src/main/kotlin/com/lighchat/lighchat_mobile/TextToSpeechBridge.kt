package com.lighchat.lighchat_mobile

import android.content.Context
import android.speech.tts.TextToSpeech
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

/**
 * Нативный TTS через Android `TextToSpeech` API — для функции «прочитать вслух»
 * текстового сообщения в чате. Оффлайн (после прогрузки голосового пакета).
 */
class TextToSpeechBridge(private val context: Context) {

    companion object {
        private const val CHANNEL = "lighchat/text_to_speech"
    }

    private var tts: TextToSpeech? = null
    @Volatile private var ready = false

    fun register(messenger: BinaryMessenger) {
        tts = TextToSpeech(context) { status ->
            ready = status == TextToSpeech.SUCCESS
        }
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "speak" -> handleSpeak(call, result)
                "stop" -> {
                    tts?.stop()
                    result.success(null)
                }
                "isSpeaking" -> result.success(tts?.isSpeaking ?: false)
                else -> result.notImplemented()
            }
        }
    }

    private fun handleSpeak(call: MethodCall, result: MethodChannel.Result) {
        val text = (call.argument<String>("text") ?: "").trim()
        if (text.isEmpty() || !ready) {
            result.success(false)
            return
        }
        val tag = call.argument<String>("languageTag")
        val locale = if (tag.isNullOrEmpty()) {
            Locale.getDefault()
        } else {
            Locale.forLanguageTag(tag.replace("_", "-"))
        }
        tts?.language = locale
        tts?.stop()
        val code = tts?.speak(text, TextToSpeech.QUEUE_FLUSH, null, "lighchat-tts")
        result.success(code == TextToSpeech.SUCCESS)
    }
}
