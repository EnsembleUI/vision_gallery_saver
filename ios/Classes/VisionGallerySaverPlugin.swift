import Flutter
import UIKit
import Photos

/**
 * SwiftVisionGallerySaverPlugin
 * 
 * A Flutter plugin that provides Vision-like precision for saving media to iOS device gallery.
 * Handles image and video saving with proper permission management and error handling.
 */
public class SwiftVisionGallerySaverPlugin: NSObject, FlutterPlugin {
    /// Error messages for various scenarios
    private struct ErrorMessages {
        static let permissionDenied = "Vision's Analysis: Permission denied or restricted. Please check settings."
        static let invalidParameters = "Vision's Analysis: Invalid parameters"
        static let unsupportedFileFormat = "Vision's Analysis: Unsupported file format"
        static let saveFailure = "Vision's Analysis: Failed to save file"
        static let fileTooLarge = "Vision's Analysis: File size exceeds limit"
    }
    
    /// Maximum file size (100 MB)
    private let maxFileSize: Int64 = 100 * 1024 * 1024
    
    /// FlutterResult callback holder
    private var result: FlutterResult?

    /// Register plugin with Flutter engine
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "vision_gallery_saver", binaryMessenger: registrar.messenger())
        let instance = SwiftVisionGallerySaverPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    /// Handle method calls from Flutter
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        self.result = result
        
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
            
        case "saveImageToGallery":
            handleImageSave(call)
            
        case "saveFileToGallery":
            handleFileSave(call)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    /// Handle image saving method
    private func handleImageSave(_ call: FlutterMethodCall) {
        guard let arguments = call.arguments as? [String: Any],
              let imageData = (arguments["imageBytes"] as? FlutterStandardTypedData)?.data,
              let image = UIImage(data: imageData),
              let quality = arguments["quality"] as? Int,
              let isReturnImagePath = arguments["isReturnImagePathOfIOS"] as? Bool
        else {
            saveResult(isSuccess: false, error: ErrorMessages.invalidParameters)
            return
        }
        
        let fileName = arguments["name"] as? String
        let skipIfExists = arguments["skipIfExists"] as? Bool ?? false
        
        // Check authorization
        requestPhotoLibraryAuthorization { authorized in
            guard authorized else {
                self.saveResult(isSuccess: false, error: ErrorMessages.permissionDenied)
                return
            }
            
            // Check if file exists before saving
            if skipIfExists, let fileName = fileName {
                let existingAsset = self.findExistingImageAsset(withName: fileName)
                if let asset = existingAsset {
                    self.handleExistingAsset(asset: asset)
                    return
                }
            }
            
            // Compress image based on quality
            guard let compressedImageData = image.jpegData(compressionQuality: CGFloat(quality) / 100.0) else {
                self.saveResult(isSuccess: false, error: ErrorMessages.saveFailure)
                return
            }
            
            self.saveImage(UIImage(data: compressedImageData) ?? image, 
                           isReturnImagePath: isReturnImagePath, 
                           fileName: fileName)
        }
    }
    
    /// Handle file saving method
    private func handleFileSave(_ call: FlutterMethodCall) {
        guard let arguments = call.arguments as? [String: Any],
              let path = arguments["file"] as? String,
              let isReturnFilePath = arguments["isReturnPathOfIOS"] as? Bool
        else {
            saveResult(isSuccess: false, error: ErrorMessages.invalidParameters)
            return
        }
        
        let fileName = arguments["name"] as? String
        let skipIfExists = arguments["skipIfExists"] as? Bool ?? false
        
        // Check authorization
        requestPhotoLibraryAuthorization { authorized in
            guard authorized else {
                self.saveResult(isSuccess: false, error: ErrorMessages.permissionDenied)
                return
            }
            
            // Validate file size
            guard self.isFileSizeValid(atPath: path) else {
                self.saveResult(isSuccess: false, error: ErrorMessages.fileTooLarge)
                return
            }
            
            // Check if file exists before saving
            if skipIfExists, let fileName = fileName {
                let existingAsset = self.findExistingAsset(withName: fileName)
                if let asset = existingAsset {
                    self.handleExistingAsset(asset: asset)
                    return
                }
            }
            
            // Determine file type and save accordingly
            if self.isImageFile(filename: path) {
                self.saveImageAtFileUrl(path, 
                                        isReturnImagePath: isReturnFilePath, 
                                        fileName: fileName)
            } else if self.isVideoFile(path) {
                self.saveVideo(path, 
                               isReturnImagePath: isReturnFilePath, 
                               fileName: fileName)
            } else {
                self.saveResult(isSuccess: false, 
                                error: ErrorMessages.unsupportedFileFormat)
            }
        }
    }
    
    /// Check file size
    private func isFileSizeValid(atPath path: String) -> Bool {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: path),
              let fileSize = attributes[.size] as? Int64 else {
            return false
        }
        return fileSize <= maxFileSize
    }
    
    /// Request photo library authorization
    private func requestPhotoLibraryAuthorization(completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                completion(status == .authorized)
            }
        }
    }
    
    /// Handle existing asset when skipIfExists is true
    private func handleExistingAsset(asset: PHAsset) {
        let options = PHContentEditingInputRequestOptions()
        options.canHandleAdjustmentData = { _ in true }
        
        asset.requestContentEditingInput(with: options) { [weak self] input, _ in
            guard let self = self else { return }
            
            if let urlStr = input?.fullSizeImageURL?.absoluteString {
                let result: [String: Any] = [
                    "isSuccess": true,
                    "foundExistingFile": true,
                    "existingFilePath": urlStr,
                    "filePath": nil,
                    "errorMessage": nil
                ]
                self.result?(result)
            } else {
                self.saveResult(isSuccess: true, foundExistingFile: true)
            }
        }
    }
    
    /// Find existing image asset
    private func findExistingImageAsset(withName fileName: String) -> PHAsset? {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "originalFilename CONTAINS[c] %@", fileName)
        
        let imageFetch = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        return imageFetch.firstObject
    }
    
    /// Find existing asset (image or video)
    private func findExistingAsset(withName fileName: String) -> PHAsset? {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "originalFilename CONTAINS[c] %@", fileName)
        
        // First try to find an image
        let imageFetch = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        if let imageAsset = imageFetch.firstObject {
            return imageAsset
        }
        
        // If no image found, try video
        let videoFetch = PHAsset.fetchAssets(with: .video, options: fetchOptions)
        return videoFetch.firstObject
    }
    
    /// Save image to photo library
    private func saveImage(
        _ image: UIImage, 
        isReturnImagePath: Bool, 
        fileName: String? = nil
    ) {
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
            
            // Set filename if provided
            if let fileName = fileName {
                request.creationDate = Date()
                request.location = nil
            }
        }) { [weak self] success, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if success {
                    if isReturnImagePath {
                        self.fetchAndReturnImagePath(image)
                    } else {
                        self.saveResult(isSuccess: true)
                    }
                } else {
                    self.saveResult(
                        isSuccess: false, 
                        error: error?.localizedDescription ?? ErrorMessages.saveFailure
                    )
                }
            }
        }
    }
    
    /// Fetch and return path for saved image
    private func fetchAndReturnImagePath(_ image: UIImage) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 1
        
        let imageFetch = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        if let asset = imageFetch.firstObject {
            let options = PHContentEditingInputRequestOptions()
            options.canHandleAdjustmentData = { _ in true }
            
            asset.requestContentEditingInput(with: options) { [weak self] input, _ in
                guard let self = self else { return }
                
                if let urlStr = input?.fullSizeImageURL?.absoluteString {
                    self.saveResult(isSuccess: true, filePath: urlStr)
                } else {
                    self.saveResult(isSuccess: true)
                }
            }
        } else {
            self.saveResult(isSuccess: true)
        }
    }
    
    /// Save video to photo library
    private func saveVideo(
        _ path: String, 
        isReturnImagePath: Bool, 
        fileName: String? = nil
    ) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL(fileURLWithPath: path))
        }) { [weak self] success, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if success {
                    if isReturnImagePath {
                        self.fetchAndReturnVideoPath(path)
                    } else {
                        self.saveResult(isSuccess: true)
                    }
                } else {
                    self.saveResult(
                        isSuccess: false, 
                        error: error?.localizedDescription ?? ErrorMessages.saveFailure
                    )
                }
            }
        }
    }
    
    /// Fetch and return path for saved video
    private func fetchAndReturnVideoPath(_ originalPath: String) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 1
        
        let videoFetch = PHAsset.fetchAssets(with: .video, options: fetchOptions)
        
        if let asset = videoFetch.firstObject {
            let options = PHVideoRequestOptions()
            options.version = .original
            options.deliveryMode = .highQualityFormat
            
            PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { [weak self] avAsset, _, _ in
                guard let self = self else { return }
                
                if let urlAsset = avAsset as? AVURLAsset {
                    self.saveResult(isSuccess: true, filePath: urlAsset.url.absoluteString)
                } else {
                    self.saveResult(isSuccess: true)
                }
            }
        } else {
            self.saveResult(isSuccess: true)
        }
    }
    
    /// Save image from file URL
    private func saveImageAtFileUrl(
        _ url: String, 
        isReturnImagePath: Bool, 
        fileName: String? = nil
    ) {
        guard let image = UIImage(contentsOfFile: url) else {
            saveResult(isSuccess: false, error: ErrorMessages.saveFailure)
            return
        }
        
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
            
            // Set filename if provided
            if let fileName = fileName {
                request.creationDate = Date()
                request.location = nil
            }
        }) { [weak self] success, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if success {
                    if isReturnImagePath {
                        self.fetchAndReturnImagePath(image)
                    } else {
                        self.saveResult(isSuccess: true)
                    }
                } else {
                    self.saveResult(
                        isSuccess: false, 
                        error: error?.localizedDescription ?? ErrorMessages.saveFailure
                    )
                }
            }
        }
    }
    
    /// Send result back to Flutter
    private func saveResult(
        isSuccess: Bool, 
        filePath: String? = nil, 
        error: String? = nil,
        foundExistingFile: Bool = false,
        existingFilePath: String? = nil
    ) {
        var resultDict: [String: Any] = [
            "isSuccess": isSuccess,
            "foundExistingFile": foundExistingFile
        ]
        
        if let filePath = filePath {
            resultDict["filePath"] = filePath
        }
        
        if let existingFilePath = existingFilePath {
            resultDict["existingFilePath"] = existingFilePath
        }
        
        if let error = error {
            resultDict["errorMessage"] = error
        }
        
        result?(resultDict)
    }
    
    /// Check if file is an image based on extension
    private func isImageFile(filename: String) -> Bool {
        let imageExtensions = [".jpg", ".jpeg", ".png", ".gif", ".heic", ".webp", ".tiff"]
        return imageExtensions.contains { filename.lowercased().hasSuffix($0) }
    }
    
    /// Check if file is a video based on extension
    private func isVideoFile(_ path: String) -> Bool {
        let videoExtensions = [".mp4", ".mov", ".avi", ".mkv", ".webm", ".m4v"]
        return videoExtensions.contains { path.lowercased().hasSuffix($0) }
    }
}