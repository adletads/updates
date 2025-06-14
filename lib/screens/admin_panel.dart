import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../providers/user_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({Key? key}) : super(key: key);

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final UserService _userService = UserService();
  final UpdateService _updateService = UpdateService();

  // Update form controllers for admin
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _projectController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();
  final TextEditingController _newDeptController = TextEditingController();
  String _status = 'ongoing';
  bool _submitting = false;

  List<QueryDocumentSnapshot> _users = [];
  List<QueryDocumentSnapshot> _updates = [];
  List<String> _departments = [];
  bool _loadingUsers = true;
  bool _loadingUpdates = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadUpdates();
    _loadDepartments();
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

  void _loadDepartments() {
    FirebaseFirestore.instance.collection('departments').snapshots().listen((snapshot) {
      setState(() {
        _departments = snapshot.docs.map((doc) => doc['name'] as String).toList();
      });
    });
  }

  void _assignManagerRole(String uid) {
    _userService.setUser(uid, {'role': 'manager'});
  }

  Future<void> _editRemarkDialog(DocumentSnapshot updateDoc) async {
    final update = updateDoc.data() as Map<String, dynamic>;
    final TextEditingController _editRemarkController = TextEditingController(text: update['remark'] ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Remark'),
        content: TextFormField(
          controller: _editRemarkController,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Remark'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, _editRemarkController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) {
      await _updateService.updateUpdate(updateDoc.id, {'remark': result});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Remark updated')));
    }
  }

  Future<void> _submitAdminUpdate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _submitting = true; });
    final now = DateTime.now();
    final dateStr = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final uid = userProvider.uid ?? FirebaseAuth.instance.currentUser?.uid ?? '';
      final name = userProvider.name ?? FirebaseAuth.instance.currentUser?.email ?? 'Admin';
      final data = {
        'date': dateStr,
        'content': _contentController.text.trim(),
        'project': _projectController.text.trim(),
        'status': _status,
        'remark': _remarkController.text.trim(),
      };
      await _updateService.addUpdate(data, uid, name);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Update submitted')));
      _contentController.clear();
      _projectController.clear();
      _remarkController.clear();
      setState(() { _status = 'ongoing'; });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error submitting update: $e')));
    } finally {
      setState(() { _submitting = false; });
    }
  }

  Future<void> _approveUpdate(DocumentSnapshot updateDoc) async {
    await _updateService.updateUpdate(updateDoc.id, {'approved': true});
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Update approved')));
  }

  Future<void> _addDepartment() async {
    final name = _newDeptController.text.trim();
    if (name.isEmpty) return;
    await FirebaseFirestore.instance.collection('departments').add({'name': name});
    _newDeptController.clear();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Department added')));
  }

  Future<void> _assignRoleAndDepartmentDialog(DocumentSnapshot userDoc) async {
    final user = userDoc.data() as Map<String, dynamic>;
    String selectedRole = user['role'] ?? 'employee';
    String selectedDept = user['department'] ?? (_departments.isNotEmpty ? _departments.first : '');
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Role & Department'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedRole,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Role',
                labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                ),
                prefixIcon: Icon(Icons.badge_outlined, color: Theme.of(context).colorScheme.primary),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.primary),
              dropdownColor: Theme.of(context).colorScheme.surface,
              items: [
                DropdownMenuItem(
                  value: 'employee', 
                  child: Text('Employee', 
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface)
                  )
                ),
                DropdownMenuItem(
                  value: 'manager', 
                  child: Text('Manager', 
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface)
                  )
                ),
                DropdownMenuItem(
                  value: 'admin', 
                  child: Text('Admin', 
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface)
                  )
                ),
                DropdownMenuItem(
                  value: 'hr', 
                  child: Text('HR', 
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface)
                  )
                ),
              ],
              onChanged: (value) {
                if (value != null) selectedRole = value;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedDept.isNotEmpty ? selectedDept : null,
              decoration: const InputDecoration(labelText: 'Department'),
              items: _departments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
              onChanged: (value) {
                if (value != null) selectedDept = value;
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, {'role': selectedRole, 'department': selectedDept}),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) {
      await _userService.setUser(userDoc.id, {'role': result['role'], 'department': result['department']});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Role and department updated')));
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _projectController.dispose();
    _remarkController.dispose();
    _newDeptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () => FirebaseAuth.instance.signOut(),
            ),
          ],
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
                : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Add department section
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Departments',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _newDeptController,
                                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                                      cursorColor: Theme.of(context).colorScheme.primary,
                                      decoration: InputDecoration(
                                        labelText: 'Department Name',
                                        labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
                                        filled: true,
                                        fillColor: Theme.of(context).colorScheme.surface,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                                        ),
                                        prefixIcon: Icon(Icons.business, color: Theme.of(context).colorScheme.primary),
                                        hintText: 'Enter department name',
                                        hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton.icon(
                                    onPressed: _addDepartment,
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                                      backgroundColor: Theme.of(context).colorScheme.primary,
                                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                    ),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add'),
                                  ),
                                ],
                              ),
                              if (_departments.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Text(
                                  'Current Departments',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _departments.map((d) => Chip(
                                    label: Text(d),
                                    labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                                    backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                                    side: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
                                  )).toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Expanded(
                          child: AnimatedList(
                            key: ValueKey('userList'),
                            initialItemCount: _users.length,
                            itemBuilder: (context, index, animation) {
                              final userDoc = _users[index];
                              final user = userDoc.data() as Map<String, dynamic>;
                              return SizeTransition(
                                sizeFactor: animation,
                                child: Card(
                                  elevation: 6,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                                  child: ListTile(
                                    title: Text(user['name'] ?? ''),
                                    subtitle: Text('Role: ${user['role'] ?? 'N/A'} - Dept: ${user['department'] ?? 'N/A'}'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        user['role'] == 'manager'
                                            ? const Text('Manager')
                                            : ElevatedButton(
                                                onPressed: () => _assignManagerRole(userDoc.id),
                                                style: ElevatedButton.styleFrom(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                                ),
                                                child: const Text('Assign Manager'),
                                              ),
                                        IconButton(
                                          icon: const Icon(Icons.admin_panel_settings),
                                          tooltip: 'Assign Role & Department',
                                          onPressed: () => _assignRoleAndDepartmentDialog(userDoc),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
            _loadingUpdates
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Submit Update',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _contentController,
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                              cursorColor: Theme.of(context).colorScheme.primary,
                              maxLines: 5,
                              validator: (value) => value == null || value.isEmpty ? 'Please enter update content' : null,
                              decoration: InputDecoration(
                                labelText: 'Update Content',
                                labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
                                filled: true,
                                fillColor: Theme.of(context).colorScheme.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _projectController,
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                              cursorColor: Theme.of(context).colorScheme.primary,
                              decoration: InputDecoration(
                                labelText: 'Project Name',
                                labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
                                filled: true,
                                fillColor: Theme.of(context).colorScheme.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                                ),
                                prefixIcon: Icon(Icons.folder_outlined, color: Theme.of(context).colorScheme.primary),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              validator: (value) => value == null || value.isEmpty ? 'Please enter project name' : null,
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _status,
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                              decoration: InputDecoration(
                                labelText: 'Status',
                                labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
                                filled: true,
                                fillColor: Theme.of(context).colorScheme.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                                ),
                                prefixIcon: Icon(Icons.flag_outlined, color: Theme.of(context).colorScheme.primary),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.primary),
                              dropdownColor: Theme.of(context).colorScheme.surface,
                              items: <DropdownMenuItem<String>>[
                                DropdownMenuItem<String>(
                                  value: 'ongoing',
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.trending_up, color: Colors.blue, size: 20),
                                      const SizedBox(width: 8),
                                      Text('Ongoing',
                                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface)
                                      ),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem<String>(
                                  value: 'blocked',
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.error_outline, color: Colors.red, size: 20),
                                      const SizedBox(width: 8),
                                      Text('Blocked',
                                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface)
                                      ),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem<String>(
                                  value: 'completed',
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                                      const SizedBox(width: 8),
                                      Text('Completed',
                                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface)
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _status = value;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _remarkController,
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                              cursorColor: Theme.of(context).colorScheme.primary,
                              decoration: InputDecoration(
                                labelText: 'Remark (optional)',
                                labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
                                filled: true,
                                fillColor: Theme.of(context).colorScheme.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 12),
                            _submitting
                                ? const Center(child: CircularProgressIndicator())
                                : AnimatedScale(
                                    scale: _submitting ? 0.95 : 1.0,
                                    duration: const Duration(milliseconds: 200),
                                    child: ElevatedButton(
                                      onPressed: _submitAdminUpdate,
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                                      ),
                                      child: const Text('Submit Update'),
                                    ),
                                  ),
                            const Divider(height: 32),
                          ],
                        ),
                      ),
                      const Text(
                        'All Updates',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _updates.isEmpty
                          ? const Text('No updates found.')
                          : AnimatedList(
                              key: ValueKey('updateList'),
                              initialItemCount: _updates.length,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index, animation) {
                                final updateDoc = _updates[index];
                                final update = updateDoc.data() as Map<String, dynamic>;
                                return SizeTransition(
                                  sizeFactor: animation,
                                  child: Card(
                                    elevation: 6,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                                    child: ListTile(
                                      title: Text(update['content'] ?? ''),
                                      subtitle: Text(
                                        'By ${update['name'] ?? ''} on ${update['date'] ?? ''}\nProject: ${update['project'] ?? ''}${(update['remark'] != null && update['remark'].toString().isNotEmpty) ? '\nRemark: ${update['remark']}' : ''}\nApproved: ${update['approved'] == true ? 'Yes' : 'No'}',
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(update['status'] ?? ''),
                                          IconButton(
                                            icon: const Icon(Icons.edit),
                                            tooltip: 'Edit Remark',
                                            onPressed: () => _editRemarkDialog(updateDoc),
                                          ),
                                          if (update['approved'] != true)
                                            IconButton(
                                              icon: const Icon(Icons.check_circle, color: Colors.green),
                                              tooltip: 'Approve Update',
                                              onPressed: () => _approveUpdate(updateDoc),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
