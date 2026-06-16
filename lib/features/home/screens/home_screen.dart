import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/services/auth_provider.dart';
import '../../auth/screens/login_screen.dart';
import '../../caregiver_booking/screens/caregiver_list_screen.dart';
import '../../caregiver_booking/screens/health_chatbot_screen.dart';
import '../../dashboard/screens/all_orders_screen.dart';
import '../../hospital_appointment/screens/family_hospital_scheduler_screen.dart';
import '../../pharmacy_delivery/models/pharmacy_order_model.dart';
import '../../pharmacy_delivery/screens/pharmacy_list_screen.dart';
import '../../pharmacy_delivery/screens/pharmacy_my_orders_screen.dart';
import '../../pharmacy_delivery/services/pharmacy_firestore_service.dart';

/// Main shell for logged-in regular users — Gojek-style bottom navbar
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String? _lastCheckedUid;
  final _pharmacyService = PharmacyFirestoreService();

  final List<Widget> _pages = const [
    _HomePage(),
    CaregiverListScreen(),
    AllOrdersScreen(),
    HealthChatbotScreen(),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthProvider>();
    final uid = auth.currentUser?.uid;
    if (uid != null && uid != _lastCheckedUid && auth.userRole == UserRole.user) {
      _lastCheckedUid = uid;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _checkPharmacyUpdatesOnLogin(uid),
      );
    }
  }

  Future<void> _checkPharmacyUpdatesOnLogin(String uid) async {
    if (!mounted) return;
    final orders = await _pharmacyService.getActiveOrdersForUser(uid);
    if (!mounted || orders.isEmpty) return;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.notifications_active, color: Color(0xFF7B5EA7), size: 22),
            SizedBox(width: 10),
            Text(
              'Update Pesanan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pesanan farmasimu ada yang berubah status:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            ...orders.map((o) => _OrderUpdateTile(order: o)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7B5EA7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PharmacyMyOrdersScreen()),
              );
            },
            child: const Text('Lihat Pesanan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoggedIn = auth.isLoggedIn;

    if (!isLoggedIn) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(child: _GuestHomePage()),
      );
    }

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: _HealinkBottomNav(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  Bottom Navigation Bar — Gojek style
// ════════════════════════════════════════════════════════════════════════════
class _HealinkBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _HealinkBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const items = [
      _NavItem(icon: Icons.home_rounded, label: 'Beranda'),
      _NavItem(icon: Icons.medical_services_rounded, label: 'Caregiver'),
      _NavItem(icon: Icons.receipt_long_rounded, label: 'Pesanan'),
      _NavItem(icon: Icons.health_and_safety_rounded, label: 'AI Chat'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isSelected = currentIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            item.icon,
                            size: 22,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

// ════════════════════════════════════════════════════════════════════════════
//  HOME PAGE (Tab 0) — for logged-in users
// ════════════════════════════════════════════════════════════════════════════
class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Row(children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.favorite,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 8),
                          const Text('Healink',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              )),
                        ]),
                        const Spacer(),
                                        // Avatar with popup menu (profile + sign out)
                        PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'logout') auth.logout();
                          },
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'name',
                              enabled: false,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    auth.userName.isNotEmpty
                                        ? auth.userName
                                        : (auth.currentUser?.email ?? ''),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: AppColors.textPrimary),
                                  ),
                                  Text(
                                    auth.currentUser?.email ?? '',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            const PopupMenuItem(
                              value: 'logout',
                              child: Row(children: [
                                Icon(Icons.logout, size: 16,
                                    color: AppColors.cancelled),
                                SizedBox(width: 8),
                                Text('Sign Out',
                                    style:
                                        TextStyle(color: AppColors.cancelled)),
                              ]),
                            ),
                          ],
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.25),
                            child: Text(
                              (auth.userName.isNotEmpty
                                      ? auth.userName
                                      : (auth.currentUser?.email ?? 'U'))[0]
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Halo, ${auth.userName.isNotEmpty ? auth.userName.split(' ').first : auth.currentUser?.email?.split('@').first ?? ''} 👋',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Butuh layanan kesehatan hari ini?',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Quick Actions ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _QuickAction(
                      icon: Icons.medical_services_rounded,
                      label: 'Caregiver',
                      color: AppColors.primary,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const CaregiverListScreen())),
                    ),
                    const SizedBox(width: 12),
                    _QuickAction(
                      icon: Icons.local_hospital_rounded,
                      label: 'Rumah Sakit',
                      color: const Color(0xFF4A90E2),
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const FamilyHospitalSchedulerScreen())),
                    ),
                    const SizedBox(width: 12),
                    _QuickAction(
                      icon: Icons.medication_rounded,
                      label: 'Farmasi',
                      color: const Color(0xFF7B5EA7),
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const PharmacyListScreen())),
                    ),
                    const SizedBox(width: 12),
                    _QuickAction(
                      icon: Icons.health_and_safety_rounded,
                      label: 'AI Chat',
                      color: const Color(0xFF00B4A6),
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const HealthChatbotScreen())),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── AI Chatbot Banner ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const HealthChatbotScreen())),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00B4A6), Color(0xFF0097A7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.health_and_safety_rounded,
                            color: Colors.white, size: 26),
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Health Assistant AI 🤖',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700)),
                            SizedBox(height: 3),
                            Text('Tanya kebutuhan caregiver pasienmu',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios,
                          color: Colors.white70, size: 14),
                    ]),
                  ),
                ),
              ),

              // ── Layanan Unggulan ──────────────────────────────────────
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text('Layanan Unggulan',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
              ),
              const SizedBox(height: 14),

              _ServiceBanner(
                title: 'Caregiver On-Demand',
                subtitle:
                    'Tenaga perawat profesional siap datang ke rumahmu',
                icon: Icons.medical_services_rounded,
                color: AppColors.primary,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const CaregiverListScreen())),
              ),
              const SizedBox(height: 12),
              _ServiceBanner(
                title: 'Jadwal Rumah Sakit',
                subtitle: 'Booking jadwal klinik & rawat inap dengan mudah',
                icon: Icons.local_hospital_rounded,
                color: const Color(0xFF4A90E2),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const FamilyHospitalSchedulerScreen())),
              ),
              const SizedBox(height: 12),
              _ServiceBanner(
                title: 'Farmasi & Obat',
                subtitle: 'Pesan obat & suplemen, diantar ke pintu rumahmu',
                icon: Icons.medication_rounded,
                color: const Color(0xFF7B5EA7),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const PharmacyListScreen())),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  GUEST HOME PAGE (no bottom nav)
// ════════════════════════════════════════════════════════════════════════════
class _GuestHomePage extends StatelessWidget {
  const _GuestHomePage();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.favorite,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 8),
                  const Text('Healink',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5)),
                  const Spacer(),
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const LoginScreen())),
                    child: const Text('Sign In',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ),
                ]),
                const SizedBox(height: 20),
                const Text('Layanan Kesehatan\nUntuk Keluargamu 🏥',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.3)),
                const SizedBox(height: 6),
                const Text(
                    'Pesan caregiver, jadwalkan klinik, antar obat ke rumah',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              _QuickAction(
                icon: Icons.medical_services_rounded,
                label: 'Caregiver',
                color: AppColors.primary,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const CaregiverListScreen())),
              ),
              const SizedBox(width: 12),
              _QuickAction(
                icon: Icons.local_hospital_rounded,
                label: 'Rumah Sakit',
                color: const Color(0xFF4A90E2),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const FamilyHospitalSchedulerScreen())),
              ),
              const SizedBox(width: 12),
              _QuickAction(
                icon: Icons.medication_rounded,
                label: 'Farmasi',
                color: const Color(0xFF7B5EA7),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const PharmacyListScreen())),
              ),
            ]),
          ),
          const SizedBox(height: 28),

          // Sign in CTA
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppColors.primary.withValues(alpha: 0.08),
                  AppColors.primary.withValues(alpha: 0.04),
                ]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Masuk untuk fitur lengkap 🤝',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  const Text(
                      'Login untuk pesan caregiver, pantau booking, dan akses AI Health Assistant.',
                      style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4)),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen())),
                      child: const Text('Masuk / Daftar'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Mitra CTA
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen())),
              icon: const Icon(Icons.handshake_rounded),
              label: const Text('Bergabung sebagai Mitra',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  Reusable Widgets
// ════════════════════════════════════════════════════════════════════════════
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
        ]),
      ),
    );
  }
}

class _ServiceBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ServiceBanner({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 14, color: color.withValues(alpha: 0.6)),
          ]),
        ),
      ),
    );
  }
}

class _OrderUpdateTile extends StatelessWidget {
  final PharmacyOrderModel order;
  const _OrderUpdateTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final isShipped = order.status == PharmacyOrderStatus.shipped;
    final color = isShipped ? const Color(0xFF2196F3) : const Color(0xFF7B5EA7);
    final icon = isShipped ? Icons.local_shipping_outlined : Icons.inventory_2_outlined;
    final label = isShipped ? 'Sedang dikirim' : 'Sedang dikemas';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.pharmacyName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
