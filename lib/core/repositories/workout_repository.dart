import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../models/workout.dart';
import '../models/workout_set.dart';

/// A workout row with a few pre-computed summary fields, so the Workout
/// Home history list doesn't need a query per row.
class WorkoutSummary {
  final WorkoutModel workout;
  final int setCount;
  final int exerciseCount;

  const WorkoutSummary({
    required this.workout,
    required this.setCount,
    required this.exerciseCount,
  });

  Duration? get duration {
    if (workout.endedAt == null) return null;
    return DateTime.parse(workout.endedAt!).difference(DateTime.parse(workout.startedAt));
  }
}

/// Best set ever logged for one exercise, ranked by estimated one-rep max
/// (Epley formula: 1RM = weight × (1 + reps/30)) — the standard way to
/// compare sets done at different rep ranges. Bodyweight/duration-only
/// exercises (no weight or reps logged) are excluded from PRs.
class PersonalRecord {
  final String exerciseName;
  final double weightKg;
  final int reps;
  final double estimatedOneRepMax;
  final String achievedAt;

  const PersonalRecord({
    required this.exerciseName,
    required this.weightKg,
    required this.reps,
    required this.estimatedOneRepMax,
    required this.achievedAt,
  });
}

class WorkoutRepository {
  WorkoutRepository(this._db);
  final Database _db;

  static const uuid = Uuid();

  Future<WorkoutModel> startWorkout(String userId) async {
    final workout = WorkoutModel(
      id: 'workout_${uuid.v4()}',
      userId: userId,
      startedAt: DateTime.now().toIso8601String(),
    );
    await _db.insert('workouts', workout.toMap());
    return workout;
  }

  Future<void> finishWorkout(String workoutId, {String? notes}) async {
    await _db.update(
      'workouts',
      {
        'ended_at': DateTime.now().toIso8601String(),
        if (notes != null) 'notes': notes,
      },
      where: 'id = ?',
      whereArgs: [workoutId],
    );
  }

  /// The most recent workout for [userId] that hasn't been finished yet,
  /// or null if none — used to resume a session after leaving the app.
  Future<WorkoutModel?> getActiveWorkout(String userId) async {
    final rows = await _db.query(
      'workouts',
      where: 'user_id = ? AND ended_at IS NULL',
      whereArgs: [userId],
      orderBy: 'started_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return WorkoutModel.fromMap(rows.first);
  }

  Future<List<WorkoutSummary>> getHistory(String userId, {int limit = 50}) async {
    final rows = await _db.rawQuery('''
      SELECT
        workouts.*,
        COUNT(workout_sets.id) AS set_count,
        COUNT(DISTINCT workout_sets.exercise_name) AS exercise_count
      FROM workouts
      LEFT JOIN workout_sets ON workout_sets.workout_id = workouts.id
      WHERE workouts.user_id = ? AND workouts.ended_at IS NOT NULL
      GROUP BY workouts.id
      ORDER BY workouts.started_at DESC
      LIMIT ?
    ''', [userId, limit]);

    return rows.map((row) {
      return WorkoutSummary(
        workout: WorkoutModel.fromMap(row),
        setCount: (row['set_count'] as int?) ?? 0,
        exerciseCount: (row['exercise_count'] as int?) ?? 0,
      );
    }).toList();
  }

  Future<WorkoutModel?> getWorkoutById(String id) async {
    final rows = await _db.query('workouts', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return WorkoutModel.fromMap(rows.first);
  }

  Future<int> addSet({
    required String workoutId,
    required String exerciseName,
    int? reps,
    double? weightKg,
    double? rpe,
    int? durationSeconds,
  }) async {
    final existing = await _db.query(
      'workout_sets',
      where: 'workout_id = ? AND exercise_name = ?',
      whereArgs: [workoutId, exerciseName],
    );
    final nextSetNumber = existing.length + 1;

    final set = WorkoutSetModel(
      id: 'set_${uuid.v4()}',
      workoutId: workoutId,
      exerciseName: exerciseName,
      setNumber: nextSetNumber,
      reps: reps,
      weightKg: weightKg,
      rpe: rpe,
      durationSeconds: durationSeconds,
    );
    await _db.insert('workout_sets', set.toMap());
    return nextSetNumber;
  }

  Future<void> deleteSet(String id) async {
    await _db.delete('workout_sets', where: 'id = ?', whereArgs: [id]);
  }

  /// All sets for [workoutId], grouped by exercise name in the order each
  /// exercise was first added, sets in logged order within each group.
  Future<Map<String, List<WorkoutSetModel>>> getSetsGrouped(String workoutId) async {
    final rows = await _db.query(
      'workout_sets',
      where: 'workout_id = ?',
      whereArgs: [workoutId],
      orderBy: 'rowid ASC',
    );
    final sets = rows.map(WorkoutSetModel.fromMap).toList();

    final grouped = <String, List<WorkoutSetModel>>{};
    for (final s in sets) {
      grouped.putIfAbsent(s.exerciseName, () => []).add(s);
    }
    return grouped;
  }

  /// Best-ever set per exercise for [userId], across all finished and
  /// in-progress workouts, ranked by estimated one-rep max.
  Future<List<PersonalRecord>> getPersonalRecords(String userId) async {
    final rows = await _db.rawQuery('''
      SELECT workout_sets.exercise_name, workout_sets.reps, workout_sets.weight_kg, workouts.started_at
      FROM workout_sets
      JOIN workouts ON workouts.id = workout_sets.workout_id
      WHERE workouts.user_id = ?
        AND workout_sets.weight_kg IS NOT NULL
        AND workout_sets.weight_kg > 0
        AND workout_sets.reps IS NOT NULL
        AND workout_sets.reps > 0
    ''', [userId]);

    final bestByExercise = <String, PersonalRecord>{};
    for (final row in rows) {
      final name = row['exercise_name'] as String;
      final reps = row['reps'] as int;
      final weight = (row['weight_kg'] as num).toDouble();
      final startedAt = row['started_at'] as String;
      final oneRepMax = weight * (1 + reps / 30.0);

      final current = bestByExercise[name];
      if (current == null || oneRepMax > current.estimatedOneRepMax) {
        bestByExercise[name] = PersonalRecord(
          exerciseName: name,
          weightKg: weight,
          reps: reps,
          estimatedOneRepMax: oneRepMax,
          achievedAt: startedAt,
        );
      }
    }

    final records = bestByExercise.values.toList()
      ..sort((a, b) => b.achievedAt.compareTo(a.achievedAt));
    return records;
  }
}
