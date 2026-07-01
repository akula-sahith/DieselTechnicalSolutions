import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize in main.dart first');
});

final apiBaseUrlProvider = StateNotifierProvider<ApiBaseUrlNotifier, String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ApiBaseUrlNotifier(prefs);
});

class ApiBaseUrlNotifier extends StateNotifier<String> {
  final SharedPreferences _prefs;
  static const String _baseUrlKey = 'custom_base_url';

  ApiBaseUrlNotifier(this._prefs) : super('') {
    _loadBaseUrl();
  }

  void _loadBaseUrl() {
    final savedUrl = _prefs.getString(_baseUrlKey);
    if (savedUrl != null && savedUrl.isNotEmpty) {
      state = savedUrl;
    } else {
      if (kIsWeb) {
        state = ApiConstants.defaultIosBaseUrl;
      } else {
        state = Platform.isAndroid 
            ? ApiConstants.defaultAndroidBaseUrl 
            : ApiConstants.defaultIosBaseUrl;
      }
    }
  }

  Future<void> updateBaseUrl(String newUrl) async {
    if (newUrl.isEmpty) {
      await _prefs.remove(_baseUrlKey);
    } else {
      await _prefs.setString(_baseUrlKey, newUrl);
    }
    _loadBaseUrl();
  }
}

final apiServiceProvider = Provider<ApiService>((ref) {
  final baseUrl = ref.watch(apiBaseUrlProvider);
  return ApiService(baseUrl);
});

class ApiService {
  late final Dio _dio;

  ApiService(String baseUrl) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (kDebugMode) {
            print('--> ${options.method} ${options.uri}');
            print('Headers: ${options.headers}');
            if (options.data != null) {
              if (options.data is FormData) {
                final formData = options.data as FormData;
                print('FormData Fields: ${formData.fields}');
                print('FormData Files: ${formData.files.map((e) => '${e.key}: ${e.value.filename}')}');
              } else {
                print('Body: ${options.data}');
              }
            }
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            print('<-- ${response.statusCode} ${response.requestOptions.uri}');
            print('Response: ${response.data}');
          }
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          if (kDebugMode) {
            print('<-- ERROR ${e.response?.statusCode} ${e.requestOptions.uri}');
            print('Error details: ${e.response?.data ?? e.message}');
          }
          return handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;

  // Standard helper methods
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.post(path, data: data, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> put(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.put(path, data: data, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> delete(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.delete(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException error) {
    String message = 'An unexpected error occurred.';
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      message = 'Connection timed out. Please check your network or server IP.';
    } else if (error.type == DioExceptionType.connectionError) {
      message = 'Failed to connect to the server. Please verify the backend is running.';
    } else if (error.response != null) {
      final responseData = error.response?.data;
      if (responseData is Map && responseData.containsKey('message')) {
        message = responseData['message'] ?? message;
      } else {
        message = 'Server responded with status code: ${error.response?.statusCode}';
      }
    }
    return ApiException(message);
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
