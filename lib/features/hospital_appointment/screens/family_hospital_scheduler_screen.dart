import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
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

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _fetchWeather();
    _hospitalsStream = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'hospital')
        .snapshots();
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
    );

    try {
      await _firestoreService.createAppointment(appointment);
      if (mounted) {
        setState(() {
          _selectedSlot = null;
          _isBooking = false;
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
                                    leading: Icon(
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

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final familyId = auth.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Jadwalkan Janji Temu'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: _hospitalsStream,
          builder: (context, hospitalSnapshot) {
            if (hospitalSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (hospitalSnapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Gagal memuat daftar rumah sakit: ${hospitalSnapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.cancelled),
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
              };
            }).toList();

            if (hospitals.isEmpty) {
              return Center(
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

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Hospital Dropdown Section (Searchable Bottom Sheet)
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
                                const Icon(
                                  Icons.local_hospital_outlined,
                                  color: HospitalColors.primary,
                                  size: 20,
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
                          stream: _firestoreService.getHospitalDailyAgenda(
                            _selectedHospitalId!,
                            _formatDateString(_selectedDate),
                          ),
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
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
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
                : () => _handleBookAppointment(familyId),
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
    );
  }
}
