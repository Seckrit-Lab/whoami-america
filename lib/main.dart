import 'dart:io';
import 'dart:typed_data'; // Added for Uint8List
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'play_session.dart'; // Import PlaySession

void main() {
  runApp(const OpenTadaApp());
}

class OpenTadaApp extends StatelessWidget {
  const OpenTadaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenTADA',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const OpenTadaHome(),
    );
  }
}

class OpenTadaHome extends StatefulWidget {
  const OpenTadaHome({super.key});

  @override
  State<OpenTadaHome> createState() => _OpenTadaHomeState();
}

class _OpenTadaHomeState extends State<OpenTadaHome> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _chatHistory = [];
  final List<String> _logEntries = [];
  PlaySession? _playSession;
  String _geminiApiKey = '';
  String _chatGptApiKey = '';
  String _lastProcessedPlaySessionLog = "";

  Uint8List? _currentImageBytes;
  bool _showLog = false;
  bool _isProcessingInput = false;

  @override
  void initState() {
    super.initState();
    _loadApiKeysAndPrepare();
  }

  Future<void> _loadApiKeysAndPrepare() async {
    bool keysAvailable = await _ensureApiKeysAvailable();
    if (keysAvailable) {
      _log("API keys loaded. Ready to open a .tada.json file.");
      _addMessageToHistory("Welcome to OpenTADA! Please select a .tada.json file to begin, or use the settings icon to update API keys.", false);
    } else {
      _log("One or both API keys not found or not provided. Please configure API keys using the settings icon.");
      _addMessageToHistory("Please configure your Gemini and ChatGPT API keys using the settings (key) icon in the AppBar to begin.", false);
    }
  }
  
  Future<String?> _loadKeyFromFile(String fileName, String keyNameForLog) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      if (await file.exists()) {
        String key = await file.readAsString();
        key = key.trim();
        if (key.isNotEmpty) {
          _log("$keyNameForLog API key found in file: $fileName");
          return key;
        }
      }
    } catch (e) {
      _log("Error reading $keyNameForLog API key file ($fileName): $e");
    }
    return null;
  }

  Future<Map<String, String?>?> _showApiKeysInputDialog({String? currentGeminiKey, String? currentChatGptKey, String title = 'API Keys Required'}) async {
    final TextEditingController geminiController = TextEditingController(text: currentGeminiKey);
    final TextEditingController chatGptController = TextEditingController(text: currentChatGptKey);

    return await showDialog<Map<String, String?>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Enter your Gemini API key:'),
                TextField(
                  controller: geminiController,
                  decoration: const InputDecoration(hintText: 'Gemini API Key'),
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                Text('Enter your ChatGPT/OpenAI API key (for Artist):'),
                TextField(
                  controller: chatGptController,
                  decoration: const InputDecoration(hintText: 'ChatGPT/OpenAI API Key'),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(null);
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                Navigator.of(context).pop({
                  'gemini': geminiController.text,
                  'chatgpt': chatGptController.text,
                });
              },
            ),
          ],
        );
      },
    );
  }

  Future<bool> _ensureApiKeysAvailable() async {
    final prefs = await SharedPreferences.getInstance();
    String? geminiKey = prefs.getString('geminikey');
    String? chatGptKey = prefs.getString('chatgptkey');

    _log("Looking for stored API keys...");

    if (geminiKey == null || geminiKey.isEmpty) {
      _log("Gemini API key not found in storage, checking for gemini.key file.");
      geminiKey = await _loadKeyFromFile('gemini.key', 'Gemini');
    }
    if (chatGptKey == null || chatGptKey.isEmpty) {
      _log("ChatGPT API key not found in storage, checking for chatgpt.key file.");
      chatGptKey = await _loadKeyFromFile('chatgpt.key', 'ChatGPT');
    }

    bool prompted = false;
    if ((geminiKey == null || geminiKey.isEmpty) || (chatGptKey == null || chatGptKey.isEmpty)) {
      _log("One or both API keys are missing. Prompting user.");
      prompted = true;
      final result = await _showApiKeysInputDialog(
        currentGeminiKey: geminiKey, 
        currentChatGptKey: chatGptKey
      );
      if (result != null) {
        geminiKey = result['gemini'];
        chatGptKey = result['chatgpt'];
      } else {
         _log("API key entry cancelled by user.");
      }
    }

    bool keysSet = false;
    if (geminiKey != null && geminiKey.isNotEmpty) {
      _geminiApiKey = geminiKey;
      await prefs.setString('geminikey', geminiKey);
      _log(prompted ? "Saved new Gemini API key." : "Loaded Gemini API key.");
      keysSet = true;
    } else {
      _geminiApiKey = ''; // Ensure it's reset if not provided
      keysSet = false;
       _log("Gemini API key not set.");
    }

    if (chatGptKey != null && chatGptKey.isNotEmpty) {
      _chatGptApiKey = chatGptKey;
      await prefs.setString('chatgptkey', chatGptKey);
      _log(prompted ? "Saved new ChatGPT API key." : "Loaded ChatGPT API key.");
      // keysSet remains true if gemini was set, or becomes true if it wasn't but chatgpt is.
      // We need both for full functionality.
    } else {
      _chatGptApiKey = ''; // Ensure it's reset
      keysSet = keysSet && false; // If chatgpt is not set, overall keysSet is false
      _log("ChatGPT API key not set.");
    }
    
    return _geminiApiKey.isNotEmpty && _chatGptApiKey.isNotEmpty;
  }
  
  Future<void> _openApiKeysSettings() async {
    _log("Opening API key settings dialog.");
    final result = await _showApiKeysInputDialog(
        currentGeminiKey: _geminiApiKey,
        currentChatGptKey: _chatGptApiKey,
        title: 'Update API Keys');

    if (result != null) {
        final prefs = await SharedPreferences.getInstance();
        String? newGeminiKey = result['gemini'];
        String? newChatGptKey = result['chatgpt'];

        bool geminiUpdated = false;
        if (newGeminiKey != null && newGeminiKey.isNotEmpty) {
            _geminiApiKey = newGeminiKey;
            await prefs.setString('geminikey', newGeminiKey);
            _log("Gemini API key updated via settings.");
            geminiUpdated = true;
        } else {
             _geminiApiKey = ''; // Clear if emptied
            await prefs.remove('geminikey');
            _log("Gemini API key cleared via settings.");
        }

        bool chatGptUpdated = false;
        if (newChatGptKey != null && newChatGptKey.isNotEmpty) {
            _chatGptApiKey = newChatGptKey;
            await prefs.setString('chatgptkey', newChatGptKey);
            _log("ChatGPT API key updated via settings.");
            chatGptUpdated = true;
        } else {
            _chatGptApiKey = ''; // Clear if emptied
            await prefs.remove('chatgptkey');
            _log("ChatGPT API key cleared via settings.");
        }

        if (geminiUpdated || chatGptUpdated) {
            _addMessageToHistory("API Key(s) updated. You may need to reopen your book file if one was active.", false);
            // If a play session was active, you might want to re-initialize or inform the user.
            if (_playSession != null && _playSession!.isInitialized) {
                // Consider how to handle this. Maybe clear the session or prompt to reopen.
                // For now, just a message.
            }
        }
         if (_geminiApiKey.isEmpty || _chatGptApiKey.isEmpty) {
            _addMessageToHistory("One or both API keys are now missing. Please set them to use the application.", false);
        }
    } else {
        _log("API key update cancelled by user.");
    }
  }


  // Listener for PlaySession updates
  void _onPlaySessionUpdate() {
    if (_playSession == null || !mounted) return;

    // Sync logs from PlaySession to the UI log
    final String currentSessionLog = _playSession!.log;
    if (currentSessionLog.length > _lastProcessedPlaySessionLog.length) {
      final String newLogPart = currentSessionLog.substring(_lastProcessedPlaySessionLog.length);
      final List<String> newLogLines = newLogPart.trim().split('\n').where((line) => line.isNotEmpty).toList();
      for (final String line in newLogLines) {
        _log("PlaySession: $line"); 
      }
      _lastProcessedPlaySessionLog = currentSessionLog;
    }

    setState(() {
      _isProcessingInput = _playSession!.isLoading;
      _currentImageBytes = _playSession!.currentImage;
    });
  }

  Future<void> _pickAndProcessTadaFile() async {
    _log("Attempting to pick .tada.json file.");
    if (_geminiApiKey.isEmpty || _chatGptApiKey.isEmpty) {
      final message = "Gemini or ChatGPT API key not configured. Please use the settings (key) icon in the AppBar to set them.";
      _log(message);
      _addMessageToHistory(message, false);
      // Optionally, directly open the settings dialog:
      // await _openApiKeysSettings();
      // if (_geminiApiKey.isEmpty || _chatGptApiKey.isEmpty) return;
      return;
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      final fileName = result.files.single.name;
      final filePath = result.files.single.path!;
      _log("File picked: $fileName");

      if (!fileName.toLowerCase().endsWith('.tada.json')) {
        final message = "Invalid file: '$fileName'. Please select a '.tada.json' file.";
        _log(message);
        _addMessageToHistory(message, false);
        return;
      }

      _playSession?.removeListener(_onPlaySessionUpdate);
      _playSession = PlaySession(apiKey: _geminiApiKey, chatGptApiKey: _chatGptApiKey);
      _playSession!.addListener(_onPlaySessionUpdate);
      _lastProcessedPlaySessionLog = "";

      setState(() {
        _isProcessingInput = true;
        _chatHistory.clear();
        _currentImageBytes = null;
      });
      _log("Initializing PlaySession with file: $filePath");

      bool success = await _playSession!.openBook(filePath);

      if (_playSession!.currentText.isNotEmpty) {
        _addMessageToHistory(_playSession!.currentText, false);
      } else if (!success) {
        _addMessageToHistory("Failed to open or initialize the book.", false);
      }

      if (mounted) {
        setState(() {
          _isProcessingInput = _playSession!.isLoading;
          _currentImageBytes = _playSession!.currentImage;
        });
      }
    } else {
      _log("File picking cancelled or failed");
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _playSession == null || !_playSession!.isInitialized || _playSession!.isLoading) {
      return;
    }

    _addMessageToHistory(text, true);
    _inputController.clear();

    setState(() {
      _isProcessingInput = true;
    });

    _log("Sending to PlaySession: $text");
    await _playSession!.processPlayerMessage(text);

    if (_playSession!.currentText.isNotEmpty) {
      _addMessageToHistory(_playSession!.currentText, false);
    }

    if (mounted) {
      setState(() {
        _isProcessingInput = _playSession!.isLoading;
        _currentImageBytes = _playSession!.currentImage;
      });
    }
  }

  Future<void> _handleApiErrorAndPromptKeys() async {
    _log("API error occurred. Prompting for API key update.");
    _addMessageToHistory("An API error occurred. This might be due to an invalid or rate-limited API key. Please update your keys.", false);
    
    final result = await _showApiKeysInputDialog(
        currentGeminiKey: _geminiApiKey,
        currentChatGptKey: _chatGptApiKey,
        title: 'API Error: Update Keys');

    if (result != null) {
        final prefs = await SharedPreferences.getInstance();
        String? newGeminiKey = result['gemini'];
        String? newChatGptKey = result['chatgpt'];

        if (newGeminiKey != null && newGeminiKey.isNotEmpty) {
            _geminiApiKey = newGeminiKey;
            await prefs.setString('geminikey', newGeminiKey);
            _log("Gemini API key updated after error.");
        } else {
            _geminiApiKey = '';
             await prefs.remove('geminikey');
        }

        if (newChatGptKey != null && newChatGptKey.isNotEmpty) {
            _chatGptApiKey = newChatGptKey;
            await prefs.setString('chatgptkey', newChatGptKey);
            _log("ChatGPT API key updated after error.");
        } else {
            _chatGptApiKey = '';
            await prefs.remove('chatgptkey');
        }
        
        if (_geminiApiKey.isNotEmpty && _chatGptApiKey.isNotEmpty) {
            _addMessageToHistory("API Keys updated. Please try your action again, or reopen the book file.", false);
        } else {
            _addMessageToHistory("One or both API keys are still missing. Please set them to continue.", false);
        }
    }
  }

  void _addMessageToHistory(String message, bool isUser) {
    setState(() {
      _chatHistory.add(ChatMessage(
        text: message,
        isUser: isUser,
      ));
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _log(String message) {
    final timestamp = DateTime.now().toString().split('.').first;
    final logMessage = "[$timestamp] $message";
    if (mounted) {
      setState(() {
        _logEntries.add(logMessage);
      });
    } else {
      _logEntries.add(logMessage);
    }
    debugPrint(logMessage);
  }

  Widget _buildStoryView(BuildContext context) {
    final isLandscape = MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    if (_chatHistory.isEmpty && _playSession == null && (_geminiApiKey.isEmpty || _chatGptApiKey.isEmpty)) {
        return Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    const Text("Please set your API keys using the (key) icon."),
                    const SizedBox(height: 20),
                    ElevatedButton(
                        onPressed: _openApiKeysSettings,
                        child: const Text('Set API Keys'),
                    ),
                ],
            ),
        );
    }


    if (_chatHistory.isEmpty && _playSession == null) {
      return Center(
        child: ElevatedButton(
          onPressed: _pickAndProcessTadaFile,
          child: const Text('Open .tada.json File'),
        ),
      );
    }

    Widget imageWidget = _currentImageBytes != null
        ? Image.memory(
            _currentImageBytes!,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              _log("Error loading image: $error");
              return const Center(child: Text('Image could not be loaded'));
            },
          )
        : const SizedBox.shrink();

    Widget chatListView = ListView.builder(
      controller: _scrollController,
      itemCount: _chatHistory.length,
      padding: const EdgeInsets.all(8.0),
      itemBuilder: (context, index) {
        return _chatHistory[index];
      },
    );

    if (isSmallScreen) {
      return Column(
        children: [
          if (_currentImageBytes != null) 
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.3, // Adjust as needed
              child: imageWidget,
            ),
          Expanded(child: chatListView),
          _buildInputBar(),
        ],
      );
    }

    if (isLandscape && _currentImageBytes != null) {
      return Row(
        children: [
          Expanded(child: chatListView),
          SizedBox(
            width: MediaQuery.of(context).size.width / 2.5, // Adjusted for better balance
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: imageWidget,
            ),
          ),
        ],
      );
    }

    if (!isLandscape && _currentImageBytes != null) {
      return Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height / 2.5, // Adjusted
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: imageWidget,
            ),
          ),
          Expanded(child: chatListView),
          _buildInputBar(),
        ],
      );
    }

    return Column(
      children: [
        Expanded(child: chatListView),
        _buildInputBar(),
      ],
    );
  }

  Widget _buildInputBar() {
    bool canSendMessage = !_isProcessingInput && 
                           _playSession != null && 
                           _playSession!.isInitialized &&
                           _geminiApiKey.isNotEmpty &&
                           _chatGptApiKey.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: (_geminiApiKey.isEmpty || _chatGptApiKey.isEmpty) 
                    ? 'Set API keys to enable input...'
                    : 'Enter your command...',
              ),
              enabled: canSendMessage,
              onSubmitted: canSendMessage ? _sendMessage : null,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: canSendMessage
                ? () => _sendMessage(_inputController.text)
                : null,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OpenTADA'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: 'Open .tada.json File',
            onPressed: (_geminiApiKey.isNotEmpty && _chatGptApiKey.isNotEmpty) 
                       ? _pickAndProcessTadaFile
                       : () {
                           _addMessageToHistory("Please set API keys using the (key) icon before opening a file.", false);
                           _openApiKeysSettings();
                         },
          ),
          IconButton(
            icon: const Icon(Icons.vpn_key), // Changed icon
            tooltip: 'API Key Settings',
            onPressed: _openApiKeysSettings, // Call the new method
          ),
          IconButton(
            icon: Icon(_showLog ? Icons.visibility_off : Icons.bug_report),
            tooltip: _showLog ? 'Hide Log' : 'Show Log',
            onPressed: () {
              setState(() {
                _showLog = !_showLog;
              });
            },
          ),
        ],
      ),
      body: _showLog
          ? ListView.builder(
              itemCount: _logEntries.length,
              itemBuilder: (context, index) {
                return ListTile(
                  dense: true,
                  title: Text(
                    _logEntries[index],
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
                  ),
                );
              },
            )
          : _buildStoryView(context),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatMessage({super.key, required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: MarkdownBody(
          data: text,
          selectable: true,
        ),
      ),
    );
  }
}