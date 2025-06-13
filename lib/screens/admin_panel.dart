import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({Key? key}) : super(key: key);

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final UserService _userService = UserService();
  final UpdateService _updateService = UpdateService();

  List<QueryDocumentSnapshot> _users = [];
  List<QueryDocumentSnapshot> _updates = [];
  bool _loadingUsers = true;
  bool _loadingUpdates = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadUpdates();
  }

  void _loadUsers() {
    _userService.usersCollection.snapshots().listen((snapshot) {
      setState(() {
        _users = snapshot.docs;
        _loadingUsers = false;
      });
    });
  }

  void _loadUpdates() {
    _updateService.getAllUpdates().listen((snapshot) {
      setState(() {
        _updates = snapshot.docs;
        _loadingUpdates = false;
      });
    });
  }

  void _assignManagerRole(String uid) {
    _userService.setUser(uid, {'role': 'manager'});
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Users'),
              Tab(text: 'Updates'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _loadingUsers
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index].data() as Map<String, dynamic>;
                      return ListTile(
                        title: Text(user['name'] ?? ''),
                        subtitle: Text('Role: ${user['role'] ?? 'N/A'} - Dept: ${user['department'] ?? 'N/A'}'),
                        trailing: user['role'] == 'manager'
                            ? const Text('Manager')
                            : ElevatedButton(
                                onPressed: () => _assignManagerRole(_users[index].id),
                                child: const Text('Assign Manager'),
                              ),
                      );
                    },
                  ),
            _loadingUpdates
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _updates.length,
                    itemBuilder: (context, index) {
                      final update = _updates[index].data() as Map<String, dynamic>;
                      return ListTile(
                        title: Text(update['content'] ?? ''),
                        subtitle: Text('By ${update['name'] ?? ''} on ${update['date'] ?? ''}'),
                        trailing: Text(update['status'] ?? ''),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
