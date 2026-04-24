import 'package:flutter/material.dart';
import '../models/trade_model.dart';
import '../services/trade_service.dart';
import '../controllers/accuracy_controller.dart';
import '../utils/date_utils.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TradeService _tradeService = TradeService();
  List<TradeModel> trades = [];
  bool loading = false;
  final String userId = "user1";

  @override
  void initState() {
    super.initState();
    fetchTrades();
  }

  Future<void> fetchTrades() async {
    if (!mounted) return;
    setState(() => loading = true);
    try {
      final data = await _tradeService.getTrades(userId).timeout(const Duration(seconds: 15));
      data.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      if (mounted) setState(() => trades = data);
    } catch (e) {
      debugPrint("Error fetching trades: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading trades: $e"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Widget _buildAccuracyCircle(String title, double percentage) {
    return Column(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: percentage / 100,
                strokeWidth: 8,
                backgroundColor: const Color(0xFF2C2C2C),
                color: Colors.blueAccent,
                strokeCap: StrokeCap.round,
              ),
              Center(child: Text("${percentage.toStringAsFixed(0)}%", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayKey = DateUtilsMM.getDayKey(now);
    final weekKey = DateUtilsMM.getWeekKey(now);
    final yearKey = DateUtilsMM.getYearKey(now);

    double dailyAcc = AccuracyController.getDailyAccuracy(allTrades: trades, todayKey: dayKey);
    double weeklyAcc = AccuracyController.getWeeklyAccuracy(allTrades: trades, weekKey: weekKey);
    double yearlyAcc = AccuracyController.getYearlyAccuracy(allTrades: trades, yearKey: yearKey);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(title: const Text("History & Accuracy", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24))),
      body: loading && trades.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Colors.tealAccent))
          : RefreshIndicator(
              color: Colors.tealAccent,
              backgroundColor: const Color(0xFF1E1E1E),
              onRefresh: fetchTrades,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildAccuracyCircle("Daily", dailyAcc),
                        _buildAccuracyCircle("Weekly", weeklyAcc),
                        _buildAccuracyCircle("Yearly", yearlyAcc),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text("All Trades", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (trades.isEmpty)
                    const Padding(padding: EdgeInsets.all(32.0), child: Center(child: Text("No trades logged yet.", style: TextStyle(color: Colors.white54)))),
                  ...trades.map((t) {
                    bool isWin = t.result == "win";
                    return Dismissible(
                      key: Key(t.tradeId),
                      direction: DismissDirection.endToStart,
                      background: Container(
                         alignment: Alignment.centerRight,
                         padding: const EdgeInsets.only(right: 20),
                         color: Colors.redAccent,
                         child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) async {
                         try {
                           await _tradeService.deleteTrade(t.tradeId);
                           if (!context.mounted) return;
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Trade deleted")));
                           fetchTrades();
                         } catch (e) {
                           debugPrint("Delete Error: $e");
                         }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12), border: Border(left: BorderSide(color: isWin ? Colors.tealAccent : Colors.redAccent, width: 4))),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("${t.pair} (${t.result.toUpperCase() == 'WIN' ? 'ITM' : 'OTM'})", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(isWin ? "+₹${t.profitLoss.toStringAsFixed(2)}" : "₹${t.profitLoss.toStringAsFixed(2)}", style: TextStyle(color: isWin ? Colors.tealAccent : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(4)), child: Text(t.strategy.toUpperCase(), style: const TextStyle(color: Colors.tealAccent, fontSize: 10, fontWeight: FontWeight.bold))),
                                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(4)), child: Text("Conf: ${t.confidence}/5", style: const TextStyle(color: Colors.white70, fontSize: 10))),
                                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(4)), child: Text(t.emotion.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 10))),
                              ],
                            ),
                          ),
                        ),
                      )
                    );
                  })
                ],
              ),
            ),
    );
  }
}
