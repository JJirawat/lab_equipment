import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MyBorrowedScreen extends StatefulWidget {
  const MyBorrowedScreen({super.key});

  @override
  State<MyBorrowedScreen> createState() => _MyBorrowedScreenState();
}

class _MyBorrowedScreenState extends State<MyBorrowedScreen> {
  String? _processingId; // เก็บ id ที่กำลังกดคืนอยู่ (กันกดซ้ำ)

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '-';
    return DateFormat('d MMM yyyy').format(timestamp.toDate());
  }

  Future<void> _returnEquipment(
    String borrowId,
    String equipmentId,
    String? size,
    int quantity,
  ) async {
    setState(() => _processingId = borrowId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final equipmentRef =
            FirebaseFirestore.instance.collection('equipment').doc(equipmentId);
        final equipmentSnapshot = await transaction.get(equipmentRef);
        final equipmentData = equipmentSnapshot.data() as Map<String, dynamic>;

        final hasSizes = equipmentData['hasSizes'] ?? false;

        if (hasSizes && size != null) {
          final sizes = List<Map<String, dynamic>>.from(
            equipmentData['sizes'].map((s) => Map<String, dynamic>.from(s)),
          );
          final sizeIndex = sizes.indexWhere((s) => s['size'] == size);
          if (sizeIndex != -1) {
            final currentAvailable = sizes[sizeIndex]['availableQty'] ?? 0;
            sizes[sizeIndex]['availableQty'] = currentAvailable + quantity;

            final totalAvailable = sizes.fold<int>(
              0,
              (sum, s) => sum + ((s['availableQty'] ?? 0) as int),
            );

            transaction.update(equipmentRef, {
              'sizes': sizes,
              'availableQty': totalAvailable,
            });
          }
        } else {
          final currentAvailable = equipmentData['availableQty'] ?? 0;
          transaction.update(equipmentRef, {
            'availableQty': currentAvailable + quantity,
          });
        }

        // อัปเดตสถานะการยืมเป็น "คืนแล้ว"
        final borrowRef =
            FirebaseFirestore.instance.collection('borrow_requests').doc(borrowId);
        transaction.update(borrowRef, {
          'status': 'returned',
          'returnedAt': FieldValue.serverTimestamp(),
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('คืนอุปกรณ์สำเร็จ')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เกิดข้อผิดพลาด ลองอีกครั้ง')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processingId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายการยืมของฉัน'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('borrow_requests')
            .where('studentId', isEqualTo: user?.uid)
            .where('status', isEqualTo: 'borrowed')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('ยังไม่มีรายการที่ยืมอยู่'));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final equipmentName = data['equipmentName'] ?? '';
              final size = data['size'];
              final quantity = data['quantity'] ?? 0;
              final borrowDate = data['borrowDate'] as Timestamp?;
              final returnDate = data['returnDate'] as Timestamp?;
              final isProcessing = _processingId == doc.id;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.science, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$equipmentName${size != null ? ' ($size)' : ''}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'กำลังยืม',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('จำนวน $quantity ชิ้น',
                        style: TextStyle(color: Colors.grey.shade700)),
                    const SizedBox(height: 4),
                    Text(
                      'ยืมเมื่อ ${_formatDate(borrowDate)}  •  กำหนดคืน ${_formatDate(returnDate)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: ElevatedButton(
                        onPressed: isProcessing
                            ? null
                            : () => _returnEquipment(
                                  doc.id,
                                  data['equipmentId'],
                                  size,
                                  quantity,
                                ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: isProcessing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'คืนอุปกรณ์',
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}