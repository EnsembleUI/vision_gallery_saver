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
    /// Error message for permission-related issues
    let errorMessage = "Vision's Analysis: Permission denied or restricted. Please check settings."
    
    /// FlutterResult callback holder
    var result: FlutterResult?

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
            guard let arguments = call.arguments as? [String: Any],
                  let imageData = (arguments["imageBytes"] as? FlutterStandardTypedData)?.data,
                  let image = UIImage(data: imageData),
                  let quality = arguments["quality"] as? Int,
                  let isReturnImagePath = arguments["isReturnImagePathOfIOS"] as? Bool
            else {
                saveResult(isSuccess: false, error: "Vision's Analysis: Invalid parameters")
                return
            }
            
            let newImage = image.jpegData(compressionQuality: CGFloat(quality) / 100.0)!
            saveImage(UIImage(data: newImage) ?? image, isReturnImagePath: isReturnImagePath)
            
        case "saveFileToGallery":
            guard let arguments = call.arguments as? [String: Any],
                  let path = arguments["file"] as? String,
                  let isReturnFilePath = arguments["isReturnPathOfIOS"] as? Bool
            else {
                saveResult(isSuccess: false, error: "Vision's Analysis: Invalid parameters")
                return
            }
            
            if isImageFile(filename: path) {
                saveImageAtFileUrl(path, isReturnImagePath: isReturnFilePath)
            } else if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(path) {
                saveVideo(path, isReturnImagePath: isReturnFilePath)
            } else {
                saveResult(isSuccess: false, error: "Vision's Analysis: Unsupported file format")
            }
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    /**
     * Save video to photo library
     * - Parameters:
     *   - path: Path to the video file
     *   - isReturnImagePath: Whether to return the saved file path
     */
    private func saveVideo(_ path: String, isReturnImagePath: Bool) {
        if !isReturnImagePath {
            UISaveVideoAtPathToSavedPhotosAlbum(path, self, #selector(didFinishSavingVideo), nil)
            return
        }
        
        var videoIds: [String] = []
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL(fileURLWithPath: path))
            if let videoId = request?.placeholderForCreatedAsset?.localIdentifier {
                videoIds.append(videoId)
            }
        }, completionHandler: { [weak self] success, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if success && !videoIds.isEmpty {
                    let assets = PHAsset.fetchAssets(withLocalIdentifiers: videoIds, options: nil)
                    if let videoAsset = assets.firstObject {
                        PHImageManager().requestAVAsset(forVideo: videoAsset, options: nil) { avurlAsset, _, _ in
                            if let urlAsset = avurlAsset as? AVURLAsset {
                                self.saveResult(isSuccess: true, filePath: urlAsset.url.absoluteString)
                            }
                        }
                    }
                } else {
                    self.saveResult(isSuccess: false, error: self.errorMessage)
                }
            }
        })
    }
    
    /**
     * Save image to photo library
     * - Parameters:
     *   - image: UIImage to save
     *   - isReturnImagePath: Whether to return the saved file path
     */
    private func saveImage(_ image: UIImage, isReturnImagePath: Bool) {
        if !isReturnImagePath {
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(didFinishSavingImage), nil)
            return
        }
        
        var imageIds: [String] = []
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
            if let imageId = request.placeholderForCreatedAsset?.localIdentifier {
                imageIds.append(imageId)
            }
        }, completionHandler: { [weak self] success, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if success && !imageIds.isEmpty {
                    let assets = PHAsset.fetchAssets(withLocalIdentifiers: imageIds, options: nil)
                    if let imageAsset = assets.firstObject {
                        let options = PHContentEditingInputRequestOptions()
                        options.canHandleAdjustmentData = { _ in true }
                        imageAsset.requestContentEditingInput(with: options) { [weak self] input, _ in
                            guard let self = self else { return }
                            if let urlStr = input?.fullSizeImageURL?.absoluteString {
                                self.saveResult(isSuccess: true, filePath: urlStr)
                            }
                        }
                    }
                } else {
                    self.saveResult(isSuccess: false, error: self.errorMessage)
                }
            }
        })
    }
    
    /**
     * Save image from file URL
     * - Parameters:
     *   - url: Path to the image file
     *   - isReturnImagePath: Whether to return the saved file path
     */
    private func saveImageAtFileUrl(_ url: String, isReturnImagePath: Bool) {
        if !isReturnImagePath {
            if let image = UIImage(contentsOfFile: url) {
                UIImageWriteToSavedPhotosAlbum(image, self, #selector(didFinishSavingImage), nil)
            }
            return
        }
        
        var imageIds: [String] = []
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: URL(string: url)!)
            if let imageId = request?.placeholderForCreatedAsset?.localIdentifier {
                imageIds.append(imageId)
            }
        }, completionHandler: { [weak self] success, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if success && !imageIds.isEmpty {
                    let assets = PHAsset.fetchAssets(withLocalIdentifiers: imageIds, options: nil)
                    if let imageAsset = assets.firstObject {
                        let options = PHContentEditingInputRequestOptions()
                        options.canHandleAdjustmentData = { _ in true }
                        imageAsset.requestContentEditingInput(with: options) { [weak self] input, _ in
                            guard let self = self else { return }
                            if let urlStr = input?.fullSizeImageURL?.absoluteString {
                                self.saveResult(isSuccess: true, filePath: urlStr)
                            }
                        }
                    }
                } else {
                    self.saveResult(isSuccess: false, error: self.errorMessage)
                }
            }
        })
    }
    
    /// Callback for video saving completion
    @objc private func didFinishSavingVideo(_ videoPath: String, error: NSError?, contextInfo: UnsafeMutableRawPointer?) {
        saveResult(isSuccess: error == nil, error: error?.localizedDescription)
    }
    
    /// Callback for image saving completion
    @objc private func didFinishSavingImage(_ image: UIImage, error: NSError?, contextInfo: UnsafeMutableRawPointer?) {
        saveResult(isSuccess: error == nil, error: error?.localizedDescription)
    }
    
    /**
     * Create and send result back to Flutter
     * - Parameters:
     *   - isSuccess: Whether the operation was successful
     *   - error: Optional error message
     *   - filePath: Optional file path
     */
    private func saveResult(isSuccess: Bool, error: String? = nil, filePath: String? = nil) {
        var saveResult = SaveResultModel()
        saveResult.isSuccess = isSuccess
        saveResult.errorMessage = error
        saveResult.filePath = filePath
        result?(saveResult.toDictionary())
    }
    
    /**
     * Check if file is an image based on extension
     * - Parameter filename: Name of the file
     * - Returns: Boolean indicating if file is an image
     */
    private func isImageFile(filename: String) -> Bool {
        let imageExtensions = [".jpg", ".jpeg", ".png", ".gif", ".heic"]
        return imageExtensions.contains { filename.lowercased().hasSuffix($0) }
    }
}

/**
 * Model for operation results
 */
struct SaveResultModel: Encodable {
    var isSuccess: Bool = false
    var filePath: String?
    var errorMessage: String?
    
    func toDictionary() -> [String: Any] {
        return [
            "isSuccess": isSuccess,
            "filePath": filePath as Any,
            "errorMessage": errorMessage as Any
        ]
    }
}