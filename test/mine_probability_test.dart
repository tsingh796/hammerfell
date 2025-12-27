import 'dart:math';

void main() {
  final random = Random();
  
  // Test 1: Normal distribution (no exclusions)
  print('=== Test 1: Normal distribution (no exclusions) ===');
  Map<String, int> counts1 = {
    'coal': 0,
    'copper': 0,
    'iron': 0,
    'gold': 0,
    'diamond': 0
  };
  
  for (int i = 0; i < 1000; i++) {
    Map<String, double> mineTypeChances = {
      'coal': 0.45,
      'copper': 0.25,
      'iron': 0.15,
      'gold': 0.10,
      'diamond': 0.05,
    };
    
    final oreNames = mineTypeChances.keys.toList();
    final weights = oreNames.map((k) => mineTypeChances[k] ?? 0.0).toList();
    final roll = random.nextDouble();
    double cumulative = 0.0;
    String? selected;
    
    for (int j = 0; j < oreNames.length; j++) {
      cumulative += weights[j];
      if (roll <= cumulative) {
        selected = oreNames[j];
        break;
      }
    }
    
    if (selected != null) {
      counts1[selected] = (counts1[selected] ?? 0) + 1;
    }
  }
  
  counts1.forEach((ore, count) {
    print('$ore: $count (${(count / 10).toStringAsFixed(1)}%)');
  });
  
  // Test 2: Exclude coal (simulating searching from coal mine)
  print('\n=== Test 2: Exclude coal (searching from coal mine) ===');
  Map<String, int> counts2 = {
    'coal': 0,
    'copper': 0,
    'iron': 0,
    'gold': 0,
    'diamond': 0
  };
  
  for (int i = 0; i < 1000; i++) {
    Map<String, double> mineTypeChances = {
      'coal': 0.45,
      'copper': 0.25,
      'iron': 0.15,
      'gold': 0.10,
      'diamond': 0.05,
    };
    
    // Exclude coal
    String currentMine = 'coal';
    if (mineTypeChances.containsKey(currentMine)) {
      mineTypeChances.remove(currentMine);
      // Normalize
      final total = mineTypeChances.values.fold(0.0, (sum, val) => sum + val);
      if (total > 0) {
        mineTypeChances = mineTypeChances.map((key, value) => MapEntry(key, value / total));
      }
    }
    
    final oreNames = mineTypeChances.keys.toList();
    final weights = oreNames.map((k) => mineTypeChances[k] ?? 0.0).toList();
    final roll = random.nextDouble();
    double cumulative = 0.0;
    String? selected;
    
    for (int j = 0; j < oreNames.length; j++) {
      cumulative += weights[j];
      if (roll <= cumulative) {
        selected = oreNames[j];
        break;
      }
    }
    
    if (selected != null) {
      counts2[selected] = (counts2[selected] ?? 0) + 1;
    }
  }
  
  counts2.forEach((ore, count) {
    print('$ore: $count (${(count / 10).toStringAsFixed(1)}%)');
  });
  
  print('\nExpected when excluding coal:');
  print('copper: ~45.5% (0.25/0.55)');
  print('iron: ~27.3% (0.15/0.55)');
  print('gold: ~18.2% (0.10/0.55)');
  print('diamond: ~9.1% (0.05/0.55)');
}
