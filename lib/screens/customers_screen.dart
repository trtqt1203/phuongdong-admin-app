import 'package:flutter/material.dart';
import 'package:phuong_dong_admin/models/booking.dart';
import 'package:phuong_dong_admin/screens/booking_detail_screen.dart';
import 'package:phuong_dong_admin/services/booking_service.dart';
import 'package:phuong_dong_admin/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});
  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  String query = '';
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Khách hàng')),
    body: StreamBuilder<List<Booking>>(
      stream: context.read<BookingService>().watchBookings(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final grouped = <String, List<Booking>>{};
        for (final booking in snapshot.data!) {
          grouped.putIfAbsent(booking.phone, () => []).add(booking);
        }
        final customers =
            grouped.entries.where((entry) {
              final term = query.trim().toLowerCase();
              final name = entry.value.first.name.toLowerCase();
              return term.isEmpty || '$name ${entry.key}'.contains(term);
            }).toList()..sort(
              (a, b) => a.value.first.name.compareTo(b.value.first.name),
            );
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                onChanged: (value) => setState(() => query = value),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Tìm tên hoặc số điện thoại',
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                itemCount: customers.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final entry = customers[index];
                  final latest = entry.value.first;
                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 7,
                      ),
                      title: Text(
                        latest.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${entry.key} · ${entry.value.length} lịch hẹn',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.gold.withValues(alpha: .15),
                        foregroundColor: AppColors.gold,
                        child: Text(
                          latest.name.isEmpty
                              ? '?'
                              : latest.name[0].toUpperCase(),
                        ),
                      ),
                      trailing: IconButton(
                        onPressed: () =>
                            launchUrl(Uri.parse('tel:${entry.key}')),
                        icon: const Icon(Icons.call_outlined),
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              BookingDetailScreen(bookingId: latest.id),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    ),
  );
}
