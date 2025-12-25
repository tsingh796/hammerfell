import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/foundation.dart';
import 'utils/backpack_manager.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';
import 'modals/furnace_modal.dart';
import 'modals/mine_modal.dart';
import 'utils/color_utils.dart';
// import 'modals/forest_modal.dart';
import 'pages/mine_page.dart';
import 'pages/forest_page.dart';

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
  runApp(const OreMinerApp());
}

class OreMinerApp extends StatelessWidget {
  const OreMinerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ore Miner Deluxe',
      theme: ThemeData.dark(),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Backpack inventory: Each slot is {'type': oreType, 'count': int}
  // Use global backpack singleton

  // Public ore asset helper for use in backpack grid
  static String oreAsset(String oreType) {
    switch (oreType) {
      case 'iron':
      case 'iron_ore':
        return 'assets/images/iron_ore.svg';
      case 'copper':
      case 'copper_ore':
        return 'assets/images/copper_ore.svg';
      case 'gold':
      case 'gold_ore':
        return 'assets/images/gold_ore.svg';
      case 'diamond':
        return 'assets/images/diamond.svg';
      case 'stone':
        return 'assets/images/stone.svg';
      case 'coal':
        return 'assets/images/coal.svg';
      default:
        return 'assets/images/unknown_ore.svg';
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
  int copperCoins = 0;
  int silverCoins = 0;
  int goldCoins = 0;
  
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

  @override
  void initState() {
    super.initState();
    _loadConfig();
    BackpackManager().load();
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        hammerfells = prefs.getInt('hammerfells') ?? 10;
        ironOre = prefs.getInt('ironOre') ?? 0;
        copperOre = prefs.getInt('copperOre') ?? 0;
        goldOre = prefs.getInt('goldOre') ?? 0;
        diamond = prefs.getInt('diamond') ?? 0;
        coal = prefs.getInt('coal') ?? 0;
        stone = prefs.getInt('stone') ?? 0;
        ironIngot = prefs.getInt('ironIngot') ?? 0;
        copperIngot = prefs.getInt('copperIngot') ?? 0;
        goldIngot = prefs.getInt('goldIngot') ?? 0;
        copperCoins = prefs.getInt('copperCoins') ?? 0;
        silverCoins = prefs.getInt('silverCoins') ?? 0;
        goldCoins = prefs.getInt('goldCoins') ?? 0;
      });
      // Load backpack
      final backpackStr = prefs.getString('backpack');
      if (backpackStr != null && backpackStr.isNotEmpty) {
        try {
          final decoded = jsonDecode(backpackStr) as List;
          for (int i = 0; i < BackpackManager().backpack.length && i < decoded.length; i++) {
            if (decoded[i] != null) {
              BackpackManager().backpack[i] = Map<String, dynamic>.from(decoded[i] as Map);
            } else {
              BackpackManager().backpack[i] = null;
            }
          }
        } catch (_) {
          for (int i = 0; i < BackpackManager().backpack.length; i++) {
            BackpackManager().backpack[i] = null;
          }
        }
      } else {
        for (int i = 0; i < BackpackManager().backpack.length; i++) {
          BackpackManager().backpack[i] = null;
        }
      }
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

  Future<void> _loadConfig() async {
    try {
      final String yamlString = await rootBundle.loadString('assets/config/game_config.yaml');
      final dynamic yamlData = loadYaml(yamlString);
      if (yamlData != null && yamlData['mines'] != null) {
        final Map<dynamic, dynamic> chances = yamlData['mines'] as Map<dynamic, dynamic>;
        mineOreChances = chances.map((key, value) {
          final Map<String, double> oreMap = {};
          if (value is Map) {
            value.forEach((oreKey, oreValue) {
              oreMap[oreKey.toString()] = (oreValue as num).toDouble();
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
    await prefs.setInt('copperCoins', copperCoins);
    await prefs.setInt('silverCoins', silverCoins);
    await prefs.setInt('goldCoins', goldCoins);
    // Save backpack as JSON string
    final encoded = BackpackManager().backpack.map((slot) => slot == null ? null : Map<String, dynamic>.from(slot)).toList();
    await prefs.setString('backpack', jsonEncode(encoded));
    // Save last entered mine if any
    if (hasEnteredMine && currentMine != null) {
      await prefs.setString('lastMine', jsonEncode(currentMine!.toJson()));
    }
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

  Future<bool> mineIronOre() async {
    if (hammerfells >= miningCost) {
      final success = _rng.nextDouble() < ironMineChance;
      setState(() {
        hammerfells -= miningCost;
        if (success) ironOre += 1;
        _saveGame();
      });
      return success;
    }
    return false;
  }

  Future<bool> mineCopperOre() async {
    if (hammerfells >= miningCost) {
      final success = _rng.nextDouble() < copperMineChance;
      setState(() {
        hammerfells -= miningCost;
        if (success) copperOre += 1;
        _saveGame();
      });
      return success;
    }
    return false;
  }

  Future<bool> mineGoldOre() async {
    if (hammerfells >= miningCost) {
      final success = _rng.nextDouble() < goldMineChance;
      setState(() {
        hammerfells -= miningCost;
        if (success) goldOre += 1;
        _saveGame();
      });
      return success;
    }
    return false;
  }

  Future<bool> mineDiamond() async {
    if (hammerfells >= miningCost) {
      final success = _rng.nextDouble() < diamondMineChance;
      setState(() {
        hammerfells -= miningCost;
        if (success) diamond += 1;
        _saveGame();
      });
      return success;
    }
    return false;
  }

  void smeltIron() {
    if (ironOre >= smeltIronCost && hammerfells >= 1) {
      setState(() {
        ironOre -= smeltIronCost;
        hammerfells -= 1;
        ironIngot += 1;
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
      copperCoins = 0;
      silverCoins = 0;
      goldCoins = 0;
      _saveGame();
    });
  }

  Widget coinIcon(String asset) => SvgPicture.asset(asset, width: 20, height: 20);

  Widget _buildCoinRow() {
    return Row(
      children: [
        coinIcon('assets/images/copper_coin.svg'),
        const SizedBox(width: 4),
        Text('$copperCoins', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 12),
        coinIcon('assets/images/silver_coin.svg'),
        const SizedBox(width: 4),
        Text('$silverCoins', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 12),
        coinIcon('assets/images/gold_coin.svg'),
        const SizedBox(width: 4),
        Text('$goldCoins', style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
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
              SvgPicture.asset(assetPath, width: 20, height: 20),
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
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (c) => FurnaceModal(
        hammerfells: hammerfells,
        ironOre: ironOre,
        copperOre: copperOre,
        goldOre: goldOre,
        onSmelt: (ore) {
          if (ore == 'iron') {
            smeltIron();
          } else if (ore == 'copper') smeltCopper();
          else if (ore == 'gold') smeltGold();
        },
        onClose: () => Navigator.of(c).pop(),
      ),
    );
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
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      appBar: null,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
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
                  Row(
                    children: [
                      coinIcon('assets/images/copper_coin.svg'),
                      const SizedBox(width: 4),
                      Text('$copperCoins', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      coinIcon('assets/images/silver_coin.svg'),
                      const SizedBox(width: 4),
                      Text('$silverCoins', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      coinIcon('assets/images/gold_coin.svg'),
                      const SizedBox(width: 4),
                      Text('$goldCoins', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              // Main content: Minecraft-style grids for ores and ingots
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left: Ores grid (5 rows x 1 column)
                    SizedBox(
                      width: 72,
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 1,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 0,
                          childAspectRatio: 1,
                        ),
                        itemCount: 5,
                        itemBuilder: (context, index) {
                          // Order: iron, copper, gold, diamond, (empty)
                          final ores = [
                            {'name': 'Iron Ore', 'count': ironOre, 'asset': 'assets/images/iron_ore.svg'},
                            {'name': 'Copper Ore', 'count': copperOre, 'asset': 'assets/images/copper_ore.svg'},
                            {'name': 'Gold Ore', 'count': goldOre, 'asset': 'assets/images/gold_ore.svg'},
                            {'name': 'Diamond', 'count': diamond, 'asset': 'assets/images/diamond.svg'},
                          ];
                          if (index < ores.length) {
                            final ore = ores[index];
                            return Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey, width: 2),
                                color: Colors.black.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SvgPicture.asset(ore['asset'] as String, width: 32, height: 32),
                                  const SizedBox(height: 4),
                                  Text('${ore['count']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            );
                          } else {
                            return Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey, width: 2),
                                color: Colors.black.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            );
                          }
                        },
                      ),
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
                    // Right: Ingots grid (5 rows x 1 column)
                    SizedBox(
                      width: 72,
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 1,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 0,
                          childAspectRatio: 1,
                        ),
                        itemCount: 5,
                        itemBuilder: (context, index) {
                          // Order: iron, copper, gold, (empty, empty)
                          final ingots = [
                            {'name': 'Iron Ingot', 'count': ironIngot, 'asset': 'assets/images/iron_ingot.svg'},
                            {'name': 'Copper Ingot', 'count': copperIngot, 'asset': 'assets/images/copper_ingot.svg'},
                            {'name': 'Gold Ingot', 'count': goldIngot, 'asset': 'assets/images/gold_ingot.svg'},
                          ];
                          if (index < ingots.length) {
                            final ingot = ingots[index];
                            return Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey, width: 2),
                                color: Colors.black.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SvgPicture.asset(ingot['asset'] as String, width: 32, height: 32),
                                  const SizedBox(height: 4),
                                  Text('${ingot['count']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            );
                          } else {
                            return Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey, width: 2),
                                color: Colors.black.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            );
                          }
                        },
                      ),
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
                    SizedBox(
                      height: 60,
                      child: ClipRect(
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
                            final slot = BackpackManager().backpack[index];
                            return DragTarget<Map<String, dynamic>>(
                              builder: (context, candidateData, rejectedData) {
                                return slot != null
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
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                SvgPicture.asset(_oreAsset(slot['type']), width: 20, height: 20),
                                                const SizedBox(width: 4),
                                                Text('${slot['count']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                                              ],
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
                                        onDragCompleted: () {},
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey, width: 2),
                                            color: Colors.black.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          alignment: Alignment.center,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SvgPicture.asset(_oreAsset(slot['type']), width: 20, height: 20),
                                              const SizedBox(width: 4),
                                              Text('${slot['count']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black)),
                                            ],
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
                              },
                              onWillAccept: (data) {
                                // Accept any item for any slot
                                return data != null;
                              },
                              onAccept: (data) {
                                setState(() {
                                  int from = data['from'] as int;
                                  int to = index;
                                  BackpackManager().moveItem(from, to);
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Bottom: action buttons always at bottom, prevent overflow
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            // Always update state after returning from MinePage
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MinePage(
                                  hammerfells: hammerfells,
                                  miningChances: {
                                    'iron': ironMineChance,
                                    'copper': copperMineChance,
                                    'gold': goldMineChance,
                                    'diamond': diamondMineChance,
                                  },
                                  onMine: (ore) async {
                                    bool success = false;
                                    if (ore == 'iron') {
                                      success = await mineIronOre();
                                    } else if (ore == 'copper') {
                                      success = await mineCopperOre();
                                    } else if (ore == 'gold') {
                                      success = await mineGoldOre();
                                    } else if (ore == 'diamond') {
                                      success = await mineDiamond();
                                    } else if (ore == 'stone') {
                                      if (hammerfells >= miningCost) {
                                        setState(() {
                                          hammerfells -= miningCost;
                                          stone++;
                                          _saveGame();
                                        });
                                        success = true;
                                      }
                                    } else if (ore == 'coal') {
                                      if (hammerfells >= miningCost) {
                                        setState(() {
                                          hammerfells -= miningCost;
                                          coal++;
                                          _saveGame();
                                        });
                                        success = true;
                                      }
                                    }
                                    _pulseRow(ore, success);
                                    return success;
                                  },
                                  onOpenFurnace: _openFurnace,
                                  mineOreChances: mineOreChances,
                                  pickOreForMine: (mineType) => pickOreForMine(mineOreChances, _rng, mineType),
                                ),
                              ),
                            );
                            setState(() {}); // Refresh state after returning
                          },
                          icon: const Icon(Icons.construction),
                          label: const Text('Mine'),
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _openFurnace,
                          icon: const Icon(Icons.local_fire_department),
                          label: const Text('Furnace'),
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ForestPage()),
                            );
                          },
                          icon: const Icon(Icons.park),
                          label: const Text('Forest'),
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


