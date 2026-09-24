import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:phuong_dong_admin/services/auth_service.dart';
import 'package:phuong_dong_admin/theme/app_theme.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool remember = true;
  bool busy = false;
  String error = '';

  Future<void> submit() async {
    if (email.text.trim().isEmpty || password.text.length < 6) {
      setState(() => error = 'Vui lòng nhập email và mật khẩu hợp lệ.');
      return;
    }
    setState(() {
      busy = true;
      error = '';
    });
    try {
      await context.read<AuthService>().signIn(
        email: email.text,
        password: password.text,
        remember: remember,
      );
    } on FirebaseAuthException catch (exception) {
      setState(
        () => error = exception.code == 'not-authorized'
            ? exception.message!
            : 'Email hoặc mật khẩu không đúng.',
      );
    } catch (_) {
      setState(
        () => error = 'Không thể đăng nhập. Kiểm tra kết nối và thử lại.',
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'PĐ',
                  textAlign: TextAlign.center,
                  style: AppTheme.serif.copyWith(
                    color: AppColors.gold,
                    fontSize: 48,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'PHƯƠNG ĐÔNG',
                  textAlign: TextAlign.center,
                  style: AppTheme.serif.copyWith(
                    fontSize: 30,
                    letterSpacing: 4,
                  ),
                ),
                const Text(
                  'KHÔNG GIAN QUẢN TRỊ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 10,
                    letterSpacing: 2.2,
                  ),
                ),
                const SizedBox(height: 42),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.username],
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: password,
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: (_) => submit(),
                  decoration: const InputDecoration(labelText: 'Mật khẩu'),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: remember,
                  onChanged: (value) =>
                      setState(() => remember = value ?? true),
                  title: const Text(
                    'Ghi nhớ đăng nhập',
                    style: TextStyle(fontSize: 13, color: AppColors.muted),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                if (error.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      error,
                      style: const TextStyle(
                        color: AppColors.rust,
                        fontSize: 13,
                      ),
                    ),
                  ),
                FilledButton(
                  onPressed: busy ? null : submit,
                  child: Text(busy ? 'ĐANG ĐĂNG NHẬP…' : 'ĐĂNG NHẬP'),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Tài khoản chỉ do chủ shop cấp. Ứng dụng không hỗ trợ tự đăng ký.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
