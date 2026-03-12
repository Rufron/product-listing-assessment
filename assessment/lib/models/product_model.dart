class VariantModel {
  final String id;
  final String label; // e.g. "M", "Red"
  final double price;
  final String currency; // e.g. "USD", "EUR"
  final String? imageUrl;

  const VariantModel({
    required this.id,
    required this.label,
    required this.price,
    required this.currency,
    this.imageUrl,
  });

  factory VariantModel.fromJson(Map<String, dynamic> json) {
    return VariantModel(
      id: json['id'] as String,
      label: json['label'] as String,
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String,
      imageUrl: json['imageUrl'] as String?,
    );
  }
}

class ProductModel {
  final String id;
  final String title;
  final String imageUrl;
  final String htmlDescription; // Raw HTML — rendered via html package
  final List<VariantModel> variants;

  const ProductModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.htmlDescription,
    required this.variants,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      title: json['title'] as String,
      imageUrl: json['imageUrl'] as String,
      htmlDescription: json['htmlDescription'] as String,
      variants: (json['variants'] as List)
          .map((v) => VariantModel.fromJson(v as Map<String, dynamic>))
          .toList(),
    );
  }
}
