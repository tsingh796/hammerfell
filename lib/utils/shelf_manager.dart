import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Manages the left and right shelves on the homepage.
/// Shelves store ores (left) and ingots (right) with unlimited stacking.
class ShelfManager extends ChangeNotifier {
  static final ShelfManager _instance = ShelfManager._internal();
  factory ShelfManager() => _instance;
  ShelfManager._internal();

  // Left shelf: Ores (5 slots)
  List<Map<String, dynamic>?> leftShelf = List.filled(5, null, growable: false);
  
  // Right shelf: Ingots (5 slots)
  List<Map<String, dynamic>?> rightShelf = List.filled(5, null, growable: false);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load left shelf (ores)
    final leftShelfStr = prefs.getString('left_shelf');
    if (leftShelfStr != null && leftShelfStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(leftShelfStr) as List;
        for (int i = 0; i < 5 && i < decoded.length; i++) {
          if (decoded[i] != null) {
            leftShelf[i] = Map<String, dynamic>.from(decoded[i] as Map);
          } else {
            leftShelf[i] = null;
          }
        }
      } catch (_) {
        leftShelf = List.filled(5, null, growable: false);
      }
    }
    
    // Load right shelf (ingots)
    final rightShelfStr = prefs.getString('right_shelf');
    if (rightShelfStr != null && rightShelfStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(rightShelfStr) as List;
        for (int i = 0; i < 5 && i < decoded.length; i++) {
          if (decoded[i] != null) {
            rightShelf[i] = Map<String, dynamic>.from(decoded[i] as Map);
          } else {
            rightShelf[i] = null;
          }
        }
      } catch (_) {
        rightShelf = List.filled(5, null, growable: false);
      }
    }
    
    notifyListeners();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save left shelf
    final leftEncoded = leftShelf.map((slot) => slot == null ? null : Map<String, dynamic>.from(slot)).toList();
    await prefs.setString('left_shelf', jsonEncode(leftEncoded));
    
    // Save right shelf
    final rightEncoded = rightShelf.map((slot) => slot == null ? null : Map<String, dynamic>.from(slot)).toList();
    await prefs.setString('right_shelf', jsonEncode(rightEncoded));
    
    notifyListeners();
  }

  /// Add item to appropriate shelf (left for ores, right for ingots)
  /// Returns true if added successfully
  bool addItem(String type) {
    // Determine which shelf based on item type
    final isOre = type.contains('ore') || type == 'coal' || type == 'stone' || type == 'diamond';
    final shelf = isOre ? leftShelf : rightShelf;
    
    // Try to add to existing stack (unlimited stacking)
    for (var slot in shelf) {
      if (slot != null && slot['type'] == type) {
        slot['count'] = (slot['count'] as int) + 1;
        save();
        return true;
      }
    }
    
    // Try to add to empty slot
    for (int i = 0; i < 5; i++) {
      if (shelf[i] == null) {
        shelf[i] = {'type': type, 'count': 1};
        save();
        return true;
      }
    }
    
    return false; // Shelf is full
  }

  /// Move item within a shelf or between shelves
  void moveItem(bool isLeftShelf, int from, int to, {bool toRightShelf = false}) {
    final fromShelf = isLeftShelf ? leftShelf : rightShelf;
    final toShelf = toRightShelf ? rightShelf : fromShelf;
    
    if (from < 0 || from >= 5 || to < 0 || to >= 5) return;
    if (from == to && fromShelf == toShelf) return;
    
    final slotFrom = fromShelf[from];
    final slotTo = toShelf[to];
    
    if (slotFrom == null) return;
    
    if (slotTo == null) {
      // Move to empty slot
      toShelf[to] = slotFrom;
      fromShelf[from] = null;
    } else if (slotFrom['type'] == slotTo['type']) {
      // Stack same items (unlimited stacking)
      slotTo['count'] = (slotTo['count'] as int) + (slotFrom['count'] as int);
      fromShelf[from] = null;
    } else {
      // Swap different items
      final temp = toShelf[to];
      toShelf[to] = slotFrom;
      fromShelf[from] = temp;
    }
    
    save();
  }

  /// Get item count from shelves
  int getItemCount(String type) {
    int count = 0;
    
    // Check left shelf
    for (var slot in leftShelf) {
      if (slot != null && slot['type'] == type) {
        count += slot['count'] as int;
      }
    }
    
    // Check right shelf
    for (var slot in rightShelf) {
      if (slot != null && slot['type'] == type) {
        count += slot['count'] as int;
      }
    }
    
    return count;
  }

  /// Remove specific amount of an item from shelves
  /// Returns true if successful
  bool removeItem(String type, int amount) {
    final isOre = type.contains('ore') || type == 'coal' || type == 'stone' || type == 'diamond';
    final shelf = isOre ? leftShelf : rightShelf;
    
    // Find slot with this item
    for (var slot in shelf) {
      if (slot != null && slot['type'] == type) {
        if ((slot['count'] as int) >= amount) {
          slot['count'] = (slot['count'] as int) - amount;
          if (slot['count'] == 0) {
            final index = shelf.indexOf(slot);
            shelf[index] = null;
          }
          save();
          return true;
        }
      }
    }
    
    return false;
  }

  void clear() {
    leftShelf = List.filled(5, null, growable: false);
    rightShelf = List.filled(5, null, growable: false);
    save();
  }
}
