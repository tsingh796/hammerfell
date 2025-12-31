import 'package:flutter/material.dart';

class ForestPage extends StatelessWidget {
  const ForestPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forest')),
      body: Center(
        child: const Text('Welcome to the Forest!'),
      ),
    );
  }
}
