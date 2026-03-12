class HtmlContentService {
  String stripTags(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  bool hasBlockContent(String html) {
    return RegExp(r'<(p|div|ul|ol|h[1-6])', caseSensitive: false)
        .hasMatch(html);
  }
}
