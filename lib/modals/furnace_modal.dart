import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FurnaceModal extends StatefulWidget {
	final int hammerfells;
	final int ironOre;
	final int copperOre;
	final int goldOre;
	final void Function(String) onSmelt;
	final VoidCallback? onClose;

	const FurnaceModal({
		super.key,
		required this.hammerfells,
		required this.ironOre,
		required this.copperOre,
		required this.goldOre,
		required this.onSmelt,
		this.onClose,
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
																_isSmelting ? (isThis ? 'Smelting ${remaining}s' : 'Busy') : 'Smelt',
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
				child: LayoutBuilder(
					builder: (context, constraints) {
						return Padding(
							padding: const EdgeInsets.all(12),
							child: ConstrainedBox(
								constraints: BoxConstraints(maxHeight: constraints.maxHeight),
								child: Column(
									children: [
										Row(
											mainAxisAlignment: MainAxisAlignment.spaceBetween,
											children: [
												const Text('Furnace', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
												IconButton(
													onPressed: _isSmelting ? null : widget.onClose,
													icon: const Icon(Icons.close),
												),
											],
										),
										const SizedBox(height: 8),
										Expanded(
											child: Builder(builder: (context) {
												final canSmeltAny = widget.hammerfells >= 1 && (widget.ironOre >= 1 || widget.copperOre >= 1 || widget.goldOre >= 1);
												if (!canSmeltAny) {
													return ListView(
														children: [
															const SizedBox(height: 12),
															const Text('No ores available to smelt.', style: TextStyle(fontSize: 14)),
															const SizedBox(height: 8),
															ElevatedButton(
																onPressed: _isSmelting ? null : widget.onClose,
																child: const Text('Close'),
															),
															const SizedBox(height: 12),
														],
													);
												}
												return ListView(
													children: [
														_oreTile('Iron Ore', widget.ironOre, 'iron', 'assets/images/iron_ore.svg'),
														_oreTile('Copper Ore', widget.copperOre, 'copper', 'assets/images/copper_ore.svg'),
														_oreTile('Gold Ore', widget.goldOre, 'gold', 'assets/images/gold_ore.svg'),
														const SizedBox(height: 12),
													],
												);
											}),
										),
									],
								),
							),
						);
					},
				),
			),
		);
	}
}
