import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/book.dart';

enum AgentType {
  director,
  conductor,
  scribe,
  artist,
}

class AgentResponse {
  final AgentType agent;
  final String message;
  final bool delegateControl;

  AgentResponse({
    required this.agent,
    required this.message,
    this.delegateControl = false,
  });
}

class Director {
  final GenerativeModel _model;
  final Book book;
  final Function(String) logMessage;
  late ChatSession _chat;

  Director({
    required String apiKey,
    required this.book,
    required this.logMessage,
  }) : _model = GenerativeModel(
          model: 'gemini-2.gemini-2.0-flash',
          apiKey: apiKey,
        ) {
    _chat = _model.startChat();
  }

  /// Initialize the director with the book content
  Future<bool> initialize() async {
    try {
      // Send initial prompt to the Director
      final initialPrompt = '''
You are the Director of a text adventure play session. 
A Tada book has the following format:
- A headline at the start of the file gives the title of the book.
- A Characters section with a list of characters, giving names and descriptions of both appearance and personality.
- A Setting, describing the overall scenario.
- Outcomes, which defines successful or unsuccessful end states for the novel.

You are able to speak to a CONDUCTOR, SCRIBE, and ARTIST by prefacing your responses with their title. 
E.g. to tell the artist to render a picture of a cube, say 'ARTIST: Draw a cube.' 
A response without such a preface is assumed to be a message directly to the player. 
A response reading only "OK" is taken to mean that control should be delegated to the appropriate other agent, which is usually the SCRIBE.

The book title is: ${book.title}
The characters are: ${book.characters.map((c) => "${c.name}: ${c.description}").join("\n")}
The setting is: ${book.setting}
The outcomes are: ${book.outcomes.map((o) => o.description).join("\n")}
''';

      final response = await _sendMessage(initialPrompt);
      logMessage('Director to Director: $initialPrompt');
      logMessage('Director to Player: $response');
      
      // Validate if the book matches the format
      if (response.toLowerCase().contains('not valid') || 
          response.toLowerCase().contains('incorrect format')) {
        return false;
      }
      
      return true;
    } catch (e) {
      debugPrint('Error initializing director: $e');
      return false;
    }
  }

  /// Send a message to the Director and get a response
  Future<String> sendMessage(String message) async {
    logMessage('Player to Director: $message');
    final response = await _sendMessage(message);
    logMessage('Director to Player: $response');
    return response;
  }

  /// Parse the director's response and route it to the appropriate agent
  Future<AgentResponse> processDirectorResponse(String response) async {
    if (response.startsWith('CONDUCTOR:')) {
      return AgentResponse(
        agent: AgentType.conductor,
        message: response.replaceFirst('CONDUCTOR:', '').trim(),
      );
    } else if (response.startsWith('SCRIBE:')) {
      return AgentResponse(
        agent: AgentType.scribe,
        message: response.replaceFirst('SCRIBE:', '').trim(),
      );
    } else if (response.startsWith('ARTIST:')) {
      return AgentResponse(
        agent: AgentType.artist,
        message: response.replaceFirst('ARTIST:', '').trim(),
      );
    } else if (response == 'OK') {
      return AgentResponse(
        agent: AgentType.scribe,
        message: '',
        delegateControl: true,
      );
    } else {
      return AgentResponse(
        agent: AgentType.director,
        message: response,
      );
    }
  }

  Future<String> _sendMessage(String message) async {
    try {
      final response = await _chat.sendMessage(Content.text(message));
      final responseText = response.text ?? 'No response from AI';
      return responseText;
    } catch (e) {
      debugPrint('Error sending message to director: $e');
      return 'Error communicating with AI service';
    }
  }
}