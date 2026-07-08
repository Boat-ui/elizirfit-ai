/// Matches the `exercises` table in the ElizirFit AI spec (Section 6).
/// This is the curated exercise library (~150-200 entries for v1),
/// not a user's logged sets — see [WorkoutSetModel] for that.
class ExerciseModel {
  final String id;
  final String name;
  final String? category; // 'chest' | 'back' | 'legs' | 'shoulders' | 'arms' | 'core' | 'cardio'
  final String? difficulty; // 'beginner' | 'intermediate' | 'advanced'
  final String? primaryMuscles; // pipe-separated
  final String? secondaryMuscles; // pipe-separated
  final String? equipment;
  final String? instructions;

  const ExerciseModel({
    required this.id,
    required this.name,
    this.category,
    this.difficulty,
    this.primaryMuscles,
    this.secondaryMuscles,
    this.equipment,
    this.instructions,
  });

  List<String> get primaryMusclesList =>
      primaryMuscles == null || primaryMuscles!.isEmpty ? [] : primaryMuscles!.split('|');

  List<String> get secondaryMusclesList =>
      secondaryMuscles == null || secondaryMuscles!.isEmpty ? [] : secondaryMuscles!.split('|');

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'difficulty': difficulty,
      'primary_muscles': primaryMuscles,
      'secondary_muscles': secondaryMuscles,
      'equipment': equipment,
      'instructions': instructions,
    };
  }

  factory ExerciseModel.fromMap(Map<String, dynamic> map) {
    return ExerciseModel(
      id: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] as String?,
      difficulty: map['difficulty'] as String?,
      primaryMuscles: map['primary_muscles'] as String?,
      secondaryMuscles: map['secondary_muscles'] as String?,
      equipment: map['equipment'] as String?,
      instructions: map['instructions'] as String?,
    );
  }
}
