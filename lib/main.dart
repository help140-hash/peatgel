import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'peatgel_db.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
            // Локализация
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ru'),
      ],
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,

      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

// ─── ГЛАВНАЯ СТРАНИЦА ───────────────────────────────────────────
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.appTitle,            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AboutPage())),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Логотип / иконка
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(Icons.eco, size: 72, color: Colors.green[700]),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.identifyPlant,              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Сфотографируйте растение\nи узнайте его название',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 40),
            // Кнопка камера
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                    const PlantPage(source: ImageSource.camera),
                  ),
                ),
                icon: const Icon(Icons.camera_alt, size: 22),
              label: Text(AppLocalizations.of(context)!.takePhoto,                    style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Кнопка галерея
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                    const PlantPage(source: ImageSource.gallery),
                  ),
                ),
                icon: const Icon(Icons.photo_library, size: 22),
              label: Text(AppLocalizations.of(context)!.uploadImage,                    style: TextStyle(fontSize: 16)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green[700],
                  side: BorderSide(color: Colors.green[700]!, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── СТРАНИЦА ОПРЕДЕЛЕНИЯ ────────────────────────────────────────
class PlantPage extends StatefulWidget {
  final ImageSource source;
  const PlantPage({super.key, required this.source});

  @override
  State<PlantPage> createState() => _PlantPageState();
}

class _PlantPageState extends State<PlantPage> {
  File? _image;
  bool _loading = false;
  List<dynamic> _results = [];
  String _error = '';

  final _picker = ImagePicker();
  final _url = 'https://help-iv-plantnet-proxy.hf.space/identify';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pickImage(widget.source);
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (picked == null) {
        if (mounted) Navigator.pop(context);
        return;
      }
      final file = File(picked.path);
      setState(() {
        _image = file;
        _results = [];
        _error = '';
      });
      await _identify(file);
    } catch (e) {
      setState(() => _error = 'Ошибка: $e');
    }
  }

  Future<void> _identify(File file) async {
    setState(() {
      _loading = true;
      _error = '';
      _results = [];
    });

    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        final request = http.MultipartRequest('POST', Uri.parse(_url));
        request.files.add(
          await http.MultipartFile.fromPath('image', file.path),
        );
        final streamed =
        await request.send().timeout(const Duration(seconds: 60));
        final body = await streamed.stream.bytesToString();

        if (streamed.statusCode == 200) {
          final data = jsonDecode(body);
          setState(() {
            _results = data['results'] ?? [];
            _loading = false;
          });
          return;
        } else {
          setState(() => _error = 'Ошибка сервера: ${streamed.statusCode}');
        }
      } catch (e) {
        if (attempt < 3) {
          setState(() => _error = 'Попытка $attempt/3... сервер просыпается');
          await Future.delayed(const Duration(seconds: 10));
        } else {
          setState(() => _error = 'Ошибка после 3 попыток: $e');
        }
      }
    }
    setState(() => _loading = false);
  }

  PeatgelData? _findPeatgel(List<dynamic> results) {
    for (final r in results) {
      final species = r['species'];
      final sciName =
      (species?['scientificNameWithoutAuthor'] ?? '').toLowerCase();
      final commonNames = (species?['commonNames'] as List?)
          ?.map((e) => e.toString().toLowerCase())
          .toList() ??
          [];
      for (final key in peatgelDB.keys) {
        if (sciName.contains(key) ||
            commonNames.any((n) => n.contains(key))) {
          return peatgelDB[key];
        }
      }
    }
    return null;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        title: const Text('Результат'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt),
            tooltip: 'Новое фото',
            onPressed: () => _pickImage(ImageSource.camera),
          ),
          IconButton(
            icon: const Icon(Icons.photo_library),
            tooltip: 'Из галереи',
            onPressed: () => _pickImage(ImageSource.gallery),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Фото
            if (_image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  _image!,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 12),

            // Загрузка
            if (_loading)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const CircularProgressIndicator(color: Colors.green),
                    const SizedBox(height: 10),
                    Text(
                      _error.isNotEmpty
                          ? _error
                          : 'Определяем растение...',
                      style: const TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

            // Ошибка
            if (!_loading && _error.isNotEmpty && _results.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error,
                          style: TextStyle(color: Colors.red[700])),
                    ),
                  ],
                ),
              ),

            // Результаты
            if (_results.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Результаты:',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              ...List.generate(
                _results.length > 5 ? 5 : _results.length,
                    (i) {
                  final r = _results[i];
                  final species = r['species'];
                  final score =
                  ((r['score'] ?? 0.0) * 100).toStringAsFixed(1);
                  final sciName =
                      species?['scientificNameWithoutAuthor'] ?? '—';
                  final commonNames =
                      (species?['commonNames'] as List?)
                          ?.take(2)
                          .join(', ') ??
                          '';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.green[700],
                        child: Text(
                          '$score%',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11),
                        ),
                      ),
                      title: Text(sciName,
                          style: const TextStyle(
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                      subtitle: commonNames.isNotEmpty
                          ? Text(commonNames,
                          style: const TextStyle(fontSize: 12))
                          : null,
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Builder(builder: (context) {
                final peatgel = _findPeatgel(_results);
                  );
                }
                return Card(
                  color: Colors.green[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.green[700]!),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.eco, color: Colors.green[700]),
                            const SizedBox(width: 8),
                            Text(
                              'Peatgel для: ${peatgel.name}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[800],
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PeatgelPage(data: peatgel),
                            ),
                          ),
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Инструкция по применению'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}


// ─── СТРАНИЦА О ПРИЛОЖЕНИИ ───────────────────────────────────────
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('О приложении'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Peatgel Digital',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800])),
            const SizedBox(height: 8),
            const Text('Версия 1.0.0', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            const Text(
              'Приложение для определения растений по фотографии. '
                  'Использует базу данных PlantNet — более 40 000 видов растений.',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 20),
            Text('Технологии:',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green[700])),
            const SizedBox(height: 8),
            const Text('• Flutter (Android)'),
            const Text('• PlantNet API'),
            const Text('• Hugging Face (прокси-сервер)'),
          ],
        ),
      ),
    );
  }
}

// ─── СТРАНИЦА PEATGEL ────────────────────────────────────────────
class PeatgelPage extends StatelessWidget {
  final PeatgelData data;
  const PeatgelPage({super.key, required this.data});

  Widget _section(String title, String content, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 15)),
              ],
            ),
            const SizedBox(height: 8),
            Text(content, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        title: Text('Peatgel — ${data.name}'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _section('Обработка почвы', data.soil,
                Icons.landscape, Colors.brown),
            _section('Обработка семян', data.seeds,
                Icons.grain, Colors.orange[700]!),
            _section('Период вегетации', data.vegetation,
                Icons.grass, Colors.green[700]!),
            _section('Дозировка', data.dose,
                Icons.water_drop, Colors.blue[700]!),
          ],
        ),
      ),
    );
  }
}

