import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// 🟥 STUDENT C WORKSPACE — Pharmacy Order Intake
class PharmacyOrderIntakeScreen extends StatelessWidget {
  const PharmacyOrderIntakeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Incoming Orders')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 64, color: AppColors.primary),
            SizedBox(height: 16),
            Text('Pharmacy Order Intake',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            SizedBox(height: 8),
            Text('🟥 Student C workspace',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
