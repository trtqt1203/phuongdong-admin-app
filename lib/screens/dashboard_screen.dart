import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phuong_dong_admin/models/booking.dart';
import 'package:phuong_dong_admin/screens/booking_detail_screen.dart';
import 'package:phuong_dong_admin/services/booking_service.dart';
import 'package:phuong_dong_admin/theme/app_theme.dart';
import 'package:phuong_dong_admin/widgets/booking_tile.dart';
import 'package:phuong_dong_admin/widgets/chart_widgets.dart';
import 'package:phuong_dong_admin/widgets/stat_card.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) => StreamBuilder<List<Booking>>(
    stream: context.read<BookingService>().watchBookings(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return _ErrorState(message: snapshot.error.toString());
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final bookings = snapshot.data!;
      final today = bookings.where((item) => item.isToday).toList()
        ..sort((a, b) => a.time.compareTo(b.time));
      return RefreshIndicator(
        onRefresh: context.read<BookingService>().refreshBookings,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
          children: [
            Text(
              DateFormat("EEEE, d 'tháng' M", 'vi').format(DateTime.now()),
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 11,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              'Tổng quan xưởng',
              style: AppTheme.serif.copyWith(fontSize: 34),
            ),
            const SizedBox(height: 18),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.5,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                StatCard(
                  label: 'Tổng lịch hẹn',
                  value: '${bookings.length}',
                  icon: Icons.event_note,
                ),
                StatCard(
                  label: 'Hôm nay',
                  value: '${today.length}',
                  icon: Icons.today,
                ),
                StatCard(
                  label: 'Chờ xác nhận',
                  value:
                      '${bookings.where((item) => item.status == BookingStatus.pending).length}',
                  icon: Icons.hourglass_top,
                ),
                StatCard(
                  label: 'Đã xác nhận',
                  value:
                      '${bookings.where((item) => item.status == BookingStatus.confirmed).length}',
                  icon: Icons.verified_outlined,
                ),
              ],
            ),
            const SizedBox(height: 22),
            _Section(
              title: '7 ngày gần nhất',
              child: WeeklyBookingsChart(bookings: bookings),
            ),
            const SizedBox(height: 14),
            _Section(
              title: 'Phân loại dịch vụ',
              child: BookingTypeChart(bookings: bookings),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Lịch hẹn hôm nay',
                  style: AppTheme.serif.copyWith(fontSize: 24),
                ),
                Text(
                  '${today.length} lịch',
                  style: AppTheme.mono.copyWith(
                    color: AppColors.gold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (today.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Hôm nay chưa có lịch hẹn.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),
              )
            else
              ...today.map(
                (booking) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: BookingTile(
                    booking: booking,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            BookingDetailScreen(bookingId: booking.id),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 10,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        'Không tải được dữ liệu.\n$message',
        textAlign: TextAlign.center,
      ),
    ),
  );
}
