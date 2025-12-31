import 'item_config.dart';

class ShopConfig {
  
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
    return ItemConfig.getSellPrice(itemType);
  }
  
  // Get buy price for an item (returns null if not available for purchase)
  static Map<String, dynamic>? getBuyPrice(String itemType) {
    return ItemConfig.getBuyPrice(itemType);
  }
  
  // Check if item is available for purchase
  static bool canBuy(String itemType) {
    return ItemConfig.canBuy(itemType);
  }
  
  // Check if item can be sold
  static bool canSell(String itemType) {
    return ItemConfig.canSell(itemType);
  }
}
