
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../modals/mine_search_modal.dart';

import '../utils/random_utils.dart';
import '../utils/backpack_manager.dart';
import '../widgets/item_icon.dart';
import '../widgets/inventory_grid_with_splitting.dart';
import '../widgets/furnace_widget.dart';
import 'package:provider/provider.dart';

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
    String? _nextOre;
    final Random _rng = Random();
    bool _hasEnteredMine = false;
    dynamic _currentMine;
    bool _mining = false;
    int? _miningButtonIndex; // Track which button (1 or 2) is currently mining
    bool _isPressed1 = false;
    bool _isPressed2 = false;
    int _crackStep = 0;
    String? _mineResult;
    final FurnaceState _furnaceState = FurnaceState();
    final String _furnaceKey = 'furnace_mine';
    late int _currentHammerfells; // Local tracking of hammerfells

    @override
    void initState() {
      super.initState();
      _currentHammerfells = widget.hammerfells;
      _restoreMineState();
      // If no mine was entered previously, default to coal mine
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_hasEnteredMine || _currentMine == null) {
          setState(() {
            _hasEnteredMine = true;
            _currentMine = Mine('coal');
            _nextOre = null;
          });
        }
      });
      _furnaceState.load(_furnaceKey).then((_) {
        setState(() {});
      });
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

    String _crackAsset(int step, String ore) {
      if (step == 1) {
        return 'assets/images/crack1.png';
      } else if (step == 2) {
        return 'assets/images/crack2.png';
      }
      return '';
    }

    String _getOreBlockAsset(String oreType) {
      switch (oreType) {
        case 'coal':
          return 'assets/images/coal_ore_block.png';
        case 'copper':
          return 'assets/images/copper_ore_block.png';
        case 'iron':
          return 'assets/images/iron_ore_block.png';
        case 'silver':
          return 'assets/images/silver_ore_block.png';
        case 'gold':
          return 'assets/images/gold_ore_block.png';
        case 'diamond':
          return 'assets/images/diamond_ore_block.png';
        case 'stone':
          return 'assets/images/stone_block.png';
        default:
          return 'assets/images/stone_block.png';
      }
    }

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
          currentMineType: _currentMine?.oreType,
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
                _furnaceState.save(_furnaceKey);
              },
            ),
          ),
        );
      }
    }

    @override
    Widget build(BuildContext context) {
      if (_hasEnteredMine && _currentMine != null && _nextOre == null) {
        _nextOre = _pickNextOre();
      }
      final String mineTitle = _currentMine != null 
          ? '${_currentMine.oreType[0].toUpperCase()}${_currentMine.oreType.substring(1)} Mine'
          : 'Mine';
      return Scaffold(
        appBar: AppBar(
          title: Text(mineTitle),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Center(
                child: Text(
                  'Hammerfells: $_currentHammerfells',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // First mining button
                  GestureDetector(
                    onLongPressStart: (_mining || _nextOre == null)
                        ? null
                        : (details) async {
                            if (_currentHammerfells <= 0) {
                              setState(() {
                                _mineResult = 'Not enough hammerfells!';
                              });
                              return;
                            }
                            setState(() {
                              _isPressed1 = true;
                              _mining = true;
                              _miningButtonIndex = 1;
                              _mineResult = null;
                              _crackStep = 1;
                            });
                            Feedback.forLongPress(context);
                            await Future.delayed(const Duration(milliseconds: 400));
                            setState(() {
                              _crackStep = 2;
                            });
                            await Future.delayed(const Duration(milliseconds: 400));
                            final oreType = _nextOre!;
                            final success = await widget.onMine(oreType);
                            setState(() {
                              _mining = false;
                              _miningButtonIndex = null;
                              _crackStep = 0;
                              _isPressed1 = false;
                              if (success) {
                                _mineResult = 'Mined $oreType!';
                                _addToBackpack(oreType);
                                _nextOre = _pickNextOre();
                                _currentHammerfells--;
                              } else {
                                _mineResult = 'Not enough hammerfells!';
                              }
                            });
                            _saveMineState();
                          },
                    onLongPressEnd: (_mining || _nextOre == null)
                        ? null
                        : (details) {
                            if (_mining) {
                              setState(() {
                                _mining = false;
                                _miningButtonIndex = null;
                                _crackStep = 0;
                                _isPressed1 = false;
                              });
                            }
                          },
                    onTapDown: (_) {
                      if (!_mining && _nextOre != null) {
                        setState(() {
                          _isPressed1 = true;
                        });
                      }
                    },
                    onTapUp: (_) {
                      if (_isPressed1) {
                        setState(() {
                          _isPressed1 = false;
                        });
                      }
                    },
                    onTapCancel: () {
                      if (_isPressed1) {
                        setState(() {
                          _isPressed1 = false;
                        });
                      }
                    },
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        image: _currentMine != null && _currentMine.oreType != null
                            ? DecorationImage(
                                image: AssetImage(_getOreBlockAsset(_currentMine.oreType)),
                                fit: BoxFit.cover,
                              )
                            : null,
                        color: _currentMine == null ? Colors.grey[700] : null,
                        border: _isPressed1 ? Border.all(color: Colors.white, width: 2) : null,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_currentMine == null)
                            const Icon(Icons.construction, size: 80, color: Colors.white),
                          if (_crackStep > 0 && _nextOre != null && _miningButtonIndex == 1)
                            Image.asset(_crackAsset(_crackStep, _nextOre!), width: 120, height: 120, fit: BoxFit.cover),
                        ],
                      ),
                    ),
                  ),
                  // Second mining button
                  GestureDetector(
                    onLongPressStart: (_mining || _nextOre == null)
                        ? null
                        : (details) async {
                            if (_currentHammerfells <= 0) {
                              setState(() {
                                _mineResult = 'Not enough hammerfells!';
                              });
                              return;
                            }
                            setState(() {
                              _isPressed2 = true;
                              _mining = true;
                              _miningButtonIndex = 2;
                              _mineResult = null;
                              _crackStep = 1;
                            });
                            Feedback.forLongPress(context);
                            await Future.delayed(const Duration(milliseconds: 400));
                            setState(() {
                              _crackStep = 2;
                            });
                            await Future.delayed(const Duration(milliseconds: 400));
                            final oreType = _nextOre!;
                            final success = await widget.onMine(oreType);
                            setState(() {
                              _mining = false;
                              _miningButtonIndex = null;
                              _crackStep = 0;
                              _isPressed2 = false;
                              if (success) {
                                _mineResult = 'Mined $oreType!';
                                _addToBackpack(oreType);
                                _nextOre = _pickNextOre();
                                _currentHammerfells--;
                              } else {
                                _mineResult = 'Not enough hammerfells!';
                              }
                            });
                            _saveMineState();
                          },
                    onLongPressEnd: (_mining || _nextOre == null)
                        ? null
                        : (details) {
                            if (_mining) {
                              setState(() {
                                _mining = false;
                                _miningButtonIndex = null;
                                _crackStep = 0;
                                _isPressed2 = false;
                              });
                            }
                          },
                    onTapDown: (_) {
                      if (!_mining && _nextOre != null) {
                        setState(() {
                          _isPressed2 = true;
                        });
                      }
                    },
                    onTapUp: (_) {
                      if (_isPressed2) {
                        setState(() {
                          _isPressed2 = false;
                        });
                      }
                    },
                    onTapCancel: () {
                      if (_isPressed2) {
                        setState(() {
                          _isPressed2 = false;
                        });
                      }
                    },
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        image: _currentMine != null && _currentMine.oreType != null
                            ? DecorationImage(
                                image: AssetImage(_getOreBlockAsset(_currentMine.oreType)),
                                fit: BoxFit.cover,
                              )
                            : null,
                        color: _currentMine == null ? Colors.grey[700] : null,
                        border: _isPressed2 ? Border.all(color: Colors.white, width: 2) : null,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_currentMine == null)
                            const Icon(Icons.construction, size: 80, color: Colors.white),
                          if (_crackStep > 0 && _nextOre != null && _miningButtonIndex == 2)
                            Image.asset(_crackAsset(_crackStep, _nextOre!), width: 120, height: 120, fit: BoxFit.cover),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_mineResult != null) ...[
                    const SizedBox(height: 12),
                    Text(_mineResult!, style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Backpack', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Consumer<BackpackManager>(
                          builder: (context, backpackManager, child) {
                            return Center(
                              child: InventoryGridWithSplitting(
                                slots: backpackManager.backpack,
                                onMoveItem: (from, to) => backpackManager.moveItem(from, to),
                                onSplitStack: (index) => backpackManager.splitStack(index),
                                onSave: () => backpackManager.save(),
                                columns: 5,
                                rows: 1,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 16,
              bottom: 16,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: _searchMine,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Search for Mine'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _openFurnace,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Furnace'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      await _saveMineState();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Home'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }
