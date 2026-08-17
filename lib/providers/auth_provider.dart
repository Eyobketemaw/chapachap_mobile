import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService;
  late final AuthService _authService;

  User? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider(this._apiService) {
    _authService = AuthService(_apiService);
  }

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.login(email, password);
      _currentUser = result['user'];
      _token = result['token'];
      _apiService.setToken(_token!);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.register(name, email, password);
      _currentUser = result['user'];
      _token = result['token'];
      _apiService.setToken(_token!);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _token = null;
    _apiService.clearToken();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');

    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('token');

    if (savedToken == null) {
      return;
    }

    _token = savedToken;
    _apiService.setToken(savedToken);

    try {
      _currentUser = await _authService.getMe();
      notifyListeners();
    } catch (e) {
      _token = null;
      _apiService.clearToken();
      await prefs.remove('token');
    }
  }
}
