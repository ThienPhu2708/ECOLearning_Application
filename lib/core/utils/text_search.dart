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

  /// Mỗi từ của [query] phải khớp một từ trong [text] (không phân biệt hoa
  /// thường):
  /// - Từ gõ có dấu ("hà") phải khớp NGUYÊN một từ có đúng dấu đó; một âm tiết
  ///   tiếng Việt đã có dấu là gõ xong, nên "hà" không dính "hàng" hay "Hạ".
  /// - Từ gõ không dấu ("ha") khớp đầu từ ("Hà", "Hạ", "Hải", "hàng") vì có thể
  ///   đang gõ dở; với [wholeWord] thì bắt buộc khớp nguyên từ.
  /// Khớp theo từ nên "ha" không dính vào giữa "Phạm".
  static bool contains(String text, String query, {bool wholeWord = false}) {
    final tokens = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty);
    if (tokens.isEmpty) return true;
    final words = text.toLowerCase().split(RegExp(r'\s+'));
    return tokens.every((token) {
      final plain = fold(token) == token;
      if (!plain) return words.any((word) => word == token);
      return words.any(
        (word) => wholeWord
            ? fold(word) == token
            : fold(word).startsWith(token),
      );
    });
  }
}
