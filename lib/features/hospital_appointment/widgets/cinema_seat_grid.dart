import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/appointment_model.dart';

class CinemaSeatGrid extends StatelessWidget {
  final List<AppointmentModel> appointments;
  final String? selectedSlot;
  final ValueChanged<String> onSlotSelected;
  final DateTime selectedDate;

  const CinemaSeatGrid({
    super.key,
    required this.appointments,
    required this.selectedSlot,
    required this.onSlotSelected,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    // Fixed 1-hour time slots from 08:00 to 17:00
    final List<String> timeSlots = [
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

    // Find all booked/taken slots (status != 'cancelled')
    final Set<String> bookedSlots = appointments
        .where((appointment) => appointment.status.toLowerCase() != 'cancelled')
        .map((appointment) => appointment.timeSlot)
        .toSet();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: timeSlots.length,
      itemBuilder: (context, index) {
        final slot = timeSlots[index];
        final isSelected = slot == selectedSlot;
        final isBooked = bookedSlots.contains(slot);

        // Determine if slot has already passed
        final now = DateTime.now();
        final parts = slot.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final slotDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          hour,
          minute,
        );
        final isPassed = slotDateTime.isBefore(now);

        Color backgroundColor;
        Color textColor;
        Color borderColor;

        if (isPassed) {
          backgroundColor = AppColors.border.withValues(alpha: 0.4); // Muted/greyed out
          textColor = AppColors.textSecondary.withValues(alpha: 0.5);
          borderColor = AppColors.border.withValues(alpha: 0.4);
        } else if (isSelected) {
          backgroundColor = AppColors.cancelled; // Red (Indicator)
          textColor = Colors.white;
          borderColor = AppColors.cancelled;
        } else if (isBooked) {
          backgroundColor = AppColors.border; // Grey (Disabled/Booked)
          textColor = AppColors.textSecondary;
          borderColor = AppColors.border;
        } else {
          backgroundColor = AppColors.accent; // Green (Selectable/Available)
          textColor = Colors.white;
          borderColor = AppColors.accent;
        }

        return GestureDetector(
          onTap: () {
            if (!isBooked && !isPassed) {
              onSlotSelected(slot);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: backgroundColor.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_seat_rounded,
                  size: 16,
                  color: textColor.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 6),
                Text(
                  slot,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
