#!/usr/bin/env python3
"""
ANDROID INTEGRATION SYSTEM
Automatically manages Python AI system startup and integration with Android app
Handles process management, health monitoring, and communication with Android
"""

import os
import sys
import json
import time
import subprocess
import threading
import signal
import psutil
import requests
from pathlib import Path
from datetime import datetime
from typing import Optional, Dict, Any

class AndroidAIIntegration:
    def __init__(self):
        self.ai_root = Path(__file__).parent
        self.config = self.load_config()
        self.python_path = self.config.get("python_path", sys.executable)
        self.server_process = None
        self.server_port = self.config.get("server_port", 8888)
        self.server_host = self.config.get("server_host", "localhost")
        self.running = False
        self.monitor_thread = None
        
        # Health check settings
        self.health_check_interval = 5  # seconds
        self.max_restart_attempts = 3
        self.restart_attempts = 0
        
    def load_config(self):
        """Load configuration from config file"""
        config_path = self.ai_root / "config.json"
        default_config = {
            "server_host": "localhost",
            "server_port": 8888,
            "auto_start": True,
            "auto_restart": True,
            "health_check_enabled": True,
            "startup_timeout": 30
        }
        
        if config_path.exists():
            try:
                with open(config_path, "r") as f:
                    config = json.load(f)
                    default_config.update(config)
                    return default_config
            except Exception as e:
                self.log(f"Error loading config: {e}", "WARNING")
        
        return default_config
    
    def log(self, message, level="INFO"):
        """Enhanced logging with timestamps"""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        log_message = f"[{timestamp}] [ANDROID-AI] [{level}] {message}"
        print(log_message)
        
        # Log to file
        log_file = self.ai_root / "android_integration.log"
        with open(log_file, "a", encoding="utf-8") as f:
            f.write(log_message + "\n")
    
    def check_python_environment(self):
        """Check if Python environment is properly set up"""
        try:
            # Check if virtual environment exists
            venv_path = self.ai_root / "venv"
            if not venv_path.exists():
                self.log("Virtual environment not found. Running setup...", "WARNING")
                return self.run_setup()
            
            # Check if required modules are available
            test_cmd = [
                str(self.python_path), "-c",
                "import tensorflow, numpy, cv2; print('Environment OK')"
            ]
            
            result = subprocess.run(test_cmd, capture_output=True, text=True, timeout=10)
            if result.returncode == 0:
                self.log("Python environment verified successfully")
                return True
            else:
                self.log(f"Environment check failed: {result.stderr}", "ERROR")
                return self.run_setup()
                
        except Exception as e:
            self.log(f"Environment check error: {str(e)}", "ERROR")
            return False
    
    def run_setup(self):
        """Run the Python environment setup"""
        self.log("Running Python environment setup...")
        
        setup_script = self.ai_root / "setup_python_environment.py"
        if not setup_script.exists():
            self.log("Setup script not found!", "ERROR")
            return False
        
        try:
            # Run setup with current Python interpreter
            result = subprocess.run([
                sys.executable, str(setup_script)
            ], capture_output=True, text=True, timeout=600)
            
            if result.returncode == 0:
                self.log("Python environment setup completed successfully")
                # Reload config after setup
                self.config = self.load_config()
                self.python_path = self.config.get("python_path", sys.executable)
                return True
            else:
                self.log(f"Setup failed: {result.stderr}", "ERROR")
                return False
                
        except subprocess.TimeoutExpired:
            self.log("Setup timeout after 10 minutes", "ERROR")
            return False
        except Exception as e:
            self.log(f"Setup error: {str(e)}", "ERROR")
            return False
    
    def is_server_running(self):
        """Check if AI server is already running"""
        try:
            response = requests.get(
                f"http://{self.server_host}:{self.server_port}/health",
                timeout=5
            )
            return response.status_code == 200
        except:
            return False
    
    def kill_existing_server(self):
        """Kill any existing AI server processes"""
        self.log("Checking for existing AI server processes...")
        
        killed_count = 0
        for proc in psutil.process_iter(['pid', 'name', 'cmdline']):
            try:
                cmdline = proc.info['cmdline']
                if cmdline and any('ai_server.py' in arg for arg in cmdline):
                    self.log(f"Killing existing AI server process (PID: {proc.info['pid']})")
                    proc.kill()
                    killed_count += 1
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                continue
        
        if killed_count > 0:
            self.log(f"Killed {killed_count} existing server processes")
            time.sleep(2)  # Wait for processes to terminate
    
    def start_ai_server(self):
        """Start the AI server process"""
        if self.is_server_running():
            self.log("AI server is already running")
            return True
        
        # Kill any existing servers
        self.kill_existing_server()
        
        self.log("Starting AI server...")
        
        server_script = self.ai_root / "ai_server.py"
        if not server_script.exists():
            self.log("AI server script not found!", "ERROR")
            return False
        
        try:
            # Start server process
            self.server_process = subprocess.Popen([
                str(self.python_path), str(server_script)
            ], 
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            cwd=self.ai_root,
            creationflags=subprocess.CREATE_NEW_PROCESS_GROUP if os.name == 'nt' else 0
            )
            
            # Wait for server to start
            timeout = self.config.get("startup_timeout", 30)
            start_time = time.time()
            
            while time.time() - start_time < timeout:
                if self.is_server_running():
                    self.log(f"AI server started successfully (PID: {self.server_process.pid})")
                    return True
                
                if self.server_process.poll() is not None:
                    # Process has terminated
                    stdout, stderr = self.server_process.communicate()
                    self.log(f"Server process terminated early: {stderr.decode()}", "ERROR")
                    return False
                
                time.sleep(1)
            
            self.log("Server startup timeout", "ERROR")
            if self.server_process:
                self.server_process.terminate()
            return False
            
        except Exception as e:
            self.log(f"Failed to start AI server: {str(e)}", "ERROR")
            return False
    
    def stop_ai_server(self):
        """Stop the AI server process"""
        if self.server_process:
            try:
                self.log("Stopping AI server...")
                self.server_process.terminate()
                
                # Wait for graceful termination
                try:
                    self.server_process.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    self.log("Force killing AI server process")
                    self.server_process.kill()
                
                self.server_process = None
                self.log("AI server stopped")
                
            except Exception as e:
                self.log(f"Error stopping server: {str(e)}", "ERROR")
        
        # Also kill any remaining processes
        self.kill_existing_server()
    
    def health_monitor(self):
        """Monitor server health and restart if needed"""
        while self.running:
            try:
                if not self.is_server_running():
                    self.log("Server health check failed", "WARNING")
                    
                    if self.config.get("auto_restart", True) and self.restart_attempts < self.max_restart_attempts:
                        self.restart_attempts += 1
                        self.log(f"Attempting server restart ({self.restart_attempts}/{self.max_restart_attempts})")
                        
                        if self.start_ai_server():
                            self.restart_attempts = 0  # Reset counter on success
                            self.log("Server restarted successfully")
                        else:
                            self.log(f"Server restart failed (attempt {self.restart_attempts})", "ERROR")
                    else:
                        if self.restart_attempts >= self.max_restart_attempts:
                            self.log("Maximum restart attempts reached", "ERROR")
                        break
                else:
                    # Server is healthy, reset restart attempts
                    self.restart_attempts = 0
                
                time.sleep(self.health_check_interval)
                
            except Exception as e:
                self.log(f"Health monitor error: {str(e)}", "ERROR")
                time.sleep(self.health_check_interval)
    
    def start_monitoring(self):
        """Start health monitoring in background"""
        if self.config.get("health_check_enabled", True) and not self.monitor_thread:
            self.monitor_thread = threading.Thread(target=self.health_monitor, daemon=True)
            self.monitor_thread.start()
            self.log("Health monitoring started")
    
    def stop_monitoring(self):
        """Stop health monitoring"""
        self.running = False
        if self.monitor_thread:
            self.monitor_thread.join(timeout=5)
            self.monitor_thread = None
            self.log("Health monitoring stopped")
    
    def get_server_status(self):
        """Get current server status"""
        try:
            response = requests.get(
                f"http://{self.server_host}:{self.server_port}/status",
                timeout=5
            )
            if response.status_code == 200:
                return response.json()
            else:
                return {"status": "error", "message": f"HTTP {response.status_code}"}
        except Exception as e:
            return {"status": "offline", "error": str(e)}
    
    def send_analysis_request(self, data):
        """Send analysis request to AI server"""
        try:
            response = requests.post(
                f"http://{self.server_host}:{self.server_port}/analyze",
                json=data,
                timeout=30
            )
            if response.status_code == 200:
                return response.json()
            else:
                return {"success": False, "error": f"HTTP {response.status_code}"}
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    def send_image_analysis_request(self, image_data, metadata=None):
        """Send image analysis request to AI server"""
        try:
            payload = {
                "image": image_data,
                **(metadata or {})
            }
            
            response = requests.post(
                f"http://{self.server_host}:{self.server_port}/analyze_image",
                json=payload,
                timeout=60  # Longer timeout for image processing
            )
            
            if response.status_code == 200:
                return response.json()
            else:
                return {"success": False, "error": f"HTTP {response.status_code}"}
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    def initialize(self):
        """Initialize the Android AI integration system"""
        self.log("🚀 Initializing Android AI Integration...")
        
        # Check Python environment
        if not self.check_python_environment():
            self.log("Failed to initialize Python environment", "ERROR")
            return False
        
        # Start AI server if auto_start is enabled
        if self.config.get("auto_start", True):
            if not self.start_ai_server():
                self.log("Failed to start AI server", "ERROR")
                return False
        
        # Start monitoring
        self.running = True
        self.start_monitoring()
        
        self.log("✅ Android AI Integration initialized successfully")
        self.log(f"🌐 AI Server: http://{self.server_host}:{self.server_port}")
        
        return True
    
    def shutdown(self):
        """Shutdown the integration system"""
        self.log("🛑 Shutting down Android AI Integration...")
        
        self.stop_monitoring()
        self.stop_ai_server()
        
        self.log("Android AI Integration shutdown completed")

class AndroidAIManager:
    """Singleton manager for Android AI Integration"""
    _instance = None
    _integration = None
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance
    
    def get_integration(self) -> AndroidAIIntegration:
        """Get or create integration instance"""
        if self._integration is None:
            self._integration = AndroidAIIntegration()
        return self._integration
    
    def start(self):
        """Start the AI integration system"""
        integration = self.get_integration()
        return integration.initialize()
    
    def stop(self):
        """Stop the AI integration system"""
        if self._integration:
            self._integration.shutdown()
            self._integration = None
    
    def get_status(self):
        """Get current system status"""
        if self._integration:
            return self._integration.get_server_status()
        else:
            return {"status": "not_initialized"}
    
    def analyze(self, data):
        """Send analysis request"""
        if self._integration:
            return self._integration.send_analysis_request(data)
        else:
            return {"success": False, "error": "Integration not initialized"}
    
    def analyze_image(self, image_data, metadata=None):
        """Send image analysis request"""
        if self._integration:
            return self._integration.send_image_analysis_request(image_data, metadata)
        else:
            return {"success": False, "error": "Integration not initialized"}

def signal_handler(signum, frame):
    """Handle shutdown signals"""
    print("\n🛑 Shutting down Android AI Integration...")
    manager = AndroidAIManager()
    manager.stop()
    sys.exit(0)

def main():
    """Main function for standalone operation"""
    # Register signal handlers
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    # Create and start manager
    manager = AndroidAIManager()
    
    if manager.start():
        print("✅ Android AI Integration started successfully")
        print("Press Ctrl+C to stop...")
        
        try:
            # Keep running
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            pass
    else:
        print("❌ Failed to start Android AI Integration")
        sys.exit(1)

if __name__ == "__main__":
    main()
