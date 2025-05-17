import 'package:flutter/material.dart';

/// Represents a book in the Tada format
class Book {
  final String title;
  final List<Character> characters;
  final String setting;
  final List<Outcome> outcomes;
  final List<Scene> scenes;
  final String filePath;

  Book({
    required this.title,
    required this.characters,
    required this.setting,
    required this.outcomes,
    required this.scenes,
    required this.filePath,
  });

  /// Parse a book from a JSON map
  static Book? fromJson(Map<String, dynamic> json, String filePath) {
    try {
      final title = json['title'] as String? ?? '';
      final charactersList = json['characters'] as List<dynamic>? ?? [];
      final characters = charactersList
          .map((charJson) => Character.fromJson(charJson as Map<String, dynamic>))
          .toList();
      final setting = json['setting'] as String? ?? '';
      final outcomesList = json['outcomes'] as List<dynamic>? ?? [];
      final outcomes = outcomesList
          .map((outcomeJson) => Outcome.fromJson(outcomeJson as Map<String, dynamic>))
          .toList();
      final scenesList = json['scenes'] as List<dynamic>? ?? [];
      final scenes = scenesList
          .map((sceneJson) => Scene.fromJson(sceneJson as Map<String, dynamic>))
          .toList();

      return Book(
        title: title,
        characters: characters,
        setting: setting,
        outcomes: outcomes,
        scenes: scenes,
        filePath: filePath,
      );
    } catch (e) {
      debugPrint('Error parsing book from JSON: $e');
      return null;
    }
  }
}

class Character {
  final String name;
  final String description;

  Character({required this.name, required this.description});

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}

class Outcome {
  final String description;
  final bool isSuccess;

  Outcome({required this.description, this.isSuccess = true});

  factory Outcome.fromJson(Map<String, dynamic> json) {
    return Outcome(
      description: json['description'] as String? ?? '',
      isSuccess: json['isSuccess'] as bool? ?? true,
    );
  }
}

class Scene {
  final int id;
  final String content;

  Scene({required this.id, required this.content});

  factory Scene.fromJson(Map<String, dynamic> json) {
    return Scene(
      id: json['id'] as int? ?? 0,
      content: json['content'] as String? ?? '',
    );
  }
}