import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trade_model.dart';

class TradeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 📌 Collection reference
  final String collection = "trades";

  /// ✅ Add trade to Firestore
  Future<void> addTrade(TradeModel trade) async {
    await _firestore
        .collection(collection)
        .doc(trade.tradeId)
        .set(trade.toMap());
  }

  /// ✅ Get all trades of a user
  Future<List<TradeModel>> getTrades(String userId) async {
    final snapshot = await _firestore
        .collection(collection)
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs
        .map((doc) => TradeModel.fromMap(doc.data()))
        .toList();
  }

  /// ✅ Get trades by day
  Future<List<TradeModel>> getTradesByDay(
      String userId, String dayKey) async {
    final snapshot = await _firestore
        .collection(collection)
        .where('userId', isEqualTo: userId)
        .where('dayKey', isEqualTo: dayKey)
        .get();

    return snapshot.docs
        .map((doc) => TradeModel.fromMap(doc.data()))
        .toList();
  }

  /// ✅ Get trades by week
  Future<List<TradeModel>> getTradesByWeek(
      String userId, String weekKey) async {
    final snapshot = await _firestore
        .collection(collection)
        .where('userId', isEqualTo: userId)
        .where('weekKey', isEqualTo: weekKey)
        .get();

    return snapshot.docs
        .map((doc) => TradeModel.fromMap(doc.data()))
        .toList();
  }

  /// ✅ Get trades by year
  Future<List<TradeModel>> getTradesByYear(
      String userId, String yearKey) async {
    final snapshot = await _firestore
        .collection(collection)
        .where('userId', isEqualTo: userId)
        .where('yearKey', isEqualTo: yearKey)
        .get();

    return snapshot.docs
        .map((doc) => TradeModel.fromMap(doc.data()))
        .toList();
  }

  /// ❌ Delete a trade
  Future<void> deleteTrade(String tradeId) async {
    await _firestore.collection(collection).doc(tradeId).delete();
  }

  /// 🔄 Update a trade
  Future<void> updateTrade(TradeModel trade) async {
    await _firestore
        .collection(collection)
        .doc(trade.tradeId)
        .update(trade.toMap());
  }
}