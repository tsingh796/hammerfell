
import 'package:flutter/material.dart';
import '../modals/mine_search_modal.dart';
import '../models/mine.dart';


class MinePage extends StatefulWidget {
  final int hammerfells;
  final Map<String, double> miningChances;
  final Future<bool> Function(String) onMine;
  final VoidCallback? onOpenFurnace;
  final Map<String, Map<String, double>> mineOreChances;
  final String Function(String) pickOreForMine;
  final bool hasEnteredMine;
  final dynamic initialMine;
  final void Function(dynamic)? onEnterMine;
  final VoidCallback? onSearchNewMine;

  const MinePage({
    Key? key,
    required this.hammerfells,
    required this.miningChances,
    required this.onMine,
    required this.mineOreChances,
    required this.pickOreForMine,
    this.onOpenFurnace,
    this.hasEnteredMine = false,
    this.initialMine,
    this.onEnterMine,
    this.onSearchNewMine,
  }) : super(key: key);

  @override
  State<MinePage> createState() => _MinePageState();
}

class _MinePageState extends State<MinePage> {
  dynamic _currentMine;
  bool _mining = false;
  String? _mineResult;
  // Each slot: {'type': oreType, 'count': int}
  final List<Map<String, dynamic>?> _backpack = List.filled(5, null, growable: false);

  void _searchMine() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).dialogBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: MineSearchModal(
          onEnterMine: (mine) {
            Navigator.of(context).pop();
            setState(() {
              _currentMine = mine;
            });
            if (widget.onEnterMine != null) widget.onEnterMine!(mine);
          },
        ),
      ),
    );
  }

  void _openFurnace() {
    if (widget.onOpenFurnace != null) {
      widget.onOpenFurnace!();
    } else {
      showModalBottomSheet(
        context: context,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        builder: (c) => const Center(child: Text('Furnace modal here')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentMine == null && widget.initialMine != null) {
      _currentMine = widget.initialMine;
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Mine')),
      body: Stack(
        children: [
          // Main content area
          Center(
            child: (_currentMine == null)
                ? const Text('Search for a mine to begin!')
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Entered ${_currentMine!.oreType[0].toUpperCase()}${_currentMine!.oreType.substring(1)} Mine!'),
                      const SizedBox(height: 20),
                      Center(
                        child: GestureDetector(
                          onTap: _mining
                              ? null
                              : () async {
                                  setState(() {
                                    _mining = true;
                                    _mineResult = null;
                                  });
                                  final oreType = widget.pickOreForMine(_currentMine!.oreType);
                                  final success = await widget.onMine(oreType);
                                  setState(() {
                                    _mining = false;
                                    _mineResult = success ? 'Mined $oreType!' : 'Failed!';
                                    if (success) {
                                      bool added = false;
                                      for (var slot in _backpack) {
                                        if (slot != null && slot['type'] == oreType && (slot['count'] as int) < 64) {
                                          slot['count'] = (slot['count'] as int) + 1;
                                          added = true;
                                          break;
                                        }
                                      }
                                      if (!added) {
                                        for (int i = 0; i < _backpack.length; i++) {
                                          if (_backpack[i] == null) {
                                            _backpack[i] = {'type': oreType, 'count': 1};
                                            added = true;
                                            break;
                                          }
                                        }
                                      }
                                    }
                                  });
                                },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: _mining
                                  ? Colors.grey
                                  : Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: _mining
                                ? const CircularProgressIndicator()
                                : const Icon(Icons.construction, size: 48, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Backpack grid
                      Column(
                        children: [
                          const Text('Backpack', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 60,
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 5,
                                mainAxisSpacing: 4,
                                crossAxisSpacing: 4,
                                childAspectRatio: 1,
                              ),
                              itemCount: 5,
                              itemBuilder: (context, index) {
                                final slot = _backpack[index];
                                return Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                    color: slot == null ? Colors.transparent : Colors.amber[200],
                                  ),
                                  alignment: Alignment.center,
                                  child: slot != null
                                      ? Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              slot['type'][0].toUpperCase() + slot['type'].substring(1),
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              '${slot['count']}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                            ),
                                          ],
                                        )
                                      : const SizedBox.shrink(),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      if (_mineResult != null) ...[
                        const SizedBox(height: 12),
                        Text(_mineResult!, style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _currentMine = null;
                            _mineResult = null;
                          });
                        },
                        child: const Text('Leave Mine'),
                      ),
                    ],
                  ),
          ),
          // Bottom left: Search for Mine button (always visible)
          Positioned(
            left: 16,
            bottom: 16,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentMine = null;
                  _mineResult = null;
                });
                if (widget.onSearchNewMine != null) {
                  widget.onSearchNewMine!();
                }
                _searchMine();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                foregroundColor: Colors.white,
              ),
              child: const Text('Search for Mine'),
            ),
          ),
          // Bottom right: Furnace button (always visible)
          Positioned(
            right: 16,
            bottom: 16,
            child: ElevatedButton(
              onPressed: _openFurnace,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Furnace'),
            ),
          ),
        ],
      ),
    );
  }
}
