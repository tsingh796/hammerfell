import 'dart:async';
import 'package:flutter/material.dart';

import '../utils/backpack_manager.dart';
import 'package:provider/provider.dart';
import 'item_icon.dart';

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FurnaceState {
  Map<String, dynamic>? input; // {'type': ore, 'count': n}
  Map<String, dynamic>? fuel; // {'type': 'coal', 'count': n}
  Map<String, dynamic>? output; // {'type': ingot, 'count': n}
  bool isSmelting = false;
  int oreSecondsRemaining = 0;
  int fuelSecondsRemaining = 0;
  int? lastUpdateTimestamp; // Track when furnace was last active
  Timer? _timer;

  FurnaceState();

  Map<String, dynamic> toJson() => {
    'input': input,
    'fuel': fuel,
    'output': output,
    'isSmelting': isSmelting,
    'oreSecondsRemaining': oreSecondsRemaining,
    'fuelSecondsRemaining': fuelSecondsRemaining,
    'lastUpdateTimestamp': lastUpdateTimestamp,
  };

  static FurnaceState fromJson(Map<String, dynamic> json) {
    final state = FurnaceState();
    state.input = json['input'] != null ? Map<String, dynamic>.from(json['input']) : null;
    state.fuel = json['fuel'] != null ? Map<String, dynamic>.from(json['fuel']) : null;
    state.output = json['output'] != null ? Map<String, dynamic>.from(json['output']) : null;
    state.isSmelting = json['isSmelting'] ?? false;
    state.oreSecondsRemaining = json['oreSecondsRemaining'] ?? 0;
    state.fuelSecondsRemaining = json['fuelSecondsRemaining'] ?? 0;
    state.lastUpdateTimestamp = json['lastUpdateTimestamp'] as int?;
    return state;
  }

  Future<void> save(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(toJson()));
  }

  Future<void> load(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(key);
    if (str != null && str.isNotEmpty) {
      try {
        final json = jsonDecode(str);
        final loaded = FurnaceState.fromJson(json);
        input = loaded.input;
        fuel = loaded.fuel;
        output = loaded.output;
        isSmelting = loaded.isSmelting;
        oreSecondsRemaining = loaded.oreSecondsRemaining;
        fuelSecondsRemaining = loaded.fuelSecondsRemaining;
        lastUpdateTimestamp = loaded.lastUpdateTimestamp;
        
        // Calculate elapsed time and update state
        if (lastUpdateTimestamp != null) {
          final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          final elapsed = now - lastUpdateTimestamp!;
          if (elapsed > 0) {
            _processElapsedTime(elapsed);
          }
        }
      } catch (_) {}
    }
  }
  
  // Call this after loading to restart the timer if fuel is still burning
  void restartTimerIfNeeded(VoidCallback onUpdate) {
    // Cancel existing timer if it's somehow stuck
    if (_timer != null && !_timer!.isActive) {
      _timer?.cancel();
      _timer = null;
    }
    
    // Start timer if fuel is burning but timer isn't running
    if (fuelSecondsRemaining > 0 && (_timer == null || !_timer!.isActive)) {
      _startFuelTimer(onUpdate);
    }
  }

  // Process elapsed time when furnace was inactive
  void _processElapsedTime(int seconds) {
    const int smeltTime = 2; // Must match the smelting time in startSmelting
    
    while (seconds > 0 && (fuelSecondsRemaining > 0 || (fuel != null && fuel!['count'] > 0))) {
      // Burn fuel
      if (fuelSecondsRemaining > 0) {
        final burnTime = seconds < fuelSecondsRemaining ? seconds : fuelSecondsRemaining;
        fuelSecondsRemaining -= burnTime;
        seconds -= burnTime;
        
        // Process smelting during this burn time
        if (isSmelting && input != null && input!['count'] > 0) {
          while (burnTime >= oreSecondsRemaining && input != null && input!['count'] > 0) {
            final timeToFinish = oreSecondsRemaining;
            
            // Complete this smelt
            final result = _getSmeltedResult(input!);
            if (result != null) {
              if (output == null) {
                output = result;
              } else if (output!['type'] == result['type'] && output!['count'] < 64) {
                output!['count'] += 1;
              } else {
                // Output full or different type, stop smelting
                isSmelting = false;
                oreSecondsRemaining = 0;
                break;
              }
              
              input!['count'] -= 1;
              if (input!['count'] == 0) {
                input = null;
                isSmelting = false;
                oreSecondsRemaining = 0;
                break;
              }
              
              // Start next smelt
              oreSecondsRemaining = smeltTime;
            }
          }
        }
      }
      
      // If fuel ran out, try to consume next coal (only if we can smelt)
      if (fuelSecondsRemaining == 0 && fuel != null && fuel!['count'] > 0 && seconds > 0 && _canStartSmelting()) {
        fuelSecondsRemaining = 64;
        fuel!['count'] -= 1;
        if (fuel!['count'] == 0) fuel = null;
      } else if (fuelSecondsRemaining == 0) {
        // No more fuel or can't smelt, flame is out
        isSmelting = false;
        oreSecondsRemaining = 0;
        break;
      }
    }
  }

  // Add ore to input slot (up to 64)
  void addOre(Map<String, dynamic> ore, int count, VoidCallback onUpdate) {
    if (input == null) {
      input = {'type': ore['type'], 'count': count};
    } else if (input!['type'] == ore['type'] && input!['count'] < 64) {
      input!['count'] = (input!['count'] as int) + count;
      if (input!['count'] > 64) input!['count'] = 64;
    }
    onUpdate();
  }

  // Add coal to fuel slot (up to 64 queued)
  void addCoal(int count, VoidCallback onUpdate) {
    if (fuel == null) {
      fuel = {'type': 'coal', 'count': count};
    } else if (fuel!['count'] < 64) {
      fuel!['count'] = (fuel!['count'] as int) + count;
      if (fuel!['count'] > 64) fuel!['count'] = 64;
    }
    // Only start burning fuel if we can actually smelt something
    if (fuelSecondsRemaining <= 0 && fuel != null && fuel!['count'] > 0 && _canStartSmelting()) {
      fuelSecondsRemaining = 64;
      fuel!['count'] -= 1;
      if (fuel!['count'] == 0) fuel = null;
      lastUpdateTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      // Start the fuel burning timer
      _startFuelTimer(onUpdate);
    }
    onUpdate();
  }

  // Start or continue the fuel burning timer
  void _startFuelTimer(VoidCallback onUpdate) {
    // Cancel any existing timer first
    if (_timer != null) {
      _timer?.cancel();
      _timer = null;
    }
    
    // Only start if there's fuel remaining
    if (fuelSecondsRemaining <= 0) return;
    
    lastUpdateTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      lastUpdateTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      if (fuelSecondsRemaining > 0) {
        // Decrement fuel
        fuelSecondsRemaining--;
        
        // If smelting, also decrement ore time
        if (isSmelting && fuelSecondsRemaining >= 0) {
          oreSecondsRemaining--;
        }
        
        onUpdate();
        
        // Check if ore finished smelting
        if (isSmelting && oreSecondsRemaining <= 0 && fuelSecondsRemaining >= 0) {
          final result = _getSmeltedResult(input!);
          // Produce ingot
          if (output == null) {
            output = result;
          } else if (result != null && output!['type'] == result['type'] && output!['count'] < 64) {
            output!['count'] += 1;
          }
          
          // Consume input ore
          if (input != null) {
            input!['count'] -= 1;
            if (input!['count'] == 0) input = null;
          }
          
          isSmelting = false;
          oreSecondsRemaining = 0;
          
          // Auto-continue smelting if possible
          if (input != null && input!['count'] > 0 && fuelSecondsRemaining > 0) {
            isSmelting = true;
            oreSecondsRemaining = 2; // Testing: 2 seconds
          }
        }
        
        // If smelting but input removed or output full, stop smelting
        if (isSmelting && (input == null || (output != null && output!['count'] >= 64))) {
          isSmelting = false;
          oreSecondsRemaining = 0;
        }
        
        // Auto-start smelting if fuel is burning, not currently smelting, and input is available
        if (!isSmelting && input != null && input!['count'] > 0 && fuelSecondsRemaining > 0) {
          final result = _getSmeltedResult(input!);
          if (result != null && (output == null || (output!['type'] == result['type'] && output!['count'] < 64))) {
            isSmelting = true;
            oreSecondsRemaining = 2; // Testing: 2 seconds
          }
        }
        
        // If fuel just hit 0, try to consume next coal (only if we can smelt)
        if (fuelSecondsRemaining == 0) {
          if (fuel != null && fuel!['count'] > 0 && _canStartSmelting()) {
            fuelSecondsRemaining = 64;
            fuel!['count'] -= 1;
            if (fuel!['count'] == 0) fuel = null;
          } else {
            // No more fuel or can't smelt, timer will stop next tick
          }
        }
      } else {
        // Fuel completely out, stop timer
        timer.cancel();
        _timer = null;
        if (isSmelting) {
          isSmelting = false;
          oreSecondsRemaining = 0;
        }
        onUpdate();
      }
    });
  }

  // Called to start smelting if possible
  void startSmelting(VoidCallback onUpdate, VoidCallback onComplete) {
    // Only start if: has input ore, not already smelting, flame is on
    if (input == null || input!['count'] == 0 || isSmelting || fuelSecondsRemaining <= 0) return;
    
    // Check if output can accept result
    final result = _getSmeltedResult(input!);
    if (result != null) {
      if (output != null && (output!['type'] != result['type'] || output!['count'] >= 64)) {
        return; // Output full or different type
      }
    }
    
    isSmelting = true;
    oreSecondsRemaining = 2; // Testing: 2 seconds (change to 8 for production)
    
    // Ensure fuel timer is running
    if (_timer == null || !_timer!.isActive) {
      _startFuelTimer(onUpdate);
    }
  }

  void stopSmelting() {
    _timer?.cancel();
    isSmelting = false;
    oreSecondsRemaining = 0;
  }

  void clear() {
    input = null;
    output = null;
    fuel = null;
    stopSmelting();
    fuelSecondsRemaining = 0;
  }

  Map<String, dynamic>? _getSmeltedResult(Map<String, dynamic> item) {
    final type = item['type'];
    if (type == 'copper_ore') {
      return {'type': 'copper_ingot', 'count': 1};
    } else if (type == 'iron_ore') {
      return {'type': 'iron_ingot', 'count': 1};
    } else if (type == 'gold_ore') {
      return {'type': 'gold_ingot', 'count': 1};
    } else if (type == 'silver_ore') {
      return {'type': 'silver_ingot', 'count': 1};
    }
    return null;
  }

  // Check if smelting can start (has ore, can produce output)
  bool _canStartSmelting() {
    // Check 1: Has ore in input
    if (input == null || input!['count'] <= 0) return false;
    
    // Check 2: Can get a valid smelting result
    final result = _getSmeltedResult(input!);
    if (result == null) return false;
    
    // Check 3: Output can accept the result
    if (output == null) return true;
    if (output!['type'] == result['type'] && output!['count'] < 64) return true;
    
    return false;
  }
}


class FurnaceWidget extends StatefulWidget {
  final FurnaceState furnaceState;
  final VoidCallback onStateChanged;
  const FurnaceWidget({super.key, required this.furnaceState, required this.onStateChanged});

  @override
  State<FurnaceWidget> createState() => _FurnaceWidgetState();
}

class _FurnaceWidgetState extends State<FurnaceWidget> {

  @override
  void initState() {
    super.initState();
    // Restart timer if fuel is still burning when widget is created
    widget.furnaceState.restartTimerIfNeeded(() => setState(() {}));
  }

  @override
  void dispose() {
    // Update timestamp one last time before disposing
    if (widget.furnaceState.fuelSecondsRemaining > 0) {
      widget.furnaceState.lastUpdateTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      widget.onStateChanged(); // Trigger save
    }
    super.dispose();
  }

  // Use ItemIcon widget for all item icons
  Widget _itemIcon(String type, int count) {
    return ItemIcon(type: type, count: count);
  }

  @override
  Widget build(BuildContext context) {
    final furnace = widget.furnaceState;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Input slot (ore)
            _buildSlot(furnace.input, 'Input',
              onAccept: (item) {
                // Handled by DragTarget onAccept below
              },
              acceptTypes: ['copper', 'copper_ore', 'iron', 'iron_ore', 'gold', 'gold_ore', 'silver', 'silver_ore'],
              count: furnace.input != null ? furnace.input!['count'] : 0,
              draggable: furnace.input != null,
              dragData: furnace.input != null ? {...furnace.input!, 'slot': 'input'} : null,
              iconBuilder: furnace.input != null ? () => ItemIcon(type: furnace.input!['type'], count: furnace.input!['count']) : null,
            ),
            const SizedBox(width: 16),
            // Output slot (tap to collect all to backpack)
            GestureDetector(
              onTap: () {
                if (furnace.output != null && furnace.output!['count'] > 0) {
                  setState(() {
                    for (int i = 0; i < furnace.output!['count']; i++) {
                      BackpackManager().addItem(furnace.output!['type']);
                    }
                    furnace.output = null;
                    widget.onStateChanged();
                  });
                }
              },
              child: _buildSlot(furnace.output, 'Output',
                isOutput: true,
                onAccept: (item) {
                  // Output slot doesn't accept drops
                },
                count: furnace.output != null ? furnace.output!['count'] : 0,
                draggable: false,
                dragData: null,
                iconBuilder: furnace.output != null ? () => ItemIcon(type: furnace.output!['type'], count: furnace.output!['count']) : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Fuel slot (coal) with burning indicator above
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Burning indicator above fuel slot
            if (furnace.fuelSecondsRemaining > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
                  const SizedBox(width: 4),
                  Text('${furnace.fuelSecondsRemaining}s', style: const TextStyle(fontSize: 12, color: Colors.orange)),
                ],
              ),
            if (furnace.fuelSecondsRemaining > 0) const SizedBox(height: 4),
            // Fuel slot
            _buildSlot(furnace.fuel, 'Fuel',
              onAccept: (item) {
                // Handled by DragTarget onAccept below
              },
              acceptTypes: ['coal'],
              isFuel: false,
              fuelSeconds: 0,
              count: furnace.fuel != null ? furnace.fuel!['count'] : 0,
              draggable: furnace.fuel != null,
              dragData: furnace.fuel != null ? {...furnace.fuel!, 'slot': 'fuel'} : null,
              iconBuilder: furnace.fuel != null ? () => ItemIcon(type: furnace.fuel!['type'], count: furnace.fuel!['count']) : null,
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Smelting progress
        if (furnace.isSmelting)
          Text('Smelting... ${furnace.oreSecondsRemaining}s', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        // Backpack grid (global)
        const Text('Backpack'),
        _buildBackpackGrid(),
      ],
    );
  }

  Widget _buildSlot(
    Map<String, dynamic>? item,
    String label, {
    bool isOutput = false,
    bool isFuel = false,
    int fuelSeconds = 0,
    int count = 0,
    required Function(Map<String, dynamic>) onAccept,
    List<String>? acceptTypes,
    bool draggable = false,
    Map<String, dynamic>? dragData,
    Widget Function()? iconBuilder,
  }) {
    return DragTarget<Map<String, dynamic>>(
      builder: (context, candidateData, rejectedData) {
        Widget childWidget;
        // ...existing code...
        if (item != null && iconBuilder != null && (draggable || isOutput)) {
          childWidget = Draggable<Map<String, dynamic>>(
            data: {
              ...item,
              'slot': isOutput ? 'output' : dragData?['slot'] ?? '',
            },
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
                child: Center(child: iconBuilder()),
              ),
            ),
            childWhenDragging: Container(),
            child: Center(child: iconBuilder()),
          );
        } else if (item != null && iconBuilder != null) {
          childWidget = Center(child: iconBuilder());
        } else {
          childWidget = Text(label, style: const TextStyle(fontSize: 12));
        }
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey, width: 2),
            color: Colors.black.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: childWidget,
        );
      },
      onWillAccept: (data) {
        // ...existing code...
        if (isOutput) return false;
        if (acceptTypes != null && data != null && !acceptTypes.contains(data['type'])) return false;
        return true;
      },
      onAccept: (data) {
        setState(() {
          // If drag is from backpack, remove from backpack here as well
          if (data != null && data['from'] != null) {
            final backpack = BackpackManager().backpack;
            int fromIdx = data['from'];
            int moveCount = backpack[fromIdx]?['count'] ?? 1;
            String type = backpack[fromIdx]?['type'];
            int actuallyMoved = 0;
            if (label == 'Input') {
              if (widget.furnaceState.input != null && widget.furnaceState.input!['type'] == type && widget.furnaceState.input!['count'] < 64) {
                int space = 64 - (widget.furnaceState.input!['count'] as int);
                int toMove = moveCount > space ? space : moveCount;
                if (toMove > 0) {
                  widget.furnaceState.input!['count'] += toMove;
                  actuallyMoved = toMove;
                }
              } else if (widget.furnaceState.input == null && moveCount > 0) {
                widget.furnaceState.input = {'type': type, 'count': moveCount};
                actuallyMoved = moveCount;
              }
              // Force restart timer when ore is added and fuel is burning
              if (actuallyMoved > 0 && widget.furnaceState.fuelSecondsRemaining > 0) {
                // Cancel any stuck timer and force a fresh restart
                widget.furnaceState._timer?.cancel();
                widget.furnaceState._timer = null;
                widget.furnaceState._startFuelTimer(() => setState(() {}));
              }
            } else if (label == 'Fuel') {
              if (widget.furnaceState.fuel != null && widget.furnaceState.fuel!['type'] == type && widget.furnaceState.fuel!['count'] < 64) {
                int space = 64 - (widget.furnaceState.fuel!['count'] as int);
                int toMove = moveCount > space ? space : moveCount;
                if (toMove > 0) {
                  widget.furnaceState.fuel!['count'] += toMove;
                  actuallyMoved = toMove;
                }
              } else if (widget.furnaceState.fuel == null && moveCount > 0) {
                widget.furnaceState.fuel = {'type': type, 'count': moveCount};
                actuallyMoved = moveCount;
              }
              // Start burning fuel if not already burning
              if (actuallyMoved > 0 && widget.furnaceState.fuelSecondsRemaining <= 0 && widget.furnaceState.fuel != null && widget.furnaceState.fuel!['count'] > 0) {
                widget.furnaceState.fuelSecondsRemaining = 64;
                widget.furnaceState.fuel!['count'] -= 1;
                if (widget.furnaceState.fuel!['count'] == 0) widget.furnaceState.fuel = null;
                widget.furnaceState.lastUpdateTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
                widget.furnaceState._startFuelTimer(() => setState(() {}));
              }
            }
            if (actuallyMoved > 0) {
              backpack[fromIdx]!['count'] -= actuallyMoved;
              if (backpack[fromIdx]!['count'] <= 0) backpack[fromIdx] = null;
              BackpackManager().save();
            }
            widget.onStateChanged();
          } else {
            onAccept(data);
            widget.onStateChanged();
          }
        });
      },
    );
  }

  Widget _buildBackpackGrid() {
    return Consumer<BackpackManager>(
      builder: (context, backpackManager, child) {
        final backpack = backpackManager.backpack;
        return Center(
          child: SizedBox(
            width: 256,
            height: 52,
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
              final slot = backpack[index];
              return DragTarget<Map<String, dynamic>>(
                builder: (context, candidateData, rejectedData) {
                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 2),
                      color: slot != null ? Colors.black.withOpacity(0.15) : Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: slot != null
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
                                child: Center(child: ItemIcon(type: slot['type'], count: slot['count'])),
                              ),
                            ),
                            childWhenDragging: Container(),
                            child: Center(child: ItemIcon(type: slot['type'], count: slot['count'])),
                          )
                        : null,
                  );
                },
                onWillAccept: (data) => true,
                onAccept: (data) {
                  setState(() {
                    // 1. Move item from backpack to furnace: move full stack, always remove from backpack if any are added to furnace
                    if (data['from'] != null && data['slot'] != null) {
                      int fromIdx = data['from'];
                      int moveCount = backpack[fromIdx]?['count'] ?? 1;
                      String type = backpack[fromIdx]?['type'];
                      int actuallyMoved = 0;
                      if (data['slot'] == 'input') {
                        if (widget.furnaceState.input != null && widget.furnaceState.input!['type'] == type && widget.furnaceState.input!['count'] < 64) {
                          int space = 64 - (widget.furnaceState.input!['count'] as int);
                          int toMove = moveCount > space ? space : moveCount;
                          if (toMove > 0) {
                            widget.furnaceState.input!['count'] += toMove;
                            actuallyMoved = toMove;
                          }
                        } else if (widget.furnaceState.input == null && moveCount > 0) {
                          widget.furnaceState.input = {'type': type, 'count': moveCount};
                          actuallyMoved = moveCount;
                        }
                      } else if (data['slot'] == 'fuel') {
                        if (widget.furnaceState.fuel != null && widget.furnaceState.fuel!['type'] == type && widget.furnaceState.fuel!['count'] < 64) {
                          int space = 64 - (widget.furnaceState.fuel!['count'] as int);
                          int toMove = moveCount > space ? space : moveCount;
                          if (toMove > 0) {
                            widget.furnaceState.fuel!['count'] += toMove;
                            actuallyMoved = toMove;
                          }
                        } else if (widget.furnaceState.fuel == null && moveCount > 0) {
                          widget.furnaceState.fuel = {'type': type, 'count': moveCount};
                          actuallyMoved = moveCount;
                        }
                      }
                      // Always remove from backpack if any were moved
                      if (actuallyMoved > 0) {
                        backpack[fromIdx]!['count'] -= actuallyMoved;
                        if (backpack[fromIdx]!['count'] <= 0) backpack[fromIdx] = null;
                        backpackManager.save();
                      }
                    }
                    // 2. Move item from furnace (input/fuel) to backpack: move full stack
                    else if (data['type'] != null && data['count'] != null && data['slot'] != null) {
                      String type = data['type'];
                      int moveCount = data['count'];
                      // Try to stack into backpack slot if same type
                      if (slot != null && slot['type'] == type && slot['count'] < 64) {
                        int space = 64 - (slot['count'] as int);
                        int toMove = moveCount > space ? space : moveCount;
                        slot['count'] += toMove;
                        if (data['slot'] == 'input' && widget.furnaceState.input != null) {
                          widget.furnaceState.input!['count'] -= toMove;
                          if (widget.furnaceState.input!['count'] <= 0) widget.furnaceState.input = null;
                        } else if (data['slot'] == 'fuel' && widget.furnaceState.fuel != null) {
                          widget.furnaceState.fuel!['count'] -= toMove;
                          if (widget.furnaceState.fuel!['count'] <= 0) widget.furnaceState.fuel = null;
                        }
                      } else if (slot == null) {
                        backpack[index] = {'type': type, 'count': moveCount};
                        if (data['slot'] == 'input' && widget.furnaceState.input != null) {
                          widget.furnaceState.input = null;
                        } else if (data['slot'] == 'fuel' && widget.furnaceState.fuel != null) {
                          widget.furnaceState.fuel = null;
                        }
                      }
                      backpackManager.save();
                    }
                    // 3. Move item within backpack
                    else if (data['from'] != null && data['slot'] == null) {
                      backpackManager.moveItem(data['from'], index);
                    }
                    widget.onStateChanged();
                  });
                },
              );
            },
          ),
          ),
        );
      },
    );
  }
}
