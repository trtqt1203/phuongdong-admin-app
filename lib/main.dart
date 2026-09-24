import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:phuong_dong_admin/screens/booking_detail_screen.dart';
import 'package:phuong_dong_admin/screens/bookings_list_screen.dart';
import 'package:phuong_dong_admin/screens/calendar_screen.dart';
import 'package:phuong_dong_admin/screens/dashboard_screen.dart';
import 'package:phuong_dong_admin/screens/login_screen.dart';
import 'package:phuong_dong_admin/screens/settings_screen.dart';
import 'package:phuong_dong_admin/services/auth_service.dart';
import 'package:phuong_dong_admin/services/booking_service.dart';
import 'package:phuong_dong_admin/services/notification_service.dart';
import 'package:phuong_dong_admin/theme/app_theme.dart';
import 'package:provider/provider.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi_VN');
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    runApp(const PhuongDongAdminApp());
  } catch (error) {
    runApp(_FirebaseSetupRequired(error: error.toString()));
  }
}

class PhuongDongAdminApp extends StatelessWidget {
  const PhuongDongAdminApp({super.key});

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthService()),
      Provider(create: (_) => BookingService()),
      ChangeNotifierProvider(create: (_) => NotificationService()),
    ],
    child: MaterialApp(
      title: 'Phương Đông Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const _AuthGate(),
    ),
  );
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    if (!auth.ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!auth.isAuthenticated) return const LoginScreen();
    return const _AuthenticatedShell();
  }
}

class _AuthenticatedShell extends StatefulWidget {
  const _AuthenticatedShell();
  @override
  State<_AuthenticatedShell> createState() => _AuthenticatedShellState();
}

class _AuthenticatedShellState extends State<_AuthenticatedShell> {
  int index = 0;
  NotificationService? notifications;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (notifications != null) return;
    notifications = context.read<NotificationService>();
    final user = context.read<AuthService>().user!;
    notifications!.openedBookingId.addListener(_openNotification);
    notifications!.initialize(user);
  }

  void _openNotification() {
    final id = notifications?.openedBookingId.value;
    if (id == null || id.isEmpty || !mounted) return;
    notifications!.openedBookingId.value = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BookingDetailScreen(bookingId: id)),
        );
      }
    });
  }

  @override
  void dispose() {
    notifications?.openedBookingId.removeListener(_openNotification);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(
      index: index,
      children: const [
        SafeArea(child: DashboardScreen()),
        BookingsListScreen(),
        CalendarScreen(),
        SettingsScreen(),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (value) => setState(() => index = value),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Tổng quan',
        ),
        NavigationDestination(
          icon: Icon(Icons.event_note_outlined),
          selectedIcon: Icon(Icons.event_note),
          label: 'Lịch hẹn',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month),
          label: 'Lịch',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: 'Cài đặt',
        ),
      ],
    ),
  );
}

class _FirebaseSetupRequired extends StatelessWidget {
  const _FirebaseSetupRequired({required this.error});
  final String error;
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.dark,
    home: Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off_outlined,
                    color: AppColors.gold,
                    size: 48,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Cần kết nối Firebase',
                    style: AppTheme.serif.copyWith(fontSize: 32),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Đặt file google-services.json vào android/app rồi làm theo FIREBASE_SETUP.md. Sau đó khởi động lại ứng dụng.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    error,
                    textAlign: TextAlign.center,
                    style: AppTheme.mono.copyWith(
                      color: AppColors.dim,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
