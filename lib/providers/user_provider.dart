import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class UserProvider extends ChangeNotifier {
  final UserService _userService = UserService();

  String? uid;
  String? name;
  String? role;
  String? department;

  bool _loading = false;
  bool get loading => _loading;

  Future<void> loadUser(String userId) async {
    _loading = true;
    notifyListeners();

    try {
      final doc = await _userService.getUser(userId);
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        uid = userId;
        name = data['name'] as String?;
        role = data['role'] as String?;
        department = data['department'] as String?;
      }
    } catch (e) {
      // Handle error
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clear() {
    uid = null;
    name = null;
    role = null;
    department = null;
    notifyListeners();
  }
}
