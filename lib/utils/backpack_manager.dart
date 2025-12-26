
  import 'dart:convert';
  import 'package:shared_preferences/shared_preferences.dart';
  import 'package:flutter/foundation.dart';


class BackpackManager extends ChangeNotifier {
  static final BackpackManager _instance = BackpackManager._internal();
  factory BackpackManager() => _instance;
  BackpackManager._internal();

  final int size = 5;
  List<Map<String, dynamic>?> backpack = List.filled(5, null, growable: false);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final backpackStr = prefs.getString('global_backpack');
    if (backpackStr != null && backpackStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(backpackStr) as List;
        for (int i = 0; i < size && i < decoded.length; i++) {
          if (decoded[i] != null) {
            backpack[i] = Map<String, dynamic>.from(decoded[i] as Map);
          } else {
            backpack[i] = null;
          }
        }
      } catch (_) {
        for (int i = 0; i < size; i++) {
          backpack[i] = null;
        }
      }
    }
    notifyListeners();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = backpack.map((slot) => slot == null ? null : Map<String, dynamic>.from(slot)).toList();
    await prefs.setString('global_backpack', jsonEncode(encoded));
    notifyListeners();
  }

  void addItem(String type) {
    bool added = false;
    for (var slot in backpack) {
      if (slot != null && slot['type'] == type && (slot['count'] as int) < 64) {
        slot['count'] = (slot['count'] as int) + 1;
        added = true;
        break;
      }
    }
    if (!added) {
      for (int i = 0; i < size; i++) {
        if (backpack[i] == null) {
          backpack[i] = {'type': type, 'count': 1};
          added = true;
          break;
        }
      }
    }
    save();
    notifyListeners();
  }

  void moveItem(int from, int to) {
    if (from < 0 || from >= size || to < 0 || to >= size) return;
    final slotFrom = backpack[from];
    final slotTo = backpack[to];
    if (slotFrom == null) return;
    if (slotTo == null) {
      backpack[to] = slotFrom;
      backpack[from] = null;
    } else if (slotFrom['type'] == slotTo['type']) {
      int available = 64 - (slotTo['count'] as int);
      int movingCount = slotFrom['count'] as int;
      if (available >= movingCount) {
        slotTo['count'] = (slotTo['count'] as int) + movingCount;
        backpack[from] = null;
      } else if (available > 0) {
        slotTo['count'] = 64;
        slotFrom['count'] = movingCount - available;
      }
    } else {
      final temp = backpack[to];
      backpack[to] = slotFrom;
      backpack[from] = temp;
    }
    save();
    notifyListeners();
  }

  void clear() {
    for (int i = 0; i < size; i++) {
      backpack[i] = null;
    }
    save();
    notifyListeners();
  }
}
