/// Pure-Dart Devanagari text pre-shaper for PDF rendering.
///
/// TrueType fonts embed complex script glyphs (pre-base vowel signs like
/// short 'i' matra \u093F and conjuncts) without direct Unicode mappings.
/// Because Flutter's `pdf` package does not bundle HarfBuzz/OpenType GSUB shaping,
/// raw Unicode Devanagari draws pre-base matras *after* the consonant (e.g.
/// "विभाग" -> "वभिाग", "साप्ताहिक" -> "साप्ताहकि", "मासिक" -> "मासकि").
///
/// This shaper reorders pre-base vowel signs before their consonant cluster
/// so that TrueType glyph advance and horizontal metrics render authentic,
/// visually correct Devanagari text.
class DevanagariShaper {
  DevanagariShaper._();

  static const int _matraI = 0x093F; // ि
  static const int _halant = 0x094D; // ्
  static const int _nukta = 0x093C;  // ़

  /// Returns true if [codeUnit] is a Devanagari consonant.
  static bool isConsonant(int codeUnit) {
    return (codeUnit >= 0x0915 && codeUnit <= 0x0939) ||
        (codeUnit >= 0x0958 && codeUnit <= 0x095F);
  }

  /// Shapes [input] string for PDF TrueType rendering by reordering
  /// pre-base vowel signs before the preceding consonant cluster.
  static String shape(String? input) {
    if (input == null || input.isEmpty) return '';

    final codeUnits = input.runes.toList();
    final n = codeUnits.length;
    final out = <int>[];
    int i = 0;

    while (i < n) {
      final code = codeUnits[i];

      if (code == _matraI) {
        // Matra 'i' (ि): Must precede the consonant or consonant cluster
        if (out.isEmpty) {
          out.add(code);
          i++;
          continue;
        }

        // Backtrack to find the start of the consonant cluster
        int idx = out.length - 1;

        // Skip preceding nukta if present
        if (idx >= 0 && out[idx] == _nukta) {
          idx--;
        }

        if (idx >= 0 && isConsonant(out[idx])) {
          idx--;
          // Traverse backwards across conjuncts: halant + consonant
          while (idx >= 1 && out[idx] == _halant && isConsonant(out[idx - 1])) {
            idx -= 2;
          }
          final clusterStart = idx + 1;
          out.insert(clusterStart, _matraI);
        } else {
          out.add(code);
        }
        i++;
      } else {
        out.add(code);
        i++;
      }
    }

    return String.fromCharCodes(out);
  }
}
