import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart'; // For potential future file-based key storage

const String geminiApiKeyName = 'geminikey';

void main() {
  runApp(const OpenTADAApp());
}

class OpenTADAApp extends StatelessWidget {
  const OpenTADAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenTADA',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.lightBlue, // You can choose any seed color
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const StoryScreen(),
    );
  }
}

class StoryScreen extends StatefulWidget {
  const StoryScreen({super.key});

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _chatHistory = [];
  GenerativeModel? _model;
  ChatSession? _chat;
  String? _apiKey;
  File? _currentImage;

  static const double phoneScreenWidthThreshold = 600.0;

  @override
  void initState() {
    super.initState();
    _loadApiKeyAndInitialize();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadApiKeyAndInitialize() async {
    final prefs = await SharedPreferences.getInstance();
    String? apiKey = prefs.getString(geminiApiKeyName);

    if (!mounted) return;

    if (apiKey == null || apiKey.isEmpty) {
      apiKey = await _promptForApiKey();
    }

    if (apiKey != null && apiKey.isNotEmpty) {
      setState(() {
        _apiKey = apiKey;
        _model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: _apiKey!);
        _chat = _model!.startChat();
      });
      if (mounted) { // Check mounted again before async file picking
        await _pickAndProcessTadaFile();
      }
    } else {
      _addMessageToHistory('API Key not provided. Cannot start session.', false);
    }
  }

  Future<String?> _promptForApiKey() async {
    if (!mounted) return null;
    String? key;
    TextEditingController keyController = TextEditingController();
    await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Enter Gemini API Key'),
          content: TextField(
            controller: keyController,
            decoration: const InputDecoration(hintText: "API Key"),
            obscureText: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () async {
                if (keyController.text.isNotEmpty) {
                  key = keyController.text;
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString(geminiApiKeyName, key!);
                  Navigator.of(dialogContext).pop(key);
                }
              },
            ),
          ],
        );
      },
    ).then((value) => key = value); // Assign the result to key
    return key;
  }

  Future<void> _pickAndProcessTadaFile() async {
    if (_model == null) {
      _addMessageToHistory("LLM not initialized. Please configure API key.", false);
      return;
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['md'], // Allow .md, then filter for .tada.md
    );

    if (result != null && result.files.single.path != null) {
      final fileName = result.files.single.name;
      if (fileName == null || !fileName.toLowerCase().endsWith('.tada.md')) {
        _addMessageToHistory("Invalid file. Please select a '.tada.md' file.", false);
        return;
      }
      File file = File(result.files.single.path!);
      try {
        String initialPromptContent = await file.readAsString();
        _sendMessageToLLM(initialPromptContent, isInitialPrompt: true);
      } catch (e) {
        _addMessageToHistory("Error reading file: ${e.toString()}", false);
      }
    } else {
      _addMessageToHistory("No file selected or file path is null.", false);
    }
  }

  void _parseResponseForImage(String responseText) {
    // Example parsing: look for [IMAGE: path/to/image.png]
    // This is a placeholder. You'll need a robust parsing strategy.
    final RegExp imageRegExp = RegExp(r"\[IMAGE:\s*([^\]]+)\s*\]");
    final match = imageRegExp.firstMatch(responseText);
    if (match != null) {
      final imagePath = match.group(1);
      if (imagePath != null && imagePath.isNotEmpty) {
        // Assuming imagePath is a local file path for now.
        // If it's a bundled asset, you'd use that. If URL, Image.network.
        File imageFile = File(imagePath);
        if (imageFile.existsSync()) { // Basic check
          setState(() {
            _currentImage = imageFile;
          });
        } else {
            _addMessageToHistory("Image not found: $imagePath", false);
        }
      }
    }
  }

  void _sendMessageToLLM(String text, {bool isInitialPrompt = false}) async {
    if (_chat == null) {
      _addMessageToHistory("Chat session not started. Load API key and select file.", false);
      return;
    }

    if (!isInitialPrompt) {
      _addMessageToHistory(text, true); // User's input
    }
    _inputController.clear();

    try {
      final response = await _chat!.sendMessage(Content.text(text));
      final llmResponseText = response.text;
      if (llmResponseText != null) {
        _addMessageToHistory(llmResponseText, false); // LLM's response
        _parseResponseForImage(llmResponseText); // Check for image commands
      } else {
        _addMessageToHistory("LLM sent an empty response.", false);
      }
    } catch (e) {
      _addMessageToHistory("Error communicating with LLM: ${e.toString()}", false);
    }

    _scrollToBottom();
  }

  void _addMessageToHistory(String text, bool isUserMessage) {
    if (!mounted) return;
    setState(() {
      _chatHistory.add(ChatMessage(text: text, isUserMessage: isUserMessage));
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildInputBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              decoration: const InputDecoration(
                hintText: 'Enter your command...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (text) {
                if (text.isNotEmpty) {
                  _sendMessageToLLM(text);
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              if (_inputController.text.isNotEmpty) {
                _sendMessageToLLM(_inputController.text);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessagesList() {
    return ListView.builder(
      controller: _scrollController, // Controller for messages list
      itemCount: _chatHistory.length,
      itemBuilder: (context, index) {
        final message = _chatHistory[index];
        return message.build(context);
      },
    );
  }

  Widget _buildImageDisplayWidget() {
    if (_currentImage == null) return const SizedBox.shrink();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0), // Add some padding around the image
        child: Image.file(
          _currentImage!,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50),
        ),
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
            onPressed: _pickAndProcessTadaFile,
            tooltip: 'Open .tada.md File',
          ),
          IconButton(
            icon: const Icon(Icons.vpn_key),
            onPressed: () async {
              final newKey = await _promptForApiKey();
              if (newKey != null && newKey.isNotEmpty) {
                setState(() {
                  _apiKey = newKey;
                  _model = GenerativeModel(model: 'gemini-pro', apiKey: _apiKey!);
                  _chat = _model!.startChat();
                  _chatHistory.clear();
                  _currentImage = null; // Reset image
                  _addMessageToHistory("API Key updated. Please select a .tada.md file.", false);
                });
              }
            },
            tooltip: 'Update API Key',
          )
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final mediaQuery = MediaQuery.of(context);
          final screenWidth = mediaQuery.size.width;
          final orientation = mediaQuery.orientation;
          final bool isSmallScreen = screenWidth < phoneScreenWidthThreshold;

          if (isSmallScreen && orientation == Orientation.portrait) {
            // Small phone, portrait: Image scrolls with chat content
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController, // Controller for combined list
                    itemCount: _chatHistory.length + (_currentImage != null ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_currentImage != null) {
                        if (index == 0) { // Image at the top of the scrollable list
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                              child: ConstrainedBox( // Constrain image height on small screens
                                constraints: BoxConstraints(maxHeight: screenWidth * 0.75),
                                child: Image.file(_currentImage!, fit: BoxFit.contain),
                              ),
                            ),
                          );
                        }
                        // Adjust index for chat history
                        final message = _chatHistory[index - 1];
                        return message.build(context);
                      } else {
                        // No image, just chat history
                        final message = _chatHistory[index];
                        return message.build(context);
                      }
                    },
                  ),
                ),
                _buildInputBar(),
              ],
            );
          } else if (orientation == Orientation.landscape) {
            // Any device in landscape: Image on the side
            return Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      SizedBox(
                        width: constraints.maxWidth / 2,
                        child: _buildImageDisplayWidget(),
                      ),
                      Expanded(child: _buildChatMessagesList()),
                    ],
                  ),
                ),
                _buildInputBar(),
              ],
            );
          } else {
            // Larger screen (tablet/desktop) in portrait: Image at the top
            return Column(
              children: [
                SizedBox(
                  height: constraints.maxHeight / 2,
                  child: _buildImageDisplayWidget(),
                ),
                Expanded(child: _buildChatMessagesList()),
                _buildInputBar(),
              ],
            );
          }
        },
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUserMessage;

  ChatMessage({required this.text, required this.isUserMessage});

  Widget build(BuildContext context) {
    return Align(
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isUserMessage
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUserMessage
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }
}