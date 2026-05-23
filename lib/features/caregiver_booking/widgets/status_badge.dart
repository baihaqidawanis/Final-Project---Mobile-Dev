import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/booking_model.dart';

class StatusBadge extends StatelessWidget {
  final BookingStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      BookingStatus.pending => ('Pending', AppColors.pending),
      BookingStatus.accepted => ('Accepted', AppColors.accepted),
      BookingStatus.completed => ('Completed', AppColors.completed),
      BookingStatus.cancelled => ('Cancelled', AppColors.cancelled),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
