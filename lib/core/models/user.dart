/// Matches the `users` table in the ElizirFit AI spec (Section 6).
class UserModel {
  final String id;
  final String name;
  final String email;
  final int? age;
  final String? sex; // 'male' | 'female' | 'other'
  final double? heightCm;
  final double? weightKg;
  final String? goal; // 'lose' | 'gain' | 'maintain' | 'recomp'
  final String? activityLevel; // 'sedentary' | 'light' | 'moderate' | 'active' | 'very_active'
  final String createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.age,
    this.sex,
    this.heightCm,
    this.weightKg,
    this.goal,
    this.activityLevel,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'age': age,
      'sex': sex,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'goal': goal,
      'activity_level': activityLevel,
      'created_at': createdAt,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      age: map['age'] as int?,
      sex: map['sex'] as String?,
      heightCm: (map['height_cm'] as num?)?.toDouble(),
      weightKg: (map['weight_kg'] as num?)?.toDouble(),
      goal: map['goal'] as String?,
      activityLevel: map['activity_level'] as String?,
      createdAt: map['created_at'] as String,
    );
  }

  UserModel copyWith({
    String? name,
    String? email,
    int? age,
    String? sex,
    double? heightCm,
    double? weightKg,
    String? goal,
    String? activityLevel,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      age: age ?? this.age,
      sex: sex ?? this.sex,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      goal: goal ?? this.goal,
      activityLevel: activityLevel ?? this.activityLevel,
      createdAt: createdAt,
    );
  }
}
