# image_downloader

Flutter plugin that downloads images and movies on the Internet and saves to Photo Library on iOS or specified directory on Android.     
This will keep Exif(DateTimeOriginal) and GPS(Latitude, Longitude).

## Getting Started

### ios

Add the following keys to your Info.plist file, located in <project root>/ios/Runner/Info.plist:
  
  * NSPhotoLibraryUsageDescription - Specifies the reason for your app to access the user’s photo library. This is called ```Privacy - Photo Library Usage Description``` in the visual editor.
  * NSPhotoLibraryAddUsageDescription - Specifies the reason for your app to get write-only access to the user’s photo library. This is called ```Privacy - Photo Library Additions Usage Description``` in the visual editor.
  
### Android

Add this permission in ```AndroidManifest.xml```. (If you call ```AndroidDestinationType#inExternalFilesDir()```, This setting is not necessary.)

```xml
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

## Example

### Basic

```dart
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
  print(error);
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
* AndroidDestinationType.directoryMovies -> Environment.DIRECTORY_MOVIES on Android

In addition, there is also custom. 

For example, the following sources is stored in ```/storage/emulated/0/sample/custom/sample.gif```.       
(Depends on the device.)

```dart
await ImageDownloader.downloadImage(url,
                                    destination: AndroidDestinationType.custom('sample')                                  
                                    ..subDirectory("custom/sample.gif"),
        );
```

For example, the following sources is stored in ```/storage/emulated/0/Android/data/<applicationId>/files/sample/custom/sample.gif```by calling ```inExternalFilesDir()``` .    
(Depends on the device.) 
 
```dart
 await ImageDownloader.downloadImage(url,
                                     destination: AndroidDestinationType.custom('sample')
                                     ..inExternalFilesDir()
                                     ..subDirectory("custom/sample.gif"),
         );
```
 
Note: ```inExternalFilesDir()``` will not require ```WRITE_EXTERNAL_STORAGE``` permission, but downloaded images will also be deleted when uninstalling.


##  Progress

You can get the progress value.   
Note: On iOS, ```onProgressUpdate``` cannot get imageId.

```dart
  @override
  void initState() {
    super.initState();

    ImageDownloader.callback(onProgressUpdate: (String imageId, int progress) {
      setState(() {
        _progress = progress;
      });
    });
  }
```

## Downloading multiple files

You can do it simply by using ```await``` .

```dart
var list = [
  "https://raw.githubusercontent.com/wiki/ko2ic/image_downloader/images/bigsize.jpg",
  "https://raw.githubusercontent.com/wiki/ko2ic/image_downloader/images/flutter.jpg",
  "https://raw.githubusercontent.com/wiki/ko2ic/image_downloader/images/flutter_transparent.png",
  "https://raw.githubusercontent.com/wiki/ko2ic/flutter_google_ad_manager/images/sample.gif",
  "https://raw.githubusercontent.com/wiki/ko2ic/image_downloader/images/flutter_no.png",
  "https://raw.githubusercontent.com/wiki/ko2ic/image_downloader/images/flutter.png",
];

List<File> files = [];

for (var url in list) {
  try {
    var imageId = await ImageDownloader.downloadImage(url);
    var path = await ImageDownloader.findPath(imageId);
    files.add(File(path));
  } catch (error) {
    print(error);
  }
}
setState(() {
  _mulitpleFiles.addAll(files);
});
```

## Preview

There is a ```open``` method to be able to immediately preview the download file.   
If you call it, in the case of ios, a preview screen using UIDocumentInteractionController is displayed. In case of Android, it is displayed by Intent.    

```dart
var imageId = await ImageDownloader.downloadImage(url);
var path = await ImageDownloader.findPath(imageId);
await ImageDownloader.open(path);
```

Note: in the case of android, to use this feature, the following settings are required.

Add the following within \<application\> tag in ```AndroidManifest.xml``` .

```xml
        <provider
                android:name="com.ko2ic.imagedownloader.FileProvider"
                android:authorities="${applicationId}.image_downloader.provider"
                android:exported="false"
                android:grantUriPermissions="true">
            <meta-data
                    android:name="android.support.FILE_PROVIDER_PATHS"
                    android:resource="@xml/provider_paths"/>
        </provider>
```

Add ```provider_paths.xml```  in ```android/app/src/main/res/xml/``` .

```xml
<?xml version="1.0" encoding="utf-8"?>
<paths xmlns:android="http://schemas.android.com/apk/res/android">
    <external-path name="external_files" path="."/>
</paths>
```

## Error Handling

### downloadImage()

You can determine the type of error with ```PlatformException#code```.   

In the case of HTTP status error, the code is stored.   
In the case of the file format is not supported, ```unsupported_file``` is stored.   
There is an important point in the case of ```unsupported_file```.   
__Even unsupported files are stored in a temporary directory.__   
It can be retrieved with ```error.details ["unsupported_file_path"];``` .   
Note: it will be deleted when you exit the app.


```dart
ImageDownloader.downloadImage(url).catchError((error) {
  if (error is PlatformException) {
    var path = "";
    if (error.code == "404") {
      print("Not Found Error.");
    } else if (error.code == "unsupported_file") {
      print("UnSupported FIle Error.");
      path = error.details["unsupported_file_path"];
    }
  }
})

```

### open()

If the file can not be previewed, the ```preview_error``` is stored in the code.

```dart
  await ImageDownloader.open(_path).catchError((error) {
    if (error is PlatformException) {
      if (error.code == "preview_error") {
        print(error.message);
      }
    }    
  });
```

## Trouble Shooting

https://github.com/ko2ic/image_downloader/wiki#trouble-shooting
