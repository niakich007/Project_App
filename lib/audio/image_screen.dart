import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;

import 'package:project_one/app_design.dart';

class ImageScreen extends StatefulWidget {
  const ImageScreen({super.key});

  @override
  State<ImageScreen> createState() => _ImageScreenState();
}

class _ImageScreenState extends State<ImageScreen>
    with SingleTickerProviderStateMixin {
  File? _imageFile;
  String _imageName = '';
  String _predictionText = '';

  bool _isLoading = false;
  bool _isPicking = false;

  final String serverHost = Platform.isAndroid ? "10.0.2.2" : "localhost";
  final int serverPort = 8000;

  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ================== Выбор изображения ==================
  Future<void> _pickImage() async {
    if (_isPicking) return;
    _isPicking = true;
    _setLoading(true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final fileName = result.files.single.name;
      File file;

      if (result.files.single.path != null) {
        file = File(result.files.single.path!);
      } else if (result.files.single.bytes != null) {
        final tempDir = await getTemporaryDirectory();
        file = File(p.join(tempDir.path, fileName));
        await file.writeAsBytes(result.files.single.bytes!);
      } else {
        throw Exception("Не удалось получить изображение");
      }

      setState(() {
        _imageFile = file;
        _imageName = fileName;
        _predictionText = '';
      });
    } catch (e) {
      _showSnack('Ошибка при загрузке изображения: $e');
    } finally {
      _isPicking = false;
      _setLoading(false);
    }
  }

  // ================== Отправка изображения на сервер ==================
  Future<void> _analyzeImage() async {
    if (_imageFile == null) {
      _showSnack('Сначала выберите изображение');
      return;
    }

    _setLoading(true);

    try {
      final uri = Uri.parse("http://$serverHost:$serverPort/analyze_image");
      final request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('file', _imageFile!.path));

      final response = await request.send().timeout(const Duration(seconds: 20));
      final body = await response.stream.bytesToString();

      if (response.statusCode != 200) {
        throw Exception("Ошибка сервера: ${response.statusCode}\n$body");
      }

      final json = jsonDecode(body);

      if (json["error"] != null) {
        _predictionText = "Ошибка сервера: ${json["error"]}";
      } else if (json["prediction"] != null) {
        _predictionText = "Эмоция: ${json["prediction"]}";
      } else {
        _predictionText = "Эмоция не определена";
      }

      setState(() {});
    } catch (e) {
      _predictionText = "Ошибка обработки: $e";
      setState(() {});
      _showSnack("Ошибка обработки: $e");
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    setState(() => _isLoading = value);
    if (value) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _showSnack(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: AppGradients.background),
          ),
          SafeArea(
            child: Align(
              alignment: const Alignment(0, -0.1),
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: screenHeight - 24),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppGlass.container(
                          child: Column(
                            children: [
                              const Text('ИИ для изображений', style: AppTextStyles.title),
                              const SizedBox(height: 16),

                              AppButtons.primary(
                                text: _imageFile == null
                                    ? 'Загрузить изображение'
                                    : 'Загрузить другое изображение',
                                onTap: _pickImage,
                              ),

                              const SizedBox(height: 12),

                              if (_imageFile != null)
                                Text(_imageName, style: AppTextStyles.body, textAlign: TextAlign.center),

                              const SizedBox(height: 12),

                              if (_imageFile != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.file(_imageFile!, height: 180, fit: BoxFit.cover),
                                ),

                              const SizedBox(height: 16),

                              if (_imageFile != null)
                                AppButtons.primary(text: "Обработать", onTap: _analyzeImage),

                              const SizedBox(height: 16),

                              Text(
                                _predictionText.isNotEmpty
                                    ? _predictionText
                                    : "Результаты будут отображены после обработки изображения",
                                style: AppTextStyles.body,
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: 16),
                              TextButton(onPressed: () => Navigator.pop(context),
                                  child: const Text('Вернуться назад', style: AppTextStyles.body)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ===== Loading Overlay =====
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !_isLoading,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _animationController.value,
                    child: Transform.scale(
                      scale: 0.8 + 0.2 * _animationController.value,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  color: Colors.black.withOpacity(0.2),
                  alignment: Alignment.center,
                  child: AppGlass.container(
                    blur: 16,
                    padding: const EdgeInsets.all(32),
                    child: const CircularProgressIndicator(
                      color: AppColors.greenLight,
                      strokeWidth: 3,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}