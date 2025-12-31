import 'package:flutter/foundation.dart';

class CoinManager extends ChangeNotifier {
  static final CoinManager _instance = CoinManager._internal();
  factory CoinManager() => _instance;
  CoinManager._internal();

  int copperCoins = 0;
  int silverCoins = 0;
  int goldCoins = 0;

  // Conversion rates
  static const int copperPerSilver = 81;
  static const int silverPerGold = 27;
  static const int copperPerGold = copperPerSilver * silverPerGold; // 2187

  void setCoins(int copper, int silver, int gold) {
    copperCoins = copper;
    silverCoins = silver;
    goldCoins = gold;
    notifyListeners();
  }

  void addCoins(int copper, int silver, int gold) {
    copperCoins += copper;
    silverCoins += silver;
    goldCoins += gold;
    notifyListeners();
  }

  void removeCoins(int copper, int silver, int gold) {
    copperCoins -= copper;
    silverCoins -= silver;
    goldCoins -= gold;
    notifyListeners();
  }

  // Check if player has enough of a specific coin type
  bool hasEnough(int amount, String coinType) {
    switch (coinType) {
      case 'copper':
        return copperCoins >= amount;
      case 'silver':
        return silverCoins >= amount;
      case 'gold':
        return goldCoins >= amount;
      default:
        return false;
    }
  }

  // Convert coins: from one type to another
  // Returns true if conversion was successful
  bool convertCoins(String fromType, String toType, int amount) {
    if (fromType == toType) return false;

    // Check if we have enough coins to convert
    if (!hasEnough(amount, fromType)) return false;

    int convertedAmount = 0;

    // Calculate conversion
    if (fromType == 'gold' && toType == 'silver') {
      convertedAmount = amount * silverPerGold;
      goldCoins -= amount;
      silverCoins += convertedAmount;
    } else if (fromType == 'gold' && toType == 'copper') {
      convertedAmount = amount * copperPerGold;
      goldCoins -= amount;
      copperCoins += convertedAmount;
    } else if (fromType == 'silver' && toType == 'copper') {
      convertedAmount = amount * copperPerSilver;
      silverCoins -= amount;
      copperCoins += convertedAmount;
    } else if (fromType == 'silver' && toType == 'gold') {
      // Check if we have enough silver for at least 1 gold
      if (amount < silverPerGold) return false;
      convertedAmount = amount ~/ silverPerGold;
      silverCoins -= convertedAmount * silverPerGold;
      goldCoins += convertedAmount;
    } else if (fromType == 'copper' && toType == 'silver') {
      if (amount < copperPerSilver) return false;
      convertedAmount = amount ~/ copperPerSilver;
      copperCoins -= convertedAmount * copperPerSilver;
      silverCoins += convertedAmount;
    } else if (fromType == 'copper' && toType == 'gold') {
      if (amount < copperPerGold) return false;
      convertedAmount = amount ~/ copperPerGold;
      copperCoins -= convertedAmount * copperPerGold;
      goldCoins += convertedAmount;
    } else {
      return false;
    }

    notifyListeners();
    return true;
  }

  // Get total wealth in copper equivalent (for comparison)
  int getTotalInCopper() {
    return copperCoins + (silverCoins * copperPerSilver) + (goldCoins * copperPerGold);
  }
}
