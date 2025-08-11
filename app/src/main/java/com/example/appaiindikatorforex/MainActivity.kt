package com.example.appaiindikatorforex

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.PixelFormat
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Base64
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.TextView
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity: FlutterActivity() {
    private val SCREEN_CAPTURE_CHANNEL = "screen_capture"
    private val OVERLAY_CHANNEL = "overlay_service"
    private val REQUEST_CODE = 1001

    private var mediaProjection: MediaProjection? = null
    private var mediaProjectionManager: MediaProjectionManager? = null
    private var imageReader: ImageReader? = null
    private var handler: Handler? = null
    private var overlayView: View? = null
    private var windowManager: WindowManager? = null

    private var captureResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SCREEN_CAPTURE_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "startCapture") {
                captureResult = result
                startScreenCapture()
            } else if (call.method == "stopCapture") {
                stopScreenCapture()
                result.success(null)
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, OVERLAY_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "showOverlay") {
                val signal = call.argument<String>("signal") ?: "-"
                showOverlay(signal)
                result.success(null)
            } else if (call.method == "hideOverlay") {
                hideOverlay()
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }

    // --- SCREEN CAPTURE ---
    private fun startScreenCapture() {
        mediaProjectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        val intent = mediaProjectionManager?.createScreenCaptureIntent()
        startActivityForResult(intent, REQUEST_CODE)
    }

    private fun stopScreenCapture() {
        mediaProjection?.stop()
        imageReader?.close()
        handler = null
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE && resultCode == Activity.RESULT_OK && data != null) {
            mediaProjection = mediaProjectionManager?.getMediaProjection(resultCode, data)
            val displayMetrics = resources.displayMetrics
            val width = displayMetrics.widthPixels
            val height = displayMetrics.heightPixels
            val density = displayMetrics.densityDpi

            imageReader = ImageReader.newInstance(width, height, PixelFormat.RGBA_8888, 2)
            handler = Handler(Looper.getMainLooper())

            mediaProjection?.createVirtualDisplay(
                "ScreenCapture",
                width, height, density,
                0,
                imageReader?.surface, null, handler
            )

            imageReader?.setOnImageAvailableListener({ reader ->
                val image = reader.acquireLatestImage()
                if (image != null) {
                    val planes = image.planes
                    val buffer = planes[0].buffer
                    val pixelStride = planes[0].pixelStride
                    val rowStride = planes[0].rowStride
                    val rowPadding = rowStride - pixelStride * width

                    val bitmap = Bitmap.createBitmap(
                        width + rowPadding / pixelStride,
                        height, Bitmap.Config.ARGB_8888
                    )
                    bitmap.copyPixelsFromBuffer(buffer)

                    // Crop to screen size
                    val cropped = Bitmap.createBitmap(bitmap, 0, 0, width, height)

                    // Convert to PNG byte array
                    val stream = ByteArrayOutputStream()
                    cropped.compress(Bitmap.CompressFormat.PNG, 100, stream)
                    val byteArray = stream.toByteArray()

                    // Convert to Base64 for Flutter
                    val base64String = Base64.encodeToString(byteArray, Base64.DEFAULT)
                    captureResult?.success(base64String)

                    image.close()
                }
            }, handler)
        }
    }

    // --- OVERLAY WINDOW ---
    private fun showOverlay(signal: String) {
        if (windowManager == null) {
            windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        }
        if (overlayView != null) {
            hideOverlay()
        }
        
        // Create overlay view programmatically since we don't have layout file yet
        overlayView = TextView(this).apply {
            text = signal.uppercase()
            textSize = 32f
            setTextColor(android.graphics.Color.WHITE)
            setBackgroundColor(android.graphics.Color.parseColor("#CC222222"))
            setPadding(32, 16, 32, 16)
            gravity = Gravity.CENTER
        }

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
            PixelFormat.TRANSLUCENT
        )
        params.gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
        params.x = 0
        params.y = 100

        windowManager!!.addView(overlayView, params)
    }

    private fun hideOverlay() {
        if (windowManager != null && overlayView != null) {
            windowManager!!.removeView(overlayView)
            overlayView = null
        }
    }
}
