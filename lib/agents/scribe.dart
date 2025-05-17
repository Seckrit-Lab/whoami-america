import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/book.dart';

class Scribe {
  final GenerativeModel _model;
  final Book book;
  final Function(String) logMessage;
  late ChatSession _chat;
  bool _isInitialized = false;

  Scribe({
    required String apiKey,
    required this.book,
    required this.logMessage,
  }) : _model = GenerativeModel(
          model: 'gemini-2.gemini-2.0-flash',
          apiKey: apiKey,
        ) {
    _chat = _model.startChat();
  }

  /// Initialize the scribe with scene information
  Future<String> initialize({
    required String scene,
    String? preferredWritingStyle,
  }) async {
    try {
      final initialPrompt = '''
You are the scribe for a Tada text adventure game based on "${book.title}".
Take any further inputs as player actions in a text adventure game akin to Zork.
Respond to player inputs by describing the actions, dialogue, and scenes resulting from the player actions specified.
Do not deviate from this process for the remainder of this conversation.

Current scene: $scene

Book information:
- Setting: ${book.setting}
- Characters: ${book.characters.map((c) => "${c.name}: ${c.description}").join("\n")}

${preferredWritingStyle != null ? 'Writing style preference: $preferredWritingStyle' : ''}

Please start by describing the current scene to the player.
''';

      logMessage('Director to Scribe: $initialPrompt');
      final response = await _sendMessage(initialPrompt);
      logMessage('Scribe to Player: $response');
      
      _isInitialized = true;
      return response;
    } catch (e) {
      debugPrint('Error initializing scribe: $e');
      return 'Error initializing the scene description.';
    }
  }

  /// Process a player's action
  Future<String> processPlayerAction(String action) async {
    if (!_isInitialized) {
      return 'The scene has not been properly initialized yet.';
    }

    logMessage('Player to Scribe: $action');
    final response = await _sendMessage(action);
    logMessage('Scribe to Player: $response');
    
    return response;
  }

  Future<String> _sendMessage(String message) async {
    try {
      final response = await _chat.sendMessage(Content.text(message));
      final responseText = response.text ?? 'No response from AI';
      return responseText;
    } catch (e) {
      debugPrint('Error sending message to scribe: $e');
      return 'Error communicating with AI service';
    }
  }

  /// Reset the scribe for a new scene
  void reset() {
    _chat = _model.startChat();
    _isInitialized = false;
  }
}