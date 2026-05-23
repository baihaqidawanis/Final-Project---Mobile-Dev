import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// 🟦 STUDENT A WORKSPACE — Family: Browse Caregiver List
/// TODO: Replace with full implementation in Phase 2
class FamilyCaregiverListScreen extends StatelessWidget {
  const FamilyCaregiverListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find a Caregiver')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.medical_services_outlined,
                size: 64, color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Caregiver List',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '🟦 Student A workspace\nPhase 2: Full CRUD implementation',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
