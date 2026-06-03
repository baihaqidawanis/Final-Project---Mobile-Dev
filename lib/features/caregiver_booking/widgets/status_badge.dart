import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/booking_model.dart';

class StatusBadge extends StatelessWidget {
  final BookingStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      BookingStatus.pending   => ('Menunggu',   AppColors.pending,   Icons.hourglass_top_rounded),
      BookingStatus.accepted  => ('Diterima',   AppColors.accepted,  Icons.check_circle_rounded),
      BookingStatus.completed => ('Selesai',    AppColors.completed, Icons.verified_rounded),
      BookingStatus.cancelled => ('Dibatalkan', AppColors.cancelled, Icons.cancel_rounded),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
