import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// 🟦 STUDENT A WORKSPACE — Caregiver: Dashboard & Request Queue
/// TODO: Replace with full implementation in Phase 2
class CaregiverDashboardScreen extends StatelessWidget {
  const CaregiverDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Requests')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Caregiver Dashboard',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '🟦 Student A workspace\nPhase 2: Accept/Decline/Complete flow',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
