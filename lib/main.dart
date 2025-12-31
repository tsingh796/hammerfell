import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'utils/backpack_manager.dart';
import 'utils/shelf_manager.dart';
import 'utils/coin_manager.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';
import 'widgets/furnace_widget.dart';
import 'widgets/chest_widget.dart';
import 'widgets/item_icon.dart';
import 'widgets/inventory_grid_with_splitting.dart';
import 'widgets/shelf_grid.dart';
import 'widgets/coin_converter.dart';
import 'modals/mine_modal.dart';
import 'utils/color_utils.dart';
// import 'modals/forest_modal.dart';
import 'pages/mine_page.dart';
import 'pages/forest_page.dart';
import 'pages/shop_page.dart';

// --- Mine class for persistence and runtime ---
class Mine {
  final String oreType;
  final Map<String, dynamic>? extra;
  Mine({required this.oreType, this.extra});

  factory Mine.fromJson(Map<String, dynamic> json) {
    return Mine(
      oreType: json['oreType'] as String,
      extra: json['extra'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    'oreType': oreType,
    if (extra != null) 'extra': extra,
  };
}

// Which modal to show in the center column

// State for showing ore/ingot names on tap

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(OreMinerApp());
}

class OreMinerApp extends StatelessWidget {
  const OreMinerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<BackpackManager>.value(
          value: BackpackManager(),
        ),
        ChangeNotifierProvider<CoinManager>.value(
          value: CoinManager(),
        ),
      ],
      child: MaterialApp(
        title: 'Ore Miner Deluxe',
        theme: ThemeData.dark(),
        home: const HomePage(),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  FurnaceState? _homeFurnaceState;
  final String _homeFurnaceKey = 'furnace_home';

  @override
  void initState() {
    super.initState();
    _loadConfig();
    BackpackManager().load();
    ShelfManager().load();
    _homeFurnaceState = FurnaceState();
    _homeFurnaceState!.load(_homeFurnaceKey).then((_) {
      setState(() {});
    });
    SharedPreferences.getInstance().then((prefs) async {
      // Load old ore/ingot values for migration
      final oldIronOre = prefs.getInt('ironOre') ?? 0;
      final oldCopperOre = prefs.getInt('copperOre') ?? 0;
      final oldGoldOre = prefs.getInt('goldOre') ?? 0;
      final oldDiamond = prefs.getInt('diamond') ?? 0;
      final oldCoal = prefs.getInt('coal') ?? 0;
      final oldStone = prefs.getInt('stone') ?? 0;
      final oldIronIngot = prefs.getInt('ironIngot') ?? 0;
      final oldCopperIngot = prefs.getInt('copperIngot') ?? 0;
      final oldGoldIngot = prefs.getInt('goldIngot') ?? 0;
      
      // Migrate old data to shelves if shelves are empty
      final needsMigration = prefs.getBool('shelves_migrated') != true;
      if (needsMigration) {
        await _migrateToShelves(
          oldIronOre, oldCopperOre, oldGoldOre, oldDiamond, oldCoal, oldStone,
          oldIronIngot, oldCopperIngot, oldGoldIngot
        );
        await prefs.setBool('shelves_migrated', true);
      }
      
      setState(() {
        hammerfells = prefs.getInt('hammerfells') ?? 10;
        ironOre = oldIronOre;
        copperOre = oldCopperOre;
        goldOre = oldGoldOre;
        diamond = oldDiamond;
        coal = oldCoal;
        stone = oldStone;
        ironIngot = oldIronIngot;
        copperIngot = oldCopperIngot;
        goldIngot = oldGoldIngot;
        // Load coins into CoinManager
        final copperCoins = prefs.getInt('copperCoins') ?? 0;
        final silverCoins = prefs.getInt('silverCoins') ?? 0;
        final goldCoins = prefs.getInt('goldCoins') ?? 0;
        CoinManager().setCoins(copperCoins, silverCoins, goldCoins);
      });
      // Load last entered mine (as JSON object)
      final lastMine = prefs.getString('lastMine');
      if (lastMine != null && lastMine.isNotEmpty) {
        try {
          final decoded = jsonDecode(lastMine);
          if (decoded is Map<String, dynamic> && decoded['oreType'] != null) {
            currentMine = Mine.fromJson(decoded);
            hasEnteredMine = true;
          } else {
            currentMine = null;
            hasEnteredMine = false;
          }
        } catch (_) {
          currentMine = null;
          hasEnteredMine = false;
        }
      }
    });
  }

  Future<void> _migrateToShelves(int ironOre, int copperOre, int goldOre, int diamond, int coal, int stone,
      int ironIngot, int copperIngot, int goldIngot) async {
    final shelfMgr = ShelfManager();
    
    // Migrate ores to left shelf
    if (ironOre > 0) shelfMgr.leftShelf[0] = {'type': 'iron_ore', 'count': ironOre};
    if (copperOre > 0) shelfMgr.leftShelf[1] = {'type': 'copper_ore', 'count': copperOre};
    if (goldOre > 0) shelfMgr.leftShelf[2] = {'type': 'gold_ore', 'count': goldOre};
    if (diamond > 0) shelfMgr.leftShelf[3] = {'type': 'diamond', 'count': diamond};
    // coal and stone can go to slot 4 or beyond if needed
    
    // Migrate ingots to right shelf
    if (ironIngot > 0) shelfMgr.rightShelf[0] = {'type': 'iron_ingot', 'count': ironIngot};
    if (copperIngot > 0) shelfMgr.rightShelf[1] = {'type': 'copper_ingot', 'count': copperIngot};
    if (goldIngot > 0) shelfMgr.rightShelf[2] = {'type': 'gold_ingot', 'count': goldIngot};
    
    await shelfMgr.save();
  }

  /// Handle transfer from backpack to shelf
  void _handleBackpackToShelf(int fromIndex, int toIndex, bool isLeftShelf) {
    final backpack = BackpackManager().backpack;
    final shelf = isLeftShelf ? ShelfManager().leftShelf : ShelfManager().rightShelf;
    
    final fromSlot = backpack[fromIndex];
    final toSlot = shelf[toIndex];
    
    if (fromSlot == null) return;
    
    if (toSlot == null) {
      // Move to empty shelf slot
      shelf[toIndex] = {...fromSlot}; // Copy the data
      backpack[fromIndex] = null;
    } else if (fromSlot['type'] == toSlot['type']) {
      // Stack unlimited on shelf
      toSlot['count'] = (toSlot['count'] as int) + (fromSlot['count'] as int);
      backpack[fromIndex] = null;
    } else {
      // Swap
      final temp = shelf[toIndex] != null ? {...shelf[toIndex]!} : null;
      shelf[toIndex] = {...fromSlot}; // Copy backpack item
      backpack[fromIndex] = temp;
    }
    
    BackpackManager().save();
    ShelfManager().save();
    setState(() {});
  }

  /// Handle transfer from shelf to backpack (respect 64 cap)
  void _handleShelfToBackpack(Map<String, dynamic> data, int toIndex) {
    final fromIndex = data['from'] as int;
    final sourceWidget = data['sourceWidget'] as String;
    
    // Determine which shelf
    bool isLeftShelf = false;
    List<Map<String, dynamic>?>? shelf;
    
    // Check both shelves to find the source
    if (fromIndex < ShelfManager().leftShelf.length && 
        ShelfManager().leftShelf[fromIndex]?['type'] == data['type']) {
      isLeftShelf = true;
      shelf = ShelfManager().leftShelf;
    } else if (fromIndex < ShelfManager().rightShelf.length && 
               ShelfManager().rightShelf[fromIndex]?['type'] == data['type']) {
      isLeftShelf = false;
      shelf = ShelfManager().rightShelf;
    } else {
      return; // Couldn't find source
    }
    
    final backpack = BackpackManager().backpack;
    final fromSlot = shelf[fromIndex];
    final toSlot = backpack[toIndex];
    
    if (fromSlot == null) return;
    
    final itemType = fromSlot['type'] as String;
    final itemCount = fromSlot['count'] as int;
    
    if (toSlot == null) {
      // Move to empty backpack slot (cap at 64)
      if (itemCount <= 64) {
        backpack[toIndex] = {'type': itemType, 'count': itemCount};
        shelf[fromIndex] = null;
      } else {
        backpack[toIndex] = {'type': itemType, 'count': 64};
        fromSlot['count'] = itemCount - 64;
      }
    } else if (toSlot['type'] == itemType) {
      // Stack in backpack (cap at 64)
      final toCount = toSlot['count'] as int;
      final available = 64 - toCount;
      
      if (available >= itemCount) {
        toSlot['count'] = toCount + itemCount;
        shelf[fromIndex] = null;
      } else if (available > 0) {
        toSlot['count'] = 64;
        fromSlot['count'] = itemCount - available;
      }
      // else: no room, do nothing
    } else {
      // Swap different items
      final temp = backpack[toIndex];
      backpack[toIndex] = {'type': itemType, 'count': itemCount > 64 ? 64 : itemCount};
      if (itemCount > 64) {
        fromSlot['count'] = itemCount - 64;
      } else {
        shelf[fromIndex] = temp;
      }
    }
    
    BackpackManager().save();
    ShelfManager().save();
    setState(() {});
  }

  // Handle cross-shelf transfers (left ↔ right)
  void _handleCrossShelfTransfer(int fromIndex, int toIndex, {required String fromShelf, required bool toLeft}) {
    final shelfManager = ShelfManager();
    final sourceShelf = fromShelf == 'left' ? shelfManager.leftShelf : shelfManager.rightShelf;
    final targetShelf = toLeft ? shelfManager.leftShelf : shelfManager.rightShelf;
    
    final sourceItem = sourceShelf[fromIndex];
    if (sourceItem == null) return;

    // Create a copy of the item being moved
    final itemCopy = {...sourceItem};
    
    if (targetShelf[toIndex] == null) {
      // Target is empty, just move the item
      targetShelf[toIndex] = itemCopy;
      sourceShelf[fromIndex] = null;
    } else {
      // Target has an item - check if we can stack
      final targetItem = targetShelf[toIndex]!;
      if (targetItem['type'] == itemCopy['type']) {
        // Same type, stack them (unlimited stacking)
        targetShelf[toIndex] = {
          'type': targetItem['type'],
          'count': (targetItem['count'] ?? 1) + (itemCopy['count'] ?? 1),
        };
        sourceShelf[fromIndex] = null;
      } else {
        // Different types, swap them
        final targetCopy = {...targetItem};
        targetShelf[toIndex] = itemCopy;
        sourceShelf[fromIndex] = targetCopy;
      }
    }
    
    shelfManager.save();
    setState(() {});
  }

  void _openChestModal() {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (c) => Padding(
        padding: const EdgeInsets.all(16),
        child: ChestWidget(),
      ),
    );
  }

  void resetDebug10() {
    setState(() {
      hammerfells = 50;
      ironOre = 10;
      copperOre = 10;
      goldOre = 10;
      diamond = 10;
      coal = 10;
      stone = 10;
      ironIngot = 10;
      copperIngot = 10;
      goldIngot = 10;
      CoinManager().setCoins(50, 5, 1);
      // Reset backpack to 10 of each for demo
      for (int i = 0; i < BackpackManager().backpack.length; i++) {
        BackpackManager().backpack[i] = null;
      }
      BackpackManager().backpack[0] = {'type': 'coal', 'count': 10};
      BackpackManager().backpack[1] = {'type': 'iron', 'count': 10};
      BackpackManager().save();
      _saveGame();
    });
  }
    // ...existing code...
  // Backpack inventory: Each slot is {'type': oreType, 'count': int}
  // Use global backpack singleton

  // Public ore asset helper for use in backpack grid
  String oreAsset(String oreType) {
    switch (oreType) {
      case 'iron':
      case 'iron_ore':
        return 'assets/images/iron_ore.png';
      case 'copper':
      case 'copper_ore':
        return 'assets/images/copper_ore.png';
      case 'gold':
      case 'gold_ore':
        return 'assets/images/gold_ore.png';
      case 'diamond':
        return 'assets/images/diamond.png';
      case 'stone':
        return 'assets/images/stone.png';
      case 'coal':
        return 'assets/images/coal.png';
      case 'silver_ore':
        return 'assets/images/silver_ore.png';
      case 'copper_ingot':
        return 'assets/images/copper_ingot.png';
      case 'iron_ingot':
        return 'assets/images/iron_ingot.png';
      case 'silver_ingot':
        return 'assets/images/silver_ingot.png';
      case 'gold_ingot':
        return 'assets/images/gold_ingot.png';
      default:
        return 'assets/images/default_item.png'; // Fallback for unknown items
    }
  }

  // Instance helper for use in widget tree
  String _oreAsset(String oreType) => oreAsset(oreType);
  // Track if a mine has been entered and which mine
  bool hasEnteredMine = false;
  Mine? currentMine;
  int hammerfells = 10;
  int ironOre = 0;
  int copperOre = 0;
  int goldOre = 0;
  int diamond = 0;
  int coal = 0;
  int stone = 0;
  int ironIngot = 0;
  int copperIngot = 0;
  int goldIngot = 0;
  // Coins now managed by CoinManager
  
  // Mining chances
  double ironMineChance = 0.5;
  double copperMineChance = 0.5;
  double goldMineChance = 0.3;
  double diamondMineChance = 0.1;
  
  // Costs
  int miningCost = 1;
  int smeltIronCost = 3;
  int smeltCopperCost = 3;
  int smeltGoldCost = 5;
  
  // Animation state
  final Map<String, double> _rowScale = {};
  final Map<String, Color?> _rowOverlayColor = {};
  
  // Random number generator
  final Random _rng = Random();
  
  // Key for positioning popups
  final GlobalKey _hammerButtonKey = GlobalKey();
  
  // Mine ore chances configuration
  Map<String, Map<String, double>> mineOreChances = {};

  // ...existing code...

  Future<void> _loadConfig() async {
    try {
      final String yamlString = await rootBundle.loadString('assets/config.yml');
      final dynamic yamlData = loadYaml(yamlString);
      if (yamlData != null && yamlData['mines'] != null) {
        final Map<dynamic, dynamic> chances = yamlData['mines'] as Map<dynamic, dynamic>;
        mineOreChances = chances.map((key, value) {
          final Map<String, double> oreMap = {};
          if (value is Map) {
            value.forEach((oreKey, oreValue) {
              // Skip find_chance as it's not an ore type
              if (oreKey.toString() != 'find_chance') {
                oreMap[oreKey.toString()] = (oreValue as num).toDouble();
              }
            });
          }
          return MapEntry(key.toString(), oreMap);
        });
      }
    } catch (e) {
      // Config not found or error loading, use defaults
      mineOreChances = {};
    }
  }

  Future<void> _saveGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('hammerfells', hammerfells);
    await prefs.setInt('ironOre', ironOre);
    await prefs.setInt('copperOre', copperOre);
    await prefs.setInt('goldOre', goldOre);
    await prefs.setInt('diamond', diamond);
    await prefs.setInt('coal', coal);
    await prefs.setInt('stone', stone);
    await prefs.setInt('ironIngot', ironIngot);
    await prefs.setInt('copperIngot', copperIngot);
    await prefs.setInt('goldIngot', goldIngot);
    // Coins saved separately by CoinManager
    final coinManager = CoinManager();
    await prefs.setInt('copperCoins', coinManager.copperCoins);
    await prefs.setInt('silverCoins', coinManager.silverCoins);
    await prefs.setInt('goldCoins', coinManager.goldCoins);
    // Save last entered mine if any
    if (hasEnteredMine && currentMine != null) {
      await prefs.setString('lastMine', jsonEncode(currentMine!.toJson()));
    }
    // Save backpack using BackpackManager
    await BackpackManager().save();
  }



  void _pulseRow(String id, bool success) {
    final color = success ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3);
    setState(() {
      _rowScale[id] = 1.1;
      _rowOverlayColor[id] = color;
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _rowScale[id] = 1.0;
          _rowOverlayColor[id] = null;
        });
      }
    });
  }

  // Picks an ore to mine based on the mine type and config chances
  String pickOreForMine(Map<String, Map<String, double>> chances, Random rng, String mineType) {
    final oreChances = chances[mineType];
    if (oreChances == null || oreChances.isEmpty) {
      return mineType; // Default to the mine type itself
    }
    
    final roll = rng.nextDouble();
    double cumulative = 0.0;
    
    for (final entry in oreChances.entries) {
      cumulative += entry.value;
      if (roll <= cumulative) {
        return entry.key;
      }
    }
    
    return oreChances.keys.first; // Fallback to first ore
  }

  Future<bool> mineOre(String oreType) async {
    if (hammerfells < miningCost) return false;
    
    // Get mining chance for this ore type
    double mineChance = 1.0; // Default 100% for stone, coal
    switch (oreType) {
      case 'iron_ore':
        mineChance = ironMineChance;
        break;
      case 'copper_ore':
        mineChance = copperMineChance;
        break;
      case 'gold_ore':
        mineChance = goldMineChance;
        break;
      case 'diamond':
        mineChance = diamondMineChance;
        break;
    }
    
    final success = _rng.nextDouble() < mineChance;
    setState(() {
      hammerfells -= miningCost;
      if (success) {
        // Increment the appropriate ore counter (legacy)
        switch (oreType) {
          case 'iron_ore':
            ironOre++;
            ShelfManager().addItem('iron_ore');
            break;
          case 'copper_ore':
            copperOre++;
            ShelfManager().addItem('copper_ore');
            break;
          case 'gold_ore':
            goldOre++;
            ShelfManager().addItem('gold_ore');
            break;
          case 'diamond':
            diamond++;
            ShelfManager().addItem('diamond');
            break;
          case 'stone':
            stone++;
            ShelfManager().addItem('stone');
            break;
          case 'coal':
            coal++;
            ShelfManager().addItem('coal');
            break;
        }
      }
      _saveGame();
    });
    return true; // Always return true when hammerfells were consumed
  }

  void smeltIron() {
    if (ironOre >= smeltIronCost && hammerfells >= 1) {
      setState(() {
        ironOre -= smeltIronCost;
        hammerfells -= 1;
        ironIngot += 1;
        ShelfManager().removeItem('iron_ore', smeltIronCost);
        ShelfManager().addItem('iron_ingot');
        _saveGame();
      });
    }
  }

  void smeltCopper() {
    if (copperOre >= smeltCopperCost && hammerfells >= 1) {
      setState(() {
        copperOre -= smeltCopperCost;
        hammerfells -= 1;
        copperIngot += 1;
        ShelfManager().removeItem('copper_ore', smeltCopperCost);
        ShelfManager().addItem('copper_ingot');
        _saveGame();
      });
    }
  }

  void smeltGold() {
    if (goldOre >= smeltGoldCost && hammerfells >= 1) {
      setState(() {
        goldOre -= smeltGoldCost;
        hammerfells -= 1;
        goldIngot += 1;
        ShelfManager().removeItem('gold_ore', smeltGoldCost);
        ShelfManager().addItem('gold_ingot');
        _saveGame();
      });
    }
  }

  void resetGame() {
    setState(() {
      hammerfells = 0;
      ironOre = 0;
      copperOre = 0;
      goldOre = 0;
      diamond = 0;
      ironIngot = 0;
      copperIngot = 0;
      goldIngot = 0;
      ShelfManager().clear();
      CoinManager().setCoins(0, 0, 0);
      _saveGame();
    });
  }

  Widget coinIcon(String asset) => Image.asset(asset, width: 20, height: 20);

  Widget _buildCoinRow() {
    return Consumer<CoinManager>(
      builder: (context, coinManager, child) {
        return Row(
          children: [
            coinIcon('assets/images/copper_coin.png'),
            const SizedBox(width: 4),
            Text('${coinManager.copperCoins}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 12),
            coinIcon('assets/images/silver_coin.png'),
            const SizedBox(width: 4),
            Text('${coinManager.silverCoins}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 12),
            coinIcon('assets/images/gold_coin.png'),
            const SizedBox(width: 4),
            Text('${coinManager.goldCoins}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.swap_horiz, size: 20),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => ChangeNotifierProvider.value(
                    value: CoinManager(),
                    child: const CoinConverterDialog(),
                  ),
                );
              },
              tooltip: 'Convert Coins',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        );
      },
    );
  }

  Widget oreRow(String id, String label, int count, int cost, Color color, String assetPath) {
    final scale = _rowScale[id] ?? 1.0;
    final overlayColor = _rowOverlayColor[id];
    
    return Transform.scale(
      scale: scale,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: overlayColor ?? color,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Image.asset(assetPath, width: 20, height: 20),
              const SizedBox(width: 10),
              Text('$label: $count', style: TextStyle(color: readableTextColor(color), fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }


  void addHammerfellsAmount(int amount) {
    setState(() {
      hammerfells += amount;
      _saveGame();
    });
  }

  void _showAddHammerfellsPopup() {
    // Try to position the popup near the hammer button; fall back to centered dialog
    final targetContext = _hammerButtonKey.currentContext;
    if (targetContext == null) {
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Add Hammerfells'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(onPressed: () => addHammerfellsAmount(1), child: const Text('+1')),
              ElevatedButton(onPressed: () => addHammerfellsAmount(10), child: const Text('+10')),
              ElevatedButton(onPressed: () => addHammerfellsAmount(100), child: const Text('+100')),
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('Close'))],
        ),
      );
      return;
    }

    final RenderBox rb = targetContext.findRenderObject() as RenderBox;
    if (!rb.hasSize) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showAddHammerfellsPopup());
      return;
    }
    final Offset pos = rb.localToGlobal(Offset.zero);
    final Size size = rb.size;
    final screen = MediaQuery.of(context).size;
    const double popupWidth = 220.0;
    double left = pos.dx;
    double top = pos.dy + size.height + 8;
    if (left + popupWidth > screen.width) left = screen.width - popupWidth - 8;
    if (left < 8) left = 8;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Add Hammerfells',
      pageBuilder: (dialogContext, anim1, anim2) {
        return Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: popupWidth,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Add Hammerfells', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(onPressed: () => addHammerfellsAmount(1), child: const Text('+1')),
                          ElevatedButton(onPressed: () => addHammerfellsAmount(10), child: const Text('+10')),
                          ElevatedButton(onPressed: () => addHammerfellsAmount(100), child: const Text('+100')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Close'))),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openFurnace() {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (c) => Padding(
        padding: const EdgeInsets.all(16),
        child: FurnaceWidget(
          furnaceState: _homeFurnaceState!,
          onStateChanged: () {
            setState(() {});
            _homeFurnaceState?.save(_homeFurnaceKey);
          },
        ),
      ),
    );
  }

  void _openShop() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: CoinManager(),
          child: const ShopPage(),
        ),
      ),
    );
    setState(() {}); // Refresh state after returning
    _saveGame(); // Save coins after shop visit
  }





  // Helper to add ore to backpack
  void addToBackpack(String oreType) {
    BackpackManager().addItem(oreType);
    setState(() {
      // Also update main counters for coal and stone
      if (oreType == 'coal') coal++;
      if (oreType == 'stone') stone++;
    });
  }



  @override
  Widget build(BuildContext context) {
    // Card colors for ores/ingots

    return Scaffold(
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text('Hammerfell', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyMedium?.color)),
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    ListTile(title: const Text('Hammerfells'), trailing: Text('$hammerfells')),
                    const Divider(),
                    ListTile(title: const Text('Iron Ore'), trailing: Text('$ironOre')),
                    ListTile(title: const Text('Copper Ore'), trailing: Text('$copperOre')),
                    ListTile(title: const Text('Gold Ore'), trailing: Text('$goldOre')),
                    ListTile(title: const Text('Diamond'), trailing: Text('$diamond')),
                    const Divider(),
                    ListTile(title: const Text('Iron Ingot'), trailing: Text('$ironIngot')),
                    ListTile(title: const Text('Copper Ingot'), trailing: Text('$copperIngot')),
                    ListTile(title: const Text('Gold Ingot'), trailing: Text('$goldIngot')),
                    if (kDebugMode) ...[
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.refresh),
                        title: const Text('Reset (debug)'),
                        onTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: const Text('Reset all values?'),
                              content: const Text('This will set ores, ingots and Hammerfells to 0.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Cancel')),
                                TextButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('Reset')),
                              ],
                            ),
                          );
                          if (confirm == true) resetGame();
                          Navigator.of(context).pop();
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.bug_report),
                        title: const Text('Reset (debug-10)'),
                        onTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: const Text('Set all values to 10?'),
                              content: const Text('This will set ores, ingots, coins, and backpack to 10 for debugging.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Cancel')),
                                TextButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('Set to 10')),
                              ],
                            ),
                          );
                          if (confirm == true) resetDebug10();
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      appBar: null,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/home_bg.png'),
            fit: BoxFit.fill,
          ),
        ),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
                children: [
                  // Top: Hammerfells and coins row
                  Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 90),
                        child: ElevatedButton(
                          key: _hammerButtonKey,
                          onPressed: _showAddHammerfellsPopup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          ),
                          child: Text('$hammerfells', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text('Hammerfells', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                    ],
                  ),
                  // Coins (right)
                  Consumer<CoinManager>(
                    builder: (context, coinManager, child) {
                      return Row(
                        children: [
                          coinIcon('assets/images/copper_coin.png'),
                          const SizedBox(width: 4),
                          Text('${coinManager.copperCoins}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 12),
                          coinIcon('assets/images/silver_coin.png'),
                          const SizedBox(width: 4),
                          Text('${coinManager.silverCoins}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 12),
                          coinIcon('assets/images/gold_coin.png'),
                          const SizedBox(width: 4),
                          Text('${coinManager.goldCoins}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      );
                    },
                  ),
                ],
              ),
              // Main content: Shelves for ores and ingots
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left Shelf: Ores (5 rows x 1 column)
                    ShelfGrid(
                      shelfId: 'left',
                      slots: ShelfManager().leftShelf,
                      onMoveItem: (fromIndex, toIndex, {fromExternal = false, String? fromShelf}) {
                        if (fromExternal) {
                          // Handle items from backpack
                          _handleBackpackToShelf(fromIndex, toIndex, true);
                        } else if (fromShelf != null && fromShelf != 'left') {
                          // Handle cross-shelf transfer (right to left)
                          _handleCrossShelfTransfer(fromIndex, toIndex, fromShelf: fromShelf, toLeft: true);
                        } else {
                          // Internal move within left shelf
                          ShelfManager().moveItem(true, fromIndex, toIndex);
                        }
                        setState(() {});
                      },
                      onSave: () {
                        ShelfManager().save();
                        setState(() {});
                      },
                      rows: 5,
                      columns: 1,
                      slotSize: 64,
                      spacing: 8,
                      acceptExternalItems: true,
                    ),
                    // Center: Modal area (just a placeholder now)
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            '', // Placeholder for modal content
                            style: TextStyle(color: Colors.white.withOpacity(0.5)),
                          ),
                        ),
                      ),
                    ),
                    // Right Shelf: Ingots (5 rows x 1 column)
                    ShelfGrid(
                      shelfId: 'right',
                      slots: ShelfManager().rightShelf,
                      onMoveItem: (fromIndex, toIndex, {fromExternal = false, String? fromShelf}) {
                        if (fromExternal) {
                          // Handle items from backpack
                          _handleBackpackToShelf(fromIndex, toIndex, false);
                        } else if (fromShelf != null && fromShelf != 'right') {
                          // Handle cross-shelf transfer (left to right)
                          _handleCrossShelfTransfer(fromIndex, toIndex, fromShelf: fromShelf, toLeft: false);
                        } else {
                          // Internal move within right shelf
                          ShelfManager().moveItem(false, fromIndex, toIndex);
                        }
                        setState(() {});
                      },
                      onSave: () {
                        ShelfManager().save();
                        setState(() {});
                      },
                      rows: 5,
                      columns: 1,
                      slotSize: 64,
                      spacing: 8,
                      acceptExternalItems: true,
                    ),
                  ],
                ),
              ),

              // Backpack grid (drag-and-drop enabled)
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Backpack', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Consumer<BackpackManager>(
                      builder: (context, backpackManager, child) {
                        return Center(
                          child: InventoryGridWithSplitting(
                            slots: backpackManager.backpack,
                            onMoveItem: (from, to) => backpackManager.moveItem(from, to),
                            onSplitStack: (index) => backpackManager.splitStack(index),
                            onSave: () => backpackManager.save(),
                            onExternalDrop: (data, toIndex) => _handleShelfToBackpack(data, toIndex),
                            columns: 5,
                            rows: 1,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Bottom: action buttons always at bottom, prevent overflow
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        SizedBox(
                          width: 56,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              // TODO: Implement Craft modal
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Image.asset('assets/images/craft_button.png', fit: BoxFit.contain),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _openChestModal,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Image.asset('assets/images/chest_close_button.png', fit: BoxFit.contain),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 56,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _openFurnace,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Image.asset(
                              (_homeFurnaceState?.fuelSecondsRemaining ?? 0) > 0
                                ? 'assets/images/furnace_on_button.png'
                                : 'assets/images/furnace_off_button.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        SizedBox(
                          width: 56,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () async {
                              // Always update state after returning from MinePage
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MinePage(
                                    hammerfells: hammerfells,
                                    miningChances: {
                                      'iron_ore': ironMineChance,
                                      'copper_ore': copperMineChance,
                                      'gold_ore': goldMineChance,
                                      'diamond': diamondMineChance,
                                    },
                                    onMine: (ore) async {
                                      return await mineOre(ore);
                                    },
                                    mineOreChances: mineOreChances,
                                    pickOreForMine: (mineType) => pickOreForMine(mineOreChances, _rng, mineType),
                                  ),
                                ),
                              );
                              setState(() {}); // Refresh state after returning
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Image.asset('assets/images/mine_button.png', fit: BoxFit.contain),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 56,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _openShop,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Image.asset('assets/images/shop_button.png', fit: BoxFit.contain),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 56,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ForestPage()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Image.asset('assets/images/forest_button.png', fit: BoxFit.contain),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


