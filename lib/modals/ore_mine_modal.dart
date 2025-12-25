import 'package:flutter/material.dart';

class OreMineModal extends StatefulWidget {
  final String oreType;
  final int hammerfells;
  final int oreCount;
  final Future<bool> Function() onMine;
  final VoidCallback onClose;
  const OreMineModal({
    super.key,
    required this.oreType,
    required this.hammerfells,
    required this.oreCount,
    required this.onMine,
    required this.onClose,
  });
  @override
  State<OreMineModal> createState() => _OreMineModalState();
}

class _OreMineModalState extends State<OreMineModal> {
  bool _mining = false;
  String? _resultText;
  int _oreCount = 0;
  int _hammerfells = 0;

  @override
  void initState() {
    super.initState();
    _oreCount = widget.oreCount;
    _hammerfells = widget.hammerfells;
  }

  String get oreLabel {
    switch (widget.oreType) {
      case 'iron': return 'Iron Ore';
      case 'copper': return 'Copper Ore';
      case 'gold': return 'Gold Ore';
      case 'diamond': return 'Diamond';
      default: return widget.oreType;
    }
  }

  Future<void> _mine() async {
    setState(() {
      _mining = true;
      _resultText = null;
    });
    final success = await widget.onMine();
    setState(() {
      _mining = false;
      if (success) {
        _oreCount++;
        _hammerfells--;
        _resultText = 'Success! You mined 1 $oreLabel.';
      } else {
        _hammerfells--;
        _resultText = 'Failed! Try again.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$oreLabel Mine', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(onPressed: _mining ? null : widget.onClose, icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 16),
          Text('Hammerfells: $_hammerfells'),
          Text('You have: $_oreCount $oreLabel'),
          const SizedBox(height: 24),
          if (_resultText != null) ...[
            Text(_resultText!, style: TextStyle(color: _resultText!.startsWith('Success') ? Colors.green : Colors.red)),
            const SizedBox(height: 12),
          ],
          ElevatedButton(
            onPressed: _mining ? null : _mine,
            child: _mining ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Mine'),
          ),
        ],
      ),
    );
  }
}
