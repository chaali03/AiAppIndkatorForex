class ApiConfig {
  // Alpha Vantage API - Real-time forex data
  static const String alphaVantageApiKey = 'YOUR_ALPHA_VANTAGE_API_KEY';
  static const String alphaVantageBaseUrl = 'https://www.alphavantage.co/query';
  
  // TradingView API - Technical analysis
  static const String tradingViewApiUrl = 'https://scanner.tradingview.com/forex/scan';
  
  // News API - Market sentiment
  static const String newsApiKey = 'YOUR_NEWS_API_KEY';
  static const String newsApiBaseUrl = 'https://newsapi.org/v2';
  
  // Forex Factory API - Economic calendar
  static const String forexFactoryApiUrl = 'https://www.forexfactory.com/api/calendar';
  
  // App settings
  static const int requestTimeout = 30000; // 30 seconds
  static const int maxRetries = 3;
  static const bool enableCaching = true;
  static const int cacheExpiryHours = 1;
  
  // AI Model settings
  static const String modelPath = 'assets/model/forex_patterns.tflite';
  static const int modelInputSize = 224;
  static const double confidenceThreshold = 0.7;
  
  // Supported currency pairs
  static const List<String> supportedPairs = [
    'EUR/USD',
    'GBP/USD', 
    'USD/JPY',
    'USD/CHF',
    'AUD/USD',
    'NZD/USD',
    'USD/CAD',
    'EUR/GBP',
    'EUR/JPY',
    'GBP/JPY',
    'AUD/JPY',
    'NZD/JPY',
    'EUR/CHF',
    'GBP/CHF',
    'AUD/CHF',
    'CAD/CHF',
    'EUR/AUD',
    'GBP/AUD',
    'AUD/NZD',
    'CAD/JPY'
  ];
  
  // Supported timeframes
  static const List<String> supportedTimeframes = [
    '1m',
    '2m', 
    '3m',
    '4m',
    '5m',
    '6m',
    '15m',
    '30m',
    '1h',
    '4h',
    '1d',
    '1w'
  ];
  
  // Technical indicators configuration
  static const Map<String, Map<String, dynamic>> indicatorConfig = {
    'RSI': {
      'period': 14,
      'overbought': 70,
      'oversold': 30,
    },
    'MACD': {
      'fastPeriod': 12,
      'slowPeriod': 26,
      'signalPeriod': 9,
    },
    'Stochastic': {
      'kPeriod': 14,
      'dPeriod': 3,
      'overbought': 80,
      'oversold': 20,
    },
    'BollingerBands': {
      'period': 20,
      'deviation': 2,
    },
    'ADX': {
      'period': 14,
      'strongTrend': 25,
    },
    'WilliamsR': {
      'period': 14,
      'overbought': -20,
      'oversold': -80,
    },
  };
  
  // Pattern recognition settings
  static const Map<String, double> patternWeights = {
    'BULLISH_ENGULFING': 0.9,
    'BEARISH_ENGULFING': 0.9,
    'HAMMER': 0.8,
    'SHOOTING_STAR': 0.8,
    'DOJI': 0.6,
    'MORNING_STAR': 0.95,
    'EVENING_STAR': 0.95,
    'THREE_WHITE_SOLDIERS': 0.9,
    'THREE_BLACK_CROWS': 0.9,
    'HEAD_AND_SHOULDERS': 0.85,
    'DOUBLE_TOP': 0.8,
    'DOUBLE_BOTTOM': 0.8,
    'ASCENDING_TRIANGLE': 0.75,
    'DESCENDING_TRIANGLE': 0.75,
    'RISING_WEDGE': 0.7,
    'FALLING_WEDGE': 0.7,
  };
  
  // Risk management settings
  static const Map<String, dynamic> riskConfig = {
    'maxRiskPerTrade': 0.02, // 2% per trade
    'maxPortfolioRisk': 0.06, // 6% total portfolio
    'minRiskRewardRatio': 1.5,
    'maxDrawdown': 0.20, // 20% max drawdown
    'positionSizingMethod': 'kelly', // kelly, fixed, percentage
  };
  
  // UI/UX settings
  static const Map<String, dynamic> uiConfig = {
    'theme': 'dark',
    'primaryColor': 0xFF00D4FF,
    'secondaryColor': 0xFF00FF88,
    'backgroundColor': 0xFF0A0A0A,
    'cardColor': 0xFF1A1A1A,
    'animationDuration': 300,
    'enableHapticFeedback': true,
    'enableSoundEffects': false,
  };
  
  // Performance settings
  static const Map<String, dynamic> performanceConfig = {
    'enableCaching': true,
    'cacheExpiryMinutes': 60,
    'maxCacheSize': 100, // MB
    'enableCompression': true,
    'enableBackgroundProcessing': true,
    'analysisInterval': 5000, // 5 seconds
  };
  
  // Error handling
  static const Map<String, String> errorMessages = {
    'network_error': 'Network connection error. Please check your internet connection.',
    'api_error': 'API service temporarily unavailable. Please try again later.',
    'permission_error': 'Screen capture permission required for analysis.',
    'model_error': 'AI model loading error. Please restart the app.',
    'analysis_error': 'Analysis failed. Please try again.',
    'timeout_error': 'Request timeout. Please check your connection.',
  };
  
  // Feature flags
  static const Map<String, bool> featureFlags = {
    'enableRealTimeData': true,
    'enableMarketSentiment': true,
    'enableMultiTimeframe': true,
    'enableRiskAssessment': true,
    'enableTradeSetup': true,
    'enableEconomicCalendar': true,
    'enableNewsAnalysis': true,
    'enableOfflineMode': true,
    'enableAdvancedPatterns': true,
    'enableHarmonicPatterns': false, // Coming soon
    'enableElliottWave': false, // Coming soon
  };
} 