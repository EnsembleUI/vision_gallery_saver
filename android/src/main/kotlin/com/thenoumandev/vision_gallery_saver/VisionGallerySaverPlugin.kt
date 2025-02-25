package com.thenoumandev.vision_gallery_saver

import androidx.annotation.NonNull
import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
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
     */
    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            "saveImageToGallery" -> {
                handleSaveImageRequest(call, result)
            }
            "saveFileToGallery" -> {
                handleSaveFileRequest(call, result)
            }
            else -> result.notImplemented()
        }
    }

    /**
     * Handles saving image request from Flutter.
     */
    private fun handleSaveImageRequest(call: MethodCall, result: Result) {
        val image = call.argument<ByteArray>("imageBytes")
        val quality = call.argument<Int>("quality") ?: 80
        val name = call.argument<String>("name")
        val skipIfExists = call.argument<Boolean>("skipIfExists") ?: false
        val androidRelativePath = call.argument<String>("androidRelativePath")

        if (image == null) {
            result.success(SaveResultModel(false, null, "Vision's analysis: Image data is missing").toHashMap())
            return
        }

        try {
            val bitmap = BitmapFactory.decodeByteArray(image, 0, image.size)
            if (bitmap == null) {
                result.success(SaveResultModel(false, null, "Vision's analysis: Failed to decode image").toHashMap())
                return
            }
            
            result.success(
                saveImageToGallery(bitmap, quality, name, skipIfExists, androidRelativePath)
            )
        } catch (e: Exception) {
            result.success(SaveResultModel(false, null, "Vision's analysis: ${e.message}").toHashMap())
        }
    }

    /**
     * Handles saving file request from Flutter.
     */
    private fun handleSaveFileRequest(call: MethodCall, result: Result) {
        val path = call.argument<String>("file")
        val name = call.argument<String>("name")
        val skipIfExists = call.argument<Boolean>("skipIfExists") ?: false
        val androidRelativePath = call.argument<String>("androidRelativePath")
        
        if (path == null) {
            result.success(SaveResultModel(false, null, "Vision's analysis: File path is missing").toHashMap())
            return
        }
        
        result.success(saveFileToGallery(path, name, skipIfExists, androidRelativePath))
    }

    /**
     * Called when the plugin is destroyed.
     */
    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        applicationContext = null
    }

    /**
     * Finds an existing file in the gallery.
     */
    private fun findExistingFile(
        extension: String, 
        fileName: String, 
        customRelativePath: String?
    ): SaveResultModel? {
        val context = applicationContext ?: return null
        val fullFileName = MediaStoreUtils.ensureExtension(fileName, extension)
        
        val mimeType = MediaStoreUtils.getMIMEType(extension)
        val isVideo = MediaStoreUtils.isMediaType(mimeType, "video/")
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // For Android 10+, query the MediaStore
            val contentUri = when {
                isVideo -> MediaStore.Video.Media.EXTERNAL_CONTENT_URI
                else -> MediaStore.Images.Media.EXTERNAL_CONTENT_URI
            }
            
            val defaultDirectory = MediaStoreUtils.getDirectoryType(mimeType)
            val relativePath = MediaStoreUtils.buildRelativePath(defaultDirectory, customRelativePath)
            
            val projection = arrayOf(MediaStore.MediaColumns._ID, MediaStore.MediaColumns.DATA)
            val selection = "${MediaStore.MediaColumns.RELATIVE_PATH} LIKE ? AND ${MediaStore.MediaColumns.DISPLAY_NAME} = ?"
            val selectionArgs = arrayOf("%$relativePath%", fullFileName)
            
            context.contentResolver.query(
                contentUri,
                projection,
                selection,
                selectionArgs,
                null
            )?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val idColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID)
                    val dataColumn = cursor.getColumnIndex(MediaStore.MediaColumns.DATA)
                    val id = cursor.getLong(idColumn)
                    val filePath = if (dataColumn != -1) cursor.getString(dataColumn) else null
                    
                    val contentUri = ContentUris.withAppendedId(
                        when {
                            isVideo -> MediaStore.Video.Media.EXTERNAL_CONTENT_URI
                            else -> MediaStore.Images.Media.EXTERNAL_CONTENT_URI
                        },
                        id
                    )

                    return SaveResultModel(
                        isSuccess = true, 
                        filePath = contentUri.toString(), 
                        errorMessage = null, 
                        foundExistingFile = true,
                        existingFilePath = filePath ?: contentUri.toString()
                    )
                }
            }
        } else {
            // For older Android versions, check the file system directly
            val directoryType = MediaStoreUtils.getDirectoryType(mimeType)
            val storePath = Environment.getExternalStoragePublicDirectory(directoryType).absolutePath
            
            // Create path with custom subfolder if specified
            val baseDir = if (customRelativePath.isNullOrEmpty()) {
                File(storePath)
            } else {
                File(storePath, customRelativePath)
            }
            
            val file = File(baseDir, fullFileName)
            if (file.exists()) {
                return SaveResultModel(
                    isSuccess = true, 
                    filePath = file.absolutePath, 
                    errorMessage = null, 
                    foundExistingFile = true,
                    existingFilePath = file.absolutePath
                )
            }
        }
        
        return null
    }

    /**
     * Saves an image to the gallery.
     */
    private fun saveImageToGallery(
        bmp: Bitmap,
        quality: Int,
        name: String?,
        skipIfExists: Boolean,
        customRelativePath: String?
    ): HashMap<String, Any?> {
        val context = applicationContext
            ?: return SaveResultModel(false, null, "Vision's analysis: Context unavailable").toHashMap()

        val fileName = name ?: System.currentTimeMillis().toString()
        
        // Check if file exists and skip if requested
        if (skipIfExists) {
            findExistingFile("jpg", fileName, customRelativePath)?.let { 
                return it.toHashMap() 
            }
        }

        var fileUri: Uri? = null
        var fos: OutputStream? = null
        var success = false

        try {
            fileUri = generateUri("jpg", fileName, customRelativePath)
            if (fileUri != null) {
                fos = context.contentResolver.openOutputStream(fileUri)
                if (fos != null) {
                    bmp.compress(Bitmap.CompressFormat.JPEG, quality, fos)
                    fos.flush()
                    success = true
                }
            }
        } catch (e: IOException) {
            return SaveResultModel(false, null, "Vision's analysis: ${e.message}").toHashMap()
        } finally {
            try {
                fos?.close()
            } catch (e: IOException) {
                // Ignore close exception
            }
            bmp.recycle()
        }

        return if (success) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                val mediaScanIntent = Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE)
                mediaScanIntent.data = fileUri
                context.sendBroadcast(mediaScanIntent)
            }
            SaveResultModel(true, fileUri.toString(), null).toHashMap()
        } else {
            SaveResultModel(false, null, "Vision's analysis: Save operation failed").toHashMap()
        }
    }

    /**
     * Saves any file to the gallery.
     */
    private fun saveFileToGallery(
        filePath: String, 
        name: String?,
        skipIfExists: Boolean,
        customRelativePath: String?
    ): HashMap<String, Any?> {
        val context = applicationContext
            ?: return SaveResultModel(false, null, "Vision's analysis: Context unavailable").toHashMap()

        val originalFile = File(filePath)
        if (!originalFile.exists()) {
            return SaveResultModel(false, null, "Vision's analysis: File not found at $filePath").toHashMap()
        }

        val fileName = name ?: originalFile.name
        val extension = originalFile.extension
        
        // Check if file exists and skip if requested
        if (skipIfExists) {
            findExistingFile(extension, fileName, customRelativePath)?.let { 
                return it.toHashMap() 
            }
        }

        var fileUri: Uri? = null
        var outputStream: OutputStream? = null
        var fileInputStream: FileInputStream? = null
        var success = false

        try {
            fileUri = generateUri(extension, fileName, customRelativePath)
            if (fileUri != null) {
                outputStream = context.contentResolver.openOutputStream(fileUri)
                if (outputStream != null) {
                    fileInputStream = FileInputStream(originalFile)

                    // Transfer the file in chunks to handle large files efficiently
                    val buffer = ByteArray(8192)
                    var bytesRead: Int
                    while (fileInputStream.read(buffer).also { bytesRead = it } > 0) {
                        outputStream.write(buffer, 0, bytesRead)
                    }

                    outputStream.flush()
                    success = true
                }
            }
        } catch (e: IOException) {
            return SaveResultModel(false, null, "Vision's analysis: ${e.message}").toHashMap()
        } finally {
            try {
                outputStream?.close()
                fileInputStream?.close()
            } catch (e: IOException) {
                // Ignore close exceptions
            }
        }

        return if (success) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                val mediaScanIntent = Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE)
                mediaScanIntent.data = fileUri
                context.sendBroadcast(mediaScanIntent)
            }
            SaveResultModel(true, fileUri.toString(), null).toHashMap()
        } else {
            SaveResultModel(false, null, "Vision's analysis: Save operation failed").toHashMap()
        }
    }

    /**
     * Generates a content URI for saving media files.
     */
    private fun generateUri(extension: String, name: String, customRelativePath: String? = null): Uri? {
        val fileName = MediaStoreUtils.ensureExtension(name, extension)
        val mimeType = MediaStoreUtils.getMIMEType(extension)
        
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // Android 10 (Q) and above: Use MediaStore
            val directoryType = MediaStoreUtils.getDirectoryType(mimeType)
            val relativePath = MediaStoreUtils.buildRelativePath(directoryType, customRelativePath)
            
            val contentUri = when {
                MediaStoreUtils.isMediaType(mimeType, "video/") -> MediaStore.Video.Media.EXTERNAL_CONTENT_URI
                MediaStoreUtils.isMediaType(mimeType, "audio/") -> MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
                else -> MediaStore.Images.Media.EXTERNAL_CONTENT_URI
            }

            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
                if (mimeType != null) {
                    put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
                }
            }

            applicationContext?.contentResolver?.insert(contentUri, values)
        } else {
            // Below Android 10: Use file system directly
            val directoryType = MediaStoreUtils.getDirectoryType(mimeType)
            val storePath = Environment.getExternalStoragePublicDirectory(directoryType).absolutePath
            
            // Create custom subfolder if specified
            val baseDir = if (customRelativePath.isNullOrEmpty()) {
                File(storePath)
            } else {
                File(storePath, customRelativePath).apply {
                    if (!exists()) {
                        mkdirs()
                    }
                }
            }
            
            val file = File(baseDir, fileName)
            Uri.fromFile(file)
        }
    }
}