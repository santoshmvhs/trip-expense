import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyService {
  // Free tier API - you can upgrade to a paid service for better rates
  static const String _baseUrl = 'https://api.exchangerate-api.com/v4/latest';

  static Future<double> convertCurrency({
    required double amount,
    required String from,
    required String to,
  }) async {
    if (from == to) return amount;

    try {
      final response = await http.get(Uri.parse('$_baseUrl/$from'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;
        final rate = rates[to] as double?;
        
        if (rate != null) {
          return amount * rate;
        }
      }
    } catch (e) {
      // Fallback: return original amount if conversion fails
      return amount;
    }

    return amount;
  }

  static Future<Map<String, double>> getExchangeRates(String baseCurrency) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/$baseCurrency'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Map<String, double>.from(data['rates'] as Map);
      }
    } catch (e) {
      // Return empty map if fetch fails
    }

    return {};
  }
}

