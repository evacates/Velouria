import 'dart:convert';

import 'package:http/http.dart' as http;

// Small RxNorm API helper for medication name lookup.
class RxNormMedicationSuggestion {
  const RxNormMedicationSuggestion({
    required this.rxcui,
    required this.name,
    this.tty,
    this.synonym,
  });

  final String rxcui;
  final String name;
  final String? tty;
  final String? synonym;
}

// More detailed RxNorm info for autofill.
class RxNormMedicationDetails {
  const RxNormMedicationDetails({
    required this.rxcui,
    required this.displayName,
    this.strength,
    this.form,
    this.tty,
    this.synonym,
  });

  final String rxcui;
  final String displayName;
  final String? strength;
  final String? form;
  final String? tty;
  final String? synonym;
}

// Does the actual network requests and response cleanup.
class RxNormService {
  RxNormService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _baseUrl = 'https://rxnav.nlm.nih.gov/REST';

  Future<List<RxNormMedicationSuggestion>> searchSuggestions(
    String query,
  ) async {
    // Search by the raw text the user typed.
    final term = query.trim();
    if (term.isEmpty) return const [];

    final uri = Uri.parse(
      '$_baseUrl/drugs.json',
    ).replace(queryParameters: {'name': term});
    final resp = await _client.get(uri);

    if (resp.statusCode != 200) {
      throw StateError('RxNorm search failed (${resp.statusCode}).');
    }

    final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
    final drugGroup = decoded['drugGroup'];
    if (drugGroup is! Map<String, dynamic>) return const [];

    final conceptGroup = drugGroup['conceptGroup'];
    if (conceptGroup is! List) return const [];

    final seen = <String>{};
    final results = <RxNormMedicationSuggestion>[];

    for (final group in conceptGroup) {
      if (group is! Map<String, dynamic>) continue;
      final concepts = group['conceptProperties'];
      if (concepts is! List) continue;

      for (final item in concepts) {
        if (item is! Map<String, dynamic>) continue;
        final rxcui = (item['rxcui'] ?? '').toString();
        final name = (item['name'] ?? '').toString();
        if (rxcui.isEmpty || name.isEmpty) continue;
        if (seen.contains(rxcui)) continue;

        seen.add(rxcui);
        results.add(
          RxNormMedicationSuggestion(
            rxcui: rxcui,
            name: name,
            tty: item['tty']?.toString(),
            synonym: item['synonym']?.toString(),
          ),
        );
      }
    }

    results.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return results.take(25).toList(growable: false);
  }

  Future<RxNormMedicationDetails> fetchDetails(String rxcui) async {
    // Look up one RxCUI and pull out the useful bits.
    final uri = Uri.parse('$_baseUrl/rxcui/$rxcui/properties.json');
    final resp = await _client.get(uri);

    if (resp.statusCode != 200) {
      throw StateError('RxNorm detail lookup failed (${resp.statusCode}).');
    }

    final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
    final properties = decoded['properties'];

    if (properties is! Map<String, dynamic>) {
      throw StateError('RxNorm did not return medication details.');
    }

    final name = (properties['name'] ?? '').toString().trim();
    if (name.isEmpty) {
      throw StateError('RxNorm medication name was empty.');
    }

    final inferredStrength = _extractStrength(name);
    final inferredForm = _extractForm(name);

    return RxNormMedicationDetails(
      rxcui: rxcui,
      displayName: name,
      strength: inferredStrength,
      form: inferredForm,
      tty: properties['tty']?.toString(),
      synonym: properties['synonym']?.toString(),
    );
  }

  String? _extractStrength(String name) {
    // Pull the dosage strength out of the display name.
    final strengthRegex = RegExp(
      r'(\d+(?:\.\d+)?)\s?(mg|mcg|g|iu|units?|ml|mL|%)',
      caseSensitive: false,
    );
    final match = strengthRegex.firstMatch(name);
    if (match == null) return null;
    return match.group(0)?.trim();
  }

  String? _extractForm(String name) {
    // Guess the dosage form from a few common keywords.
    final lower = name.toLowerCase();

    const formKeywords = <String, String>{
      'tablet': 'Tablet',
      'capsule': 'Capsule',
      'solution': 'Solution',
      'suspension': 'Suspension',
      'inhaler': 'Inhaler',
      'injectable': 'Injection',
      'injection': 'Injection',
      'patch': 'Patch',
      'cream': 'Cream',
      'ointment': 'Ointment',
      'gel': 'Gel',
      'drops': 'Drops',
      'spray': 'Spray',
      'powder': 'Powder',
    };

    for (final entry in formKeywords.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }

    return null;
  }
}
