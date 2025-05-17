import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert'; // Import for jsonDecode
import 'models/book.dart';
import 'agents/director.dart';
import 'agents/conductor.dart';
import 'agents/scribe.dart';
import 'agents/artist.dart';

class PlaySession with ChangeNotifier {
  final String apiKey;
  final String chatGptApiKey;
  Book? book;
  Director? _director;
  Conductor? _conductor;
  Scribe? _scribe;
  Artist? _artist;
  
  String _log = '';
  Uint8List? _currentImage;
  String _currentText = '';
  bool _isLoading = false;
  AgentType _activeAgent = AgentType.director;
  
  PlaySession({required this.apiKey, required this.chatGptApiKey});
  
  String get log => _log;
  Uint8List? get currentImage => _currentImage;
  String get currentText => _currentText;
  bool get isLoading => _isLoading;
  bool get isInitialized => book != null;
  
  /// Log a message to the application log
  void addLog(String message) {
    _log += '$message\n';
    notifyListeners();
  }
  
  /// Open a book file and initialize the play session
  Future<bool> openBook(String filePath) async {
    _setLoading(true);
    
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        _currentText = 'Book file not found: $filePath';
        _setLoading(false);
        return false;
      }
      
      final content = await file.readAsString();
      // Parse the string content as JSON
      final Map<String, dynamic> jsonMap;
      try {
        jsonMap = jsonDecode(content) as Map<String, dynamic>;
      } catch (e) {
        _currentText = 'Failed to parse book file as JSON: $e';
        _setLoading(false);
        return false;
      }
      
      final parsedBook = Book.fromJson(jsonMap, filePath);
      
      if (parsedBook == null) {
        _currentText = 'Failed to parse book file. Please check the format.';
        _setLoading(false);
        return false;
      }
      
      book = parsedBook;
      
      // Initialize agents
      _artist = Artist(apiKey: chatGptApiKey, logMessage: addLog);
      _conductor = Conductor(apiKey: apiKey, book: book!, logMessage: addLog);
      _scribe = Scribe(apiKey: apiKey, book: book!, logMessage: addLog);
      _director = Director(apiKey: apiKey, book: book!, logMessage: addLog);
      
      await _conductor!.initialize();
      
      // Initialize director with book content
      final isValid = await _director!.initialize();
      
      if (!isValid) {
        _currentText = 'The book file does not match the required Tada format. Please contact the author for help.';
        _setLoading(false);
        return false;
      }
      
      // Ask for player preferences
      _currentText = await _conductor!.askForPreferences();
      _activeAgent = AgentType.conductor;
      
      _setLoading(false);
      return true;
      
    } catch (e) {
      _currentText = 'Error opening book: $e';
      _setLoading(false);
      return false;
    }
  }
  
  /// Process a player message based on the active agent
  Future<void> processPlayerMessage(String message) async {
    if (book == null || _director == null) {
      _currentText = 'Play session not properly initialized';
      return;
    }
    
    _setLoading(true);
    addLog('Player: $message'); // Log player's message

    try {
      switch (_activeAgent) {
        case AgentType.conductor:
          final response = await _conductor!.processPreferences(message);
          addLog('Conductor (after preferences): $response'); // Log agent response
          
          // After getting preferences, switch to the director and ask for title screen
          final preferences = _conductor!.getPlayerPreferences();
          
          _director!.sendMessage(
            'Player preferences: Art style: ${preferences['artStyle']}, Writing style: ${preferences['writingStyle']}'
          );
          
          // Generate title screen
          _setLoading(true);
          final titleImage = await _artist!.generateTitleScreen(
            book!.title,
            book!.setting,
            characterDescriptions: book!.characters.isNotEmpty 
                ? [book!.characters[0].description]
                : null,
            artStyle: preferences['artStyle'],
          );
          
          if (titleImage != null) {
            _currentImage = titleImage;
          }
          
          // Switch to director for next steps
          _activeAgent = AgentType.director;
          _currentText = "Title screen generated. What would you like to do next?";
          break;
          
        case AgentType.director:
          final response = await _director!.sendMessage(message);
          addLog('Director (LLM response): $response'); // Log LLM response via agent
          final agentResponse = await _director!.processDirectorResponse(response);
          addLog('Director (processed response): ${agentResponse.message}'); // Log processed response
          
          // Route to appropriate agent
          switch (agentResponse.agent) {
            case AgentType.conductor:
              _activeAgent = AgentType.conductor;
              final conductorResponse = await _conductor!.sendMessage(agentResponse.message);
              _currentText = conductorResponse;
              addLog('Conductor: $conductorResponse'); // Log agent response
              break;
              
            case AgentType.scribe:
              if (agentResponse.delegateControl) {
                _activeAgent = AgentType.scribe;
                
                // Reset scribe for new scene
                _scribe!.reset();
                
                // Get player preferences
                final preferences = _conductor!.getPlayerPreferences();
                
                // Initialize scribe with current scene
                final scribeResponse = await _scribe!.initialize(
                  scene: response, // This 'response' is from the director's LLM call
                  preferredWritingStyle: preferences['writingStyle'],
                );
                
                _currentText = scribeResponse;
                addLog('Scribe (init): $scribeResponse'); // Log agent response
              } else {
                _activeAgent = AgentType.scribe;
                _currentText = agentResponse.message;
                addLog('Scribe: ${agentResponse.message}'); // Log agent response
              }
              break;
              
            case AgentType.artist:
              addLog('Artist (request): ${agentResponse.message}'); // Log request to artist
              final image = await _artist!.generateImage(
                agentResponse.message,
                artStyle: _conductor!.getPlayerPreferences()['artStyle'],
              );
              
              if (image != null) {
                _currentImage = image;
                addLog('Artist (response): Image generated'); // Log image generation
              } else {
                addLog('Artist (response): Image generation failed');
              }
              
              // Stay with director
              _currentText = "Image generated. What would you like to do next?";
              break;
              
            case AgentType.director:
              _currentText = agentResponse.message;
              addLog('Director: ${agentResponse.message}'); // Log agent response
              break;
          }
          break;
          
        case AgentType.scribe:
          final response = await _scribe!.processPlayerAction(message);
          _currentText = response;
          addLog('Scribe (action response): $response'); // Log agent response
          break;
          
        default:
          _currentText = "Unsupported agent type";
          break;
      }
    } catch (e) {
      _currentText = "Error processing your message: $e";
      addLog('Error: $_currentText'); // Log error
    } finally {
      _setLoading(false);
    }
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}