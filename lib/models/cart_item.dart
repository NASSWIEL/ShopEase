class CartItem {
  final String id;
  final String name;
  final double price;
  int quantity;
  final String? imageUrl;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    this.imageUrl,
  });

  // Create a copy of the cart item with updated quantity
  CartItem copyWith({int? quantity}) {
    return CartItem(
      id: id,
      name: name,
      price: price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl,
    );
  }

  // Add title getter to fix compatibility with article_ajoute_panier.dart
  String get title => name;

  // Return non-nullable imageUrl for places that require it
  String get imageUrlOrDefault => imageUrl ?? "https://via.placeholder.com/150";
}
