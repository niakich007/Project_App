import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_design.dart';
import 'home_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final TextEditingController _emailController = TextEditingController();
  final supabase = Supabase.instance.client;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // ================= Dialog helpers =================
  void _showDialog(String text) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Text(text),
      ),
    );
  }

  void _closeDialog() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  // ================= Send Reset Email =================
  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showDialog('Введите ваш e-mail');
      Future.delayed(const Duration(seconds: 2), _closeDialog);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await supabase.auth.resetPasswordForEmail(
        email,
        redirectTo:
        'https://YOUR_APP_URL.com/reset-password', // <-- Укажи свой redirect URL
      );

      setState(() => _isLoading = false);

      _showDialog(
          'Проверьте почту. Ссылка для сброса пароля отправлена на $email');

      Future.delayed(const Duration(seconds: 3), () {
        _closeDialog();
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 600),
            pageBuilder: (_, __, ___) => const HomeScreen(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
                  child: child,
                ),
              );
            },
          ),
        );
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showDialog('Ошибка отправки письма: $e');
      Future.delayed(const Duration(seconds: 2), _closeDialog);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AppBackground.screen(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: AppGlass.container(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Восстановление пароля', style: AppTextStyles.title),
                        const SizedBox(height: 24),

                        Material(
                          type: MaterialType.transparency,
                          child: TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: AppTextStyles.body,
                            decoration: InputDecoration(
                              hintText: 'E-mail',
                              hintStyle: AppTextStyles.caption,
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.15),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        AppButtons.primary(
                          text: 'Отправить',
                          onTap: _sendResetEmail,
                        ),

                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Вернуться назад',
                            style: AppTextStyles.caption,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // ================= Loading Overlay =================
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}
