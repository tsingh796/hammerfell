import 'package:flutter/material.dart';

typedef SetStateCallback = void Function(void Function());

Future<void> pulseRow(
	String id,
	bool success,
	SetStateCallback setState,
	Map<String, double> rowScale,
	Map<String, Color?> rowOverlayColor,
) async {
	setState(() {
		rowScale[id] = 1.06;
		rowOverlayColor[id] = success ? Colors.green.withOpacity(0.18) : Colors.red.withOpacity(0.18);
	});

	await Future.delayed(const Duration(milliseconds: 320));
	setState(() {
		rowScale[id] = 1.0;
		rowOverlayColor[id] = null;
	});
}
