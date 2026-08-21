import 'dart:convert';
import 'api_service.dart';
import '../models/cart_item.dart';

class OrderService {
  final ApiService _apiService;

  OrderService(this._apiService);

  Future<void> placeOrder(int restaurantId, List<CartItem> items) async {
    final response = await _apiService.post('/api/orders', {
      'restaurantId': restaurantId,
      'items': items
          .map((cartItem) => {
                'menuItemId': cartItem.menuItem.id,
                'quantity': cartItem.quantity,
              })
          .toList(),
    });

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    } else {
      throw Exception(data['message'] ?? 'Failed to place order');
    }
  }
}