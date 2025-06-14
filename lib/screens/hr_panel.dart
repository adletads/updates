import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HRPanel extends StatelessWidget {
  const HRPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HR Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: const Center(
        child: Text('Welcome to the HR Panel!'),
      ),
    );
  }
}
