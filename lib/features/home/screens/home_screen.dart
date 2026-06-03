import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/services/auth_provider.dart';
import '../../auth/screens/login_screen.dart';
import '../../caregiver_booking/screens/caregiver_list_screen.dart';
import '../../caregiver_booking/screens/my_bookings_screen.dart';
import '../../pharmacy_delivery/screens/pharmacy_list_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoggedIn = auth.isLoggedIn;

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
                    Row(children: [
                      Row(children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.favorite, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 8),
                        const Text('Healink', style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        )),
                      ]),
                      const Spacer(),
                      if (!isLoggedIn)
                        TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          onPressed: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const LoginScreen())),
                          child: const Text('Sign In', style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                        )
                      else
                        // ✅ Logged-in user: avatar + menu (Pesananku + Sign Out)
                        PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'orders') {
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const MyBookingsScreen()));
                            } else if (v == 'logout') {
                              auth.logout();
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'orders',
                              child: Row(children: const [
                                Icon(Icons.receipt_long_outlined, size: 18),
                                SizedBox(width: 8),
                                Text('Pesananku'),
                              ]),
                            ),
                            PopupMenuItem(
                              value: 'logout',
                              child: Row(children: const [
                                Icon(Icons.logout, size: 18),
                                SizedBox(width: 8),
                                Text('Sign Out'),
                              ]),
                            ),
                          ],
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white.withValues(alpha: 0.25),
                            child: Text(
                              (auth.userName.isNotEmpty
                                      ? auth.userName
                                      : (auth.currentUser?.email ?? 'U'))[0]
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                    ]),
                    const SizedBox(height: 20),
                    const Text('Layanan Kesehatan\nUntuk Keluargamu 🏥', style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    )),
                    const SizedBox(height: 6),
                    Text(
                      isLoggedIn
                          ? 'Selamat datang kembali, ${auth.userName.isNotEmpty ? auth.userName.split(' ').first : auth.currentUser?.email?.split('@').first ?? ''} 👋'
                          : 'Pesan caregiver, jadwalkan klinik, antar obat ke rumah',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Quick Access: "Pesananku" banner for logged-in users ────
              if (isLoggedIn)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const MyBookingsScreen())),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        boxShadow: [BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.06),
                          blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Row(children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.receipt_long_outlined,
                              color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Pesananku',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary)),
                          Text('Lihat & kelola semua pesanan caregivermu',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ])),
                        const Icon(Icons.arrow_forward_ios,
                            size: 14, color: AppColors.textSecondary),
                      ]),
                    ),
                  ),
                ),

              // ── Service Categories ──────────────────────────────────────
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text('Pilih Layanan', style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              ),
              const SizedBox(height: 14),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  _ServiceCard(
                    icon: Icons.medical_services_rounded,
                    label: 'Caregiver',
                    color: AppColors.primary,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const CaregiverListScreen())),
                  ),
                  const SizedBox(width: 12),
                  _ServiceCard(
                    icon: Icons.local_hospital_rounded,
                    label: 'Rumah Sakit',
                    color: const Color(0xFF4A90E2),
                    onTap: () => _showComingSoon(context, 'Rumah Sakit'),
                  ),
                  const SizedBox(width: 12),
                  _ServiceCard(
                    icon: Icons.medication_rounded,
                    label: 'Farmasi',
                    color: const Color(0xFF7B5EA7),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const PharmacyListScreen())),
                  ),
                ]),
              ),
              const SizedBox(height: 32),

              // ── How it works ────────────────────────────────────────────
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text('Cara Kerja Healink', style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              ),
              const SizedBox(height: 14),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(children: [
                  _HowItWorksStep(
                    step: '1',
                    icon: Icons.search_rounded,
                    title: 'Pilih Layanan',
                    desc: 'Cari caregiver, rumah sakit, atau farmasi terdekat',
                    color: AppColors.primary,
                  ),
                  _HowItWorksStep(
                    step: '2',
                    icon: Icons.calendar_today_rounded,
                    title: 'Buat Pesanan',
                    desc: 'Pilih jadwal, isi detail, dan konfirmasi pesanan',
                    color: const Color(0xFF4A90E2),
                  ),
                  _HowItWorksStep(
                    step: '3',
                    icon: Icons.check_circle_rounded,
                    title: 'Layanan Diberikan',
                    desc: 'Terima layanan profesional langsung di rumahmu',
                    color: AppColors.accepted,
                    isLast: true,
                  ),
                ]),
              ),
              const SizedBox(height: 32),

              // ── Mitra CTA (only for guests) ─────────────────────────────
              if (!isLoggedIn)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary.withValues(alpha: 0.08), AppColors.primary.withValues(alpha: 0.04)]),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Bergabung sebagai Mitra 🤝', style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 6),
                      const Text('Daftar sebagai caregiver dan mulai terima pesanan dari keluarga di sekitarmu.',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
                      const SizedBox(height: 14),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        onPressed: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const LoginScreen())),
                        child: const Text('Daftar sebagai Mitra', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String service) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Icon(Icons.construction_rounded, size: 48, color: AppColors.primary),
          const SizedBox(height: 12),
          Text('Layanan $service\nSegera Hadir! 🚧',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text('Fitur $service sedang dalam pengembangan oleh tim kami.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, height: 1.4)),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ServiceCard({
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
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 10),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ]),
        ),
      ),
    );
  }
}

class _HowItWorksStep extends StatelessWidget {
  final String step;
  final IconData icon;
  final String title;
  final String desc;
  final Color color;
  final bool isLast;

  const _HowItWorksStep({
    required this.step,
    required this.icon,
    required this.title,
    required this.desc,
    required this.color,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: Center(child: Text(step, style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w800, color: color))),
        ),
        if (!isLast)
          Container(width: 2, height: 40, color: AppColors.border),
      ]),
      const SizedBox(width: 14),
      Expanded(child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(
            fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
          SizedBox(height: isLast ? 0 : 16),
        ]),
      )),
    ]);
  }
}
