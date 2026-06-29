import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'equipment_icons.dart';

class AddEquipmentScreen extends StatefulWidget {
  const AddEquipmentScreen({super.key});

  @override
  State<AddEquipmentScreen> createState() => _AddEquipmentScreenState();
}

class _AddEquipmentScreenState extends State<AddEquipmentScreen> {
  final _nameController = TextEditingController();
  final _totalQtyController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _category = 'แก้ว';
  String _selectedIconKey = equipmentIconOptions.first.key;
  int _selectedColorIndex = 0;
  bool _hasSizes = false;
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _categories = ['แก้ว', 'เครื่องมือ', 'อื่นๆ'];

  final List<String> _standardSizes = [
    '10 ml',
    '50 ml',
    '100 ml',
    '250 ml',
    '500 ml',
    '1000 ml',
  ];

  final Map<String, bool> _selectedSizes = {};
  final Map<String, TextEditingController> _sizeQtyControllers = {};

  @override
  void initState() {
    super.initState();
    for (var size in _standardSizes) {
      _selectedSizes[size] = false;
      _sizeQtyControllers[size] = TextEditingController();
    }
  }

  Future<void> _addEquipment() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'กรุณากรอกชื่ออุปกรณ์';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    int totalQty = 0;
    List<Map<String, dynamic>> sizesData = [];

    if (_hasSizes) {
      for (var size in _standardSizes) {
        if (_selectedSizes[size] == true) {
          final qtyText = _sizeQtyControllers[size]!.text.trim();
          final qty = int.tryParse(qtyText) ?? 0;
          if (qty > 0) {
            sizesData.add({
              'size': size,
              'totalQty': qty,
              'availableQty': qty,
            });
            totalQty += qty;
          }
        }
      }

      if (sizesData.isEmpty) {
        setState(() {
          _errorMessage = 'กรุณาเลือกขนาดและกรอกจำนวนอย่างน้อย 1 ขนาด';
          _isLoading = false;
        });
        return;
      }
    } else {
      final qty = int.tryParse(_totalQtyController.text.trim());
      if (qty == null || qty <= 0) {
        setState(() {
          _errorMessage = 'จำนวนต้องเป็นตัวเลขมากกว่า 0';
          _isLoading = false;
        });
        return;
      }
      totalQty = qty;
    }

    try {
      await FirebaseFirestore.instance.collection('equipment').add({
        'name': _nameController.text.trim(),
        'category': _category,
        'icon': _selectedIconKey,
        'colorIndex': _selectedColorIndex,
        'hasSizes': _hasSizes,
        'sizes': sizesData,
        'totalQty': totalQty,
        'availableQty': totalQty,
        'description': _descriptionController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เพิ่มอุปกรณ์สำเร็จ')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'เกิดข้อผิดพลาด ลองอีกครั้ง';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เพิ่มอุปกรณ์ใหม่'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ชื่ออุปกรณ์',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'เช่น บีกเกอร์ (Beaker)',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'เลือกไอคอนอุปกรณ์',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: equipmentIconOptions.map((option) {
                final isSelected = _selectedIconKey == option.key;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIconKey = option.key),
                  child: Container(
                    width: 64,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? equipmentColorOptions[_selectedColorIndex]
                              .withOpacity(0.15)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? equipmentColorOptions[_selectedColorIndex]
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          option.icon,
                          color: isSelected
                              ? equipmentColorOptions[_selectedColorIndex]
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          option.label,
                          style: const TextStyle(fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            const Text(
              'เลือกสี',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: List.generate(equipmentColorOptions.length, (index) {
                final isSelected = _selectedColorIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColorIndex = index),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: equipmentColorOptions[index],
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.black, width: 2)
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check,
                            color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),

            const Text(
              'หมวดหมู่',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: _categories.map((cat) {
                final isSelected = _category == cat;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _category = cat),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? Colors.blue : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        cat,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'มีหลายขนาดให้เลือก (ถ้ามี)',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Switch(
                    value: _hasSizes,
                    activeColor: Colors.blue,
                    onChanged: (value) {
                      setState(() => _hasSizes = value);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            if (_hasSizes) ...[
              const Text(
                'เลือกขนาดที่มี และกรอกจำนวน',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._standardSizes.map((size) {
                final isChecked = _selectedSizes[size] ?? false;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: isChecked ? Colors.blue.shade50 : Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: isChecked,
                        activeColor: Colors.blue,
                        onChanged: (value) {
                          setState(() {
                            _selectedSizes[size] = value ?? false;
                          });
                        },
                      ),
                      Expanded(
                        child: Text(size, style: const TextStyle(fontSize: 15)),
                      ),
                      if (isChecked)
                        SizedBox(
                          width: 90,
                          child: TextField(
                            controller: _sizeQtyControllers[size],
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'จำนวน',
                              isDense: true,
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(width: 4),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),
            ],

            if (!_hasSizes) ...[
              const Text(
                'จำนวนทั้งหมด (ชิ้น)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _totalQtyController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'เช่น 20',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            const Text(
              'รายละเอียด / หมายเหตุการใช้งาน',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'เช่น ใช้สำหรับผสมสาร',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _addEquipment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'เพิ่มอุปกรณ์',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}