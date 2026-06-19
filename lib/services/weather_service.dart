import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherData {
  final double current;
  final double? high;
  final double? low;

  const WeatherData({required this.current, this.high, this.low});
}

class WeatherService {
  WeatherService._();
  static final WeatherService instance = WeatherService._();

  /// Fetches current temperature + daily high/low in °F for the given US zip.
  /// Uses wttr.in — no API key required.
  Future<WeatherData?> fetchWeather(String zipcode) async {
    if (zipcode.trim().isEmpty) return null;
    try {
      final uri = Uri.parse(
          'https://wttr.in/${Uri.encodeComponent(zipcode)}?format=j1');
      final response =
          await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      // Current temperature
      final current =
          (json['current_condition'] as List?)?.first as Map<String, dynamic>?;
      if (current == null) return null;
      final currentTemp =
          double.tryParse(current['temp_F'] as String? ?? '');
      if (currentTemp == null) return null;

      // Today's high/low (weather[0] = today)
      final weatherList = json['weather'] as List?;
      double? high, low;
      if (weatherList != null && weatherList.isNotEmpty) {
        final today = weatherList[0] as Map<String, dynamic>;
        high = double.tryParse(today['maxtempF'] as String? ?? '');
        low = double.tryParse(today['mintempF'] as String? ?? '');
      }

      return WeatherData(current: currentTemp, high: high, low: low);
    } catch (_) {
      return null;
    }
  }

  /// Convenience — returns only current °F (used by legacy callers).
  Future<double?> fetchTemperature(String zipcode) async {
    return (await fetchWeather(zipcode))?.current;
  }
}
