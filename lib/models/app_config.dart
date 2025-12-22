import 'package:flutter/services.dart' show rootBundle;
import 'package:yaml/yaml.dart';

class AppConfig {
  final Map<String, dynamic> mining;
  final Map<String, dynamic> smelting;

  AppConfig({required this.mining, required this.smelting});

  static Map<String, dynamic> _toMap(dynamic yaml) {
    if (yaml == null) return <String, dynamic>{};
    if (yaml is YamlMap) return Map<String, dynamic>.from(yaml);
    if (yaml is Map) return Map<String, dynamic>.from(yaml);
    return <String, dynamic>{};
  }

  factory AppConfig.fromYaml(YamlMap doc) {
    final mining = _toMap(doc['mining']);
    final smelting = _toMap(doc['smelting']);
    return AppConfig(mining: mining, smelting: smelting);
  }

  static Future<AppConfig> loadFromAssets([String path = 'assets/config.yml']) async {
    final yamlStr = await rootBundle.loadString(path);
    final doc = loadYaml(yamlStr) as YamlMap;
    return AppConfig.fromYaml(doc);
  }

  int miningCost(String ore, {int fallback = 1}) {
    final m = mining[ore];
    if (m is Map && m['cost'] != null) return (m['cost'] as num).toInt();
    return fallback;
  }

  /// Returns a chance between 0.0 and 1.0 for the given mining key.
  double miningChance(String ore, {double fallback = 1.0}) {
    final m = mining[ore];
    if (m is Map && m['chance'] != null) return (m['chance'] as num).toDouble();
    return fallback;
  }

  int smeltingCost(String ore, {int fallback = 1}) {
    final s = smelting[ore];
    if (s is Map && s['cost'] != null) return (s['cost'] as num).toInt();
    return fallback;
  }
}
