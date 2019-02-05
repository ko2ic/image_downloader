package com.ko2ic.imagedownloader

import android.app.DownloadManager
import android.content.ContentValues
import android.content.Context
import android.net.Uri
import android.os.Environment
import android.provider.MediaStore
import android.util.Log
import android.webkit.MimeTypeMap
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.PluginRegistry.Registrar
import java.io.BufferedInputStream
import java.io.File
import java.io.FileInputStream
import java.net.URLConnection
import java.text.SimpleDateFormat
import java.util.*


class ImageDownloaderPlugin(
    private val registrar: PluginRegistry.Registrar,
    private val permissionListener: ImageDownloderPermissionListener
) : MethodCallHandler {
    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val channel = MethodChannel(registrar.messenger(), "plugins.ko2ic.com/image_downloader")

            val listener = ImageDownloderPermissionListener(registrar.activity())
            registrar.addRequestPermissionsResultListener(listener)

            channel.setMethodCallHandler(ImageDownloaderPlugin(registrar, listener))
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "downloadImage" -> {
                val permissionCallback = CallbackImpl(call, result, registrar.context())
                this.permissionListener.callback = permissionCallback
                if (permissionListener.alreadyGranted()) {
                    permissionCallback.granted()
                }
            }
            "findPath" -> {
                val imageId = call.argument<String>("imageId") ?: throw IllegalArgumentException("imageId is required.")
                val filePath = findPath(imageId, registrar.context())
                result.success(filePath)
            }
            "findName" -> {
                val imageId = call.argument<String>("imageId") ?: throw IllegalArgumentException("imageId is required.")
                val fileName = findName(imageId, registrar.context())
                result.success(fileName)
            }
            "findByteSize" -> {
                val imageId = call.argument<String>("imageId") ?: throw IllegalArgumentException("imageId is required.")
                val fileSize = findByteSize(imageId, registrar.context())
                result.success(fileSize)
            }
            "findMimeType" -> {
                val imageId = call.argument<String>("imageId") ?: throw IllegalArgumentException("imageId is required.")
                val mimeType = findMimeType(imageId, registrar.context())
                result.success(mimeType)
            }
            else -> result.notImplemented()
        }
    }

    private fun findPath(imageId: String, context: Context): String {
        val data = findFileData(imageId, context)
        return data.path
    }

    private fun findName(imageId: String, context: Context): String {
        val data = findFileData(imageId, context)
        return data.name
    }

    private fun findByteSize(imageId: String, context: Context): Int {
        val data = findFileData(imageId, context)
        return data.byteSize
    }

    private fun findMimeType(imageId: String, context: Context): String {
        val data = findFileData(imageId, context)
        return data.mimetype
    }

    private fun findFileData(imageId: String, context: Context): FileData {
        val contentResolver = context.contentResolver
        return contentResolver.query(
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            null,
            "${MediaStore.Images.Media._ID}=?",
            arrayOf(imageId),
            null
        ).use {
            it.moveToFirst()
            val path = it.getString(it.getColumnIndex(MediaStore.Images.Media.DATA))
            val name = it.getString(it.getColumnIndex(MediaStore.Images.Media.DISPLAY_NAME))
            val size = it.getInt(it.getColumnIndex(MediaStore.Images.Media.SIZE))
            val mimetype = it.getString(it.getColumnIndex(MediaStore.Images.Media.MIME_TYPE))
            FileData(path = path, name = name, byteSize = size, mimetype = mimetype)

        }
    }

    class CallbackImpl(private val call: MethodCall, private val result: Result, private val context: Context) :
        ImageDownloderPermissionListener.Callback {
        override fun granted() {
            val url = call.argument<String>("url")

            val uri = Uri.parse(url)
            val request = DownloadManager.Request(uri)

            request.setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
            request.allowScanningByMediaScanner()

            val tempFileName = SimpleDateFormat("yyyy-MM-dd.HH.mm.sss", Locale.getDefault()).format(Date())

            request.setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, tempFileName)

            val downloader = Downloader(context, request)

            downloader.execute(onNext = {
                when (it) {
                    is Downloader.DownloadStatus.Failed -> Log.d("downloader", it.reason)
                    is Downloader.DownloadStatus.Paused -> Log.d("downloader", it.reason)
                }

            }, onError = {
                result.error(it.message, null, null)
            }, onComplete = {

                val file =
                    File("${Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)}/$tempFileName")

                val stream = BufferedInputStream(FileInputStream(file))
                val mimeType = URLConnection.guessContentTypeFromStream(stream)

                val extension = MimeTypeMap.getSingleton().getExtensionFromMimeType(mimeType)

                val fileName = if (extension != null) {
                    "$tempFileName.$extension"
                } else {
                    uri.lastPathSegment?.split("/")?.last() ?: "file"
                }

                val newFile =
                    File("${Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)}/$fileName")

                file.renameTo(newFile)
                val imageId = saveToContentResolver(newFile)
                result.success(imageId)
            })
        }

        override fun denied() {
            result.success(null)
        }

        private fun saveToContentResolver(file: File): String {
            val mimeType = MimeTypeMap.getSingleton().getMimeTypeFromExtension(file.extension)
            val contentValues = ContentValues()

            contentValues.put(MediaStore.Images.Media.MIME_TYPE, mimeType)
            contentValues.put(MediaStore.Images.Media.DATA, file.absolutePath)
            contentValues.put(MediaStore.Images.ImageColumns.DISPLAY_NAME, file.name)
            contentValues.put(MediaStore.Images.ImageColumns.SIZE, file.length());
            context.contentResolver.insert(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                contentValues
            )

            return context.contentResolver.query(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                arrayOf(MediaStore.Images.Media._ID, MediaStore.Images.Media.DATA),
                "${MediaStore.Images.Media.DATA}=?",
                arrayOf(file.absolutePath),
                null
            ).use {
                it.moveToFirst()
                it.getString(it.getColumnIndex(MediaStore.Images.Media._ID))
            }
        }
    }

    private data class FileData(val path: String, val name: String, val byteSize: Int, val mimetype: String)
}