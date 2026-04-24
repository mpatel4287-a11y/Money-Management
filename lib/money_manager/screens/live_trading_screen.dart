import 'package:flutter/material.dart';
import '../models/trade_model.dart';
import '../models/goal_model.dart';
import '../services/trade_service.dart';
import '../services/goal_service.dart';
import '../controllers/trade_controller.dart';
import '../controllers/risk_controller.dart';
import '../utils/date_utils.dart';

class LiveTradingScreen extends StatefulWidget {
  const LiveTradingScreen({super.key});

  @override
  State<LiveTradingScreen> createState() => _LiveTradingScreenState();
}

class _LiveTradingScreenState extends State<LiveTradingScreen> {
  final TradeService _tradeService = TradeService();
  final GoalService _goalService = GoalService();

  List<TradeModel> trades = [];
  GoalModel? activeGoal;

  bool loading = false;
  final String userId = "user1";

  double currentCapital = 0;
  double dailyProfitTarget = 0;
  double dailyLossLimit = 0;
  double tradeAmount = 100;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    if (!mounted) return;
    setState(() => loading = true);
    
    try {
      // Fetch user's master goal with a timeout to avoid infinite loading
      GoalModel? g;
      try {
        g = await _goalService.getGoal(userId).timeout(const Duration(seconds: 10));
      } catch (e) {
        debugPrint("Goal fetch timeout or error: $e");
      }

      if (g == null) {
        // Use a local default if Firestore is unreachable or empty
        g = GoalModel(
          userId: userId, 
          depositAmount: 2000, 
          targetAmount: 10000, 
          targetDays: 30, 
          startDate: DateTime.now()
        );
        // Try to save it, but don't block if it fails
        _goalService.saveGoal(g).catchError((e) => debugPrint("Failed to save default goal: $e"));
      }
      
      List<TradeModel> rawTrades = [];
      try {
        rawTrades = await _tradeService.getTrades(userId).timeout(const Duration(seconds: 10));
      } catch (e) {
        debugPrint("Trades fetch timeout or error: $e");
      }
      
      rawTrades.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      double netPnL = 0;
      for (var t in rawTrades) {
         netPnL += t.profitLoss;
      }
      
      double cap = g.depositAmount + netPnL;
      
      double dTarget = RiskController.getDailyProfitTarget(goal: g, currentCapital: cap);
      double dLossLimit = RiskController.getDailyStopLoss(dailyTarget: dTarget);
      double tAmt = RiskController.getTradeAmount(dailyTarget: dTarget);
      
      if (mounted) {
        setState(() {
          activeGoal = g;
          trades = rawTrades;
          currentCapital = cap;
          dailyProfitTarget = dTarget;
          dailyLossLimit = dLossLimit;
          tradeAmount = tAmt;
          loading = false;
        });
      }
    } catch (e) {
      debugPrint("Error in fetchData: $e");
      if (mounted) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading data: $e"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  double getTodayPnL() {
    final now = DateTime.now();
    final dayKey = DateUtilsMM.getDayKey(now);
    double pnl = 0;
    for (var t in trades) {
      if (t.dayKey == dayKey) pnl += t.profitLoss;
    }
    return pnl;
  }

  bool get isCoolingDown {
    final now = DateTime.now();
    final dayKey = DateUtilsMM.getDayKey(now);
    // Get today's trades only
    final todayTrades = trades.where((t) => t.dayKey == dayKey).toList();
    
    if (todayTrades.length < 2) return false;
    
    // Sort by timestamp descending
    todayTrades.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    final lastTrade = todayTrades[0];
    final prevTrade = todayTrades[1];

    if (lastTrade.result == 'loss' && prevTrade.result == 'loss') {
      final diff = now.difference(lastTrade.timestamp);
      if (diff.inMinutes < 30) {
        return true;
      }
    }
    return false;
  }

  int get remainingCoolDownMinutes {
    final now = DateTime.now();
    final dayKey = DateUtilsMM.getDayKey(now);
    final todayTrades = trades.where((t) => t.dayKey == dayKey).toList();
    if (todayTrades.isEmpty) return 0;
    todayTrades.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final diff = now.difference(todayTrades[0].timestamp);
    return 30 - diff.inMinutes;
  }

  bool get isLocked {
    if (activeGoal == null || dailyProfitTarget == 0) return true; 
    if (isCoolingDown) return true;
    double todayPnL = getTodayPnL();
    if (todayPnL >= dailyProfitTarget) return true;
    if (todayPnL <= -dailyLossLimit) return true;
    return false;
  }

  Future<void> addTradeWithDetails(
    double profitLoss,
    String pair,
    String strategy,
    String reason,
    int confidence,
    String emotion,
  ) async {
    if (isLocked) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Locked! Check cool-down or daily limits.")));
       return;
    }

    setState(() => loading = true);
    try {
      final trade = TradeController.createTrade(
        userId: userId,
        amount: tradeAmount,
        payoutPercent: 90,
        profitLoss: profitLoss,
        pair: pair,
        reason: reason,
        confidence: confidence,
        emotion: emotion,
        strategy: strategy,
      );

      await _tradeService.addTrade(trade);
      
      // We must fetch data entirely again to recalculate the automated core constraints
      await fetchData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void showSettingsDialog() {
    if (activeGoal == null) return;
    
    final depCtrl = TextEditingController(text: activeGoal!.depositAmount.toStringAsFixed(0));
    final targCtrl = TextEditingController(text: activeGoal!.targetAmount.toStringAsFixed(0));
    final daysCtrl = TextEditingController(text: activeGoal!.targetDays.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text("Master Plan Settings", style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Set your overarching targets. The system will auto-calculate daily limits.", style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 16),
                _buildTextField(depCtrl, "Initial Deposit (₹)"),
                const SizedBox(height: 16),
                _buildTextField(targCtrl, "Target Amount (₹)"),
                const SizedBox(height: 16),
                _buildTextField(daysCtrl, "Target Days"),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent, foregroundColor: Colors.black),
              onPressed: () async {
                double? d = double.tryParse(depCtrl.text);
                double? t = double.tryParse(targCtrl.text);
                int? days = int.tryParse(daysCtrl.text);
                if (d != null && t != null && days != null) {
                  GoalModel updated = GoalModel(
                     userId: userId, 
                     depositAmount: d, 
                     targetAmount: t, 
                     targetDays: days,
                     startDate: activeGoal!.startDate, // Preserving start date
                  );
                  await _goalService.saveGoal(updated);
                  if (context.mounted) {
                     Navigator.pop(context);
                  }
                  await fetchData();
                }
              },
              child: const Text("Save Plan"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.tealAccent)),
      ),
    );
  }

  void showTradeDialog() {
    if (isLocked) {
      String message = "Your target or stop loss has been hit. Trading is locked for today.";
      if (isCoolingDown) {
        message = "Cool-down active! You lost 2 in a row. Take a $remainingCoolDownMinutes min break to avoid revenge trading.";
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(isCoolingDown ? "Session Cool-down" : "Done for the day", style: const TextStyle(color: Colors.white)),
          content: Text(message, style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK", style: TextStyle(color: Colors.tealAccent)))
          ],
        )
      );
      return;
    }

    final profitController = TextEditingController();
    final pairController = TextEditingController(text: "EUR/USD");
    final reasonController = TextEditingController();
    int confidence = 3;
    String emotion = "calm";
    String selectedStrategy = "S/R Bounce";

    final strategies = ["S/R Bounce", "Trend Follow", "Breakout", "Indicators", "Martingale"];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text("Log ITM/OTM Trade", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: pairController,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              labelText: "Pair",
                              labelStyle: const TextStyle(color: Colors.white70),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.tealAccent)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: profitController,
                            keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              labelText: "PnL (₹)",
                              labelStyle: const TextStyle(color: Colors.white70),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.tealAccent)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text("Strategy Used", style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: strategies.map((s) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(s, style: const TextStyle(fontSize: 11)),
                              selected: selectedStrategy == s,
                              selectedColor: Colors.tealAccent,
                              onSelected: (selected) { if (selected) setDialogState(() => selectedStrategy = s); },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: reasonController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Reason / Setup Notes",
                        labelStyle: const TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.tealAccent)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text("Confidence (1-5)", style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: [1, 2, 3, 4, 5].map((level) {
                        return ChoiceChip(
                          label: Text(level.toString(), style: const TextStyle(fontSize: 11)),
                          selected: confidence == level,
                          selectedColor: Colors.tealAccent,
                          labelStyle: TextStyle(color: confidence == level ? Colors.black : Colors.white, fontWeight: FontWeight.bold),
                          backgroundColor: const Color(0xFF2C2C2C),
                          onSelected: (selected) { if (selected) setDialogState(() => confidence = level); },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text("Emotional State", style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ["calm", "fear", "greed", "revenge"].map((em) {
                        return ChoiceChip(
                          label: Text(em.toUpperCase(), style: const TextStyle(fontSize: 11)),
                          selected: emotion == em,
                          selectedColor: em == 'revenge' || em == 'fear' ? Colors.redAccent : Colors.tealAccent,
                          labelStyle: TextStyle(color: emotion == em ? (em == 'revenge' || em == 'fear' ? Colors.white : Colors.black) : Colors.white, fontWeight: FontWeight.bold),
                          backgroundColor: const Color(0xFF2C2C2C),
                          onSelected: (selected) { if (selected) setDialogState(() => emotion = em); },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.white70))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () async {
                    if (profitController.text.isEmpty) return;
                    double profitLoss = double.tryParse(profitController.text) ?? 0;
                    String pair = pairController.text.isEmpty ? "EUR/USD" : pairController.text;
                    String reason = reasonController.text.isEmpty ? "Standard strategy" : reasonController.text;

                    await addTradeWithDetails(profitLoss, pair, selectedStrategy, reason, confidence, emotion);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                  child: const Text("Log ITM/OTM", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, Color color, {IconData? icon, String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white12, width: 1)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[Icon(icon, color: color, size: 18), const SizedBox(width: 8)],
              Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
          if (subtitle != null) ...[const SizedBox(height: 6), Text(subtitle, style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600))]
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (activeGoal == null) {
        return Scaffold(
          backgroundColor: const Color(0xFF121212), 
          body: Center(
            child: loading 
              ? const CircularProgressIndicator(color: Colors.tealAccent)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Could not load trading plan.", style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: fetchData, child: const Text("Retry"))
                  ],
                )
          )
        );
    }
    
    double todayPnL = getTodayPnL();
    bool cooling = isCoolingDown;
    bool safetyLocked = isLocked;
    
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Live Engine", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        actions: [
          IconButton(icon: const Icon(Icons.settings, color: Colors.white70), onPressed: showSettingsDialog)
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showTradeDialog,
        backgroundColor: safetyLocked ? Colors.grey : Colors.tealAccent,
        foregroundColor: safetyLocked ? Colors.white : Colors.black,
        icon: Icon(cooling ? Icons.timer : (safetyLocked ? Icons.lock : Icons.add)),
        label: Text(cooling ? "Cool-down active" : (safetyLocked ? "Trade Locked" : "Log Trade"), style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        color: Colors.tealAccent,
        backgroundColor: const Color(0xFF1E1E1E),
        onRefresh: fetchData,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            if (safetyLocked && dailyProfitTarget > 0) 
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1), border: Border.all(color: Colors.redAccent), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Icon(cooling ? Icons.timer : Icons.lock, color: Colors.redAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cooling 
                          ? "Cool-down active: Lost 2 in a row. Take a 30m break." 
                          : "Done for the day. You hit your auto-target limits. Preserve your capital.", 
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                      )
                    ),
                  ],
                ),
              ),
            if (dailyProfitTarget == 0) // Goal completed!
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.tealAccent.withValues(alpha: 0.1), border: Border.all(color: Colors.tealAccent), borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  children: [
                    Icon(Icons.star, color: Colors.tealAccent),
                    const SizedBox(width: 8),
                    Expanded(child: Text("GOAL HIT! You've achieved your target amount!", style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 18))),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(child: _buildStatCard("Total Capital", "₹${currentCapital.toStringAsFixed(0)}", Colors.white, icon: Icons.account_balance_wallet)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard("Next Trade", "₹${tradeAmount.toStringAsFixed(0)}", Colors.tealAccent, icon: Icons.payments, subtitle: tradeAmount <= 100 && dailyProfitTarget > 0 ? "⚠️ Min ₹100 limits active" : null)),
              ],
            ),
            const SizedBox(height: 16),
             Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white12, width: 1)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Today's Net PnL vs Auto Limits", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              todayPnL >= 0 ? "+₹${todayPnL.toStringAsFixed(2)}" : "₹${todayPnL.toStringAsFixed(2)}", 
                              style: TextStyle(color: todayPnL >= 0 ? Colors.tealAccent : Colors.redAccent, fontSize: 28, fontWeight: FontWeight.bold)
                            ),
                            if (activeGoal != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(4)),
                                child: Text(
                                  "Req: ${(RiskController.getRequiredDailyGrowthRate(activeGoal!) * 100).toStringAsFixed(1)}% / Day",
                                  style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                     value: dailyProfitTarget == 0 ? 1 : (todayPnL > 0 
                         ? (todayPnL / dailyProfitTarget).clamp(0.0, 1.0)
                         : (todayPnL.abs() / dailyLossLimit).clamp(0.0, 1.0)),
                     backgroundColor: const Color(0xFF2C2C2C),
                     color: todayPnL >= 0 ? Colors.tealAccent : Colors.redAccent,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       Text("Stop: -₹${dailyLossLimit.toStringAsFixed(0)}", style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                       Text("Target: ₹${dailyProfitTarget.toStringAsFixed(0)}", style: const TextStyle(color: Colors.tealAccent, fontSize: 12)),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
