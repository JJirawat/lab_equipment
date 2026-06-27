import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _classController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _role = 'student'; // ค่าเริ่มต้นคือนักเรียน
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _register() async {
    final isStudent = _role == 'student';

    if (_nameController.text.trim().isEmpty ||
        _studentIdController.text.trim().isEmpty ||
        (isStudent && _classController.text.trim().isEmpty) ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'กรุณากรอกข้อมูลให้ครบ';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // แปลงรหัสนักเรียนเป็นอีเมลปลอม เพื่อใช้ login กับ Firebase Auth
    final fakeEmail = '${_studentIdController.text.trim()}@labapp.local';

    try {
      // สร้างบัญชีผู้ใช้ใน Firebase Authentication
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: fakeEmail,
        password: _passwordController.text.trim(),
      );

      // เก็บข้อมูลเพิ่มเติมไว้ใน Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
        'name': _nameController.text.trim(),
        'studentId': _studentIdController.text.trim(),
        'class': isStudent ? _classController.text.trim() : '',
        'realEmail': _emailController.text.trim(),
        'role': _role,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context); // กลับไปหน้า Login หลังสมัครสำเร็จ
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e.code);
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'รหัสนักเรียนนี้มีบัญชีอยู่แล้ว';
      case 'weak-password':
        return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
      default:
        return 'สมัครสมาชิกไม่สำเร็จ ลองอีกครั้ง';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isStudent = _role == 'student';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'สมัครสมาชิก',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'สร้างบัญชีเพื่อใช้งาน',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),

            // เลือกบทบาท
            Row(
              children: [
                Expanded(
                  child: _roleButton('student', 'นักเรียน', Icons.school),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _roleButton('teacher', 'ครู', Icons.person),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildTextField(
              controller: _nameController,
              hint: 'ชื่อ-นามสกุล',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _studentIdController,
              hint: 'รหัสนักเรียน / รหัสครู',
              icon: Icons.badge_outlined,
            ),
            const SizedBox(height: 16),

            // ช่องชั้นเรียน แสดงเฉพาะตอนเลือกบทบาทนักเรียน
            if (isStudent) ...[
              _buildTextField(
                controller: _classController,
                hint: 'ชั้นเรียน (เช่น ม.6/1)',
                icon: Icons.class_outlined,
              ),
              const SizedBox(height: 16),
            ],

            _buildTextField(
              controller: _emailController,
              hint: 'อีเมล',
              icon: Icons.email_outlined,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _passwordController,
              hint: 'รหัสผ่าน',
              icon: Icons.lock_outline,
              obscure: true,
            ),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'สมัครสมาชิก',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _roleButton(String value, String label, IconData icon) {
    final isSelected = _role == value;
    return GestureDetector(
      onTap: () => setState(() => _role = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}