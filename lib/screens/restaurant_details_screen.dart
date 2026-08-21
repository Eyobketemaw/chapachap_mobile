import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/restaurant_service.dart';
import '../models/restaurant.dart';
import '../models/menu_item.dart';

// Shows a single restaurant's details and menu items.
// Takes the restaurant's id via constructor - the screen fetches full
// details itself rather than relying on data passed in from Home,
// since Home's list only has partial restaurant data (no menu items).
class RestaurantDetailsScreen extends StatefulWidget {
  final int restaurantId;

  const RestaurantDetailsScreen({super.key, required this.restaurantId});

  @override
  State<RestaurantDetailsScreen> createState() =>
      _RestaurantDetailsScreenState();
}

class _RestaurantDetailsScreenState extends State<RestaurantDetailsScreen> {
  Restaurant? _restaurant;
  List<MenuItem> _menuItems = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final restaurantService = context.read<RestaurantService>();
      // widget.restaurantId - 'widget' gives us access to this State's
      // parent StatefulWidget's fields, since restaurantId lives there,
      // not in this State class itself.
      final result = await restaurantService.getRestaurantWithMenu(
        widget.restaurantId,
      );

      if (mounted) {
        setState(() {
          _restaurant = result['restaurant'];
          _menuItems = result['menuItems'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        // Show the restaurant name once loaded, generic title while loading
        title: Text(_restaurant?.name ?? 'Restaurant'),
        backgroundColor: const Color(0xFFB8342A),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFB8342A)),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDetails,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // _restaurant is guaranteed non-null here, since _isLoading is false
    // and _error is null - the only remaining possibility is success.
    final restaurant = _restaurant!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Restaurant hero image - same pattern as the Home screen card
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 200,
            width: double.infinity,
            child: restaurant.image != null
                ? Image.network(
                    restaurant.image!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade300,
                        child: const Icon(
                          Icons.restaurant,
                          size: 48,
                          color: Colors.grey,
                        ),
                      );
                    },
                  )
                : Container(
                    color: Colors.grey.shade300,
                    child: const Icon(
                      Icons.restaurant,
                      size: 48,
                      color: Colors.grey,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),

        if (restaurant.address != null)
          Text(
            restaurant.address!,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        const SizedBox(height: 20),

        const Text(
          'Menu',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        if (_menuItems.isEmpty)
          const Text('No menu items yet.', style: TextStyle(color: Colors.grey))
        else
          // .map().toList() converts our List<MenuItem> into a
          // List<Widget> - since we're inside a ListView's children
          // (not a separate ListView.builder), this is fine for a
          // menu-sized list rather than a huge scrollable feed.
          ..._menuItems.map((item) => _MenuItemTile(item: item)),
      ],
    );
  }
}

// A single menu item row - photo, name, price.
// Separate widget for the same reason _RestaurantCard was separate:
// it's a repeated, self-contained visual unit.
class _MenuItemTile extends StatelessWidget {
  final MenuItem item;

  const _MenuItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Thumbnail image - imageUrl getter handles the
            // filename-to-full-URL conversion for us (built into MenuItem)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 64,
                width: 64,
                child: item.imageUrl != null
                    ? Image.network(
                        item.imageUrl!,
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

            // Name + price, takes up remaining horizontal space
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.price.toStringAsFixed(0)} ETB',
                    style: const TextStyle(
                      color: Color(0xFFB8342A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // TODO: add-to-cart button goes here once Phase 3 (Cart) exists
          ],
        ),
      ),
    );
  }
}
