/// Matches the `workouts` table in the ElizirFit AI spec (Section 6).
/// A workout is a session container; its sets live in [WorkoutSetModel].
class WorkoutModel {
  final String id;
  final String userId;
  final String startedAt;
  final String? endedAt;
  final String? notes;
  final bool synced;

  const WorkoutModel({
    required this.id,
    required this.userId,
    required this.startedAt,
    this.endedAt,
    this.notes,
    this.synced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'started_at': startedAt,
      'ended_at': endedAt,
      'notes': notes,
      'synced': synced ? 1 : 0,
    };
  }

  factory WorkoutModel.fromMap(Map<String, dynamic> map) {
    return WorkoutModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      startedAt: map['started_at'] as String,
      endedAt: map['ended_at'] as String?,
      notes: map['notes'] as String?,
      synced: (map['synced'] as int? ?? 0) == 1,
    );
  }
}
