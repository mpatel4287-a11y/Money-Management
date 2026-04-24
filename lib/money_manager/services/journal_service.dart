import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/journal_model.dart';

class JournalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collection = "daily_journals";

  Future<void> saveJournal(JournalModel journal) async {
    String docId = "${journal.userId}_${journal.dayKey}";
    await _firestore
        .collection(collection)
        .doc(docId)
        .set(journal.toMap(), SetOptions(merge: true));
  }

  Future<String?> getJournal(String userId, String dayKey) async {
    String docId = "${userId}_$dayKey";
    final doc = await _firestore.collection(collection).doc(docId).get();
    
    if (doc.exists && doc.data() != null) {
       return JournalModel.fromMap(doc.data()!).reflection;
    }
    return null;
  }
}
