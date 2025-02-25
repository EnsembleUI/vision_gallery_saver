package com.thenoumandev.vision_gallery_saver

/**
 * Data class to represent the result of save operations.
 * 
 * @property isSuccess Whether the operation was successful
 * @property filePath The path to the saved file (if successful)
 * @property errorMessage Any error message (if unsuccessful)
 * @property foundExistingFile Whether an existing file was found instead of saving a new one
 * @property existingFilePath Path to the existing file (when foundExistingFile is true)
 */
data class SaveResultModel(
    var isSuccess: Boolean,
    var filePath: String? = null,
    var errorMessage: String? = null,
    var foundExistingFile: Boolean = false,
    var existingFilePath: String? = null
) {
    /**
     * Converts the result to a HashMap for Flutter communication
     */
    fun toHashMap(): HashMap<String, Any?> {
        return hashMapOf(
            "isSuccess" to isSuccess,
            "filePath" to filePath,
            "errorMessage" to errorMessage,
            "foundExistingFile" to foundExistingFile,
            "existingFilePath" to existingFilePath
        )
    }
}