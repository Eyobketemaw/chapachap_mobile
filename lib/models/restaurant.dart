// Represents a single restaurant, matching the JSON shape returned by
// GET /api/restaurants and GET /api/restaurants/:id
class Restaurant {
  final int id;
  final String name;
  final String? address;
  final bool isOpen;
  final String?
  image; // full URL already (unlike MenuItem.image, which is just a filename)

  Restaurant({
    required this.id,
    required this.name,
    this.address,
    required this.isOpen,
    this.image,
  });

  // Factory constructor: builds a Restaurant instance from a raw JSON map.
  // This is the standard Dart pattern for turning backend responses into
  // typed objects instead of passing raw Maps around your app.
  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      isOpen: json['isOpen'] ?? true,
      image: json['image'],
    );
  }
}
