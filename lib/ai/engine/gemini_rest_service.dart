import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiRestService {
  final String _modelName = 'gemini-2.0-flash';

  Future<Map<String, dynamic>> generateContent({
    required String apiKey,
    required String systemInstruction,
    required List<Map<String, dynamic>> contents,
    required List<Map<String, dynamic>> tools,
  }) async {
    if (apiKey.isEmpty) {
      throw Exception("Gemini API key is empty");
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_modelName:generateContent?key=$apiKey',
    );

    final requestBody = {
      'contents': contents,
      'systemInstruction': {
        'parts': [
          {'text': systemInstruction}
        ]
      },
      'tools': tools.isNotEmpty ? [{'functionDeclarations': tools}] : null,
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 1000,
      }
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode != 200) {
      throw Exception("REST API Call failed: ${response.statusCode} - ${response.body}");
    }

    return jsonDecode(response.body);
  }
}
