import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/foundation.dart';
import 'config/app_config.dart';

void main() {
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

  void _pulseRow(String id, bool success) {
    setState(() {
      _rowScale[id] = 1.06;
      _rowOverlayColor[id] = success ? Colors.green.withOpacity(0.18) : Colors.red.withOpacity(0.18);
    });

    Future.delayed(const Duration(milliseconds: 320), () {
      setState(() {
        _rowScale[id] = 1.0;
        _rowOverlayColor[id] = null;
      });
    });
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
    try {
      final cfg = await AppConfig.loadFromAssets();
      setState(() {
        ironMineCost = cfg.miningCost('iron', fallback: ironMineCost);
        copperMineCost = cfg.miningCost('copper', fallback: copperMineCost);
        goldMineCost = cfg.miningCost('gold', fallback: goldMineCost);
        diamondMineCost = cfg.miningCost('diamond', fallback: diamondMineCost);

        smeltIronCost = cfg.smeltingCost('iron', fallback: smeltIronCost);
        smeltCopperCost = cfg.smeltingCost('copper', fallback: smeltCopperCost);
        smeltGoldCost = cfg.smeltingCost('gold', fallback: smeltGoldCost);

        // Load chance values for mining
        ironMineChance = cfg.miningChance('iron', fallback: ironMineChance);
        copperMineChance = cfg.miningChance('copper', fallback: copperMineChance);
        goldMineChance = cfg.miningChance('gold', fallback: goldMineChance);
        diamondMineChance = cfg.miningChance('diamond', fallback: diamondMineChance);
      });
    } catch (e) {
      // If something goes wrong reading the config, keep defaults
    }
  }

  // Mining functions
  void mineIronOre() {
    if (hammerfells >= 1) {
      final success = _rng.nextDouble() < ironMineChance;
      setState(() {
        hammerfells -= 1;
        if (success) {
          ironOre += 1;
        }
        _saveGame();
      });
      _showResultSnackBar(success, success ? 'Mined Iron Ore!' : 'Failed to mine Iron Ore.');
    }
  }

  void mineCopperOre() {
    if (hammerfells >= 1) {
      final success = _rng.nextDouble() < copperMineChance;
      setState(() {
        hammerfells -= 1;
        if (success) {
          copperOre += 1;
        }
        _saveGame();
      });
      _showResultSnackBar(success, success ? 'Mined Copper Ore!' : 'Failed to mine Copper Ore.');
    }
  }

  void mineGoldOre() {
    if (hammerfells >= 1) {
      final success = _rng.nextDouble() < goldMineChance;
      setState(() {
        hammerfells -= 1;
        if (success) {
          goldOre += 1;
        }
        _saveGame();
      });
      _showResultSnackBar(success, success ? 'Mined Gold Ore!' : 'Failed to mine Gold Ore.');
    }
  }

  void mineDiamond() {
    if (hammerfells >= 1) {
      final success = _rng.nextDouble() < diamondMineChance;
      setState(() {
        hammerfells -= 1;
        if (success) {
          diamond += 1;
        }
        _saveGame();
      });
      _showResultSnackBar(success, success ? 'Mined Diamond!' : 'Failed to mine Diamond.');
    }
  }

  // Smelting functions (1 H each)
  void smeltIron() {
    if (hammerfells >= smeltIronCost && ironOre >= 1) {
      setState(() {
        hammerfells -= smeltIronCost;
        ironOre -= 1;
        ironIngot += 1;
        _saveGame();
      });
    }
  }

  void smeltCopper() {
    if (hammerfells >= smeltCopperCost && copperOre >= 1) {
      setState(() {
        hammerfells -= smeltCopperCost;
        copperOre -= 1;
        copperIngot += 1;
        _saveGame();
      });
    }
  }

  void smeltGold() {
    if (hammerfells >= smeltGoldCost && goldOre >= 1) {
      setState(() {
        hammerfells -= smeltGoldCost;
        goldOre -= 1;
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
    // If the RenderBox hasn't been laid out yet, retry after the current frame so localToGlobal works
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
        onMine: (ore) {
          if (ore == 'iron') mineIronOre();
          else if (ore == 'copper') mineCopperOre();
          else if (ore == 'gold') mineGoldOre();
          else if (ore == 'diamond') mineDiamond();
        },
      ),
    );
  }

  void _openForest() {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (c) => const ForestModal(),
    );
  }

  Color _darken(Color c, [double amount = 0.2]) { 
    final hsl = HSLColor.fromColor(c);
    final l = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(l).toColor();
  }

  Color _readableTextColor(Color bg) {
    return bg.computeLuminance() > 0.55 ? Colors.black : Colors.white;
  }

  Widget oreRow(String id, String oreName, int oreAmount, int cost, Color bgColor, String svgAsset) {
    final textColor = _readableTextColor(bgColor);
    final scale = _rowScale[id] ?? 1.0;
    final overlay = _rowOverlayColor[id];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left: icon and name/amount
                  Row(
                    children: [
                      SvgPicture.asset(svgAsset, width: 20, height: 20, colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn)),
                      const SizedBox(width: 10),
                      Text('$oreName: $oreAmount', style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  // Right: H cost only
                  Text(
                    '$cost H',
                    style: TextStyle(color: textColor.withOpacity(0.85), fontSize: 12),
                  ),
                ],
              ),
            ),
            // Colored overlay for success/failure pulse
            if (overlay != null)
              Positioned.fill(
                child: AnimatedOpacity(
                  opacity: overlay != null ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 220),
                  child: Container(
                    decoration: BoxDecoration(
                      color: overlay,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget smeltRow(String ingotName, int ingotAmount, String oreName, int availableOre, VoidCallback onSmelt, Color bgColor, IconData icon) {
    final canSmelt = hammerfells >= 1 && availableOre >= 1;
    final textColor = _readableTextColor(bgColor);
    final buttonColor = _darken(bgColor, 0.25);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Ingot: icon and count on the left
            Row(
              children: [
                Icon(icon, size: 20, color: textColor),
                const SizedBox(width: 10),
                Text('$ingotName: $ingotAmount', style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
              ],
            ),
            // Button and combined requirement on the right
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: textColor,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  onPressed: canSmelt ? onSmelt : null,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_fire_department, size: 18, color: textColor),
                      const SizedBox(width: 8),
                      Text('Furnace', style: TextStyle(color: textColor)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '1 $oreName, 1 H',
                  style: TextStyle(color: canSmelt ? textColor.withOpacity(0.85) : Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Card colors for ores/ingots
    final Color ironColor = Colors.grey.shade800;
    final Color copperColor = const Color(0xFFB87333);
    final Color goldColor = Colors.amber.shade700;
    final Color diamondColor = const Color(0xFF81D4FA);
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
      appBar: AppBar(title: const Text('Ore Miner Deluxe')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top: Hammerfells + quick-add button
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Hammerfells: $hammerfells',
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 56),
                  child: ElevatedButton(
                    key: _hammerButtonKey,
                    onPressed: _showAddHammerfellsPopup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    child: const Text('H'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Main content: ores and ingots
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  oreRow('iron', 'Iron Ore', ironOre, 2, ironColor, 'assets/images/iron_ore.svg'),
                  oreRow('copper', 'Copper Ore', copperOre, 1, copperColor, 'assets/images/copper_ore.svg'),
                  oreRow('gold', 'Gold Ore', goldOre, 5, goldColor, 'assets/images/gold_ore.svg'),
                  oreRow('diamond', 'Diamond', diamond, 10, diamondColor, 'assets/images/diamond.svg'),
                  const SizedBox(height: 20),

                  // Display ingots (counts only); smelting is done via the single Furnace button below
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: ironColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          SvgPicture.asset('assets/images/iron_ingot.svg', width: 20, height: 20, colorFilter: ColorFilter.mode(_readableTextColor(ironColor), BlendMode.srcIn)),
                          const SizedBox(width: 10),
                          Text('Iron Ingot: $ironIngot', style: TextStyle(color: _readableTextColor(ironColor), fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: copperColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          SvgPicture.asset('assets/images/copper_ingot.svg', width: 20, height: 20, colorFilter: ColorFilter.mode(_readableTextColor(copperColor), BlendMode.srcIn)),
                          const SizedBox(width: 10),
                          Text('Copper Ingot: $copperIngot', style: TextStyle(color: _readableTextColor(copperColor), fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: goldColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          SvgPicture.asset('assets/images/gold_ingot.svg', width: 20, height: 20, colorFilter: ColorFilter.mode(_readableTextColor(goldColor), BlendMode.srcIn)),
                          const SizedBox(width: 10),
                          Text('Gold Ingot: $goldIngot', style: TextStyle(color: _readableTextColor(goldColor), fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom: action buttons
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _openMine(),
                    icon: const Icon(Icons.construction),
                    label: const Text('Mine'),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _openFurnace(),
                    icon: SvgPicture.asset('assets/images/furnace.svg', width: 18, height: 18),
                    label: const Text('Furnace'),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _openForest(),
                    icon: const Icon(Icons.park),
                    label: const Text('Forest'),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class FurnaceModal extends StatefulWidget {
  final int hammerfells;
  final int ironOre;
  final int copperOre;
  final int goldOre;
  final void Function(String) onSmelt;

  const FurnaceModal({
    super.key,
    required this.hammerfells,
    required this.ironOre,
    required this.copperOre,
    required this.goldOre,
    required this.onSmelt,
  });

  @override
  State<FurnaceModal> createState() => _FurnaceModalState();
}

class _FurnaceModalState extends State<FurnaceModal> with SingleTickerProviderStateMixin {
  bool _isSmelting = false;
  String? _selectedOre;
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && _selectedOre != null) {
          widget.onSmelt(_selectedOre!);
          // Keep the modal open to allow multiple smelts; reset smelting state so another smelt can start
          setState(() {
            _isSmelting = false;
            _selectedOre = null;
          });
          _controller.reset();
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startSmelt(String key) {
    if (_isSmelting) return;
    setState(() {
      _isSmelting = true;
      _selectedOre = key;
      _controller.reset();
      _controller.forward();
    });
  }

  Widget _oreTile(String label, int available, String key, String svgAsset) {
    final canSmelt = widget.hammerfells >= 1 && available >= 1;
    final isThis = _isSmelting && _selectedOre == key;

    return ListTile(
      leading: SvgPicture.asset(svgAsset, width: 28, height: 28, colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.onSurface, BlendMode.srcIn)),
      title: Text(label),
      subtitle: Text('Available: $available'),
      trailing: canSmelt
          ? SizedBox(
              width: 160,
              height: 44,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final remaining = _controller.isAnimating ? (3 - (_controller.value * 3).floor()) : 3;
                  return GestureDetector(
                    onTap: _isSmelting ? null : () => _startSmelt(key),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        color: Theme.of(context).colorScheme.surface,
                        child: Stack(
                          children: [
                            FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: isThis ? _controller.value : 0,
                              child: Container(color: Colors.green.withOpacity(0.75)),
                            ),
                            Center(
                              child: Text(
                                _isSmelting ? (isThis ? 'Smelting ${remaining}s' : 'Busy') : 'Smelt',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
          : const Text('Unavailable', style: TextStyle(color: Colors.grey)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !_isSmelting,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Furnace', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(
                    onPressed: _isSmelting ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Builder(builder: (context) {
                final canSmeltAny = widget.hammerfells >= 1 && (widget.ironOre >= 1 || widget.copperOre >= 1 || widget.goldOre >= 1);
                if (!canSmeltAny) {
                  return Column(
                    children: [
                      const SizedBox(height: 12),
                      const Text('No ores available to smelt.', style: TextStyle(fontSize: 14)),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _isSmelting ? null : () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                }
                return Column(
                  children: [
                    _oreTile('Iron Ore', widget.ironOre, 'iron', 'assets/images/iron_ore.svg'),
                    _oreTile('Copper Ore', widget.copperOre, 'copper', 'assets/images/copper_ore.svg'),
                    _oreTile('Gold Ore', widget.goldOre, 'gold', 'assets/images/gold_ore.svg'),
                    const SizedBox(height: 12),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class MineModal extends StatelessWidget {
  final int hammerfells;
  final Map<String, double>? miningChances;
  final void Function(String) onMine;

  const MineModal({
    super.key,
    required this.hammerfells,
    required this.onMine,
    this.miningChances,
  });

  Widget _mineTile(BuildContext context, String label, int cost, String key, String svgAsset) {
    final canMine = hammerfells >= 1;
    final chance = miningChances != null ? (miningChances![key] ?? 1.0) : 1.0;
    final chancePct = (chance * 100).toStringAsFixed(0);
    return ListTile(
      leading: SvgPicture.asset(svgAsset, width: 28, height: 28, colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.onSurface, BlendMode.srcIn)),
      title: Text(label),
      subtitle: Text('1 H • $chancePct% chance'),
      trailing: canMine
          ? ElevatedButton(
              onPressed: () {
                onMine(key);
              },
              child: const Text('Mine'),
            )
          : const Text('Unavailable', style: TextStyle(color: Colors.grey)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canMineAny = hammerfells >= 1; // at least copper cost
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Mine', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 8),
            if (!canMineAny) ...[
              const SizedBox(height: 12),
              const Text('Not enough Hammerfells to mine.', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
              const SizedBox(height: 12),
            ] else ...[
              _mineTile(context, 'Iron Ore', 2, 'iron', 'assets/images/iron_ore.svg'),
              _mineTile(context, 'Copper Ore', 1, 'copper', 'assets/images/copper_ore.svg'),
              _mineTile(context, 'Gold Ore', 5, 'gold', 'assets/images/gold_ore.svg'),
              _mineTile(context, 'Diamond', 10, 'diamond', 'assets/images/diamond.svg'),
              const SizedBox(height: 12),
            ]
          ],
        ),
      ),
    );
  }
}

class ForestModal extends StatelessWidget {
  const ForestModal({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Forest', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 8),
            // Placeholder: leave empty for now
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

