import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

// Import screens
import 'ui/screens/game_screen.dart';

// Global variables (kept in main for app-wide access)
String title = 'Who Am I: America';
String playerPrompt = "You have just arrived in a beautiful neighborhood. A mysterious but warm stranger gives you a gentle smile and says, in a voice like sunshine: \"I am your neighbor, and America is the neighborhood that we share. Would you please tell me a little about yourself? I can make sure to introduce you to friends and neighbors from across this beautiful land. You can learn about them -- maybe even a little about yourself, too.\"";
String bookPath = 'assets/books/Who Am I America.tada.md';
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
        playerPrompt: playerPrompt,
        artStyles: const [
          'Crayon', 
          'Child''s Drawing', 
          'Acrylic on Canvas', 
          'Watercolor', 
          'Colored Pencil', 
          'Oil Painting', 
          'Ukiyo-e', 
          'Chinese watercolor', 
          'Pastels', 
          'Airbrush', 
          'Vector Art', 
          'Watercolor and Pen', 
          'Screen Printing', 
          'Low Poly', 
          'Storybook', 
          'Layered Paper', 
          'Sticker Illustration', 
          'Cutaway', 
          'Blueprint', 
          'Mythological map', 
          'Botanical Illustration', 
          'Voynich Manuscript', 
          'Felt Pieces', 
          'Isometric 3D', 
          'Claymation', 
          'Cel Shading', 
          'Beatrix Potter', 
          'Maurice Sendak', 
          'Dr. Seuss', 
          'Norman Rockwell' 
        ],
      ),
    );
  }
}