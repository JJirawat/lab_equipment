import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BorrowScreen extends StatefulWidget {
  final String equipmentId;
  final Map<String, dynamic> equipmentData;

  const BorrowScreen({
    super.key,
    required this.equipmentId,
    required this.equipmentData,
  });

  @override
  State<BorrowScreen> createState() => _BorrowScreenState();
}

class _BorrowScreenState extends State<BorrowScreen> {
  int _quantity = 1;
  String? _selectedSize;
  DateTime _borrowDate = DateTime.now();
  DateTime _returnDate = DateTime.now().add(const Duration(days: 7));
  final _purposeController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  int get _maxAvailable {
    final hasSizes = widget.equipmentData['hasSizes'] ?? false;
    if (hasSizes && _selectedSize != null) {
      final sizes = widget.equipmentData['sizes'] as List<dynamic>;
      final sizeData = sizes.firstWhere(
        (s) => s['size'] == _selectedSize,
        orElse: () => null,
      );
      return sizeData != null ? (sizeData['availableQty'] ?? 0) : 0;
    }
    return widget.equipmentData['availableQty'] ?? 0;
  }

  Future<void> _pickDate(bool isBorrowDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isBorrowDate ? _borrowDate : _returnDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() {
        if (isBorrowDate) {
          _borrowDate = picked;
        } else {
          _returnDate = picked;
        }
      });
    }
  }

  Future<void> _confirmBorrow() async {
    final hasSizes = widget.equipmentData['hasSizes'] ?? false;

    if (hasSizes && _selectedSize == null) {
      setState(() => _errorMessage = 'กรุณาเลือกขนาดที่ต้องการยืม');
      return;
    }

    if (_quantity > _maxAvailable) {
      setState(() => _errorMessage = 'จำนวนที่ยืมมากกว่าที่มีอยู่');
      return;
    }

    if (_returnDate.isBefore(_borrowDate)) {
      setState(() => _errorMessage = 'วันที่คืนต้องอยู่หลังวันที่ยืม');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = 'กรุณาเข้าสู่ระบบใหม่';
        _isLoading = false;
      });
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userName = userDoc.data()?['name'] ?? 'ไม่ทราบชื่อ';

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final equipmentRef = FirebaseFirestore.instance
            .collection('equipment')
            .doc(widget.equipmentId);
        final equipmentSnapshot = await transaction.get(equipmentRef);
        final equipmentData = equipmentSnapshot.data() as Map<String, dynamic>;

        if (hasSizes) {
          final sizes = List<Map<String, dynamic>>.from(
            equipmentData['sizes'].map((s) => Map<String, dynamic>.from(s)),
          );
          final sizeIndex =
              sizes.indexWhere((s) => s['size'] == _selectedSize);
          final currentAvailable = sizes[sizeIndex]['availableQty'] ?? 0;

          if (currentAvailable < _quantity) {
            throw Exception('จำนวนไม่พอ');
          }

          sizes[sizeIndex]['availableQty'] = currentAvailable - _quantity;

          final totalAvailable = sizes.fold<int>(
            0,
            (sum, s) => sum + ((s['availableQty'] ?? 0) as int),
          );

          transaction.update(equipmentRef, {
            'sizes': sizes,
            'availableQty': totalAvailable,
          });
        } else {
          final currentAvailable = equipmentData['availableQty'] ?? 0;
          if (currentAvailable < _quantity) {
            throw Exception('จำนวนไม่พอ');
          }
          transaction.update(equipmentRef, {
            'availableQty': currentAvailable - _quantity,
          });
        }

        // สร้างรายการยืมใหม่
        final borrowRef =
            FirebaseFirestore.instance.collection('borrow_requests').doc();
        transaction.set(borrowRef, {
          'studentId': user.uid,
          'studentName': userName,
          'equipmentId': widget.equipmentId,
          'equipmentName': widget.equipmentData['name'],
          'size': _selectedSize,
          'quantity': _quantity,
          'borrowDate': Timestamp.fromDate(_borrowDate),
          'returnDate': Timestamp.fromDate(_returnDate),
          'purpose': _purposeController.text.trim(),
          'status': 'borrowed',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // สร้างการแจ้งเตือนไปหาครู
        final notificationRef =
            FirebaseFirestore.instance.collection('notifications').doc();
        transaction.set(notificationRef, {
          'type': 'borrow',
          'studentName': userName,
          'equipmentName': widget.equipmentData['name'],
          'size': _selectedSize,
          'quantity': _quantity,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ยืมอุปกรณ์สำเร็จ')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'เกิดข้อผิดพลาด: จำนวนอุปกรณ์อาจไม่พอแล้ว';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSizes = widget.equipmentData['hasSizes'] ?? false;
    final sizes = hasSizes
        ? List<Map<String, dynamic>>.from(widget.equipmentData['sizes'])
        : <Map<String, dynamic>>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('ยืมอุปกรณ์'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.science, color: Colors.blue, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.equipmentData['name'] ?? '',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (hasSizes) ...[
              const Text(
                'เลือกขนาด',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: sizes.map((s) {
                  final size = s['size'];
                  final available = s['availableQty'] ?? 0;
                  final isSelected = _selectedSize == size;
                  return ChoiceChip(
                    label: Text('$size (เหลือ $available)'),
                    selected: isSelected,
                    selectedColor: Colors.blue,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                    onSelected: available > 0
                        ? (_) {
                            setState(() {
                              _selectedSize = size;
                              _quantity = 1;
                            });
                          }
                        : null,
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],

            const Text(
              'จำนวนที่ยืม',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: _quantity > 1
                      ? () => setState(() => _quantity--)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(
                  '$_quantity',
                  style: const TextStyle(fontSize: 18),
                ),
                IconButton(
                  onPressed: _quantity < _maxAvailable
                      ? () => setState(() => _quantity++)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
                const SizedBox(width: 8),
                Text(
                  'คงเหลือ $_maxAvailable ชิ้น',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 20),

            const Text(
              'วัตถุประสงค์ในการยืม',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _purposeController,
              decoration: InputDecoration(
                hintText: 'เช่น ทดลองปฏิบัติการเคมี',
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
              'วันที่ยืม',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _pickDate(true),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      '${_borrowDate.day}/${_borrowDate.month}/${_borrowDate.year}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'วันที่คืน (กำหนด)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _pickDate(false),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      '${_returnDate.day}/${_returnDate.month}/${_returnDate.year}',
                    ),
                  ],
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
                onPressed: _isLoading ? null : _confirmBorrow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'ยืนยันการยืม',
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