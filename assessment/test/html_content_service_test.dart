import 'package:flutter_test/flutter_test.dart';
import 'package:winp_flux_assessment/services/html_content_service.dart';

void main() {
  group('HtmlContentService.stripTags', () {
    final service = HtmlContentService();

    test('removes simple HTML tags and trims whitespace', () {
      const html = '  <p>Hello <strong>world</strong></p>  ';
      final result = service.stripTags(html);
      expect(result, 'Hello world');
    });

    test('returns empty string for empty input', () {
      const html = '';
      final result = service.stripTags(html);
      expect(result, '');
    });

    test('returns empty string for whitespace-only input', () {
      const html = '   \n\t  ';
      final result = service.stripTags(html);
      expect(result, '');
    });

    test('does not modify plain text without tags', () {
      const html = 'Just some plain text';
      final result = service.stripTags(html);
      expect(result, html);
    });
  });

  group('HtmlContentService.hasBlockContent', () {
    final service = HtmlContentService();

    test('detects paragraph block tag', () {
      const html = '<p>Paragraph</p>';
      expect(service.hasBlockContent(html), isTrue);
    });

    test('detects heading block tags case-insensitively', () {
      const html = '<H2>Title</H2>';
      expect(service.hasBlockContent(html), isTrue);
    });

    test('detects list block tags (ul/ol)', () {
      const html = '<ul><li>Item</li></ul>';
      expect(service.hasBlockContent(html), isTrue);
    });

    test('returns false when only inline tags are present', () {
      const html = '<span>Text</span><strong>more</strong><em>here</em>';
      expect(service.hasBlockContent(html), isFalse);
    });
  });
}
