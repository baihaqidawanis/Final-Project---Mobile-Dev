import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStorageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Uploads a file to the specified path inside the `healink-storage` bucket
  /// and returns the public URL of the uploaded file.
  Future<String> uploadFile({
    required File file,
    required String filePath,
  }) async {
    try {
      // 1. Upload the file to the bucket
      await _supabase.storage.from('healink-storage').upload(
            filePath,
            file,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      // 2. Get the public URL
      final String publicUrl =
          _supabase.storage.from('healink-storage').getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload file to Supabase: $e');
    }
  }
}
