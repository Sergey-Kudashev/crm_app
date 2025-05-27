/// Перетворює рядок в нижній регістр (для запису в базу)
String toLowerCaseTrimmed(String text) {
  return text.trim().toLowerCase();
}

/// Форматує рядок, щоб кожне слово починалося з великої літери (для відображення)
String capitalizeWords(String text) {
  if (text.isEmpty) return text;

  return text
      .split(RegExp(r'\s+'))  // Розбиваємо по одному чи більше пробілів
      .map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      })
      .join(' ');
}
