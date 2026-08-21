import 'menu_item.dart';

// Represents one line in the cart: a MenuItem the user wants,
// plus how many of it. Kept separate from MenuItem itself since
// "how many" is cart-specific state, not something the backend's
// MenuItem data would ever include.
class CartItem {
  final MenuItem menuItem;
  int quantity;

  CartItem({
    required this.menuItem,
    this.quantity = 1,
  });

  // Convenience getter - price for this line (unit price × quantity),
  // used when calculating the cart's subtotal for display.
  double get lineTotal => menuItem.price * quantity;
}