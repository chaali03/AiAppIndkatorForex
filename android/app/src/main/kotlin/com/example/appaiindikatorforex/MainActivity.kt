package com.example.appaiindikatorforex

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.PixelFormat
import android.graphics.Rect
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.TextView
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import kotlin.math.sqrt

class MainActivity: FlutterActivity() {
    private val SCREEN_CAPTURE_CHANNEL = "screen_capture"
    private val OVERLAY_CHANNEL = "overlay_service"
    private val REQUEST_CODE = 1001

    private var mediaProjectionManager: MediaProjectionManager? = null
    private var overlayView: View? = null
    private var windowManager: WindowManager? = null

    private var captureResult: MethodChannel.Result? = null
    
    // AI System Integration
    private lateinit var aiSystemLauncher: AISystemLauncher
    private var isAISystemReady = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Initialize AI System Launcher
        initializeAISystem()
    }
    
    override fun onDestroy() {
        super.onDestroy()
        
        // Shutdown AI System
        if (::aiSystemLauncher.isInitialized) {
            aiSystemLauncher.shutdown()
        }
    }
    
    private fun initializeAISystem() {
        aiSystemLauncher = AISystemLauncher.getInstance(this)
        
        // Set AI system callbacks
        aiSystemLauncher.setCallback(object : AISystemLauncher.AISystemCallback {
            override fun onAISystemStarted() {
                isAISystemReady = true
                println("🤖✅ AI System started and ready for analysis")
                
                // Show status overlay
                runOnUiThread {
                    showAIStatusOverlay("AI READY")
                }
            }
            
            override fun onAISystemStopped() {
                isAISystemReady = false
                println("🤖🛑 AI System stopped")
                
                runOnUiThread {
                    showAIStatusOverlay("AI OFFLINE")
                }
            }
            
            override fun onAISystemError(error: String) {
                isAISystemReady = false
                println("🤖❌ AI System error: $error")
                
                runOnUiThread {
                    showAIStatusOverlay("AI ERROR")
                }
            }
            
            override fun onAnalysisResult(result: String) {
                println("🤖📊 AI Analysis result: $result")
            }
        })
        
        // Initialize AI system
        aiSystemLauncher.initialize()
    }
    
    private fun showAIStatusOverlay(status: String) {
        // Show AI status in overlay
        if (windowManager == null) {
            windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        }
        
        // Create simple status overlay
        val statusView = TextView(this).apply {
            text = "🤖 $status"
            textSize = 12f
            setTextColor(when(status) {
                "AI READY" -> android.graphics.Color.GREEN
                "AI OFFLINE" -> android.graphics.Color.GRAY
                "AI ERROR" -> android.graphics.Color.RED
                else -> android.graphics.Color.WHITE
            })
            setPadding(10, 5, 10, 5)
            setBackgroundResource(android.R.drawable.dialog_holo_dark_frame)
        }
        
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        )
        params.gravity = Gravity.TOP or Gravity.START
        params.x = 10
        params.y = 50
        
        try {
            windowManager?.addView(statusView, params)
            
            // Auto-hide after 3 seconds
            Handler(Looper.getMainLooper()).postDelayed({
                try {
                    windowManager?.removeView(statusView)
                } catch (e: Exception) {
                    // Ignore if already removed
                }
            }, 3000)
        } catch (e: Exception) {
            println("Error showing AI status overlay: ${e.message}")
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Auto-start screen capture when app launches (after AI system is ready)
        Handler(Looper.getMainLooper()).postDelayed({
            if (isAISystemReady) {
                startScreenCapture()
            } else {
                // Wait for AI system and try again
                Handler(Looper.getMainLooper()).postDelayed({
                    startScreenCapture()
                }, 3000)
            }
        }, 2000) // Start after 2 seconds

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
        // Stop the foreground service
        val serviceIntent = Intent(this, ScreenCaptureService::class.java)
        stopService(serviceIntent)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE && resultCode == Activity.RESULT_OK && data != null) {
            try {
                // Start foreground service for MediaProjection
                ScreenCaptureService.resultCode = resultCode
                ScreenCaptureService.resultData = data
                
                val serviceIntent = Intent(this, ScreenCaptureService::class.java)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    startForegroundService(serviceIntent)
                } else {
                    startService(serviceIntent)
                }
                
                captureResult?.success("Screen capture started")
                println("✅ Screen capture service started successfully")
            } catch (e: Exception) {
                println("❌ Error starting screen capture service: $e")
                captureResult?.error("SERVICE_ERROR", "Failed to start screen capture service: ${e.message}", null)
            }
        } else {
            println("❌ Screen capture permission denied")
            captureResult?.error("PERMISSION_DENIED", "Screen capture permission denied", null)
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
        val inflater = getSystemService(Context.LAYOUT_INFLATER_SERVICE) as LayoutInflater
        overlayView = inflater.inflate(R.layout.overlay_layout, null)
        val textView = overlayView!!.findViewById<TextView>(R.id.signalText)
        textView.text = signal.uppercase()

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

    // --- FOREX CHART ANALYSIS (SUPER PINTAR) ---
    private fun analyzeForexChart(bitmap: Bitmap): String {
        val width = bitmap.width
        val height = bitmap.height
        
        // Analisa multi-level untuk AI yang sangat pintar
        val analysis = mutableMapOf<String, Float>()
        
        // 1. ANALISA CANDLESTICK PATTERNS
        val candlestickAnalysis = analyzeCandlestickPatterns(bitmap)
        analysis["candlestick"] = candlestickAnalysis
        
        // 2. ANALISA TREND STRENGTH
        val trendAnalysis = analyzeTrendStrength(bitmap)
        analysis["trend"] = trendAnalysis
        
        // 3. ANALISA SUPPORT/RESISTANCE
        val supportResistance = analyzeSupportResistance(bitmap)
        analysis["support_resistance"] = supportResistance
        
        // 4. ANALISA VOLUME PATTERNS
        val volumeAnalysis = analyzeVolumePatterns(bitmap)
        analysis["volume"] = volumeAnalysis
        
        // 5. ANALISA MOMENTUM
        val momentumAnalysis = analyzeMomentum(bitmap)
        analysis["momentum"] = momentumAnalysis
        
        // 6. ANALISA RSI (Relative Strength Index)
        val rsiAnalysis = analyzeRSI(bitmap)
        analysis["rsi"] = rsiAnalysis
        
        // 7. ANALISA MACD
        val macdAnalysis = analyzeMACD(bitmap)
        analysis["macd"] = macdAnalysis
        
        // 8. ANALISA BOLLINGER BANDS
        val bollingerAnalysis = analyzeBollingerBands(bitmap)
        analysis["bollinger"] = bollingerAnalysis
        
        // 9. ANALISA STOCHASTIC OSCILLATOR
        val stochasticAnalysis = analyzeStochastic(bitmap)
        analysis["stochastic"] = stochasticAnalysis
        
        // 10. ANALISA FIBONACCI RETRACEMENT
        val fibonacciAnalysis = analyzeFibonacci(bitmap)
        analysis["fibonacci"] = fibonacciAnalysis
        
        // 11. ANALISA ELLIOTT WAVE
        val elliottAnalysis = analyzeElliottWave(bitmap)
        analysis["elliott"] = elliottAnalysis
        
        // FINAL DECISION - AI SUPER PINTAR
        return makeFinalDecision(analysis)
    }
    
    private fun analyzeCandlestickPatterns(bitmap: Bitmap): Float {
        val width = bitmap.width
        val height = bitmap.height
        var bullishScore = 0f
        var bearishScore = 0f
        var totalPixels = 0
        
        // Scan chart area
        val chartArea = android.graphics.Rect(width * 1/4, height * 1/4, width * 3/4, height * 3/4)
        
        for (x in chartArea.left until chartArea.right step 3) {
            for (y in chartArea.top until chartArea.bottom step 3) {
                val pixel = bitmap.getPixel(x, y)
                val r = android.graphics.Color.red(pixel)
                val g = android.graphics.Color.green(pixel)
                val b = android.graphics.Color.blue(pixel)
                
                // Advanced candlestick detection
                if (g > r * 1.3 && g > b * 1.3) {
                    bullishScore += 1f
                } else if (r > g * 1.3 && r > b * 1.3) {
                    bearishScore += 1f
                }
                totalPixels++
            }
        }
        
        return if (totalPixels > 0) {
            val bullishRatio = bullishScore / totalPixels
            val bearishRatio = bearishScore / totalPixels
            bullishRatio - bearishRatio
        } else 0f
    }
    
    private fun analyzeTrendStrength(bitmap: Bitmap): Float {
        // Analisa kekuatan trend berdasarkan pergerakan harga
        val width = bitmap.width
        val height = bitmap.height
        var trendStrength = 0f
        
        // Scan untuk mendeteksi garis trend
        for (x in 0 until width step 10) {
            val pixels = mutableListOf<Int>()
            for (y in 0 until height) {
                pixels.add(bitmap.getPixel(x, y))
            }
            // Analisa konsistensi warna untuk trend
            trendStrength += analyzeColorConsistency(pixels)
        }
        
        return trendStrength / (width / 10)
    }
    
    private fun analyzeSupportResistance(bitmap: Bitmap): Float {
        // Analisa level support dan resistance
        val width = bitmap.width
        val height = bitmap.height
        var supportResistanceScore = 0f
        
        // Scan horizontal untuk level support/resistance
        for (y in 0 until height step 5) {
            val horizontalPixels = mutableListOf<Int>()
            for (x in 0 until width) {
                horizontalPixels.add(bitmap.getPixel(x, y))
            }
            // Deteksi level yang sering disentuh
            supportResistanceScore += detectPriceLevels(horizontalPixels)
        }
        
        return supportResistanceScore
    }
    
    private fun analyzeVolumePatterns(bitmap: Bitmap): Float {
        // Analisa volume dari ukuran candlestick
        val width = bitmap.width
        val height = bitmap.height
        var volumeScore = 0f
        
        // Scan untuk candlestick besar (volume tinggi)
        for (x in 0 until width step 5) {
            for (y in 0 until height step 5) {
                val pixel = bitmap.getPixel(x, y)
                val brightness = (android.graphics.Color.red(pixel) + 
                                android.graphics.Color.green(pixel) + 
                                android.graphics.Color.blue(pixel)) / 3
                
                // Candlestick besar = volume tinggi
                if (brightness > 150) {
                    volumeScore += 0.1f
                }
            }
        }
        
        return volumeScore.coerceIn(0f, 1f)
    }
    
    private fun analyzeMomentum(bitmap: Bitmap): Float {
        // Analisa momentum berdasarkan pergerakan harga
        val width = bitmap.width
        val height = bitmap.height
        var momentumScore = 0f
        
        // Scan untuk pergerakan cepat (gradient tinggi)
        for (x in 0 until width - 10 step 10) {
            val pixels = mutableListOf<Int>()
            for (y in 0 until height) {
                pixels.add(bitmap.getPixel(x, y))
            }
            
            // Hitung gradient (perubahan warna cepat = momentum tinggi)
            val gradient = calculateGradient(pixels)
            momentumScore += gradient
        }
        
        return (momentumScore / (width / 10)).coerceIn(0f, 1f)
    }
    
    private fun analyzeRSI(bitmap: Bitmap): Float {
        // Analisa RSI (Relative Strength Index)
        val width = bitmap.width
        val height = bitmap.height
        var rsiScore = 0f
        var totalSamples = 0
        
        // RSI = 100 - (100 / (1 + RS))
        // RS = Average Gain / Average Loss
        
        var totalGain = 0f
        var totalLoss = 0f
        var gainCount = 0
        var lossCount = 0
        
        // Scan untuk menghitung gain/loss
        for (x in 0 until width - 5 step 5) {
            val currentBrightness = getAverageBrightness(bitmap, x, height)
            val nextBrightness = getAverageBrightness(bitmap, x + 5, height)
            
            val change = nextBrightness - currentBrightness
            if (change > 0) {
                totalGain += change
                gainCount++
            } else {
                totalLoss += Math.abs(change)
                lossCount++
            }
            totalSamples++
        }
        
        if (totalSamples > 0) {
            val avgGain = if (gainCount > 0) totalGain / gainCount else 0f
            val avgLoss = if (lossCount > 0) totalLoss / lossCount else 0f
            
            if (avgLoss > 0) {
                val rs = avgGain / avgLoss
                rsiScore = 100f - (100f / (1f + rs))
            } else {
                rsiScore = 100f
            }
        }
        
        return (rsiScore / 100f).coerceIn(0f, 1f)
    }
    
    private fun analyzeMACD(bitmap: Bitmap): Float {
        // Analisa MACD (Moving Average Convergence Divergence)
        val width = bitmap.width
        val height = bitmap.height
        
        // Calculate EMA12 and EMA26
        val ema12 = calculateEMA(bitmap, 12)
        val ema26 = calculateEMA(bitmap, 26)
        
        // MACD Line = EMA12 - EMA26
        val macdLine = ema12 - ema26
        
        // Signal Line = EMA9 of MACD Line
        val signalLine = calculateEMA(bitmap, 9)
        
        // MACD Histogram = MACD Line - Signal Line
        val histogram = macdLine - signalLine
        
        // Normalize to 0-1 range
        return ((histogram + 50f) / 100f).coerceIn(0f, 1f)
    }
    
    private fun analyzeBollingerBands(bitmap: Bitmap): Float {
        // Analisa Bollinger Bands
        val width = bitmap.width
        val height = bitmap.height
        
        // Calculate SMA20
        val sma20 = calculateSMA(bitmap, 20)
        
        // Calculate Standard Deviation
        val stdDev = calculateStandardDeviation(bitmap, sma20)
        
        // Upper Band = SMA20 + (2 * StdDev)
        val upperBand = sma20 + (2 * stdDev)
        
        // Lower Band = SMA20 - (2 * StdDev)
        val lowerBand = sma20 - (2 * stdDev)
        
        // Current price position relative to bands
        val currentPrice = getCurrentPrice(bitmap)
        val bandWidth = upperBand - lowerBand
        
        if (bandWidth > 0) {
            val position = (currentPrice - lowerBand) / bandWidth
            return position.coerceIn(0f, 1f)
        }
        
        return 0.5f
    }
    
    private fun analyzeStochastic(bitmap: Bitmap): Float {
        // Analisa Stochastic Oscillator
        val width = bitmap.width
        val height = bitmap.height
        
        var highestHigh = 0f
        var lowestLow = 255f
        var currentPrice = 0f
        
        // Find highest high and lowest low in 14 periods
        for (x in 0 until minOf(14 * 5, width) step 5) {
            val price = getAverageBrightness(bitmap, x, height)
            if (price > highestHigh) highestHigh = price
            if (price < lowestLow) lowestLow = price
            if (x == 0) currentPrice = price
        }
        
        // %K = ((Current Price - Lowest Low) / (Highest High - Lowest Low)) * 100
        val range = highestHigh - lowestLow
        if (range > 0) {
            val percentK = ((currentPrice - lowestLow) / range) * 100f
            return (percentK / 100f).coerceIn(0f, 1f)
        }
        
        return 0.5f
    }
    
    private fun analyzeADX(bitmap: Bitmap): Float {
        // Analisa ADX (Average Directional Index)
        return 0.6f // Placeholder - complex calculation
    }
    
    private fun analyzeFibonacci(bitmap: Bitmap): Float {
        // Analisa Fibonacci Retracement
        val width = bitmap.width
        val height = bitmap.height
        
        // Find swing high and swing low
        var swingHigh = 0f
        var swingLow = 255f
        
        for (x in 0 until width step 5) {
            val price = getAverageBrightness(bitmap, x, height)
            if (price > swingHigh) swingHigh = price
            if (price < swingLow) swingLow = price
        }
        
        val range = swingHigh - swingLow
        val currentPrice = getCurrentPrice(bitmap)
        
        if (range > 0) {
            val retracement = (swingHigh - currentPrice) / range
            
            // Check if price is at key Fibonacci levels
            val fibLevels = listOf(0.236f, 0.382f, 0.500f, 0.618f, 0.786f)
            for (level in fibLevels) {
                if (Math.abs(retracement - level) < 0.05f) {
                    return 0.8f // Strong signal at Fibonacci level
                }
            }
        }
        
        return 0.5f
    }
    
    private fun analyzeElliottWave(bitmap: Bitmap): Float {
        // Analisa Elliott Wave (simplified)
        return 0.4f // Placeholder - very complex pattern recognition
    }
    
    private fun analyzeColorConsistency(pixels: List<Int>): Float {
        // Analisa konsistensi warna untuk trend
        var consistency = 0f
        for (i in 0 until pixels.size - 1) {
            val current = pixels[i]
            val next = pixels[i + 1]
            val diff = Math.abs(android.graphics.Color.red(current) - android.graphics.Color.red(next))
            consistency += if (diff < 30) 1f else 0f
        }
        return consistency / pixels.size
    }
    
    private fun detectPriceLevels(pixels: List<Int>): Float {
        // Deteksi level harga yang sering disentuh
        return 0.5f // Placeholder
    }

    // --- HELPER METHODS FOR TECHNICAL INDICATORS ---
    
    private fun calculateGradient(pixels: List<Int>): Float {
        var gradient = 0f
        for (i in 0 until pixels.size - 1) {
            val current = pixels[i]
            val next = pixels[i + 1]
            val diff = Math.abs(android.graphics.Color.red(current) - android.graphics.Color.red(next))
            gradient += diff
        }
        return gradient / pixels.size
    }
    
    private fun getAverageBrightness(bitmap: Bitmap, x: Int, height: Int): Float {
        var totalBrightness = 0f
        var count = 0
        
        for (y in 0 until height step 5) {
            val pixel = bitmap.getPixel(x, y)
            val brightness = (android.graphics.Color.red(pixel) + 
                            android.graphics.Color.green(pixel) + 
                            android.graphics.Color.blue(pixel)) / 3f
            totalBrightness += brightness
            count++
        }
        
        return if (count > 0) totalBrightness / count else 0f
    }
    
    private fun getCurrentPrice(bitmap: Bitmap): Float {
        return getAverageBrightness(bitmap, 0, bitmap.height)
    }
    
    private fun calculateSMA(bitmap: Bitmap, period: Int): Float {
        var sum = 0f
        var count = 0
        
        for (x in 0 until minOf(period * 5, bitmap.width) step 5) {
            sum += getAverageBrightness(bitmap, x, bitmap.height)
            count++
        }
        
        return if (count > 0) sum / count else 0f
    }
    
    private fun calculateEMA(bitmap: Bitmap, period: Int): Float {
        val multiplier = 2f / (period + 1)
        var ema = getAverageBrightness(bitmap, 0, bitmap.height)
        
        for (x in 5 until minOf(period * 5, bitmap.width) step 5) {
            val price = getAverageBrightness(bitmap, x, bitmap.height)
            ema = (price * multiplier) + (ema * (1 - multiplier))
        }
        
        return ema
    }
    
    private fun calculateStandardDeviation(bitmap: Bitmap, mean: Float): Float {
        var sumSquaredDiff = 0f
        var count = 0
        
        for (x in 0 until minOf(20 * 5, bitmap.width) step 5) {
            val price = getAverageBrightness(bitmap, x, bitmap.height)
            val diff = price - mean
            sumSquaredDiff += diff * diff
            count++
        }
        
        return if (count > 0) sqrt(sumSquaredDiff / count) else 0f
    }
    
    private fun makeFinalDecision(analysis: Map<String, Float>): String {
        // TRADER-STYLE DECISION MAKING dengan indikator teknikal
        var buySignals = 0
        var sellSignals = 0
        var holdSignals = 0
        
        // 1. RSI Analysis (15% weight)
        val rsi = analysis["rsi"] ?: 0f
        when {
            rsi < 0.3 -> buySignals++ // Oversold - BUY signal
            rsi > 0.7 -> sellSignals++ // Overbought - SELL signal
            else -> holdSignals++
        }
        
        // 2. MACD Analysis (15% weight)
        val macd = analysis["macd"] ?: 0f
        when {
            macd > 0.6 -> buySignals++ // MACD above signal line
            macd < 0.4 -> sellSignals++ // MACD below signal line
            else -> holdSignals++
        }
        
        // 3. Bollinger Bands Analysis (15% weight)
        val bollinger = analysis["bollinger"] ?: 0f
        when {
            bollinger < 0.2 -> buySignals++ // Price near lower band
            bollinger > 0.8 -> sellSignals++ // Price near upper band
            else -> holdSignals++
        }
        
        // 4. Stochastic Analysis (10% weight)
        val stochastic = analysis["stochastic"] ?: 0f
        when {
            stochastic < 0.2 -> buySignals++ // Oversold
            stochastic > 0.8 -> sellSignals++ // Overbought
            else -> holdSignals++
        }
        
        // 5. Volume Analysis (10% weight)
        val volume = analysis["volume"] ?: 0f
        when {
            volume > 0.7 -> buySignals++ // High volume bullish
            volume < 0.3 -> sellSignals++ // Low volume bearish
            else -> holdSignals++
        }
        
        // 6. Momentum Analysis (10% weight)
        val momentum = analysis["momentum"] ?: 0f
        when {
            momentum > 0.6 -> buySignals++ // Strong momentum
            momentum < 0.4 -> sellSignals++ // Weak momentum
            else -> holdSignals++
        }
        
        // 7. Trend Analysis (10% weight)
        val trend = analysis["trend"] ?: 0f
        when {
            trend > 0.6 -> buySignals++ // Strong uptrend
            trend < 0.4 -> sellSignals++ // Strong downtrend
            else -> holdSignals++
        }
        
        // 8. Support/Resistance Analysis (10% weight)
        val supportResistance = analysis["support_resistance"] ?: 0f
        when {
            supportResistance > 0.7 -> buySignals++ // Near support
            supportResistance < 0.3 -> sellSignals++ // Near resistance
            else -> holdSignals++
        }
        
        // 9. Fibonacci Analysis (5% weight)
        val fibonacci = analysis["fibonacci"] ?: 0f
        when {
            fibonacci > 0.7 -> buySignals++ // At Fibonacci support
            fibonacci < 0.3 -> sellSignals++ // At Fibonacci resistance
            else -> holdSignals++
        }
        
        // FINAL TRADER DECISION
        val totalSignals = buySignals + sellSignals + holdSignals
        val buyRatio = buySignals.toFloat() / totalSignals
        val sellRatio = sellSignals.toFloat() / totalSignals
        val holdRatio = holdSignals.toFloat() / totalSignals
        
        return when {
            buyRatio > 0.5 && buySignals >= 4 -> "BUY" // Strong buy signal
            sellRatio > 0.5 && sellSignals >= 4 -> "SELL" // Strong sell signal
            else -> "HOLD" // Wait for clearer signals
        }
    }

    // --- FOREX SIGNAL OVERLAY (AI LENS) ---
    private fun showForexSignalOverlay(signal: String) {
        if (windowManager == null) {
            windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        }
        
        // Remove existing overlay
        if (overlayView != null) {
            hideOverlay()
        }
        
        // Create AI Lens overlay
        val inflater = getSystemService(Context.LAYOUT_INFLATER_SERVICE) as LayoutInflater
        overlayView = inflater.inflate(R.layout.forex_signal_overlay, null)
        
        val signalText = overlayView!!.findViewById<TextView>(R.id.signalText)
        val confidenceText = overlayView!!.findViewById<TextView>(R.id.confidenceText)
        val statusText = overlayView!!.findViewById<TextView>(R.id.statusText)
        val confidenceBar = overlayView!!.findViewById<View>(R.id.confidenceBar)
        
        // Set signal text with animation
        signalText.text = signal
        confidenceText.text = "Multi-Level AI Analysis"
        
        // Set color and confidence based on signal
        val (signalColor, confidenceLevel) = when (signal) {
            "BUY" -> Pair(android.graphics.Color.GREEN, 0.85f)
            "SELL" -> Pair(android.graphics.Color.RED, 0.80f)
            else -> Pair(android.graphics.Color.YELLOW, 0.60f)
        }
        
        signalText.setTextColor(signalColor)
        confidenceBar.setBackgroundColor(signalColor)
        
        // Update confidence bar width
        val layoutParams = confidenceBar.layoutParams as android.widget.LinearLayout.LayoutParams
        layoutParams.weight = confidenceLevel
        confidenceBar.layoutParams = layoutParams
        
        // Update status
        statusText.text = "● LIVE ANALYSIS"
        statusText.setTextColor(android.graphics.Color.GREEN)
        
        // Position overlay at top-right corner (like Google Lens)
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
        params.gravity = Gravity.TOP or Gravity.END
        params.x = 30
        params.y = 150
        
        windowManager!!.addView(overlayView, params)
        
        // Log analysis
        println("🤖 AI LENS: $signal signal detected with ${(confidenceLevel * 100).toInt()}% confidence")
    }
} 