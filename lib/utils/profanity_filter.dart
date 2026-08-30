class ProfanityFilter {
  static bool hasProfanity(String text) {
    if (text.isEmpty) return false;
    
    final badWords = [
      'siker', 'sik', 'amk', 'oç', 'orospu', 'pic', 'piç', 
      'yarak', 'yarrak', 'amcık', 'siktir', 'göt', 'ibne', 'pezevenk'
    ];
    
    final lowerText = text.toLowerCase().replaceAll(RegExp(r'\s+'), ''); // Boşlukları silerek bitişik yazımları da yakala
    
    for (var word in badWords) {
      if (lowerText.contains(word)) {
        return true;
      }
    }
    
    return false;
  }
}
