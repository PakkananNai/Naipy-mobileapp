package com.example.code_explainer

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.pakkanannai.naipy/platform"
    private var pendingSaveResult: MethodChannel.Result? = null
    private var pendingSaveBytes: ByteArray? = null
    private var pendingSaveName: String = "untitled.py"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "saveDocument" -> {
                        val name = call.argument<String>("name") ?: "untitled.py"
                        val bytes = call.argument<ByteArray>("bytes")
                        if (bytes == null) {
                            result.error("invalid_bytes", "Missing file content", null)
                        } else {
                            pendingSaveResult = result
                            pendingSaveBytes = bytes
                            pendingSaveName = name
                            val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                                addCategory(Intent.CATEGORY_OPENABLE)
                                type = "text/x-python"
                                putExtra(Intent.EXTRA_TITLE, name)
                            }
                            startActivityForResult(intent, CREATE_DOCUMENT_REQUEST)
                        }
                    }
                    "writeDocument" -> {
                        val uriString = call.argument<String>("uri")
                        val bytes = call.argument<ByteArray>("bytes")
                        if (uriString == null || bytes == null) {
                            result.error("invalid_arguments", "Missing URI or content", null)
                        } else {
                            try {
                                contentResolver.openOutputStream(Uri.parse(uriString), "wt")!!.use {
                                    it.write(bytes)
                                }
                                result.success(uriString)
                            } catch (error: Exception) {
                                result.error("write_failed", error.message, null)
                            }
                        }
                    }
                    "openUrl" -> {
                        val url = call.argument<String>("url")
                        if (url == null) {
                            result.error("invalid_url", "Missing URL", null)
                        } else {
                            try {
                                startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
                                result.success(true)
                            } catch (error: Exception) {
                                result.error("open_url_failed", error.message, null)
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    @Deprecated("Deprecated in Android API")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != CREATE_DOCUMENT_REQUEST) return
        val result = pendingSaveResult ?: return
        pendingSaveResult = null
        val bytes = pendingSaveBytes
        pendingSaveBytes = null
        val uri = if (resultCode == Activity.RESULT_OK) data?.data else null
        if (uri == null || bytes == null) {
            result.success(null)
            return
        }
        try {
            contentResolver.openOutputStream(uri, "wt")!!.use { it.write(bytes) }
            result.success(uri.toString())
        } catch (error: Exception) {
            result.error("write_failed", error.message, null)
        }
    }

    companion object {
        private const val CREATE_DOCUMENT_REQUEST = 7041
    }
}
