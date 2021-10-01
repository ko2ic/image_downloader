package com.ko2ic.imagedownloader

import android.app.DownloadManager
import android.app.DownloadManager.*
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.database.Cursor
import java.math.BigDecimal
import java.math.RoundingMode


class Downloader(private val context: Context, private val request: Request) {

    private val manager: DownloadManager =
        context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager

    private var receiver: BroadcastReceiver? = null

    private var downloadId: Long? = null

    fun execute(
        onNext: (DownloadStatus) -> Unit,
        onError: (DownloadFailedException) -> Unit,
        onComplete: () -> Unit
    ) {
        receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                intent ?: return
                if (ACTION_DOWNLOAD_COMPLETE == intent.action) {
                    val id = intent.getLongExtra(EXTRA_DOWNLOAD_ID, -1)
                    resolveDownloadStatus(id, onNext, onError, onComplete)
                }
            }
        }
        context.registerReceiver(receiver, IntentFilter(ACTION_DOWNLOAD_COMPLETE))
        downloadId = manager.enqueue(request)
        downloadId?.let { nullableDownloadId ->
            Thread {
                var downloading = true

                while (downloading) {

                    val q = Query()
                    q.setFilterById(nullableDownloadId)

                    val cursor = manager.query(q)
                    cursor.moveToFirst()

                    if (cursor.count == 0) {
                        cursor.close()
                        break
                    }

                    val downloadedBytes = cursor.getInt(
                        cursor.getColumnIndex(COLUMN_BYTES_DOWNLOADED_SO_FAR)
                    )
                    val totalBytes = cursor.getInt(cursor.getColumnIndex(COLUMN_TOTAL_SIZE_BYTES))

                    when (cursor.getInt(cursor.getColumnIndex(COLUMN_STATUS))) {
                        STATUS_SUCCESSFUL -> downloading = false
                        STATUS_FAILED -> downloading = false
                    }

                    if (totalBytes == 0) {
                        break
                    }

                    val progress = BigDecimal(downloadedBytes).divide(
                        BigDecimal(totalBytes), 2, RoundingMode.DOWN
                    ).multiply(
                        BigDecimal(100)
                    ).setScale(0, RoundingMode.DOWN)

                    onNext(
                        DownloadStatus.Running(
                            createRequestResult(nullableDownloadId, cursor),
                            progress.toInt()
                        )
                    )

                    cursor.close()
                    Thread.sleep(200)
                }
            }.start()
        }
    }

    fun cancel() {
        downloadId?.let {
            manager.remove(it)
        }

        receiver?.let {
            context.unregisterReceiver(it)
            receiver = null
        }
    }

    private fun resolveDownloadStatus(
        id: Long,
        onNext: (DownloadStatus) -> Unit,
        onError: (DownloadFailedException) -> Unit,
        onComplete: () -> Unit
    ) {
        val query = Query().apply {
            setFilterById(id)
        }
        val cursor = manager.query(query)
        if (cursor.moveToFirst()) {
            val status = cursor.getInt(cursor.getColumnIndex(COLUMN_STATUS))
            val reason = cursor.getInt(cursor.getColumnIndex(COLUMN_REASON))
            val requestResult: RequestResult = createRequestResult(id, cursor)
            when (status) {
                STATUS_FAILED -> {
                    val failedReason = when (reason) {
                        ERROR_CANNOT_RESUME -> Pair(
                            "ERROR_CANNOT_RESUME",
                            "Some possibly transient error occurred but we can't resume the download."
                        )
                        ERROR_DEVICE_NOT_FOUND -> Pair(
                            "ERROR_DEVICE_NOT_FOUND",
                            "No external storage device was found."
                        )
                        ERROR_FILE_ALREADY_EXISTS -> Pair(
                            "ERROR_FILE_ALREADY_EXISTS",
                            "The requested destination file already exists (the download manager will not overwrite an existing file)."
                        )
                        ERROR_FILE_ERROR -> Pair(
                            "ERROR_FILE_ERROR",
                            "A storage issue arises which doesn't fit under any other error code."
                        )
                        ERROR_HTTP_DATA_ERROR -> Pair(
                            "ERROR_HTTP_DATA_ERROR",
                            "An error receiving or processing data occurred at the HTTP level."
                        )
                        ERROR_INSUFFICIENT_SPACE -> Pair(
                            "ERROR_INSUFFICIENT_SPACE",
                            "There was insufficient storage space."
                        )
                        ERROR_TOO_MANY_REDIRECTS -> Pair(
                            "ERROR_TOO_MANY_REDIRECTS",
                            "There were too many redirects."
                        )
                        ERROR_UNHANDLED_HTTP_CODE -> Pair(
                            "ERROR_UNHANDLED_HTTP_CODE",
                            "An HTTP code was received that download manager can't handle."
                        )
                        ERROR_UNKNOWN -> Pair(
                            "ERROR_UNKNOWN",
                            "The download has completed with an error that doesn't fit under any other error code."
                        )
                        in 400..599 -> Pair(reason.toString(), "HTTP status code error.")
                        else -> Pair(reason.toString(), "Unknown.")
                    }
                    onNext(DownloadStatus.Failed(requestResult, failedReason.first))
                    cancel()
                    onError(DownloadFailedException(failedReason.first, failedReason.second))
                }
                STATUS_PAUSED -> {
                    val pausedReason = when (reason) {
                        PAUSED_QUEUED_FOR_WIFI -> "PAUSED_QUEUED_FOR_WIFI"
                        PAUSED_UNKNOWN -> "PAUSED_UNKNOWN"
                        PAUSED_WAITING_FOR_NETWORK -> "PAUSED_WAITING_FOR_NETWORK"
                        PAUSED_WAITING_TO_RETRY -> "PAUSED_WAITING_TO_RETRY"
                        else -> "PAUSED_UNKNOWN"
                    }
                    onNext(DownloadStatus.Paused(requestResult, pausedReason))
                }
                STATUS_PENDING -> {
                    onNext(DownloadStatus.Pending(requestResult))
                }
                STATUS_SUCCESSFUL -> {
                    onNext(DownloadStatus.Successful(requestResult))
                    onComplete()
                    receiver?.let {
                        context.unregisterReceiver(it)
                    }
                }
            }
        }
        cursor.close()
    }

    private fun createRequestResult(id: Long, cursor: Cursor): RequestResult =
        RequestResult(
            id = id,
            remoteUri = cursor.getString(cursor.getColumnIndex(COLUMN_URI)),
            localUri = cursor.getString(cursor.getColumnIndex(COLUMN_LOCAL_URI)),
            mediaType = cursor.getString(cursor.getColumnIndex(COLUMN_MEDIA_TYPE)),
            totalSize = cursor.getInt(cursor.getColumnIndex(COLUMN_TOTAL_SIZE_BYTES)),
            title = cursor.getString(cursor.getColumnIndex(COLUMN_TITLE)),
            description = cursor.getString(cursor.getColumnIndex(COLUMN_DESCRIPTION))
        )

    sealed class DownloadStatus(val result: RequestResult) {
        class Successful(result: RequestResult) : DownloadStatus(result)
        class Running(result: RequestResult, val progress: Int) : DownloadStatus(result)
        class Pending(result: RequestResult) : DownloadStatus(result)
        class Paused(result: RequestResult, val reason: String) : DownloadStatus(result)
        class Failed(result: RequestResult, val reason: String) : DownloadStatus(result)
    }

    class DownloadFailedException(val code: String, message: String) : Throwable(message)
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