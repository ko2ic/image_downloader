package com.ko2ic.imagedownloader

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.PluginRegistry

class ImageDownloaderPermissionListener(private val activity: Activity) :
    PluginRegistry.RequestPermissionsResultListener {

    private val permissionRequestId: Int = 2578166

    var callback: Callback? = null

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<String>,
        grantResults: IntArray
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
        val permissions = arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE)

        if (!isPermissionGranted(permissions)) {
            // Request authorization. User is not yet authorized.
            ActivityCompat.requestPermissions(activity, permissions, permissionRequestId)
            return false
        }
        // User already has authorization. Or below Android6.0
        return true
    }

    private fun isPermissionGranted(permissions: Array<String>) =
        permissions.none { ContextCompat.checkSelfPermission(activity, it) != PackageManager.PERMISSION_GRANTED }

    interface Callback {
        fun granted()
        fun denied()
    }
}

