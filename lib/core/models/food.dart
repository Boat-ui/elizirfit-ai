/// Matches the `foods` table in the ElizirFit AI spec (Section 6).
/// `verified == false` means the nutrition values are estimated,
/// not from a cited source — never present this as certain in the UI.
class FoodModel {
  final String id;
  final String name;
  final String? localNames; // pipe-separated alt names
  final String? category; // 'staple' | 'soup' | 'protein' | 'snack' | 'drink' | 'breakfast' | 'fruit' | 'vegetable'
  final double servingSizeG;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double? fiberG;
  final double? sugarG;
  final double? sodiumMg;
  final String? source; // citation for the nutrition data
  final bool verified;

  const FoodModel({
    required this.id,
    required this.name,
    this.localNames,
    this.category,
    required this.servingSizeG,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.fiberG,
    this.sugarG,
    this.sodiumMg,
    this.source,
    this.verified = false,
  });

  List<String> get localNamesList =>
      localNames == null || localNames!.isEmpty ? [] : localNames!.split('|');

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'local_names': localNames,
      'category': category,
      'serving_size_g': servingSizeG,
      'calories': calories,
      'protein_g': proteinG,
      'carbs_g': carbsG,
      'fat_g': fatG,
      'fiber_g': fiberG,
      'sugar_g': sugarG,
      'sodium_mg': sodiumMg,
      'source': source,
      'verified': verified ? 1 : 0,
    };
  }

  factory FoodModel.fromMap(Map<String, dynamic> map) {
    return FoodModel(
      id: map['id'] as String,
      name: map['name'] as String,
      localNames: map['local_names'] as String?,
      category: map['category'] as String?,
      servingSizeG: (map['serving_size_g'] as num).toDouble(),
      calories: (map['calories'] as num).toDouble(),
      proteinG: (map['protein_g'] as num).toDouble(),
      carbsG: (map['carbs_g'] as num).toDouble(),
      fatG: (map['fat_g'] as num).toDouble(),
      fiberG: (map['fiber_g'] as num?)?.toDouble(),
      sugarG: (map['sugar_g'] as num?)?.toDouble(),
      sodiumMg: (map['sodium_mg'] as num?)?.toDouble(),
      source: map['source'] as String?,
      verified: (map['verified'] as int? ?? 0) == 1,
    );
  }
}
