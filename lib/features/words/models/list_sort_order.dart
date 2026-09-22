enum ListSortOrder {
  alphabeticalAsc,
  alphabeticalDesc,
  wordCountAsc,
  wordCountDesc,
  reset;

  String get label {
    switch (this) {
      case ListSortOrder.alphabeticalAsc:
        return 'A\'dan Z\'ye';
      case ListSortOrder.alphabeticalDesc:
        return 'Z\'den A\'ya';
      case ListSortOrder.wordCountDesc:
        return 'Kelime Sayısı (Çoktan Aza)';
      case ListSortOrder.wordCountAsc:
        return 'Kelime Sayısı (Azdan Çoğa)';
      case ListSortOrder.reset:
        return 'Sıralamayı Sıfırla';
    }
  }
}
