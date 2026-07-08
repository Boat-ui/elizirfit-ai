import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../database/seed/food_seed_data.dart';
import '../models/food.dart';

class FoodRepository {
  FoodRepository(this._db);
  final Database _db;

  static const uuid = Uuid();

  /// Inserts the starter Ghana food dataset (Section 7) if the `foods`
  /// table is empty. Safe to call on every app start — it's a no-op once
  /// seeded. Uses a batch insert since this can be ~90 rows.
  Future<void> seedIfEmpty() async {
    final countResult = Sqflite.firstIntValue(
      await _db.rawQuery('SELECT COUNT(*) FROM foods'),
    );
    if ((countResult ?? 0) > 0) return;

    final batch = _db.batch();
    for (final entry in ghanaFoodSeed) {
      final row = Map<String, Object?>.from(entry);
      row['id'] = 'food_${uuid.v4()}';
      batch.insert('foods', row);
    }
    await batch.commit(noResult: true);
  }

  /// Foods matching [query] against name or local_names, case-insensitive.
  /// Empty query returns everything (used for browsing by category).
  Future<List<FoodModel>> search(String query, {String? category}) async {
    final whereParts = <String>[];
    final whereArgs = <Object?>[];

    if (query.trim().isNotEmpty) {
      whereParts.add('(name LIKE ? OR local_names LIKE ?)');
      final like = '%${query.trim()}%';
      whereArgs.addAll([like, like]);
    }
    if (category != null && category.isNotEmpty) {
      whereParts.add('category = ?');
      whereArgs.add(category);
    }

    final rows = await _db.query(
      'foods',
      where: whereParts.isEmpty ? null : whereParts.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'name ASC',
      limit: 100,
    );
    return rows.map(FoodModel.fromMap).toList();
  }

  Future<FoodModel?> getById(String id) async {
    final rows = await _db.query('foods', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return FoodModel.fromMap(rows.first);
  }

  Future<List<String>> getCategories() async {
    final rows = await _db.rawQuery(
      'SELECT DISTINCT category FROM foods WHERE category IS NOT NULL ORDER BY category',
    );
    return rows.map((r) => r['category'] as String).toList();
  }
}
