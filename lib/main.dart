import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

// Import screens
import 'ui/screens/game_screen.dart';

// Global variables (kept in main for app-wide access)
String title = 'Welcome to the Neybahood';
String playerPrompt = "Hello, and welcome to the Neybahood! Please tell me a bit about yourself, so that you can have a happy time in the neybahood that's just for you.";
String bookPath = 'assets/books/Welcome to the Neybahood.tada.md';
String? geminiApiKey;
String? openaiApiKey;
late String bookContent;

void main() async {
  // This is needed when using async in main
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load the book content
  bookContent = await rootBundle.loadString(bookPath);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: GameScreen(
        title: title,
        bookContent: bookContent,
        playerPrompt: playerPrompt
      ),
    );
  }
}