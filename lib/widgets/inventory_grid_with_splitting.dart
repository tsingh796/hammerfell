import 'package:flutter/material.dart';
import 'item_icon.dart';

/// A reusable inventory grid widget that supports:
/// - Drag and drop item movement
/// - Long press to split stacks
/// - Held items display above source slot
/// - Auto-return items to source on outside click or disposal
class InventoryGridWithSplitting extends StatefulWidget {
  final List<Map<String, dynamic>?> slots;
  final Function(int fromIndex, int toIndex) onMoveItem;
  final Map<String, dynamic>? Function(int index) onSplitStack;
  final Function() onSave;
  final int columns;
  final int rows;
  final double? width;
  final double slotSize;
  final double spacing;

  const InventoryGridWithSplitting({
    Key? key,
    required this.slots,
    required this.onMoveItem,
    required this.onSplitStack,
    required this.onSave,
    this.columns = 5,
    this.rows = 1,
    this.width,
    this.slotSize = 48,
    this.spacing = 4,
  }) : super(key: key);

  @override
  State<InventoryGridWithSplitting> createState() => _InventoryGridWithSplittingState();
}

class _InventoryGridWithSplittingState extends State<InventoryGridWithSplitting> {
  Map<String, dynamic>? _heldItems;
  int? _heldItemsSourceIndex;

  @override
  void dispose() {
    // Return held items to source when widget is disposed
    _returnHeldItemsToSource();
    super.dispose();
  }

  void _returnHeldItemsToSource() {
    if (_heldItems != null && _heldItemsSourceIndex != null) {
      var sourceSlot = widget.slots[_heldItemsSourceIndex!];
      if (sourceSlot != null && sourceSlot['type'] == _heldItems!['type']) {
        sourceSlot['count'] += _heldItems!['count'] as int;
        widget.onSave();
      }
      if (mounted) {
        setState(() {
          _heldItems = null;
          _heldItemsSourceIndex = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gridWidth = widget.width ?? (widget.columns * (widget.slotSize + widget.spacing) - widget.spacing);
    final gridHeight = widget.rows * (widget.slotSize + widget.spacing) - widget.spacing;

    return GestureDetector(
      onTap: () {
        // Return held items to source if clicking on the grid background
        if (_heldItems != null) {
          _returnHeldItemsToSource();
        }
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
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
                            data: {...slot, 'from': index},
                            feedback: Material(
                              color: Colors.transparent,
                              child: Container(
                                width: widget.slotSize,
                                height: widget.slotSize,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.amber, width: 2),
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: ItemIcon(type: slot['type'], count: slot['count'], size: 20),
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
                            child: GestureDetector(
                              onLongPress: () {
                                if (slot['count'] > 1) {
                                  setState(() {
                                    // Store original type before split
                                    final originalType = slot['type'];
                                    // Split returns the removed half
                                    final splitItems = widget.onSplitStack(index);
                                    if (splitItems != null) {
                                      _heldItems = splitItems;
                                      _heldItemsSourceIndex = index;
                                    }
                                  });
                                }
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey, width: 2),
                                  color: Colors.black.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: ItemIcon(type: slot['type'], count: slot['count'], size: 20),
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

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (_heldItems != null) {
                          setState(() {
                            // Check if tapping the source slot - merge back and cancel
                            if (_heldItemsSourceIndex == index) {
                              if (slot != null && slot['type'] == _heldItems!['type']) {
                                slot['count'] += _heldItems!['count'] as int;
                                _heldItems = null;
                                _heldItemsSourceIndex = null;
                                widget.onSave();
                              }
                            } else if (slot == null) {
                              // Place in empty slot
                              widget.slots[index] = _heldItems;
                              _heldItems = null;
                              _heldItemsSourceIndex = null;
                            } else if (slot['type'] == _heldItems!['type']) {
                              // Stack with same item type
                              int space = 64 - (slot['count'] as int);
                              int adding = _heldItems!['count'] as int;
                              if (adding <= space) {
                                slot['count'] += adding;
                                _heldItems = null;
                                _heldItemsSourceIndex = null;
                              } else {
                                slot['count'] = 64;
                                _heldItems!['count'] = adding - space;
                              }
                            } else {
                              // Different item type - return to source
                              if (_heldItemsSourceIndex != null) {
                                var sourceSlot = widget.slots[_heldItemsSourceIndex!];
                                if (sourceSlot != null && sourceSlot['type'] == _heldItems!['type']) {
                                  sourceSlot['count'] += _heldItems!['count'] as int;
                                  _heldItems = null;
                                  _heldItemsSourceIndex = null;
                                }
                              }
                            }

                            if (_heldItems == null) {
                              widget.onSave();
                            }
                          });
                        }
                      },
                      child: slotWidget,
                    );
                  },
                  onWillAccept: (data) => data != null,
                  onAccept: (data) {
                    widget.onMoveItem(data['from'] as int, index);
                  },
                );
              },
            ),
          ),
          // Held items indicator positioned above source slot
          if (_heldItems != null && _heldItemsSourceIndex != null)
            Positioned(
              left: (_heldItemsSourceIndex! % widget.columns) * (widget.slotSize + widget.spacing),
              top: -56,
              child: Container(
                width: widget.slotSize,
                height: widget.slotSize,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.orange, width: 3),
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: ItemIcon(type: _heldItems!['type'], count: _heldItems!['count'], size: 20),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
