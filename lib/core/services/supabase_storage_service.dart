import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../app_config.dart';

class SupabaseStorageService {
  static final SupabaseStorageService _instance = SupabaseStorageService._internal();
  factory SupabaseStorageService() => _instance;
  SupabaseStorageService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  /// Uploads raw file bytes to the configured Supabase storage bucket
  Future<String> uploadFile({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    try {
      final bucket = AppConfig.supabaseBucket;
      
      // Upload using Supabase storage Client
      await _client.storage.from(bucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: true,
            ),
          );

      // Return the public URL
      return getPublicUrl(path);
    } catch (e) {
      throw Exception('Failed to upload to Supabase: $e');
    }
  }

  /// Retrieves the public download/view URL for a specific file path
  String getPublicUrl(String path) {
    final bucket = AppConfig.supabaseBucket;
    return _client.storage.from(bucket).getPublicUrl(path);
  }
}
