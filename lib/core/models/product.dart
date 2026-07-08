/// Matches the `products` table in the ElizirFit AI spec (Section 6).
/// This is the barcode/QR-scanned packaged-product dataset — separate
/// from `foods`, which covers home-cooked/whole foods.
class ProductModel {
  final String id;
  final String barcode;
  final String name;
  final String? brand;
  final String? manufacturer;
  final double servingSizeG;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double? sugarG;
  final double? sodiumMg;
  final String? ingredients;

  const ProductModel({
    required this.id,
    required this.barcode,
    required this.name,
    this.brand,
    this.manufacturer,
    required this.servingSizeG,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.sugarG,
    this.sodiumMg,
    this.ingredients,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'barcode': barcode,
      'name': name,
      'brand': brand,
      'manufacturer': manufacturer,
      'serving_size_g': servingSizeG,
      'calories': calories,
      'protein_g': proteinG,
      'carbs_g': carbsG,
      'fat_g': fatG,
      'sugar_g': sugarG,
      'sodium_mg': sodiumMg,
      'ingredients': ingredients,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as String,
      barcode: map['barcode'] as String,
      name: map['name'] as String,
      brand: map['brand'] as String?,
      manufacturer: map['manufacturer'] as String?,
      servingSizeG: (map['serving_size_g'] as num).toDouble(),
      calories: (map['calories'] as num).toDouble(),
      proteinG: (map['protein_g'] as num).toDouble(),
      carbsG: (map['carbs_g'] as num).toDouble(),
      fatG: (map['fat_g'] as num).toDouble(),
      sugarG: (map['sugar_g'] as num?)?.toDouble(),
      sodiumMg: (map['sodium_mg'] as num?)?.toDouble(),
      ingredients: map['ingredients'] as String?,
    );
  }
}
