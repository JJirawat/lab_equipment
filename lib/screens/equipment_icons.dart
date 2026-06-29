import 'package:flutter/material.dart';

class EquipmentIconOption {
  final String key;
  final IconData icon;
  final String label;

  const EquipmentIconOption({
    required this.key,
    required this.icon,
    required this.label,
  });
}

const List<EquipmentIconOption> equipmentIconOptions = [
  EquipmentIconOption(key: 'beaker', icon: Icons.science, label: 'บีกเกอร์'),
  EquipmentIconOption(key: 'flask', icon: Icons.local_drink, label: 'ขวดรูปชมพู่'),
  EquipmentIconOption(key: 'tube', icon: Icons.opacity, label: 'หลอดทดลอง'),
  EquipmentIconOption(key: 'thermometer', icon: Icons.thermostat, label: 'เทอร์โมมิเตอร์'),
  EquipmentIconOption(key: 'scale', icon: Icons.balance, label: 'ตาชั่ง'),
  EquipmentIconOption(key: 'magnifier', icon: Icons.search, label: 'แว่นขยาย'),
  EquipmentIconOption(key: 'tool', icon: Icons.build, label: 'เครื่องมือ'),
  EquipmentIconOption(key: 'bottle', icon: Icons.water_drop, label: 'ขวดสาร'),
  EquipmentIconOption(key: 'funnel', icon: Icons.filter_alt, label: 'กรวยกรอง'),
  EquipmentIconOption(key: 'other', icon: Icons.category, label: 'อื่นๆ'),
];

const List<Color> equipmentColorOptions = [
  Colors.blue,
  Colors.teal,
  Colors.purple,
  Colors.orange,
  Colors.pink,
  Colors.green,
  Colors.indigo,
  Colors.brown,
];

IconData getEquipmentIcon(String? key) {
  final found = equipmentIconOptions.firstWhere(
    (e) => e.key == key,
    orElse: () => equipmentIconOptions.first,
  );
  return found.icon;
}

Color getEquipmentColor(int? colorIndex) {
  if (colorIndex == null ||
      colorIndex < 0 ||
      colorIndex >= equipmentColorOptions.length) {
    return Colors.blue;
  }
  return equipmentColorOptions[colorIndex];
}