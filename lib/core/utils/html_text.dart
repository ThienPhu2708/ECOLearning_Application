import 'package:html/dom.dart';
import 'package:html/parser.dart';

/// Converts HTML descriptions to readable text for native Flutter widgets.
String htmlToPlainText(String source) {
  final text = StringBuffer();

  void append(Node node) {
    if (node is Text) {
      text.write(node.data);
      return;
    }
    final tag = node is Element ? node.localName : null;
    if (tag == 'script' || tag == 'style' || tag == 'template') return;
    if (tag == 'br') {
      text.writeln();
      return;
    }
    final separator = switch (tag) {
      'p' ||
      'div' ||
      'blockquote' ||
      'ul' ||
      'ol' ||
      'h1' ||
      'h2' ||
      'h3' ||
      'h4' ||
      'h5' ||
      'h6' => '\n\n',
      'li' => '\n',
      _ => '',
    };
    text.write(separator);
    for (final child in node.nodes) {
      append(child);
    }
    text.write(separator);
  }

  append(parseFragment(source));
  return text
      .toString()
      .replaceAll(RegExp(r'[ \t\r]*\n[ \t\r]*'), '\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}
