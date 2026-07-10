/// Matches the `activity_logs` table in the ElizirFit AI spec (Section 6).
class ActivityLogModel {
  final String id;
  final String userId;
  final String activityType; // 'walk' | 'run' | 'cycle' | 'other'
  final String startedAt;
  final double durationMinutes;
  final double? distanceKm;
  final double? caloriesEstimated;
  final bool synced;

  const ActivityLogModel({
    required this.id,
    required this.userId,
    required this.activityType,
    required this.startedAt,
    required this.durationMinutes,
    this.distanceKm,
    this.caloriesEstimated,
    this.synced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'activity_type': activityType,
      'started_at': startedAt,
      'duration_minutes': durationMinutes,
      'distance_km': distanceKm,
      'calories_estimated': caloriesEstimated,
      'synced': synced ? 1 : 0,
    };
  }

  factory ActivityLogModel.fromMap(Map<String, dynamic> map) {
    return ActivityLogModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      activityType: map['activity_type'] as String,
      startedAt: map['started_at'] as String,
      durationMinutes: (map['duration_minutes'] as num).toDouble(),
      distanceKm: (map['distance_km'] as num?)?.toDouble(),
      caloriesEstimated: (map['calories_estimated'] as num?)?.toDouble(),
      synced: (map['synced'] as int? ?? 0) == 1,
    );
  }
}

/// Standard MET-based calorie estimate, per Section 6 of the spec:
/// calories = MET_value × body_weight_kg × duration_hours.
class MetValues {
  static const double walking = 3.5;
  static const double running = 9.8;
  static const double cycling = 7.5;
  static const double other = 4.0; // general moderate activity

  static double metFor(String activityType) {
    switch (activityType) {
      case 'walk':
        return walking;
      case 'run':
        return running;
      case 'cycle':
        return cycling;
      default:
        return other;
    }
  }

  static double estimateCalories({
    required double metValue,
    required double bodyWeightKg,
    required double durationMinutes,
  }) {
    final durationHours = durationMinutes / 60.0;
    return metValue * bodyWeightKg * durationHours;
  }
}
