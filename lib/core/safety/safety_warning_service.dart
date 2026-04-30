class SafetyWarningService {
  const SafetyWarningService();

  // Allergy keywords that should trigger a warning.
  static const Map<String, String> _allergyKeywordWarnings = {
    'penicillin': 'Possible penicillin allergy risk.',
    'sulfa': 'Possible sulfa allergy risk.',
    'aspirin': 'Aspirin-related allergy warning.',
    'ibuprofen': 'NSAID sensitivity warning.',
    'amphetamine': 'Stimulant sensitivity warning.',
  };

  // Extra reaction warnings that are more about side effects.
  static const Map<String, String> _reactionKeywords = {
    'adderall':
        'Stimulants may increase heart rate, blood pressure, and anxiety.',
    'metformin':
        'Watch for gastrointestinal side effects and dehydration symptoms.',
    'warfarin': 'Bleeding risk: monitor interactions and INR as directed.',
    'prednisone': 'Steroid use can affect mood, sleep, and blood sugar.',
    'lisinopril': 'ACE inhibitors may cause cough or angioedema in rare cases.',
  };

  List<String> warningsFor({
    required String medicationName,
    required List<String> allergyKeywords,
  }) {
    // Run a lazy keyword check and collect any matches.
    final lower = medicationName.toLowerCase().trim();
    if (lower.isEmpty) return const [];

    final warnings = <String>{};

    for (final allergy in allergyKeywords) {
      final a = allergy.toLowerCase().trim();
      if (a.isEmpty) continue;

      for (final entry in _allergyKeywordWarnings.entries) {
        final keyword = entry.key;
        final matchesAllergy = a.contains(keyword) || keyword.contains(a);
        final matchesMedication = lower.contains(keyword);
        if (matchesAllergy && matchesMedication) {
          warnings.add(entry.value);
        }
      }
    }

    for (final entry in _reactionKeywords.entries) {
      if (lower.contains(entry.key)) {
        warnings.add(entry.value);
      }
    }

    return warnings.toList(growable: false);
  }
}
