package com.thenoumandev.vision_gallery_saver

import androidx.annotation.NonNull
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Environment
import android.os.Build
import android.provider.MediaStore
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import java.io.FileInputStream
import java.io.IOException
import android.text.TextUtils
import android.webkit.MimeTypeMap
import java.io.OutputStream

/**
 * VisionGallerySaverPlugin
 * 
 * A Flutter plugin that provides functionality to save images and files to the device's gallery.
 * This plugin is designed with Vision's precision to handle media storage efficiently across different
 * Android versions, particularly considering the storage changes in Android 10 (Q) and above.
 */
class VisionGallerySaverPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private var applicationContext: Context? = null

    /**
     * Called when the plugin is first initialized.
     * Sets up the method channel and stores the application context.
     */
    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "vision_gallery_saver")
        channel.setMethodCallHandler(this)
        applicationContext = binding.applicationContext
    }

    /**
     * Handles method calls from Flutter.
     * Supports:
     * - getPlatformVersion: Returns the Android version
     * - saveImageToGallery: Saves image data as a file in the gallery
     * - saveFileToGallery: Saves any file (video, gif, etc.) to the gallery
     */
    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            "saveImageToGallery" -> {
                val image = call.argument<ByteArray>("imageBytes")
                val quality = call.argument<Int>("quality")
                val name = call.argument<String>("name")

                result.success(
                    saveImageToGallery(
                        BitmapFactory.decodeByteArray(
                            image ?: ByteArray(0),
                            0,
                            image?.size ?: 0
                        ), quality, name
                    )
                )
            }
            "saveFileToGallery" -> {
                val path = call.argument<String>("file")
                val name = call.argument<String>("name")
                result.success(saveFileToGallery(path, name))
            }
            else -> result.notImplemented()
        }
    }

    /**
     * Called when the plugin is destroyed.
     * Cleans up resources and removes the method call handler.
     */
    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        applicationContext = null
    }

    /**
     * Generates a content URI for saving media files.
     * Handles the different approaches required for Android Q (API 29) and above vs older versions.
     * 
     * @param extension The file extension (e.g., "jpg", "mp4")
     * @param name Optional custom filename
     * @return Uri? The generated URI where the file will be saved
     */
    private fun generateUri(extension: String = "", name: String? = null): Uri? {
        var fileName = name ?: System.currentTimeMillis().toString()
        val mimeType = getMIMEType(extension)
        val isVideo = mimeType?.startsWith("video") == true

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // Android 10 (Q) and above: Use MediaStore
            val uri = when {
                isVideo -> MediaStore.Video.Media.EXTERNAL_CONTENT_URI
                else -> MediaStore.Images.Media.EXTERNAL_CONTENT_URI
            }

            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(
                    MediaStore.MediaColumns.RELATIVE_PATH, when {
                        isVideo -> Environment.DIRECTORY_MOVIES
                        else -> Environment.DIRECTORY_PICTURES
                    }
                )
                if (!TextUtils.isEmpty(mimeType)) {
                    put(
                        when {
                            isVideo -> MediaStore.Video.Media.MIME_TYPE
                            else -> MediaStore.Images.Media.MIME_TYPE
                        }, mimeType
                    )
                }
            }

            applicationContext?.contentResolver?.insert(uri, values)
        } else {
            // Below Android 10: Use file system directly
            val storePath = Environment.getExternalStoragePublicDirectory(
                when {
                    isVideo -> Environment.DIRECTORY_MOVIES
                    else -> Environment.DIRECTORY_PICTURES
                }
            ).absolutePath
            val appDir = File(storePath).apply {
                if (!exists()) {
                    mkdir()
                }
            }

            val file = File(appDir, if (extension.isNotEmpty()) "$fileName.$extension" else fileName)
            Uri.fromFile(file)
        }
    }

    /**
     * Determines the MIME type from a file extension.
     * 
     * @param extension The file extension to check
     * @return String? The MIME type, or null if unknown
     */
    private fun getMIMEType(extension: String): String? {
        return if (!TextUtils.isEmpty(extension)) {
            MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension.lowercase())
        } else {
            null
        }
    }

    /**
     * Notifies the system that a new media file has been added.
     * Required for Android versions below Q to make files visible in gallery apps.
     * 
     * @param context The application context
     * @param fileUri The URI of the saved file
     */
    private fun sendBroadcast(context: Context, fileUri: Uri?) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            val mediaScanIntent = Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE)
            mediaScanIntent.data = fileUri
            context.sendBroadcast(mediaScanIntent)
        }
    }

    /**
     * Saves an image to the gallery.
     * Handles compression and quality settings for JPEG images.
     * 
     * @param bmp The bitmap to save
     * @param quality The JPEG compression quality (1-100)
     * @param name Optional custom filename
     * @return HashMap<String, Any?> Result containing success status, file path, and any error message
     */
    private fun saveImageToGallery(
        bmp: Bitmap?,
        quality: Int?,
        name: String?
    ): HashMap<String, Any?> {
        if (bmp == null || quality == null) {
            return SaveResultModel(false, null, "Vision's analysis: Parameters missing").toHashMap()
        }

        val context = applicationContext
            ?: return SaveResultModel(false, null, "Vision's analysis: Context unavailable").toHashMap()

        var fileUri: Uri? = null
        var fos: OutputStream? = null
        var success = false

        try {
            fileUri = generateUri("jpg", name)
            if (fileUri != null) {
                fos = context.contentResolver.openOutputStream(fileUri)
                if (fos != null) {
                    bmp.compress(Bitmap.CompressFormat.JPEG, quality, fos)
                    fos.flush()
                    success = true
                }
            }
        } catch (e: IOException) {
            return SaveResultModel(false, null, "Vision's analysis: ${e}").toHashMap()
        } finally {
            fos?.close()
            bmp.recycle()
        }

        return if (success) {
            sendBroadcast(context, fileUri)
            SaveResultModel(true, fileUri.toString(), null).toHashMap()
        } else {
            SaveResultModel(false, null, "Vision's analysis: Save operation failed").toHashMap()
        }
    }

    /**
     * Saves any file (video, gif, etc.) to the gallery.
     * 
     * @param filePath The source file path
     * @param name Optional custom filename
     * @return HashMap<String, Any?> Result containing success status, file path, and any error message
     */
    private fun saveFileToGallery(filePath: String?, name: String?): HashMap<String, Any?> {
        if (filePath == null) {
            return SaveResultModel(false, null, "Vision's analysis: File path missing").toHashMap()
        }

        val context = applicationContext
            ?: return SaveResultModel(false, null, "Vision's analysis: Context unavailable").toHashMap()

        var fileUri: Uri? = null
        var outputStream: OutputStream? = null
        var fileInputStream: FileInputStream? = null
        var success = false

        try {
            val originalFile = File(filePath)
            if (!originalFile.exists()) {
                return SaveResultModel(false, null, "Vision's analysis: File not found at $filePath").toHashMap()
            }

            fileUri = generateUri(originalFile.extension, name)
            if (fileUri != null) {
                outputStream = context.contentResolver.openOutputStream(fileUri)
                if (outputStream != null) {
                    fileInputStream = FileInputStream(originalFile)

                    // Transfer the file in chunks to handle large files efficiently
                    val buffer = ByteArray(10240)
                    var count = 0
                    while (fileInputStream.read(buffer).also { count = it } > 0) {
                        outputStream.write(buffer, 0, count)
                    }

                    outputStream.flush()
                    success = true
                }
            }
        } catch (e: IOException) {
            return SaveResultModel(false, null, "Vision's analysis: ${e}").toHashMap()
        } finally {
            outputStream?.close()
            fileInputStream?.close()
        }

        return if (success) {
            sendBroadcast(context, fileUri)
            SaveResultModel(true, fileUri.toString(), null).toHashMap()
        } else {
            SaveResultModel(false, null, "Vision's analysis: Save operation failed").toHashMap()
        }
    }
}

/**
 * Data class to represent the result of save operations.
 * 
 * @property isSuccess Whether the operation was successful
 * @property filePath The path to the saved file (if successful)
 * @property errorMessage Any error message (if unsuccessful)
 */
data class SaveResultModel(
    var isSuccess: Boolean,
    var filePath: String? = null,
    var errorMessage: String? = null
) {
    /**
     * Converts the result to a HashMap for Flutter communication
     */
    fun toHashMap(): HashMap<String, Any?> {
        return hashMapOf(
            "isSuccess" to isSuccess,
            "filePath" to filePath,
            "errorMessage" to errorMessage
        )
    }
}