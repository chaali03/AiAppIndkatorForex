import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';

class AnalysisResult {
  final String signal; // 'BUY' | 'SELL' | 'HOLD'
  final double confidence; // 0.0..1.0
  final String pattern;
  final String reason;
  final Map<String, double> indicators;
  final DateTime timestamp;

  AnalysisResult({
    required this.signal,
    required this.confidence,
    required this.pattern,
    required this.reason,
    required this.indicators,
    required this.timestamp,
  });

  String get signalUpperCase => signal.toUpperCase();
  int get confidencePercent => (confidence * 100).round();

  Color get signalColor {
    switch (signalUpperCase) {
      case 'BUY':
        return const Color(0xFF34D399); // green
      case 'SELL':
        return const Color(0xFFFF6B6B); // red
      default:
        return const Color(0xFFFBBF24); // amber
    }
  }
}

class ForexAnalyzer {
  static Future<AnalysisResult> analyze(Uint8List imageBytes) async {
    // Minimal, deterministic-ish mock using bytes length as seed
    final seed = imageBytes.length + DateTime.now().millisecond;
    final rng = Random(seed);

    final signals = ['BUY', 'SELL', 'HOLD'];
    final signal = signals[rng.nextInt(signals.length)];
    final confidence = 0.55 + rng.nextDouble() * 0.4; // 55%..95%

    final patterns = [
      'BULLISH_ENGULFING',
      'BEARISH_ENGULFING',
      'DOUBLE_BOTTOM',
      'DOUBLE_TOP',
      'BULLISH_DIVERGENCE',
      'BEARISH_DIVERGENCE',
      'INSIDE_BAR',
    ];
    final pattern = patterns[rng.nextInt(patterns.length)];

    final indicators = <String, double>{
      'RSI': 30 + rng.nextDouble() * 40, // 30..70
      'MACD': -0.5 + rng.nextDouble(),
      'STOCH': rng.nextDouble() * 100,
      'ADX': 10 + rng.nextDouble() * 30,
    };

    final reason =
        'Signal: $signal with ${((confidence) * 100).toStringAsFixed(0)}% confidence from pattern $pattern';

    return AnalysisResult(
      signal: signal,
      confidence: confidence.clamp(0.0, 1.0),
      pattern: pattern,
      reason: reason,
      indicators: indicators,
      timestamp: DateTime.now(),
    );
  }
}
