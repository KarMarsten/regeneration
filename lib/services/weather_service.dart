import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  WeatherService._();
  static final WeatherService instance = WeatherService._();

  /// Fetches current temperature in °F for the given US zip code.
  /// Uses wttr.in — no API key required.
  Future<double?> fetchTemperature(String zipcode) async {
    if (zipcode.trim().isEmpty) return null;
    try {
      final uri = Uri.parse(
          'https://wttr.in/${Uri.encodeComponent(zipcode)}?format=j1');
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final current = (json['current_condition'] as List?)?.first
          as Map<String, dynamic>?;
      if (current == null) return null;

      // temp_F is a string in wttr.in response
      final tempFStr = current['temp_F'] as String?;
      return tempFStr != null ? double.tryParse(tempFStr) : null;
    } catch (_) {
      return null;
    }
  }
}
