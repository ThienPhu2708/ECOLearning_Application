/// So khớp văn bản tiếng Việt không phân biệt hoa thường và dấu
/// ("tran minh khoa" khớp "Trần Minh Khoa").
class TextSearch {
  TextSearch._();

  static const _from =
      'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
  static const _to =
      'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';

  static String fold(String input) {
    final buffer = StringBuffer();
    for (final rune in input.toLowerCase().runes) {
      final ch = String.fromCharCode(rune);
      final i = _from.indexOf(ch);
      buffer.write(i >= 0 ? _to[i] : ch);
    }
    return buffer.toString().trim();
  }

  static bool contains(String text, String query) {
    final q = fold(query);
    return q.isEmpty || fold(text).contains(q);
  }
}
