import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/services/auth_provider.dart';
import '../models/appointment_model.dart';
import '../services/hospital_firestore_service.dart';
import '../theme/hospital_colors.dart';

class HospitalAdminDashboardScreen extends StatefulWidget {
  const HospitalAdminDashboardScreen({super.key});

  @override
  State<HospitalAdminDashboardScreen> createState() => _HospitalAdminDashboardScreenState();
}

class _HospitalAdminDashboardScreenState extends State<HospitalAdminDashboardScreen> {
  final HospitalFirestoreService _firestoreService = HospitalFirestoreService();
  DateTime _selectedDate = DateTime.now();
  int _currentIndex = 0;

  String get _selectedDateString => DateFormat('yyyy-MM-dd').format(_selectedDate);

  final List<String> _timeSlots = [
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
  ];

  @override
  void initState() {
    super.initState();
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

  void _showOfflineBookingBottomSheet(
    BuildContext context,
    String slot,
    String hospitalId,
  ) {
    final nameController = TextEditingController();
    final symptomsController = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.border,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Pesan Offline (Slot $slot)',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        const Divider(),
                        const SizedBox(height: 12),
                        const Text(
                          'Nama Pasien',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            hintText: 'Nama pasien...',
                            prefixIcon: const Icon(
                              Icons.person_outline_rounded,
                              color: HospitalColors.primary,
                            ),
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Keluhan Utama / Catatan',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: symptomsController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Catatan keluhan pasien...',
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: HospitalColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            onPressed: isSaving
                                ? null
                                : () async {
                                    final name = nameController.text.trim();
                                    if (name.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Nama pasien harus diisi'),
                                          backgroundColor: AppColors.cancelled,
                                        ),
                                      );
                                      return;
                                    }
                                    setModalState(() {
                                      isSaving = true;
                                    });

                                    final appointment = AppointmentModel(
                                      appointmentId: '',
                                      familyId: 'offline',
                                      hospitalId: hospitalId,
                                      dateString: _selectedDateString,
                                      timeSlot: slot,
                                      status: 'booked',
                                      patientName: name,
                                      symptoms: symptomsController.text.trim(),
                                    );

                                    try {
                                      await _firestoreService.createAppointment(appointment);
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Janji temu offline berhasil disimpan'),
                                            backgroundColor: AppColors.accent,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      setModalState(() {
                                        isSaving = false;
                                      });
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Gagal menyimpan: $e'),
                                            backgroundColor: AppColors.cancelled,
                                          ),
                                        );
                                      }
                                    }
                                  },
                            child: isSaving
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    'Simpan Janji Temu',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showReleaseSlotDialog(BuildContext context, AppointmentModel appointment) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Batalkan / Lepas Slot'),
          content: Text(
            'Apakah Anda yakin ingin membatalkan janji temu untuk ${appointment.patientName} (${appointment.timeSlot})?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await _firestoreService.cancelAppointment(appointment.appointmentId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Janji temu berhasil dibatalkan'),
                        backgroundColor: AppColors.accent,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal membatalkan: $e'),
                        backgroundColor: AppColors.cancelled,
                      ),
                    );
                  }
                }
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.cancelled),
              child: const Text('Lepaskan Slot'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final hospitalId = auth.currentUser!.id;

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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: Colors.white,
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Jadwal Janji Temu',
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
                            DateFormat('EEEE, d MMMM yyyy').format(_selectedDate),
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
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, color: HospitalColors.primary),
                        tooltip: 'Hari Sebelumnya',
                        onPressed: () {
                          setState(() {
                            _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.date_range_rounded, color: HospitalColors.primary),
                        tooltip: 'Pilih Tanggal',
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            builder: (context, child) {
                              return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: HospitalColors.primary,
                                      onPrimary: Colors.white,
                                      onSurface: AppColors.textPrimary,
                                    ),
                                  ),
                                  child: child!,
                                );
                            },
                          );
                          if (picked != null) {
                            setState(() {
                              _selectedDate = picked;
                            });
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, color: HospitalColors.primary),
                        tooltip: 'Hari Berikutnya',
                        onPressed: () {
                          setState(() {
                            _selectedDate = _selectedDate.add(const Duration(days: 1));
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Tab View Content using IndexedStack to preserve view states
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  // View 0: Agenda Hari Ini
                  StreamBuilder<List<AppointmentModel>>(
                    stream: _firestoreService.getHospitalDailyAgenda(hospitalId, _selectedDateString),
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
                                      color: HospitalColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: [
                                        const Icon(
                                          Icons.access_time_filled_rounded,
                                          color: HospitalColors.primary,
                                          size: 18,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          appointment.timeSlot,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: HospitalColors.primary,
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
                                        FutureBuilder<DocumentSnapshot>(
                                          future: appointment.familyId == 'offline'
                                              ? null
                                              : FirebaseFirestore.instance.collection('users').doc(appointment.familyId).get(),
                                          builder: (context, userSnapshot) {
                                            String displayName = 'Memuat nama...';
                                            if (appointment.familyId == 'offline') {
                                              displayName = appointment.patientName;
                                            } else if (userSnapshot.connectionState == ConnectionState.done) {
                                              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                                                final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                                                displayName = userData?['name'] ?? appointment.familyId;
                                              } else {
                                                displayName = appointment.familyId; // Fallback to ID
                                              }
                                            }
                                            final patientName = appointment.patientName.isNotEmpty
                                                ? appointment.patientName
                                                : displayName;
                                            return Text(
                                              'Pasien: $patientName',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimary,
                                              ),
                                            );
                                          },
                                        ),
                                        if (appointment.symptoms.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Keluhan: ${appointment.symptoms}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
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

                  // View 1: Kelola Slot Waktu
                  StreamBuilder<List<AppointmentModel>>(
                    stream: _firestoreService.getHospitalDailyAgenda(hospitalId, _selectedDateString),
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

                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.25,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _timeSlots.length,
                        itemBuilder: (context, index) {
                          final slot = _timeSlots[index];
                          final appointmentIndex = appointments.indexWhere((a) => a.timeSlot == slot);
                          final hasAppointment = appointmentIndex != -1;
                          final appointment = hasAppointment ? appointments[appointmentIndex] : null;

                          final isOffline = hasAppointment && appointment?.familyId == 'offline';

                          return GestureDetector(
                            onTap: () {
                              if (hasAppointment) {
                                _showReleaseSlotDialog(context, appointment!);
                              } else {
                                _showOfflineBookingBottomSheet(context, slot, hospitalId);
                              }
                            },
                            child: Card(
                              margin: EdgeInsets.zero,
                              color: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: hasAppointment
                                      ? (isOffline ? AppColors.pending : HospitalColors.primary)
                                      : AppColors.accent.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Slot Header
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          slot,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        Icon(
                                          hasAppointment
                                              ? (isOffline
                                                  ? Icons.offline_pin_rounded
                                                  : Icons.online_prediction_rounded)
                                              : Icons.add_circle_outline_rounded,
                                          size: 20,
                                          color: hasAppointment
                                              ? (isOffline ? AppColors.pending : HospitalColors.primary)
                                              : AppColors.accent,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    // Details
                                    if (hasAppointment) ...[
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              appointment!.patientName.isNotEmpty
                                                  ? appointment.patientName
                                                  : 'Pasien Online',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              isOffline ? 'Walk-in (Offline)' : 'Booking Online',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: isOffline ? AppColors.pending : HospitalColors.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ] else ...[
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Tersedia',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.accent,
                                              ),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              'Ketuk untuk pesan',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: HospitalColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_rounded),
            label: 'Agenda Hari Ini',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Kelola Slot',
          ),
        ],
      ),
    );
  }
}
