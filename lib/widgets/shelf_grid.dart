import 'package:flutter/material.dart';
import 'item_icon.dart';

/// A shelf grid widget similar to inventory grid but with unlimited stacking.
/// Used for ore and ingot storage on the homepage.
/// 
/// Key differences from regular inventory:
/// - No 64 cap on stack size (can hold unlimited items of same type)
/// - Typically vertical layout (1 column, multiple rows)
/// - Supports drag and drop for moving items
class ShelfGrid extends StatefulWidget {
  final List<Map<String, dynamic>?> slots;
  final Function(int fromIndex, int toIndex, {bool fromExternal, String? fromShelf}) onMoveItem;
  final Function() onSave;
  final int columns;
  final int rows;
  final double slotSize;
  final double spacing;
  final bool acceptExternalItems; // Whether this shelf accepts items from outside (e.g., from chest)
  final String shelfId; // Identifier for this shelf (e.g., 'left' or 'right')

  const ShelfGrid({
    Key? key,
    required this.slots,
    required this.onMoveItem,
    required this.onSave,
    required this.shelfId,
    this.columns = 1,
    this.rows = 5,
    this.slotSize = 56,
    this.spacing = 8,
    this.acceptExternalItems = true,
  }) : super(key: key);

  @override
  State<ShelfGrid> createState() => _ShelfGridState();
}

class _ShelfGridState extends State<ShelfGrid> {
  @override
  Widget build(BuildContext context) {
    final gridWidth = widget.columns * (widget.slotSize + widget.spacing) - widget.spacing;
    final gridHeight = widget.rows * (widget.slotSize + widget.spacing) - widget.spacing;

    return SizedBox(
            width: gridWidth,
            height: gridHeight,
            child: GridView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: widget.columns,
                mainAxisSpacing: widget.spacing,
                crossAxisSpacing: widget.spacing,
                childAspectRatio: 1,
              ),
              itemCount: widget.slots.length,
              itemBuilder: (context, index) {
                final slot = widget.slots[index];
                return DragTarget<Map<String, dynamic>>(
                  builder: (context, candidateData, rejectedData) {
                    Widget slotWidget = slot != null
                        ? Draggable<Map<String, dynamic>>(
                            data: {...slot, 'from': index, 'sourceWidget': 'shelf', 'shelfId': widget.shelfId},
                            feedback: Material(
                              color: Colors.transparent,
                              child: ItemIcon(
                                type: slot['type'],
                                count: slot['count'] ?? 1,
                                size: widget.slotSize,
                              ),
                            ),
                            childWhenDragging: _buildEmptySlot(),
                            onDragEnd: (details) {
                              if (!details.wasAccepted) {
                                // Item wasn't accepted anywhere, just refresh
                                setState(() {});
                              }
                            },
                            child: _buildFilledSlot(slot),
                          )
                        : _buildEmptySlot();

                    return slotWidget;
                  },
                  onWillAccept: (data) {
                    if (!widget.acceptExternalItems && data?['sourceWidget'] != 'shelf') {
                      return false;
                    }
                    return data != null;
                  },
                  onAccept: (data) {
                    final fromIndex = data['from'] as int;
                    final fromExternal = data['sourceWidget'] != 'shelf';
                    final fromShelf = data['shelfId'] as String?;
                    
                    widget.onMoveItem(fromIndex, index, fromExternal: fromExternal, fromShelf: fromShelf);
                    widget.onSave();
                    setState(() {}); // Refresh UI
                  },
                );
              },
            ),
          );
  }

  Widget _buildEmptySlot() {
    return Container(
      width: widget.slotSize,
      height: widget.slotSize,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey, width: 2),
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildFilledSlot(Map<String, dynamic> slot) {
    return Container(
      width: widget.slotSize,
      height: widget.slotSize,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey, width: 2),
        color: Colors.black.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ItemIcon(
        type: slot['type'],
        count: slot['count'] ?? 1,
        size: widget.slotSize * 0.7,
      ),
    );
  }
}
