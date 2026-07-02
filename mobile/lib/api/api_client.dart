import 'dart:async';

import 'package:dio/dio.dart';

import 'api_config.dart';
import 'token_storage.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          unawaited(_handleUnauthorized());
        }

        final data = error.response?.data;
        String message = 'Something went wrong. Please try again.';
        if (data is Map && data['message'] != null) {
          message = data['message'].toString();
        } else if (data is Map && data['errors'] is Map) {
          final errors = data['errors'] as Map;
          message = errors.values.first is List
              ? (errors.values.first as List).first.toString()
              : errors.values.first.toString();
        } else if (error.message != null) {
          message = error.message!;
        }
        handler.reject(DioException(
          requestOptions: error.requestOptions,
          response: error.response,
          message: message,
        ));
      },
    ));
  }

  late final Dio _dio;

  Future<void> Function()? onUnauthorized;

  Future<void> _handleUnauthorized() async {
    await clearToken();
    await onUnauthorized?.call();
  }

  Future<String?> _getToken() => TokenStorage.read();

  Future<void> saveToken(String token) => TokenStorage.write(token);

  Future<void> clearToken() => TokenStorage.clear();

  Future<bool> hasToken() => TokenStorage.hasToken();

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) async {
    try {
      final response = await _dio.get(path, queryParameters: query);
      return _asMap(response.data);
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'Request failed', statusCode: e.response?.statusCode);
    }
  }

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body}) async {
    try {
      final response = await _dio.post(path, data: body);
      return _asMap(response.data);
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'Request failed', statusCode: e.response?.statusCode);
    }
  }

  Future<Map<String, dynamic>> uploadFile(
    String path, {
    required String filePath,
    String fieldName = 'file',
  }) async {
    try {
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(filePath),
      });
      final response = await _dio.post(
        path,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return _asMap(response.data);
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'Upload failed', statusCode: e.response?.statusCode);
    }
  }

  Future<Map<String, dynamic>> patch(String path, {Map<String, dynamic>? body}) async {
    try {
      final response = await _dio.patch(path, data: body);
      return _asMap(response.data);
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'Request failed', statusCode: e.response?.statusCode);
    }
  }

  Future<void> delete(String path) async {
    try {
      await _dio.delete(path);
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'Request failed', statusCode: e.response?.statusCode);
    }
  }

  Future<List<Map<String, dynamic>>> getList(String path, {Map<String, dynamic>? query}) async {
    final data = await get(path, query: query);
    final items = data['data'];
    if (items is List) {
      return items
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {'data': data};
  }
}
