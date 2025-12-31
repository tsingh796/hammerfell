import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/shop_config.dart';
import '../utils/backpack_manager.dart';
import '../utils/coin_manager.dart';
import '../widgets/item_icon.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({
    Key? key,
  }) : super(key: key);

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: ShopConfig.categories.length,
      vsync: this,
    );
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  void _showNotification(String message, {bool isSuccess = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 160, left: 10, right: 10),
        backgroundColor: (isSuccess ? Colors.green : Colors.red).shade700.withOpacity(0.95),
      ),
    );
  }
  
  void _buyItem(String itemType, Map<String, dynamic> priceInfo) {
    final amount = priceInfo['amount'] as int;
    final coinType = priceInfo['coinType'] as String;
    final quantity = priceInfo['quantity'] as int? ?? 1;
    final coinManager = CoinManager();
    
    if (coinManager.hasEnough(amount, coinType)) {
      final backpackManager = Provider.of<BackpackManager>(context, listen: false);
      
      // Check if backpack has space for the quantity of items
      int addedCount = 0;
      for (int i = 0; i < quantity; i++) {
        final hasSpace = backpackManager.backpack.any((slot) => slot == null || 
          (slot['type'] == itemType && (slot['count'] ?? 0) < 64));
        
        if (hasSpace) {
          backpackManager.addItem(itemType);
          addedCount++;
        } else {
          break;
        }
      }
      
      if (addedCount > 0) {
        // Charge for the transaction
        if (coinType == 'copper') {
          coinManager.removeCoins(amount, 0, 0);
        } else if (coinType == 'silver') {
          coinManager.removeCoins(0, amount, 0);
        } else if (coinType == 'gold') {
          coinManager.removeCoins(0, 0, amount);
        }
        
        setState(() {});
        
        if (addedCount == quantity) {
          _showNotification('Bought ${quantity > 1 ? "$quantity " : ""}$itemType for $amount $coinType coins');
        } else {
          _showNotification('Bought $addedCount/$quantity $itemType (backpack full)');
        }
      } else {
        _showNotification('Backpack is full!', isSuccess: false);
      }
    } else {
      _showNotification('Not enough $coinType coins!', isSuccess: false);
    }
  }
  
  void _sellItem(String itemType, int fromIndex) {
    final backpackManager = Provider.of<BackpackManager>(context, listen: false);
    final priceInfo = ShopConfig.getSellPrice(itemType);
    
    if (priceInfo != null) {
      final amount = priceInfo['amount'] as int;
      final coinType = priceInfo['coinType'] as String;
      final quantity = priceInfo['quantity'] as int? ?? 1;
      final coinManager = CoinManager();
      
      // Count how many of this item we have
      int totalCount = 0;
      for (var slot in backpackManager.backpack) {
        if (slot != null && slot['type'] == itemType) {
          totalCount += slot['count'] as int? ?? 1;
        }
      }
      
      if (totalCount >= quantity) {
        // Remove the required quantity
        int remainingToRemove = quantity;
        for (int i = 0; i < backpackManager.backpack.length && remainingToRemove > 0; i++) {
          final slot = backpackManager.backpack[i];
          if (slot != null && slot['type'] == itemType) {
            final count = slot['count'] as int? ?? 1;
            if (count <= remainingToRemove) {
              backpackManager.backpack[i] = null;
              remainingToRemove -= count;
            } else {
              backpackManager.backpack[i] = {
                'type': itemType,
                'count': count - remainingToRemove,
              };
              remainingToRemove = 0;
            }
          }
        }
        backpackManager.save();
        
        // Add coins
        if (coinType == 'copper') {
          coinManager.addCoins(amount, 0, 0);
        } else if (coinType == 'silver') {
          coinManager.addCoins(0, amount, 0);
        } else if (coinType == 'gold') {
          coinManager.addCoins(0, 0, amount);
        }
        
        _showNotification('Sold ${quantity > 1 ? "$quantity " : ""}$itemType for $amount $coinType coins');
        setState(() {});
      } else {
        _showNotification('Need $quantity $itemType to sell (have $totalCount)', isSuccess: false);
      }
    }
  }
  
  Widget _buildBuyGrid(List<String> items) {
    // Filter to only show items that have a buy price
    final buyableItems = items.where((item) => ShopConfig.canBuy(item)).toList();
    
    if (buyableItems.isEmpty) {
      return const Center(
        child: Text(
          'No items available in this category',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }
    
    return Consumer<CoinManager>(
      builder: (context, coinManager, child) {
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 0.8,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: buyableItems.length,
          itemBuilder: (context, index) {
            final itemType = buyableItems[index];
            final priceInfo = ShopConfig.getBuyPrice(itemType)!;
            final amount = priceInfo['amount'] as int;
            final coinType = priceInfo['coinType'] as String;
            final quantity = priceInfo['quantity'] as int? ?? 1;
            final canAfford = coinManager.hasEnough(amount, coinType);
            
            return GestureDetector(
              onTap: () => _buyItem(itemType, priceInfo),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: canAfford ? Colors.white24 : Colors.red.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ItemIcon(type: itemType, count: 1, size: 40),
                            ),
                          ),
                          if (quantity > 1)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'x$quantity',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: canAfford 
                            ? Colors.green.withOpacity(0.3)
                            : Colors.red.withOpacity(0.3),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Opacity(
                        opacity: canAfford ? 1.0 : 0.5,
                        child: _coinIcon(coinType, size: 14),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$amount',
                        style: TextStyle(
                          color: canAfford ? Colors.white : Colors.red.shade300,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
      },
    );
  }
  
  Widget _buildBackpackWithSellPrices() {
    return Consumer<BackpackManager>(
      builder: (context, backpackManager, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            border: Border(
              top: BorderSide(color: Colors.white24, width: 1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Backpack - Tap to Sell',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: SizedBox(
                  height: 80,
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 1,
                      childAspectRatio: 1.33,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                    ),
                    itemCount: backpackManager.backpack.length,
                  itemBuilder: (context, index) {
                    final slot = backpackManager.backpack[index];
                    
                    if (slot == null) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white24, width: 1),
                        ),
                      );
                    }
                    
                    final itemType = slot['type'] as String;
                    final count = slot['count'] as int? ?? 1;
                    final priceInfo = ShopConfig.getSellPrice(itemType);
                    final canSell = ShopConfig.canSell(itemType);
                    
                    // Count total items of this type in backpack
                    int totalCount = 0;
                    for (var s in backpackManager.backpack) {
                      if (s != null && s['type'] == itemType) {
                        totalCount += s['count'] as int? ?? 1;
                      }
                    }
                    
                    final quantity = priceInfo?['quantity'] as int? ?? 1;
                    final hasEnough = totalCount >= quantity;
                    
                    return GestureDetector(
                      onTap: canSell ? () => _sellItem(itemType, index) : null,
                      child: Container(
                        decoration: BoxDecoration(
                          color: canSell 
                              ? (hasEnough ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.1))
                              : Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: canSell ? (hasEnough ? Colors.green : Colors.red.shade700) : Colors.white24,
                            width: canSell ? 2 : 1,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: 8,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: ItemIcon(type: itemType, count: count, size: 36),
                              ),
                            ),
                            if (canSell && priceInfo != null)
                              Positioned(
                                bottom: 2,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (hasEnough ? Colors.green : Colors.red).withOpacity(0.8),
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(6),
                                      bottomRight: Radius.circular(6),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (quantity > 1) ...[
                                        Text(
                                          '$quantity',
                                          style: TextStyle(
                                            color: hasEnough ? Colors.white : Colors.red.shade200,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Icon(Icons.arrow_forward, size: 8, color: Colors.white),
                                        const SizedBox(width: 2),
                                      ],
                                      _coinIcon(priceInfo['coinType'] as String, size: 10),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${priceInfo['amount']}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _coinIcon(String coinType, {double size = 14}) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.store, color: Colors.white),
            const SizedBox(width: 8),
            const Text('Shop'),
            const Spacer(),
            Consumer<CoinManager>(
              builder: (context, coinManager, child) {
                return Row(
                  children: [
                    // Gold coins
                    Image.asset('assets/images/gold_coin.png', width: 16, height: 16),
                    const SizedBox(width: 2),
                    Text(
                      '${coinManager.goldCoins}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Silver coins
                    Image.asset('assets/images/silver_coin.png', width: 16, height: 16),
                    const SizedBox(width: 2),
                    Text(
                      '${coinManager.silverCoins}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Copper coins
                    Image.asset('assets/images/copper_coin.png', width: 16, height: 16),
                    const SizedBox(width: 2),
                    Text(
                      '${coinManager.copperCoins}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        backgroundColor: Colors.brown.shade700,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: ShopConfig.categories.keys.map((category) {
            return Tab(text: category);
          }).toList(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/shop_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: ShopConfig.categories.values.map((items) {
                  return _buildBuyGrid(items);
                }).toList(),
              ),
            ),
            _buildBackpackWithSellPrices(),
          ],
        ),
      ),
    );
  }
}
