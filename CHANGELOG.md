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
