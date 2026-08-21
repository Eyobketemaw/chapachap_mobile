import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];

  // Tracks which restaurant the current cart belongs to - enforces the
  // "one restaurant per cart" rule. Null means the cart is empty.
  int? _restaurantId;
  String? _restaurantName;

  List<CartItem> get items => _items;
  int? get restaurantId => _restaurantId;
  String? get restaurantName => _restaurantName;
  bool get isEmpty => _items.isEmpty;

  // Total number of individual items (not lines) - e.g. 2x Doro Wat +
  // 1x Tibs = 3, useful for a cart badge icon later.
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  // Sum of every line's total - what the user will actually pay
  // (before any backend-calculated fees, which we don't have yet).
  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.lineTotal);

  // Returns true if adding this item would conflict with an existing
  // different restaurant's items already in the cart - the UI uses this
  // to decide whether to show the "clear cart?" confirmation dialog.
  bool wouldConflictWithRestaurant(int newRestaurantId) {
    return _restaurantId != null && _restaurantId != newRestaurantId;
  }

  // Adds an item to the cart, or increases its quantity if it's already
  // there. Assumes the caller has already resolved any restaurant
  // conflict (via wouldConflictWithRestaurant + a confirmation dialog).
  void addItem(MenuItem menuItem, int restaurantId, String restaurantName) {
    // If the cart was empty, this item's restaurant becomes the cart's owner.
    _restaurantId = restaurantId;
    _restaurantName = restaurantName;

    // Check if this exact menu item is already in the cart.
    final existingIndex = _items.indexWhere((item) => item.menuItem.id == menuItem.id);

    if (existingIndex != -1) {
      _items[existingIndex].quantity++;
    } else {
      _items.add(CartItem(menuItem: menuItem));
    }

    notifyListeners();
  }

  void removeItem(int menuItemId) {
    _items.removeWhere((item) => item.menuItem.id == menuItemId);

    // If that was the last item, the cart is now empty - reset the
    // restaurant lock so a different restaurant can be added freely.
    if (_items.isEmpty) {
      _restaurantId = null;
      _restaurantName = null;
    }

    notifyListeners();
  }

  void updateQuantity(int menuItemId, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(menuItemId);
      return;
    }

    final index = _items.indexWhere((item) => item.menuItem.id == menuItemId);
    if (index != -1) {
      _items[index].quantity = newQuantity;
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    _restaurantId = null;
    _restaurantName = null;
    notifyListeners();
  }
}