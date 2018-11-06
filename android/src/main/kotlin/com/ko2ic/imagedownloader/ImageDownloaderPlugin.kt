package com.ko2ic.imagedownloader

import android.app.DownloadManager
import android.content.Context
import android.net.Uri
import android.os.Environment
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
        if (call.method == "downloadImage") {
            val permissionCallback = CallbackImpl(call, result, registrar.context())
            this.permissionListener.callback = permissionCallback
            if (permissionListener.alreadyGranted()) {
                permissionCallback.granted()
            }
        } else {
            result.notImplemented()
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

                file.renameTo(File("${Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)}/$fileName"))
                result.success(true)
            })
        }

        override fun denied() {
            result.success(false)
        }
    }
}

