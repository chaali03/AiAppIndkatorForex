import 'dart:async';
import '../ai/forex_analyzer.dart';
import '../utils/logger.dart';

class OverlayService {
  static bool _isOverlayVisible = false;
  static AnalysisResult? _currentResult;

  static Future<void> showOverlay(String signal) async {
    if (!_isOverlayVisible) {
      try {
        // NOTE: Overlay window for Android is planned for a later implementation.
        // For now, log the signal
        Logger.info('AI SIGNAL: $signal', 'OVERLAY');
        _isOverlayVisible = true;
        Logger.info('Overlay shown with signal: $signal', 'OVERLAY');
      } catch (e) {
        Logger.error('Error showing overlay: $e', 'OVERLAY', e);
      }
    }
  }

  static Future<void> showEnhancedOverlay(AnalysisResult result) async {
    // Always update the current result so UI can reflect the latest analysis
    _currentResult = result;
    if (!_isOverlayVisible) {
      try {
        // NOTE: Enhanced overlay window for Android is planned for a later implementation.
        // For now, log once when overlay becomes visible
        Logger.info('AI LENS SIGNAL: ${result.signalUpperCase} (${result.confidencePercent}%)', 'OVERLAY');
        _isOverlayVisible = true;
      } catch (e) {
        Logger.error('Error showing enhanced overlay: $e', 'OVERLAY', e);
      }
    }
  }

  static Future<void> hideOverlay() async {
    if (_isOverlayVisible) {
      // NOTE: Hide overlay window for Android to be implemented later.
      _isOverlayVisible = false;
      _currentResult = null;
      Logger.info('Overlay hidden', 'OVERLAY');
    }
  }

  static AnalysisResult? get currentResult => _currentResult;
  static bool get isOverlayVisible => _isOverlayVisible;

  static void dispose() {
    hideOverlay();
  }
}
