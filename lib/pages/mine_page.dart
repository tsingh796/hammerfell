
import 'dart:math';

import 'package:flutter/material.dart';
import '../modals/mine_search_modal.dart';

import '../models/mine.dart';
import '../utils/random_utils.dart';
import 'package:flutter_svg/flutter_svg.dart';


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
    String? _nextOre;
    final Random _rng = Random();
    // Helper to get ore icon asset path
    String _oreAsset(String ore) {
      switch (ore) {
        case 'iron':
          return 'assets/images/iron_ore.svg';
        case 'copper':
          return 'assets/images/copper_ore.svg';
        case 'gold':
          return 'assets/images/gold_ore.svg';
        case 'diamond':
          return 'assets/images/diamond.svg';
        default:
          return 'assets/images/stone.svg';
      }
    }

    // Cracking overlay asset for animation (2 steps)
    String _crackAsset(int step, String ore) {
      // You can add your own assets for more steps or different ores
      if (step == 1) {
        return 'assets/images/crack1.svg';
      } else if (step == 2) {
        return 'assets/images/crack2.svg';
      }
      return '';
    }

    // Helper to pick next ore using weightedRandomChoice utility
    String _pickNextOre() {
      final oreChances = widget.mineOreChances[_currentMine!.oreType];
      if (oreChances == null || oreChances.isEmpty) return _currentMine!.oreType;
      final oreNames = oreChances.keys.toList();
      final weights = oreNames.map((k) => oreChances[k] ?? 0.0).toList();
      return weightedRandomChoice(oreNames, weights, rng: _rng) ?? _currentMine!.oreType;
    }
  dynamic _currentMine;
  bool _mining = false;
  int _crackStep = 0;
  bool _isPressed = false;
  String? _mineResult;
  // Each slot: {'type': oreType, 'count': int}
  final List<Map<String, dynamic>?> _backpack = List.filled(5, null, growable: false);

  // Helper for readable text color (copied from main.dart)
  Color _readableTextColor(Color background) {
    // Simple luminance check for dark/light backgrounds
    return background.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }

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
    // Initialize _nextOre when entering a mine
    if (_currentMine != null && _nextOre == null) {
      _nextOre = _pickNextOre();
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
                          onLongPressStart: (_mining || _nextOre == null)
                              ? null
                              : (details) async {
                                  setState(() {
                                    _isPressed = true;
                                    _mining = true;
                                    _mineResult = null;
                                    _crackStep = 1;
                                  });
                                  // Haptic feedback for tactile feel
                                  Feedback.forLongPress(context);
                                  await Future.delayed(const Duration(milliseconds: 400));
                                  setState(() {
                                    _crackStep = 2;
                                  });
                                  await Future.delayed(const Duration(milliseconds: 400));
                                  final oreType = _nextOre!;
                                  await widget.onMine(oreType); // Always succeed
                                  setState(() {
                                    _mining = false;
                                    _crackStep = 0;
                                    _isPressed = false;
                                    _mineResult = 'Mined $oreType!';
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
                                    // Pick next ore for next mining
                                    _nextOre = _pickNextOre();
                                  });
                                },
                          onLongPressEnd: (_mining || _nextOre == null)
                              ? null
                              : (details) {
                                  // If user releases early, reset animation
                                  if (_mining) {
                                    setState(() {
                                      _mining = false;
                                      _crackStep = 0;
                                      _isPressed = false;
                                    });
                                  }
                                },
                          onTapDown: (_) {
                            if (!_mining && _nextOre != null) {
                              setState(() {
                                _isPressed = true;
                              });
                            }
                          },
                          onTapUp: (_) {
                            if (_isPressed) {
                              setState(() {
                                _isPressed = false;
                              });
                            }
                          },
                          onTapCancel: () {
                            if (_isPressed) {
                              setState(() {
                                _isPressed = false;
                              });
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 100),
                            width: _isPressed ? 92 : 100,
                            height: _isPressed ? 92 : 100,
                            decoration: BoxDecoration(
                              color: _mining || _isPressed
                                  ? Colors.grey[800]
                                  : Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                              border: Border.all(
                                color: _isPressed ? Colors.amber : Colors.black54,
                                width: _isPressed ? 3 : 2,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                _nextOre != null
                                    ? SvgPicture.asset(_oreAsset(_nextOre!), width: 48, height: 48)
                                    : const Icon(Icons.construction, size: 48, color: Colors.white),
                                if (_crackStep > 0)
                                  SvgPicture.asset(_crackAsset(_crackStep, _nextOre!), width: 48, height: 48),
                                if (_isPressed && !_mining)
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                              ],
                            ),
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
                                      ? Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            SvgPicture.asset(_oreAsset(slot['type']), width: 20, height: 20),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${slot['count']}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: _readableTextColor(Colors.amber[200]!),
                                              ),
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
                            _nextOre = null;
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
