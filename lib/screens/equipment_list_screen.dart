import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'borrow_screen.dart';

class EquipmentListScreen extends StatefulWidget {
  final bool isTeacher; // true = ครู (ไม่มีปุ่มยืม), false = นักเรียน (มีปุ่มยืม)

  const EquipmentListScreen({super.key, this.isTeacher = false});

  @override
  State<EquipmentListScreen> createState() => _EquipmentListScreenState();
}

class _EquipmentListScreenState extends State<EquipmentListScreen> {
  String _selectedCategory = 'ทั้งหมด';
  String _searchText = '';

  final List<String> _categories = ['ทั้งหมด', 'แก้ว', 'เครื่องมือ', 'อื่นๆ'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายการอุปกรณ์'),
      ),
      body: Column(
        children: [
          // ช่องค้นหา
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                setState(() => _searchText = value.trim());
              },
              decoration: InputDecoration(
                hintText: 'ค้นหาอุปกรณ์...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ตัวกรองหมวดหมู่
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: Colors.blue,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                    onSelected: (_) {
                      setState(() => _selectedCategory = cat);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // รายการอุปกรณ์แบบกริด (ดึงข้อมูล realtime จาก Firestore)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('equipment')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('ยังไม่มีอุปกรณ์ในระบบ'));
                }

                // กรองข้อมูลตามหมวดหมู่และคำค้นหา
                final items = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final category = data['category'] ?? '';

                  final matchCategory = _selectedCategory == 'ทั้งหมด' ||
                      category == _selectedCategory;
                  final matchSearch = _searchText.isEmpty ||
                      name.contains(_searchText.toLowerCase());

                  return matchCategory && matchSearch;
                }).toList();

                if (items.isEmpty) {
                  return const Center(child: Text('ไม่พบอุปกรณ์ที่ค้นหา'));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final doc = items[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final name = data['name'] ?? '';
                    final availableQty = data['availableQty'] ?? 0;
                    final category = data['category'] ?? '';

                    // เลือกไอคอนตามหมวดหมู่
                    IconData icon = Icons.science;
                    if (category == 'แก้ว') icon = Icons.science_outlined;
                    if (category == 'เครื่องมือ') icon = Icons.build_outlined;

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
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
                          // รูป/ไอคอนอุปกรณ์
                          Container(
                            height: 80,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                            child: Icon(icon, size: 40, color: Colors.blue),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'คงเหลือ $availableQty ชิ้น',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: availableQty > 0
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // ปุ่มยืม แสดงเฉพาะนักเรียน และของต้องเหลืออยู่
                                if (!widget.isTeacher)
                                  SizedBox(
                                    width: double.infinity,
                                    height: 32,
                                    child: ElevatedButton(
                                      onPressed: availableQty > 0
                                          ? () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      BorrowScreen(
                                                    equipmentId: doc.id,
                                                    equipmentData: data,
                                                  ),
                                                ),
                                              );
                                            }
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        padding: EdgeInsets.zero,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        availableQty > 0
                                            ? 'ยืม'
                                            : 'ของไม่พอ',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}