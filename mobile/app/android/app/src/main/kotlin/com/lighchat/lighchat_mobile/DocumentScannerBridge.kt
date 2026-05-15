package com.lighchat.lighchat_mobile

import android.app.Activity
import android.content.Intent
import android.graphics.BitmapFactory
import android.graphics.pdf.PdfDocument
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions.RESULT_FORMAT_JPEG
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions.SCANNER_MODE_FULL
import com.google.mlkit.vision.documentscanner.GmsDocumentScanning
import com.google.mlkit.vision.documentscanner.GmsDocumentScanningResult
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

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
            "imagesToPdf" -> {
                @Suppress("UNCHECKED_CAST")
                val paths = (call.argument<List<Any?>>("paths") ?: emptyList())
                    .mapNotNull { it as? String }
                val filename = call.argument<String>("filename")
                val pdfPath = try {
                    buildPdf(paths, filename)
                } catch (t: Throwable) {
                    null
                }
                if (pdfPath != null) {
                    result.success(pdfPath)
                } else {
                    result.error("pdf_failed", "Failed to build PDF", null)
                }
            }
            else -> result.notImplemented()
        }
    }

    /**
     * Объединяет JPEG-страницы в один PDF через `android.graphics.pdf.PdfDocument`.
     * Размер страницы = размеру bitmap'а исходной страницы — пропорции сохраняются.
     */
    private fun buildPdf(paths: List<String>, filename: String?): String? {
        if (paths.isEmpty()) return null
        val pdf = PdfDocument()
        var added = 0
        try {
            for ((index, path) in paths.withIndex()) {
                val bmp = BitmapFactory.decodeFile(path) ?: continue
                val pageInfo = PdfDocument.PageInfo
                    .Builder(bmp.width, bmp.height, index)
                    .create()
                val page = pdf.startPage(pageInfo)
                page.canvas.drawBitmap(bmp, 0f, 0f, null)
                pdf.finishPage(page)
                bmp.recycle()
                added += 1
            }
            if (added == 0) {
                pdf.close()
                return null
            }
            val stamp = System.currentTimeMillis()
            val safeName = (filename?.trim()
                ?.takeIf { it.isNotEmpty() }
                ?.replace("/", "_")
                ?.replace("\\", "_")
                ?.let { if (it.endsWith(".pdf")) it else "$it.pdf" })
                ?: "scan_$stamp.pdf"
            val out = File(activity.cacheDir, safeName)
            FileOutputStream(out).use { pdf.writeTo(it) }
            return out.absolutePath
        } finally {
            pdf.close()
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
