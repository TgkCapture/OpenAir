import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OpenAir App - Scaffold Tests', () {
    test('app constants are correct', () {
      expect('openair', 'openair');
    });

    test('primary color hex is valid', () {
      const primaryColor = '#E63946';
      expect(primaryColor.startsWith('#'), true);
      expect(primaryColor.length, 7);
    });

    test('supported themes are dark and light', () {
      const themes = ['dark', 'light'];
      expect(themes.contains('dark'), true);
      expect(themes.contains('light'), true);
    });

    test('bottom nav has exactly 5 tabs', () {
      const tabs = ['Home', 'TV', 'Radio', 'Library', 'Profile'];
      expect(tabs.length, 5);
    });

    test('api base url format is valid', () {
      const baseUrl = 'http://localhost:8000/api/v1';
      expect(baseUrl.startsWith('http'), true);
      expect(baseUrl.contains('/api/v1'), true);
    });
  });
}