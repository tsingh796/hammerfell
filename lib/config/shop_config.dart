class ShopConfig {
  // Item prices - both buy (what you pay) and sell (what shop pays you)
  // Format: {'buy': amount, 'sell': amount, 'coinType': 'copper'/'silver'/'gold', 'quantity': items per transaction}
  static const Map<String, Map<String, dynamic>> prices = {
    // Ores
    'coal': {'buy': 2, 'sell': 1, 'coinType': 'copper', 'quantity': 8},
    'stone': {'buy': 1, 'sell': 1, 'coinType': 'copper', 'quantity': 16},
    'copper_ore': {'buy': 5, 'sell': 3, 'coinType': 'copper', 'quantity': 1},
    'iron_ore': {'buy': 8, 'sell': 6, 'coinType': 'copper', 'quantity': 1},
    'silver_ore': {'buy': 3, 'sell': 2, 'coinType': 'silver', 'quantity': 1},
    'gold_ore': {'buy': 5, 'sell': 3, 'coinType': 'silver', 'quantity': 1},
    'diamond': {'buy': 15, 'sell': 10, 'coinType': 'gold', 'quantity': 1},
    
    // Ingots
    'copper_ingot': {'buy': 2, 'sell': 1, 'coinType': 'silver', 'quantity': 1},
    'iron_ingot': {'buy': 3, 'sell': 2, 'coinType': 'silver', 'quantity': 1},
    'silver_ingot': {'buy': 7, 'sell': 5, 'coinType': 'silver', 'quantity': 1},
    'gold_ingot': {'buy': 2, 'sell': 1, 'coinType': 'gold', 'quantity': 1},
  };
  
  // Category organization
  static const Map<String, List<String>> categories = {
    'Resources': [
      'diamond',
      'gold_ore',
      'gold_ingot',
      'silver_ore',
      'silver_ingot',
      'copper_ore',
      'copper_ingot',
      'iron_ore',
      'iron_ingot',
      'coal',
    ],
    'Materials': [
      'stone',
      // To be added: 'oak_log', 'oak_plank', 'stick', 'leather', 'leather_strips'
    ],
    'Armor': [], // To be populated when armor is added
    'Weapons': [], // To be populated when weapons are added
  };
  
  // Get sell price for an item (returns null if not found)
  static Map<String, dynamic>? getSellPrice(String itemType) {
    final itemPrice = prices[itemType];
    if (itemPrice == null) return null;
    return {
      'amount': itemPrice['sell'],
      'coinType': itemPrice['coinType'],
      'quantity': itemPrice['quantity'] ?? 1,
    };
  }
  
  // Get buy price for an item (returns null if not available for purchase)
  static Map<String, dynamic>? getBuyPrice(String itemType) {
    final itemPrice = prices[itemType];
    if (itemPrice == null) return null;
    return {
      'amount': itemPrice['buy'],
      'coinType': itemPrice['coinType'],
      'quantity': itemPrice['quantity'] ?? 1,
    };
  }
  
  // Check if item is available for purchase
  static bool canBuy(String itemType) {
    return prices.containsKey(itemType) && prices[itemType]!['buy'] != null;
  }
  
  // Check if item can be sold
  static bool canSell(String itemType) {
    return prices.containsKey(itemType) && prices[itemType]!['sell'] != null;
  }
}
