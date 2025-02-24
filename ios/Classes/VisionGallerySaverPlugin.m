#import "VisionGallerySaverPlugin.h"
#if __has_include(<vision_gallery_saver/vision_gallery_saver-Swift.h>)
#import <vision_gallery_saver/vision_gallery_saver-Swift.h>
#else
#import "vision_gallery_saver-Swift.h"
#endif

@implementation VisionGallerySaverPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    [SwiftVisionGallerySaverPlugin registerWithRegistrar:registrar];
}
@end