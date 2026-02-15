// ======================= Импорты =======================

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:project_one/home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project_one/profile_screen.dart';
import 'app_design.dart';
import 'audio/audio_screen.dart';
import 'audio/image_screen.dart';

// ======================= Главный экран с BottomNavigation =======================

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Текущий выбранный таб в BottomNavigation
  int _currentIndex = 0;

  // Клиент Supabase
  final supabase = Supabase.instance.client;

  // ================= Данные пользователя =================
  String _displayName = '';
  String _email = '';
  String _uid = '';

  // Флаг загрузки (для overlay индикатора)
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // При запуске экрана загружаем данные пользователя
    _loadUserData();
  }

  // ================= Загрузка данных пользователя из Supabase =================
  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      // Получаем текущего авторизованного пользователя
      final user = supabase.auth.currentUser;

      if (user != null) {
        // Запрашиваем данные пользователя из таблицы users
        final res = await supabase
            .from('users')
            .select('display_name,email,id')
            .eq('id', user.id)
            .maybeSingle();

        // Если данные найдены — обновляем состояние
        if (res != null) {
          setState(() {
            _displayName = res['display_name'] ?? '';
            _email = res['email'] ?? '';
            _uid = res['id'] ?? '';
          });
        }
      }
    } catch (e) {
      print('Ошибка загрузки данных пользователя: $e');
    } finally {
      // Выключаем индикатор загрузки
      setState(() => _isLoading = false);
    }
  }

  // =================== Навигация с возвратом результата ===================
  // Используется, например, для экрана редактирования профиля
  Future<T?> _openScreenWithResult<T>(BuildContext context, Widget screen) {
    return Navigator.of(context).push<T>(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, animation, __, child) {
          // Анимация: плавное появление + лёгкий зум
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

  // =================== Список вкладок ===================
  List<Widget> _tabs() => [
    // Вкладка профиля
    ProfileTab(
      displayName: _displayName,
      email: _email,
      uid: _uid,
      onEdit: () async {
        // Открываем экран редактирования и ждём результат
        final updatedLogin = await _openScreenWithResult<String>(
          context,
          ProfileEditScreen(currentLogin: _displayName),
        );

        // Если логин изменился — обновляем его
        if (updatedLogin != null && updatedLogin.isNotEmpty) {
          setState(() {
            _displayName = updatedLogin;
          });
        }
      },
    ),

    // Вкладка аудио
    AudioAI_Tab(onUse: () => _openScreen(context, const AudioScreen())),

    // Вкладка изображений
    ImageAI_Tab(onUse: () => _openScreen(context, const ImageScreen())),

    // Заглушка
    PlaceholderTab(onUse: () => _openScreen(context, const PlaceholderScreen())),
  ];

  // =================== Обычное открытие экрана ===================
  void _openScreen(BuildContext context, Widget screen) {
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

  // =================== Элемент нижнего меню ===================
  BottomNavigationBarItem _navItem(String iconPath, String label, bool isActive) {
    return BottomNavigationBarItem(
      label: label,
      icon: SvgPicture.asset(
        iconPath,
        width: isActive ? 28 : 24,
        height: isActive ? 28 : 24,
        colorFilter: ColorFilter.mode(
          isActive ? Colors.white : Colors.white54,
          BlendMode.srcIn,
        ),
      ),
    );
  }

  // =================== Основной UI ===================
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          // Показываем текущую вкладку
          body: _tabs()[_currentIndex],

          // Нижнее меню
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppColors.greenDark,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white54,
            items: [
              _navItem('assets/icons/profile_icons.svg', 'Profile', _currentIndex == 0),
              _navItem('assets/icons/music_icons.svg', 'Audio', _currentIndex == 1),
              _navItem('assets/icons/image_icons.svg', 'Image', _currentIndex == 2),
              _navItem('assets/icons/people_icons.svg', 'Maybe', _currentIndex == 3),
            ],
          ),
        ),

        // ================= Loading Overlay =================
        // Если идёт загрузка — показываем затемнение + спиннер
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(
                color: AppColors.greenLight,
                strokeWidth: 3,
              ),
            ),
          ),
      ],
    );
  }
}
// ================== Tabs ==================
// Ниже идут виджеты вкладок для BottomNavigationBar

// ================== Вкладка профиля ==================
// Показывает данные пользователя и кнопки управления аккаунтом

class ProfileTab extends StatelessWidget {
  // Колбэк для открытия экрана редактирования профиля
  final VoidCallback onEdit;

  // Данные пользователя, полученные из Supabase
  final String displayName;
  final String email;
  final String uid;

  const ProfileTab({
    super.key,
    required this.onEdit,
    required this.displayName,
    required this.email,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    return AppBackground.screen( // Фоновый экран приложения
      child: Center( // Центрируем карточку профиля
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24), // Отступы по бокам
          child: AppGlass.container( // Стеклянная карточка (твой дизайн)
            child: Column(
              mainAxisSize: MainAxisSize.min, // Карточка по высоте = контенту
              crossAxisAlignment: CrossAxisAlignment.start, // Выравнивание по левому краю
              children: [
                // Заголовок экрана
                const Text('Профиль пользователя', style: AppTextStyles.title),
                const SizedBox(height: 16),

                // ================= Логин =================
                RichText(
                  text: TextSpan(
                    style: AppTextStyles.body,
                    children: [
                      const TextSpan(
                        text: 'Логин: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      // Значение логина из Supabase
                      TextSpan(text: displayName),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // ================= Email =================
                RichText(
                  text: TextSpan(
                    style: AppTextStyles.body,
                    children: [
                      const TextSpan(
                        text: 'E-mail: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      // Email пользователя
                      TextSpan(text: email),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // ================= UID =================
                RichText(
                  text: TextSpan(
                    style: AppTextStyles.body,
                    children: [
                      const TextSpan(
                        text: 'UID: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      // Уникальный идентификатор пользователя в Supabase
                      TextSpan(text: uid),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ================= Кнопки управления =================
                Column(
                  children: [
                    // Кнопка редактирования профиля
                    AppButtons.primary(
                      text: 'Редактировать',
                      onTap: onEdit, // Передаётся из MainScreen
                    ),
                    const SizedBox(height: 12),

                    // Кнопка выхода из аккаунта
                    SizedBox(
                      width: double.infinity, // Растягиваем на всю ширину
                      child: OutlinedButton(
                        onPressed: () async {
                          // Получаем клиент Supabase
                          final supabase = Supabase.instance.client;

                          // Выходим из аккаунта
                          await supabase.auth.signOut();

                          // Полностью очищаем стек навигации и кидаем на HomeScreen
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const HomeScreen()),
                                (route) => false,
                          );
                        },
                        child: const Text('Выйти из аккаунта'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================== Вкладка Audio AI ==================
// Экран-приглашение для перехода в аудио нейронку

class AudioAI_Tab extends StatelessWidget {
  // Колбэк открытия экрана аудио
  final VoidCallback onUse;

  const AudioAI_Tab({super.key, required this.onUse});

  @override
  Widget build(BuildContext context) {
    return AppBackground.screen(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: AppGlass.container(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Иконка аудио
                SvgPicture.asset(
                  'assets/icons/music_icons.svg',
                  width: 80,
                  height: 80,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(height: 16),

                // Заголовок
                const Text('AUDIO', style: AppTextStyles.title),
                const SizedBox(height: 8),

                // Подзаголовок
                const Text('Попробуй нейронку своими руками', style: AppTextStyles.body),
                const SizedBox(height: 24),

                // Кнопка перехода к функционалу
                AppButtons.primary(
                  text: 'Использовать',
                  onTap: onUse,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================== Вкладка Image AI ==================
// Аналогичная вкладка, но для генерации изображений

class ImageAI_Tab extends StatelessWidget {
  final VoidCallback onUse;
  const ImageAI_Tab({super.key, required this.onUse});

  @override
  Widget build(BuildContext context) {
    return AppBackground.screen(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: AppGlass.container(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Иконка изображений
                SvgPicture.asset(
                  'assets/icons/image_icons.svg',
                  width: 80,
                  height: 80,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(height: 16),

                // Заголовок
                const Text('IMAGE', style: AppTextStyles.title),
                const SizedBox(height: 8),

                // Описание
                const Text('Попробуй нейронку своими руками', style: AppTextStyles.body),
                const SizedBox(height: 24),

                // Кнопка перехода
                AppButtons.primary(
                  text: 'Использовать',
                  onTap: onUse,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================== Вкладка-заглушка ==================
// Используется под будущий функционал

class PlaceholderTab extends StatelessWidget {
  final VoidCallback onUse;
  const PlaceholderTab({super.key, required this.onUse});

  @override
  Widget build(BuildContext context) {
    return AppBackground.screen(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: AppGlass.container(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Иконка людей
                SvgPicture.asset(
                  'assets/icons/people_icons.svg',
                  width: 80,
                  height: 80,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(height: 16),

                // Заголовок
                const Text('MAYBE', style: AppTextStyles.title),
                const SizedBox(height: 8),

                // Описание
                const Text('Заглушка для будущих функций', style: AppTextStyles.body),
                const SizedBox(height: 24),

                // Кнопка-заглушка
                AppButtons.primary(
                  text: 'Использовать',
                  onTap: onUse,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================== Экран-заглушка ==================

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Еще'),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: const Center(child: Text('Будущие функции')),
    );
  }
}
