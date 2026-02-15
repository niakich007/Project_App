import 'dart:ui';
import 'package:flutter/material.dart';

class AppColors {
  /// Фирменные зелёные цвета
  static const Color greenLight = Color(0xFF6FAF9A);
  static const Color greenDark = Color(0xFF1E4F43);

  /// Поверхности glassmorphism
  static const Color glassSurface = Color(0x55FFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);

  /// Текст
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xD9FFFFFF);
  static const Color textMuted = Color(0x99FFFFFF);
}

class AppGradients {
  /// Основной фон приложения
  static const LinearGradient background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColors.greenLight,
      AppColors.greenDark,
    ],
  );

  /// Акцентный градиент
  static const LinearGradient accent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF7EBFA8),
      Color(0xFF235F52),
    ],
  );
}

class AppTextStyles {
  static const TextStyle title = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
    decoration: TextDecoration.none,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    decoration: TextDecoration.none,
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    decoration: TextDecoration.none,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 13,
    color: AppColors.textMuted,
    decoration: TextDecoration.none,
  );
}


class AppGlass {
  /// Универсальный стеклянный контейнер
  static Widget container({
    required Widget child,
    double borderRadius = 24,
    double blur = 24,
    EdgeInsets padding = const EdgeInsets.all(20),
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AppColors.glassSurface,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: AppColors.glassBorder,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 30,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class AppButtons {
  /// Основная кнопка действия
  static Widget primary({
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: AppGradients.accent,
        ),
        child: Text(
          text,
          style: AppTextStyles.subtitle,
        ),
      ),
    );
  }
}

class AppBackground {
  /// Базовый фон экрана
  static Widget screen({required Widget child}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppGradients.background,
      ),
      child: SafeArea(
        child: child,
      ),
    );
  }
}
