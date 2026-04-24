import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/goal_model.dart';

class GoalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collection = "goals";

  Future<void> saveGoal(GoalModel goal) async {
    await _firestore
        .collection(collection)
        .doc(goal.userId)
        .set(goal.toMap(), SetOptions(merge: true));
  }

  Future<GoalModel?> getGoal(String userId) async {
    final doc = await _firestore.collection(collection).doc(userId).get();
    if (doc.exists && doc.data() != null) {
      return GoalModel.fromMap(doc.data()!);
    }
    return null;
  }
}
