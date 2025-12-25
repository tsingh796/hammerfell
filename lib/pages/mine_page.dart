
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../modals/mine_search_modal.dart';

import '../utils/random_utils.dart';
import '../utils/backpack_manager.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/item_icon.dart';
import '../widgets/furnace_widget.dart';

class Mine {
  final String oreType;
  
  Mine(this.oreType);
  
  Map<String, dynamic> toJson() => {'oreType': oreType};
}

class MinePage extends StatefulWidget {
  final int hammerfells;
  final Map<String, double> miningChances;
  final Future<bool> Function(String) onMine;
  final VoidCallback? onOpenFurnace;
  final Map<String, Map<String, double>> mineOreChances;
  final String Function(String) pickOreForMine;
  // Remove hasEnteredMine, initialMine, onEnterMine, onSearchNewMine from constructor
  // Backpack and addToBackpack removed; MinePage manages its own backpack

  const MinePage({
    Key? key,
    required this.hammerfells,
    required this.miningChances,
    required this.onMine,
    required this.mineOreChances,
    required this.pickOreForMine,
    this.onOpenFurnace,
  }) : super(key: key);

  @override
  State<MinePage> createState() => _MinePageState();
}

class _MinePageState extends State<MinePage> {
  // Use global backpack singleton
  String? _nextOre;
  final Random _rng = Random();
  bool _hasEnteredMine = false;
  dynamic _currentMine;
  bool _mining = false;
  bool _isPressed = false;
  int _crackStep = 0;
  String? _mineResult;

  // Add a local furnace state for this page
  final FurnaceState _furnaceState = FurnaceState();

  @override
  void initState() {
    super.initState();
    _restoreMineState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _restoreMineState();
  }

  Future<void> _restoreMineState() async {
    final prefs = await SharedPreferences.getInstance();
    final lastMine = prefs.getString('minepage_lastMine');
    if (lastMine != null && lastMine.isNotEmpty) {
      try {
        final decoded = jsonDecode(lastMine);
        setState(() {
          _hasEnteredMine = true;
          _currentMine = decoded is Map<String, dynamic> && decoded.containsKey('oreType')
              ? Mine(decoded['oreType'])
              : null;
        });
      } catch (_) {
        setState(() {
          _hasEnteredMine = false;
          _currentMine = null;
        });
      }
    } else {
      setState(() {
        _hasEnteredMine = false;
        _currentMine = null;
      });
    }
    await BackpackManager().load();
  }

  Future<void> _loadMineState() async {
    final prefs = await SharedPreferences.getInstance();
    final lastMine = prefs.getString('minepage_lastMine');
    if (lastMine != null && lastMine.isNotEmpty) {
      try {
        final decoded = jsonDecode(lastMine);
        setState(() {
          _hasEnteredMine = true;
          _currentMine = decoded is Map<String, dynamic> && decoded.containsKey('oreType')
              ? Mine(decoded['oreType'])
              : null;
        });
      } catch (_) {
        setState(() {
          _hasEnteredMine = false;
          _currentMine = null;
        });
      }
    } else {
      setState(() {
        _hasEnteredMine = false;
        _currentMine = null;
      });
    }
    // Load global backpack
    await BackpackManager().load();
  }

  Future<void> _saveMineState() async {
    final prefs = await SharedPreferences.getInstance();
    // Save mine
    if (_hasEnteredMine && _currentMine != null) {
      await prefs.setString('minepage_lastMine', jsonEncode(_currentMine));
    } else {
      await prefs.remove('minepage_lastMine');
    }
    // Save global backpack
    await BackpackManager().save();
  }

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
    if (step == 1) {
      return 'assets/images/crack1.svg';
    } else if (step == 2) {
      return 'assets/images/crack2.svg';
    }
    return '';
  }

  // Helper to pick next ore using weightedRandomChoice utility
  String _pickNextOre() {
    final oreType = _currentMine.oreType;
    final oreChances = widget.mineOreChances[oreType];
    if (oreChances == null || oreChances.isEmpty) return oreType;
    final oreNames = oreChances.keys.toList();
    final weights = oreNames.map((k) => oreChances[k] ?? 0.0).toList();
    return weightedRandomChoice(oreNames, weights, rng: _rng) ?? oreType;
  }

  void _addToBackpack(String oreType) {
    BackpackManager().addItem(oreType);
    setState(() {});
  }

  void _searchMine() {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (c) => MineSearchModal(
        onEnterMine: (mine) {
          Navigator.of(c).pop();
          setState(() {
            _hasEnteredMine = true;
            _currentMine = mine;
            _nextOre = null;
          });
          _saveMineState();
        },
      ),
    );
  }

  void _openFurnace() {
    if (widget.onOpenFurnace != null) {
      widget.onOpenFurnace!();
    } else {
      showModalBottomSheet(
        context: context,
        isDismissible: true,
        enableDrag: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        builder: (c) => Padding(
          padding: const EdgeInsets.all(16),
          child: FurnaceWidget(
            furnaceState: _furnaceState,
            onStateChanged: () {
              setState(() {});
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initialize _nextOre when entering a mine
    if (_hasEnteredMine && _currentMine != null && _nextOre == null) {
      _nextOre = _pickNextOre();
    }
    final bool showMiningUI = (_hasEnteredMine && _currentMine != null);
    return Scaffold(
      appBar: AppBar(title: const Text('Mine')),
      body: Stack(
        children: [
          // Main content area
          Center(
            child: (!showMiningUI)
                ? const Text('Search for a mine to begin!')
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Entered ${_currentMine.oreType[0].toUpperCase()}${_currentMine.oreType.substring(1)} Mine!'),
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
                                  // Only update backpack, not homepage grid
                                  await widget.onMine(oreType); // Always succeed
                                  setState(() {
                                    _mining = false;
                                    _crackStep = 0;
                                    _isPressed = false;
                                    _mineResult = 'Mined $oreType!';
                                    _addToBackpack(oreType);
                                    // Pick next ore for next mining
                                    _nextOre = _pickNextOre();
                                  });
                                  _saveMineState();
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
                                  ? ItemIcon(type: _nextOre!, count: 1, size: 48, showCount: false)
                                  : const Icon(Icons.construction, size: 48, color: Colors.white),
                                if (_crackStep > 0)
                                  // Crack overlay remains SVG, as it's a visual effect, not an item icon
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
                      // ...existing code...
                      if (_mineResult != null) ...[
                        const SizedBox(height: 12),
                        Text(_mineResult!, style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _mineResult = null;
                            _nextOre = null;
                            _hasEnteredMine = false;
                            _currentMine = null;
                          });
                          _saveMineState();
                        },
                        child: const Text('Leave Mine'),
                      ),

                      // Backpack grid (unified style with HomePage)
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Backpack', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 60,
                              child: ClipRect(
                                child: GridView.builder(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 5,
                                    mainAxisSpacing: 4,
                                    crossAxisSpacing: 4,
                                    childAspectRatio: 1,
                                  ),
                                  itemCount: 5,
                                  itemBuilder: (context, index) {
                                    final slot = BackpackManager().backpack[index];
                                    return DragTarget<Map<String, dynamic>>(
                                      builder: (context, candidateData, rejectedData) {
                                        return slot != null
                                            ? Draggable<Map<String, dynamic>>(
                                                data: {...slot, 'from': index},
                                                feedback: Material(
                                                  color: Colors.transparent,
                                                  child: Container(
                                                    width: 48,
                                                    height: 48,
                                                    decoration: BoxDecoration(
                                                      border: Border.all(color: Colors.amber, width: 2),
                                                      color: Colors.black.withOpacity(0.7),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        ItemIcon(type: slot['type'], count: slot['count'], size: 20),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                childWhenDragging: Container(
                                                  decoration: BoxDecoration(
                                                    border: Border.all(color: Colors.grey, width: 2),
                                                    color: Colors.black.withOpacity(0.05),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                ),
                                                onDragCompleted: () {},
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    border: Border.all(color: Colors.grey, width: 2),
                                                    color: Colors.black.withOpacity(0.15),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      ItemIcon(type: slot['type'], count: slot['count'], size: 20),
                                                    ],
                                                  ),
                                                ),
                                              )
                                            : Container(
                                                decoration: BoxDecoration(
                                                  border: Border.all(color: Colors.grey, width: 2),
                                                  color: Colors.black.withOpacity(0.05),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              );
                                      },
                                      onWillAccept: (data) {
                                        if (data == null) return false;
                                        // Accept if empty or same type and not full
                                        if (slot == null) return true;
                                        if (slot['type'] == data['type'] && (slot['count'] as int) < 64) return true;
                                        return false;
                                      },
                                      onAccept: (data) {
                                        setState(() {
                                          int from = data['from'] as int;
                                          int to = index;
                                          BackpackManager().moveItem(from, to);
                                        });
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
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
                  _mineResult = null;
                });
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
