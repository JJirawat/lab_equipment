import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (mounted) {
      setState(() {
        _notificationsEnabled = doc.data()?['notificationsEnabled'] ?? true;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateNotificationSetting(bool value) async {
    setState(() => _notificationsEnabled = value);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({'notificationsEnabled': value});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('ตั้งค่า'),
        backgroundColor: Colors.grey.shade50,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _sectionTitle('การแจ้งเตือน'),
                _settingsCard([
                  _switchRow(
                    icon: Icons.notifications_outlined,
                    label: 'เปิดการแจ้งเตือน',
                    subtitle: 'รับการแจ้งเตือนเมื่อมีรายการยืม-คืน',
                    value: _notificationsEnabled,
                    onChanged: _updateNotificationSetting,
                  ),
                ]),
                const SizedBox(height: 20),

                _sectionTitle('การแสดงผล'),
                _settingsCard([
                  _navRow(
                    icon: Icons.dark_mode_outlined,
                    label: 'ธีมแอป',
                    trailing: 'สว่าง',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ฟีเจอร์นี้กำลังพัฒนา')),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _navRow(
                    icon: Icons.language_outlined,
                    label: 'ภาษา',
                    trailing: 'ไทย',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ฟีเจอร์นี้กำลังพัฒนา')),
                      );
                    },
                  ),
                ]),
                const SizedBox(height: 20),

                _sectionTitle('เกี่ยวกับ'),
                _settingsCard([
                  _navRow(
                    icon: Icons.info_outline,
                    label: 'เวอร์ชันแอป',
                    trailing: '1.0.0',
                    onTap: null,
                  ),
                ]),
              ],
            ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _settingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(children: children),
    );
  }

  Widget _switchRow({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Colors.grey.shade700),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: Colors.blue,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _navRow({
    required IconData icon,
    required String label,
    required String trailing,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: Colors.grey.shade700),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ),
            Text(trailing, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
            ],
          ],
        ),
      ),
    );
  }
}