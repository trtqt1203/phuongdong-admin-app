import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phuong_dong_admin/models/booking.dart';
import 'package:phuong_dong_admin/theme/app_theme.dart';
import 'package:phuong_dong_admin/widgets/status_badge.dart';

class BookingTile extends StatelessWidget {
  const BookingTile({super.key, required this.booking, required this.onTap});
  final Booking booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: .12),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: .35),
                  ),
                ),
                child: Text(
                  booking.name.isEmpty
                      ? '?'
                      : booking.name.substring(0, 1).toUpperCase(),
                  style: AppTheme.serif.copyWith(
                    fontSize: 21,
                    color: AppColors.gold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            booking.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        StatusBadge(status: booking.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${booking.typeLabel} · ${booking.date} lúc ${booking.time}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      booking.phone,
                      style: AppTheme.mono.copyWith(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                    if (booking.quote != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        money.format(booking.quote!.total),
                        style: AppTheme.mono.copyWith(
                          color: AppColors.gold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
