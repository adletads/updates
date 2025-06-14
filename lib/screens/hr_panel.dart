import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';

class HRPanel extends StatefulWidget {
  const HRPanel({Key? key}) : super(key: key);

  @override
  State<HRPanel> createState() => _HRPanelState();
}

class _HRPanelState extends State<HRPanel> {
  final UserService _userService = UserService();
  
  // Controllers
  final TextEditingController _announceController = TextEditingController();
  final TextEditingController _policyController = TextEditingController();
  
  // Data
  List<QueryDocumentSnapshot> _employees = [];
  List<QueryDocumentSnapshot> _announcements = [];
  List<QueryDocumentSnapshot> _policies = [];
  bool _isLoading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _loadEmployees();
    _loadAnnouncements();
    _loadPolicies();
  }

  void _loadEmployees() {
    _userService.usersCollection.snapshots().listen((snapshot) {
      setState(() {
        _employees = snapshot.docs;
      });
    });
  }

  void _loadAnnouncements() {
    FirebaseFirestore.instance.collection('announcements').snapshots().listen((snapshot) {
      setState(() {
        _announcements = snapshot.docs;
      });
    });
  }

  void _loadPolicies() {
    FirebaseFirestore.instance.collection('policies').snapshots().listen((snapshot) {
      setState(() {
        _policies = snapshot.docs;
        _isLoading = false;
      });
    });
  }

  Future<void> _addAnnouncement() async {
    if (_announceController.text.trim().isEmpty) return;

    setState(() { _submitting = true; });
    try {
      await FirebaseFirestore.instance.collection('announcements').add({
        'content': _announceController.text.trim(),
        'date': DateTime.now().toIso8601String(),
        'by': FirebaseAuth.instance.currentUser?.email ?? 'HR',
      });
      _announceController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement posted successfully'))
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error posting announcement: $e'))
      );
    } finally {
      setState(() { _submitting = false; });
    }
  }

  Future<void> _addPolicy() async {
    if (_policyController.text.trim().isEmpty) return;

    setState(() { _submitting = true; });
    try {
      await FirebaseFirestore.instance.collection('policies').add({
        'content': _policyController.text.trim(),
        'date': DateTime.now().toIso8601String(),
        'by': FirebaseAuth.instance.currentUser?.email ?? 'HR',
      });
      _policyController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Policy added successfully'))
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding policy: $e'))
      );
    } finally {
      setState(() { _submitting = false; });
    }
  }

  @override
  void dispose() {
    _announceController.dispose();
    _policyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('HR Panel'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () => FirebaseAuth.instance.signOut(),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Employees'),
              Tab(text: 'Announcements'),
              Tab(text: 'Policies'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Employees Tab
            ListView(
              padding: const EdgeInsets.all(16),
              children: _employees.map((doc) {
                final employee = doc.data() as Map<String, dynamic>;
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: Text(employee['name'] ?? 'N/A'),
                    subtitle: Text(
                      'Department: ${employee['department'] ?? 'N/A'}\n'
                      'Role: ${employee['role'] ?? 'N/A'}',
                    ),
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        (employee['name'] as String?)?.isNotEmpty == true
                            ? (employee['name'] as String).substring(0, 1).toUpperCase()
                            : '?',
                        style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            // Announcements Tab
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Post Announcement',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _announceController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Announcement Content',
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            fillColor: Theme.of(context).colorScheme.surface,
                            filled: true,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _submitting ? null : _addAnnouncement,
                          icon: const Icon(Icons.send),
                          label: const Text('Post Announcement'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Recent Announcements',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                ..._announcements.map((doc) {
                  final announcement = doc.data() as Map<String, dynamic>;
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(announcement['content'] ?? ''),
                      subtitle: Text(
                        'Posted by ${announcement['by']} on '
                        '${DateTime.parse(announcement['date']).toString().split('.')[0]}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('announcements')
                              .doc(doc.id)
                              .delete();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Announcement deleted')),
                          );
                        },
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),

            // Policies Tab
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Policy',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _policyController,
                          maxLines: 5,
                          decoration: InputDecoration(
                            labelText: 'Policy Content',
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            fillColor: Theme.of(context).colorScheme.surface,
                            filled: true,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _submitting ? null : _addPolicy,
                          icon: const Icon(Icons.policy),
                          label: const Text('Add Policy'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Company Policies',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                ..._policies.map((doc) {
                  final policy = doc.data() as Map<String, dynamic>;
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(policy['content'] ?? ''),
                      subtitle: Text(
                        'Added by ${policy['by']} on '
                        '${DateTime.parse(policy['date']).toString().split('.')[0]}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('policies')
                              .doc(doc.id)
                              .delete();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Policy deleted')),
                          );
                        },
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
