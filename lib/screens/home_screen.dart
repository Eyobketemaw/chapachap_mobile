import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/restaurant_service.dart';
import '../models/restaurant.dart';
import 'login_screen.dart';
import 'restaurant_details_screen.dart';
import '../providers/cart_provider.dart';
import 'cart_screen.dart';

// Home screen - now Stateful because it needs to fetch and hold onto
// the restaurant list, plus track loading/error states while that
// fetch is in progress.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Three-state pattern: while _isLoading is true, ignore _restaurants/_error.
  // Once false, check _error first (show it if present), otherwise show _restaurants.
  List<Restaurant> _restaurants = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Kick off the fetch once, when this screen first appears.
    _loadRestaurants();
  }

  Future<void> _loadRestaurants() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // read (not watch) - we're calling a method once, not subscribing
      // to RestaurantService for future rebuilds (it has no state to watch anyway).
      final restaurantService = context.read<RestaurantService>();
      final restaurants = await restaurantService.getAllRestaurants();

      if (mounted) {
        setState(() {
          _restaurants = restaurants;
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

  // Decides what to show based on our three states: loading, error, success.
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color.fromARGB(255, 178, 61, 52),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Color(0xFFC9463D),
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                // Retry - just re-runs the same fetch, reusing all our
                // existing loading/error handling for free.
                onPressed: _loadRestaurants,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_restaurants.isEmpty) {
      return const Center(
        child: Text(
          'No restaurants available yet.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Success state with real data - ListView.builder only builds the
    // widgets currently visible on screen, not all of them at once.
    // This matters a lot once you have 50+ restaurants instead of 5 -
    // it's the standard, performant way to show any scrollable list in Flutter.
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _restaurants.length,
      itemBuilder: (context, index) {
        final restaurant = _restaurants[index];
        return _RestaurantCard(restaurant: restaurant);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 240, 239, 239),
      appBar: AppBar(
        title: const Text('ChapaChap'),
        backgroundColor: const Color.fromARGB(255, 170, 63, 55),
        actions: [
          // Cart icon with item-count badge
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CartScreen(),
                        ),
                      );
                    },
                  ),
                  // Only show the badge if there's actually something in the cart
                  if (cart.itemCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${cart.itemCount}',
                          style: const TextStyle(
                            color: Color(0xFFB8342A),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Hello, ${user?.name ?? 'there'}!',
                style: const TextStyle(
                  color: Color.fromARGB(255, 0, 0, 0),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // The three-state body goes here next
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }
}

// A single restaurant's card in the Home screen list.
// Separate widget (not a helper method) since this is a repeated,
// self-contained visual unit - the standard Flutter pattern for list items.
class _RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;

  const _RestaurantCard({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior:
          Clip.antiAlias, // makes the image respect the card's rounded corners
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  RestaurantDetailsScreen(restaurantId: restaurant.id),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Restaurant photo, or a placeholder icon if none exists yet
            SizedBox(
              height: 160,
              width: double.infinity,
              child: restaurant.image != null
                  ? Image.network(
                      restaurant.image!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
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
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (restaurant.address != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      restaurant.address!,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
