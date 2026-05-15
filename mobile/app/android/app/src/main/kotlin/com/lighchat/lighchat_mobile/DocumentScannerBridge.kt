package com.lighchat.lighchat_mobile

import android.app.Activity
import android.content.Intent
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions.RESULT_FORMAT_JPEG
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions.SCANNER_MODE_FULL
import com.google.mlkit.vision.documentscanner.GmsDocumentScanning
import com.google.mlkit.vision.documentscanner.GmsDocumentScanningResult
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Bridge для нативного Google ML Kit Document Scanner.
 * Channel: `lighchat/document_scanner`. Методы:
 *  - `isAvailable()` — `true`, если Play Services установлены.
 *  - `scan()` — открывает Google scanner UI; возвращает массив абсолютных
 *    путей к JPEG-страницам. Caller сам перемещает/удаляет файлы.
 *
 * Нужен `Activity`, поэтому MainActivity передаёт self и
 * проксирует `onActivityResult` через [handleActivityResult].
 */
class DocumentScannerBridge(private val activity: Activity) {

    companion object {
        const val CHANNEL = "lighchat/document_scanner"
        const val REQUEST_CODE = 0xD0C5
    }

    private var channel: MethodChannel? = null
    private var pendingResult: MethodChannel.Result? = null

    fun register(messenger: BinaryMessenger) {
        channel = MethodChannel(messenger, CHANNEL).apply {
            setMethodCallHandler { call, result -> handle(call, result) }
        }
    }

    /** Должно вызываться из MainActivity.onActivityResult для нашего request code. */
    fun handleActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_CODE) return false
        val r = pendingResult
        pendingResult = null
        if (r == null) return true
        if (resultCode != Activity.RESULT_OK || data == null) {
            r.success(emptyList<String>())
            return true
        }
        val scan = GmsDocumentScanningResult.fromActivityResultIntent(data)
        val paths = scan?.pages?.mapNotNull { it.imageUri.path } ?: emptyList()
        r.success(paths)
        return true
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isAvailable" -> result.success(true)
            "scan" -> startScan(result)
            else -> result.notImplemented()
        }
    }

    private fun startScan(result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error("busy", "Another scan is already in progress", null)
            return
        }
        pendingResult = result
        val options = GmsDocumentScannerOptions.Builder()
            .setGalleryImportAllowed(false)
            .setPageLimit(20)
            .setResultFormats(RESULT_FORMAT_JPEG)
            .setScannerMode(SCANNER_MODE_FULL)
            .build()
        GmsDocumentScanning.getClient(options)
            .getStartScanIntent(activity)
            .addOnSuccessListener { sender ->
                try {
                    activity.startIntentSenderForResult(
                        sender, REQUEST_CODE, Intent(), 0, 0, 0,
                    )
                } catch (t: Throwable) {
                    val r = pendingResult
                    pendingResult = null
                    r?.error("start_failed", t.message, null)
                }
            }
            .addOnFailureListener { e ->
                val r = pendingResult
                pendingResult = null
                r?.error("unavailable", e.message, null)
            }
    }
}
