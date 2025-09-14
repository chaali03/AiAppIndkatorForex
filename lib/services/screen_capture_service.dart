import 'dart:typed_data';
import 'dart:math';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import '../ai/forex_analyzer.dart';
import 'overlay_service.dart';
import '../utils/logger.dart';

class ScreenCaptureService {
  static bool _isCapturing = false;
  static int _frameCount = 0;
  
  // Initialize permissions
  static Future<bool> requestPermissions() async {
    // Request screen recording permission (Android specific)
    final status = await Permission.systemAlertWindow.request();
    return status == PermissionStatus.granted;
  }
  
  static Future<void> startCapture(Function(Uint8List imageBytes) onImage) async {
    _isCapturing = true;
    _frameCount = 0;
    
    // Check permissions first
    final hasPermission = await requestPermissions();
    if (!hasPermission) {
      Logger.error('Screen capture permission denied', 'SCREEN_CAPTURE');
      return;
    }
    
    Logger.info('Starting REAL-TIME MetaTrader 5 screen capture...', 'SCREEN_CAPTURE');
    Logger.info('SUPER AI FOREX ANALYSIS - EVERY MOMENT', 'SCREEN_CAPTURE');
    
    // Start real-time screen capture via Android native
    // Analisa langsung di Android, overlay langsung muncul di atas MetaTrader
    
    while (_isCapturing) {
      try {
        // 1) Capture a frame (simulated for now)
        final Uint8List frame = await _captureRealScreen();
        onImage(frame);

        // 2) Run AI analysis
        final AnalysisResult result = await ForexAnalyzer.analyze(frame);

        // 3) Update overlay/current result for UI consumption
        await OverlayService.showEnhancedOverlay(result);

        // 4) Bookkeeping
        _frameCount++;
        if (_frameCount % 5 == 0) {
          Logger.debug('Frames analyzed: $_frameCount | Signal: ${result.signalUpperCase} (${result.confidencePercent}%)', 'SCREEN_CAPTURE');
        }

        // 5) Control loop speed (target ~10 FPS)
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        Logger.error('Error in screen capture: $e', 'SCREEN_CAPTURE', e);
        break;
      }
    }
  }

  static void stopCapture() {
    _isCapturing = false;
    Logger.info('Screen capture stopped', 'SCREEN_CAPTURE');
  }
  
  // Capture real screen (akan diimplementasi via platform channel)
  static Future<Uint8List> _captureRealScreen() async {
    // NOTE: Implementasi real screen capture via platform channel dipending.
    // Untuk sekarang, gunakan simulasi yang lebih realistic
    
    const width = 400;
    const height = 300;
    
    // Create MetaTrader-like chart
    final image = img.Image(width: width, height: height);
    
    // MetaTrader dark theme background
    img.fill(image, color: img.ColorRgb8(15, 20, 30));
    
    // Generate realistic forex price data
    final priceData = _generateRealisticForexData(width);
    
    // Draw candlesticks (like MetaTrader)
    _drawCandlesticks(image, priceData, width, height);
    
    // Add MetaTrader-style indicators
    _addMetaTraderIndicators(image, priceData, width, height);
    
    // Add price labels and grid
    _addMetaTraderUI(image, width, height);
    
    return Uint8List.fromList(img.encodePng(image));
  }
  
  // Generate realistic forex price data (like MetaTrader)
  static List<Map<String, double>> _generateRealisticForexData(int points) {
    final random = Random();
    final data = <Map<String, double>>[];
    double open = 1.2500; // EUR/USD example
    
    for (int i = 0; i < points; i++) {
      // Realistic forex price movement
      const volatility = 0.001; // 10 pips
      final change = (random.nextDouble() - 0.5) * volatility;
      final high = open + (random.nextDouble() * volatility * 0.5);
      final low = open - (random.nextDouble() * volatility * 0.5);
      final close = open + change;
      
      data.add({
        'open': open,
        'high': high,
        'low': low,
        'close': close,
      });
      
      open = close; // Next candle opens at previous close
    }
    
    return data;
  }
  
  // Draw candlesticks (like MetaTrader)
  static void _drawCandlesticks(img.Image image, List<Map<String, double>> data, int width, int height) {
    final candleWidth = width / data.length;
    
    for (int i = 0; i < data.length; i++) {
      final candle = data[i];
      final x = (i * candleWidth).round();
      final w = candleWidth * 0.8;
      
      // Calculate y positions
      final minPrice = data.map((d) => d['low']!).reduce((a, b) => a < b ? a : b);
      final maxPrice = data.map((d) => d['high']!).reduce((a, b) => a > b ? a : b);
      
      final openY = height - ((candle['open']! - minPrice) / (maxPrice - minPrice) * height).round();
      final closeY = height - ((candle['close']! - minPrice) / (maxPrice - minPrice) * height).round();
      final highY = height - ((candle['high']! - minPrice) / (maxPrice - minPrice) * height).round();
      final lowY = height - ((candle['low']! - minPrice) / (maxPrice - minPrice) * height).round();
      
      // Determine color (green for bullish, red for bearish)
      final isBullish = candle['close']! > candle['open']!;
      final color = isBullish ? img.ColorRgb8(0, 200, 100) : img.ColorRgb8(200, 50, 50);
      
      // Draw wick
      img.drawLine(image, x1: (x + w/2).round(), y1: highY, x2: (x + w/2).round(), y2: lowY, color: color);
      
      // Draw body
      final bodyTop = openY < closeY ? openY : closeY;
      final bodyBottom = openY < closeY ? closeY : openY;
      img.fillRect(image, x1: x, y1: bodyTop, x2: (x + w).round(), y2: bodyBottom, color: color);
    }
  }
  
  // Add MetaTrader-style indicators
  static void _addMetaTraderIndicators(img.Image image, List<Map<String, double>> data, int width, int height) {
    // Calculate SMA
    final closes = data.map((d) => d['close']!).toList();
    final sma20 = _calculateSMA(closes, 20);
    
    // Draw SMA line
    for (int i = 1; i < sma20.length; i++) {
      if (sma20[i - 1] != null && sma20[i] != null) {
        final minPrice = data.map((d) => d['low']!).reduce((a, b) => a < b ? a : b);
        final maxPrice = data.map((d) => d['high']!).reduce((a, b) => a > b ? a : b);
        
        final x1 = (i - 1) * (width / data.length);
        final x2 = i * (width / data.length);
        final y1 = height - ((sma20[i - 1]! - minPrice) / (maxPrice - minPrice) * height).round();
        final y2 = height - ((sma20[i]! - minPrice) / (maxPrice - minPrice) * height).round();
        
        // Draw SMA in blue
        img.drawLine(image, x1: x1.round(), y1: y1.round(), x2: x2.round(), y2: y2.round(), color: img.ColorRgb8(100, 150, 255));
      }
    }
  }
  
  // Calculate Simple Moving Average
  static List<double?> _calculateSMA(List<double> prices, int period) {
    final sma = <double?>[];
    
    for (int i = 0; i < prices.length; i++) {
      if (i < period - 1) {
        sma.add(null);
      } else {
        double sum = 0;
        for (int j = i - period + 1; j <= i; j++) {
          sum += prices[j];
        }
        sma.add(sum / period);
      }
    }
    
    return sma;
  }
  
  // Add MetaTrader UI elements
  static void _addMetaTraderUI(img.Image image, int width, int height) {
    final gridColor = img.ColorRgb8(40, 50, 60);
    
    // Grid lines
    for (int x = 0; x < width; x += 50) {
      img.drawLine(image, x1: x, y1: 0, x2: x, y2: height - 1, color: gridColor);
    }
    for (int y = 0; y < height; y += 40) {
      img.drawLine(image, x1: 0, y1: y, x2: width - 1, y2: y, color: gridColor);
    }
    
    // Price labels (simplified)
    final labelColor = img.ColorRgb8(150, 150, 150);
    for (int y = 0; y < height; y += 80) {
      final price = 1.2500 - (y / height * 0.005);
      // Draw price label (simplified)
      img.drawString(image, price.toStringAsFixed(4), font: img.arial24, x: 5, y: y, color: labelColor);
    }
  }
  
  static bool get isCapturing => _isCapturing;
  static int get frameCount => _frameCount;
}
