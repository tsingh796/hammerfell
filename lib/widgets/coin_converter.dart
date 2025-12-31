import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/coin_manager.dart';

class CoinConverterDialog extends StatefulWidget {
  const CoinConverterDialog({Key? key}) : super(key: key);

  @override
  State<CoinConverterDialog> createState() => _CoinConverterDialogState();
}

class _CoinConverterDialogState extends State<CoinConverterDialog> {
  String fromCoin = 'copper';
  String toCoin = 'silver';
  int amount = 1;

  final List<String> coinTypes = ['copper', 'silver', 'gold'];

  Widget _coinImage(String coinType, {double size = 20}) {
    String assetPath;
    switch (coinType) {
      case 'copper':
        assetPath = 'assets/images/copper_coin.png';
        break;
      case 'silver':
        assetPath = 'assets/images/silver_coin.png';
        break;
      case 'gold':
        assetPath = 'assets/images/gold_coin.png';
        break;
      default:
        assetPath = 'assets/images/copper_coin.png';
    }
    return Image.asset(assetPath, width: size, height: size);
  }

  String getConversionRate() {
    if (fromCoin == toCoin) return 'Same coin type';
    
    if (fromCoin == 'copper' && toCoin == 'silver') {
      return '${CoinManager.copperPerSilver} copper → 1 silver';
    } else if (fromCoin == 'copper' && toCoin == 'gold') {
      return '${CoinManager.copperPerGold} copper → 1 gold';
    } else if (fromCoin == 'silver' && toCoin == 'gold') {
      return '${CoinManager.silverPerGold} silver → 1 gold';
    } else if (fromCoin == 'silver' && toCoin == 'copper') {
      return '1 silver → ${CoinManager.copperPerSilver} copper';
    } else if (fromCoin == 'gold' && toCoin == 'silver') {
      return '1 gold → ${CoinManager.silverPerGold} silver';
    } else if (fromCoin == 'gold' && toCoin == 'copper') {
      return '1 gold → ${CoinManager.copperPerGold} copper';
    }
    return '';
  }

  void _convertCoins() {
    final coinManager = Provider.of<CoinManager>(context, listen: false);
    
    if (fromCoin == toCoin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot convert to the same coin type!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = coinManager.convertCoins(fromCoin, toCoin, amount);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully converted $amount $fromCoin coins!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not enough coins to convert!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CoinManager>(
      builder: (context, coinManager, child) {
        return AlertDialog(
          title: const Text('Convert Coins'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Current Balance:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCoinDisplay('copper', coinManager.copperCoins),
                  _buildCoinDisplay('silver', coinManager.silverCoins),
                  _buildCoinDisplay('gold', coinManager.goldCoins),
                ],
              ),
              const SizedBox(height: 24),
              // From coin selection
              Row(
                children: [
                  const Text('From: '),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<String>(
                      value: fromCoin,
                      isExpanded: true,
                      items: coinTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Row(
                            children: [
                              _coinImage(type, size: 20),
                              const SizedBox(width: 8),
                              Text(type),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            fromCoin = value;
                            if (fromCoin == toCoin) {
                              // Switch toCoin to a different type
                              toCoin = coinTypes.firstWhere((t) => t != fromCoin);
                            }
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // To coin selection
              Row(
                children: [
                  const Text('To: '),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<String>(
                      value: toCoin,
                      isExpanded: true,
                      items: coinTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Row(
                            children: [
                              _coinImage(type, size: 20),
                              const SizedBox(width: 8),
                              Text(type),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            toCoin = value;
                            if (fromCoin == toCoin) {
                              // Switch fromCoin to a different type
                              fromCoin = coinTypes.firstWhere((t) => t != toCoin);
                            }
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Amount input
              Row(
                children: [
                  const Text('Amount: '),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (value) {
                        setState(() {
                          amount = int.tryParse(value) ?? 1;
                          if (amount < 1) amount = 1;
                        });
                      },
                      controller: TextEditingController(text: amount.toString()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Rate: ${getConversionRate()}',
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _convertCoins,
              child: const Text('Convert'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCoinDisplay(String coinType, int count) {
    return Column(
      children: [
        _coinImage(coinType, size: 24),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
