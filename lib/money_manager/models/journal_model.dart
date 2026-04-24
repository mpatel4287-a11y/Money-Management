class JournalModel {
  final String dayKey;
  final String userId;
  final String reflection;

  JournalModel({
    required this.dayKey,
    required this.userId,
    required this.reflection,
  });

  Map<String, dynamic> toMap() {
    return {
      'dayKey': dayKey,
      'userId': userId,
      'reflection': reflection,
    };
  }

  factory JournalModel.fromMap(Map<String, dynamic> map) {
    return JournalModel(
      dayKey: map['dayKey'],
      userId: map['userId'],
      reflection: map['reflection'],
    );
  }
}
