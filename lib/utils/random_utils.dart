import 'dart:math';

/// Utility function to randomly select an item based on weighted chances.
/// [items] is a list of possible items (e.g., ore names).
/// [chances] is a list of corresponding chances (must be same length, values should sum to 1.0 or less).
/// Returns the selected item, or null if input is invalid.
dynamic weightedRandomChoice(List items, List<double> chances, {Random? rng}) {
  if (items.length != chances.length || items.isEmpty) return null;
  final random = rng ?? Random();
  final roll = random.nextDouble();
  double cumulative = 0.0;
  for (int i = 0; i < items.length; i++) {
    cumulative += chances[i];
    if (roll <= cumulative) {
      return items[i];
    }
  }
  // If rounding error, return last item
  return items.last;
}
