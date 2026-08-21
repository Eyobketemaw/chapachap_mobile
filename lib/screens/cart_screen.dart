import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../models/cart_item.dart';
import '../services/order_service.dart';

// Shows the current cart contents. Uses Consumer to rebuild whenever
// CartProvider changes (quantity adjusted, item removed, etc.) -
// no local state needed here, since everything lives in CartProvider.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('Your Order'),
        backgroundColor: const Color(0xFFB8342A),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              if (cart.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => cart.clearCart(),
                child: const Text(
                  'Clear All',
                  style: TextStyle(color: Colors.white),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.isEmpty) {
            return const Center(
              child: Text(
                'Your cart is empty.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final cartItem = cart.items[index];
                    return _CartItemTile(cartItem: cartItem);
                  },
                ),
              ),
              _CartSummary(cart: cart),
            ],
          );
        },
      ),
    );
  }
}

class _CartSummary extends StatefulWidget {
  final CartProvider cart;

  const _CartSummary({required this.cart});

  @override
  State<_CartSummary> createState() => _CartSummaryState();
}

class _CartSummaryState extends State<_CartSummary> {
  // Local state just for this button's loading/error handling -
  // doesn't belong in CartProvider itself, since CartProvider
  // represents "what's in the cart," not "is an order being placed."
  bool _isPlacingOrder = false;
  String? _error;

  Future<void> _placeOrder() async {
    setState(() {
      _isPlacingOrder = true;
      _error = null;
    });

    try {
      final orderService = context.read<OrderService>();
      await orderService.placeOrder(
        widget.cart.restaurantId!,
        widget.cart.items,
      );

      if (mounted) {
        widget.cart.clearCart();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // TODO: navigate to an Order Status screen once Phase 5 exists
        Navigator.pop(context); // for now, just return to the previous screen
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isPlacingOrder = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal', style: TextStyle(fontSize: 16)),
              Text(
                '${widget.cart.subtotal.toStringAsFixed(0)} ETB',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB8342A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _isPlacingOrder ? null : _placeOrder,
            child: _isPlacingOrder
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Place Order →'),
          ),
        ],
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem cartItem;

  const _CartItemTile({required this.cartItem});

  @override
  Widget build(BuildContext context) {
    // read here too - button taps are one-off actions, not something
    // this specific tile needs to rebuild in response to.
    final cart = context.read<CartProvider>();
    final menuItem = cartItem.menuItem;

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 56,
                width: 56,
                child: menuItem.imageUrl != null
                    ? Image.network(
                        menuItem.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade300,
                            child: const Icon(
                              Icons.fastfood,
                              color: Colors.grey,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.fastfood, color: Colors.grey),
                      ),
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    menuItem.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${menuItem.price.toStringAsFixed(0)} ETB',
                    style: const TextStyle(
                      color: Color(0xFFB8342A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Quantity stepper: - [count] +
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () =>
                      cart.updateQuantity(menuItem.id, cartItem.quantity - 1),
                ),
                Text('${cartItem.quantity}'),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () =>
                      cart.updateQuantity(menuItem.id, cartItem.quantity + 1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
