import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/services/auth_provider.dart';
import '../models/appointment_model.dart';
import '../services/mock_hospital_service.dart';
import '../widgets/calendar_picker.dart';
import '../widgets/cinema_seat_grid.dart';

class FamilyHospitalSchedulerScreen extends StatefulWidget {
  const FamilyHospitalSchedulerScreen({super.key});

  @override
  State<FamilyHospitalSchedulerScreen> createState() => _FamilyHospitalSchedulerScreenState();
}

class _FamilyHospitalSchedulerScreenState extends State<FamilyHospitalSchedulerScreen> {
  final MockHospitalService _mockService = MockHospitalService();

  // Mock list of hospitals
  final List<Map<String, String>> _hospitals = [
    {'id': 'rs-mitra-keluarga', 'name': 'RS Mitra Keluarga'},
    {'id': 'rs-siloam', 'name': 'RS Siloam Hospitals'},
    {'id': 'rs-pondok-indah', 'name': 'RS Pondok Indah'},
  ];

  late String _selectedHospitalId;
  late DateTime _selectedDate;
  String? _selectedSlot;
  bool _isBooking = false;
  List<AppointmentModel>? _bookedAppointments;

  @override
  void initState() {
    super.initState();
    _selectedHospitalId = _hospitals[0]['id']!;
    _selectedDate = DateTime.now();
    _loadMockAppointments();
  }

  String _formatDateString(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> _loadMockAppointments() async {
    setState(() {
      _bookedAppointments = null;
    });
    final appointments = await _mockService.getAppointmentsForDate(
      _formatDateString(_selectedDate),
    );
    if (mounted) {
      setState(() {
        _bookedAppointments = appointments;
      });
    }
  }

  Future<void> _handleBookAppointment(String familyId) async {
    if (_selectedSlot == null) return;

    setState(() {
      _isBooking = true;
    });

    final appointment = AppointmentModel(
      appointmentId: 'mock-appt-${DateTime.now().millisecondsSinceEpoch}',
      familyId: familyId,
      hospitalId: _selectedHospitalId,
      dateString: _formatDateString(_selectedDate),
      timeSlot: _selectedSlot!,
      status: 'booked',
    );

    try {
      await _mockService.bookAppointment(appointment);
      if (mounted) {
        setState(() {
          _bookedAppointments?.add(appointment);
          _selectedSlot = null; // Clear selected slot
          _isBooking = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Janji temu berhasil dijadwalkan (MOCK)! 🎉'),
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
            content: Text('Gagal membuat janji temu (MOCK): $e'),
            backgroundColor: AppColors.cancelled,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final familyId = auth.currentUser?.uid ?? 'mock-family-id';

    final selectedHospitalName = _hospitals.firstWhere((h) => h['id'] == _selectedHospitalId)['name']!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Jadwalkan Janji Temu (Mock Mode)'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedHospitalId,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedHospitalId = val;
                                _selectedSlot = null; // Reset selection
                              });
                              _loadMockAppointments();
                            }
                          },
                          items: _hospitals.map((hospital) {
                            return DropdownMenuItem<String>(
                              value: hospital['id'],
                              child: Text(hospital['name']!),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 2. Date Selection Section
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Pilih Tanggal',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              CalendarPicker(
                selectedDate: _selectedDate,
                onDateSelected: (date) {
                  setState(() {
                    _selectedDate = date;
                    _selectedSlot = null; // Reset selected time slot when date changes
                  });
                  _loadMockAppointments();
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
                        const Icon(Icons.info_outline, size: 13, color: AppColors.textSecondary),
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

                    // Load mock agenda list
                    _bookedAppointments == null
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : CinemaSeatGrid(
                            appointments: _bookedAppointments!,
                            selectedSlot: _selectedSlot,
                            onSlotSelected: (slot) {
                              setState(() {
                                _selectedSlot = slot;
                              });
                            },
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      // 4. Floating Action Booking Button
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
              backgroundColor: _selectedSlot == null ? AppColors.border : AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: _selectedSlot == null || _isBooking
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
                        : 'Jadwalkan Kunjungan (${_selectedSlot})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _selectedSlot == null ? AppColors.textSecondary : Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
