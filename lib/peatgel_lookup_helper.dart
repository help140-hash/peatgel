import 'peatgel_db.dart';

String normalizePlantName(String input) {
  var s = input.toLowerCase().trim();
  s = s.replaceAll(RegExp(r'\s+'), ' ');
  s = s.replaceAll('&', ' and ');
  s = s.replaceAll('/', ',');
  s = s.replaceAll(';', ',');
  s = s.replaceAll(' ,', ',');
  s = s.replaceAll(', ', ',');
  s = s.replaceAll(RegExp(r"[^a-z0-9,\- ]"), '');
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();

  const typoFixes = {
    'cassva': 'cassava',
    'tapoica': 'tapioca',
    'strawbery': 'strawberry',
    'strawberrry': 'strawberry',
    'chilli': 'pepper',
    'chile': 'pepper',
  };

  typoFixes.forEach((wrong, correct) {
    s = s.replaceAll(wrong, correct);
  });

  return s;
}

final Map<String, String> plantAliases = {
  'cassava,tapioca': 'cassava',
  'tapioca': 'cassava',
  'manioc': 'cassava',
  'common cassava': 'cassava',

  'beans': 'bean',
  'common bean': 'bean',

  'maize': 'corn',

  'bell pepper': 'pepper',
  'sweet pepper': 'pepper',
  'chili pepper': 'pepper',
  'chilli pepper': 'pepper',

  'melon': 'cucumis melo',
  'muskmelon': 'cucumis melo',

  'sweet cherry': 'cherry',
  'sour cherry': 'cherry',

  'grapes': 'grape',

  'garden strawberry': 'garden strawberry',
  'wild strawberries': 'wild strawberry',
  'strawberries': 'garden strawberry',

  'sugar cane': 'sugarcane',
};

PeatgelData? findPlantInDatabase(String detectedName) {
  final normalized = normalizePlantName(detectedName);

  if (peatgelDB.containsKey(normalized)) {
    return peatgelDB[normalized];
  }

  final aliasKey = plantAliases[normalized];
  if (aliasKey != null && peatgelDB.containsKey(aliasKey)) {
    return peatgelDB[aliasKey];
  }

  final parts = normalized
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  for (final part in parts) {
    if (peatgelDB.containsKey(part)) {
      return peatgelDB[part];
    }

    final aliasPart = plantAliases[part];
    if (aliasPart != null && peatgelDB.containsKey(aliasPart)) {
      return peatgelDB[aliasPart];
    }
  }

  for (final key in peatgelDB.keys) {
    if (normalized.contains(key)) {
      return peatgelDB[key];
    }
  }

  for (final key in peatgelDB.keys) {
    if (key.contains(normalized)) {
      return peatgelDB[key];
    }
  }

  return null;
}

PeatgelData? findPlantFromPlantNetResult(Map<String, dynamic> result) {
  final species = result['species'] as Map<String, dynamic>?;
  if (species == null) return null;

  final scientificName =
      species['scientificNameWithoutAuthor']?.toString() ?? '';

  final commonNames = (species['commonNames'] as List?)
          ?.map((e) => e.toString())
          .toList() ??
      [];

  for (final name in commonNames) {
    final found = findPlantInDatabase(name);
    if (found != null) return found;
  }

  if (scientificName.isNotEmpty) {
    final found = findPlantInDatabase(scientificName);
    if (found != null) return found;
  }

  return null;
}

String getDisplayPlantName(Map<String, dynamic> result) {
  final species = result['species'] as Map<String, dynamic>?;
  if (species == null) return 'Unknown plant';

  final commonNames = (species['commonNames'] as List?)
          ?.map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList() ??
      [];

  if (commonNames.isNotEmpty) {
    return commonNames.first;
  }

  return species['scientificNameWithoutAuthor']?.toString() ?? 'Unknown plant';
}

String getScientificName(Map<String, dynamic> result) {
  final species = result['species'] as Map<String, dynamic>?;
  if (species == null) return 'Unknown';
  return species['scientificNameWithoutAuthor']?.toString() ?? 'Unknown';
}
