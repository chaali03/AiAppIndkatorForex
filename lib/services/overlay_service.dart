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
    _currentResult = result;
    if (!_isOverlayVisible) {
      try {
        // TODO: Implement enhanced overlay window for Android
        // For now, just print the enhanced signal
        print('🤖 AI LENS SIGNAL: ${result.signalUpperCase} (${result.confidencePercent}%)');
        print('📊 Pattern: ${result.pattern}');
        print('🔍 Reason: ${result.reason}');
        _isOverlayVisible = true;
        print('Enhanced overlay shown with signal: ${result.signalUpperCase}');
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
