import 'package:flutter_test/flutter_test.dart';
import 'package:dreadmoor/core/models/script_models.dart';

void main() {
  group('EventScript JSON Serialization', () {
    test('should parse basic fields correctly fromJson', () {
      final json = {
        'id': 'e1',
        'type': 'message',
        'threadId': 't1',
        'sender': 'rebecca',
        'text': 'Hello',
        'duration': 500,
      };

      final event = EventScript.fromJson(json);

      expect(event.id, 'e1');
      expect(event.type, 'message');
      expect(event.threadId, 't1');
      expect(event.sender, 'rebecca');
      expect(event.text, 'Hello');
      expect(event.duration, 500);
      expect(event.meta, isNull);
      expect(event.options, isNull);
    });

    test('should parse meta field correctly fromJson', () {
      final json = {
        'id': 'e2',
        'type': 'typing',
        'meta': {'delayAfter': 1000}
      };

      final event = EventScript.fromJson(json);

      expect(event.meta, isNotNull);
      expect(event.meta!.delayAfter, 1000);
    });

    test('should parse options field correctly fromJson', () {
      final json = {
        'id': 'e3',
        'type': 'choice',
        'options': [
          {'text': 'Option 1', 'jumpto': 's1'},
          {'text': 'Option 2', 'jumpto': 's2'}
        ]
      };

      final event = EventScript.fromJson(json);

      expect(event.options, isNotNull);
      expect(event.options!.length, 2);
      expect(event.options![0].text, 'Option 1');
      expect(event.options![0].jumpto, 's1');
      expect(event.options![1].text, 'Option 2');
      expect(event.options![1].jumpto, 's2');
    });

    test('should serialize to JSON correctly (explicitToJson: true)', () {
      final event = EventScript(
        id: 'e5',
        type: 'choice',
        meta: EventMeta(delayAfter: 2000),
        options: [
          ChoiceOption(text: 'Yes', jumpto: 'scene_yes'),
        ],
      );

      final json = event.toJson();

      expect(json['id'], 'e5');
      expect(json['meta'], isA<Map<String, dynamic>>());
      expect(json['meta']['delayAfter'], 2000);
      expect(json['options'], isA<List>());
      expect(json['options'][0], isA<Map<String, dynamic>>());
      expect(json['options'][0]['text'], 'Yes');
      expect(json['options'][0]['jumpto'], 'scene_yes');
    });

    test('should handle missing optional fields', () {
      final json = {
        'id': 'e4',
        'type': 'system',
      };

      final event = EventScript.fromJson(json);

      expect(event.id, 'e4');
      expect(event.type, 'system');
      expect(event.threadId, isNull);
      expect(event.sender, isNull);
      expect(event.text, isNull);
      expect(event.meta, isNull);
      expect(event.options, isNull);

      final backToJson = event.toJson();
      expect(backToJson['meta'], isNull);
      expect(backToJson['options'], isNull);
    });
  });
}
