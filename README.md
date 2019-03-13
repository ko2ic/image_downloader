# image_downloader

Flutter plugin that downloads images on the Internet and saves them on device.     
This will keep Exif(DateTimeOriginal) and GPS(Latitude, Longitude).

For Android, image is saved in ```Environment.DIRECTORY_DOWNLOADS```.   
For ios, image is saved in Photo Library.

## Getting Started

### ios

Add the following keys to your Info.plist file, located in <project root>/ios/Runner/Info.plist:
  
  * NSPhotoLibraryUsageDescription - Specifies the reason for your app to access the user’s photo library. This is called ```Privacy - Photo Library Usage Description``` in the visual editor.
  * NSPhotoLibraryAddUsageDescription - Specifies the reason for your app to get write-only access to the user’s photo library. This is called ```Privacy - Photo Library Additions Usage Description``` in the visual editor.
  
### Android

Add this permission in ```AndroidManifest.xml```. 

```
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

## Example

```
try {
  // Saved with this method.
  var imageId = await ImageDownloader.downloadImage("https://raw.githubusercontent.com/wiki/ko2ic/image_downloader/images/flutter.png");
  if (imageId == null) {
    return;
  }

  // Below is a method of obtaining saved image information.
  var fileName = await ImageDownloader.findName(imageId);
  var path = await ImageDownloader.findPath(imageId);
  var size = await ImageDownloader.findByteSize(imageId);
  var mimeType = await ImageDownloader.findMimeType(imageId);
} on PlatformException catch (error) {
  print(error)
}
```

The return value is as follows.

* imageId of the saved image if saving succeeded.
* null if not been granted permission.
* Otherwise it is a PlatformException.

## Trouble Shooting

https://github.com/ko2ic/image_downloader/wiki#trouble-shooting