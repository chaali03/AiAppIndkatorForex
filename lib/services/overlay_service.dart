import 'dart:async';
import 'package:flutter/material.dart';
import '../ai/forex_analyzer.dart';

class OverlayService {
  static bool _isOverlayVisible = false;
  static AnalysisResult? _currentResult;

  static Future<void> showOverlay(String signal) async {
    if (!_isOverlayVisible) {
      try {
        // TODO: Implement overlay window for Android
        // For now, just print the signal
        print('AI SIGNAL: $signal');
        _isOverlayVisible = true;
        print('Overlay shown with signal: $signal');
      } catch (e) {
        print('Error showing overlay: $e');
      }
    }
  }

  static Future<void> showEnhancedOverlay(AnalysisResult result) async {
    // Always update the current result so UI can reflect the latest analysis
    _currentResult = result;
    if (!_isOverlayVisible) {
      try {
        // TODO: Implement enhanced overlay window for Android
        // For now, log once when overlay becomes visible
        print('🤖 AI LENS SIGNAL: ${result.signalUpperCase} (${result.confidencePercent}%)');
        _isOverlayVisible = true;
      } catch (e) {
        print('Error showing enhanced overlay: $e');
      }
    }
  }

  static Future<void> hideOverlay() async {
    if (_isOverlayVisible) {
      // TODO: Hide overlay window for Android
      _isOverlayVisible = false;
      _currentResult = null;
      print('Overlay hidden');
    }
  }

  static AnalysisResult? get currentResult => _currentResult;
  static bool get isOverlayVisible => _isOverlayVisible;

  static void dispose() {
    hideOverlay();
  }
}
