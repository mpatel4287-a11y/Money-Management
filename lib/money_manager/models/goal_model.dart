class GoalModel {
  final String userId;
  final double depositAmount;
  final double targetAmount;
  final int targetDays;
  final DateTime startDate;

  GoalModel({
    required this.userId,
    required this.depositAmount,
    required this.targetAmount,
    required this.targetDays,
    required this.startDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'depositAmount': depositAmount,
      'targetAmount': targetAmount,
      'targetDays': targetDays,
      'startDate': startDate.toIso8601String(),
    };
  }

  factory GoalModel.fromMap(Map<String, dynamic> map) {
    return GoalModel(
      userId: map['userId'],
      depositAmount: (map['depositAmount'] as num).toDouble(),
      targetAmount: (map['targetAmount'] as num).toDouble(),
      targetDays: map['targetDays'] as int,
      startDate: DateTime.parse(map['startDate']),
    );
  }
}
