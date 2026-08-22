class SafetyFilterService {
  static final List<String> _forbiddenKeywords = [
    "küfür", "hakaret", "dolandırıcı", "sahtekar", "tehdit", "taciz",
    "şerefsiz", "salak", "aptal", "gerizekalı", "piç", "ibne", "orospu",
    "yavşak", "pezevenk", "amk", "aq", "sg", "oç", "sik", "yarrak",
  ];

  /// Metinde uygunsuz, taciz veya hakaret içeren ifade var mı kontrol eder
  static bool containsInappropriateContent(String text) {
    if (text.trim().isEmpty) return false;
    final lower = text.toLowerCase();
    for (var word in _forbiddenKeywords) {
      if (lower.contains(word)) return true;
    }
    return false;
  }

  /// Uygunsuz kelimeleri yıldızla maskeler
  static String maskInappropriateContent(String text) {
    String masked = text;
    for (var word in _forbiddenKeywords) {
      final pattern = RegExp(RegExp.escape(word), caseSensitive: false);
      masked = masked.replaceAllMapped(pattern, (match) => '*' * match.group(0)!.length);
    }
    return masked;
  }
}
