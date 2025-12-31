class ItemConfig {
  final String id;
  final String name;
  final bool mineable;
  final bool smeltable;
  final String? smeltsTo;
  final int? smeltTime;
  final int stackSize;
  final Map<String, dynamic>? shopPrice;
  
  const ItemConfig({
    required this.id,
    required this.name,
    this.mineable = false,
    this.smeltable = false,
    this.smeltsTo,
    this.smeltTime,
    this.stackSize = 64,
    this.shopPrice,
  });
  
  static const Map<String, ItemConfig> _items = {
    // Ores
    'coal': ItemConfig(
      id: 'coal',
      name: 'Coal',
      mineable: true,
      smeltable: false,
      stackSize: 64,
      shopPrice: {'buy': 2, 'sell': 1, 'coinType': 'copper', 'quantity': 8},
    ),
    'stone': ItemConfig(
      id: 'stone',
      name: 'Stone',
      mineable: true,
      smeltable: false,
      stackSize: 64,
      shopPrice: {'buy': 1, 'sell': 1, 'coinType': 'copper', 'quantity': 16},
    ),
    'copper_ore': ItemConfig(
      id: 'copper_ore',
      name: 'Copper Ore',
      mineable: true,
      smeltable: true,
      smeltsTo: 'copper_ingot',
      smeltTime: 10,
      stackSize: 64,
      shopPrice: {'buy': 5, 'sell': 3, 'coinType': 'copper', 'quantity': 1},
    ),
    'iron_ore': ItemConfig(
      id: 'iron_ore',
      name: 'Iron Ore',
      mineable: true,
      smeltable: true,
      smeltsTo: 'iron_ingot',
      smeltTime: 10,
      stackSize: 64,
      shopPrice: {'buy': 8, 'sell': 6, 'coinType': 'copper', 'quantity': 1},
    ),
    'silver_ore': ItemConfig(
      id: 'silver_ore',
      name: 'Silver Ore',
      mineable: true,
      smeltable: true,
      smeltsTo: 'silver_ingot',
      smeltTime: 10,
      stackSize: 64,
      shopPrice: {'buy': 3, 'sell': 2, 'coinType': 'silver', 'quantity': 1},
    ),
    'gold_ore': ItemConfig(
      id: 'gold_ore',
      name: 'Gold Ore',
      mineable: true,
      smeltable: true,
      smeltsTo: 'gold_ingot',
      smeltTime: 10,
      stackSize: 64,
      shopPrice: {'buy': 5, 'sell': 3, 'coinType': 'silver', 'quantity': 1},
    ),
    'diamond': ItemConfig(
      id: 'diamond',
      name: 'Diamond',
      mineable: true,
      smeltable: false,
      stackSize: 64,
      shopPrice: {'buy': 15, 'sell': 10, 'coinType': 'gold', 'quantity': 1},
    ),
    
    // Ingots
    'copper_ingot': ItemConfig(
      id: 'copper_ingot',
      name: 'Copper Ingot',
      mineable: false,
      smeltable: false,
      stackSize: 64,
      shopPrice: {'buy': 2, 'sell': 1, 'coinType': 'silver', 'quantity': 1},
    ),
    'iron_ingot': ItemConfig(
      id: 'iron_ingot',
      name: 'Iron Ingot',
      mineable: false,
      smeltable: false,
      stackSize: 64,
      shopPrice: {'buy': 3, 'sell': 2, 'coinType': 'silver', 'quantity': 1},
    ),
    'silver_ingot': ItemConfig(
      id: 'silver_ingot',
      name: 'Silver Ingot',
      mineable: false,
      smeltable: false,
      stackSize: 64,
      shopPrice: {'buy': 7, 'sell': 5, 'coinType': 'silver', 'quantity': 1},
    ),
    'gold_ingot': ItemConfig(
      id: 'gold_ingot',
      name: 'Gold Ingot',
      mineable: false,
      smeltable: false,
      stackSize: 64,
      shopPrice: {'buy': 2, 'sell': 1, 'coinType': 'gold', 'quantity': 1},
    ),
  };
  
  // Static getters for item properties
  static ItemConfig? get(String id) => _items[id];
  static bool exists(String id) => _items.containsKey(id);
  static int getStackSize(String id) => _items[id]?.stackSize ?? 64;
  static bool isMineable(String id) => _items[id]?.mineable ?? false;
  static bool isSmeltable(String id) => _items[id]?.smeltable ?? false;
  static String? getSmeltsTo(String id) => _items[id]?.smeltsTo;
  static int? getSmeltTime(String id) => _items[id]?.smeltTime;
  static Map<String, dynamic>? getShopPrice(String id) => _items[id]?.shopPrice;
  
  // Shop helper methods
  static Map<String, dynamic>? getBuyPrice(String id) {
    final price = _items[id]?.shopPrice;
    if (price == null || price['buy'] == null) return null;
    return {
      'amount': price['buy'],
      'coinType': price['coinType'],
      'quantity': price['quantity'] ?? 1,
    };
  }
  
  static Map<String, dynamic>? getSellPrice(String id) {
    final price = _items[id]?.shopPrice;
    if (price == null || price['sell'] == null) return null;
    return {
      'amount': price['sell'],
      'coinType': price['coinType'],
      'quantity': price['quantity'] ?? 1,
    };
  }
  
  static bool canBuy(String id) {
    final price = _items[id]?.shopPrice;
    return price != null && price['buy'] != null;
  }
  
  static bool canSell(String id) {
    final price = _items[id]?.shopPrice;
    return price != null && price['sell'] != null;
  }
  
  // Get all item IDs
  static List<String> getAllItemIds() => _items.keys.toList();
  
  // Get items by category
  static List<String> getMineable() => 
      _items.entries.where((e) => e.value.mineable).map((e) => e.key).toList();
  
  static List<String> getSmeltable() => 
      _items.entries.where((e) => e.value.smeltable).map((e) => e.key).toList();
}
