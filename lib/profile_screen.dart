import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_design.dart';

// ======================= Экран редактирования профиля =======================
// Позволяет пользователю изменить логин и обновить его в Supabase
class ProfileEditScreen extends StatefulWidget {
  // Текущий логин передаётся из MainScreen
  final String currentLogin;

  const ProfileEditScreen({super.key, required this.currentLogin});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  // Контроллер для поля ввода логина
  final TextEditingController _loginController = TextEditingController();

  // Клиент Supabase
  final supabase = Supabase.instance.client;

  // Флаг загрузки для overlay индикатора
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Показываем текущий логин в TextField
    _loginController.text = widget.currentLogin;
  }

  @override
  void dispose() {
    // Освобождаем контроллер
    _loginController.dispose();
    super.dispose();
  }

  // ======================= Обновление логина =======================
  Future<void> _updateLogin() async {
    final newLogin = _loginController.text.trim();

    // Проверка на пустое значение
    if (newLogin.isEmpty) {
      _showMessage('Введите логин');
      return;
    }

    // Проверка на неизменённый логин
    if (newLogin == widget.currentLogin) {
      _showMessage('Логин не изменился');
      return;
    }

    // Включаем индикатор загрузки
    setState(() => _isLoading = true);

    try {
      // ================= Проверка уникальности логина =================
      final exists = await supabase
          .from('users')
          .select('id')
          .eq('display_name', newLogin)
          .limit(1)
          .maybeSingle();

      if (exists != null) {
        _showMessage('Логин уже занят');
        return;
      }

      // Получаем текущего пользователя из Supabase auth
      final user = supabase.auth.currentUser;
      if (user == null) {
        _showMessage('Ошибка: пользователь не найден');
        return;
      }

      // ================= Обновление логина в таблице users =================
      await supabase.from('users').update({'display_name': newLogin}).eq('id', user.id);

      // ================= Обновление логина в auth metadata =================
      await supabase.auth.updateUser(UserAttributes(
        data: {'display_name': newLogin},
      ));

      // Показ уведомления об успешном обновлении
      _showMessage('Логин успешно обновлён');

      // Возвращаем новый логин на предыдущий экран
      Navigator.pop(context, newLogin);
    } catch (e) {
      _showMessage('Ошибка обновления логина: $e');
    } finally {
      // Выключаем индикатор загрузки
      setState(() => _isLoading = false);
    }
  }

  // ======================= Вспомогательная функция =======================
  // Показывает SnackBar с сообщением
  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  // ======================= UI экрана =======================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ================= Фоновый экран =================
          AppBackground.screen(
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: AppGlass.container(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Заголовок экрана
                        const Text('Редактирование профиля', style: AppTextStyles.title),
                        const SizedBox(height: 24),

                        // ================= Поле ввода логина =================
                        Text('Логин', style: AppTextStyles.body),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _loginController,
                          style: AppTextStyles.body,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.15),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            hintText: widget.currentLogin, // текущий логин в hint
                            hintStyle: AppTextStyles.caption,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ================= Кнопка "Изменить" =================
                        AppButtons.primary(
                          text: 'Изменить',
                          onTap: _updateLogin, // Вызывает функцию обновления логина
                        ),

                        const SizedBox(height: 16),

                        // ================= Кнопка "Вернуться назад" =================
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context), // Закрытие экрана без изменений
                            child: const Text('Вернуться назад', style: AppTextStyles.body),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ================= Индикатор загрузки =================
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3), // полупрозрачное затемнение
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.greenLight,
                  strokeWidth: 3,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
