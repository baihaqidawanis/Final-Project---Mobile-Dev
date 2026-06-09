import 'dart:convert';
import 'package:http/http.dart' as http;
import 'weather_repository.dart';

class LiveWeatherRepository implements WeatherRepository {
  // Placeholder API Key (to be configured in constants later)
  final String _apiKey = '4ac38ecff93e440072b2b487e83f2e2e';

  @override
  Future<String> getWeatherForDate(String dateString) async {
    try {
      // Fetching default location (Jakarta) current weather metrics
      final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?q=Jakarta&appid=$_apiKey&units=metric',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final temp = data['main']['temp'];
        final description = data['weather'][0]['description'] as String?;

        final descFormatted = description != null && description.isNotEmpty
            ? "${description[0].toUpperCase()}${description.substring(1)}"
            : "Unknown";

        return '$descFormatted, ${temp.toStringAsFixed(1)}°C';
      } else {
        return 'Weather data unavailable';
      }
    } catch (e) {
      return 'Weather data unavailable';
    }
  }
}
