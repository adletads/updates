import 'package:flutter/material.dart';

class HRPanel extends StatelessWidget {
  const HRPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HR Panel'),
      ),
      body: const Center(
        child: Text('Welcome to the HR Panel!'),
      ),
    );
  }
}
