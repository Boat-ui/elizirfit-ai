/// Matches the `water_logs` table in the ElizirFit AI spec (Section 6).
class WaterLogModel {
  final String id;
  final String userId;
  final String loggedAt;
  final double amountMl;

  const WaterLogModel({
    required this.id,
    required this.userId,
    required this.loggedAt,
    required this.amountMl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'logged_at': loggedAt,
      'amount_ml': amountMl,
    };
  }

  factory WaterLogModel.fromMap(Map<String, dynamic> map) {
    return WaterLogModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      loggedAt: map['logged_at'] as String,
      amountMl: (map['amount_ml'] as num).toDouble(),
    );
  }
}
