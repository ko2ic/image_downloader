## 0.31.0
* Enable to work with V2

## 0.30.0
* Migrate to Null Safety

## 0.20.1
* Fix for build for XCode 12

## 0.20.0
* Support to webp(only Android)

## 0.19.2
* Got rid of download notification
* Support to bitcode

## 0.19.1

* Fix AndroidX migration
* Fix to return early when there is no activity
* Create a sample for http communication on Android9

## 0.19.0

* Fixed AndroidX migration
* Fixed typo
* Bump Gradle and Kotlin


## 0.18.1

* Fix warning of analytics.

## 0.18.0

* Supports to cancel downloading.(only single download)

## 0.17.0

* Supports HTTP Request Header.

## 0.16.2

* Fix swift_version to 4.2.

## 0.16.1

* Fix to return an error if it could not be saved on Android.

## 0.16.0

* Supports downloading HEIC and saving as jpeg in case of iOS

## 0.15.4

* Fixed an issue where progress was not displayed correctly

## 0.15.3

* Fix crash with progress function

## 0.15.2

* Add saving in Environment.DIRECTORY_MOVIES

## 0.15.1

* Fix ```NSMutableData.count``` to ```NSMutableData.length``` .

## 0.15.0+1

* Update README.md

## 0.15.0

* Support downloading video.
* Added the feature to be able to immediately preview the download file.

## 0.14.1

* Fix bug when downloading multiple files.
* Add samples of multiple files.

## 0.14.0

* Add feature to get progress value.

## 0.13.4

* Fix crash when MimeType cannot be determined.   
(It could not be retrieved from the file name due to a simple mistake)

## 0.13.3

* Fix crash when MimeType cannot be determined.

## 0.13.2

* Fix crash when calling ```downloadImage()``` after getting HTTP error on Android.

## 0.13.1

* Fix to return correct file path on iOS.

## 0.13.0

* Returned as code of PlatformException in case of Http Status Code error.(e.g. 404) 
* Delete remaining files in case of errors on Android.

## 0.12.1

* Fix to returns when not been granted permission on Android. 
* Fix Kotlin's warning.

## 0.12.0 

* Be able to specify the destination in external storage on Android. 

## 0.11.2+1

* Update Document.

## 0.11.2

* Bump Swift Version to 4.2.

## 0.11.1

* Fixed bug that does't work when using another Plugin using onRequestPermissionsResult.

## 0.11.0

* **Breaking change**. Changed the return value from bool to imageId. 
  You can acquire saved image information by using imageId.
* Added findName, findPath, findByteSize, findMimeType.

## 0.10.0

* **Breaking change**. Migrate from the deprecated original Android Support
  Library to AndroidX. This shouldn't result in any functional changes, but it
  requires any Android apps using this plugin to [also
  migrate](https://developer.android.com/jetpack/androidx/migrate) if they're
  using the original support library.

## 0.9.2

* fix broken link of sample image.

## 0.9.1

* Fix warnings of Dart Analysis.
* Describe some documents.
* Update ImageDownloder to private constructor.


## 0.9.0

* initial public release.
