package com.example.appaiindikatorforex

import android.content.Context
import android.os.AsyncTask
import android.os.Handler
import android.os.Looper
import android.util.Log
import kotlinx.coroutines.*
import org.json.JSONObject
import java.io.*
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors

/**
 * ADVANCED CRYPTO AI SYSTEM LAUNCHER
 * Automatically manages Python AI system startup and health monitoring from Android
 * 
 * Features:
 * - Automatic Python environment detection and setup
 * - AI server startup and health monitoring  
 * - HTTP API communication with Python backend
 * - Error handling and recovery
 * - Background service management
 */
class AISystemLauncher(private val context: Context) {
    
    companion object {
        private const val TAG = "AISystemLauncher"
        // Use 10.0.2.2 for Android Emulator to reach host machine's localhost
        // For physical device, replace with your PC IPv4 (e.g., 192.168.x.x)
        private const val AI_SERVER_HOST = "10.0.2.2"
        private const val AI_SERVER_PORT = 8888
        private const val HEALTH_CHECK_INTERVAL = 5000L // 5 seconds
        private const val STARTUP_TIMEOUT = 60000L // 60 seconds
        
        @Volatile
        private var instance: AISystemLauncher? = null
        
        fun getInstance(context: Context): AISystemLauncher {
            return instance ?: synchronized(this) {
                instance ?: AISystemLauncher(context.applicationContext).also { instance = it }
            }
        }
    }
    
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private val handler = Handler(Looper.getMainLooper())
    private val executor = Executors.newCachedThreadPool()
    
    @Volatile
    private var isServerRunning = false
    @Volatile
    private var isStarting = false
    @Volatile
    private var healthCheckJob: Job? = null
    
    private var serverProcess: Process? = null
    private var aiSystemCallback: AISystemCallback? = null
    
    /**
     * Callback interface for AI system events
     */
    interface AISystemCallback {
        fun onAISystemStarted()
        fun onAISystemStopped()
        fun onAISystemError(error: String)
        fun onAnalysisResult(result: String)
    }
    
    /**
     * Set callback for AI system events
     */
    fun setCallback(callback: AISystemCallback) {
        this.aiSystemCallback = callback
    }
    
    /**
     * Initialize and start the AI system
     */
    fun initialize() {
        if (isStarting || isServerRunning) {
            log("AI system already running or starting")
            return
        }
        
        log("🚀 Initializing Advanced Crypto AI System...")
        isStarting = true
        
        scope.launch {
            try {
                // Check if AI server is already running
                if (checkServerHealth()) {
                    log("AI server already running")
                    onServerStarted()
                    return@launch
                }
                
                // Start the AI system
                val success = startAISystem()
                if (success) {
                    // Wait for server to start
                    val started = waitForServerStartup()
                    if (started) {
                        onServerStarted()
                    } else {
                        onServerError("Server startup timeout")
                    }
                } else {
                    onServerError("Failed to start AI system")
                }
                
            } catch (e: Exception) {
                log("Error initializing AI system: ${e.message}")
                onServerError("Initialization error: ${e.message}")
            } finally {
                isStarting = false
            }
        }
    }
    
    /**
     * Start the AI system process
     */
    private suspend fun startAISystem(): Boolean = withContext(Dispatchers.IO) {
        try {
            log("Starting AI system process...")
            
            // Get the AI directory path
            val aiDir = getAIDirectory()
            if (!aiDir.exists()) {
                log("AI directory not found: ${aiDir.absolutePath}")
                return@withContext false
            }
            
            // Choose the appropriate startup script
            val startupScript = when {
                System.getProperty("os.name").lowercase().contains("windows") -> {
                    File(aiDir, "start_ai_system.bat")
                }
                else -> {
                    File(aiDir, "start_ai_system.sh")
                }
            }
            
            if (!startupScript.exists()) {
                // Fallback to Python script
                val pythonScript = File(aiDir, "android_integration.py")
                if (!pythonScript.exists()) {
                    log("No startup scripts found")
                    return@withContext false
                }
                
                // Try to start with Python
                return@withContext startWithPython(pythonScript)
            }
            
            // Start with batch/shell script
            val processBuilder = ProcessBuilder().apply {
                command(startupScript.absolutePath)
                directory(aiDir)
                redirectErrorStream(true)
            }
            
            serverProcess = processBuilder.start()
            
            log("AI system process started successfully")
            return@withContext true
            
        } catch (e: Exception) {
            log("Error starting AI system: ${e.message}")
            return@withContext false
        }
    }
    
    /**
     * Start AI system with Python directly
     */
    private fun startWithPython(scriptFile: File): Boolean {
        return try {
            val processBuilder = ProcessBuilder().apply {
                command("python", scriptFile.absolutePath)
                directory(scriptFile.parentFile)
                redirectErrorStream(true)
            }
            
            serverProcess = processBuilder.start()
            log("Started AI system with Python")
            true
            
        } catch (e: Exception) {
            log("Failed to start with Python: ${e.message}")
            
            // Try alternative Python commands
            for (pythonCmd in listOf("python3", "py")) {
                try {
                    val processBuilder = ProcessBuilder().apply {
                        command(pythonCmd, scriptFile.absolutePath)
                        directory(scriptFile.parentFile)
                        redirectErrorStream(true)
                    }
                    
                    serverProcess = processBuilder.start()
                    log("Started AI system with $pythonCmd")
                    return true
                    
                } catch (ex: Exception) {
                    log("Failed to start with $pythonCmd: ${ex.message}")
                }
            }
            
            false
        }
    }
    
    /**
     * Get the AI directory based on the app's location
     */
    private fun getAIDirectory(): File {
        // Try multiple possible locations
        val possiblePaths = listOf(
            // Relative to app directory
            File(context.filesDir.parent, "../../ai"),
            File(context.filesDir.parent, "../../../ai"), 
            // Absolute paths (if installed in common locations)
            File("/data/data/${context.packageName}/ai"),
            File("/sdcard/AppAiIndikatorForex/ai"),
            File(System.getProperty("user.home"), "AppAiIndikatorForex/ai")
        )
        
        for (path in possiblePaths) {
            try {
                val canonicalPath = path.canonicalFile
                if (canonicalPath.exists() && canonicalPath.isDirectory) {
                    log("Found AI directory: ${canonicalPath.absolutePath}")
                    return canonicalPath
                }
            } catch (e: Exception) {
                // Continue to next path
            }
        }
        
        // Default fallback
        return File(context.filesDir, "ai")
    }
    
    /**
     * Wait for server to start up
     */
    private suspend fun waitForServerStartup(): Boolean {
        val startTime = System.currentTimeMillis()
        
        while (System.currentTimeMillis() - startTime < STARTUP_TIMEOUT) {
            if (checkServerHealth()) {
                return true
            }
            delay(1000) // Wait 1 second between checks
        }
        
        return false
    }
    
    /**
     * Check if AI server is healthy
     */
    private suspend fun checkServerHealth(): Boolean = withContext(Dispatchers.IO) {
        return@withContext try {
            val url = URL("http://$AI_SERVER_HOST:$AI_SERVER_PORT/health")
            val connection = url.openConnection() as HttpURLConnection
            connection.requestMethod = "GET"
            connection.connectTimeout = 5000
            connection.readTimeout = 5000
            
            val responseCode = connection.responseCode
            connection.disconnect()
            
            responseCode == 200
            
        } catch (e: Exception) {
            false
        }
    }
    
    /**
     * Start health monitoring
     */
    private fun startHealthMonitoring() {
        healthCheckJob?.cancel()
        healthCheckJob = scope.launch {
            while (isActive && isServerRunning) {
                try {
                    if (!checkServerHealth()) {
                        log("Health check failed - server appears to be down")
                        onServerStopped()
                        break
                    }
                    delay(HEALTH_CHECK_INTERVAL)
                } catch (e: Exception) {
                    log("Health check error: ${e.message}")
                    delay(HEALTH_CHECK_INTERVAL)
                }
            }
        }
    }
    
    /**
     * Send analysis request to AI server
     */
    fun analyzeData(data: String, callback: (String?) -> Unit) {
        if (!isServerRunning) {
            callback(null)
            return
        }
        
        scope.launch {
            try {
                val result = sendAnalysisRequest(data)
                withContext(Dispatchers.Main) {
                    callback(result)
                }
            } catch (e: Exception) {
                log("Analysis request failed: ${e.message}")
                withContext(Dispatchers.Main) {
                    callback(null)
                }
            }
        }
    }
    
    /**
     * Send image analysis request
     */
    fun analyzeImage(imageBase64: String, metadata: String, callback: (String?) -> Unit) {
        if (!isServerRunning) {
            callback(null)
            return
        }
        
        scope.launch {
            try {
                val result = sendImageAnalysisRequest(imageBase64, metadata)
                withContext(Dispatchers.Main) {
                    callback(result)
                }
            } catch (e: Exception) {
                log("Image analysis request failed: ${e.message}")
                withContext(Dispatchers.Main) {
                    callback(null)
                }
            }
        }
    }
    
    /**
     * Send HTTP request to AI server for analysis
     */
    private suspend fun sendAnalysisRequest(data: String): String? = withContext(Dispatchers.IO) {
        return@withContext try {
            val url = URL("http://$AI_SERVER_HOST:$AI_SERVER_PORT/analyze")
            val connection = url.openConnection() as HttpURLConnection
            
            connection.requestMethod = "POST"
            connection.setRequestProperty("Content-Type", "application/json")
            connection.setRequestProperty("Accept", "application/json")
            connection.doOutput = true
            connection.connectTimeout = 30000
            connection.readTimeout = 30000
            
            // Send data
            connection.outputStream.use { os ->
                os.write(data.toByteArray())
            }
            
            // Read response
            val responseCode = connection.responseCode
            if (responseCode == 200) {
                connection.inputStream.use { inputStream ->
                    inputStream.reader().readText()
                }
            } else {
                log("Analysis request failed with code: $responseCode")
                null
            }
            
        } catch (e: Exception) {
            log("Analysis request error: ${e.message}")
            null
        }
    }
    
    /**
     * Send HTTP request for image analysis
     */
    private suspend fun sendImageAnalysisRequest(imageBase64: String, metadata: String): String? = withContext(Dispatchers.IO) {
        return@withContext try {
            val url = URL("http://$AI_SERVER_HOST:$AI_SERVER_PORT/analyze_image")
            val connection = url.openConnection() as HttpURLConnection
            
            connection.requestMethod = "POST"
            connection.setRequestProperty("Content-Type", "application/json")
            connection.setRequestProperty("Accept", "application/json")
            connection.doOutput = true
            connection.connectTimeout = 60000  // Longer timeout for images
            connection.readTimeout = 60000
            
            // Prepare payload
            val payload = JSONObject().apply {
                put("image", imageBase64)
                if (metadata.isNotEmpty()) {
                    put("metadata", JSONObject(metadata))
                }
            }
            
            // Send data
            connection.outputStream.use { os ->
                os.write(payload.toString().toByteArray())
            }
            
            // Read response
            val responseCode = connection.responseCode
            if (responseCode == 200) {
                connection.inputStream.use { inputStream ->
                    inputStream.reader().readText()
                }
            } else {
                log("Image analysis request failed with code: $responseCode")
                null
            }
            
        } catch (e: Exception) {
            log("Image analysis request error: ${e.message}")
            null
        }
    }
    
    /**
     * Stop the AI system
     */
    fun shutdown() {
        log("🛑 Shutting down AI system...")
        
        isServerRunning = false
        healthCheckJob?.cancel()
        
        serverProcess?.let { process ->
            try {
                process.destroyForcibly()
                serverProcess = null
                log("AI system process terminated")
            } catch (e: Exception) {
                log("Error terminating process: ${e.message}")
            }
        }
        
        scope.cancel()
    }
    
    /**
     * Called when server starts successfully
     */
    private fun onServerStarted() {
        isServerRunning = true
        isStarting = false
        startHealthMonitoring()
        
        handler.post {
            log("✅ AI system started successfully")
            aiSystemCallback?.onAISystemStarted()
        }
    }
    
    /**
     * Called when server stops
     */
    private fun onServerStopped() {
        isServerRunning = false
        healthCheckJob?.cancel()
        
        handler.post {
            log("🛑 AI system stopped")
            aiSystemCallback?.onAISystemStopped()
        }
    }
    
    /**
     * Called when server error occurs
     */
    private fun onServerError(error: String) {
        isServerRunning = false
        isStarting = false
        healthCheckJob?.cancel()
        
        handler.post {
            log("❌ AI system error: $error")
            aiSystemCallback?.onAISystemError(error)
        }
    }
    
    /**
     * Check if AI system is running
     */
    fun isRunning(): Boolean = isServerRunning
    
    /**
     * Get AI system status
     */
    fun getStatus(callback: (String?) -> Unit) {
        if (!isServerRunning) {
            callback(null)
            return
        }
        
        scope.launch {
            try {
                val url = URL("http://$AI_SERVER_HOST:$AI_SERVER_PORT/status")
                val connection = url.openConnection() as HttpURLConnection
                connection.requestMethod = "GET"
                connection.connectTimeout = 5000
                connection.readTimeout = 5000
                
                val result = if (connection.responseCode == 200) {
                    connection.inputStream.use { it.reader().readText() }
                } else {
                    null
                }
                
                withContext(Dispatchers.Main) {
                    callback(result)
                }
                
            } catch (e: Exception) {
                log("Status request error: ${e.message}")
                withContext(Dispatchers.Main) {
                    callback(null)
                }
            }
        }
    }
    
    /**
     * Logging utility
     */
    private fun log(message: String) {
        Log.i(TAG, message)
        println("[$TAG] $message")  // Also print to console
    }
}
