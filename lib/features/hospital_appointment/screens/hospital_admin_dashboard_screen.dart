import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/services/auth_provider.dart';
import '../models/appointment_model.dart';
import '../services/hospital_firestore_service.dart';

class HospitalAdminDashboardScreen extends StatefulWidget {
  const HospitalAdminDashboardScreen({super.key});

  @override
  State<HospitalAdminDashboardScreen> createState() => _HospitalAdminDashboardScreenState();
}

class _HospitalAdminDashboardScreenState extends State<HospitalAdminDashboardScreen> {
  final HospitalFirestoreService _firestoreService = HospitalFirestoreService();
  late final String _todayDateString;

  @override
  void initState() {
    super.initState();
    _todayDateString = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppColors.completed; // Blue
      case 'delayed':
        return AppColors.pending; // Orange
      case 'cancelled':
        return AppColors.cancelled; // Red
      case 'booked':
      default:
        return AppColors.accent; // Green
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final hospitalId = auth.currentUser?.uid ?? 'mock-hospital-id';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Agenda Harian Klinik'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header showing selected/today date info
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Jadwal Janji Temu Hari Ini',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Daily roster stream list builder
            Expanded(
              child: StreamBuilder<List<AppointmentModel>>(
                stream: _firestoreService.getHospitalDailyAgenda(hospitalId, _todayDateString),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          'Error loading appointments: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.cancelled),
                        ),
                      ),
                    );
                  }

                  final appointments = snapshot.data ?? [];

                  if (appointments.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_busy_rounded,
                            size: 64,
                            color: AppColors.textSecondary.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Tidak ada janji temu hari ini',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: appointments.length,
                    itemBuilder: (context, index) {
                      final appointment = appointments[index];
                      final statusColor = _getStatusColor(appointment.status);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              // Left: Time slot card indicator
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.access_time_filled_rounded,
                                      color: AppColors.primary,
                                      size: 18,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      appointment.timeSlot,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Middle: Details info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ID Keluarga: ${appointment.familyId}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        // Status badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            appointment.status.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: statusColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Right: Action Dropdown popup button
                              PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: AppColors.textSecondary,
                                ),
                                onSelected: (newStatus) async {
                                  try {
                                    await _firestoreService.updateAppointmentStatus(
                                      appointment.appointmentId,
                                      newStatus,
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Status updated to $newStatus'),
                                          backgroundColor: AppColors.accent,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Error: $e'),
                                          backgroundColor: AppColors.cancelled,
                                        ),
                                      );
                                    }
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'booked',
                                    child: Row(
                                      children: [
                                        Icon(Icons.bookmark, color: AppColors.accent, size: 18),
                                        SizedBox(width: 8),
                                        Text('Booked'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'completed',
                                    child: Row(
                                      children: [
                                        Icon(Icons.check_circle, color: AppColors.completed, size: 18),
                                        SizedBox(width: 8),
                                        Text('Completed'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delayed',
                                    child: Row(
                                      children: [
                                        Icon(Icons.watch_later, color: AppColors.pending, size: 18),
                                        SizedBox(width: 8),
                                        Text('Delayed'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'cancelled',
                                    child: Row(
                                      children: [
                                        Icon(Icons.cancel, color: AppColors.cancelled, size: 18),
                                        SizedBox(width: 8),
                                        Text('Cancelled'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
