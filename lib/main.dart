import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

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
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String? _apiKey;
  final _secureStorage = const FlutterSecureStorage();
  static const String _geminiApiKeyName = "geminikey";
  static const String _initialPromptPath = "books/The Beloved Dead Chapter 0.tada";

  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _loadApiKeyAndInitialPrompt();
  }

  Future<void> _loadApiKeyAndInitialPrompt() async {
    setState(() {
      _isLoading = true;
    });
    _apiKey = await _secureStorage.read(key: _geminiApiKeyName);
    if (_apiKey == null || _apiKey!.isEmpty) {
      await _promptForApiKey();
    }
    if (_apiKey != null && _apiKey!.isNotEmpty) {
      await _loadInitialPrompt();
    } else {
      _addMessage("API Key not provided. Please restart and provide an API Key.", "system");
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _promptForApiKey() async {
    final TextEditingController apiKeyController = TextEditingController();
    await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Gemini API Key'),
          content: TextField(
            controller: apiKeyController,
            decoration: const InputDecoration(hintText: "API Key"),
            obscureText: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Save'),
              onPressed: () async {
                if (apiKeyController.text.isNotEmpty) {
                  await _secureStorage.write(key: _geminiApiKeyName, value: apiKeyController.text);
                  setState(() {
                    _apiKey = apiKeyController.text;
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadInitialPrompt() async {
    if (_apiKey == null || _apiKey!.isEmpty) return;
    try {
      final String prompt = await rootBundle.loadString(_initialPromptPath);
      _addMessage("Starting session with initial prompt...", "system");
      await _sendMessageToLLM(prompt, isInitialPrompt: true);
    } catch (e) {
      _addMessage("Error loading initial prompt: $e", "system");
    }
  }

  void _addMessage(String text, String sender, {String? imageUrl}) {
    setState(() {
      _messages.add({"sender": sender, "text": text, "imageUrl": imageUrl ?? ""});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
      if (sender == "llm" && imageUrl != null && imageUrl.isNotEmpty) {
        _imageUrl = imageUrl;
      }
    });
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.isEmpty || _isLoading) return;
    _textController.clear();
    _addMessage(text, "user");
    await _sendMessageToLLM(text);
  }

  Future<void> _sendMessageToLLM(String text, {bool isInitialPrompt = false}) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      _addMessage("API Key is missing. Cannot send message.", "system");
      await _promptForApiKey();
      if (_apiKey == null || _apiKey!.isEmpty) return;
    }

    setState(() {
      _isLoading = true;
    });

    final Uri geminiApiUrl = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_apiKey');

    final requestBody = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": text}
          ]
        }
      ],
    });

    try {
      final response = await http.post(
        geminiApiUrl,
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        String llmResponseText = "Error: Could not parse LLM response.";
        if (responseBody['candidates'] != null &&
            responseBody['candidates'].isNotEmpty &&
            responseBody['candidates'][0]['content'] != null &&
            responseBody['candidates'][0]['content']['parts'] != null &&
            responseBody['candidates'][0]['content']['parts'].isNotEmpty) {
          llmResponseText = responseBody['candidates'][0]['content']['parts'][0]['text'];
        } else if (responseBody['promptFeedback'] != null &&
            responseBody['promptFeedback']['blockReason'] != null) {
          llmResponseText = "Blocked: ${responseBody['promptFeedback']['blockReason']}";
          if (responseBody['promptFeedback']['safetyRatings'] != null) {
            llmResponseText += "\nDetails: ${responseBody['promptFeedback']['safetyRatings']}";
          }
        }
        _addMessage(llmResponseText, "llm");
      } else {
        String errorBody = response.body;
        try {
          final decodedError = jsonDecode(response.body);
          if (decodedError['error'] != null && decodedError['error']['message'] != null) {
            errorBody = decodedError['error']['message'];
          }
        } catch (_) {}
        _addMessage("Error from LLM: ${response.statusCode}\n$errorBody", "system");
      }
    } catch (e) {
      _addMessage("Error sending message: $e", "system");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildImageDisplay(BuildContext context, Orientation orientation) {
    if (_imageUrl == null) {
      return const SizedBox.shrink();
    }

    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    Widget imageWidget = Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.network(
          _imageUrl!,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
        ),
      ),
    );

    if (orientation == Orientation.landscape) {
      return SizedBox(
        width: screenWidth / 2,
        child: imageWidget,
      );
    } else {
      return SizedBox(
        height: screenHeight / 3,
        width: screenWidth,
        child: imageWidget,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OpenTADA'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                  width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            ),
        ],
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          Widget imageDisplay = _buildImageDisplay(context, orientation);
          Widget chatArea = Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                bool isUser = message['sender'] == 'user';
                bool isSystem = message['sender'] == 'system';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blueAccent : (isSystem ? Colors.grey[700] : Colors.grey[800]),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Text(
                      message['text']!,
                      style: TextStyle(color: isSystem ? Colors.yellowAccent : Colors.white),
                    ),
                  ),
                );
              },
            ),
          );

          Widget inputBar = Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: "Enter your command...",
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _isLoading ? null : _handleSubmitted,
                    enabled: !_isLoading,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _isLoading ? null : () => _handleSubmitted(_textController.text),
                ),
              ],
            ),
          );

          if (orientation == Orientation.landscape && _imageUrl != null) {
            return Row(
              children: <Widget>[
                imageDisplay,
                Expanded(
                  child: Column(
                    children: <Widget>[
                      chatArea,
                      inputBar,
                    ],
                  ),
                ),
              ],
            );
          } else {
            return Column(
              children: <Widget>[
                if (_imageUrl != null) imageDisplay,
                chatArea,
                inputBar,
              ],
            );
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}