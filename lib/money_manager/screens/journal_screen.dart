import 'package:flutter/material.dart';
import '../models/trade_model.dart';
import '../models/journal_model.dart';
import '../services/trade_service.dart';
import '../services/journal_service.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final TradeService _tradeService = TradeService();
  final JournalService _journalService = JournalService();

  Map<String, List<TradeModel>> groupedTrades = {};
  Map<String, String> dailyReflections = {};
  
  bool loading = false;
  final String userId = "user1";

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    if (!mounted) return;
    setState(() => loading = true);
    try {
      final trades = await _tradeService.getTrades(userId).timeout(const Duration(seconds: 15));
      trades.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      Map<String, List<TradeModel>> tempGrp = {};
      for (var t in trades) {
        if (!tempGrp.containsKey(t.dayKey)) {
          tempGrp[t.dayKey] = [];
        }
        tempGrp[t.dayKey]!.add(t);
      }

      // Fetch reflections for each day concurrently for better performance
      final dayKeys = tempGrp.keys.toList();
      final reflectionFutures = dayKeys.map((dayKey) => _journalService.getJournal(userId, dayKey));
      final reflections = await Future.wait(reflectionFutures).timeout(const Duration(seconds: 10));
      
      Map<String, String> tempRef = {};
      for (int i = 0; i < dayKeys.length; i++) {
        if (reflections[i] != null) {
          tempRef[dayKeys[i]] = reflections[i]!;
        }
      }

      if (mounted) {
        setState(() {
          groupedTrades = tempGrp;
          dailyReflections = tempRef;
        });
      }
    } catch (e) {
      debugPrint("Error fetching journal data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not load journal: $e"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> saveReflection(String dayKey, String text) async {
    try {
      JournalModel j = JournalModel(dayKey: dayKey, userId: userId, reflection: text);
      await _journalService.saveJournal(j);
      setState(() {
        dailyReflections[dayKey] = text;
      });
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reflection saved")));
      }
    } catch (e) {
      debugPrint("Save error: $e");
    }
  }

  Future<void> _deleteTrade(String tradeId) async {
    try {
       await _tradeService.deleteTrade(tradeId);
       fetchData(); // Refresh UI
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Trade deleted")));
       }
    } catch (e) {
       debugPrint("Delete Error: $e");
    }
  }

  void _showReflectionDialog(String dayKey, String currentText) {
    final ctrl = TextEditingController(text: currentText);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text("Reflect on $dayKey", style: const TextStyle(color: Colors.white)),
          content: TextField(
            controller: ctrl,
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "How was your trading day? Did you follow your rules?",
              hintStyle: TextStyle(color: Colors.white30),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.tealAccent)),
            ),
          ),
          actions: [
             TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.white70))),
             ElevatedButton(
               style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent, foregroundColor: Colors.black),
               onPressed: () {
                 saveReflection(dayKey, ctrl.text);
                 Navigator.pop(context);
               }, 
               child: const Text("Save")
             )
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> sortedDays = groupedTrades.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(title: const Text("Trading Journal", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24))),
      body: loading && groupedTrades.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Colors.tealAccent))
          : RefreshIndicator(
              color: Colors.tealAccent,
              backgroundColor: const Color(0xFF1E1E1E),
              onRefresh: fetchData,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: sortedDays.length,
                itemBuilder: (context, index) {
                  String dayKey = sortedDays[index];
                  List<TradeModel> dayTrades = groupedTrades[dayKey]!;
                  String reflection = dailyReflections[dayKey] ?? "";

                  return Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Text(dayKey, style: const TextStyle(color: Colors.tealAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                         const Divider(color: Colors.white24),
                         ...dayTrades.map((t) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                   Icon(t.result == 'win' ? Icons.check_circle : Icons.cancel, color: t.result == 'win' ? Colors.tealAccent : Colors.redAccent, size: 20),
                                   const SizedBox(width: 8),
                                   Expanded(
                                     child: Column(
                                       crossAxisAlignment: CrossAxisAlignment.start,
                                       children: [
                                         Text("${t.pair} | ${t.result == 'win' ? 'ITM' : 'OTM'} | ${t.profitLoss > 0 ? '+' : ''}₹${t.profitLoss.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                         const SizedBox(height: 4),
                                         Text("Strategy: ${t.strategy} | Reason: ${t.reason}", style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic, fontSize: 11)),
                                       ]
                                     )
                                   ),
                                   IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.white30, size: 20),
                                      onPressed: () => _deleteTrade(t.tradeId),
                                   )
                                ],
                              ),
                            );
                         }),
                         const SizedBox(height: 16),
                         Container(
                           padding: const EdgeInsets.all(12),
                           decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               const Text("Day Reflection", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                               const SizedBox(height: 8),
                               Text(reflection.isEmpty ? "No reflection written for this day." : reflection, style: const TextStyle(color: Colors.white)),
                               const SizedBox(height: 12),
                               SizedBox(
                                 width: double.infinity,
                                 child: OutlinedButton.icon(
                                   icon: const Icon(Icons.edit, size: 16),
                                   label: Text(reflection.isEmpty ? "Write Reflection" : "Edit Reflection"),
                                   style: OutlinedButton.styleFrom(foregroundColor: Colors.tealAccent, side: const BorderSide(color: Colors.tealAccent)),
                                   onPressed: () => _showReflectionDialog(dayKey, reflection),
                                 ),
                               )
                             ],
                           ),
                         )
                      ],
                    ),
                  );
                },
              ),
          )
    );
  }
}
