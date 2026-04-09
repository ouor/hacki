import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';

class TranslationService with Loggable {
  TranslationService({
    PreferenceRepository? preferenceRepository,
    Dio? dio,
  })  : _preferenceRepository =
            preferenceRepository ?? locator.get<PreferenceRepository>(),
        _dio = dio ?? Dio();

  final PreferenceRepository _preferenceRepository;
  final Dio _dio;

  static final Map<String, String> _cache = <String, String>{};

  Future<String> translate({
    required String text,
  }) async {
    final String normalizedText = text.trim();
    if (normalizedText.isEmpty) {
      throw AppException(message: 'Nothing to translate.');
    }

    final TranslationConfig config =
        await _preferenceRepository.getTranslationConfig();
    if (!config.isConfigured) {
      throw AppException(
        message: 'Translation settings are incomplete.',
      );
    }

    final String cacheKey = jsonEncode(<String, String>{
      'baseUrl': config.baseUrl.trim(),
      'modelName': config.modelName.trim(),
      'translatePrompt': config.translatePrompt.trim(),
      'text': normalizedText,
    });

    final String? cached = _cache[cacheKey];
    if (cached != null) {
      return cached;
    }

    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        config.baseUrl.trim(),
        data: <String, dynamic>{
          'model': config.modelName.trim(),
          'messages': <Map<String, String>>[
            <String, String>{
              'role': 'system',
              'content': config.translatePrompt.trim(),
            },
            <String, String>{
              'role': 'user',
              'content': normalizedText,
            },
          ],
          'stream': false,
        },
        options: Options(
          headers: <String, String>{
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${config.apiKey.trim()}',
          },
        ),
      );

      final dynamic data = response.data;
      final dynamic choices = data is Map<String, dynamic> ? data['choices'] : null;
      final dynamic firstChoice =
          choices is List<dynamic> && choices.isNotEmpty ? choices.first : null;
      final dynamic message =
          firstChoice is Map<String, dynamic> ? firstChoice['message'] : null;
      final dynamic content =
          message is Map<String, dynamic> ? message['content'] : null;
      final String translatedText = (content as String? ?? '').trim();

      if (translatedText.isEmpty) {
        throw AppException(message: 'Translation response was empty.');
      }

      _cache[cacheKey] = translatedText;
      return translatedText;
    } on DioException catch (error, stackTrace) {
      logError(error, stackTrace: stackTrace);
      final String? serverMessage = switch (error.response?.data) {
        {'error': {'message': final String message}} => message,
        {'message': final String message} => message,
        _ => null,
      };
      throw AppException(
        message: serverMessage ?? 'Translation request failed.',
        error: error,
        stackTrace: stackTrace,
      );
    } on AppException {
      rethrow;
    } catch (error, stackTrace) {
      logError(error, stackTrace: stackTrace);
      throw AppException(
        message: 'Translation failed.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
