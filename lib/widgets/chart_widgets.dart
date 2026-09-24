import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phuong_dong_admin/models/booking.dart';
import 'package:phuong_dong_admin/theme/app_theme.dart';

class WeeklyBookingsChart extends StatelessWidget {
  const WeeklyBookingsChart({super.key, required this.bookings});
  final List<Booking> bookings;

  @override
  Widget build(BuildContext context) {
    final days = List.generate(
      7,
      (index) => DateTime.now().subtract(Duration(days: 6 - index)),
    );
    final counts = days.map((day) {
      final key = DateFormat('yyyy-MM-dd').format(day);
      return bookings.where((item) => item.date == key).length;
    }).toList();
    final maximum = counts
        .fold<int>(1, (value, item) => item > value ? item : value)
        .toDouble();
    return SizedBox(
      height: 190,
      child: BarChart(
        BarChartData(
          maxY: maximum + 1,
          alignment: BarChartAlignment.spaceAround,
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= days.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Text(
                      DateFormat('E', 'vi').format(days[index]),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.muted,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(
            days.length,
            (index) => BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: counts[index].toDouble(),
                  color: AppColors.gold,
                  width: 18,
                  borderRadius: BorderRadius.circular(2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BookingTypeChart extends StatelessWidget {
  const BookingTypeChart({super.key, required this.bookings});
  final List<Booking> bookings;

  @override
  Widget build(BuildContext context) {
    final fitting = bookings.where((item) => item.type == 'domay').length;
    final consulting = bookings.length - fitting;
    final total = bookings.isEmpty ? 1 : bookings.length;
    return SizedBox(
      height: 190,
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 42,
                sectionsSpace: 2,
                sections: [
                  PieChartSectionData(
                    value: consulting.toDouble(),
                    color: AppColors.gold,
                    title: '${(consulting * 100 / total).round()}%',
                    radius: 28,
                    titleStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  PieChartSectionData(
                    value: fitting.toDouble(),
                    color: AppColors.green,
                    title: '${(fitting * 100 / total).round()}%',
                    radius: 28,
                    titleStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Legend(color: AppColors.gold, label: 'Tư vấn'),
              SizedBox(height: 10),
              _Legend(color: AppColors.green, label: 'Đo may'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(width: 8, height: 8, color: color),
      const SizedBox(width: 7),
      Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
    ],
  );
}
