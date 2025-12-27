import 'package:flutter/material.dart';
import '../utils/backpack_manager.dart';
import 'package:provider/provider.dart';

import 'item_icon.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ChestManager {
  static final ChestManager _instance = ChestManager._internal();
  factory ChestManager() => _instance;
  ChestManager._internal();


  // 5x5 grid
  final int size = 25;
  final List<Map<String, dynamic>?> chest = List.generate(25, (_) => null);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final chestStr = prefs.getString('global_chest');
    if (chestStr != null && chestStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(chestStr) as List;
        for (int i = 0; i < size && i < decoded.length; i++) {
          if (decoded[i] != null) {
            chest[i] = Map<String, dynamic>.from(decoded[i] as Map);
          } else {
            chest[i] = null;
          }
        }
      } catch (_) {
        for (int i = 0; i < size; i++) {
          chest[i] = null;
        }
      }
    }
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = chest.map((slot) => slot == null ? null : Map<String, dynamic>.from(slot)).toList();
    await prefs.setString('global_chest', jsonEncode(encoded));
  }

  void moveItem(int from, int to) {
    if (from == to) return;
    final temp = chest[from];
    chest[from] = chest[to];
    chest[to] = temp;
    save();
  }

  void addItem(String type) {
    // Try to stack first
    for (var slot in chest) {
      if (slot != null && slot['type'] == type && slot['count'] < 64) {
        slot['count'] += 1;
        save();
        return;
      }
    }
    // Find empty slot
    for (int i = 0; i < chest.length; i++) {
      if (chest[i] == null) {
        chest[i] = {'type': type, 'count': 1};
        save();
        return;
      }
    }
  }
}

class ChestWidget extends StatefulWidget {
  const ChestWidget({super.key});

  @override
  State<ChestWidget> createState() => _ChestWidgetState();
}

class _ChestWidgetState extends State<ChestWidget> {
  @override
  void initState() {
    super.initState();
    ChestManager().load().then((_) {
      setState(() {});
    });
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Chest', style: TextStyle(fontWeight: FontWeight.bold)),
        _buildChestGrid(),
        const SizedBox(height: 24),
        const Text('Backpack'),
        _buildBackpackGrid(),
      ],
    );
  }

  Widget _buildChestGrid() {
    final chest = ChestManager().chest;
    return SizedBox(
      height: 300,
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
        itemCount: 25,
        itemBuilder: (context, index) {
          final slot = chest[index];
          return DragTarget<Map<String, dynamic>>(
            builder: (context, candidateData, rejectedData) {
              return Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.brown, width: 2),
                  color: slot != null ? Colors.brown.withOpacity(0.18) : Colors.brown.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: slot != null
                    ? Draggable<Map<String, dynamic>>(
                        data: {...slot, 'fromChest': index},
                        feedback: Material(
                          color: Colors.transparent,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.amber, width: 2),
                              color: Colors.brown.withOpacity(0.7),
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
                // 1. Move item within chest (merge if same type, else swap)
                if (data['fromChest'] != null) {
                  int fromIdx = data['fromChest'];
                  if (fromIdx == index) return;
                  final chest = ChestManager().chest;
                  final fromSlot = chest[fromIdx];
                  final toSlot = chest[index];
                  if (fromSlot != null && toSlot != null && fromSlot['type'] == toSlot['type'] && toSlot['count'] < 64) {
                    int space = 64 - (toSlot['count'] as int);
                    int toMove = fromSlot['count'] > space ? space : fromSlot['count'];
                    toSlot['count'] += toMove;
                    fromSlot['count'] -= toMove;
                    if (fromSlot['count'] <= 0) chest[fromIdx] = null;
                  } else {
                    ChestManager().moveItem(fromIdx, index);
                  }
                  ChestManager().save();
                }
                // 2. Move from backpack to chest (merge if same type, else fill empty)
                else if (data['from'] != null) {
                  final backpack = BackpackManager().backpack;
                  int fromIdx = data['from'];
                  if (backpack[fromIdx] != null) {
                    int moveCount = backpack[fromIdx]!['count'] ?? 1;
                    String type = backpack[fromIdx]!['type'];
                    // Try to stack into chest slot if same type
                    if (slot != null && slot['type'] == type && slot['count'] < 64) {
                      int space = 64 - (slot['count'] as int);
                      int toMove = moveCount > space ? space : moveCount;
                      slot['count'] += toMove;
                      backpack[fromIdx]!['count'] -= toMove;
                      if (backpack[fromIdx]!['count'] <= 0) backpack[fromIdx] = null;
                    } else if (slot == null) {
                      chest[index] = {'type': type, 'count': moveCount};
                      backpack[fromIdx] = null;
                    }
                    BackpackManager().save();
                  }
                }
                ChestManager().save();
                setState(() {});
              });
            },
          );
        },
      ),
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
                  // Move item within backpack
                  if (data['from'] != null && data['fromChest'] == null) {
                    backpackManager.moveItem(data['from'], index);
                  }
                  // Move from chest to backpack (move full stack)
                  else if (data['fromChest'] != null) {
                    setState(() {
                      final chest = ChestManager().chest;
                      int fromIdx = data['fromChest'];
                      if (chest[fromIdx] != null) {
                        int moveCount = chest[fromIdx]!['count'] ?? 1;
                        String type = chest[fromIdx]!['type'];
                        // Try to stack into backpack slot if same type
                        if (slot != null && slot['type'] == type && slot['count'] < 64) {
                          int space = 64 - (slot['count'] as int);
                          int toMove = moveCount > space ? space : moveCount;
                          slot['count'] += toMove;
                          chest[fromIdx]!['count'] -= toMove;
                          if (chest[fromIdx]!['count'] <= 0) chest[fromIdx] = null;
                        } else if (slot == null) {
                          backpack[index] = {'type': type, 'count': moveCount};
                          chest[fromIdx] = null;
                        }
                        ChestManager().save();
                        BackpackManager().save();
                      }
                    });
                  }
                  // No need for BackpackManager().save() here for within-backpack moves; Consumer will rebuild
                },
              );
            },
          ),
        );
      },
    );
  }
}
