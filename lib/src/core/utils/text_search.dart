/// Busca texto sin distinguir mayúsculas ni tildes: «cancion» encuentra
/// «Canción» y «JOSE» encuentra «José».
abstract final class TextSearch {
  static const String _from = 'áàäâãéèëêíìïîóòöôõúùüûñç';
  static const String _to = 'aaaaaeeeeiiiiooooouuuunc';

  /// El texto en minúsculas y sin tildes, con los espacios sobrantes quitados.
  static String normalize(String text) {
    final lower = text.toLowerCase();
    final out = StringBuffer();
    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      final at = _from.indexOf(char);
      out.write(at == -1 ? char : _to[at]);
    }
    return out.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Si [haystack] contiene todas las palabras de [query], en cualquier orden.
  /// Una búsqueda vacía coincide con todo.
  static bool matches(String haystack, String query) {
    final words = normalize(query).split(' ').where((w) => w.isNotEmpty);
    if (words.isEmpty) return true;
    final target = normalize(haystack);
    return words.every(target.contains);
  }
}
