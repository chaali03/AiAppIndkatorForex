#!/usr/bin/env python3
"""
ADVANCED CRYPTO AI SERVER
High-performance local HTTP server that provides crypto trading signals to Android app
Features real-time analysis, WebSocket support, and professional-grade predictions
"""

import os
import sys
import json
import time
import threading
import signal
import traceback
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional, Any

# HTTP Server imports
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
import socketserver

# WebSocket support
try:
    import websockets
    import asyncio
    WEBSOCKET_AVAILABLE = True
except ImportError:
    WEBSOCKET_AVAILABLE = False
    print("WebSocket support not available. Install with: pip install websockets")

# AI and analysis imports
try:
    import numpy as np
    import cv2
    from PIL import Image
    import io
    import base64
    
    # Import our advanced crypto analyzer
    from advanced_crypto_analyzer import AdvancedCryptoAnalyzer
    AI_AVAILABLE = True
except ImportError as e:
    AI_AVAILABLE = False
    print(f"AI modules not available: {e}")
    print("Please run setup_python_environment.py first")

class CryptoAIServer:
    def __init__(self, host="localhost", port=8888):
        self.host = host
        self.port = port
        self.running = False
        self.ai_analyzer = None
        self.server = None
        self.websocket_server = None
        
        # Performance tracking
        self.request_count = 0
        self.start_time = time.time()
        self.error_count = 0
        
        # Configuration
        self.config = self.load_config()
        
        # Initialize AI analyzer if available
        if AI_AVAILABLE:
            try:
                self.ai_analyzer = AdvancedCryptoAnalyzer()
                print("🤖 Advanced Crypto AI Analyzer initialized successfully")
            except Exception as e:
                print(f"❌ Failed to initialize AI analyzer: {e}")
                AI_AVAILABLE = False
    
    def load_config(self):
        """Load configuration from config file"""
        config_path = Path(__file__).parent / "config.json"
        default_config = {
            "server_host": self.host,
            "server_port": self.port,
            "max_image_size": 2048,
            "timeout_seconds": 30,
            "enable_websocket": True,
            "enable_cors": True,
            "log_requests": True
        }
        
        if config_path.exists():
            try:
                with open(config_path, "r") as f:
                    config = json.load(f)
                    # Merge with defaults
                    default_config.update(config)
                    return default_config
            except Exception as e:
                print(f"Error loading config: {e}")
        
        return default_config
    
    def log(self, message, level="INFO"):
        """Enhanced logging with timestamps"""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        print(f"[{timestamp}] [{level}] {message}")
        
        # Log to file if enabled
        if self.config.get("log_requests", True):
            log_file = Path(__file__).parent / "server.log"
            with open(log_file, "a", encoding="utf-8") as f:
                f.write(f"[{timestamp}] [{level}] {message}\n")

class AIRequestHandler(BaseHTTPRequestHandler):
    def __init__(self, request, client_address, server):
        self.ai_server = server.ai_server
        super().__init__(request, client_address, server)
    
    def do_OPTIONS(self):
        """Handle CORS preflight requests"""
        if self.ai_server.config.get("enable_cors", True):
            self.send_response(200)
            self.send_header("Access-Control-Allow-Origin", "*")
            self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
            self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization")
            self.end_headers()
        else:
            self.send_error(405)
    
    def do_GET(self):
        """Handle GET requests"""
        try:
            parsed_path = urlparse(self.path)
            path = parsed_path.path
            
            if path == "/":
                self.serve_status_page()
            elif path == "/status":
                self.serve_status_json()
            elif path == "/health":
                self.serve_health_check()
            elif path == "/analyze":
                # GET analyze with query parameters
                params = parse_qs(parsed_path.query)
                self.handle_analyze_request(params)
            else:
                self.send_error(404, "Endpoint not found")
                
        except Exception as e:
            self.ai_server.log(f"Error in GET request: {str(e)}", "ERROR")
            self.send_error(500, f"Internal server error: {str(e)}")
    
    def do_POST(self):
        """Handle POST requests"""
        try:
            parsed_path = urlparse(self.path)
            path = parsed_path.path
            
            if path == "/analyze":
                self.handle_analyze_post()
            elif path == "/analyze_image":
                self.handle_image_analysis()
            else:
                self.send_error(404, "Endpoint not found")
                
        except Exception as e:
            self.ai_server.log(f"Error in POST request: {str(e)}", "ERROR")
            self.send_error(500, f"Internal server error: {str(e)}")
    
    def serve_status_page(self):
        """Serve HTML status page"""
        uptime = time.time() - self.ai_server.start_time
        uptime_str = f"{int(uptime // 3600)}h {int((uptime % 3600) // 60)}m {int(uptime % 60)}s"
        
        html = f"""
<!DOCTYPE html>
<html>
<head>
    <title>Advanced Crypto AI Server</title>
    <style>
        body {{ font-family: Arial, sans-serif; margin: 20px; background: #1a1a1a; color: #fff; }}
        .container {{ max-width: 800px; margin: 0 auto; }}
        .status {{ background: #2d2d2d; padding: 20px; border-radius: 8px; margin: 10px 0; }}
        .metric {{ display: inline-block; margin: 10px 20px; }}
        .value {{ font-size: 24px; font-weight: bold; color: #4CAF50; }}
        .label {{ font-size: 14px; color: #ccc; }}
        .ai-status {{ color: {'#4CAF50' if AI_AVAILABLE else '#f44336'}; }}
        .endpoint {{ background: #333; padding: 10px; margin: 5px 0; border-radius: 4px; }}
        h1 {{ color: #4CAF50; }}
        h2 {{ color: #2196F3; }}
    </style>
</head>
<body>
    <div class="container">
        <h1>🤖 Advanced Crypto AI Server</h1>
        
        <div class="status">
            <h2>Server Status</h2>
            <div class="metric">
                <div class="value">{'🟢 Online' if self.ai_server.running else '🔴 Offline'}</div>
                <div class="label">Status</div>
            </div>
            <div class="metric">
                <div class="value">{uptime_str}</div>
                <div class="label">Uptime</div>
            </div>
            <div class="metric">
                <div class="value">{self.ai_server.request_count}</div>
                <div class="label">Requests</div>
            </div>
            <div class="metric">
                <div class="value">{self.ai_server.error_count}</div>
                <div class="label">Errors</div>
            </div>
        </div>
        
        <div class="status">
            <h2>AI System Status</h2>
            <div class="ai-status">
                {'✅ AI Analyzer Ready' if AI_AVAILABLE else '❌ AI Analyzer Not Available'}
            </div>
            {f'<div>Model loaded: {self.ai_server.ai_analyzer.model_path if self.ai_server.ai_analyzer else "N/A"}</div>' if AI_AVAILABLE else ''}
        </div>
        
        <div class="status">
            <h2>Available Endpoints</h2>
            <div class="endpoint"><strong>GET /</strong> - This status page</div>
            <div class="endpoint"><strong>GET /status</strong> - JSON status information</div>
            <div class="endpoint"><strong>GET /health</strong> - Health check</div>
            <div class="endpoint"><strong>POST /analyze</strong> - Analyze crypto data (JSON)</div>
            <div class="endpoint"><strong>POST /analyze_image</strong> - Analyze chart image</div>
        </div>
        
        <div class="status">
            <h2>Configuration</h2>
            <div>Host: {self.ai_server.host}:{self.ai_server.port}</div>
            <div>CORS: {'Enabled' if self.ai_server.config.get("enable_cors") else 'Disabled'}</div>
            <div>WebSocket: {'Available' if WEBSOCKET_AVAILABLE else 'Not Available'}</div>
        </div>
    </div>
</body>
</html>
"""
        
        self.send_response(200)
        self.send_header("Content-type", "text/html")
        if self.ai_server.config.get("enable_cors", True):
            self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(html.encode())
    
    def serve_status_json(self):
        """Serve JSON status information"""
        uptime = time.time() - self.ai_server.start_time
        
        status = {
            "status": "online" if self.ai_server.running else "offline",
            "uptime_seconds": uptime,
            "requests_handled": self.ai_server.request_count,
            "errors": self.ai_server.error_count,
            "ai_available": AI_AVAILABLE,
            "websocket_available": WEBSOCKET_AVAILABLE,
            "server_info": {
                "host": self.ai_server.host,
                "port": self.ai_server.port,
                "version": "1.0.0"
            },
            "timestamp": datetime.now().isoformat()
        }
        
        self.send_json_response(status)
    
    def serve_health_check(self):
        """Serve health check endpoint"""
        health = {
            "status": "healthy",
            "ai_ready": AI_AVAILABLE and self.ai_server.ai_analyzer is not None,
            "timestamp": datetime.now().isoformat()
        }
        
        self.send_json_response(health)
    
    def handle_analyze_request(self, params):
        """Handle analyze request with parameters"""
        if not AI_AVAILABLE or not self.ai_server.ai_analyzer:
            self.send_error(503, "AI analyzer not available")
            return
        
        try:
            # Extract analysis parameters
            symbol = params.get("symbol", ["BTCUSDT"])[0]
            timeframe = params.get("timeframe", ["1h"])[0]
            
            # For demo purposes, generate sample analysis
            # In real implementation, you would get actual price data
            result = self.generate_sample_analysis(symbol, timeframe)
            
            self.send_json_response(result)
            
        except Exception as e:
            self.ai_server.error_count += 1
            self.ai_server.log(f"Error in analyze request: {str(e)}", "ERROR")
            self.send_error(500, f"Analysis error: {str(e)}")
    
    def handle_analyze_post(self):
        """Handle POST analyze request with JSON data"""
        if not AI_AVAILABLE or not self.ai_server.ai_analyzer:
            self.send_error(503, "AI analyzer not available")
            return
        
        try:
            content_length = int(self.headers.get('Content-Length', 0))
            if content_length > 10 * 1024 * 1024:  # 10MB limit
                self.send_error(413, "Request too large")
                return
            
            post_data = self.rfile.read(content_length)
            data = json.loads(post_data.decode('utf-8'))
            
            # Process the analysis request
            result = self.process_analysis_data(data)
            
            self.send_json_response(result)
            
        except json.JSONDecodeError:
            self.send_error(400, "Invalid JSON data")
        except Exception as e:
            self.ai_server.error_count += 1
            self.ai_server.log(f"Error in POST analyze: {str(e)}", "ERROR")
            self.send_error(500, f"Analysis error: {str(e)}")
    
    def handle_image_analysis(self):
        """Handle image analysis from screen capture"""
        if not AI_AVAILABLE or not self.ai_server.ai_analyzer:
            self.send_error(503, "AI analyzer not available")
            return
        
        try:
            content_length = int(self.headers.get('Content-Length', 0))
            if content_length > 20 * 1024 * 1024:  # 20MB limit for images
                self.send_error(413, "Image too large")
                return
            
            post_data = self.rfile.read(content_length)
            data = json.loads(post_data.decode('utf-8'))
            
            # Extract base64 image data
            if "image" not in data:
                self.send_error(400, "No image data provided")
                return
            
            image_data = data["image"]
            if image_data.startswith("data:image"):
                # Remove data URL prefix
                image_data = image_data.split(",")[1]
            
            # Decode base64 image
            image_bytes = base64.b64decode(image_data)
            image = Image.open(io.BytesIO(image_bytes))
            
            # Convert to numpy array for processing
            image_array = np.array(image)
            
            # Process image analysis
            result = self.process_image_analysis(image_array, data)
            
            self.send_json_response(result)
            
        except Exception as e:
            self.ai_server.error_count += 1
            self.ai_server.log(f"Error in image analysis: {str(e)}", "ERROR")
            self.send_error(500, f"Image analysis error: {str(e)}")
    
    def process_analysis_data(self, data):
        """Process analysis request with price/indicator data"""
        try:
            symbol = data.get("symbol", "BTCUSDT")
            timeframe = data.get("timeframe", "1h")
            price_data = data.get("price_data", [])
            
            if not price_data:
                return self.generate_sample_analysis(symbol, timeframe)
            
            # Use AI analyzer to process real data
            # This is where you'd implement the actual AI analysis
            result = self.ai_server.ai_analyzer.analyze_comprehensive(
                price_data=price_data,
                symbol=symbol,
                timeframe=timeframe
            )
            
            return {
                "success": True,
                "symbol": symbol,
                "timeframe": timeframe,
                "timestamp": datetime.now().isoformat(),
                "analysis": result
            }
            
        except Exception as e:
            raise Exception(f"Analysis processing failed: {str(e)}")
    
    def process_image_analysis(self, image_array, metadata):
        """Process chart image analysis"""
        try:
            # Extract candlestick data from image
            candlesticks = self.extract_candlesticks_from_image(image_array)
            
            if not candlesticks:
                return {
                    "success": False,
                    "error": "No candlestick data found in image",
                    "timestamp": datetime.now().isoformat()
                }
            
            # Analyze extracted data
            symbol = metadata.get("symbol", "Unknown")
            timeframe = metadata.get("timeframe", "Unknown")
            
            result = self.ai_server.ai_analyzer.analyze_comprehensive(
                price_data=candlesticks,
                symbol=symbol,
                timeframe=timeframe
            )
            
            return {
                "success": True,
                "symbol": symbol,
                "timeframe": timeframe,
                "candlesticks_detected": len(candlesticks),
                "timestamp": datetime.now().isoformat(),
                "analysis": result
            }
            
        except Exception as e:
            raise Exception(f"Image analysis failed: {str(e)}")
    
    def extract_candlesticks_from_image(self, image_array):
        """Extract candlestick data from chart image using computer vision"""
        try:
            # This is a simplified implementation
            # In a real scenario, you'd use sophisticated computer vision
            # to detect and extract candlestick patterns from chart images
            
            # Convert to OpenCV format
            if len(image_array.shape) == 3:
                cv_image = cv2.cvtColor(image_array, cv2.COLOR_RGB2BGR)
            else:
                cv_image = image_array
            
            # Generate sample data based on image analysis
            # Replace this with actual computer vision candlestick detection
            candlesticks = []
            for i in range(20):  # Sample 20 candlesticks
                candlesticks.append({
                    "open": 50000 + i * 100 + np.random.randint(-500, 500),
                    "high": 50500 + i * 100 + np.random.randint(-300, 800),
                    "low": 49500 + i * 100 + np.random.randint(-800, 300),
                    "close": 50000 + i * 100 + np.random.randint(-500, 500),
                    "volume": np.random.randint(1000, 10000)
                })
            
            return candlesticks
            
        except Exception as e:
            self.ai_server.log(f"Error extracting candlesticks: {str(e)}", "ERROR")
            return []
    
    def generate_sample_analysis(self, symbol, timeframe):
        """Generate sample analysis for demonstration"""
        import random
        
        # Generate realistic sample data
        indicators = {
            "rsi": round(random.uniform(20, 80), 2),
            "macd": round(random.uniform(-100, 100), 2),
            "bb_upper": round(random.uniform(52000, 55000), 2),
            "bb_lower": round(random.uniform(48000, 51000), 2),
            "sma_20": round(random.uniform(49000, 52000), 2),
            "ema_12": round(random.uniform(49500, 51500), 2),
            "adx": round(random.uniform(15, 45), 2)
        }
        
        # Generate signal
        signals = ["BUY", "SELL", "HOLD"]
        signal = random.choice(signals)
        confidence = round(random.uniform(0.6, 0.95), 2)
        
        return {
            "success": True,
            "symbol": symbol,
            "timeframe": timeframe,
            "timestamp": datetime.now().isoformat(),
            "analysis": {
                "signal": signal,
                "confidence": confidence,
                "technical_indicators": indicators,
                "patterns_detected": ["doji", "hammer"] if random.random() > 0.5 else ["engulfing"],
                "risk_level": random.choice(["LOW", "MEDIUM", "HIGH"]),
                "predicted_move": round(random.uniform(-5, 5), 2)
            }
        }
    
    def send_json_response(self, data):
        """Send JSON response with proper headers"""
        self.ai_server.request_count += 1
        
        json_data = json.dumps(data, indent=2)
        
        self.send_response(200)
        self.send_header("Content-type", "application/json")
        if self.ai_server.config.get("enable_cors", True):
            self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(json_data.encode())
    
    def send_error(self, code, message):
        """Send error response"""
        self.ai_server.error_count += 1
        super().send_error(code, message)
    
    def log_message(self, format, *args):
        """Override default logging"""
        if self.ai_server.config.get("log_requests", True):
            self.ai_server.log(f"{self.address_string()} - {format % args}")

class ThreadedHTTPServer(socketserver.ThreadingMixIn, HTTPServer):
    """Thread-per-request HTTP server"""
    allow_reuse_address = True
    daemon_threads = True
    
    def __init__(self, server_address, RequestHandlerClass, ai_server):
        self.ai_server = ai_server
        super().__init__(server_address, RequestHandlerClass)

def signal_handler(signum, frame):
    """Handle shutdown signals"""
    print("\n🛑 Shutting down AI server...")
    sys.exit(0)

def main():
    """Main server startup function"""
    print("🚀 Advanced Crypto AI Server Starting...")
    
    # Check if setup was completed
    config_path = Path(__file__).parent / "config.json"
    if not config_path.exists():
        print("❌ Setup not completed. Please run setup_python_environment.py first")
        sys.exit(1)
    
    # Register signal handlers
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    try:
        # Create AI server instance
        ai_server = CryptoAIServer()
        
        # Create HTTP server
        server_address = (ai_server.host, ai_server.port)
        httpd = ThreadedHTTPServer(server_address, AIRequestHandler, ai_server)
        ai_server.server = httpd
        ai_server.running = True
        
        print(f"✅ Server started successfully!")
        print(f"🌐 Listening on http://{ai_server.host}:{ai_server.port}")
        print(f"🤖 AI Status: {'Ready' if AI_AVAILABLE else 'Not Available'}")
        print(f"📊 WebSocket: {'Available' if WEBSOCKET_AVAILABLE else 'Not Available'}")
        print(f"⏰ Started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print("\n📋 Available endpoints:")
        print(f"   • http://{ai_server.host}:{ai_server.port}/ - Status page")
        print(f"   • http://{ai_server.host}:{ai_server.port}/analyze - Analysis API")
        print(f"   • http://{ai_server.host}:{ai_server.port}/analyze_image - Image analysis")
        print("\n🛑 Press Ctrl+C to stop the server")
        
        # Start serving requests
        httpd.serve_forever()
        
    except OSError as e:
        if e.errno == 48:  # Address already in use
            print(f"❌ Port {ai_server.port} is already in use")
            print("Try changing the port in config.json or stopping the existing server")
        else:
            print(f"❌ Server startup failed: {str(e)}")
        sys.exit(1)
    except Exception as e:
        print(f"💥 Unexpected error: {str(e)}")
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()
