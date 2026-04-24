import '../models/trade_model.dart';

class AccuracyController {
  /// Generic accuracy calculator
  static double calculateAccuracy(List<TradeModel> trades) {
    if (trades.isEmpty) return 0;

    int wins = trades.where((t) => t.result == "win").length;
    int total = trades.length;

    return (wins / total) * 100;
  }

  /// Daily accuracy
  static double getDailyAccuracy({
    required List<TradeModel> allTrades,
    required String todayKey,
  }) {
    final trades =
        allTrades.where((t) => t.dayKey == todayKey).toList();

    return calculateAccuracy(trades);
  }

  /// Weekly accuracy
  static double getWeeklyAccuracy({
    required List<TradeModel> allTrades,
    required String weekKey,
  }) {
    final trades =
        allTrades.where((t) => t.weekKey == weekKey).toList();

    return calculateAccuracy(trades);
  }

  /// Yearly accuracy
  static double getYearlyAccuracy({
    required List<TradeModel> allTrades,
    required String yearKey,
  }) {
    final trades =
        allTrades.where((t) => t.yearKey == yearKey).toList();

    return calculateAccuracy(trades);
  }
}