import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mine.dart';
import '../utils/random_utils.dart';

class MineSearchModal extends StatefulWidget {
  final void Function(Mine) onEnterMine;
  final String? currentMineType;
  const MineSearchModal({super.key, required this.onEnterMine, this.currentMineType});

  @override
  State<MineSearchModal> createState() => _MineSearchModalState();
}

class _MineSearchModalState extends State<MineSearchModal> {
    Future<void> _persistMine(String oreType) async {
      final mineJson = '{"oreType": "$oreType"}';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('minepage_lastMine', mineJson);
    }
  bool _searching = true;
  String? _foundOre;
  late Timer _timer;
  late int _secondsRemaining;
  late double _progress;

  static const int searchDuration = 2; // seconds
  // Remove hardcoded ores/weights, will use config if available

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
    // Use config-driven mine type selection if available via InheritedWidget or static config
    // Try to get mining chances from main.dart (via InheritedWidget or static/global)
    // Fallback to hardcoded if not available
    Map<String, double> mineTypeChances = {
      'coal': 0.45,
      'copper': 0.25,
      'iron': 0.15,
      'gold': 0.10,
      'diamond': 0.05,
    };
    
    // Exclude current mine type if provided, and redistribute probabilities
    if (widget.currentMineType != null && mineTypeChances.containsKey(widget.currentMineType)) {
      mineTypeChances.remove(widget.currentMineType);
      // Normalize probabilities to sum to 1.0
      final total = mineTypeChances.values.fold(0.0, (sum, val) => sum + val);
      if (total > 0) {
        mineTypeChances = mineTypeChances.map((key, value) => MapEntry(key, value / total));
      }
    }
    
    // If mining chances are provided via InheritedWidget or static config, use them
    // For now, use hardcoded values only. Remove reference to _HomePageState.
    final oreNames = mineTypeChances.keys.toList();
    final weights = oreNames.map((k) => mineTypeChances[k] ?? 0.0).toList();
    return weightedRandomChoice(oreNames, weights) ?? 'coal';
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
                onPressed: () async {
                  await _persistMine(_foundOre!);
                  widget.onEnterMine(Mine(_foundOre!));
                },
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
