import 'package:flutter/material.dart';

Color darken(Color c, [double amount = 0.2]) {
	final hsl = HSLColor.fromColor(c);
	final l = (hsl.lightness - amount).clamp(0.0, 1.0);
	return hsl.withLightness(l).toColor();
}

Color readableTextColor(Color bg) {
	return bg.computeLuminance() > 0.55 ? Colors.black : Colors.white;
}
