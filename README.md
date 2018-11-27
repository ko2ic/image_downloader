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
bool isSuccess;
try {
  isSuccess = await ImageDownloader.downloadImage("https://flutter.io/images/flutter-mark-square-100.png");
} on PlatformException catch (_) {
  isSuccess = false;
}
```

True if saving succeeded.     
False if not been granted permission.    
Otherwise it is a PlatformException.
