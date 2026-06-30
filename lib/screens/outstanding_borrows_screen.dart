import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class OutstandingBorrowsScreen extends StatelessWidget {
  const OutstandingBorrowsScreen({super.key});

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '-';
    return DateFormat('d MMM yyyy').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('นักเรียนที่ยังไม่คืน'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('borrow_requests')
            .where('status', isEqualTo: 'borrowed')
            .orderBy('returnDate')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('ไม่มีรายการที่ค้างยืมอยู่ 🎉'),
            );
          }

          final docs = snapshot.data!.docs;
          final now = DateTime.now();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final studentName = data['studentName'] ?? 'ไม่ทราบชื่อ';
              final equipmentName = data['equipmentName'] ?? '';
              final size = data['size'];
              final quantity = data['quantity'] ?? 0;
              final borrowDate = data['borrowDate'] as Timestamp?;
              final returnDate = data['returnDate'] as Timestamp?;

              final isOverdue =
                  returnDate != null && returnDate.toDate().isBefore(now);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isOverdue
                        ? Colors.red.shade200
                        : Colors.grey.shade200,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.08),
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
                        CircleAvatar(
                          backgroundColor: isOverdue
                              ? Colors.red.shade50
                              : Colors.blue.shade50,
                          child: Icon(
                            Icons.person,
                            color: isOverdue ? Colors.red : Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                studentName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                '$equipmentName${size != null ? ' ($size)' : ''} x$quantity',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isOverdue)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'เกินกำหนด',
                              style: TextStyle(color: Colors.red, fontSize: 11),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'ยืมเมื่อ ${_formatDate(borrowDate)}  •  กำหนดคืน ${_formatDate(returnDate)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isOverdue ? Colors.red : Colors.grey.shade600,
                        fontWeight:
                            isOverdue ? FontWeight.w600 : FontWeight.normal,
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