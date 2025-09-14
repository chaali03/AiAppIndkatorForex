import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

class Logger {
  static const String _tag = 'AI_FOREX_MASTER';
  
  // Log levels
  static const int verbose = 0;
  static const int debugLevel = 1;
  static const int infoLevel = 2;
  static const int warningLevel = 3;
  static const int errorLevel = 4;
  static const int fatalLevel = 5;
  
  static int _currentLevel = debugLevel;
  
  static void setLogLevel(int level) {
    _currentLevel = level;
  }
  
  static void verbose(String message, [String? tag]) {
    _log(verbose, message, tag);
  }
  
  static void debug(String message, [String? tag]) {
    _log(debugLevel, message, tag);
  }
  
  static void info(String message, [String? tag]) {
    _log(infoLevel, message, tag);
  }
  
  static void warning(String message, [String? tag]) {
    _log(warningLevel, message, tag);
  }
  
  static void error(String message, [String? tag, dynamic error, StackTrace? stackTrace]) {
    _log(errorLevel, message, tag);
    if (error != null) {
      developer.log('Error details: $error', name: tag ?? _tag);
    }
    if (stackTrace != null) {
      developer.log('Stack trace: $stackTrace', name: tag ?? _tag);
    }
  }
  
  static void fatal(String message, [String? tag, dynamic error, StackTrace? stackTrace]) {
    _log(fatalLevel, message, tag);
    if (error != null) {
      developer.log('Fatal error details: $error', name: tag ?? _tag);
    }
    if (stackTrace != null) {
      developer.log('Fatal stack trace: $stackTrace', name: tag ?? _tag);
    }
  }
  
  static void _log(int level, String message, String? tag) {
    if (level >= _currentLevel) {
      final logTag = tag ?? _tag;
      final timestamp = DateTime.now().toIso8601String();
      final levelName = _getLevelName(level);
      
      final logMessage = '[$timestamp] [$levelName] $message';
      
      if (kDebugMode) {
        developer.log(logMessage, name: logTag);
      } else {
        // In release mode, only log errors and fatal messages
        if (level >= errorLevel) {
          developer.log(logMessage, name: logTag);
        }
      }
    }
  }
  
  static String _getLevelName(int level) {
    switch (level) {
      case verbose:
        return 'VERBOSE';
      case debugLevel:
        return 'DEBUG';
      case infoLevel:
        return 'INFO';
      case warningLevel:
        return 'WARNING';
      case errorLevel:
        return 'ERROR';
      case fatalLevel:
        return 'FATAL';
      default:
        return 'UNKNOWN';
    }
  }
  
  // Specialized logging methods for different components
  static void api(String message) {
    debug(message, 'API');
  }
  
  static void ai(String message) {
    debug(message, 'AI');
  }
  
  static void ui(String message) {
    debug(message, 'UI');
  }
  
  static void network(String message) {
    debug(message, 'NETWORK');
  }
  
  static void database(String message) {
    debug(message, 'DATABASE');
  }
  
  static void analysis(String message) {
    info(message, 'ANALYSIS');
  }
  
  static void pattern(String message) {
    debug(message, 'PATTERN');
  }
  
  static void indicator(String message) {
    debug(message, 'INDICATOR');
  }
  
  static void sentiment(String message) {
    debug(message, 'SENTIMENT');
  }
  
  static void risk(String message) {
    info(message, 'RISK');
  }
  
  static void trade(String message) {
    info(message, 'TRADE');
  }
  
  // Performance logging
  static void performance(String operation, Duration duration) {
    info('$operation took ${duration.inMilliseconds}ms', 'PERFORMANCE');
  }
  
  // Memory usage logging
  static void memory(String component, int bytes) {
    final mb = bytes / (1024 * 1024);
    debug('$component memory usage: ${mb.toStringAsFixed(2)}MB', 'MEMORY');
  }
  
  // Error tracking
  static void trackError(String errorMessage, String context, [Map<String, dynamic>? extras]) {
    Logger.error('Error in $context: $errorMessage', 'ERROR_TRACKING');
    if (extras != null) {
      debug('Error extras: $extras', 'ERROR_TRACKING');
    }
  }
  
  // Analytics events
  static void analytics(String event, [Map<String, dynamic>? parameters]) {
    info('Analytics event: $event', 'ANALYTICS');
    if (parameters != null) {
      debug('Event parameters: $parameters', 'ANALYTICS');
    }
  }
  
  // User actions
  static void userAction(String action, [Map<String, dynamic>? details]) {
    info('User action: $action', 'USER_ACTION');
    if (details != null) {
      debug('Action details: $details', 'USER_ACTION');
    }
  }
  
  // API calls
  static void apiCall(String endpoint, String method, [Map<String, dynamic>? requestData]) {
    info('API call: $method $endpoint', 'API_CALL');
    if (requestData != null) {
      debug('Request data: $requestData', 'API_CALL');
    }
  }
  
  static void apiResponse(String endpoint, int statusCode, [Map<String, dynamic>? responseData]) {
    info('API response: $endpoint - $statusCode', 'API_RESPONSE');
    if (responseData != null) {
      debug('Response data: $responseData', 'API_RESPONSE');
    }
  }
  
  // AI analysis logging
  static void aiAnalysis(String currencyPair, String timeframe, String signal, double confidence) {
    info('AI Analysis - $currencyPair $timeframe: $signal (${(confidence * 100).toStringAsFixed(1)}%)', 'AI_ANALYSIS');
  }
  
  static void patternDetection(String patternName, double confidence) {
    pattern('Detected pattern: $patternName (${(confidence * 100).toStringAsFixed(1)}%)');
  }
  
  static void indicatorCalculation(String indicatorName, double value) {
    indicator('$indicatorName: ${value.toStringAsFixed(4)}');
  }
  
  // Market data logging
  static void marketData(String currencyPair, double price, String source) {
    debug('Market data - $currencyPair: $price from $source', 'MARKET_DATA');
  }
  
  static void sentimentAnalysis(double score, int bullishSignals, int bearishSignals) {
    sentiment('Sentiment score: ${score.toStringAsFixed(3)}, Bullish: $bullishSignals, Bearish: $bearishSignals');
  }
  
  // Risk assessment logging
  static void riskAssessment(String riskLevel, double riskRewardRatio, double positionSize) {
    risk('Risk Level: $riskLevel, R/R: ${riskRewardRatio.toStringAsFixed(2)}, Position: ${(positionSize * 100).toStringAsFixed(1)}%');
  }
  
  // Trade setup logging
  static void tradeSetup(String signal, double entryPrice, double stopLoss, double takeProfit) {
    trade('Trade Setup - Signal: $signal, Entry: $entryPrice, SL: $stopLoss, TP: $takeProfit');
  }
} 