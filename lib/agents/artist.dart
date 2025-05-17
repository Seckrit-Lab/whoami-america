import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:openai_dart/openai_dart.dart'; // Import OpenAI
import 'dart:convert'; // For base64 decoding
import 'package:http/http.dart' as http; // For fetching image data if URL is returned

class Artist {
  final OpenAIClient _openAIClient; // Changed from GenerativeModel
  final Function(String) logMessage;

  Artist({
    required String apiKey,
    required this.logMessage,
  }) : _openAIClient = OpenAIClient(apiKey: apiKey); // Initialize OpenAIClient

  /// Generate an image based on a prompt
  Future<Uint8List?> generateImage(String prompt, {String? artStyle}) async {
    try {
      String enhancedPrompt = prompt;

      // Add art style preference if specified
      if (artStyle != null && artStyle.isNotEmpty) {
        enhancedPrompt += ' Style: $artStyle';
      }

      logMessage('Director/Scribe to Artist: $enhancedPrompt');

      final request = CreateImageRequest(
        prompt: enhancedPrompt,
        n: 1, // Number of images to generate
        //size: CreateImageRequestSize.s1024x1024, // Or other supported sizes like s1792x1024 or s1024x1792 for DALL-E 3
        //responseFormat: CreateImageRequestResponseFormat.b64Json, // Or url
        model: CreateImageRequestModel.model(ImageModels.dallE3), // Explicitly use DALL-E 3
        // quality: CreateImageRequestQuality.hd, // Optional: for DALL-E 3, can be 'standard' or 'hd'
        // style: CreateImageRequestStyle.vivid, // Optional: for DALL-E 3, can be 'vivid' or 'natural'
      );

      final response = await _openAIClient.createImage(request: request);

      if (response.data.isNotEmpty) {
        final imageData = response.data.first;
        if (imageData.b64Json != null) {
          logMessage('Artist to Player: [Generated image]');
          return base64Decode(imageData.b64Json!);
        } else if (imageData.url != null) {
          // If URL is returned, you need to fetch the image data
          logMessage('Artist to Player: [Generated image URL: ${imageData.url}]');
          final imageResponse = await http.get(Uri.parse(imageData.url!));
          if (imageResponse.statusCode == 200) {
            logMessage('Artist to Player: [Fetched image from URL]');
            return imageResponse.bodyBytes;
          } else {
            logMessage('Artist to Player: [Failed to fetch image from URL: ${imageResponse.statusCode}]');
          }
        }
      }

      logMessage('Artist to Player: [Failed to generate image - no data]');
      return null;
    } catch (e) {
      debugPrint('Error generating image: $e');
      logMessage('Artist to Player: [Error generating image: $e]');
      return null;
    }
  }

  /// Generate a title screen for a book
  Future<Uint8List?> generateTitleScreen(
      String title, String setting, {
      List<String>? characterDescriptions,
      String? location,
      String? artStyle,
  }) async {
    final charactersText = characterDescriptions != null && characterDescriptions.isNotEmpty
        ? 'Characters: ${characterDescriptions.join(", ")}'
        : '';

    final locationText = location != null && location.isNotEmpty
        ? 'Location: $location'
        : '';

    final prompt = '''
Create a title screen image for a text adventure game titled "$title".
The setting is: $setting
$charactersText
$locationText
Include the title "$title" in the image.
''';

    return generateImage(prompt, artStyle: artStyle);
  }
}