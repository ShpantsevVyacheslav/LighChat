package com.lighchat.lighchat_mobile

import android.content.Context
import android.content.Intent
import android.media.AudioFormat
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.ParcelFileDescriptor
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.nio.ByteBuffer
import java.util.Locale
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

/**
 * On-device транскрибация голосовых сообщений через Android SpeechRecognizer.
 *
 * - API 31+ (Android 12): `createOnDeviceSpeechRecognizer`.
 * - API 33+ (Android 13): передача аудио из файла через `EXTRA_AUDIO_SOURCE`
 *   (декодируем .m4a → PCM 16-bit mono 16 kHz через MediaCodec).
 *
 * Сетевые вызовы OpenAI / Cloud Function больше не используются —
 * поэтому работает в РФ без VPN и в E2EE-чатах.
 */
class VoiceTranscriberBridge(private val context: Context) {

    companion object {
        private const val CHANNEL = "lighchat/voice_transcribe"
        private const val TAG = "VoiceTranscriber"
        private const val TARGET_SAMPLE_RATE = 16000
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private val executor = Executors.newSingleThreadExecutor()

    fun register(messenger: io.flutter.plugin.common.BinaryMessenger) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "supportedLocales" -> handleSupportedLocales(result)
                "transcribeFile" -> handleTranscribeFile(call, result)
                else -> result.notImplemented()
            }
        }
    }

    private fun handleSupportedLocales(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            result.success(emptyList<String>())
            return
        }
        if (!SpeechRecognizer.isOnDeviceRecognitionAvailable(context)) {
            result.success(emptyList<String>())
            return
        }
        // ACTION_GET_LANGUAGE_DETAILS возвращает результат через ordered broadcast,
        // что требует BroadcastReceiver. Чтобы не усложнять — возвращаем системный
        // язык как минимально гарантированный; реальный фильтр локалей делает
        // SpeechRecognizer сам, отвергая невалидные `EXTRA_LANGUAGE`.
        val tags = mutableListOf<String>()
        val def = Locale.getDefault().toLanguageTag()
        if (def.isNotBlank()) tags.add(def)
        // Дополнительные часто используемые локали (best-effort).
        listOf(
            "ru-RU", "en-US", "es-ES", "es-MX", "pt-BR", "tr-TR",
            "id-ID", "kk-KZ", "uz-UZ"
        ).forEach { if (!tags.contains(it)) tags.add(it) }
        result.success(tags)
    }

    private fun handleTranscribeFile(call: MethodCall, result: MethodChannel.Result) {
        val filePath = call.argument<String>("filePath") ?: ""
        val languageTag = call.argument<String>("languageTag") ?: "en-US"
        if (filePath.isEmpty()) {
            result.error("invalid_url", "Empty filePath", null)
            return
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            result.error(
                "unsupported_os",
                "On-device transcription from file requires Android 13+",
                null
            )
            return
        }
        if (!SpeechRecognizer.isOnDeviceRecognitionAvailable(context)) {
            result.error(
                "no_model",
                "On-device speech recognition is not available. Install a language pack in system settings.",
                null
            )
            return
        }

        executor.execute {
            try {
                val pcmFile = decodeToPcm(File(filePath))
                runRecognition(pcmFile, languageTag, result)
            } catch (t: Throwable) {
                Log.e(TAG, "decode/recognize failed", t)
                mainHandler.post {
                    result.error("recognition_failed", t.message ?: "unknown", null)
                }
            }
        }
    }

    /** Декодирует .m4a/.aac/etc → PCM 16-bit mono 16kHz во временный файл. */
    private fun decodeToPcm(src: File): File {
        if (!src.exists()) throw IllegalStateException("Audio file missing: ${src.path}")
        val extractor = MediaExtractor()
        extractor.setDataSource(src.path)
        var audioTrack = -1
        var format: MediaFormat? = null
        for (i in 0 until extractor.trackCount) {
            val f = extractor.getTrackFormat(i)
            val mime = f.getString(MediaFormat.KEY_MIME) ?: continue
            if (mime.startsWith("audio/")) {
                audioTrack = i
                format = f
                break
            }
        }
        if (audioTrack < 0 || format == null) {
            extractor.release()
            throw IllegalStateException("No audio track in $src")
        }
        extractor.selectTrack(audioTrack)
        val mime = format.getString(MediaFormat.KEY_MIME)!!
        val codec = MediaCodec.createDecoderByType(mime)
        codec.configure(format, null, null, 0)
        codec.start()

        val srcSampleRate = format.getInteger(MediaFormat.KEY_SAMPLE_RATE)
        val srcChannelCount = format.getInteger(MediaFormat.KEY_CHANNEL_COUNT)

        val outFile = File.createTempFile("stt-pcm-", ".pcm", context.cacheDir)
        val out = FileOutputStream(outFile)

        val info = MediaCodec.BufferInfo()
        var sawInputEnd = false
        var sawOutputEnd = false
        try {
            while (!sawOutputEnd) {
                if (!sawInputEnd) {
                    val inIdx = codec.dequeueInputBuffer(10_000)
                    if (inIdx >= 0) {
                        val inBuf = codec.getInputBuffer(inIdx)!!
                        inBuf.clear()
                        val size = extractor.readSampleData(inBuf, 0)
                        if (size < 0) {
                            codec.queueInputBuffer(
                                inIdx, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM
                            )
                            sawInputEnd = true
                        } else {
                            codec.queueInputBuffer(
                                inIdx, 0, size, extractor.sampleTime, 0
                            )
                            extractor.advance()
                        }
                    }
                }
                val outIdx = codec.dequeueOutputBuffer(info, 10_000)
                if (outIdx >= 0) {
                    val buf = codec.getOutputBuffer(outIdx)!!
                    if (info.size > 0) {
                        val chunk = ByteArray(info.size)
                        buf.position(info.offset)
                        buf.get(chunk, 0, info.size)
                        val resampled = downmixAndResample(
                            chunk, srcSampleRate, srcChannelCount, TARGET_SAMPLE_RATE
                        )
                        out.write(resampled)
                    }
                    codec.releaseOutputBuffer(outIdx, false)
                    if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
                        sawOutputEnd = true
                    }
                }
            }
        } finally {
            out.flush()
            out.close()
            codec.stop()
            codec.release()
            extractor.release()
        }
        return outFile
    }

    /** Простой downmix mono + линейный resample к 16 kHz. */
    private fun downmixAndResample(
        pcm: ByteArray, srcRate: Int, channels: Int, dstRate: Int
    ): ByteArray {
        val shortBuf = ByteBuffer.wrap(pcm).order(java.nio.ByteOrder.LITTLE_ENDIAN).asShortBuffer()
        val srcSamples = shortBuf.remaining() / channels
        val mono = ShortArray(srcSamples)
        for (i in 0 until srcSamples) {
            var sum = 0
            for (c in 0 until channels) sum += shortBuf.get().toInt()
            mono[i] = (sum / channels).toShort()
        }
        if (srcRate == dstRate) {
            val out = ByteArray(mono.size * 2)
            val bb = ByteBuffer.wrap(out).order(java.nio.ByteOrder.LITTLE_ENDIAN)
            for (s in mono) bb.putShort(s)
            return out
        }
        val ratio = srcRate.toDouble() / dstRate
        val dstSamples = (mono.size / ratio).toInt()
        val out = ByteArray(dstSamples * 2)
        val bb = ByteBuffer.wrap(out).order(java.nio.ByteOrder.LITTLE_ENDIAN)
        for (i in 0 until dstSamples) {
            val srcIdx = (i * ratio).toInt().coerceIn(0, mono.size - 1)
            bb.putShort(mono[srcIdx])
        }
        return out
    }

    private fun runRecognition(
        pcmFile: File, languageTag: String, result: MethodChannel.Result
    ) {
        mainHandler.post {
            val recognizer = try {
                SpeechRecognizer.createOnDeviceSpeechRecognizer(context)
            } catch (t: Throwable) {
                result.error("recognizer_unavailable", t.message ?: "unknown", null)
                pcmFile.delete()
                return@post
            }

            val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                putExtra(
                    RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                    RecognizerIntent.LANGUAGE_MODEL_FREE_FORM
                )
                putExtra(RecognizerIntent.EXTRA_LANGUAGE, languageTag)
                putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, false)
                putExtra("android.speech.extra.PREFER_OFFLINE", true)
            }

            try {
                val pfd = ParcelFileDescriptor.open(
                    pcmFile, ParcelFileDescriptor.MODE_READ_ONLY
                )
                intent.putExtra(RecognizerIntent.EXTRA_AUDIO_SOURCE, pfd)
                intent.putExtra(
                    RecognizerIntent.EXTRA_AUDIO_SOURCE_ENCODING,
                    AudioFormat.ENCODING_PCM_16BIT
                )
                intent.putExtra(
                    RecognizerIntent.EXTRA_AUDIO_SOURCE_SAMPLING_RATE,
                    TARGET_SAMPLE_RATE
                )
                intent.putExtra(RecognizerIntent.EXTRA_AUDIO_SOURCE_CHANNEL_COUNT, 1)
            } catch (t: Throwable) {
                Log.e(TAG, "failed to attach audio source", t)
                result.error("audio_source_failed", t.message ?: "unknown", null)
                pcmFile.delete()
                recognizer.destroy()
                return@post
            }

            val delivered = AtomicBoolean(false)
            recognizer.setRecognitionListener(object : RecognitionListener {
                override fun onResults(results: Bundle?) {
                    if (!delivered.compareAndSet(false, true)) return
                    val list = results?.getStringArrayList(
                        SpeechRecognizer.RESULTS_RECOGNITION
                    )
                    val text = list?.firstOrNull()?.trim() ?: ""
                    result.success(mapOf("text" to text))
                    pcmFile.delete()
                    recognizer.destroy()
                }

                override fun onError(error: Int) {
                    if (!delivered.compareAndSet(false, true)) return
                    val msg = errorToString(error)
                    result.error("recognition_failed", "code=$error $msg", null)
                    pcmFile.delete()
                    recognizer.destroy()
                }

                override fun onReadyForSpeech(p: Bundle?) {}
                override fun onBeginningOfSpeech() {}
                override fun onRmsChanged(v: Float) {}
                override fun onBufferReceived(b: ByteArray?) {}
                override fun onEndOfSpeech() {}
                override fun onPartialResults(p: Bundle?) {}
                override fun onEvent(eventType: Int, p: Bundle?) {}
            })

            try {
                recognizer.startListening(intent)
            } catch (t: Throwable) {
                if (delivered.compareAndSet(false, true)) {
                    result.error("recognition_failed", t.message ?: "unknown", null)
                }
                pcmFile.delete()
                recognizer.destroy()
            }
        }
    }

    private fun errorToString(code: Int): String = when (code) {
        SpeechRecognizer.ERROR_AUDIO -> "audio error"
        SpeechRecognizer.ERROR_CLIENT -> "client error"
        SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "permission denied"
        SpeechRecognizer.ERROR_NETWORK -> "network error"
        SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "network timeout"
        SpeechRecognizer.ERROR_NO_MATCH -> "no speech match"
        SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "recognizer busy"
        SpeechRecognizer.ERROR_SERVER -> "server error"
        SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "speech timeout"
        else -> "unknown"
    }
}
