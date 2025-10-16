import 'package:flutter_test/flutter_test.dart';
import 'package:alex/services/safety_service.dart';

void main() {
  group('SafetyService', () {
    setUpAll(() async {
      // Initialize the safety service before running tests
      await SafetyService.initialize();
    });

    test('should detect sensitive content in suicidal messages', () {
      expect(SafetyService.containsSensitiveContent('I want to kill myself'), isTrue);
      expect(SafetyService.containsSensitiveContent('I am going to end it all'), isTrue);
      expect(SafetyService.containsSensitiveContent('Life is not worth living anymore'), isTrue);
      expect(SafetyService.containsSensitiveContent('I want to die'), isTrue);
    });

    test('should detect sensitive content in self-harm messages', () {
      expect(SafetyService.containsSensitiveContent('I want to cut myself'), isTrue);
      expect(SafetyService.containsSensitiveContent('I am going to hurt myself'), isTrue);
      expect(SafetyService.containsSensitiveContent('I want to harm myself'), isTrue);
    });

    test('should not flag normal conversation as sensitive', () {
      expect(SafetyService.containsSensitiveContent('How are you today?'), isFalse);
      expect(SafetyService.containsSensitiveContent('What is the weather like?'), isFalse);
      expect(SafetyService.containsSensitiveContent('I love programming'), isFalse);
      expect(SafetyService.containsSensitiveContent('Tell me a joke'), isFalse);
    });

    test('should provide help resources', () {
      final resources = SafetyService.getHelpResources();
      expect(resources, isNotEmpty);
      expect(resources.length, greaterThan(5)); // Should have multiple resources
    });

    test('should generate safe response', () {
      final response = SafetyService.generateSafeResponse();
      expect(response, isNotEmpty);
      expect(response, contains('concerned'));
      expect(response, contains('resources'));
    });

    test('should be initialized after setup', () {
      expect(SafetyService.isInitialized, isTrue);
    });
  });
}