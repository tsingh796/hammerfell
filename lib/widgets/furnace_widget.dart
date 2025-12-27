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
  Timer? _timer;

  FurnaceState();

  Map<String, dynamic> toJson() => {
    'input': input,
    'fuel': fuel,
    'output': output,
    'isSmelting': isSmelting,
    'oreSecondsRemaining': oreSecondsRemaining,
    'fuelSecondsRemaining': fuelSecondsRemaining,
  };

  static FurnaceState fromJson(Map<String, dynamic> json) {
    final state = FurnaceState();
    state.input = json['input'] != null ? Map<String, dynamic>.from(json['input']) : null;
    state.fuel = json['fuel'] != null ? Map<String, dynamic>.from(json['fuel']) : null;
    state.output = json['output'] != null ? Map<String, dynamic>.from(json['output']) : null;
    state.isSmelting = json['isSmelting'] ?? false;
    state.oreSecondsRemaining = json['oreSecondsRemaining'] ?? 0;
    state.fuelSecondsRemaining = json['fuelSecondsRemaining'] ?? 0;
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
        isSmelting = false; // Always reset smelting on load
        oreSecondsRemaining = 0;
        fuelSecondsRemaining = loaded.fuelSecondsRemaining;
      } catch (_) {}
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
    // If not burning, start burning one coal
    if (fuelSecondsRemaining <= 0 && fuel != null && fuel!['count'] > 0) {
      fuelSecondsRemaining = 64;
      fuel!['count'] -= 1;
      if (fuel!['count'] == 0) fuel = null;
    }
    onUpdate();
  }

  // Remove from output slot (collect to backpack)
  Map<String, dynamic>? takeOutput() {
    if (output != null && output!['count'] > 0) {
      final out = {'type': output!['type'], 'count': output!['count']};
      output = null;
      return out;
    }
    return null;
  }

  // Called to start smelting if possible
  void startSmelting(VoidCallback onUpdate, VoidCallback onComplete) {
    if (input == null || input!['count'] == 0 || isSmelting || fuelSecondsRemaining < 8 || (output != null && output!['count'] >= 64)) return;
    isSmelting = true;
    oreSecondsRemaining = 2;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      oreSecondsRemaining--;
      fuelSecondsRemaining--;
      onUpdate();
      // If fuel runs out, try to burn next coal
      if (fuelSecondsRemaining == 0 && fuel != null && fuel!['count'] > 0) {
        fuelSecondsRemaining = 64;
        fuel!['count'] -= 1;
        if (fuel!['count'] == 0) fuel = null;
      }
      // Stop if any stop condition met
      if (oreSecondsRemaining <= 0) {
        // Only smelt if output slot is not full
        if (output == null) {
          output = _getSmeltedResult(input!);
        } else if (output!['count'] < 64) {
          output!['count'] += 1;
        }
        input!['count'] -= 1;
        if (input!['count'] == 0) input = null;
        timer.cancel();
        isSmelting = false;
        onComplete();
        // Auto-continue if possible
        if (input != null && input!['count'] > 0 && fuelSecondsRemaining >= 8 && (output == null || output!['count'] < 64)) {
          startSmelting(onUpdate, onComplete);
        }
      }
      // Stop if fuel runs out or output is full or input is empty
      if (fuelSecondsRemaining < 8 || input == null || (output != null && output!['count'] >= 64)) {
        timer.cancel();
        isSmelting = false;
        onComplete();
      }
    });
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
    if (type == 'copper') {
      return {'type': 'copper_ingot', 'count': 1};
    } else if (type == 'iron') {
      return {'type': 'iron_ingot', 'count': 1};
    } else if (type == 'gold') {
      return {'type': 'gold_ingot', 'count': 1};
    }
    return null;
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
                setState(() {
                  if (item['type'] == 'copper' || item['type'] == 'iron' || item['type'] == 'gold') {
                    int count = item['count'] ?? 1;
                    furnace.addOre(item, count, () {});
                    widget.onStateChanged();
                  }
                });
              },
              acceptTypes: ['copper', 'iron', 'gold'],
              count: furnace.input != null ? furnace.input!['count'] : 0,
              draggable: furnace.input != null,
              dragData: furnace.input != null ? {...furnace.input!, 'slot': 'input'} : null,
              iconBuilder: furnace.input != null ? () => ItemIcon(type: furnace.input!['type'], count: furnace.input!['count']) : null,
            ),
            const SizedBox(width: 16),
            // Output slot (clickable to collect all, or draggable to specific slot)
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
                draggable: true,
                dragData: furnace.output != null ? {...furnace.output!, 'slot': 'output'} : null,
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
                if (item['type'] == 'coal') {
                  setState(() {
                    int count = item['count'] ?? 1;
                    furnace.addCoal(count, () {});
                    widget.onStateChanged();
                  });
                }
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
        // Smelting progress and controls
        if (furnace.isSmelting)
          Text('Smelting... ${furnace.oreSecondsRemaining}s', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
        if (!furnace.isSmelting && furnace.input != null && furnace.input!['count'] > 0)
          Column(
            children: [
              if (furnace.fuelSecondsRemaining < 8)
                const Text('Need at least 8s of fuel to start smelting', style: TextStyle(fontSize: 12, color: Colors.grey)),
              if (furnace.output != null && furnace.output!['count'] >= 64)
                const Text('Output is full, remove items first', style: TextStyle(fontSize: 12, color: Colors.grey)),
              if (furnace.fuelSecondsRemaining >= 8 && (furnace.output == null || furnace.output!['count'] < 64))
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      furnace.startSmelting(() => setState(() {}), widget.onStateChanged);
                    });
                  },
                  child: const Text('Start Smelting'),
                ),
            ],
          ),
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
        return SizedBox(
          height: 60,
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
                    // 3. Move item from output slot to backpack: add all to backpack and clear output
                    else if (data['slot'] == 'output' && data['type'] != null && data['count'] != null) {
                      String type = data['type'];
                      int moveCount = data['count'];
                      if (slot != null && slot['type'] == type && slot['count'] < 64) {
                        int space = 64 - (slot['count'] as int);
                        int toMove = moveCount > space ? space : moveCount;
                        slot['count'] += toMove;
                        if (widget.furnaceState.output != null) {
                          widget.furnaceState.output!['count'] -= toMove;
                          if (widget.furnaceState.output!['count'] <= 0) widget.furnaceState.output = null;
                        }
                      } else if (slot == null) {
                        backpack[index] = {'type': type, 'count': moveCount};
                        widget.furnaceState.output = null;
                      }
                      backpackManager.save();
                    }
                    // 4. Move item within backpack
                    else if (data['from'] != null && data['slot'] == null) {
                      backpackManager.moveItem(data['from'], index);
                    }
                    widget.onStateChanged();
                  });
                },
              );
            },
          ),
        );
      },
    );
  }
}
