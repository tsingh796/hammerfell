import 'package:flutter/material.dart';

class CoinIcon extends StatelessWidget {
	final String asset;
	final double size;

	const CoinIcon(this.asset, {super.key, this.size = 20});

	@override
	Widget build(BuildContext context) {
		return Image.asset(asset, width: size, height: size);
	}
}
