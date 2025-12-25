import 'package:flutter/material.dart';
import '../utils/backpack_manager.dart';
import 'item_icon.dart';

class ChestManager {
  static final ChestManager _instance = ChestManager._internal();
  factory ChestManager() => _instance;
  ChestManager._internal();

  // 5x5 grid
  final List<Map<String, dynamic>?> chest = List.generate(25, (_) => null);

  void moveItem(int from, int to) {
    if (from == to) return;
    final temp = chest[from];
    chest[from] = chest[to];
    chest[to] = temp;
  }

  void addItem(String type) {
    // Try to stack first
    for (var slot in chest) {
      if (slot != null && slot['type'] == type && slot['count'] < 64) {
        slot['count'] += 1;
        return;
      }
    }
    // Find empty slot
    for (int i = 0; i < chest.length; i++) {
      if (chest[i] == null) {
        chest[i] = {'type': type, 'count': 1};
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
                // 1. Move item within chest
                if (data['fromChest'] != null) {
                  ChestManager().moveItem(data['fromChest'], index);
                }
                // 2. Move from backpack to chest
                else if (data['from'] != null) {
                  final backpack = BackpackManager().backpack;
                  int fromIdx = data['from'];
                  if (backpack[fromIdx] != null) {
                    ChestManager().addItem(backpack[fromIdx]!['type']);
                    backpack[fromIdx]!['count'] -= 1;
                    if (backpack[fromIdx]!['count'] <= 0) backpack[fromIdx] = null;
                    BackpackManager().save();
                  }
                }
                // 3. Move from chest to backpack
                else if (data['fromChest'] != null) {
                  // handled above
                }
                setState(() {});
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildBackpackGrid() {
    final backpack = BackpackManager().backpack;
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
                // 1. Move item within backpack
                if (data['from'] != null) {
                  BackpackManager().moveItem(data['from'], index);
                }
                // 2. Move from chest to backpack
                else if (data['fromChest'] != null) {
                  final chest = ChestManager().chest;
                  int fromIdx = data['fromChest'];
                  if (chest[fromIdx] != null) {
                    BackpackManager().addItem(chest[fromIdx]!['type']);
                    chest[fromIdx]!['count'] -= 1;
                    if (chest[fromIdx]!['count'] <= 0) chest[fromIdx] = null;
                  }
                }
                setState(() {});
              });
            },
          );
        },
      ),
    );
  }
}
