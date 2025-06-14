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

class _EmployeePanelState extends State<EmployeePanel> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _projectController = TextEditingController();
  String _status = 'ongoing';
  bool _loading = false;
  final UpdateService _updateService = UpdateService();

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  List<Map<String, dynamic>> _previousUpdates = [];
  bool _loadingUpdates = true;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
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

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'ongoing':
        return Colors.blue;
      case 'blocked':
        return Colors.red;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'ongoing':
        return Icons.trending_up;
      case 'blocked':
        return Icons.error_outline;
      case 'completed':
        return Icons.check_circle_outline;
      default:
        return Icons.help_outline;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _contentController.dispose();
    _projectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Updates'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _contentController.clear();
          _projectController.clear();
          setState(() => _status = 'ongoing');
        },
        label: const Text('New Update'),
        icon: const Icon(Icons.add),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'New Update',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _contentController,
                              decoration: InputDecoration(
                                labelText: 'Update Content',
                                hintText: 'What did you work on today?',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Theme.of(context).colorScheme.surface,
                              ),
                              maxLines: 5,
                              validator: (value) => value == null || value.isEmpty ? 'Please enter update content' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _projectController,
                              decoration: InputDecoration(
                                labelText: 'Project Name',
                                hintText: 'Enter the project name',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Theme.of(context).colorScheme.surface,
                                prefixIcon: const Icon(Icons.folder_outlined),
                              ),
                              validator: (value) => value == null || value.isEmpty ? 'Please enter project name' : null,
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _status,
                              decoration: InputDecoration(
                                labelText: 'Status',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Theme.of(context).colorScheme.surface,
                                prefixIcon: Icon(
                                  _getStatusIcon(_status),
                                  color: _getStatusColor(_status),
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'ongoing',
                                  child: Row(
                                    children: [
                                      Icon(Icons.trending_up, color: Colors.blue),
                                      SizedBox(width: 8),
                                      Text('Ongoing'),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'blocked',
                                  child: Row(
                                    children: [
                                      Icon(Icons.error_outline, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Blocked'),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'completed',
                                  child: Row(
                                    children: [
                                      Icon(Icons.check_circle_outline, color: Colors.green),
                                      SizedBox(width: 8),
                                      Text('Completed'),
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
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: _loading
                                  ? const Center(child: CircularProgressIndicator())
                                  : ElevatedButton(
                                      onPressed: _submitUpdate,
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.send),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Submit Update',
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  color: Theme.of(context).colorScheme.onPrimary,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Previous Updates',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
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
                                          return AnimatedBuilder(
                                            animation: _controller,
                                            builder: (context, child) {
                                              final delay = index * 0.2;
                                              final animValue = _controller.value - delay;
                                              final opacity = animValue.clamp(0.0, 1.0);
                                              final slideY = (1 - opacity) * 20;

                                              return Opacity(
                                                opacity: opacity,
                                                child: Transform.translate(
                                                  offset: Offset(0, slideY),
                                                  child: Card(
                                                    elevation: 2,
                                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                                    child: ListTile(
                                                      title: Text(
                                                        update['content'] ?? '',
                                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                                      ),
                                                      subtitle: Padding(
                                                        padding: const EdgeInsets.only(top: 8),
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text('Project: ${update['project'] ?? ''}'),
                                                            Row(
                                                              children: [
                                                                Container(
                                                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                                  decoration: BoxDecoration(
                                                                    color: _getStatusColor(update['status']),
                                                                    borderRadius: BorderRadius.circular(12),
                                                                  ),
                                                                  child: Text(
                                                                    update['status']?.toUpperCase() ?? '',
                                                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                                                  ),
                                                                ),
                                                                const SizedBox(width: 8),
                                                                Text(update['date'] ?? ''),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
