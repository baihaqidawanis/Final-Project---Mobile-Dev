import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../app_config.dart';

class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;

  const ChatMessage({required this.role, required this.content});

  Map<String, String> toJson() => {'role': role, 'content': content};
}

class GroqService {
  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.1-8b-instant';

  static const String _systemPrompt = '''
Kamu adalah Asisten Kesehatan Healink, sebuah aplikasi on-demand healthcare & caregiving di Indonesia.

Tugas kamu:
1. Membantu pengguna menentukan jenis caregiver yang dibutuhkan berdasarkan kondisi pasien
2. Memberikan saran umum tentang perawatan orang sakit atau lansia
3. Menjawab pertanyaan umum seputar kesehatan dalam Bahasa Indonesia

Aturan:
- Jawab dalam Bahasa Indonesia yang ramah dan mudah dimengerti
- Jangan memberikan diagnosis medis, selalu sarankan konsultasi dokter untuk masalah serius
- Jika ditanya spesialisasi caregiver, berikan rekomendasi spesifik (contoh: "Elderly Care", "Post-Surgery", "Physical Therapy")
- Jawaban singkat dan padat (maksimal 3-4 paragraf)
- Selalu akhiri dengan tindakan yang bisa dilakukan di aplikasi Healink (cari caregiver, dll)
''';

  /// Send a chat message and get a response from Groq.
  /// [history] is the previous messages in the conversation.
  Future<String> sendMessage({
    required String message,
    required List<ChatMessage> history,
  }) async {
    if (AppConfig.groqApiKey.isEmpty) {
      return '⚠️ API key Groq belum dikonfigurasi. Silakan tambahkan di AppConfig.';
    }

    final messages = [
      {'role': 'system', 'content': _systemPrompt},
      ...history.map((m) => m.toJson()),
      {'role': 'user', 'content': message},
    ];

    try {
      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Authorization': 'Bearer ${AppConfig.groqApiKey}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': _model,
              'messages': messages,
              'max_tokens': 500,
              'temperature': 0.7,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final content =
            data['choices']?[0]?['message']?['content'] as String? ?? '';
        return content.trim();
      } else if (response.statusCode == 401) {
        return '❌ API key tidak valid. Periksa kembali di AppConfig.groqApiKey';
      } else if (response.statusCode == 429) {
        return '⏳ Terlalu banyak permintaan. Coba lagi dalam beberapa detik.';
      } else {
        debugPrint('[Groq] Error ${response.statusCode}: ${response.body}');
        return '❌ Gagal menghubungi AI. Coba lagi.';
      }
    } catch (e) {
      debugPrint('[Groq] Exception: $e');
      return '❌ Koneksi bermasalah. Periksa internet kamu.';
    }
  }
}
