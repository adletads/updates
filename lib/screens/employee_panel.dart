import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/firestore_service.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmployeePanel extends StatefulWidget {
  const EmployeePanel({Key? key}) : super(key: key);

  @override
  State<EmployeePanel> createState() => _EmployeePanelState();
}

class _EmployeePanelState extends State<EmployeePanel> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _projectController = TextEditingController();
  String _status = 'ongoing';
  bool _loading = false;
  final UpdateService _updateService = UpdateService();

  List<Map<String, dynamic>> _previousUpdates = [];
  bool _loadingUpdates = true;

  @override
  void initState() {
    super.initState();
    _loadPreviousUpdates();
  }

  void _loadPreviousUpdates() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final uid = userProvider.uid ?? FirebaseAuth.instance.currentUser?.uid ?? '';
    _updateService.getUpdatesForUser(uid).listen((snapshot) {
      setState(() {
        _previousUpdates = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
        _loadingUpdates = false;
      });
    });
  }

  Future<void> _submitUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(now);

    final data = {
      'date': dateStr,
      'content': _contentController.text.trim(),
      'project': _projectController.text.trim(),
      'status': _status,
    };

    try {
      final uid = userProvider.uid ?? FirebaseAuth.instance.currentUser?.uid ?? '';
      final name = userProvider.name ?? FirebaseAuth.instance.currentUser?.email ?? '';
      await _updateService.addUpdate(data, uid, name);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Update submitted')));
      _contentController.clear();
      _projectController.clear();
      setState(() {
        _status = 'ongoing';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error submitting update: $e')));
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _projectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Panel'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(labelText: 'Update Content'),
                maxLines: 5,
                validator: (value) => value == null || value.isEmpty ? 'Please enter update content' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _projectController,
                decoration: const InputDecoration(labelText: 'Project Name'),
                validator: (value) => value == null || value.isEmpty ? 'Please enter project name' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'ongoing', child: Text('Ongoing')),
                  DropdownMenuItem(value: 'blocked', child: Text('Blocked')),
                  DropdownMenuItem(value: 'completed', child: Text('Completed')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _status = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitUpdate,
                      child: const Text('Submit Update'),
                    ),
              const SizedBox(height: 24),
              const Text('Previous Updates', style: TextStyle(fontWeight: FontWeight.bold)),
              _loadingUpdates
                  ? const Center(child: CircularProgressIndicator())
                  : _previousUpdates.isEmpty
                      ? const Text('No previous updates found.')
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _previousUpdates.length,
                          itemBuilder: (context, index) {
                            final update = _previousUpdates[index];
                            return Card(
                              child: ListTile(
                                title: Text(update['content'] ?? ''),
                                subtitle: Text('Project: ${update['project'] ?? ''}\nStatus: ${update['status'] ?? ''}\nDate: ${update['date'] ?? ''}'),
                              ),
                            );
                          },
                        ),
            ],
          ),
        ),
      ),
    );
  }
}
