/// Matches the `meal_logs` table in the ElizirFit AI spec (Section 6).
/// Exactly one of [foodId] / [productId] should be set — a meal log
/// entry points at either a home-cooked food or a scanned product.
class MealLogModel {
  final String id;
  final String userId;
  final String loggedAt;
  final String mealType; // 'breakfast' | 'lunch' | 'dinner' | 'snack'
  final String? foodId;
  final String? productId;
  final double quantityServings;
  final bool synced;

  const MealLogModel({
    required this.id,
    required this.userId,
    required this.loggedAt,
    required this.mealType,
    this.foodId,
    this.productId,
    this.quantityServings = 1,
    this.synced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'logged_at': loggedAt,
      'meal_type': mealType,
      'food_id': foodId,
      'product_id': productId,
      'quantity_servings': quantityServings,
      'synced': synced ? 1 : 0,
    };
  }

  factory MealLogModel.fromMap(Map<String, dynamic> map) {
    return MealLogModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      loggedAt: map['logged_at'] as String,
      mealType: map['meal_type'] as String,
      foodId: map['food_id'] as String?,
      productId: map['product_id'] as String?,
      quantityServings: (map['quantity_servings'] as num).toDouble(),
      synced: (map['synced'] as int? ?? 0) == 1,
    );
  }
}
