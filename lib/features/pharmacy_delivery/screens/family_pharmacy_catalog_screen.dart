import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// 🟥 STUDENT C WORKSPACE — Pharmacy Catalog
class FamilyPharmacyCatalogScreen extends StatelessWidget {
  const FamilyPharmacyCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pharmacy')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.medication_outlined, size: 64, color: AppColors.primary),
            SizedBox(height: 16),
            Text('Pharmacy Catalog',
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
