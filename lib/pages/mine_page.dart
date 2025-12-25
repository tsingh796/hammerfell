import 'package:flutter/material.dart';

class MinePage extends StatelessWidget {
  const MinePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    void _openFurnace() {
      showModalBottomSheet(
        context: context,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        builder: (c) => const Center(child: Text('Furnace modal here')), // Replace with FurnaceModal if needed
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mine')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome to the Mine!'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _openFurnace,
              child: const Text('Furnace'),
            ),
          ],
        ),
      ),
    );
  }
}
