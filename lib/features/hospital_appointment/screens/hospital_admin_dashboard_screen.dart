import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// 🟩 STUDENT B WORKSPACE — Hospital Admin Dashboard
class HospitalAdminDashboardScreen extends StatelessWidget {
  const HospitalAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clinic Schedule')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_month_outlined,
                size: 64, color: AppColors.primary),
            SizedBox(height: 16),
            Text('Hospital Admin Dashboard',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            SizedBox(height: 8),
            Text('🟩 Student B workspace',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
