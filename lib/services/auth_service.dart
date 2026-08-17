import 'dart:convert';
import 'api_service.dart';
import '../models/user.dart';

class AuthService {
  final ApiService _apiService;

  AuthService(this._apiService);

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _apiService.post('/api/auth/login', {
      'email': email,
      'password': password,
    });

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      final user = User.fromJson(data['data']['user']);
      final token = data['data']['token'];
      return {'user': user, 'token': token};
    } else {
      throw Exception(data['message'] ?? 'Login failed');
    }
  }

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    final response = await _apiService.post('/api/auth/register', {
      'name': name,
      'email': email,
      'password': password,
      'role': 'customer',
    });

    final data = jsonDecode(response.body);

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        data['success'] == true) {
      final user = User.fromJson(data['data']['user']);
      final token = data['data']['token'];
      return {'user': user, 'token': token};
    } else {
      throw Exception(data['message'] ?? 'Registration failed');
    }
  }

  Future<User> getMe() async {
    final response = await _apiService.get('/api/auth/me');
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return User.fromJson(data['data']['user']);
    } else {
      throw Exception(data['message'] ?? 'Failed to fetch user');
    }
  }
}
