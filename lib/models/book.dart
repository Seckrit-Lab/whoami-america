import 'package:flutter/material.dart';

/// Represents a book in the Tada format
class Book {
  final String title;
  final List<Character> characters;
  final String setting;
  final List<Outcome> outcomes;
  final String filePath;

  Book({
    required this.title,
    required this.characters,
    required this.setting,
    required this.outcomes,
    required this.filePath,
  });

  /// Parse a book from markdown content
  static Book? fromMarkdown(String markdown, String filePath) {
    try {
      String title = '';
      List<Character> characters = [];
      String setting = '';
      List<Outcome> outcomes = [];
      
      // Extract title (first headline)
      final titleRegex = RegExp(r'^# (.+)$', multiLine: true);
      final titleMatch = titleRegex.firstMatch(markdown);
      if (titleMatch != null) {
        title = titleMatch.group(1)!.trim();
      }
      
      // Extract characters section
      final charactersRegex = RegExp(r'## Characters\s+([\s\S]*?)(?=^##|\Z)', multiLine: true);
      final charactersMatch = charactersRegex.firstMatch(markdown);
      if (charactersMatch != null) {
        final charactersList = charactersMatch.group(1)!.trim();
        // Parse character entries (assuming list format)
        final characterEntries = RegExp(r'- ([^:]+):([\s\S]*?)(?=^-|\Z)', multiLine: true)
            .allMatches(charactersList);
        
        for (final entry in characterEntries) {
          final name = entry.group(1)?.trim() ?? '';
          final description = entry.group(2)?.trim() ?? '';
          characters.add(Character(name: name, description: description));
        }
      }
      
      // Extract setting
      final settingRegex = RegExp(r'## Setting\s+([\s\S]*?)(?=^##|\Z)', multiLine: true);
      final settingMatch = settingRegex.firstMatch(markdown);
      if (settingMatch != null) {
        setting = settingMatch.group(1)!.trim();
      }
      
      // Extract outcomes
      final outcomesRegex = RegExp(r'## Outcomes\s+([\s\S]*?)(?=^##|\Z)', multiLine: true);
      final outcomesMatch = outcomesRegex.firstMatch(markdown);
      if (outcomesMatch != null) {
        final outcomesList = outcomesMatch.group(1)!.trim();
        // Parse outcome entries
        final outcomeEntries = RegExp(r'- (.+)', multiLine: true).allMatches(outcomesList);
        for (final entry in outcomeEntries) {
          final description = entry.group(1)?.trim() ?? '';
          outcomes.add(Outcome(description: description));
        }
      }
      
      return Book(
        title: title,
        characters: characters,
        setting: setting,
        outcomes: outcomes,
        filePath: filePath,
      );
    } catch (e) {
      debugPrint('Error parsing book: $e');
      return null;
    }
  }
}

class Character {
  final String name;
  final String description;

  Character({required this.name, required this.description});
}

class Outcome {
  final String description;
  final bool isSuccess;

  Outcome({required this.description, this.isSuccess = true});
}