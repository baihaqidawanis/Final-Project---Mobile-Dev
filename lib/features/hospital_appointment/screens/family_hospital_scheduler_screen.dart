import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../app_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/services/auth_provider.dart';
import '../models/appointment_model.dart';
import '../services/hospital_firestore_service.dart';
import '../theme/hospital_colors.dart';
import '../widgets/calendar_picker.dart';
import '../widgets/cinema_seat_grid.dart';

class FamilyHospitalSchedulerScreen extends StatefulWidget {
  const FamilyHospitalSchedulerScreen({super.key});

  @override
  State<FamilyHospitalSchedulerScreen> createState() =>
      _FamilyHospitalSchedulerScreenState();
}

class _FamilyHospitalSchedulerScreenState
    extends State<FamilyHospitalSchedulerScreen> {
  final HospitalFirestoreService _firestoreService = HospitalFirestoreService();

  String? _selectedHospitalId;
  bool _selectedHospitalIdInitialized = false;
  late DateTime _selectedDate;
  String? _selectedSlot;
  bool _isBooking = false;
  String _weatherForecast = 'Loading weather...';
  late final Stream<QuerySnapshot> _hospitalsStream;

  String? _lastQueriedHospitalId;
  String? _lastQueriedDateString;
  Stream<List<AppointmentModel>>? _agendaStream;

  final TextEditingController _patientNameController = TextEditingController();
  final TextEditingController _symptomsController = TextEditingController();
  
  int _currentNavigationIndex = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // The last slot starts at 17:00. If it is 17:00 or later, default selected date to tomorrow.
    if (now.hour >= 17) {
      _selectedDate = now.add(const Duration(days: 1));
    } else {
      _selectedDate = now;
    }
    _fetchWeather();
    _hospitalsStream = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'hospital')
        .snapshots();
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    _symptomsController.dispose();
    super.dispose();
  }

  String _formatDateString(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> _fetchWeather() async {
    setState(() {
      _weatherForecast = 'Loading weather...';
    });
    try {
      final weather = await AppConfig.weatherRepository.getWeatherForDate(
        _formatDateString(_selectedDate),
      );
      if (mounted) {
        setState(() {
          _weatherForecast = weather;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _weatherForecast = 'Weather data unavailable';
        });
      }
    }
  }

  Future<void> _handleBookAppointment(String familyId) async {
    if (_isBooking || _selectedSlot == null || _selectedHospitalId == null) {
      return;
    }

    setState(() {
      _isBooking = true;
    });

    final appointment = AppointmentModel(
      appointmentId: '', // Firestore auto-generates this doc ID
      familyId: familyId,
      hospitalId: _selectedHospitalId!,
      dateString: _formatDateString(_selectedDate),
      timeSlot: _selectedSlot!,
      status: 'booked',
      patientName: _patientNameController.text.trim(),
      symptoms: _symptomsController.text.trim(),
    );

    try {
      await _firestoreService.createAppointment(appointment);
      if (mounted) {
        setState(() {
          _selectedSlot = null;
          _patientNameController.clear();
          _symptomsController.clear();
          _isBooking = false;
          // Switch to My Appointments tab to see status
          _currentNavigationIndex = 1;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Janji temu berhasil tersimpan'),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isBooking = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat janji temu: $e'),
            backgroundColor: AppColors.cancelled,
          ),
        );
      }
    }
  }

  void _showHospitalSearchBottomSheet(
    BuildContext context,
    List<Map<String, String>> hospitals,
  ) {
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredHospitals = hospitals.where((hospital) {
              final name = hospital['name']?.toLowerCase() ?? '';
              return name.contains(searchQuery.toLowerCase());
            }).toList();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle Bar
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Title and Close Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Pilih Rumah Sakit',
                            style: TextStyle(
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
                    ),
                    const SizedBox(height: 8),

                    // Search Input
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Cari rumah sakit...',
                          prefixIcon: const Icon(
                            Icons.search_rounded,
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
                        onChanged: (value) {
                          setModalState(() {
                            searchQuery = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // List of hospitals
                    Flexible(
                      child: filteredHospitals.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.local_hospital_outlined,
                                    size: 48,
                                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Tidak ada rumah sakit yang cocok',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                              itemCount: filteredHospitals.length,
                              itemBuilder: (context, index) {
                                final hospital = filteredHospitals[index];
                                final isSelected = hospital['id'] == _selectedHospitalId;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? HospitalColors.primary.withValues(alpha: 0.05)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? HospitalColors.primary
                                          : AppColors.border,
                                      width: isSelected ? 1.5 : 1.0,
                                    ),
                                  ),
                                  child: ListTile(
                                    leading: hospital['photoUrl'] != null && hospital['photoUrl']!.isNotEmpty
                                        ? CircleAvatar(
                                            radius: 14,
                                            backgroundImage: CachedNetworkImageProvider(hospital['photoUrl']!),
                                          )
                                        : Icon(
                                            Icons.local_hospital_outlined,
                                            color: isSelected
                                                ? HospitalColors.primary
                                                : AppColors.textSecondary,
                                          ),
                                    title: Text(
                                      hospital['name']!,
                                      style: TextStyle(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        color: isSelected
                                            ? HospitalColors.primary
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                    trailing: isSelected
                                        ? const Icon(
                                            Icons.check_circle_rounded,
                                            color: HospitalColors.primary,
                                          )
                                        : null,
                                    onTap: () {
                                      setState(() {
                                        _selectedHospitalId = hospital['id'];
                                        _selectedSlot = null; // Reset selection
                                      });
                                      _fetchWeather();
                                      Navigator.pop(context);
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showBookingConfirmationModal(
    BuildContext context,
    String familyId,
    String selectedHospitalName,
  ) {
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
                        // Handle Bar
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

                        // Title
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Konfirmasi Janji Temu',
                              style: TextStyle(
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

                        // Booking summary details
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: HospitalColors.primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: HospitalColors.primary.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.local_hospital_rounded, color: HospitalColors.primary),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      selectedHospitalName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_month_rounded, color: HospitalColors.primary),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      DateFormat('EEEE, d MMMM yyyy').format(_selectedDate),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.access_time_filled_rounded, color: HospitalColors.primary),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Slot Waktu: $_selectedSlot',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: HospitalColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Patient Name input field
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
                          controller: _patientNameController,
                          decoration: InputDecoration(
                            hintText: 'Masukkan nama pasien...',
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

                        // Complaint / Symptoms input field
                        const Text(
                          'Keluhan Utama / Gejala',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _symptomsController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Tuliskan keluhan atau gejala yang dialami...',
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

                        // Action Button
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
                            onPressed: _isBooking
                                ? null
                                : () async {
                                    setModalState(() {});
                                    Navigator.pop(context);
                                    await _handleBookAppointment(familyId);
                                  },
                            child: _isBooking
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    'Konfirmasi Jadwal',
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

  void _confirmCancelAppointment(BuildContext context, String appointmentId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Batalkan Janji Temu'),
          content: const Text('Apakah Anda yakin ingin membatalkan janji temu ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tidak'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await _firestoreService.cancelAppointment(appointmentId);
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
                        content: Text('Gagal membatalkan janji temu: $e'),
                        backgroundColor: AppColors.cancelled,
                      ),
                    );
                  }
                }
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.cancelled),
              child: const Text('Ya, Batalkan'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAppointmentsList(String familyId) {
    return StreamBuilder<List<AppointmentModel>>(
      stream: _firestoreService.getFamilyAppointments(familyId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Gagal memuat janji temu: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.cancelled),
              ),
            ),
          );
        }

        final appointments = snapshot.data ?? [];

        if (appointments.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_rounded,
                    size: 64,
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum ada janji temu terdaftar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Silakan jadwalkan kunjungan Anda di tab "Jadwalkan".',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            final appointment = appointments[index];
            
            Color statusColor;
            switch (appointment.status.toLowerCase()) {
              case 'approved':
                statusColor = AppColors.primary;
                break;
              case 'completed':
                statusColor = AppColors.completed;
                break;
              case 'delayed':
                statusColor = AppColors.pending;
                break;
              case 'cancelled':
                statusColor = AppColors.cancelled;
                break;
              case 'booked':
              default:
                statusColor = AppColors.accent;
                break;
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hospital Name fetched from users collection
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(appointment.hospitalId)
                          .get(),
                      builder: (context, hospitalSnapshot) {
                        String hospitalName = 'Memuat nama rumah sakit...';
                        if (hospitalSnapshot.connectionState == ConnectionState.done) {
                          if (hospitalSnapshot.hasData && hospitalSnapshot.data!.exists) {
                            final data = hospitalSnapshot.data!.data() as Map<String, dynamic>?;
                            hospitalName = data?['name'] ?? 'Rumah Sakit Tanpa Nama';
                          } else {
                            hospitalName = 'Rumah Sakit Tidak Ditemukan';
                          }
                        }
                        return Text(
                          hospitalName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    
                    // Date & Time
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 16, color: HospitalColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          appointment.dateString,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.access_time_rounded, size: 16, color: HospitalColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          appointment.timeSlot,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Patient Detail Info
                    Text(
                      'Pasien: ${appointment.patientName}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (appointment.symptoms.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Keluhan: ${appointment.symptoms}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    if (appointment.statusReason.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Alasan: ${appointment.statusReason}',
                        style: TextStyle(
                          fontSize: 13,
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    
                    // Status badge and cancel button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
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
                        if (appointment.status.toLowerCase() == 'booked')
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.cancelled,
                              side: const BorderSide(color: AppColors.cancelled),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                            onPressed: () => _confirmCancelAppointment(context, appointment.appointmentId),
                            child: const Text(
                               'Batalkan',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final familyId = auth.currentUser?.uid ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream: _hospitalsStream,
      builder: (context, hospitalSnapshot) {
        if (hospitalSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (hospitalSnapshot.hasError) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Gagal memuat daftar rumah sakit: ${hospitalSnapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.cancelled),
                ),
              ),
            ),
          );
        }

        final docs = hospitalSnapshot.data?.docs ?? [];
        final hospitals = docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'name': data['name'] as String? ?? 'Rumah Sakit Tanpa Nama',
            'photoUrl': data['photoUrl'] as String? ?? '',
          };
        }).toList();

        if (hospitals.isEmpty) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.local_hospital_outlined,
                      size: 64,
                      color: AppColors.textSecondary.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Belum ada rumah sakit terdaftar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Auto-initialize selected hospital
        if (!_selectedHospitalIdInitialized) {
          _selectedHospitalId = hospitals.first['id'];
          _selectedHospitalIdInitialized = true;
        }

        // Verify selected hospital is still in list (handles deletions gracefully)
        if (!hospitals.any((h) => h['id'] == _selectedHospitalId)) {
          _selectedHospitalId = hospitals.first['id'];
        }

        final selectedHospitalName = hospitals.firstWhere(
          (h) => h['id'] == _selectedHospitalId,
        )['name']!;

        final currentDateString = _formatDateString(_selectedDate);
        if (_agendaStream == null ||
            _lastQueriedHospitalId != _selectedHospitalId ||
            _lastQueriedDateString != currentDateString) {
          _lastQueriedHospitalId = _selectedHospitalId;
          _lastQueriedDateString = currentDateString;
          _agendaStream = _firestoreService.getHospitalDailyAgenda(
            _selectedHospitalId!,
            currentDateString,
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(_currentNavigationIndex == 0 ? 'Jadwalkan Janji Temu' : 'Janji Temu Saya'),
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textPrimary,
            elevation: 0.5,
          ),
          body: SafeArea(
            child: IndexedStack(
              index: _currentNavigationIndex,
              children: [
                // View 0: Booking Form
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Hospital Dropdown Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        color: Colors.white,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pilih Rumah Sakit',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            InkWell(
                              onTap: () => _showHospitalSearchBottomSheet(context, hospitals),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    Builder(
                                      builder: (context) {
                                        final currentHospital = hospitals.firstWhere(
                                          (h) => h['id'] == _selectedHospitalId,
                                          orElse: () => {'photoUrl': ''},
                                        );
                                        final pUrl = currentHospital['photoUrl'] ?? '';
                                        return pUrl.isNotEmpty
                                            ? CircleAvatar(
                                                radius: 12,
                                                backgroundImage: CachedNetworkImageProvider(pUrl),
                                              )
                                            : const Icon(
                                                Icons.local_hospital_outlined,
                                                color: HospitalColors.primary,
                                                size: 20,
                                              );
                                      },
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        selectedHospitalName,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: HospitalColors.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 2. Date Selection Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pilih Tanggal Kunjungan',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('EEEE, d MMMM yyyy').format(_selectedDate),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: HospitalColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: HospitalColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.calendar_month_rounded),
                                color: HospitalColors.primary,
                                onPressed: () async {
                                  final DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate: _selectedDate,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 90)),
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: const ColorScheme.light(
                                            primary: HospitalColors.primary,
                                            onPrimary: Colors.white,
                                            onSurface: AppColors.textPrimary,
                                          ),
                                          textButtonTheme: TextButtonThemeData(
                                            style: TextButton.styleFrom(
                                              foregroundColor: HospitalColors.primary,
                                            ),
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (picked != null && picked != _selectedDate) {
                                    setState(() {
                                      _selectedDate = picked;
                                      _selectedSlot = null; // Reset selected time slot when date changes
                                    });
                                    _fetchWeather();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      CalendarPicker(
                        selectedDate: _selectedDate,
                        onDateSelected: (date) {
                          setState(() {
                            _selectedDate = date;
                            _selectedSlot =
                                null; // Reset selected time slot when date changes
                          });
                          _fetchWeather();
                        },
                      ),
                      const SizedBox(height: 16),

                      // 3. Time Slot Grid Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pilih Waktu Kunjungan (Slot 1 Jam)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  size: 13,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Menampilkan jadwal untuk $selectedHospitalName',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Weather Forecast Display Card
                            Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: AppColors.border),
                              ),
                              color: HospitalColors.primary.withValues(alpha: 0.05),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.wb_sunny_rounded,
                                      color: HospitalColors.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Prakiraan Cuaca: ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        _weatherForecast,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: HospitalColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Render live streams from Firestore for selected hospital & date
                            StreamBuilder<List<AppointmentModel>>(
                              stream: _agendaStream,
                              builder: (context, agendaSnapshot) {
                                if (agendaSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(24.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }

                                if (agendaSnapshot.hasError) {
                                  return Center(
                                    child: Text(
                                      'Error loading slots: ${agendaSnapshot.error}',
                                      style: const TextStyle(
                                        color: AppColors.cancelled,
                                      ),
                                    ),
                                  );
                                }

                                final appointments = agendaSnapshot.data ?? [];

                                return CinemaSeatGrid(
                                  appointments: appointments,
                                  selectedSlot: _selectedSlot,
                                  selectedDate: _selectedDate,
                                  onSlotSelected: (slot) {
                                    setState(() {
                                      if (_selectedSlot == slot) {
                                        _selectedSlot = null;
                                      } else {
                                        _selectedSlot = slot;
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Scheduling Action Button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _selectedSlot == null || _selectedHospitalId == null
                                  ? AppColors.border
                                  : HospitalColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            onPressed: _selectedSlot == null || _selectedHospitalId == null || _isBooking
                                ? null
                                : () => _showBookingConfirmationModal(context, familyId, selectedHospitalName),
                            child: _isBooking
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                  )
                                : Text(
                                    _selectedSlot == null
                                        ? 'Pilih Waktu Dahulu'
                                        : 'Jadwalkan Kunjungan ($_selectedSlot)',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: _selectedSlot == null || _selectedHospitalId == null
                                          ? AppColors.textSecondary
                                          : Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
                
                // View 1: Appointments status list view
                _buildAppointmentsList(familyId),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentNavigationIndex,
            selectedItemColor: HospitalColors.primary,
            unselectedItemColor: AppColors.textSecondary,
            onTap: (index) {
              setState(() {
                _currentNavigationIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month_rounded),
                label: 'Jadwalkan',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_rounded),
                label: 'Janji Temu Saya',
              ),
            ],
          ),
        );
      },
    );
  }
}
