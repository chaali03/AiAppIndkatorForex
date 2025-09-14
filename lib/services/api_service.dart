import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import '../utils/logger.dart';

class ApiService {
  static final Dio _dio = Dio();
  static const String _alphaVantageApiKey = 'YOUR_ALPHA_VANTAGE_API_KEY';
  static const String _tradingViewApiUrl = 'https://scanner.tradingview.com/forex/scan';

  // Alpha Vantage API for real-time forex data
  static Future<Map<String, dynamic>> getRealTimeForexData(String fromCurrency, String toCurrency) async {
    try {
      final response = await http.get(Uri.parse(
        'https://www.alphavantage.co/query?function=CURRENCY_EXCHANGE_RATE&from_currency=$fromCurrency&to_currency=$toCurrency&apikey=$_alphaVantageApiKey'
      ));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['Realtime Currency Exchange Rate'] ?? {};
      }
    } catch (e) {
      Logger.error('Error fetching real-time forex data: $e', 'API_SERVICE', e);
    }
    return {};
  }

  // Alpha Vantage API for technical indicators
  static Future<Map<String, dynamic>> getTechnicalIndicators(String symbol, String function) async {
    try {
      final response = await http.get(Uri.parse(
        'https://www.alphavantage.co/query?function=$function&symbol=$symbol&interval=5min&apikey=$_alphaVantageApiKey'
      ));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      Logger.error('Error fetching technical indicators: $e', 'API_SERVICE', e);
    }
    return {};
  }

  // TradingView API for advanced technical analysis
  static Future<Map<String, dynamic>> getTradingViewAnalysis(String symbol) async {
    try {
      final response = await _dio.post(_tradingViewApiUrl, data: {
        "symbols": {"tickers": [symbol]},
        "columns": [
          "Recommend.Other",
          "Recommend.All", 
          "Recommend.MA",
          "RSI",
          "RSI[1]",
          "Stoch.K",
          "Stoch.D",
          "Stoch.K[1]",
          "Stoch.D[1]",
          "MACD.macd",
          "MACD.signal",
          "BB.basis",
          "BB.upper",
          "BB.lower",
          "ADX",
          "ADX+DI",
          "ADX-DI",
          "CCI20",
          "Williams%R",
          "Volatility.D"
        ]
      });
      
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      Logger.error('Error fetching TradingView analysis: $e', 'API_SERVICE', e);
    }
    return {};
  }

  // Forex Factory API for economic calendar
  static Future<List<Map<String, dynamic>>> getEconomicCalendar() async {
    try {
      final response = await http.get(Uri.parse(
        'https://www.forexfactory.com/api/calendar'
      ));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['events'] ?? []);
      }
    } catch (e) {
      Logger.error('Error fetching economic calendar: $e', 'API_SERVICE', e);
    }
    return [];
  }

  // News API for market sentiment
  static Future<List<Map<String, dynamic>>> getForexNews() async {
    try {
      final response = await http.get(Uri.parse(
        'https://newsapi.org/v2/everything?q=forex&language=en&sortBy=publishedAt&apiKey=YOUR_NEWS_API_KEY'
      ));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['articles'] ?? []);
      }
    } catch (e) {
      Logger.error('Error fetching forex news: $e', 'API_SERVICE', e);
    }
    return [];
  }

  // Market sentiment analysis
  static Future<Map<String, dynamic>> analyzeMarketSentiment(String currencyPair) async {
    try {
      // Get multiple data sources
      final forexData = await getRealTimeForexData(
        currencyPair.split('/')[0], 
        currencyPair.split('/')[1]
      );
      
      final tvAnalysis = await getTradingViewAnalysis(currencyPair);
      final news = await getForexNews();
      
      // Calculate sentiment score
      double sentimentScore = 0.0;
      int bullishSignals = 0;
      int bearishSignals = 0;
      
      // Analyze TradingView recommendations
      if (tvAnalysis.isNotEmpty && tvAnalysis['data'] != null) {
        final data = tvAnalysis['data'][0];
        final recommendAll = data['d'][1]; // Recommend.All
        final recommendMA = data['d'][2]; // Recommend.MA
        
        if (recommendAll != null) {
          if (recommendAll > 0.5) {
            bullishSignals++;
          } else if (recommendAll < -0.5) {
            bearishSignals++;
          }
        }
        
        if (recommendMA != null) {
          if (recommendMA > 0.5) {
            bullishSignals++;
          } else if (recommendMA < -0.5) {
            bearishSignals++;
          }
        }
      }
      
      // Analyze news sentiment
      for (final article in news.take(10)) {
        final title = article['title']?.toString().toLowerCase() ?? '';
        final content = article['description']?.toString().toLowerCase() ?? '';
        
        if (title.contains('bullish') || content.contains('bullish') ||
            title.contains('strong') || content.contains('strong') ||
            title.contains('gain') || content.contains('gain')) {
          bullishSignals++;
        }
        
        if (title.contains('bearish') || content.contains('bearish') ||
            title.contains('weak') || content.contains('weak') ||
            title.contains('fall') || content.contains('fall')) {
          bearishSignals++;
        }
      }
      
      // Calculate final sentiment
      final totalSignals = bullishSignals + bearishSignals;
      if (totalSignals > 0) {
        sentimentScore = (bullishSignals - bearishSignals) / totalSignals;
      }
      
      return {
        'sentiment_score': sentimentScore,
        'bullish_signals': bullishSignals,
        'bearish_signals': bearishSignals,
        'total_signals': totalSignals,
        'forex_data': forexData,
        'tradingview_analysis': tvAnalysis,
        'news_count': news.length,
      };
      
    } catch (e) {
      Logger.error('Error analyzing market sentiment: $e', 'API_SERVICE', e);
      return {
        'sentiment_score': 0.0,
        'bullish_signals': 0,
        'bearish_signals': 0,
        'total_signals': 0,
        'error': e.toString(),
      };
    }
  }

  // Advanced pattern recognition with multiple timeframes
  static Future<Map<String, dynamic>> getMultiTimeframeAnalysis(String symbol) async {
    final timeframes = ['1m', '5m', '15m', '1h', '4h', '1d'];
    final results = <String, Map<String, dynamic>>{};
    
    for (final timeframe in timeframes) {
      try {
        final response = await _dio.post(_tradingViewApiUrl, data: {
          "symbols": {"tickers": ["$symbol:$timeframe"]},
          "columns": [
            "Recommend.Other",
            "Recommend.All",
            "RSI",
            "Stoch.K",
            "MACD.macd",
            "BB.basis",
            "BB.upper",
            "BB.lower"
          ]
        });
        
        if (response.statusCode == 200 && response.data['data'] != null) {
          results[timeframe] = response.data;
        }
      } catch (e) {
        Logger.error('Error fetching $timeframe analysis: $e', 'API_SERVICE', e);
      }
    }
    
    return {
      'timeframes': results,
      'summary': _calculateMultiTimeframeSummary(results),
    };
  }

  static Map<String, dynamic> _calculateMultiTimeframeSummary(Map<String, Map<String, dynamic>> timeframes) {
    double totalBullish = 0;
    double totalBearish = 0;
    int validTimeframes = 0;
    
    for (final entry in timeframes.entries) {
      final data = entry.value;
      if (data['data'] != null && data['data'].isNotEmpty) {
        final recommendAll = data['data'][0]['d'][1];
        if (recommendAll != null) {
          if (recommendAll > 0) {
            totalBullish += recommendAll;
          } else {
            totalBearish += recommendAll.abs();
          }
          validTimeframes++;
        }
      }
    }
    
    if (validTimeframes == 0) {
      return {
        'overall_signal': 'neutral',
        'confidence': 0.0,
        'bullish_strength': 0.0,
        'bearish_strength': 0.0,
      };
    }
    
    final overallSignal = totalBullish > totalBearish ? 'bullish' : 'bearish';
    final confidence = (totalBullish + totalBearish) / validTimeframes;
    final bullishStrength = totalBullish / validTimeframes;
    final bearishStrength = totalBearish / validTimeframes;
    
    return {
      'overall_signal': overallSignal,
      'confidence': confidence,
      'bullish_strength': bullishStrength,
      'bearish_strength': bearishStrength,
      'timeframes_analyzed': validTimeframes,
    };
  }
} 