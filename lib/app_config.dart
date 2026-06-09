import 'features/hospital_appointment/repositories/live_weather_repository.dart';
import 'features/hospital_appointment/repositories/weather_repository.dart';

class AppConfig {
  // Global switch to toggle between Live APIs and local configurations
  static const bool useRealApis = true;

  // Getter to retrieve the appropriate WeatherRepository
  static WeatherRepository get weatherRepository {
    return LiveWeatherRepository();
  }
}
