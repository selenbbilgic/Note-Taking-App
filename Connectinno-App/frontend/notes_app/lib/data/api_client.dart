import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? details;

  ApiException(this.message, {this.statusCode, this.details});

  @override
  String toString() => message;
}

class ApiClient {
  final Dio _dio;
  ApiClient(String baseUrl)
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
        ),
      );

  Future<Response<T>> _authRequest<T>(
    Future<Response<T>> Function(String token) f,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    print('[ApiClient] Current user: ${user?.uid}');
    if (user == null) {
      throw ApiException(
        'Authentication required. Please sign in to continue.',
      );
    }

    try {
      final token = await user.getIdToken();
      print('[ApiClient] Got token: ${token?.substring(0, 20)}...');
      return f(token ?? "");
    } catch (e) {
      throw ApiException(
        'Failed to get authentication token. Please try signing in again.',
      );
    }
  }

  Future<Response<dynamic>> getNotes() async {
    try {
      return await _authRequest((t) {
        print(
          '[ApiClient] Making GET request to /notes with token: ${t.substring(0, 20)}...',
        );
        return _dio.get(
          '/notes',
          options: Options(headers: {'Authorization': 'Bearer $t'}),
        );
      });
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to fetch notes');
    }
  }

  Future<Response<dynamic>> createNote(
    String title,
    String content, {
    bool pinned = false,
  }) async {
    try {
      return await _authRequest(
        (t) => _dio.post(
          '/notes',
          data: {'title': title, 'content': content, 'pinned': pinned},
          options: Options(headers: {'Authorization': 'Bearer $t'}),
        ),
      );
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to create note');
    }
  }

  Future<Response<dynamic>> updateNote(
    String id, {
    String? title,
    String? content,
    bool? pinned,
  }) async {
    try {
      return await _authRequest((t) {
        final body = <String, dynamic>{
          'title': title,
          'content': content,
          'pinned': pinned,
        }..removeWhere((k, v) => v == null);
        return _dio.put(
          '/notes/$id',
          data: body,
          options: Options(headers: {'Authorization': 'Bearer $t'}),
        );
      });
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to update note');
    }
  }

  Future<Response<dynamic>> deleteNote(String id) async {
    try {
      return await _authRequest(
        (t) => _dio.delete(
          '/notes/$id',
          options: Options(headers: {'Authorization': 'Bearer $t'}),
        ),
      );
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to delete note');
    }
  }

  ApiException _handleDioException(DioException e, String operation) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          'Connection timeout. Please check your internet connection and try again.',
          statusCode: e.response?.statusCode,
        );
      case DioExceptionType.connectionError:
        return ApiException(
          'Unable to connect to the server. Please check your internet connection.',
          statusCode: e.response?.statusCode,
        );
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['detail'] ?? e.message;
        switch (statusCode) {
          case 401:
            return ApiException(
              'Authentication failed. Please sign in again.',
              statusCode: statusCode,
            );
          case 403:
            return ApiException(
              'Access denied. You don\'t have permission to perform this action.',
              statusCode: statusCode,
            );
          case 404:
            return ApiException(
              'The requested resource was not found.',
              statusCode: statusCode,
            );
          case 500:
            return ApiException(
              'Server error. Please try again later.',
              statusCode: statusCode,
            );
          default:
            return ApiException(
              '$operation. ${message ?? 'Please try again.'}',
              statusCode: statusCode,
            );
        }
      case DioExceptionType.cancel:
        return ApiException('Request was cancelled.');
      case DioExceptionType.unknown:
      default:
        return ApiException(
          '$operation. Please check your internet connection and try again.',
        );
    }
  }
}
