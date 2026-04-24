import 'dart:math';
import '../models/trade_model.dart';
import '../utils/date_utils.dart';

class TradeController {
  /// Create a new trade (strict validation applied)
  static TradeModel createTrade({
    required String userId,
    required double amount,
    required double payoutPercent,
    required double profitLoss,
    required String pair,
    required String reason,
    required int confidence,
    required String emotion,
    required String strategy,
  }) {
    // 🔒 Enforce ₹100 minimum
    if (amount < 100) {
      throw Exception("Trade amount cannot be less than ₹100");
    }

    // 🔒 Confidence validation
    if (confidence < 1 || confidence > 5) {
      throw Exception("Confidence must be between 1 and 5");
    }

    final now = DateTime.now();

    // 📅 Generate keys
    final dayKey = DateUtilsMM.getDayKey(now);
    final weekKey = DateUtilsMM.getWeekKey(now);
    final yearKey = DateUtilsMM.getYearKey(now);

    // 📊 Determine result (Binary Terminology: ITM/OTM)
    final result = profitLoss >= 0 ? "win" : "loss";

    // 🆔 Simple unique ID
    final tradeId = "${now.microsecondsSinceEpoch}_${Random().nextInt(9999)}";

    return TradeModel(
      tradeId: tradeId,
      userId: userId,
      amount: amount,
      payoutPercent: payoutPercent,
      profitLoss: profitLoss,
      result: result,
      pair: pair,
      reason: reason,
      confidence: confidence,
      emotion: emotion,
      strategy: strategy,
      timestamp: now,
      dayKey: dayKey,
      weekKey: weekKey,
      yearKey: yearKey,
    );
  }
}