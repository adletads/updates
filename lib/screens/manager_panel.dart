import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/user_provider.dart';
import '../services/firestore_service.dart';

class ManagerPanel extends StatefulWidget {
  const ManagerPanel({Key? key}) : super(key: key);

  @override
  State<ManagerPanel> createState() => _ManagerPanelState();
}

class _ManagerPanelState extends State<ManagerPanel> {
  final UpdateService _updateService = UpdateService();
  List<QueryDocumentSnapshot> _updates = [];
  bool _loading = true;

  String? _filterName;
  String? _filterProject;
  String? _filterStatus;
  DateTimeRange? _filterDateRange;

  @override
  void initState() {
    super.initState();
    _loadUpdates();
  }

  Future<void> _loadUpdates() async {
    setState(() {
      _loading = true;
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    // For demo, fetch all updates. In real app, filter by assigned team uids.
    _updateService.getAllUpdates().listen((snapshot) {
      setState(() {
        _updates = snapshot.docs;
        _loading = false;
      });
    });
  }

  void _applyFilters() {
    // TODO: Implement filtering logic based on _filterName, _filterProject, _filterStatus, _filterDateRange
    // For now, just reload all updates
    _loadUpdates();
  }

  Future<void> _approveUpdate(DocumentSnapshot updateDoc) async {
    await _updateService.updateUpdate(updateDoc.id, {'approved': true});
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Update approved')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manager Panel'),
      ),
      body: Column(
        children: [
          ExpansionTile(
            title: const Text('Filters'),
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  cursorColor: Theme.of(context).colorScheme.primary,
                  decoration: InputDecoration(
                    labelText: 'Employee Name',
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
                  onChanged: (value) {
                    setState(() {
                      _filterName = value.isEmpty ? null : value;
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  cursorColor: Theme.of(context).colorScheme.primary,
                  decoration: InputDecoration(
                    labelText: 'Project',
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
                  onChanged: (value) {
                    setState(() {
                      _filterProject = value.isEmpty ? null : value;
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButtonFormField<String>(
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
                  items: [
                    DropdownMenuItem(
                      value: null, 
                      child: Text('All Statuses', 
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface)
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'ongoing',
                      child: Row(
                        children: [
                          Icon(Icons.trending_up, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Text('Ongoing', 
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface)
                          ),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'blocked',
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Text('Blocked', 
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface)
                          ),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'completed',
                      child: Row(
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
                    _filterStatus = value;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _updates.length,
                    itemBuilder: (context, index) {
                      final update = _updates[index].data() as Map<String, dynamic>;
                      return ListTile(
                        title: Text(update['content'] ?? ''),
                        subtitle: Text('By ${update['name'] ?? ''} on ${update['date'] ?? ''}\nProject: ${update['project'] ?? ''}${(update['remark'] != null && update['remark'].toString().isNotEmpty) ? '\nRemark: ${update['remark']}' : ''}\nApproved: ${update['approved'] == true ? 'Yes' : 'No'}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(update['status'] ?? ''),
                            if (update['approved'] != true)
                              IconButton(
                                icon: const Icon(Icons.check_circle, color: Colors.green),
                                tooltip: 'Approve Update',
                                onPressed: () => _approveUpdate(_updates[index]),
                              ),
                          ],
                        ),
                        onTap: () {
                          // TODO: Show update details and allow commenting/feedback
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
