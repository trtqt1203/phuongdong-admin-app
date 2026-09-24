import 'package:flutter/material.dart';
import 'package:phuong_dong_admin/models/booking.dart';
import 'package:phuong_dong_admin/theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, this.large = false});
  final BookingStatus status;
  final bool large;

  Color get color => switch (status) {
    BookingStatus.pending => AppColors.gold,
    BookingStatus.confirmed => AppColors.green,
    BookingStatus.cancelled => AppColors.rust,
    BookingStatus.completed => AppColors.dim,
  };

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: large ? 12 : 8,
      vertical: large ? 7 : 4,
    ),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      border: Border.all(color: color.withValues(alpha: .55)),
      borderRadius: BorderRadius.circular(3),
    ),
    child: Text(
      status.label.toUpperCase(),
      style: TextStyle(
        color: color,
        fontSize: large ? 12 : 10,
        fontWeight: FontWeight.w700,
        letterSpacing: .8,
      ),
    ),
  );
}
