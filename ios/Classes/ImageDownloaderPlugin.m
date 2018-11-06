#import "ImageDownloaderPlugin.h"
#import <image_downloader/image_downloader-Swift.h>

@implementation ImageDownloaderPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftImageDownloaderPlugin registerWithRegistrar:registrar];
}
@end
