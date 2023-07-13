package com.ko2ic.imagedownloader

import android.Manifest
import android.annotation.TargetApi
import android.app.Activity
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.PluginRegistry

class ImageDownloaderPermissionListener(private val activity: Activity) :
    PluginRegistry.RequestPermissionsResultListener {

    private val permissionRequestId: Int = 2578166

    var callback: Callback? = null

    companion object {
        private val STORAGE_PERMISSIONS = arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE)

        @TargetApi(Build.VERSION_CODES.TIRAMISU)
        private val STORAGE_PERMISSIONS_TIRAMISU = arrayOf(Manifest.permission.READ_MEDIA_IMAGES, Manifest.permission.READ_MEDIA_VIDEO)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int, permissions: Array<String>, grantResults: IntArray
    ): Boolean {

        if (!isPermissionGranted(permissions)) {
            // when select deny.
            callback?.denied()
            return false
        }
        when (requestCode) {
            permissionRequestId -> {
                if (alreadyGranted()) {
                    callback?.granted()
                } else {
                    callback?.denied()
                }
            }
            else -> return false
        }
        return true
    }

    fun alreadyGranted(): Boolean {
        val permissions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            STORAGE_PERMISSIONS_TIRAMISU
        } else {
            STORAGE_PERMISSIONS
        }

        if (!isPermissionGranted(permissions)) {
            // Request authorization. User is not yet authorized.
            ActivityCompat.requestPermissions(activity, permissions, permissionRequestId)
            return false
        }
        // User already has authorization. Or below Android6.0
        return true
    }

    private fun isPermissionGranted(permissions: Array<String>) = permissions.none {
        ContextCompat.checkSelfPermission(
            activity, it
        ) != PackageManager.PERMISSION_GRANTED
    }

    interface Callback {
        fun granted()
        fun denied()
    }
}

