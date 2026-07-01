import 'package:flutter/material.dart';

class StudentDashboardV2 extends StatelessWidget {
  const StudentDashboardV2({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          "Student Dashboard V2",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}