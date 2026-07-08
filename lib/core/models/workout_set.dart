/// Matches the `workout_sets` table in the ElizirFit AI spec (Section 6).
/// `exerciseName` is stored directly (denormalized) rather than a foreign
/// key to `exercises`, per the spec's schema — keeps a logged set valid
/// even if the exercise library entry is later edited or removed.
class WorkoutSetModel {
  final String id;
  final String workoutId;
  final String exerciseName;
  final int setNumber;
  final int? reps;
  final double? weightKg;
  final double? rpe;
  final int? durationSeconds;

  const WorkoutSetModel({
    required this.id,
    required this.workoutId,
    required this.exerciseName,
    required this.setNumber,
    this.reps,
    this.weightKg,
    this.rpe,
    this.durationSeconds,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workout_id': workoutId,
      'exercise_name': exerciseName,
      'set_number': setNumber,
      'reps': reps,
      'weight_kg': weightKg,
      'rpe': rpe,
      'duration_seconds': durationSeconds,
    };
  }

  factory WorkoutSetModel.fromMap(Map<String, dynamic> map) {
    return WorkoutSetModel(
      id: map['id'] as String,
      workoutId: map['workout_id'] as String,
      exerciseName: map['exercise_name'] as String,
      setNumber: map['set_number'] as int,
      reps: map['reps'] as int?,
      weightKg: (map['weight_kg'] as num?)?.toDouble(),
      rpe: (map['rpe'] as num?)?.toDouble(),
      durationSeconds: map['duration_seconds'] as int?,
    );
  }
}
