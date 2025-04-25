class Product {
  final String id;
  final String name;
  final String imageUrl;
  final String price;
  final String? description;
  final Map<String, String>? specs;

  Product({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    this.description,
    this.specs,
  });
}
