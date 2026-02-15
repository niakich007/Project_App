// Импорт асинхронности (Future, async/await)
import 'dart:async';

// Импорт Flutter UI
import 'package:flutter/material.dart';

// Экран после регистрации
import 'package:project_one/home_screen.dart';

// Supabase SDK
import 'package:supabase_flutter/supabase_flutter.dart';

// Ваши стили и оформление
import 'app_design.dart';
import 'main_screen.dart';

// Экран авторизации (регистрация / вход)
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

// State экрана + поддержка анимации
class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {

  // Контроллер анимации
  late AnimationController _controller;

  // Анимация прозрачности
  late Animation<double> _fadeAnimation;

  // Анимация масштаба
  late Animation<double> _scaleAnimation;

  // Контроллеры текстовых полей
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _repeatPasswordController =
  TextEditingController();

  // Клиент Supabase
  final supabase = Supabase.instance.client;

  // Флаг: режим регистрации или входа
  bool isRegister = true;

  // Флаг: показывать ли загрузчик
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Создаём контроллер анимации
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // Анимация плавного появления
    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    // Анимация лёгкого увеличения
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    // Запускаем анимацию
    _controller.forward();
  }

  @override
  void dispose() {
    // Освобождаем ресурсы
    _controller.dispose();
    _emailController.dispose();
    _displayNameController.dispose();
    _passwordController.dispose();
    _repeatPasswordController.dispose();
    super.dispose();
  }

  // ================= Диалоги =================

  // Показать диалог с текстом
  void _showDialog(String text) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Text(text),
      ),
    );
  }

  // Закрыть диалог если он открыт
  void _closeDialog() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  // ================= Лоадер =================

  // Виджет загрузчика на весь экран
  Widget _buildLoader() {
    // Если не загружаемся — ничего не показываем
    if (!_isLoading) return const SizedBox.shrink();

    return Container(
      color: Colors.black.withOpacity(0.45),
      child: const Center(
        child: SizedBox(
          width: 64,
          height: 64,
          child: CircularProgressIndicator(strokeWidth: 6),
        ),
      ),
    );
  }

  // ================= Регистрация =================
  Future<void> _registerUser() async {
    // Если уже идёт загрузка — выходим
    if (_isLoading) return;

    // Берём значения из полей
    final email = _emailController.text.trim();
    final displayName = _displayNameController.text.trim();
    final password = _passwordController.text;
    final repeatPassword = _repeatPasswordController.text;

    // Проверка на пустые поля
    if (email.isEmpty ||
        displayName.isEmpty ||
        password.isEmpty ||
        repeatPassword.isEmpty) {
      _showDialog('Заполните все поля');
      Future.delayed(const Duration(seconds: 1), _closeDialog);
      return;
    }

    // Проверка совпадения паролей
    if (password != repeatPassword) {
      _showDialog('Пароли не совпадают');
      Future.delayed(const Duration(seconds: 1), _closeDialog);
      return;
    }

    // Включаем лоадер
    setState(() => _isLoading = true);

    try {
      // Проверяем, есть ли такой email в базе
      final existingEmail = await supabase
          .from('users')
          .select()
          .eq('email', email)
          .maybeSingle();

      if (existingEmail != null) {
        setState(() => _isLoading = false);
        _showDialog('Такой e-mail уже существует');
        Future.delayed(const Duration(seconds: 1), _closeDialog);
        return;
      }

      // Проверяем, занят ли логин
      final existingDisplay = await supabase
          .from('users')
          .select()
          .eq('display_name', displayName)
          .maybeSingle();

      if (existingDisplay != null) {
        setState(() => _isLoading = false);
        _showDialog('Такой логин уже занят');
        Future.delayed(const Duration(seconds: 1), _closeDialog);
        return;
      }

      // Создаём пользователя в Supabase Auth
      final res = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': displayName},
      );

      // Если не создался — ошибка
      if (res.user == null) throw 'Ошибка создания пользователя';

      // Записываем пользователя в таблицу users
      await supabase.from('users').insert({
        'id': res.user!.id,
        'email': email,
        'display_name': displayName,
      });

      // Выключаем лоадер
      setState(() => _isLoading = false);

      // Показываем успех
      _showDialog('Регистрация успешна');

      // Переходим на HomeScreen
      Future.delayed(const Duration(seconds: 1), () {
        _closeDialog();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      });
    } catch (e) {
      // Обработка ошибки
      setState(() => _isLoading = false);
      print('Ошибка регистрации: $e');
      _showDialog('Ошибка регистрации');
      Future.delayed(const Duration(seconds: 1), _closeDialog);
    }
  }

  // ================= Вход =================
  Future<void> _loginUser() async {
    if (_isLoading) return;

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
      // Авторизация через Supabase
      final res = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      setState(() => _isLoading = false);

      // Если пользователь получен — вход успешен
      if (res.user != null) {
        _showDialog('Вход выполнен');
        Future.delayed(const Duration(seconds: 1), () {
          _closeDialog();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        });
      } else {
        _showDialog('Неверный email или пароль');
        Future.delayed(const Duration(seconds: 1), _closeDialog);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('Ошибка входа: $e');
      _showDialog('Ошибка входа');
      Future.delayed(const Duration(seconds: 1), _closeDialog);
    }
  }
  @override
  Widget build(BuildContext context) {
    // Основной виджет экрана
    return Stack(
      children: [
        // Фоновый экран с кастомным дизайном
        AppBackground.screen(
          child: Center(
            child: SingleChildScrollView(
              // Отступы вокруг формы
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                // Анимация прозрачности
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  // Анимация масштаба
                  scale: _scaleAnimation,
                  child: AppGlass.container(
                    // Стеклянная/полупрозрачная карточка
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Заголовок: Регистрация или Вход
                        Text(
                          isRegister ? 'Регистрация' : 'Вход',
                          style: AppTextStyles.title,
                        ),
                        const SizedBox(height: 24), // Отступ

                        // Поле логина (только для регистрации)
                        if (isRegister)
                          _InputField(
                            controller: _displayNameController,
                            hint: 'Логин (Display Name)',
                          ),
                        if (isRegister) const SizedBox(height: 16), // Отступ

                        // Поле email
                        _InputField(
                          controller: _emailController,
                          hint: 'E-mail',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16), // Отступ

                        // Поле пароль
                        _InputField(
                          controller: _passwordController,
                          hint: 'Пароль',
                          obscureText: true, // Скрытый ввод
                        ),
                        if (isRegister) const SizedBox(height: 16), // Отступ

                        // Поле повтор пароля (только для регистрации)
                        if (isRegister)
                          _InputField(
                            controller: _repeatPasswordController,
                            hint: 'Повтор пароля',
                            obscureText: true,
                          ),

                        const SizedBox(height: 24), // Отступ

                        // Кнопка действия (Регистрация или Вход)
                        AppButtons.primary(
                          text: isRegister
                              ? 'Зарегистрироваться'
                              : 'Войти',
                          onTap: isRegister ? _registerUser : _loginUser,
                        ),

                        const SizedBox(height: 16), // Отступ

                        // Кнопка переключения режима (Регистрация <-> Вход)
                        TextButton(
                          onPressed: () {
                            setState(() => isRegister = !isRegister);
                          },
                          child: Text(
                            isRegister
                                ? 'Уже есть аккаунт? Войти'
                                : 'Нет аккаунта? Зарегистрироваться',
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

        // Полноэкранный загрузчик поверх формы
        _buildLoader(),
      ],
    );
  }
}

// ================= Кастомное поле ввода =================
class _InputField extends StatelessWidget {
  // Контроллер текста
  final TextEditingController controller;

  // Подсказка для поля
  final String hint;

  // Скрывать текст или нет (для пароля)
  final bool obscureText;

  // Тип клавиатуры
  final TextInputType keyboardType;

  const _InputField({
    required this.controller,
    required this.hint,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      // Прозрачный материал, чтобы не было дефолтного фона
      type: MaterialType.transparency,
      child: TextField(
        controller: controller,        // Привязка к контроллеру
        obscureText: obscureText,      // Скрытый текст для пароля
        keyboardType: keyboardType,    // Тип клавиатуры
        style: AppTextStyles.body,     // Стили текста
        decoration: InputDecoration(
          hintText: hint,              // Подсказка
          hintStyle: AppTextStyles.caption, // Стиль подсказки
          filled: true,                // Заполнение фоном
          fillColor: Colors.white.withOpacity(0.15), // Полупрозрачный фон
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14), // Скругление
            borderSide: BorderSide.none,            // Без рамки
          ),
          contentPadding:
          const EdgeInsets.symmetric(vertical: 14, horizontal: 16), // Внутренние отступы
        ),
      ),
    );
  }
}
