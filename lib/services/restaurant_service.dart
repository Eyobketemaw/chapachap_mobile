import 'dart:convert';
import 'api_service.dart';
import '../models/restaurant.dart';
import '../models/menu_item.dart';

// Handles all restaurant/menu-related API calls, mirroring the pattern
// already established by AuthService - takes ApiService via constructor
// dependency injection, throws Exceptions with backend error messages.
class RestaurantService {
  final ApiService _apiService;

  RestaurantService(this._apiService);

  // GET /api/restaurants - list all restaurants (paginated on the backend,
  // but for MVP we just take the first page/default limit and show that)
  Future<List<Restaurant>> getAllRestaurants() async {
    final response = await _apiService.get('/api/restaurants');
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      // data['data'] is a JSON array - map each item through
      // Restaurant.fromJson to get a typed List<Restaurant>
      final List<dynamic> restaurantsJson = data['data'];
      return restaurantsJson.map((json) => Restaurant.fromJson(json)).toList();
    } else {
      throw Exception(data['message'] ?? 'Failed to load restaurants');
    }
  }

  // GET /api/restaurants/:id - single restaurant WITH its menu items
  // already nested inside (confirmed earlier in Postman testing) - so
  // this one call gives us everything the Restaurant Details screen needs.
  Future<Map<String, dynamic>> getRestaurantWithMenu(int restaurantId) async {
    final response = await _apiService.get('/api/restaurants/$restaurantId');
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      final restaurant = Restaurant.fromJson(data['data']);

      final List<dynamic> menuItemsJson = data['data']['menuItems'] ?? [];
      final menuItems = menuItemsJson
          .map((json) => MenuItem.fromJson(json))
          .toList();

      return {'restaurant': restaurant, 'menuItems': menuItems};
    } else {
      throw Exception(data['message'] ?? 'Failed to load restaurant');
    }
  }
}
