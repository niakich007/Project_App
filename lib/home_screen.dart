// Импорт стандартных Flutter виджетов
import 'package:flutter/material.dart';

// Импорт Supabase для авторизации
import 'package:supabase_flutter/supabase_flutter.dart';

// Импорты экранов приложения
import 'package:project_one/register_screen.dart';
import 'app_design.dart';
import 'forgot_password_screen.dart';
import 'main_screen.dart';

// ================= Главный экран авторизации =================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// ================= State для HomeScreen =================
class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {

  // Контроллер анимации
  late AnimationController _controller;

  // Анимация прозрачности (fade in)
  late Animation<double> _fadeAnimation;

  // Анимация увеличения (scale)
  late Animation<double> _scaleAnimation;

  // Контроллеры для полей ввода
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Экземпляр Supabase клиента
  final supabase = Supabase.instance.client;

  // Флаг загрузки (показывает спиннер)
  bool _isLoading = false;

  // Текущий пользователь, если он уже авторизован
  User? _currentUser;

  @override
  void initState() {
    super.initState();

    // Инициализация контроллера анимации
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // Анимация плавного появления
    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    // Анимация легкого увеличения
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    // Запуск анимации
    _controller.forward();

    // Проверяем, был ли пользователь уже залогинен
    _checkCurrentUser();
  }

  @override
  void dispose() {
    // Освобождаем ресурсы
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ================= Проверка текущего пользователя =================
  Future<void> _checkCurrentUser() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      // Если пользователь уже есть — сохраняем его
      setState(() => _currentUser = user);
    }
  }

  // ================= Вспомогательные методы для диалогов =================
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

  // ================= Автовход =================
  Future<void> _autoLogin() async {
    if (_currentUser == null) return;

    setState(() => _isLoading = true);

    // Небольшая задержка для плавности UX
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() => _isLoading = false);

    // Переход на главный экран
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  // ================= Вход по email и паролю =================
  Future<void> _loginUser() async {
    if (_isLoading) return;

    // Получаем значения из полей
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Проверка на пустые поля
    if (email.isEmpty || password.isEmpty) {
      _showDialog('Заполните все поля');
      Future.delayed(const Duration(seconds: 1), _closeDialog);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Пытаемся авторизоваться через Supabase
      final res = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      setState(() => _isLoading = false);

      // Если пользователь успешно вошёл
      if (res.user != null) {
        _showDialog('Вход выполнен');

        Future.delayed(const Duration(seconds: 1), () {
          _closeDialog();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        });
      }
    } on AuthApiException catch (e) {
      setState(() => _isLoading = false);

      // Если email не подтверждён
      if (e.code == 'email_not_confirmed') {
        _showDialog(
            'Email не подтверждён. Проверьте вашу почту и подтвердите регистрацию.');
      } else {
        _showDialog('Ошибка входа: ${e.message}');
      }

      Future.delayed(const Duration(seconds: 2), _closeDialog);
    } catch (e) {
      // Любая другая ошибка
      setState(() => _isLoading = false);
      _showDialog('Ошибка входа');
      Future.delayed(const Duration(seconds: 2), _closeDialog);
    }
  }

  // ================= Красивая навигация с анимацией =================
  void _navigate(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, __, ___) => screen,
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
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Фоновый дизайн
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
                        // Кнопка автовхода, если пользователь уже есть
                        if (_currentUser != null) ...[
                          ElevatedButton(
                            onPressed: _autoLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                            ),
                            child: Text(
                              'Войти как ${_currentUser!.userMetadata?['display_name'] ?? 'пользователь'}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        Text('Вход', style: AppTextStyles.title),
                        const SizedBox(height: 24),

                        // Поле email
                        _InputField(
                          controller: _emailController,
                          hint: 'E-mail',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),

                        // Поле пароля
                        _InputField(
                          controller: _passwordController,
                          hint: 'Пароль',
                          obscureText: true,
                        ),
                        const SizedBox(height: 24),

                        // Кнопка входа
                        AppButtons.primary(
                          text: 'Войти',
                          onTap: _loginUser,
                        ),
                        const SizedBox(height: 16),

                        // Переход на восстановление пароля
                        TextButton(
                          onPressed: () =>
                              _navigate(context, const ForgotPasswordScreen()),
                          child: Text('Забыли пароль?', style: AppTextStyles.caption),
                        ),

                        // Переход на регистрацию
                        TextButton(
                          onPressed: () =>
                              _navigate(context, const AuthScreen()),
                          child: Text('Регистрация', style: AppTextStyles.caption),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // ================= Оверлей загрузки =================
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

// ================= Кастомное поле ввода =================
class _InputField extends StatelessWidget {
  final String hint;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextEditingController? controller;

  const _InputField({
    this.controller,
    required this.hint,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: AppTextStyles.body,
        decoration: InputDecoration(
          hintText: hint,
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
    );
  }
}
