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
