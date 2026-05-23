import 'package:flutter/material.dart';
import '../../auth/services/auth_provider.dart';

// 🟦 Student A - Caregiver Booking
import '../../caregiver_booking/screens/family_caregiver_list_screen.dart';
import '../../caregiver_booking/screens/caregiver_dashboard_screen.dart';

// 🟩 Student B - Hospital Appointment (placeholders)
import '../../hospital_appointment/screens/family_hospital_scheduler_screen.dart';
import '../../hospital_appointment/screens/hospital_admin_dashboard_screen.dart';

// 🟥 Student C - Pharmacy Delivery (placeholders)
import '../../pharmacy_delivery/screens/family_pharmacy_catalog_screen.dart';
import '../../pharmacy_delivery/screens/pharmacy_order_intake_screen.dart';

class RoleRouterScaffold extends StatefulWidget {
  final UserRole userRole;
  const RoleRouterScaffold({super.key, required this.userRole});

  @override
  State<RoleRouterScaffold> createState() => _RoleRouterScaffoldState();
}

class _RoleRouterScaffoldState extends State<RoleRouterScaffold> {
  int _currentIndex = 0;

  List<Widget> get _screens {
    switch (widget.userRole) {
      case UserRole.family:
        return [
          const FamilyCaregiverListScreen(),
          const FamilyHospitalSchedulerScreen(),
          const FamilyPharmacyCatalogScreen(),
        ];
      case UserRole.caregiver:
        return [
          const CaregiverDashboardScreen(),
        ];
      case UserRole.hospital:
        return [
          const HospitalAdminDashboardScreen(),
        ];
      case UserRole.pharmacy:
        return [
          const PharmacyOrderIntakeScreen(),
        ];
    }
  }

  List<BottomNavigationBarItem> get _navItems {
    switch (widget.userRole) {
      case UserRole.family:
        return const [
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services_outlined),
            activeIcon: Icon(Icons.medical_services),
            label: 'Caregivers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_hospital_outlined),
            activeIcon: Icon(Icons.local_hospital),
            label: 'Hospitals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medication_outlined),
            activeIcon: Icon(Icons.medication),
            label: 'Pharmacy',
          ),
        ];
      case UserRole.caregiver:
        return const [
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'My Requests',
          ),
        ];
      case UserRole.hospital:
        return const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Schedule',
          ),
        ];
      case UserRole.pharmacy:
        return const [
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            activeIcon: Icon(Icons.shopping_bag),
            label: 'Orders',
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = _screens;
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: screens.length > 1
          ? BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
              items: _navItems,
            )
          : null,
    );
  }
}
