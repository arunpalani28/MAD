class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String unit;
  final bool isSubscriptionAvailable;
  final double rating;
  final String category;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.unit,
    this.isSubscriptionAvailable = true,
    this.rating = 4.5,
    required this.category,
  });

  /// ✅ Convert Spring Boot JSON → Products
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      description: json['description'] ?? 'Fresh dairy product',
      price: (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'] ??
          'https://via.placeholder.com/150',
      unit: json['unit'] ?? '1 unit',
      category: json['category'] ?? 'Other',
      isSubscriptionAvailable:
          json['isSubscriptionAvailable'] ?? true,
      rating: (json['rating'] ?? 4.5).toDouble(),
    );
  }
}

class CartItem {
  final Product product;
  int quantity;
  bool isSubscription;
  String frequency; // 'Daily', 'Alternate', 'One-time'

  CartItem({
    required this.product,
    this.quantity = 1,
    this.isSubscription = false,
    this.frequency = 'One-time',
  });

  double get total => product.price * quantity;
}
