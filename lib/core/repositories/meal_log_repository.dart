import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../models/meal_log.dart';

/// A meal log row joined with the food/product it points to — everything
/// the Nutrition Home screen needs to render one line of "today's meals"
/// without a second query per row.
class MealLogEntry {
  final MealLogModel log;
  final String foodName;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final bool verified;

  const MealLogEntry({
    required this.log,
    required this.foodName,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.verified,
  });
}

class DailyTotals {
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;

  const DailyTotals({
    this.calories = 0,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
  });
}

class MealLogRepository {
  MealLogRepository(this._db);
  final Database _db;

  static const uuid = Uuid();

  Future<void> logFood({
    required String userId,
    required String foodId,
    required String mealType,
    required double quantityServings,
    DateTime? loggedAt,
  }) async {
    final log = MealLogModel(
      id: 'meal_${uuid.v4()}',
      userId: userId,
      loggedAt: (loggedAt ?? DateTime.now()).toIso8601String(),
      mealType: mealType,
      foodId: foodId,
      quantityServings: quantityServings,
    );
    await _db.insert('meal_logs', log.toMap());
  }

  Future<void> deleteLog(String id) async {
    await _db.delete('meal_logs', where: 'id = ?', whereArgs: [id]);
  }

  /// All meal log entries for [userId] on the given day (defaults to
  /// today), joined with food nutrition, most recent first.
  Future<List<MealLogEntry>> getEntriesForDay({
    required String userId,
    DateTime? day,
  }) async {
    final target = day ?? DateTime.now();
    final dayStart = DateTime(target.year, target.month, target.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final rows = await _db.rawQuery('''
      SELECT
        meal_logs.*,
        foods.name AS food_name,
        foods.calories AS food_calories,
        foods.protein_g AS food_protein_g,
        foods.carbs_g AS food_carbs_g,
        foods.fat_g AS food_fat_g,
        foods.verified AS food_verified
      FROM meal_logs
      LEFT JOIN foods ON meal_logs.food_id = foods.id
      WHERE meal_logs.user_id = ?
        AND meal_logs.logged_at >= ?
        AND meal_logs.logged_at < ?
      ORDER BY meal_logs.logged_at DESC
    ''', [userId, dayStart.toIso8601String(), dayEnd.toIso8601String()]);

    return rows.map((row) {
      final qty = (row['quantity_servings'] as num).toDouble();
      final baseCal = (row['food_calories'] as num?)?.toDouble() ?? 0;
      final baseProtein = (row['food_protein_g'] as num?)?.toDouble() ?? 0;
      final baseCarbs = (row['food_carbs_g'] as num?)?.toDouble() ?? 0;
      final baseFat = (row['food_fat_g'] as num?)?.toDouble() ?? 0;

      return MealLogEntry(
        log: MealLogModel.fromMap(row),
        foodName: (row['food_name'] as String?) ?? 'Unknown food',
        calories: baseCal * qty,
        proteinG: baseProtein * qty,
        carbsG: baseCarbs * qty,
        fatG: baseFat * qty,
        verified: (row['food_verified'] as int? ?? 0) == 1,
      );
    }).toList();
  }

  Future<DailyTotals> getTotalsForDay({required String userId, DateTime? day}) async {
    final entries = await getEntriesForDay(userId: userId, day: day);
    double cal = 0, protein = 0, carbs = 0, fat = 0;
    for (final e in entries) {
      cal += e.calories;
      protein += e.proteinG;
      carbs += e.carbsG;
      fat += e.fatG;
    }
    return DailyTotals(calories: cal, proteinG: protein, carbsG: carbs, fatG: fat);
  }
}
