
import 'dart:async';
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../modals/mine_search_modal.dart';

import '../utils/random_utils.dart';
import '../utils/backpack_manager.dart';
import '../widgets/item_icon.dart';
import '../widgets/inventory_grid_with_splitting.dart';
import '../widgets/furnace_widget.dart';
import 'package:provider/provider.dart';

class Mine {
  final String oreType;
  
  Mine(this.oreType);
  
  Map<String, dynamic> toJson() => {'oreType': oreType};
}

// Custom clippers for trapezoid shapes
class TopTrapezoidClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0); // top-left (wider - ceiling receding)
    path.lineTo(size.width, 0); // top-right (wider)
    path.lineTo(180, size.height); // bottom-right (narrower - matches front block width)
    path.lineTo(60, size.height); // bottom-left (narrower - matches front block width)
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class BottomTrapezoidClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(60, 0); // top-left (narrower - matches front block width)
    path.lineTo(180, 0); // top-right (narrower - matches front block width)
    path.lineTo(size.width, size.height); // bottom-right (wider - floor receding)
    path.lineTo(0, size.height); // bottom-left (wider)
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class LeftTopTrapezoidClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    // Left side of top front block - 120px inner edge, wider outer edge
    path.moveTo(0, 0); // top-left (outer edge, wider)
    path.lineTo(size.width, 70); // top-right (inner edge - 120px matches front block)
    path.lineTo(size.width, size.height); // bottom-right (inner edge - 120px)
    path.lineTo(0, size.height); // bottom-left (outer edge, narrower - perspective)
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class RightTopTrapezoidClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    // Right side of top front block - 120px inner edge, wider outer edge
    path.moveTo(0, 70); // top-left (inner edge - 120px matches front block)
    path.lineTo(size.width, 0); // top-right (outer edge, wider)
    path.lineTo(size.width, size.height); // bottom-right (outer edge, narrower - perspective)
    path.lineTo(0, size.height); // bottom-left (inner edge - 120px)
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// Custom painter for trapezoid borders
class TrapezoidBorderPainter extends CustomPainter {
  final String position;
  final Color color;
  final double width;
  
  TrapezoidBorderPainter({
    required this.position,
    required this.color,
    required this.width,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    
    final path = Path();
    
    switch (position) {
      case 'top':
        path.moveTo(0, 0);
        path.lineTo(size.width, 0);
        path.lineTo(180, size.height);
        path.lineTo(60, size.height);
        path.close();
        break;
      case 'bottom':
        path.moveTo(60, 0);
        path.lineTo(180, 0);
        path.lineTo(size.width, size.height);
        path.lineTo(0, size.height);
        path.close();
        break;
      case 'leftTop':
        path.moveTo(0, 0);
        path.lineTo(size.width, 70);
        path.lineTo(size.width, size.height);
        path.lineTo(0, size.height);
        path.close();
        break;
      case 'rightTop':
        path.moveTo(0, 70);
        path.lineTo(size.width, 0);
        path.lineTo(size.width, size.height);
        path.lineTo(0, size.height);
        path.close();
        break;
      case 'leftBottom':
        path.moveTo(0, 0);
        path.lineTo(size.width, 0);
        path.lineTo(size.width, 120);
        path.lineTo(0, size.height);
        path.close();
        break;
      case 'rightBottom':
        path.moveTo(0, 0);
        path.lineTo(size.width, 0);
        path.lineTo(size.width, size.height);
        path.lineTo(0, 120);
        path.close();
        break;
    }
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LeftBottomTrapezoidClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    // Left side of bottom front block - 120px inner edge, wider outer edge
    path.moveTo(0, 0); // top-left (outer edge, narrower - perspective)
    path.lineTo(size.width, 0); // top-right (inner edge - 120px)
    path.lineTo(size.width, 120); // bottom-right (inner edge - 120px matches front block)
    path.lineTo(0, size.height); // bottom-left (outer edge, wider)
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class RightBottomTrapezoidClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    // Right side of bottom front block - 120px inner edge, wider outer edge
    path.moveTo(0, 0); // top-left (inner edge - 120px)
    path.lineTo(size.width, 0); // top-right (outer edge, narrower - perspective)
    path.lineTo(size.width, size.height); // bottom-right (outer edge, wider)
    path.lineTo(0, 120); // bottom-left (inner edge - 120px matches front block)
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}



class MinePage extends StatefulWidget {
  final int hammerfells;
  final Map<String, double> miningChances;
  final Future<bool> Function(String) onMine;
  final VoidCallback? onOpenFurnace;
  final Map<String, Map<String, double>> mineOreChances;
  final String Function(String) pickOreForMine;
  // Remove hasEnteredMine, initialMine, onEnterMine, onSearchNewMine from constructor
  const MinePage({
    Key? key,
    required this.hammerfells,
    required this.miningChances,
    required this.onMine,
    required this.mineOreChances,
    required this.pickOreForMine,
    this.onOpenFurnace,
  }) : super(key: key);

  @override
  State<MinePage> createState() => _MinePageState();
}

  class _MinePageState extends State<MinePage> {
    String? _nextOre1; // Next ore for button 1
    String? _nextOre2; // Next ore for button 2
    final Random _rng = Random();
    bool _hasEnteredMine = false;
    dynamic _currentMine;
    bool _mining = false;
    int? _miningButtonIndex; // Track which button (1 or 2) is currently mining
    bool _isPressed1 = false;
    bool _isPressed2 = false;
    int _crackStep = 0;
    bool _block1Mined = false; // Track if block 1 has been mined
    bool _block2Mined = false; // Track if block 2 has been mined
    String? _mineResult;
    final FurnaceState _furnaceState = FurnaceState();
    final String _furnaceKey = 'furnace_mine';
    late int _currentHammerfells; // Local tracking of hammerfells
    
    // Tunnel surrounding blocks (8 blocks around player)
    String _topBlock = 'stone';
    String _bottomBlock = 'stone';
    String _leftTopBlock = 'stone';
    String _rightTopBlock = 'stone';
    String _leftBottomBlock = 'stone';
    String _rightBottomBlock = 'stone';
    
    // Track if each surrounding block is being mined
    bool _miningSurrounding = false;
    int _surroundingCrackStep = 0;
    String? _surroundingBlockPosition;
    String? _pressedSurroundingBlock; // Track which surrounding block is pressed

    @override
    void initState() {
      super.initState();
      _currentHammerfells = widget.hammerfells;
      _restoreMineState();
      // If no mine was entered previously, default to coal mine
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_hasEnteredMine || _currentMine == null) {
          setState(() {
            _hasEnteredMine = true;
            _currentMine = Mine('coal');
            _nextOre1 = _pickNextOre();
            _nextOre2 = _pickNextOre();
            _generateSurroundingBlocks();
            _block1Mined = false;
            _block2Mined = false;
          });
        }
      });
      _furnaceState.load(_furnaceKey).then((_) {
        setState(() {});
      });
    }

    @override
    void didChangeDependencies() {
      super.didChangeDependencies();
      _restoreMineState();
    }

    Future<void> _restoreMineState() async {
      final prefs = await SharedPreferences.getInstance();
      final lastMine = prefs.getString('minepage_lastMine');
      if (lastMine != null && lastMine.isNotEmpty) {
        try {
          final decoded = jsonDecode(lastMine);
          setState(() {
            _hasEnteredMine = true;
            _currentMine = decoded is Map<String, dynamic> && decoded.containsKey('oreType')
                ? Mine(decoded['oreType'])
                : null;
          });
        } catch (_) {
          setState(() {
            _hasEnteredMine = false;
            _currentMine = null;
          });
        }
      } else {
        setState(() {
          _hasEnteredMine = false;
          _currentMine = null;
        });
      }
      await BackpackManager().load();
    }

    Future<void> _saveMineState() async {
      final prefs = await SharedPreferences.getInstance();
      // Save mine
      if (_hasEnteredMine && _currentMine != null) {
        await prefs.setString('minepage_lastMine', jsonEncode(_currentMine));
      } else {
        await prefs.remove('minepage_lastMine');
      }
      // Save global backpack
      await BackpackManager().save();
    }

    void _playErrorSound() async {
      final player = AudioPlayer();
      await player.play(AssetSource('sounds/mining_not_started.ogg'));
    }

    String _crackAsset(int step, String ore) {
      if (step == 1) {
        return 'assets/images/crack1.png';
      } else {
        return 'assets/images/crack2.png';
      }
    }

    String _getOreBlockAsset(String oreType) {
      switch (oreType) {
        case 'coal':
          return 'assets/images/coal_ore_block.png';
        case 'copper':
          return 'assets/images/copper_ore_block.png';
        case 'iron':
          return 'assets/images/iron_ore_block.png';
        case 'silver':
          return 'assets/images/silver_ore_block.png';
        case 'gold':
          return 'assets/images/gold_ore_block.png';
        case 'diamond':
          return 'assets/images/diamond_ore_block.png';
        case 'stone':
          return 'assets/images/stone_block.png';
        default:
          return 'assets/images/stone_block.png';
      }
    }

    String _getOreIconAsset(String oreType) {
      switch (oreType) {
        case 'coal':
          return 'assets/images/coal.png';
        case 'copper':
          return 'assets/images/copper_ore.png';
        case 'iron':
          return 'assets/images/iron_ore.png';
        case 'gold':
          return 'assets/images/gold_ore.png';
        case 'diamond':
          return 'assets/images/diamond.png';
        case 'stone':
          return 'assets/images/stone.png';
        default:
          return 'assets/images/stone.png';
      }
    }

    String _pickNextOre() {
      if (_currentMine == null) return 'stone';
      final oreType = _currentMine.oreType;
      final oreChances = widget.mineOreChances[oreType];
      if (oreChances == null || oreChances.isEmpty) return oreType;
      final oreNames = oreChances.keys.toList();
      final weights = oreNames.map((k) => oreChances[k] ?? 0.0).toList();
      return weightedRandomChoice(oreNames, weights, rng: _rng) ?? oreType;
    }

    void _generateSurroundingBlocks() {
      // 20% chance for ore in surrounding blocks, 80% stone
      _topBlock = _rng.nextDouble() < 0.2 ? _pickNextOre() : 'stone';
      _bottomBlock = _rng.nextDouble() < 0.2 ? _pickNextOre() : 'stone';
      _leftTopBlock = _rng.nextDouble() < 0.2 ? _pickNextOre() : 'stone';
      _rightTopBlock = _rng.nextDouble() < 0.2 ? _pickNextOre() : 'stone';
      _leftBottomBlock = _rng.nextDouble() < 0.2 ? _pickNextOre() : 'stone';
      _rightBottomBlock = _rng.nextDouble() < 0.2 ? _pickNextOre() : 'stone';
    }

    void _mineSurroundingBlock(String position) {
      if (_mining || _miningSurrounding) return;
      if (_currentHammerfells < 1) return;
      
      String blockType = 'stone';
      switch (position) {
        case 'top':
          blockType = _topBlock;
          break;
        case 'bottom':
          blockType = _bottomBlock;
          break;
        case 'leftTop':
          blockType = _leftTopBlock;
          break;
        case 'rightTop':
          blockType = _rightTopBlock;
          break;
        case 'leftBottom':
          blockType = _leftBottomBlock;
          break;
        case 'rightBottom':
          blockType = _rightBottomBlock;
          break;
      }
      
      if (blockType != 'stone') {
        setState(() {
          _miningSurrounding = true;
          _surroundingBlockPosition = position;
          _surroundingCrackStep = 1;
        });
        
        Timer.periodic(const Duration(milliseconds: 200), (timer) {
          if (!mounted || !_miningSurrounding || _surroundingBlockPosition != position) {
            timer.cancel();
            return;
          }
          setState(() {
            _surroundingCrackStep++;
            if (_surroundingCrackStep > 2) {
              _surroundingCrackStep = 0;
              timer.cancel();
              widget.onMine(blockType).then((success) {
                if (success) {
                  _addToBackpack(blockType);
                  _currentHammerfells--;
                }
              });
              _miningSurrounding = false;
              _surroundingBlockPosition = null;
              
              // Replace mined block with stone
              switch (position) {
                case 'top':
                  _topBlock = 'stone';
                  break;
                case 'bottom':
                  _bottomBlock = 'stone';
                  break;
                case 'leftTop':
                  _leftTopBlock = 'stone';
                  break;
                case 'rightTop':
                  _rightTopBlock = 'stone';
                  break;
                case 'leftBottom':
                  _leftBottomBlock = 'stone';
                  break;
                case 'rightBottom':
                  _rightBottomBlock = 'stone';
                  break;
              }
            }
          });
        });
      }
    }

    Widget _buildSurroundingBlock(String blockType, String position, double width, double height, double top, double left) {
      CustomClipper<Path>? clipper;
      switch (position) {
        case 'top':
          clipper = TopTrapezoidClipper();
          break;
        case 'bottom':
          clipper = BottomTrapezoidClipper();
          break;
        case 'leftTop':
          clipper = LeftTopTrapezoidClipper();
          break;
        case 'rightTop':
          clipper = RightTopTrapezoidClipper();
          break;
        case 'leftBottom':
          clipper = LeftBottomTrapezoidClipper();
          break;
        case 'rightBottom':
          clipper = RightBottomTrapezoidClipper();
          break;
      }
      
      bool isMining = _miningSurrounding && _surroundingBlockPosition == position;
      bool isPressed = _pressedSurroundingBlock == position;
      
      return Positioned(
        top: top,
        left: left,
        child: GestureDetector(
          onTapDown: (TapDownDetails details) {
            setState(() {
              _pressedSurroundingBlock = position;
            });
            if (_currentHammerfells < 1) {
              _playErrorSound();
            }
          },
          onTapUp: (TapUpDetails details) {
            setState(() {
              _pressedSurroundingBlock = null;
            });
          },
          onTapCancel: () {
            setState(() {
              _pressedSurroundingBlock = null;
            });
          },
          onLongPressStart: (LongPressStartDetails details) {
            _mineSurroundingBlock(position);
          },
          onLongPressEnd: (LongPressEndDetails details) {
            if (_miningSurrounding && _surroundingBlockPosition == position) {
              setState(() {
                _miningSurrounding = false;
                _surroundingBlockPosition = null;
                _surroundingCrackStep = 0;
              });
            }
          },
          child: Stack(
            children: [
              ClipPath(
                clipper: clipper,
                child: Container(
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(_getOreBlockAsset(blockType)),
                      fit: BoxFit.fill,
                    ),
                  ),
                  child: isMining && _surroundingCrackStep > 0
                      ? Image.asset(
                          _crackAsset(_surroundingCrackStep, blockType),
                          width: width,
                          height: height,
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
              ),
              CustomPaint(
                size: Size(width, height),
                painter: TrapezoidBorderPainter(
                  position: position,
                  color: (isMining || isPressed) ? Colors.white : Colors.black,
                  width: (isMining || isPressed) ? 2 : 1,
                ),
              ),
            ],
          ),
        ),
      );
    }

    void _addToBackpack(String oreType) {
      BackpackManager().addItem(oreType);
      setState(() {});
    }

    void _searchMine() {
      showModalBottomSheet(
        context: context,
        isDismissible: true,
        enableDrag: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        builder: (c) => MineSearchModal(
          currentMineType: _currentMine?.oreType,
          onEnterMine: (mine) {
            Navigator.of(c).pop();
            setState(() {
              _hasEnteredMine = true;
              _currentMine = mine;
              _nextOre1 = _pickNextOre();
              _nextOre2 = _pickNextOre();
              _generateSurroundingBlocks();
              _block1Mined = false;
              _block2Mined = false;
            });
            _saveMineState();
          },
        ),
      );
    }

    void _openFurnace() {
      if (widget.onOpenFurnace != null) {
        widget.onOpenFurnace!();
      } else {
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
              furnaceState: _furnaceState,
              onStateChanged: () {
                setState(() {});
                _furnaceState.save(_furnaceKey);
              },
            ),
          ),
        );
      }
    }

    @override
    Widget build(BuildContext context) {
      if (_hasEnteredMine && _currentMine != null) {
        if (_nextOre1 == null) {
          _nextOre1 = _pickNextOre();
        }
        if (_nextOre2 == null) {
          _nextOre2 = _pickNextOre();
        }
      }
      final String mineTitle = _currentMine != null 
          ? '${_currentMine.oreType[0].toUpperCase()}${_currentMine.oreType.substring(1)} Mine'
          : 'Mine';
      return Scaffold(
        appBar: AppBar(
          title: Text(mineTitle),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Center(
                child: Text(
                  'Hammerfells: $_currentHammerfells',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            Stack(
              children: [
                // Surrounding blocks with trapezoid shapes
                // Top block - sits directly above the two front blocks
                _buildSurroundingBlock(_topBlock, 'top', 240, 70,
                  MediaQuery.of(context).size.height / 2 - 299,
                  MediaQuery.of(context).size.width / 2 - 120),
                // Left top - sits to the left of top front block (block 1)
                _buildSurroundingBlock(_leftTopBlock, 'leftTop', 60, 190, 
                  MediaQuery.of(context).size.height / 2 - 300, 
                  MediaQuery.of(context).size.width / 2 - 120),
                // Right top - sits to the right of top front block (block 1)
                _buildSurroundingBlock(_rightTopBlock, 'rightTop', 60, 190,
                  MediaQuery.of(context).size.height / 2 - 300,
                  MediaQuery.of(context).size.width / 2 + 60),
                // Left bottom - sits to the left of bottom front block (block 2)
                _buildSurroundingBlock(_leftBottomBlock, 'leftBottom', 60, 190,
                  MediaQuery.of(context).size.height / 2 - 110,
                  MediaQuery.of(context).size.width / 2 - 120),
                // Right bottom - sits to the right of bottom front block (block 2)
                _buildSurroundingBlock(_rightBottomBlock, 'rightBottom', 60, 190,
                  MediaQuery.of(context).size.height / 2 - 110,
                  MediaQuery.of(context).size.width / 2 + 60),
                // Bottom block - sits directly below the two front blocks
                _buildSurroundingBlock(_bottomBlock, 'bottom', 240, 70,
                  MediaQuery.of(context).size.height / 2 + 10,
                  MediaQuery.of(context).size.width / 2 - 120),
                
                // Main mining area centered
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // First mining button
                      GestureDetector(
                    onLongPressStart: (LongPressStartDetails details) async {
                      if (_currentMine == null || _nextOre1 == null) return;
                      if (_currentHammerfells < 1) return;
                      if (_mining) return;
                      final oreType = _nextOre1!;
                      setState(() {
                        _mining = true;
                        _isPressed1 = true;
                        _miningButtonIndex = 1;
                        _crackStep = 1;
                      });
                      Timer.periodic(const Duration(milliseconds: 200), (timer) {
                        if (!mounted || !_mining || _miningButtonIndex != 1) {
                          timer.cancel();
                          return;
                        }
                        setState(() {
                          _crackStep++;
                          if (_crackStep > 2) {
                            _crackStep = 0;
                            timer.cancel();
                            widget.onMine(oreType).then((success) {
                              if (success) {
                                _addToBackpack(oreType);
                                _currentHammerfells--;
                              }
                            });
                            _mining = false;
                            _block1Mined = true;
                            _nextOre1 = _pickNextOre();
                            // Check if both blocks are mined
                            if (_block1Mined && _block2Mined) {
                              _generateSurroundingBlocks();
                              _block1Mined = false;
                              _block2Mined = false;
                            }
                          }
                        });
                      });
                    },
                    onLongPressEnd: (LongPressEndDetails details) {
                      if (_nextOre1 == null || _miningButtonIndex != 1) return;
                      setState(() {
                        _mining = false;
                        _isPressed1 = false;
                        _crackStep = 0;
                      });
                    },
                    onTapDown: (_) {
                      if (!_mining && _nextOre1 != null) {
                        setState(() {
                          _isPressed1 = true;
                        });
                      }
                      if (_currentHammerfells < 1) {
                        _playErrorSound();
                      }
                    },
                    onTapUp: (_) {
                      if (_isPressed1) {
                        setState(() {
                          _isPressed1 = false;
                        });
                      }
                    },
                    onTapCancel: () {
                      if (_isPressed1) {
                        setState(() {
                          _isPressed1 = false;
                        });
                      }
                    },
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        image: _nextOre1 != null
                            ? DecorationImage(
                                image: AssetImage(_getOreBlockAsset(_nextOre1!)),
                                fit: BoxFit.cover,
                              )
                            : _currentMine != null && _currentMine.oreType != null && _currentMine.oreType.isNotEmpty
                                ? DecorationImage(
                                    image: AssetImage(_getOreBlockAsset(_currentMine.oreType)),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                        color: _currentMine == null ? Colors.grey[700] : null,
                        border: _isPressed1 ? Border.all(color: Colors.white, width: 2) : null,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_currentMine == null)
                            const Icon(Icons.construction, size: 80, color: Colors.white),
                          if (_crackStep > 0 && _nextOre1 != null && _miningButtonIndex == 1)
                            Image.asset(_crackAsset(_crackStep, _nextOre1!), width: 120, height: 120, fit: BoxFit.cover),
                        ],
                      ),
                    ),
                  ),
                  // Second mining button
                  GestureDetector(
                    onLongPressStart: (LongPressStartDetails details) async {
                      if (_currentMine == null || _nextOre2 == null) return;
                      if (_currentHammerfells < 1) return;
                      if (_mining) return;
                      final oreType = _nextOre2!;
                      setState(() {
                        _mining = true;
                        _isPressed2 = true;
                        _miningButtonIndex = 2;
                        _crackStep = 1;
                      });
                      Timer.periodic(const Duration(milliseconds: 200), (timer) {
                        if (!mounted || !_mining || _miningButtonIndex != 2) {
                          timer.cancel();
                          return;
                        }
                        setState(() {
                          _crackStep++;
                          if (_crackStep > 2) {
                            _crackStep = 0;
                            timer.cancel();
                            widget.onMine(oreType).then((success) {
                              if (success) {
                                _addToBackpack(oreType);
                                _currentHammerfells--;
                              }
                            });
                            _mining = false;
                            _block2Mined = true;
                            _nextOre2 = _pickNextOre();
                            // Check if both blocks are mined
                            if (_block1Mined && _block2Mined) {
                              _generateSurroundingBlocks();
                              _block1Mined = false;
                              _block2Mined = false;
                            }
                          }
                        });
                      });
                    },
                    onLongPressEnd: (LongPressEndDetails details) {
                      if (_nextOre2 == null || _miningButtonIndex != 2) return;
                      setState(() {
                        _mining = false;
                        _isPressed2 = false;
                        _crackStep = 0;
                      });
                    },
                    onTapDown: (TapDownDetails details) {
                      if (!_mining && _nextOre2 != null) {
                        setState(() {
                          _isPressed2 = true;
                        });
                      }
                      if (_currentHammerfells < 1) {
                        _playErrorSound();
                      }
                    },
                    onTapUp: (_) {
                      if (_isPressed2) {
                        setState(() {
                          _isPressed2 = false;
                        });
                      }
                    },
                    onTapCancel: () {
                      if (_isPressed2) {
                        setState(() {
                          _isPressed2 = false;
                        });
                      }
                    },
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        image: _nextOre2 != null
                            ? DecorationImage(
                                image: AssetImage(_getOreBlockAsset(_nextOre2!)),
                                fit: BoxFit.cover,
                              )
                            : _currentMine != null && _currentMine.oreType != null && _currentMine.oreType.isNotEmpty
                                ? DecorationImage(
                                    image: AssetImage(_getOreBlockAsset(_currentMine.oreType)),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                        color: _currentMine == null ? Colors.grey[700] : null,
                        border: _isPressed2 ? Border.all(color: Colors.white, width: 2) : null,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_currentMine == null)
                            const Icon(Icons.construction, size: 80, color: Colors.white),
                          if (_crackStep > 0 && _nextOre2 != null && _miningButtonIndex == 2)
                            Image.asset(_crackAsset(_crackStep, _nextOre2!), width: 120, height: 120, fit: BoxFit.cover),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_mineResult != null) ...[
                    const SizedBox(height: 12),
                    Text(_mineResult!, style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                  const SizedBox(height: 20),
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
                                columns: 5,
                                rows: 1,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
              ],
            ),
            Positioned(
              left: 16,
              bottom: 16,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: _searchMine,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Search for Mine'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _openFurnace,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Furnace'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      await _saveMineState();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Home'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }
