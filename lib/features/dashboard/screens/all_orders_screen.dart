import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/services/auth_provider.dart';
import '../../caregiver_booking/screens/my_bookings_screen.dart';
import '../../pharmacy_delivery/screens/pharmacy_my_orders_screen.dart';

const _kPurple = Color(0xFF7B5EA7);

class AllOrdersScreen extends StatelessWidget {
  const AllOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final uid = auth.currentUser?.uid ?? '';
    final userName = auth.userName.isNotEmpty
        ? auth.userName
        : (auth.currentUser?.email ?? 'Pengguna');

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: const Text(
            'Pesanan Saya',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          bottom: TabBar(
            labelColor: _kPurple,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: _kPurple,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 13),
            tabs: const [
              Tab(
                icon: Icon(Icons.medication_outlined, size: 20),
                text: 'Farmasi',
              ),
              Tab(
                icon: Icon(Icons.medical_services_outlined, size: 20),
                text: 'Caregiver',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            PharmacyOrdersBody(uid: uid),
            CaregiverBookingsBody(uid: uid, userName: userName),
          ],
        ),
      ),
    );
  }
}
