import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../database/seed/exercise_seed_data.dart';
import '../models/exercise.dart';

class ExerciseRepository {
  ExerciseRepository(this._db);
  final Database _db;

  static const uuid = Uuid();

  /// Inserts the starter exercise library (Section 4) if the `exercises`
  /// table is empty. Safe to call on every app start.
  Future<void> seedIfEmpty() async {
    final countResult = Sqflite.firstIntValue(
      await _db.rawQuery('SELECT COUNT(*) FROM exercises'),
    );
    if ((countResult ?? 0) > 0) return;

    final batch = _db.batch();
    for (final entry in exerciseSeed) {
      final row = Map<String, Object?>.from(entry);
      row['id'] = 'ex_${uuid.v4()}';
      batch.insert('exercises', row);
    }
    await batch.commit(noResult: true);
  }

  /// Exercises matching [query] against name, filtered by [category] and
  /// [equipment] when given. Empty query returns everything (browsing).
  Future<List<ExerciseModel>> search(
    String query, {
    String? category,
    String? equipment,
  }) async {
    final whereParts = <String>[];
    final whereArgs = <Object?>[];

    if (query.trim().isNotEmpty) {
      whereParts.add('name LIKE ?');
      whereArgs.add('%${query.trim()}%');
    }
    if (category != null && category.isNotEmpty) {
      whereParts.add('category = ?');
      whereArgs.add(category);
    }
    if (equipment != null && equipment.isNotEmpty) {
      whereParts.add('equipment = ?');
      whereArgs.add(equipment);
    }

    final rows = await _db.query(
      'exercises',
      where: whereParts.isEmpty ? null : whereParts.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'name ASC',
      limit: 200,
    );
    return rows.map(ExerciseModel.fromMap).toList();
  }

  Future<ExerciseModel?> getById(String id) async {
    final rows = await _db.query('exercises', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return ExerciseModel.fromMap(rows.first);
  }

  Future<List<String>> getCategories() async {
    final rows = await _db.rawQuery(
      'SELECT DISTINCT category FROM exercises WHERE category IS NOT NULL ORDER BY category',
    );
    return rows.map((r) => r['category'] as String).toList();
  }

  Future<List<String>> getEquipmentTypes() async {
    final rows = await _db.rawQuery(
      'SELECT DISTINCT equipment FROM exercises WHERE equipment IS NOT NULL ORDER BY equipment',
    );
    return rows.map((r) => r['equipment'] as String).toList();
  }
}
