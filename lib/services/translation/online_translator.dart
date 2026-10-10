import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../logic/interpreter_prompt.dart';
import '../../logic/sse_text.dart';
import '../../models/settings.dart';
import 'translation_engine.dart';

class OnlineTranslator implements TranslationEngine {
  OnlineTranslator({required this.client, required this.settings});

  final http.Client client;
  final AppSettings Function() settings;

  @override
  Stream<String> translate(TranslationRequest request) async* {
    if (request.from.code == request.to.code) {
      yield request.text;
      return;
    }
    final current = settings();
    if (current.apiKey.trim().isEmpty) {
      throw TranslationException('Chưa có API key. Mở Cài đặt và nhập khóa Gemini hoặc OpenAI.');
    }
    final prompt = buildInterpreterPrompt(
      sourceLanguage: request.from.name,
      targetLanguage: request.to.name,
      utterance: request.text,
      context: request.context,
    );
    if (current.provider == AiProvider.gemini) {
      yield* _gemini(current, prompt);
    } else {
      yield* _openai(current, prompt);
    }
  }

  Stream<String> _gemini(AppSettings current, InterpreterPrompt prompt) async* {
    final model = current.geminiModel.trim().isEmpty ? 'gemini-2.5-flash' : current.geminiModel.trim();
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:streamGenerateContent?alt=sse',
    );
    final body = <String, dynamic>{
      'systemInstruction': {
        'parts': [
          {'text': prompt.system},
        ],
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': prompt.user},
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.2,
        'maxOutputTokens': 256,
        'thinkingConfig': {'thinkingBudget': 0},
      },
    };
    try {
      yield* _stream(
        uri: uri,
        headers: {'Content-Type': 'application/json', 'x-goog-api-key': current.apiKey.trim()},
        body: body,
        pick: textFromGeminiEvent,
      );
    } on TranslationException catch (error) {
      if (!error.message.toLowerCase().contains('thinking')) rethrow;
      body['generationConfig'] = {'temperature': 0.2, 'maxOutputTokens': 256};
      yield* _stream(
        uri: uri,
        headers: {'Content-Type': 'application/json', 'x-goog-api-key': current.apiKey.trim()},
        body: body,
        pick: textFromGeminiEvent,
      );
    }
  }

  Stream<String> _openai(AppSettings current, InterpreterPrompt prompt) async* {
    final root = current.openAiBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$root/chat/completions');
    final model = current.openAiModel.trim().isEmpty ? 'gpt-4o-mini' : current.openAiModel.trim();
    yield* _stream(
      uri: uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${current.apiKey.trim()}',
      },
      body: {
        'model': model,
        'temperature': 0.2,
        'max_tokens': 256,
        'stream': true,
        'messages': [
          {'role': 'system', 'content': prompt.system},
          {'role': 'user', 'content': prompt.user},
        ],
      },
      pick: textFromOpenAiEvent,
    );
  }

  Stream<String> _stream({
    required Uri uri,
    required Map<String, String> headers,
    required Map<String, dynamic> body,
    required String? Function(Map<String, dynamic> json) pick,
  }) async* {
    final request = http.Request('POST', uri)
      ..headers.addAll(headers)
      ..body = jsonEncode(body);
    final http.StreamedResponse response;
    try {
      response = await client.send(request).timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw TranslationException('AI phản hồi quá chậm. Kiểm tra mạng hoặc đổi sang mô hình nhanh hơn.');
    } catch (error) {
      throw TranslationException('Không kết nối được máy chủ dịch: $error');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final raw = await response.stream.bytesToString();
      throw TranslationException(_httpError(response.statusCode, raw));
    }
    await for (final line in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
      final data = _data(line);
      if (data == null) continue;
      if (data == '[DONE]') break;
      if (!data.startsWith('{')) continue;
      final decoded = jsonDecode(data);
      if (decoded is! Map) continue;
      final json = decoded.cast<String, dynamic>();
      final text = pick(json);
      if (text != null && text.isNotEmpty) yield text;
    }
  }

  String? _data(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith(':')) return null;
    if (trimmed.startsWith('data:')) return trimmed.substring(5).trim();
    return trimmed;
  }

  String _httpError(int status, String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final message = errorMessageFromBody(decoded.cast<String, dynamic>());
        if (message != null && message.isNotEmpty) return message;
      }
    } catch (_) {}
    if (status == 400 && raw.toLowerCase().contains('thinking')) return 'thinking';
    if (status == 401 || status == 403) return 'API key bị từ chối. Kiểm tra lại khóa trong Cài đặt.';
    return 'Máy chủ dịch trả về lỗi $status.';
  }
}
