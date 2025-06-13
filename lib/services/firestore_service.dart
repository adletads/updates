import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');

  Future<DocumentSnapshot> getUser(String uid) {
    return usersCollection.doc(uid).get();
  }

  Future<void> setUser(String uid, Map<String, dynamic> data) {
    return usersCollection.doc(uid).set(data, SetOptions(merge: true));
  }
}

class UpdateService {
  final CollectionReference updatesCollection = FirebaseFirestore.instance.collection('updates');

  Future<DocumentSnapshot> getUpdate(String updateId) {
    return updatesCollection.doc(updateId).get();
  }

  Future<void> addUpdate(Map<String, dynamic> data, String uid, String? name) {
    final updateData = Map<String, dynamic>.from(data);
    updateData['uid'] = uid;
    updateData['name'] = name;
    return updatesCollection.add(updateData);
  }

  Future<void> updateUpdate(String updateId, Map<String, dynamic> data) {
    return updatesCollection.doc(updateId).update(data);
  }

  Future<void> deleteUpdate(String updateId) {
    return updatesCollection.doc(updateId).delete();
  }

  Stream<QuerySnapshot> getUpdatesForUser(String uid) {
    return updatesCollection.where('uid', isEqualTo: uid).orderBy('date', descending: true).snapshots();
  }

  Stream<QuerySnapshot> getAllUpdates() {
    return updatesCollection.orderBy('date', descending: true).snapshots();
  }

  Stream<QuerySnapshot> getUpdatesForUsers(List<String> uids) {
    return updatesCollection.where('uid', whereIn: uids).orderBy('date', descending: true).snapshots();
  }
}
