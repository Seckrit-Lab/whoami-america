import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io'; // For File
import 'dart:convert'; // For jsonDecode
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';

// Import other created files
import '../../models/story.dart';
import '../../services/openai_api.dart';
import '../widgets/story_display.dart';
import '../widgets/text_input.dart';
import '../widgets/image_display.dart';

// Import global variables
import '../../main.dart';

class GameScreen extends StatefulWidget {
  final String title;
  final String bookContent;
  final String playerPrompt;
  final List<String> artStyles;

  const GameScreen({
    required this.title,
    required this.bookContent,
    required this.playerPrompt,
    super.key, required List<String> this.artStyles
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  List<StoryElement> storyLog = [];
  String? currentImageData;
  final TextEditingController _inputController = TextEditingController();
  List<String> appLog = [];
  SharedPreferences? _prefsInstance;
  late final String _storyTitle;

  late OpenAIService _openAIService;

  bool _isLoadingState = true;
  bool _gameStarted = false;
  bool _isGeneratingImage = false; // Track image generation state

  @override
  void initState() {
    super.initState();
    _storyTitle = widget.title;
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    _prefsInstance = await SharedPreferences.getInstance();
    await _ensureApiKeys();
    if (openaiApiKey != null) {
      _openAIService = OpenAIService(apiKey: openaiApiKey!, artStyles: widget.artStyles);
      // Load the built-in game data
      await _loadBuiltInGameData();
    } else {
       _addAppLog('One or more API keys are missing. Cannot start game initialization fully.');
    }
    if (mounted) {
      setState(() {
        _isLoadingState = false;
      });
    }
  }

  Future<void> _loadBuiltInGameData() async {
    _addAppLog('Loading provided game data.');
    try {
      // Use the book content provided through constructor instead of loading from assets
      _initializeGameFromTada(widget.bookContent);
      if (mounted) {
        setState(() {
          _gameStarted = true;
        });
      }
    } catch (e) {
      _addAppLog('Error loading provided game data: $e');
      if (mounted) {
        setState(() {
          storyLog.add(TextElement('Error loading game data: $e'));
        });
      }
    }
  }

  Future<String?> _promptForKey(BuildContext dialogContext, String serviceName, String keyName) async {
    String? keyValue;
    TextEditingController keyController = TextEditingController();
    await showDialog(
      context: dialogContext, // Use passed context
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter API Key for $serviceName'),
          content: TextField(
            controller: keyController,
            decoration: InputDecoration(hintText: '$serviceName API Key'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (keyController.text.isNotEmpty) {
                    keyValue = keyController.text;
                }
                Navigator.of(context).pop();
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
    if (keyValue?.isNotEmpty == true) {
      await _prefsInstance!.setString(keyName, keyValue!);
      _addAppLog('API Key for $serviceName stored.');
    } else {
       _addAppLog('API Key for $serviceName not provided or submitted empty.');
    }
    return keyValue;
  }

  Future<void> _ensureApiKeys() async {
    openaiApiKey = _prefsInstance!.getString('openai_api_key');
    if (openaiApiKey == null || openaiApiKey!.isEmpty) {
      _addAppLog('OpenAI API Key not found. Prompting user.');
      if (mounted) {
        openaiApiKey = await _promptForKey(context, "OpenAI", "openai_api_key");
      }
    }

    if (openaiApiKey == null) {
        _addAppLog('Essential API keys are missing. Application might not function correctly.');
    }
  }

  Future<void> _promptForTadaJson() async {
    _addAppLog('Prompting user to select a .tada.json file.');
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      String filePath = result.files.single.path!;
      if (!filePath.toLowerCase().endsWith('.tada.json')) {
          _addAppLog('Selected file is not a .tada.json file: $filePath');
          if(mounted) {
            setState(() {
            storyLog.add(TextElement('Error: Please select a .tada.json file.'));
          });
          }
          return;
      }
      
      File file = File(filePath);
      try {
        String fileContent = await file.readAsString();
        _addAppLog('.tada.json file loaded: ${file.path}');
        _initializeGameFromTada(fileContent);
        if(mounted) {
          setState(() {
          _gameStarted = true;
        });
        }
      } catch (e) {
        _addAppLog('Error reading or parsing .tada.json file: $e');
        if(mounted) {
          setState(() {
          storyLog.add(TextElement('Error loading game file: $e'));
        });
        }
      }
    } else {
      _addAppLog('No .tada.json file selected.');
      if(mounted) {
        setState(() {
        storyLog.add(TextElement('No game file selected. Please select a .tada.json file to start.'));
      });
      }
    }
  }

  void _initializeGameFromTada(String tadaMarkdownContent) {
    _addAppLog('Initializing game from .tada.md content.');
    try {
      // Create the initial prompt for the LLM
      const String initialPrompt = "The following is the script for an interactive fiction game. ";
    
      // Combine the instruction with the Markdown content
      final String combinedPrompt = "$initialPrompt\n\n$tadaMarkdownContent";
    
      // Store this as the first context for the OpenAI service
      _openAIService.setInitialContext(combinedPrompt);
    
      // Add initial greeting to the story log
      if(mounted) {
        setState(() {
          storyLog.clear(); // Clear previous logs if any
          storyLog.add(TextElement(widget.playerPrompt));
        });
      }
    } catch (e) {
      _addAppLog('Error initializing game from .tada.md: $e');
      if(mounted) {
        setState(() {
          storyLog.add(TextElement('Error processing game file: $e'));
        });
      }
    }
  }

  Future<void> _handleUserInput(String input) async {
    if (input.trim().isEmpty || !_gameStarted) return;
    _addAppLog('User input: $input');
    final userInputElement = UserInputElement(input);
    if(mounted) {
      setState(() {
      storyLog.add(userInputElement);
    });
    }
    _inputController.clear();

    try {
      _addAppLog('Sending to OpenAI: $input');
      String storyResponse = await _openAIService.getResponse(input, storyLogToString());
      _addAppLog('Received from OpenAI: $storyResponse');
      
      // Clean the response before displaying it to the user
      String displayText = storyResponse;
      if (storyResponse.toLowerCase().contains("generate image:")) {
        // Remove the image generation prompt from the displayed text
        displayText = storyResponse.substring(0, storyResponse.toLowerCase().lastIndexOf("generate image:")).trim();
      } else if (storyResponse.toLowerCase().contains("new scene image:")) {
        // Remove the image generation prompt from the displayed text
        displayText = storyResponse.substring(0, storyResponse.toLowerCase().lastIndexOf("new scene image:")).trim();
      }
      
      if(mounted) {
        setState(() {
          storyLog.add(TextElement(displayText));
        });
      }

      if (storyResponse.toLowerCase().contains("generate image:") || storyResponse.toLowerCase().contains("new scene image:")) { 
        String imagePrompt = storyResponse.substring(storyResponse.toLowerCase().indexOf("image:") + 6).trim();
        if (imagePrompt.isEmpty) imagePrompt = "Sci-fi scene: ${storyLog.lastWhere((e) => e is TextElement, orElse: () => TextElement('')).text}";
        
        _addAppLog('Requesting image from OpenAI for prompt: $imagePrompt');
        // Set generating state to true
        if (mounted) {
          setState(() {
            _isGeneratingImage = true;
          });
        }
        
        try {
          String? imageData = await _openAIService.generateImage(imagePrompt);
          _addAppLog('Received base64 image data from OpenAI');
          if (imageData != null && mounted) {
            setState(() {
              currentImageData = imageData; // Now storing base64 data
              storyLog.add(ImageElement(imageData));
              _isGeneratingImage = false; // Set back to false when complete
            });
          } else {
            if (mounted) {
              setState(() {
                _isGeneratingImage = false; // Set back to false on failure
              });
            }
            _addAppLog('Failed to generate image or component not mounted.');
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _isGeneratingImage = false; // Set back to false on error
            });
          }
          _addAppLog('Error generating image: $e');
        }
      }
    } on ApiException catch (e) {
        _addAppLog('API Error: ${e.message}');
        if(mounted) {
          setState(() {
          storyLog.add(TextElement('API Error: ${e.message}'));
        });
        }
        if (e.isAuthError || e.isLimitError) {
            _addAppLog('Attempting to re-authenticate for ${e.serviceName}');
            if (e.serviceName.toLowerCase().contains('openai')) {
                await _prefsInstance!.remove('openai_api_key');
                openaiApiKey = null;
            }
            await _ensureApiKeys(); 
            if ((e.serviceName.toLowerCase().contains('openai') && openaiApiKey != null && _prefsInstance!.getString('openai_api_key') != null) ) {
                 _addAppLog('New API key provided for ${e.serviceName}. Please try your command again.');
                 if(mounted) {
                   setState(() {
                     storyLog.add(TextElement('New API key provided for ${e.serviceName}. Please try your command again.'));
                 });
                 }
            } else {
                 _addAppLog('Failed to get new API key for ${e.serviceName}.');
                 if(mounted) {
                   setState(() {
                     storyLog.add(TextElement('Failed to get new API key for ${e.serviceName}.'));
                 });
                 }
            }
        }
    } catch (e) {
      _addAppLog('Error processing input: $e');
      if(mounted) {
        setState(() {
        storyLog.add(TextElement('Error: Could not process your request. $e'));
      });
      }
    }
  }

  String storyLogToString() {
    // Provide limited history to avoid large payloads / context window issues
    return storyLog.reversed.whereType<TextElement>().take(5).map((e) => e.text).toList().reversed.join('\n');
  }
  
  void _addAppLog(String message) {
    final timestamp = DateTime.now().toIso8601String();
    if(mounted) {
      setState(() {
      appLog.insert(0, '$timestamp: $message');
    });
    }
    // Log to console for easier debugging during development
    // print('$timestamp: $message'); 
  }

  void _showAppLog() {
    _addAppLog('Application log viewed.');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Application Log'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: appLog.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text(appLog[index], style: const TextStyle(fontSize: 12)),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            )
          ],
        );
      },
    );
  }

  Future<void> _exportToPdf() async {
    _addAppLog('Exporting story to PDF');
    final pdf = pw.Document();
    
    // Create a PDF document
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Text('$_storyTitle - Story Export', 
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}'),
        ),
        build: (context) => _buildPdfContent(),
      ),
    );
    
    try {
      // Get temporary directory for saving the file
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/story_export.pdf');
      
      // Save the PDF
      await file.writeAsBytes(await pdf.save());
      _addAppLog('PDF saved to: ${file.path}');
      
      if (mounted) {
        // Show success message with option to open the file
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('PDF exported successfully'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () async {
                if (await file.exists()) {
                  // Use system default viewer to open the PDF
                  await Printing.layoutPdf(
                    onLayout: (_) async => await file.readAsBytes(),
                  );
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      _addAppLog('Error exporting PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting PDF: $e')),
        );
      }
    }
  }
  
  List<pw.Widget> _buildPdfContent() {
    List<pw.Widget> content = [];
    
    // Add each story element to the PDF
    for (var element in storyLog) {
      if (element is TextElement || element is UserInputElement) {
        // Add text elements
        content.add(
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 8),
            child: pw.Text(
              element.text,
              style: element is UserInputElement 
                ? pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue)
                : const pw.TextStyle(),
            ),
          )
        );
      } else if (element is ImageElement) {
        // Add image elements (if possible)
        try {
          final imageData = base64Decode(element.imageUrl);
          final image = pw.MemoryImage(imageData);
          content.add(
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 16),
              child: pw.Center(
                child: pw.Image(image, height: 300),
              ),
            )
          );
        } catch (e) {
          content.add(
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 8),
              child: pw.Text('[Image could not be included in PDF]', 
                style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
            )
          );
        }
      }
    }
    
    return content;
  }

  Future<void> _printStory() async {
    _addAppLog('Printing story');
    await Printing.layoutPdf(
      onLayout: (format) async {
        final pdf = pw.Document();
        pdf.addPage(
          pw.MultiPage(
            pageFormat: format,
            margin: const pw.EdgeInsets.all(32),
            header: (context) => pw.Text(_storyTitle, 
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            footer: (context) => pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(top: 10),
              child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}'),
            ),
            build: (context) => _buildPdfContent(),
          ),
        );
        return pdf.save();
      },
    );
    _addAppLog('Print dialog closed');
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.print),
                title: const Text('Print Story'),
                onTap: () {
                  Navigator.pop(context);
                  _printStory();
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('Export to PDF'),
                onTap: () {
                  Navigator.pop(context);
                  _exportToPdf();
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoadingState) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (openaiApiKey == null) {
         return Scaffold(
            appBar: AppBar(title: const Text('Tada - API Key Error')),
            body: Center(
                child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'One or more API keys are missing. Please provide them when prompted or ensure they are stored.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isLoadingState = true;
                            });
                            _initializeApp(); // Retry initialization
                          },
                          child: const Text('Retry API Key Setup'),
                        )
                      ],
                    )
                ),
            ),
        );
    }
    if (!_gameStarted) {
        return Scaffold(
            appBar: AppBar(title: const Text('Tada - Load Game')),
            body: Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        if (storyLog.isNotEmpty && storyLog.last is TextElement)
                            Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text((storyLog.last as TextElement).text, style: TextStyle(color: storyLog.last.text.toLowerCase().contains('error') ? Colors.red : Theme.of(context).textTheme.bodyLarge?.color), textAlign: TextAlign.center,),
                            ),
                        ElevatedButton(
                            onPressed: _promptForTadaJson,
                            child: const Text('Select Game File (.tada.json)'),
                        ),
                    ],
                ),
            ),
             floatingActionButton: FloatingActionButton(
                onPressed: _showAppLog,
                tooltip: 'Show Application Log',
                child: const Icon(Icons.receipt_long),
            ),
        );
    }

    final orientation = MediaQuery.of(context).orientation;
    final screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 600;

    Widget imageWidget = _isGeneratingImage
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Generating image...', style: TextStyle(fontStyle: FontStyle.italic)),
              ],
            ),
          )
        : currentImageData != null
            ? ImageDisplay(
                key: ValueKey(currentImageData),
                imageData: currentImageData!,
                isSmallScreen: isSmallScreen,
              )
            : const SizedBox.shrink();

    Widget storyArea = Expanded(
      child: StoryDisplay(storyLog: storyLog, imageForSmallScreen: isSmallScreen && currentImageData != null ? imageWidget : null),
    );
    Widget inputArea = TextInput(controller: _inputController, onSubmitted: _handleUserInput);

    return Scaffold(
      appBar: AppBar(
        title: _storyTitle.isNotEmpty ? Text(_storyTitle) : const Text('Tada - Interactive Fiction'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            onPressed: _showExportOptions,
            tooltip: 'Export Story',
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: _showAppLog,
            tooltip: 'Show Application Log',
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (isSmallScreen) {
              return Column(
                children: [
                  storyArea, // StoryDisplay handles inline image if imageForSmallScreen is provided
                  inputArea,
                ],
              );
            } else if (orientation == Orientation.landscape) {
              return Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [storyArea, inputArea],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Center(child: Padding(padding: const EdgeInsets.all(8.0), child: imageWidget)),
                  ),
                ],
              );
            } else { // Portrait
              return Column(
                children: [
                  Expanded(
                    flex: 1,
                    child: Center(child: Padding(padding: const EdgeInsets.all(8.0), child: imageWidget)),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [storyArea, inputArea],
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}