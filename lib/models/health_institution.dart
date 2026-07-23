import 'package:cloud_firestore/cloud_firestore.dart';

class HealthInstitution {
  final String id;
  final String name;
  final String type;
  final String address;
  final String phone;

  const HealthInstitution({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.phone,
  });

  factory HealthInstitution.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    String text(String key) => data[key]?.toString().trim() ?? '';

    return HealthInstitution(
      id: document.id,
      name: text('nom').isNotEmpty
          ? text('nom')
          : (text('displayName').isNotEmpty
                ? text('displayName')
                : text('name')),
      type: text('type').isNotEmpty ? text('type') : text('category'),
      address: text('adresse').isNotEmpty ? text('adresse') : text('address'),
      phone: text('telephone').isNotEmpty ? text('telephone') : text('phone'),
    );
  }

  bool matches(String query) {
    final normalized = _normalize(query);
    if (normalized.isEmpty) return true;
    return _normalize('$name $type $address').contains(normalized);
  }

  static String _normalize(String value) {
    const accents = <String, String>{
      'à': 'a',
      'â': 'a',
      'ä': 'a',
      'á': 'a',
      'ç': 'c',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'î': 'i',
      'ï': 'i',
      'í': 'i',
      'ô': 'o',
      'ö': 'o',
      'ó': 'o',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ú': 'u',
    };
    var normalized = value.toLowerCase();
    for (final entry in accents.entries) {
      normalized = normalized.replaceAll(entry.key, entry.value);
    }
    return normalized
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}
