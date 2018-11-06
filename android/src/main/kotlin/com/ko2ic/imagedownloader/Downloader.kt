package com.ko2ic.imagedownloader

import android.app.DownloadManager
import android.app.DownloadManager.*
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.database.Cursor


class Downloader(private val context: Context, private val request: DownloadManager.Request) {

    private val manager: DownloadManager =
        context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager

    private var receiver: BroadcastReceiver? = null

    private var downloadId: Long? = null

    fun execute(
        onNext: (DownloadStatus) -> Unit,
        onError: (DownloadFailedException) -> Unit,
        onComplete: () -> Unit
    ): Unit {
        receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                intent ?: return
                if (DownloadManager.ACTION_DOWNLOAD_COMPLETE.equals(intent.action)) {
                    val id = intent.getLongExtra(DownloadManager.EXTRA_DOWNLOAD_ID, -1)
                    resolveDownloadStatus(id, onNext, onError, onComplete)
                }
            }
        }
        context.registerReceiver(receiver, IntentFilter(DownloadManager.ACTION_DOWNLOAD_COMPLETE))
        downloadId = manager.enqueue(request)
    }

    private fun cancel() {
        if (downloadId != null) {
            manager.remove(downloadId!!)
        }

        receiver?.let {
            context.unregisterReceiver(it)
        }
    }

    private fun resolveDownloadStatus(
        id: Long,
        onNext: (DownloadStatus) -> Unit,
        onError: (DownloadFailedException) -> Unit,
        onComplete: () -> Unit
    ) {
        val query = DownloadManager.Query().apply {
            setFilterById(id)
        }
        val cursor = manager.query(query)
        if (cursor.moveToFirst()) {
            val status = cursor.getInt(cursor.getColumnIndex(DownloadManager.COLUMN_STATUS))
            val reason = cursor.getInt(cursor.getColumnIndex(DownloadManager.COLUMN_REASON))
            val requestResult: RequestResult = createRequestResult(id, cursor)
            when (status) {
                DownloadManager.STATUS_FAILED -> {
                    val failedReason = when (reason) {
                        ERROR_CANNOT_RESUME -> "ERROR_CANNOT_RESUME"
                        ERROR_DEVICE_NOT_FOUND -> "ERROR_DEVICE_NOT_FOUND"
                        ERROR_FILE_ALREADY_EXISTS -> "ERROR_FILE_ALREADY_EXISTS"
                        ERROR_FILE_ERROR -> "ERROR_FILE_ERROR"
                        ERROR_HTTP_DATA_ERROR -> "ERROR_HTTP_DATA_ERROR"
                        ERROR_INSUFFICIENT_SPACE -> "ERROR_INSUFFICIENT_SPACE"
                        ERROR_TOO_MANY_REDIRECTS -> "ERROR_TOO_MANY_REDIRECTS"
                        ERROR_UNHANDLED_HTTP_CODE -> "ERROR_UNHANDLED_HTTP_CODE"
                        ERROR_UNKNOWN -> "ERROR_UNKNOWN"
                        else -> "ERROR_UNKNOWN"
                    }
                    onNext(DownloadStatus.Failed(requestResult, failedReason))
                    onError(DownloadFailedException(failedReason))
                }
                DownloadManager.STATUS_PAUSED -> {
                    val pausedReason = when (reason) {
                        PAUSED_QUEUED_FOR_WIFI -> "PAUSED_QUEUED_FOR_WIFI"
                        PAUSED_UNKNOWN -> "PAUSED_UNKNOWN"
                        PAUSED_WAITING_FOR_NETWORK -> "PAUSED_WAITING_FOR_NETWORK"
                        PAUSED_WAITING_TO_RETRY -> "PAUSED_WAITING_TO_RETRY"
                        else -> "PAUSED_UNKNOWN"
                    }
                    onNext(DownloadStatus.Paused(requestResult, pausedReason))
                }
                DownloadManager.STATUS_PENDING -> {
                    onNext(DownloadStatus.Pending(requestResult))
                }
                DownloadManager.STATUS_RUNNING -> {
                    onNext(DownloadStatus.Running(requestResult))
                }
                DownloadManager.STATUS_SUCCESSFUL -> {
                    onNext(DownloadStatus.Successful(requestResult))
                    onComplete()
                    cancel()
                }
            }
        }
        cursor.close()
    }

    fun createRequestResult(id: Long, cursor: Cursor): RequestResult =
        RequestResult(
            id = id,
            remoteUri = cursor.getString(cursor.getColumnIndex(COLUMN_URI)),
            localUri = cursor.getString(cursor.getColumnIndex(COLUMN_LOCAL_URI)),
            mediaType = cursor.getString(cursor.getColumnIndex(COLUMN_MEDIA_TYPE)),
            totalSize = cursor.getInt(cursor.getColumnIndex(COLUMN_TOTAL_SIZE_BYTES)),
            title = cursor.getString(cursor.getColumnIndex(COLUMN_TITLE)),
            description = cursor.getString(cursor.getColumnIndex(COLUMN_DESCRIPTION))
        )

    sealed class DownloadStatus(result: RequestResult) {
        class Successful(result: RequestResult) : DownloadStatus(result)
        class Running(result: RequestResult) : DownloadStatus(result)
        class Pending(result: RequestResult) : DownloadStatus(result)
        class Paused(result: RequestResult, val reason: String) : DownloadStatus(result)
        class Failed(result: RequestResult, val reason: String) : DownloadStatus(result)
    }

    class DownloadFailedException(message: String) : Throwable(message)
}

data class RequestResult(
    val id: Long,
    val remoteUri: String,
    val localUri: String?,
    val mediaType: String?,
    val totalSize: Int,
    val title: String?,
    val description: String?
)