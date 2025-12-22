import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/mine.dart';

class MineSearchModal extends StatefulWidget {
  final void Function(Mine) onEnterMine;
  const MineSearchModal({super.key, required this.onEnterMine});

  @override
  State<MineSearchModal> createState() => _MineSearchModalState();
}

class _MineSearchModalState extends State<MineSearchModal> {
  bool _searching = true;
  String? _foundOre;
  late Timer _timer;
  late int _secondsRemaining;
  late double _progress;

  static const int searchDuration = 8; // seconds
  static const List<String> ores = ['copper', 'iron', 'gold', 'diamond'];
  static const List<double> weights = [0.5, 0.3, 0.15, 0.05]; // sum to 1

  @override
  void initState() {
    super.initState();
    _startSearch();
  }

  void _startSearch() {
    setState(() {
      _searching = true;
      _foundOre = null;
      _secondsRemaining = searchDuration;
      _progress = 0.0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsRemaining--;
        _progress = 1 - (_secondsRemaining / searchDuration);
        if (_secondsRemaining <= 0) {
          final ore = _pickRandomOre();
          _searching = false;
          _foundOre = ore;
          _timer.cancel();
        }
      });
    });
  }

  String _pickRandomOre() {
    final rng = Random();
    double roll = rng.nextDouble();
    double acc = 0;
    for (int i = 0; i < ores.length; i++) {
      acc += weights[i];
      if (roll < acc) return ores[i];
    }
    return ores.last;
  }

  @override
  void dispose() {
    if (_timer.isActive) _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_searching) {
      final int minutes = _secondsRemaining ~/ 60;
      final int seconds = _secondsRemaining % 60;
      final String timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}' ;
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Searching for a new mine...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            LinearProgressIndicator(
              minHeight: 8,
              value: _progress,
            ),
            const SizedBox(height: 16),
            Text('Time remaining: $timeStr', style: const TextStyle(fontSize: 16)),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Found ${_foundOre![0].toUpperCase()}${_foundOre!.substring(1)} Mine!', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => widget.onEnterMine(Mine(_foundOre!)),
                child: const Text('Enter Mine'),
              ),
              OutlinedButton(
                onPressed: _startSearch,
                child: const Text('Keep Searching'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
