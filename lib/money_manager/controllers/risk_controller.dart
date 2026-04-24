import 'dart:math';
import '../models/goal_model.dart';

class RiskController {
  /// Calculates the required daily growth rate (CAGR) to reach the target amount.
  /// Formula: r = (Target / StartValue)^(1 / Days) - 1
  static double getRequiredDailyGrowthRate(GoalModel goal) {
    if (goal.targetDays <= 0 || goal.depositAmount <= 0) return 0;
    
    double ratio = goal.targetAmount / goal.depositAmount;
    return pow(ratio, 1 / goal.targetDays) - 1;
  }

  /// Calculates the dynamic daily profit target using compounding logic.
  /// This ensures that the target is a fixed percentage of your current capital,
  /// making it much more realistic than simple linear division.
  static double getDailyProfitTarget({
    required GoalModel goal,
    required double currentCapital,
  }) {
    if (currentCapital >= goal.targetAmount) return 0; // Mission accomplished

    double dailyRate = getRequiredDailyGrowthRate(goal);
    double targetProfit = currentCapital * dailyRate;
    
    // Ensure the target is at least enough to cover a minimum trade profit
    // Minimum profit from ₹100 at 90% is ₹90.
    if (targetProfit < 90 && currentCapital < goal.targetAmount) {
       return 90; 
    }

    return targetProfit;
  }

  /// Stop loss is set to 2x the daily target.
  /// This provides a realistic "buffer" allowing you to lose up to 2 trades
  /// before closing the session to protect your psychology and capital.
  static double getDailyStopLoss({
    required double dailyTarget,
  }) {
    return dailyTarget * 2;
  }

  /// Trade amount is calculated to hit the daily target in roughly 1-2 positive steps.
  /// Uses a standard 90% payout assumption.
  static double getTradeAmount({
    required double dailyTarget,
  }) {
    // To make 'dailyTarget' in one trade with 90% payout:
    double amount = dailyTarget / 0.9;
    
    if (amount < 100) {
      return 100; // Enforce broker minimum
    }
    
    return amount;
  }
}