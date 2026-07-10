import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../models/activity_log.dart';

class ActivityRepository {
  ActivityRepository(this._db);
  final Database _db;

  static const uuid = Uuid();

  /// Logs an activity and returns it with `caloriesEstimated` filled in
  /// using the standard MET formula (spec Section 6):
  /// calories = MET_value × body_weight_kg × duration_hours.
  Future<ActivityLogModel> logActivity({
    required String userId,
    required String activityType,
    required double durationMinutes,
    required double bodyWeightKg,
    double? distanceKm,
    DateTime? startedAt,
  }) async {
    final met = MetValues.metFor(activityType);
    final calories = MetValues.estimateCalories(
      metValue: met,
      bodyWeightKg: bodyWeightKg,
      durationMinutes: durationMinutes,
    );

    final log = ActivityLogModel(
      id: 'activity_${uuid.v4()}',
      userId: userId,
      activityType: activityType,
      startedAt: (startedAt ?? DateTime.now()).toIso8601String(),
      durationMinutes: durationMinutes,
      distanceKm: distanceKm,
      caloriesEstimated: calories,
    );
    await _db.insert('activity_logs', log.toMap());
    return log;
  }

  Future<void> deleteActivity(String id) async {
    await _db.delete('activity_logs', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ActivityLogModel>> getEntriesForDay({
    required String userId,
    DateTime? day,
  }) async {
    final target = day ?? DateTime.now();
    final dayStart = DateTime(target.year, target.month, target.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final rows = await _db.query(
      'activity_logs',
      where: 'user_id = ? AND started_at >= ? AND started_at < ?',
      whereArgs: [userId, dayStart.toIso8601String(), dayEnd.toIso8601String()],
      orderBy: 'started_at DESC',
    );
    return rows.map(ActivityLogModel.fromMap).toList();
  }

  Future<double> getTotalCaloriesForDay({required String userId, DateTime? day}) async {
    final entries = await getEntriesForDay(userId: userId, day: day);
    return entries.fold<double>(0, (sum, e) => sum + (e.caloriesEstimated ?? 0));
  }

  Future<List<ActivityLogModel>> getHistory(String userId, {int limit = 50}) async {
    final rows = await _db.query(
      'activity_logs',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'started_at DESC',
      limit: limit,
    );
    return rows.map(ActivityLogModel.fromMap).toList();
  }
}
