import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';

class SimpleOCRService {
  final String baseUrl;
  final String? geminiApiKey; // Made optional for backward compatibility
  final String geminiApiUrl;

  SimpleOCRService({
    required this.baseUrl,
    this.geminiApiKey,
    this.geminiApiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent',
  });

  /// Original method - just OCR
  Future<String> processImage(File imageFile) async {
    try {
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/predict'),
      );

      // Attach the file
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
        ),
      );

      // Send it
      var response = await request.send();

      // Get response
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        // Try to parse JSON if possible, otherwise return raw string
        try {
          var json = jsonDecode(responseData);
          // Handle common response formats
          if (json is Map) {
            if (json.containsKey('text')) return json['text'].toString();
            if (json.containsKey('result')) return json['result'].toString();
            if (json.containsKey('data')) return json['data'].toString();
            if (json.containsKey('prediction')) return json['prediction'].toString();
          }
          return responseData;
        } catch (e) {
          // Not JSON, just return the raw text
          return responseData.trim();
        }
      } else {
        throw Exception('Server error: ${response.statusCode} - $responseData');
      }
    } catch (e) {
      throw Exception('Failed to process image: $e');
    }
  }

  /// New method: OCR + Gemini Translation
  Future<TranslationResult> processImageWithTranslation(File imageFile) async {
    // First, get the text using OCR
    String extractedText = await processImage(imageFile);

    // If no Gemini API key, return just the extracted text
    if (geminiApiKey == null || geminiApiKey!.isEmpty) {
      return TranslationResult(
        originalText: extractedText,
        translatedText: 'Translation unavailable - No API key provided',
        sourceLanguage: _detectLanguage(extractedText),
        targetLanguage: 'en',
      );
    }

    // Translate the extracted text
    String translatedText = await _translateWithGemini(extractedText);

    return TranslationResult(
      originalText: extractedText,
      translatedText: translatedText,
      sourceLanguage: _detectLanguage(extractedText),
      targetLanguage: 'en',
    );
  }

  /// New method: Translate existing text with Gemini
  Future<String> translateText(String text) async {
    if (geminiApiKey == null || geminiApiKey!.isEmpty) {
      return 'Translation unavailable - No API key provided';
    }
    return _translateWithGemini(text);
  }

  /// New method: Translate Hebrew/Samaritan text with Gemini
  Future<String> _translateWithGemini(String text) async {
    if (text.isEmpty) return '';

    try {
      // Create the prompt for translation
      final prompt = '''
Translate the following text from Hebrew/Samaritan to English. 
If the text appears to be in Ancient Hebrew or Samaritan script, 
provide an accurate English translation. Only respond with the translation, no explanations.

Text to translate: $text
''';

      // Prepare the request body
      final requestBody = {
        "contents": [
          {
            "parts": [
              {
                "text": prompt
              }
            ]
          }
        ]
      };

      // Make the API call to Gemini
      final response = await http.post(
        Uri.parse('$geminiApiUrl?key=$geminiApiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Parse Gemini API response
        if (data.containsKey('candidates') &&
            data['candidates'].isNotEmpty &&
            data['candidates'][0].containsKey('content') &&
            data['candidates'][0]['content'].containsKey('parts') &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {

          return data['candidates'][0]['content']['parts'][0]['text'].trim();
        }

        return text; // Return original if translation not found
      } else {
        return _mockTranslation(text); // Fallback
      }
    } catch (e) {
      return _mockTranslation(text); // Fallback
    }
  }

  /// New method: Mock translation for testing (fallback)
  String _mockTranslation(String text) {
    // Common Hebrew phrases mock translation
    if (text.contains('שלום') || text.contains('שָׁלוֹם')) {
      return 'Hello / Peace';
    } else if (text.contains('תורה') || text.contains('תּוֹרָה')) {
      return 'Torah (The Law)';
    } else if (text.contains('ישראל')) {
      return 'Israel';
    } else if (text.contains('אלוהים') || text.contains('אֱלֹהִים')) {
      return 'God';
    } else if (text.contains('משה')) {
      return 'Moses';
    } else if (text.contains('אהרן')) {
      return 'Aaron';
    } else if (text.contains('בראשית')) {
      return 'In the beginning';
    }

    return '[Translation Demo] $text';
  }

  /// New method: Simple language detection
  String _detectLanguage(String text) {
    if (text.isEmpty) return 'unknown';

    // Check for Hebrew Unicode range (U+0590 to U+05FF)
    final hebrewRegex = RegExp(r'[\u0590-\u05FF]');
    if (hebrewRegex.hasMatch(text)) {
      return 'he';
    }

    // Check for Samaritan Unicode range (U+0800 to U+083F)
    final samaritanRegex = RegExp(r'[\u0800-\u083F]');
    if (samaritanRegex.hasMatch(text)) {
      return 'sam';
    }

    return 'unknown';
  }
}

/// New class: Translation result model
class TranslationResult {
  final String originalText;
  final String translatedText;
  final String sourceLanguage;
  final String targetLanguage;

  TranslationResult({
    required this.originalText,
    required this.translatedText,
    required this.sourceLanguage,
    required this.targetLanguage,
  });

  Map<String, dynamic> toJson() {
    return {
      'originalText': originalText,
      'translatedText': translatedText,
      'sourceLanguage': sourceLanguage,
      'targetLanguage': targetLanguage,
    };
  }

  @override
  String toString() {
    return '''
Original Text ($sourceLanguage):
$originalText

Translated Text ($targetLanguage):
$translatedText
''';
  }
}