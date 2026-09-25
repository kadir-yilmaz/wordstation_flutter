import 'package:flutter_test/flutter_test.dart';
import 'package:wordstation_flutter/core/services/tts_service.dart';
import 'package:wordstation_flutter/features/words/controllers/study_controller.dart';
import 'package:wordstation_flutter/features/words/models/synonym_group_model.dart';
import 'package:wordstation_flutter/features/words/models/word_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SynonymGroupModel - Tests', () {
    test('SynonymGroupModel serialization and deserialization', () {
      final json = {
        'turkish': 'hızlı',
        'words': [
          {'en': 'fast', 'tr': 'hızlı'},
          {'en': 'quick', 'tr': 'hızlı'},
          {'en': 'rapid', 'tr': 'hızlı'},
        ],
      };

      final group = SynonymGroupModel.fromJson(json);
      expect(group.turkishMeaning, 'hızlı');
      expect(group.words.length, 3);
      expect(group.words.first.en, 'fast');

      final serialized = group.toJson();
      expect(serialized['turkishMeaning'], 'hızlı');
      expect((serialized['words'] as List).length, 3);
    });
  });

  group('StudyController - Logic & State Tests', () {
    late StudyController controller;

    setUp(() {
      controller = StudyController(TtsService());
    });

    test('Matches synonyms from global vocabulary when studying isolated sublist', () {
      const word1 = WordModel(id: 1, en: 'abundant', tr: 'bol, çok', listName: 'Day 1');
      const word2 = WordModel(id: 2, en: 'plentiful', tr: 'bol; bereketli', listName: 'Day 2');
      const word3 = WordModel(id: 3, en: 'sparse', tr: 'kıt, seyrek', listName: 'Day 3');

      // Studying only Day 1 word1, but index built with entire vocabulary [word1, word2, word3]
      controller.initWithWords([word1], allVocabularyWords: [word1, word2, word3]);

      expect(controller.state.synonymBadges.isNotEmpty, isTrue);
      expect(controller.state.synonymBadges.first.word.en, 'plentiful');
      expect(controller.state.synonymBadges.first.matchedMeaning, 'bol');
    });

    test('Flip card toggle switches isFlipped state', () {
      const word1 = WordModel(id: 1, en: 'ephemeral', tr: 'geçici');
      controller.initWithWords([word1]);

      expect(controller.state.isFlipped, isFalse);
      controller.flip();
      expect(controller.state.isFlipped, isTrue);
      controller.flip();
      expect(controller.state.isFlipped, isFalse);
    });

    test('next and prev correctly navigate and clamp index', () {
      final words = [
        const WordModel(id: 1, en: 'word_1', tr: 'kelime_1'),
        const WordModel(id: 2, en: 'word_2', tr: 'kelime_2'),
        const WordModel(id: 3, en: 'word_3', tr: 'kelime_3'),
      ];

      controller.initWithWords(words);
      expect(controller.state.currentIndex, 0);

      // Move next
      controller.next();
      expect(controller.state.currentIndex, 1);

      controller.next();
      expect(controller.state.currentIndex, 2);

      // Clamped at end
      controller.next();
      expect(controller.state.currentIndex, 2);

      // Move back
      controller.prev();
      expect(controller.state.currentIndex, 1);

      controller.prev();
      expect(controller.state.currentIndex, 0);

      // Clamped at start
      controller.prev();
      expect(controller.state.currentIndex, 0);
    });

    test('seekTo and search query filtering update visible word and index', () {
      final words = [
        const WordModel(id: 1, en: 'apple', tr: 'elma'),
        const WordModel(id: 2, en: 'banana', tr: 'muz'),
        const WordModel(id: 3, en: 'cherry', tr: 'kiraz'),
      ];

      controller.initWithWords(words);

      // Jump directly to cherry (index 2)
      controller.seekTo(2);
      expect(controller.state.currentIndex, 2);
      expect(controller.state.currentWord?.en, 'cherry');

      // Filter by search query (default startsWith)
      controller.onSearchChanged('ban');
      expect(controller.state.words.length, 1);
      expect(controller.state.currentWord?.en, 'banana');

      // 'err' doesn't start with any word in startsWith mode
      controller.onSearchChanged('err');
      expect(controller.state.words.isEmpty, true);

      // Toggle to contains mode: 'err' matches 'cherry'
      controller.toggleSearchMode();
      expect(controller.state.isSearchContains, true);
      expect(controller.state.words.length, 1);
      expect(controller.state.currentWord?.en, 'cherry');

      // Clear search restores all words
      controller.onSearchChanged('');
      expect(controller.state.words.length, 3);
    });
  });
}
