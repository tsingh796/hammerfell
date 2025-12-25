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
        return 'assets/images/iron_ore.svg';
      case 'copper':
      case 'copper_ore':
        return 'assets/images/copper_ore.svg';
      case 'gold':
      case 'gold_ore':
        return 'assets/images/gold_ore.svg';
      case 'coal':
        return 'assets/images/coal.svg';
      case 'stone':
        return 'assets/images/stone.svg';
      case 'copper_ingot':
        return 'assets/images/copper_ingot.svg';
      case 'iron_ingot':
        return 'assets/images/iron_ingot.svg';
      case 'gold_ingot':
        return 'assets/images/gold_ingot.svg';
      default:
        return 'assets/images/unknown_ore.svg';
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
          child: asset.endsWith('.svg')
              ? SvgPicture.asset(asset, fit: BoxFit.contain)
              : const Icon(Icons.help_outline),
        ),
        if (showCount)
          Text('$count', style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}
