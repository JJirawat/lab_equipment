import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'equipment_icons.dart';

class EditEquipmentScreen extends StatefulWidget {
  final String equipmentId;
  final Map<String, dynamic> equipmentData;

  const EditEquipmentScreen({
    super.key,
    required this.equipmentId,
    required this.equipmentData,
  });

  @override
  State<EditEquipmentScreen> createState() => _EditEquipmentScreenState();
}

class _EditEquipmentScreenState extends State<EditEquipmentScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _totalQtyController;
  late bool _hasSizes;
  late Map<String, TextEditingController> _sizeQtyControllers;
  bool _isLoading = false;
  bool _isDeleting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.equipmentData['name'] ?? '');
    _descriptionController =
        TextEditingController(text: widget.equipmentData['description'] ?? '');
    _hasSizes = widget.equipmentData['hasSizes'] ?? false;

    _sizeQtyControllers = {};
    if (_hasSizes) {
      final sizes = List<Map<String, dynamic>>.from(widget.equipmentData['sizes'] ?? []);
      for (var s in sizes) {
        _sizeQtyControllers[s['size']] =
            TextEditingController(text: '${s['totalQty'] ?? 0}');
      }
    }

    _totalQtyController =
        TextEditingController(text: '${widget.equipmentData['totalQty'] ?? 0}');
  }

  // คำนวณจำนวนที่ถูกยืมอยู่ตอนนี้ (totalQty เดิม - availableQty เดิม)
  int get _currentlyBorrowed {
    final total = (widget.equipmentData['totalQty'] ?? 0) as int;
    final available = (widget.equipmentData['availableQty'] ?? 0) as int;
    return total - available;
  }

  Future<void> _saveChanges() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'กรุณากรอกชื่ออุปกรณ์');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_hasSizes) {
        final oldSizes = List<Map<String, dynamic>>.from(widget.equipmentData['sizes'] ?? []);
        final newSizes = <Map<String, dynamic>>[];
        int newTotalQty = 0;
        int newAvailableQty = 0;

        for (var oldSize in oldSizes) {
          final sizeKey = oldSize['size'];
          final oldTotal = (oldSize['totalQty'] ?? 0) as int;
          final oldAvailable = (oldSize['availableQty'] ?? 0) as int;
          final borrowedForThisSize = oldTotal - oldAvailable;

          final newTotalForSize =
              int.tryParse(_sizeQtyControllers[sizeKey]?.text.trim() ?? '') ?? oldTotal;
          final newAvailableForSize =
              (newTotalForSize - borrowedForThisSize).clamp(0, newTotalForSize);

          newSizes.add({
            'size': sizeKey,
            'totalQty': newTotalForSize,
            'availableQty': newAvailableForSize,
          });

          newTotalQty += newTotalForSize;
          newAvailableQty += newAvailableForSize;
        }

        await FirebaseFirestore.instance
            .collection('equipment')
            .doc(widget.equipmentId)
            .update({
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'sizes': newSizes,
          'totalQty': newTotalQty,
          'availableQty': newAvailableQty,
        });
      } else {
        final newTotal = int.tryParse(_totalQtyController.text.trim()) ?? 0;
        final newAvailable = (newTotal - _currentlyBorrowed).clamp(0, newTotal);

        await FirebaseFirestore.instance
            .collection('equipment')
            .doc(widget.equipmentId)
            .update({
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'totalQty': newTotal,
          'availableQty': newAvailable,
        });
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกการแก้ไขสำเร็จ')),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'เกิดข้อผิดพลาด ลองอีกครั้ง');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('ต้องการลบ "${widget.equipmentData['name']}" ใช่ไหม?\nการลบไม่สามารถย้อนกลับได้'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    try {
      await FirebaseFirestore.instance
          .collection('equipment')
          .doc(widget.equipmentId)
          .delete();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบอุปกรณ์สำเร็จ')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDeleting = false;
          _errorMessage = 'ลบไม่สำเร็จ ลองอีกครั้ง';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = getEquipmentIcon(widget.equipmentData['icon']);
    final iconColor = getEquipmentColor(widget.equipmentData['colorIndex']);

    return Scaffold(
      appBar: AppBar(
        title: const Text('แก้ไขอุปกรณ์'),
        actions: [
          IconButton(
            icon: _isDeleting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _isDeleting ? null : _confirmDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 34, color: iconColor),
              ),
            ),
            const SizedBox(height: 24),

            const Text('ชื่ออุปกรณ์', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (_hasSizes) ...[
              const Text('จำนวนทั้งหมดแต่ละขนาด',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                'ระบบจะคำนวณจำนวนคงเหลือใหม่ให้อัตโนมัติ',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 10),
              ..._sizeQtyControllers.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      SizedBox(width: 70, child: Text(entry.key)),
                      Expanded(
                        child: TextField(
                          controller: entry.value,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            isDense: true,
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ] else ...[
              const Text('จำนวนทั้งหมด (ชิ้น)',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                'ปัจจุบันถูกยืมอยู่ $_currentlyBorrowed ชิ้น ระบบจะคำนวณจำนวนคงเหลือใหม่ให้อัตโนมัติ',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _totalQtyController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),

            const Text('รายละเอียด / หมายเหตุ',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
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
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ),

            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('บันทึกการแก้ไข',
                        style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}