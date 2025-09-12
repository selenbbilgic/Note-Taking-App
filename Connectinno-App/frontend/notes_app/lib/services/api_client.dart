import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    if (user == null) {
      throw StateError('Not authenticated');
    }
    final token = await user.getIdToken();
    return f(token ?? "");
  }

  Future<Response<dynamic>> getNotes() => _authRequest(
    (t) => _dio.get(
      '/notes',
      options: Options(headers: {'Authorization': 'Bearer $t'}),
    ),
  );

  Future<Response<dynamic>> createNote(String title, String content) =>
      _authRequest(
        (t) => _dio.post(
          '/notes',
          data: {'title': title, 'content': content},
          options: Options(headers: {'Authorization': 'Bearer $t'}),
        ),
      );

  Future<Response<dynamic>> updateNote(
    String id, {
    String? title,
    String? content,
  }) => _authRequest(
    (t) => _dio.put(
      '/notes/$id',
      data: {'title': title, 'content': content},
      options: Options(headers: {'Authorization': 'Bearer $t'}),
    ),
  );

  Future<Response<dynamic>> deleteNote(String id) => _authRequest(
    (t) => _dio.delete(
      '/notes/$id',
      options: Options(headers: {'Authorization': 'Bearer $t'}),
    ),
  );
}
