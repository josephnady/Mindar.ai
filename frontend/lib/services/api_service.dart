import 'package:dio/dio.dart';
import '../models/event_type.dart';
import '../models/mind_event.dart';
import 'token_storage.dart';

/// Thin client around the Mindar Spring Boot API. Point [baseUrl] at your
/// deployed backend (or 10.0.2.2 for the Android emulator talking to
/// localhost, or localhost for iOS simulator).
class ApiService {
  ApiService({String? baseUrl}) : _baseUrl = baseUrl ?? const String.fromEnvironment(
          'MINDAR_API_BASE_URL',
          defaultValue: 'http://10.0.2.2:8080/api',
        ) {
    _dio = Dio(BaseOptions(baseUrl: _baseUrl, connectTimeout: const Duration(seconds: 10)));
    _dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) async {
      final token = await _tokenStorage.readToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    }));
  }

  final String _baseUrl;
  late final Dio _dio;
  final TokenStorage _tokenStorage = TokenStorage();

  // --- Auth ---

  Future<String> register({required String name, required String email, required String password}) async {
    final res = await _dio.post('/auth/register', data: {
      'displayName': name,
      'email': email,
      'password': password,
    });
    final token = res.data['token'] as String;
    await _tokenStorage.saveToken(token);
    return token;
  }

  Future<String> login({required String email, required String password}) async {
    final res = await _dio.post('/auth/login', data: {'email': email, 'password': password});
    final token = res.data['token'] as String;
    await _tokenStorage.saveToken(token);
    return token;
  }

  Future<void> logout() => _tokenStorage.clear();

  Future<bool> hasSession() async => (await _tokenStorage.readToken()) != null;

  // --- Events ---

  Future<List<MindEvent>> getEventsForRange(DateTime start, DateTime end) async {
    final res = await _dio.get('/events', queryParameters: {
      'start': _isoDate(start),
      'end': _isoDate(end),
    });
    return (res.data as List).map((j) => MindEvent.fromJson(j)).toList();
  }

  Future<List<MindEvent>> getEventsForDay(DateTime day) async {
    final res = await _dio.get('/events/day/${_isoDate(day)}');
    return (res.data as List).map((j) => MindEvent.fromJson(j)).toList();
  }

  Future<MindEvent> createEvent({
    required EventType type,
    required DateTime date,
    required String transcript,
    String? title,
  }) async {
    final event = MindEvent(eventType: type, eventDate: date, title: title ?? '', transcript: transcript);
    final res = await _dio.post('/events', data: event.toCreateJson());
    return MindEvent.fromJson(res.data);
  }

  Future<void> deleteEvent(int id) => _dio.delete('/events/$id');

  Future<MindEvent> toggleTodoComplete(int id, bool completed) async {
    final res = await _dio.patch('/events/$id', data: {'completed': completed});
    return MindEvent.fromJson(res.data);
  }

  String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
