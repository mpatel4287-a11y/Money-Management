class TradeModel {
  final String tradeId;
  final String userId;

  final double amount; // must be >= 100
  final double payoutPercent;

  final double profitLoss; // +ve or -ve
  final String result; // "win" or "loss"

  final String pair;

  final String reason;
  final int confidence; // 1 to 5
  final String emotion;
  final String strategy;

  final DateTime timestamp;

  final String dayKey;   // YYYY-MM-DD
  final String weekKey;  // YYYY-WW
  final String yearKey;  // YYYY

  TradeModel({
    required this.tradeId,
    required this.userId,
    required this.amount,
    required this.payoutPercent,
    required this.profitLoss,
    required this.result,
    required this.pair,
    required this.reason,
    required this.confidence,
    required this.emotion,
    required this.strategy,
    required this.timestamp,
    required this.dayKey,
    required this.weekKey,
    required this.yearKey,
  });

  /// Convert object → Map (for Firebase later)
  Map<String, dynamic> toMap() {
    return {
      'tradeId': tradeId,
      'userId': userId,
      'amount': amount,
      'payoutPercent': payoutPercent,
      'profitLoss': profitLoss,
      'result': result,
      'pair': pair,
      'reason': reason,
      'confidence': confidence,
      'emotion': emotion,
      'strategy': strategy,
      'timestamp': timestamp.toIso8601String(),
      'dayKey': dayKey,
      'weekKey': weekKey,
      'yearKey': yearKey,
    };
  }

  /// Convert Map → object
  factory TradeModel.fromMap(Map<String, dynamic> map) {
    return TradeModel(
      tradeId: map['tradeId'],
      userId: map['userId'],
      amount: (map['amount'] as num).toDouble(),
      payoutPercent: (map['payoutPercent'] as num).toDouble(),
      profitLoss: (map['profitLoss'] as num).toDouble(),
      result: map['result'],
      pair: map['pair'],
      reason: map['reason'],
      confidence: map['confidence'],
      emotion: map['emotion'],
      strategy: map['strategy'] ?? "General",
      timestamp: DateTime.parse(map['timestamp']),
      dayKey: map['dayKey'],
      weekKey: map['weekKey'],
      yearKey: map['yearKey'],
    );
  }
}