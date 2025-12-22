import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'models/app_config.dart';
import 'modals/furnace_modal.dart';
import 'modals/mine_modal.dart';
// import 'modals/forest_modal.dart';
import 'widgets/ore_row.dart';
import 'widgets/smelt_row.dart';
import 'widgets/coin_icon.dart';
import 'utils/color_utils.dart';
import 'utils/animation_utils.dart';

// Which modal to show in the center column
String? _centerModal; // 'mine', 'furnace', or null

// State for showing ore/ingot names on tap
final Map<String, bool> _showOreName = {
  'iron': false,
  'copper': false,
  'gold': false,
  'diamond': false,
};
final Map<String, bool> _showIngotName = {
  'iron': false,
  'copper': false,
  'gold': false,
};

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
  int hammerfells = 10;
  int copperCoins = 0;
  int silverCoins = 0;
  int goldCoins = 0;

  // Ores
  int ironOre = 0;
  int copperOre = 0;
  int goldOre = 0;
  int diamond = 0;

  // Ingots
  int ironIngot = 0;
  int copperIngot = 0;
  int goldIngot = 0;

  // Configurable costs (defaults match previous hard-coded values)
  int ironMineCost = 2;
  int copperMineCost = 1;
  int goldMineCost = 5;
  int diamondMineCost = 10;

  int smeltIronCost = 1;
  int smeltCopperCost = 1;
  int smeltGoldCost = 1;

  // Mining chances (0.0 - 1.0), defaults to always succeed
  double ironMineChance = 1.0;
  double copperMineChance = 1.0;
  double goldMineChance = 1.0;
  double diamondMineChance = 1.0;

  final Random _rng = Random();

  // Key for Hammerfells button to anchor popup
  final GlobalKey _hammerButtonKey = GlobalKey();

  // Row animation state (for success/failure pulse)
  final Map<String, double> _rowScale = {
    'iron': 1.0,
    'copper': 1.0,
    'gold': 1.0,
    'diamond': 1.0,
  };
  final Map<String, Color?> _rowOverlayColor = {
    'iron': null,
    'copper': null,
    'gold': null,
    'diamond': null,
  };

  Future<void> _pulseRow(String id, bool success) async {
    await pulseRow(id, success, setState, _rowScale, _rowOverlayColor);
  }


  @override
  void initState() {
    super.initState();
    _loadGame();
    _loadConfig();
  }

  Future<void> _loadGame() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      hammerfells = prefs.getInt('hammerfells') ?? 10;
      ironOre = prefs.getInt('ironOre') ?? 0;
      copperOre = prefs.getInt('copperOre') ?? 0;
      goldOre = prefs.getInt('goldOre') ?? 0;
      diamond = prefs.getInt('diamond') ?? 0;
      ironIngot = prefs.getInt('ironIngot') ?? 0;
      copperIngot = prefs.getInt('copperIngot') ?? 0;
      goldIngot = prefs.getInt('goldIngot') ?? 0;
    });
  }

  Future<void> _saveGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('hammerfells', hammerfells);
    await prefs.setInt('ironOre', ironOre);
    await prefs.setInt('copperOre', copperOre);
    await prefs.setInt('goldOre', goldOre);
    await prefs.setInt('diamond', diamond);
    await prefs.setInt('ironIngot', ironIngot);
    await prefs.setInt('copperIngot', copperIngot);
    await prefs.setInt('goldIngot', goldIngot);
  }

  Future<void> _loadConfig() async {
    // Load configuration if needed
  }

  Future<bool> mineIronOre() async {
    if (hammerfells >= ironMineCost) {
      final success = _rng.nextDouble() < ironMineChance;
      setState(() {
        hammerfells -= ironMineCost;
        if (success) ironOre += 1;
        _saveGame();
      });
      return success;
    }
    return false;
  }

  Future<bool> mineCopperOre() async {
    if (hammerfells >= copperMineCost) {
      final success = _rng.nextDouble() < copperMineChance;
      setState(() {
        hammerfells -= copperMineCost;
        if (success) copperOre += 1;
        _saveGame();
      });
      return success;
    }
    return false;
  }

  Future<bool> mineGoldOre() async {
    if (hammerfells >= goldMineCost) {
      final success = _rng.nextDouble() < goldMineChance;
      setState(() {
        hammerfells -= goldMineCost;
        if (success) goldOre += 1;
        _saveGame();
      });
      return success;
    }
    return false;
  }

  Future<bool> mineDiamond() async {
    if (hammerfells >= diamondMineCost) {
      final success = _rng.nextDouble() < diamondMineChance;
      setState(() {
        hammerfells -= diamondMineCost;
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

  void addHammerfellsAmount(int amount) {
    setState(() {
      hammerfells += amount;
      _saveGame();
    });
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
      _saveGame();
    });
  }

  Widget coinIcon(String asset) => SvgPicture.asset(asset, width: 20, height: 20);

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
              Text('$label: $count', style: TextStyle(color: _readableTextColor(color), fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Color _readableTextColor(Color background) {
    return readableTextColor(background);
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

  void _showResultSnackBar(bool success, String message) {
    final color = success ? Colors.green[700] : Colors.red[700];
    final icon = success ? Icons.check_circle : Icons.cancel;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 900),
      ),
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
          if (ore == 'iron') smeltIron();
          else if (ore == 'copper') smeltCopper();
          else if (ore == 'gold') smeltGold();
        },
      ),
    );
  }

  void _openMine() {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (c) => MineModal(
        hammerfells: hammerfells,
        miningChances: {
          'iron': ironMineChance,
          'copper': copperMineChance,
          'gold': goldMineChance,
          'diamond': diamondMineChance,
        },
        onMine: (ore) async {
          bool success = false;
          if (ore == 'iron') success = await mineIronOre();
          else if (ore == 'copper') success = await mineCopperOre();
          else if (ore == 'gold') success = await mineGoldOre();
          else if (ore == 'diamond') success = await mineDiamond();
          _pulseRow(ore, success);
          return success;
        },

      ),
    );
  }

  Widget _oreIconValue(String id, String name, int value, Color color, String asset) {
    return GestureDetector(
      onTap: () => setState(() => _showOreName[id] = !_showOreName[id]!),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(asset, width: 24, height: 24),
              const SizedBox(width: 8),
              Text('$value', style: TextStyle(color: readableTextColor(color), fontWeight: FontWeight.bold, fontSize: 16)),
              if (_showOreName[id]!) ...[
                const SizedBox(width: 8),
                Text(name, style: TextStyle(color: readableTextColor(color), fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _ingotIconValue(String id, String name, int value, Color color, String asset) {
    return GestureDetector(
      onTap: () => setState(() => _showIngotName[id] = !_showIngotName[id]!),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(asset, width: 24, height: 24),
              const SizedBox(width: 8),
              Text('$value', style: TextStyle(color: readableTextColor(color), fontWeight: FontWeight.bold, fontSize: 16)),
              if (_showIngotName[id]!) ...[
                const SizedBox(width: 8),
                Text(name, style: TextStyle(color: readableTextColor(color), fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Card colors for ores/ingots
    final Color ironColor = const Color(0xFFB0BEC5); // bluish gray
    final Color copperColor = const Color(0xFFB87333); // copper
    final Color goldColor = const Color(0xFFFFD700); // gold
    final Color diamondColor = const Color(0xFF81D4FA); // light blue
    final Color silverColor = const Color(0xFFC0C0C0); // silver
    Widget coinIcon(String asset) => SvgPicture.asset(asset, width: 20, height: 20);
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
              // Main content: 3 columns (ores | modal | ingots)
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left: Ores (icon + value, tap to show name)
                    SizedBox(
                      width: 56,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _oreIconValue('iron', 'Iron Ore', ironOre, ironColor, 'assets/images/iron_ore.svg'),
                          _oreIconValue('copper', 'Copper Ore', copperOre, copperColor, 'assets/images/copper_ore.svg'),
                          _oreIconValue('gold', 'Gold Ore', goldOre, goldColor, 'assets/images/gold_ore.svg'),
                          _oreIconValue('diamond', 'Diamond', diamond, diamondColor, 'assets/images/diamond.svg'),
                        ],
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
                    // Right: Ingots (icon + value, tap to show name)
                    SizedBox(
                      width: 56,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _ingotIconValue('iron', 'Iron Ingot', ironIngot, ironColor, 'assets/images/iron_ingot.svg'),
                          _ingotIconValue('copper', 'Copper Ingot', copperIngot, copperColor, 'assets/images/copper_ingot.svg'),
                          _ingotIconValue('gold', 'Gold Ingot', goldIngot, goldColor, 'assets/images/gold_ingot.svg'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Bottom: action buttons always at bottom
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            barrierDismissible: true,
                            builder: (context) => Center(
                              child: FractionallySizedBox(
                                widthFactor: 0.7,
                                heightFactor: 0.7,
                                child: Material(
                                  color: Theme.of(context).dialogBackgroundColor,
                                  borderRadius: BorderRadius.circular(16),
                                  clipBehavior: Clip.antiAlias,
                                  child: MineModal(
                                    hammerfells: hammerfells,
                                    miningChances: {
                                      'iron': ironMineChance,
                                      'copper': copperMineChance,
                                      'gold': goldMineChance,
                                      'diamond': diamondMineChance,
                                    },
                                    onMine: (ore) async {
                                      bool success = false;
                                      if (ore == 'iron') success = await mineIronOre();
                                      else if (ore == 'copper') success = await mineCopperOre();
                                      else if (ore == 'gold') success = await mineGoldOre();
                                      else if (ore == 'diamond') success = await mineDiamond();
                                      _pulseRow(ore, success);
                                      return success;
                                    },
                                    onClose: () => Navigator.of(context).pop(),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.construction),
                        label: const Text('Mine'),
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            barrierDismissible: true,
                            builder: (context) => Center(
                              child: FractionallySizedBox(
                                widthFactor: 0.7,
                                heightFactor: 0.7,
                                child: Material(
                                  color: Theme.of(context).dialogBackgroundColor,
                                  borderRadius: BorderRadius.circular(16),
                                  clipBehavior: Clip.antiAlias,
                                  child: FurnaceModal(
                                    hammerfells: hammerfells,
                                    ironOre: ironOre,
                                    copperOre: copperOre,
                                    goldOre: goldOre,
                                    onSmelt: (ore) {
                                      if (ore == 'iron') smeltIron();
                                      else if (ore == 'copper') smeltCopper();
                                      else if (ore == 'gold') smeltGold();
                                    },
                                    onClose: () => Navigator.of(context).pop(),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        icon: SvgPicture.asset('assets/images/furnace.svg', width: 18, height: 18),
                        label: const Text('Furnace'),
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            barrierDismissible: true,
                            builder: (context) => Center(
                              child: FractionallySizedBox(
                                widthFactor: 0.8,
                                heightFactor: 0.7,
                                child: Material(
                                  color: Theme.of(context).dialogBackgroundColor,
                                  borderRadius: BorderRadius.circular(16),
                                  clipBehavior: Clip.antiAlias,
                                  child: SafeArea(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text('Forest', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                              IconButton(
                                                onPressed: () => Navigator.of(context).pop(),
                                                icon: const Icon(Icons.close),
                                              ),
                                            ],
                                          ),
                                          const Expanded(
                                            child: Center(
                                              child: Text(''),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
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
            ],
          ),
        ),
      ),
    );
  }
}


