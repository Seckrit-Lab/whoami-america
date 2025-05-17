import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/book.dart';

class Conductor {
  final GenerativeModel _model;
  final Book book;
  final Function(String) logMessage;
  late ChatSession _chat;
  
  // Player preferences
  String? preferredWritingStyle;
  String? preferredArtStyle;

  Conductor({
    required String apiKey,
    required this.book,
    required this.logMessage,
  }) : _model = GenerativeModel(
          model: 'gemini-2.gemini-2.0-flash',
          apiKey: apiKey,
        ) {
    _chat = _model.startChat();
  }

  /// Initialize the conductor
  Future<void> initialize() async {
    try {
      final initialPrompt = '''
You are the Conductor for a text adventure game based on "${book.title}".
Your role is to guide the overall experience by:
1. Understanding the player's preferred writing and art styles
2. Tracking the player's mood and enjoyment
3. Providing guidance to the Director about how to adjust the story
4. Helping transition between scenes

Here are the details about the book:
- Title: ${book.title}
- Setting: ${book.setting}
- Characters: ${book.characters.map((c) => "${c.name}: ${c.description}").join("\n")}

Please respond in a friendly manner and help establish the player's preferences.
''';

      await _sendMessage(initialPrompt);
      logMessage('Director to Conductor: $initialPrompt');
    } catch (e) {
      debugPrint('Error initializing conductor: $e');
    }
  }

  /// Ask about player preferences
  Future<String> askForPreferences() async {
    const message = "What are your preferred writing and art styles for this adventure? This helps me tailor the experience to your tastes.";
    logMessage('Conductor to Player: $message');
    return message;
  }

  /// Process player's preference response
  Future<String> processPreferences(String playerResponse) async {
    logMessage('Player to Conductor: $playerResponse');
    
    try {
      final prompt = '''
Based on the player's response, identify their preferred writing style and art style.
Response: $playerResponse
Please summarize both preferences in a clear format.
''';

      final response = await _sendMessage(prompt);
      
      // Extract preferences from the response (simplified implementation)
      // In a real implementation, you would parse this more carefully
      if (response.toLowerCase().contains('writing style')) {
        final writingStyleMatch = RegExp(r'writing style[:\s]+([^,.]+)', caseSensitive: false)
            .firstMatch(response);
        if (writingStyleMatch != null) {
          preferredWritingStyle = writingStyleMatch.group(1)?.trim();
        }
      }
      
      if (response.toLowerCase().contains('art style')) {
        final artStyleMatch = RegExp(r'art style[:\s]+([^,.]+)', caseSensitive: false)
            .firstMatch(response);
        if (artStyleMatch != null) {
          preferredArtStyle = artStyleMatch.group(1)?.trim();
        }
      }
      
      final confirmationResponse = await _sendMessage(
          "Thank the player and confirm that you've noted their preferences.");
      logMessage('Conductor to Player: $confirmationResponse');
      
      return confirmationResponse;
    } catch (e) {
      debugPrint('Error processing preferences: $e');
      return "I'm sorry, I couldn't properly process your preferences. Let's continue and I'll do my best to adapt.";
    }
  }

  /// Send a message to the conductor
  Future<String> sendMessage(String message) async {
    logMessage('Director to Conductor: $message');
    final response = await _sendMessage(message);
    logMessage('Conductor to Player: $response');
    return response;
  }

  /// Get the player's preferences
  Map<String, String?> getPlayerPreferences() {
    return {
      'writingStyle': preferredWritingStyle,
      'artStyle': preferredArtStyle,
    };
  }

  Future<String> _sendMessage(String message) async {
    try {
      final response = await _chat.sendMessage(Content.text(message));
      final responseText = response.text ?? 'No response from AI';
      return responseText;
    } catch (e) {
      debugPrint('Error sending message to conductor: $e');
      return 'Error communicating with AI service';
    }
  }
}