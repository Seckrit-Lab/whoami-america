import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenTADA',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const StoryPage(),
    );
  }
}

class StoryPage extends StatefulWidget {
  const StoryPage({super.key});

  @override
  State<StoryPage> createState() => _StoryPageState();
}

class _StoryPageState extends State<StoryPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Widget> _storyContent = [
    const Text("Welcome to OpenTADA IF Engine!\nYour adventure begins..."),
  ];
  String? _currentImageUrl; // Placeholder for image asset path

  void _handleSubmitted(String text) {
    if (text.isEmpty) return;
    setState(() {
      _storyContent.add(Text("> $text", style: const TextStyle(fontStyle: FontStyle.italic)));
      // Placeholder for game logic processing input and generating response
      _storyContent.add(Text("You typed: \"$text\". The story unfolds..."));
      // Example: update image
      // _currentImageUrl = "assets/new_scene.png"; // Make sure this asset exists
    });
    _textController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _buildStoryArea(Orientation orientation, BoxConstraints constraints) {
    return Expanded(
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(8.0),
        itemCount: _storyContent.length,
        itemBuilder: (context, index) {
          // Placeholder for handling inline images on small screens
          // For now, images are handled by the main layout
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: _storyContent[index],
          );
        },
      ),
    );
  }

  Widget _buildImageArea(Orientation orientation, BoxConstraints constraints) {
    if (_currentImageUrl == null) {
      return const SizedBox.shrink();
    }

    final screenSize = MediaQuery.of(context).size;
    final isSmallScreenPhone = (orientation == Orientation.portrait && screenSize.width < 600);

    if (isSmallScreenPhone) {
      // On small phone screens, image is displayed inline or omitted from fixed layout
      // This example will omit it from fixed layout; inline handling is in _buildStoryArea
      return const SizedBox.shrink();
    }

    double imageWidth = 0;
    double imageHeight = 0;

    if (orientation == Orientation.landscape) {
      imageWidth = constraints.maxWidth * 0.5;
      imageHeight = constraints.maxHeight;
    } else { // Portrait (and not small screen phone)
      imageHeight = constraints.maxHeight * 0.5;
      imageWidth = constraints.maxWidth;
    }

    return SizedBox(
      width: imageWidth,
      height: imageHeight,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.asset(
          _currentImageUrl!,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Center(child: Text("Image not found")),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OpenTADA Interactive Fiction'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final orientation = MediaQuery.of(context).orientation;
          final screenSize = MediaQuery.of(context).size;
          final isSmallScreenPhone = (orientation == Orientation.portrait && screenSize.width < 600);

          Widget storyArea = _buildStoryArea(orientation, constraints);
          Widget imageArea = _buildImageArea(orientation, constraints);
          
          Widget inputField = Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: 'Enter command...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: _handleSubmitted,
            ),
          );

          if (isSmallScreenPhone) {
            // Image would be handled inline within storyArea if logic was added there
            return Column(
              children: [
                storyArea,
                inputField,
              ],
            );
          } else if (orientation == Orientation.landscape) {
            return Row(
              children: [
                Expanded(
                  child: Column(children: [storyArea, inputField]),
                ),
                if (_currentImageUrl != null) imageArea,
              ],
            );
          } else { // Portrait (larger screen)
            return Column(
              children: [
                if (_currentImageUrl != null) imageArea,
                storyArea,
                inputField,
              ],
            );
          }
        },
      ),
    );
  }
}