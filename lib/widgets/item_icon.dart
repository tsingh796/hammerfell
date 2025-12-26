import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ItemIcon extends StatelessWidget {
  final String type;
  final int count;
  final double size;
  final bool showCount;
  const ItemIcon({
    super.key,
    required this.type,
    required this.count,
    this.size = 28,
    this.showCount = true,
  });

  String get asset {
    switch (type) {
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
      case 'coal':
        return 'assets/images/coal.png';
      case 'stone':
        return 'assets/images/stone.png';
      case 'copper_ingot':
        return 'assets/images/copper_ingot.png';
      case 'iron_ingot':
        return 'assets/images/iron_ingot.png';
      case 'gold_ingot':
        return 'assets/images/gold_ingot.png';
      default:
        return 'assets/images/unknown_ore.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
            child: Image.asset(asset, fit: BoxFit.contain),
        ),
        if (showCount)
          Text('$count', style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}
