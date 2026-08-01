/// Normalizes text for deterministic, diacritic-insensitive lookup.
String normalizeSearchText(String value) {
  var normalized = value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  const replacements = <String, String>{
    'àáâãäåāăąǎ': 'a',
    'çćĉċč': 'c',
    'ďđ': 'd',
    'èéêëēĕėęě': 'e',
    'ĝğġģ': 'g',
    'ĥħ': 'h',
    'ìíîïĩīĭįı': 'i',
    'ĵ': 'j',
    'ķ': 'k',
    'ĺļľŀł': 'l',
    'ñńņňŉŋ': 'n',
    'òóôõöøōŏőǒ': 'o',
    'ŕŗř': 'r',
    'śŝşš': 's',
    'ţťŧ': 't',
    'ùúûüũūŭůűųǔ': 'u',
    'ýÿŷ': 'y',
    'źżž': 'z',
  };
  for (final entry in replacements.entries) {
    for (final character in entry.key.runes) {
      normalized = normalized.replaceAll(
        String.fromCharCode(character),
        entry.value,
      );
    }
  }
  return normalized
      .replaceAll('æ', 'ae')
      .replaceAll('œ', 'oe')
      .replaceAll('ß', 'ss');
}
