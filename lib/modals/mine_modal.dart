import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MineModal extends StatefulWidget {
	final int hammerfells;
	final Map<String, double>? miningChances;
	final Future<bool> Function(String) onMine;

	const MineModal({
		super.key,
		required this.hammerfells,
		required this.onMine,
		this.miningChances,
	});

	@override
	_MineModalState createState() => _MineModalState();
}

enum _MineStatus { idle, loading, success, failure }

class _MineModalState extends State<MineModal> with TickerProviderStateMixin {
	final Map<String, _MineStatus> _statuses = {};
	final Map<String, AnimationController> _controllers = {};
	static const _progressDuration = Duration(milliseconds: 1000);
	static const _colorHoldDuration = Duration(milliseconds: 800);

	AnimationController _ensureController(String key) {
		if (!_controllers.containsKey(key)) {
			_controllers[key] = AnimationController(vsync: this, duration: _progressDuration)
				..addListener(() {
					if (mounted) setState(() {});
				});
		}
		return _controllers[key]!;
	}

	@override
	void dispose() {
		for (final c in _controllers.values) {
			c.dispose();
		}
		super.dispose();
	}

	Widget _mineTile(BuildContext context, String label, int cost, String key, String svgAsset) {
		final canMine = widget.hammerfells >= 1;
		final chance = widget.miningChances != null ? (widget.miningChances![key] ?? 1.0) : 1.0;
		final chancePct = (chance * 100).toStringAsFixed(0);
		final status = _statuses[key] ?? _MineStatus.idle;
		final controller = _ensureController(key);
		final progress = controller.value.clamp(0.0, 1.0);

		Widget buttonChild = Stack(
			alignment: Alignment.center,
			children: [
				Positioned.fill(
					child: ClipRRect(
						borderRadius: BorderRadius.circular(8),
						child: FractionallySizedBox(
							alignment: Alignment.centerLeft,
							widthFactor: status == _MineStatus.idle ? 0.0 : (status == _MineStatus.loading ? progress : 1.0),
							child: Container(
								color: status == _MineStatus.success
										? Colors.green
										: status == _MineStatus.failure
												? Colors.orange
												: Colors.yellow,
							),
						),
					),
				),
				const Center(child: Text('Mine', style: TextStyle(color: Colors.white))),
			],
		);

		return ListTile(
			leading: SvgPicture.asset(svgAsset, width: 28, height: 28, colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.onSurface, BlendMode.srcIn)),
			title: Text(label),
			subtitle: Text('1 H • $chancePct% chance'),
			trailing: canMine
					? ElevatedButton(
							style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10)),
							onPressed: status == _MineStatus.loading
									? null
									: () async {
											setState(() => _statuses[key] = _MineStatus.loading);
											final c = _ensureController(key);
											c.reset();

											await c.forward();
											bool success = false;
											try {
												success = await widget.onMine(key);
											} catch (_) {
												success = false;
											}

											setState(() => _statuses[key] = success ? _MineStatus.success : _MineStatus.failure);
											c.value = 1.0;
											await Future.delayed(_colorHoldDuration);

											if (mounted) setState(() => _statuses[key] = _MineStatus.idle);
											c.reset();
										},
							child: SizedBox(width: 72, height: 36, child: buttonChild),
						)
					: const Text('Unavailable', style: TextStyle(color: Colors.grey)),
		);
	}

	@override
	Widget build(BuildContext context) {
		final canMineAny = widget.hammerfells >= 1;
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
