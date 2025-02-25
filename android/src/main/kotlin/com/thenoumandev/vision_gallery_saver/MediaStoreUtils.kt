package com.thenoumandev.vision_gallery_saver

import android.content.Context
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Environment
import android.webkit.MimeTypeMap
import java.io.File

/**
 * Utility class for MediaStore operations, providing helper methods
 * for handling file types, MIME types, and media scanning.
 */
object MediaStoreUtils {
    
    /**
     * Gets the MIME type from a file extension.
     * 
     * @param extension The file extension (e.g., "jpg", "mp4")
     * @return The MIME type for the extension, or null if unknown
     */
    fun getMIMEType(extension: String): String? {
        if (extension.isEmpty()) return null
        return MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension.lowercase())
    }
    
    /**
     * Scans a file URI to make it visible in the gallery.
     * 
     * @param context The application context
     * @param uri The URI of the file to scan
     * @param mimeType The MIME type of the file
     */
    fun scanFile(context: Context, uri: Uri, mimeType: String?) {
        MediaScannerConnection.scanFile(
            context,
            arrayOf(uri.path),
            arrayOf(mimeType),
            null
        )
    }
    
    /**
     * Determines if a file is a specific media type based on MIME type.
     * 
     * @param mimeType The MIME type to check
     * @param mediaType The media type prefix to check against (e.g., "image/", "video/")
     * @return True if the MIME type matches the specified media type
     */
    fun isMediaType(mimeType: String?, mediaType: String): Boolean {
        return mimeType?.startsWith(mediaType) == true
    }
    
    /**
     * Gets the appropriate storage directory for a given MIME type.
     * 
     * @param mimeType The MIME type of the file
     * @return The appropriate Environment directory type
     */
    fun getDirectoryType(mimeType: String?): String {
        return when {
            isMediaType(mimeType, "video/") -> Environment.DIRECTORY_MOVIES
            isMediaType(mimeType, "audio/") -> Environment.DIRECTORY_MUSIC
            isMediaType(mimeType, "image/") -> Environment.DIRECTORY_PICTURES
            else -> Environment.DIRECTORY_DOWNLOADS
        }
    }
    
    /**
     * Constructs a proper relative path combining the default directory and custom path.
     * 
     * @param directoryType The default directory type (e.g., DIRECTORY_PICTURES)
     * @param customPath The custom path to append (if any)
     * @return The combined relative path
     */
    fun buildRelativePath(directoryType: String, customPath: String?): String {
        if (customPath.isNullOrEmpty()) {
            return directoryType
        }
        
        // If custom path already starts with the directory type, use it as is
        if (customPath.startsWith(directoryType)) {
            return customPath
        }
        
        // Otherwise, combine them
        return "$directoryType${File.separator}$customPath"
    }
    
    /**
     * Checks if the file extension is for an image file.
     * 
     * @param fileName The file name to check
     * @return True if the file has an image extension
     */
    fun isImageFile(fileName: String): Boolean {
        val imageExtensions = listOf(".jpg", ".jpeg", ".png", ".gif", ".bmp", ".webp", ".heic")
        return imageExtensions.any { fileName.lowercase().endsWith(it) }
    }
    
    /**
     * Checks if the file extension is for a video file.
     * 
     * @param fileName The file name to check
     * @return True if the file has a video extension
     */
    fun isVideoFile(fileName: String): Boolean {
        val videoExtensions = listOf(".mp4", ".mov", ".3gp", ".mkv", ".webm", ".avi")
        return videoExtensions.any { fileName.lowercase().endsWith(it) }
    }
    
    /**
     * Ensures a filename has the specified extension.
     * 
     * @param fileName The filename to check
     * @param extension The extension to ensure (without the dot)
     * @return The filename with the extension
     */
    fun ensureExtension(fileName: String, extension: String): String {
        val ext = if (extension.startsWith(".")) extension else ".$extension"
        return if (fileName.lowercase().endsWith(ext.lowercase())) {
            fileName
        } else {
            "$fileName$ext"
        }
    }
}