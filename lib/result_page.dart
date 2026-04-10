import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'peatgel_db.dart';
import 'peatgel_lookup_helper.dart';

class ResultPage extends StatelessWidget {
  final File imageFile;
  final Map<String, dynamic> data;

  const ResultPage({
    super.key,
    required this.imageFile,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final results = (data['results'] as List?) ?? [];
    final firstResult = results.isNotEmpty ? results.first as Map<String, dynamic> : null;

    final peatgelItem =
        firstResult != null ? findPlantFromPlantNetResult(firstResult) : null;

    final displayName =
        firstResult != null ? getDisplayPlantName(firstResult) : 'Unknown plant';

    final scientificName =
        firstResult != null ? getScientificName(firstResult) : 'Unknown';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Результат'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(
                imageFile,
                width: double.infinity,
                height: 260,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Results:',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...results.take(5).map((item) {
              final result = item as Map<String, dynamic>;
              final species = result['species'] as Map<String, dynamic>?;
              final score = ((result['score'] ?? 0.0) as num) * 100;

              final commonNames = (species?['commonNames'] as List?)
                      ?.map((e) => e.toString())
                      .where((e) => e.trim().isNotEmpty)
                      .toList() ??
                  [];

              final title = commonNames.isNotEmpty
                  ? commonNames.first
                  : (species?['scientificNameWithoutAuthor']?.toString() ?? 'Unknown');

              final latinName =
                  species?['scientificNameWithoutAuthor']?.toString() ?? 'Unknown';

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${score.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            latinName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontStyle: FontStyle.italic,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),
            if (peatgelItem != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.orange, width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.info_outline, color: Colors.orange),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Найдена культура в базе Peatgel',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Название: ${peatgelItem.name}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    Text('Почва: ${peatgelItem.soil}'),
                    const SizedBox(height: 8),
                    Text('Семена: ${peatgelItem.seeds}'),
                    const SizedBox(height: 8),
                    Text('Вегетация: ${peatgelItem.vegetation}'),
                    const SizedBox(height: 8),
                    Text('Дозировка: ${peatgelItem.dose}'),
                  ],
                ),
              )
            else if (firstResult != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.orange, width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.info_outline, color: Colors.orange),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Культура не была найдена в базе данных Peatgel',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Определено как: $displayName'),
                    const SizedBox(height: 4),
                    Text('Латинское название: $scientificName'),
                    const SizedBox(height: 8),
                    const Text(
                      'Проверь базу peatgel_db.dart или добавь алиас в peatgel_lookup_helper.dart',
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Пример перехода на экран результата:
// Navigator.push(
//   context,
//   MaterialPageRoute(
//     builder: (_) => ResultPage(
//       imageFile: _imageFile!,
//       data: json.decode(response.body) as Map<String, dynamic>,
//     ),
//   ),
// );
