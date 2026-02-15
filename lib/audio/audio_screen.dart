import 'dart:io';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;

import 'package:project_one/app_design.dart';

class AudioScreen extends StatefulWidget {
  const AudioScreen({super.key});

  @override
  State<AudioScreen> createState() => _AudioScreenState();
}

class _AudioScreenState extends State<AudioScreen> with SingleTickerProviderStateMixin {
  File? _audioFile;
  String _audioName = '';

  bool _isLoading = false;
  bool _isPicking = false;
  bool _isPlaying = false;
  bool _playedOnce = false;

  double _durationSec = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();

  String? _selectedModel;
  String _predictionText = '';

  // =========================
  // Обновлённый список моделей для чекпоинтов сервера
  // =========================
  final Map<String, String> _models = {
    "ResNet 1 источник": "resnet_1sources",
    "ResNet 2 источника": "resnet_2sources",
    "ResNet 3 источника": "resnet_3sources",
    "EfficientNet 1 источник": "efficientnet_1sources",
    "EfficientNet 2 источника": "efficientnet_2sources",
    "EfficientNet 3 источника": "efficientnet_3sources",
  };

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
    _audioPlayer.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // ================== Загрузка аудио ==================
  Future<void> _pickAudio() async {
    if (_isPicking) return;
    _isPicking = true;
    _setLoading(true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
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
        throw Exception("Не удалось получить аудиофайл");
      }

      await _audioPlayer.stop();
      await _audioPlayer.setFilePath(file.path);
      _durationSec = (_audioPlayer.duration?.inMilliseconds.toDouble() ?? 0) / 1000;

      if (_durationSec > 60) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Аудио должно быть не более 60 секунд')),
        );
        return;
      }

      setState(() {
        _audioFile = file;
        _audioName = fileName;
        _isPlaying = false;
        _playedOnce = false;
        _predictionText = '';
        _selectedModel = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при загрузке аудио: $e')),
      );
    } finally {
      _isPicking = false;
      _setLoading(false);
    }
  }

  // ================== Воспроизведение ==================
  Future<void> _playAudio() async {
    if (_audioFile == null || _playedOnce) return;

    try {
      await _audioPlayer.play();
      setState(() {
        _isPlaying = true;
        _playedOnce = true;
      });

      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          setState(() => _isPlaying = false);
        }
      });
    } catch (e) {
      print('Ошибка воспроизведения: $e');
    }
  }

  Future<void> _pauseAudio() async {
    await _audioPlayer.pause();
    setState(() => _isPlaying = false);
  }

  Future<void> _stopAudio() async {
    await _audioPlayer.stop();
    setState(() => _isPlaying = false);
  }

  // ================== Анализ аудио ==================
  Future<void> _analyzeAudio() async {
    if (_audioFile == null || _selectedModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите аудио и модель')),
      );
      return;
    }

    _setLoading(true);

    try {
      var request = http.MultipartRequest(
          'POST',
          Uri.parse("http://10.0.2.2:8000/analyze") // Для iOS может быть http://127.0.0.1:8000/analyze
      );

      request.fields['model_code'] = _selectedModel!;
      request.files.add(await http.MultipartFile.fromPath('file', _audioFile!.path));

      var response = await request.send();
      var body = await response.stream.bytesToString();

      final json = jsonDecode(body);

      if (json["detected"] != null) {
        List list = json["detected"];
        _predictionText = list.isNotEmpty
            ? "Предсказанные классы: ${list.join(", ")}"
            : "Предсказанные классы: отсутствуют";
      } else {
        _predictionText = "Предсказанные классы: отсутствуют";
      }

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка анализа: $e')),
      );
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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // ===== Единый фон =====
          Container(
            decoration: const BoxDecoration(
              gradient: AppGradients.background,
            ),
          ),

          // ===== Контент =====
          SafeArea(
            child: Align(
              alignment: const Alignment(0, -0.1),
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: screenHeight - 24,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        AppGlass.container(
                          child: Column(
                            children: [
                              const Text('Аудио нейронка', style: AppTextStyles.title),
                              const SizedBox(height: 16),
                              AppButtons.primary(
                                text: _audioFile == null
                                    ? 'Загрузить аудио'
                                    : 'Загрузить другое аудио',
                                onTap: _pickAudio,
                              ),
                              const SizedBox(height: 16),
                              if (_audioFile != null)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      iconSize: 48,
                                      icon: SvgPicture.asset(
                                        _isPlaying
                                            ? 'assets/icons/pause.svg'
                                            : 'assets/icons/play.svg',
                                      ),
                                      onPressed: _isPlaying ? _pauseAudio : _playAudio,
                                    ),
                                    const SizedBox(width: 16),
                                    IconButton(
                                      iconSize: 48,
                                      icon: SvgPicture.asset('assets/icons/stop.svg'),
                                      onPressed: _stopAudio,
                                    ),
                                    const SizedBox(width: 16),
                                    AppButtons.primary(
                                      text: "Отправить на анализ",
                                      onTap: _analyzeAudio,
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 16),
                              if (_audioFile != null)
                                AppGlass.container(
                                  borderRadius: 16,
                                  blur: 12,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    value: _selectedModel,
                                    underline: const SizedBox(),
                                    hint: const Text('Выберите модель нейронки'),
                                    items: _models.entries.map((e) {
                                      return DropdownMenuItem(
                                        value: e.value,
                                        child: Text(e.key),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      setState(() => _selectedModel = val);
                                    },
                                  ),
                                ),
                              const SizedBox(height: 16),
                              Text(
                                _predictionText.isNotEmpty
                                    ? _predictionText
                                    : "Предсказанные классы:",
                                style: AppTextStyles.body,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Вернуться назад', style: AppTextStyles.body),
                              ),
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
