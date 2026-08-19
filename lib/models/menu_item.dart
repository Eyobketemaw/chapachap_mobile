import '../config/api_config.dart';

// Represents a single menu item, matching the JSON shape returned by
// GET /api/restaurants/:id (nested) and GET /api/restaurants/:id/menu-items
class MenuItem {
  final int id;
  final int restaurantId;
  final String name;
  final double price;
  final bool available;
  final String?
  image; // raw filename from backend, e.g. "1787124333105-xxx.jpg" - NOT a full URL

  MenuItem({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.price,
    required this.available,
    this.image,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'],
      // restaurantId might be missing when this MenuItem comes nested
      // inside a Restaurant's JSON (getById), since the backend doesn't
      // repeat it there - default to 0 as a safe fallback in that case.
      restaurantId: json['restaurantId'] ?? 0,
      name: json['name'],
      // Backend sends price as a string (Sequelize DECIMAL type does this) -
      // double.parse() converts it to a real number Dart can do math with.
      price: double.parse(json['price'].toString()),
      available: json['available'] ?? true,
      image: json['image'],
    );
  }

  // Turns the raw filename into a full, browsable URL.
  // Returns null if there's no image at all, so the UI can show a
  // placeholder instead of trying to load a broken link.
  String? get imageUrl {
    if (image == null || image!.isEmpty) return null;
    return '${ApiConfig.baseUrl}/uploads/$image';
  }
}
