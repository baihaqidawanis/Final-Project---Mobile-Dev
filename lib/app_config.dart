import 'features/hospital_appointment/repositories/live_weather_repository.dart';
import 'features/hospital_appointment/repositories/weather_repository.dart';

class AppConfig {
  // Global switch to toggle between Live APIs and local configurations
  static const bool useRealApis = true;

  // ── Groq Cloud AI ──────────────────────────────────────────────────────────
  // Get your free API key at: https://console.groq.com → API Keys → Create API Key
  // Free tier: 30 req/min, 6000 token/min — lebih dari cukup untuk demo
  // ⚠️ Jangan commit key asli ke GitHub! Isi key asli hanya saat run lokal.
  static const String groqApiKey =
      ''; // TODO: INSERT_YOUR_API_KEY_HERE (Do not commit real keys!)

  // ── Supabase Configuration ───────────────────────────────────────────────
  static const String supabaseUrl = 'https://dwlavoryaptfwqyisrus.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_kA4t8ThCLZgwJWF8ps7PTw_SwFiI_ay';

  // Getter to retrieve the appropriate WeatherRepository
  static WeatherRepository get weatherRepository {
    return LiveWeatherRepository();
  }
}
