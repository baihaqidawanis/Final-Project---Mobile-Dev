import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// 🟩 STUDENT B WORKSPACE — Hospital Appointment
/// Placeholder screen. Student B will implement the full cinema-seat
/// scheduling UI here.
class FamilyHospitalSchedulerScreen extends StatelessWidget {
  const FamilyHospitalSchedulerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hospitals')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_hospital_outlined,
                size: 64, color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Hospital Scheduling',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '🟩 Student B workspace',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
