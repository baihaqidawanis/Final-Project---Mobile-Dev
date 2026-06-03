import 'package:flutter/material.dart';
import '../../auth/services/auth_provider.dart';

// 🟦 Student A - Caregiver Booking
import '../../caregiver_booking/screens/caregiver_dashboard_screen.dart';
import '../../caregiver_booking/screens/caregiver_history_screen.dart';

// 🟩 Student B - Hospital Appointment
import '../../hospital_appointment/screens/hospital_admin_dashboard_screen.dart';

// 🟥 Student C - Pharmacy Delivery
import '../../pharmacy_delivery/screens/pharmacy_order_intake_screen.dart';

/// RoleRouterScaffold is only for MITRA roles:
/// caregiver, hospital, pharmacy
/// Admin → AdminDashboardScreen (handled in AppGate)
/// User  → HomeScreen (handled in AppGate)
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
      case UserRole.caregiver:
        return const [
          CaregiverDashboardScreen(),
          CaregiverHistoryScreen(),
        ];
      case UserRole.hospital:
        return [const HospitalAdminDashboardScreen()];
      case UserRole.pharmacy:
        return [const PharmacyOrderIntakeScreen()];
      default:
        return [const CaregiverDashboardScreen()];
    }
  }

  List<BottomNavigationBarItem> get _navItems {
    switch (widget.userRole) {
      case UserRole.caregiver:
        return const [
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            activeIcon: Icon(Icons.history_rounded),
            label: 'Riwayat',
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
      default:
        return const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = _screens;
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: screens.length > 1
          ? BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
              selectedItemColor: const Color(0xFF00B4A6),
              unselectedItemColor: const Color(0xFF6B7F7E),
              type: BottomNavigationBarType.fixed,
              elevation: 12,
              items: _navItems,
            )
          : null,
    );
  }
}
