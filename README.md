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

Add this permission in ```AndroidManifest.xml```. (If you call ```AndroidDestinationType#inExternalFilesDir()```, This setting is not necessary.)

```
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

## Example

### Basic

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

### Custom

You can specify the storage location.    
(Currently, external storage is only supported on Android.)

Three directories by default are provided.

* AndroidDestinationType.directoryDownloads -> Environment.DIRECTORY_DOWNLOADS on Android
* AndroidDestinationType.directoryPictures -> Environment.DIRECTORY_PICTURES on Android
* AndroidDestinationType.directoryDCIM -> Environment.DIRECTORY_DCIM on Android

In addition, there is also custom. 

For example, the following sources is stored in ```/storage/emulated/0/sample/custom/sample.gif```.       
(Depends on the device.)

```
await ImageDownloader.downloadImage(url,
                                    destination: AndroidDestinationType.custom('sample')                                  
                                    ..subDirectory("custom/sample.gif"),
        );
```

For example, the following sources is stored in ```/storage/emulated/0/Android/data/<applicationId>/files/sample/custom/sample.gif```by calling ```inExternalFilesDir()``` .    
(Depends on the device.) 
 
```
 await ImageDownloader.downloadImage(url,
                                     destination: AndroidDestinationType.custom('sample')
                                     ..inExternalFilesDir()
                                     ..subDirectory("custom/sample.gif"),
         );
```
 
Note: ```inExternalFilesDir()``` will not require ```WRITE_EXTERNAL_STORAGE``` permission, but downloaded images will also be deleted when uninstalling.


## Trouble Shooting

https://github.com/ko2ic/image_downloader/wiki#trouble-shooting