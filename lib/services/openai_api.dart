import 'package:dart_openai/dart_openai.dart';
import '../models/story.dart'; // For ApiException

class OpenAIService {
  final String apiKey;
  final List<String> artStyles;

  OpenAIService({required this.apiKey, required this.artStyles}) {
    // Initialize the OpenAI package with your API key
    OpenAI.apiKey = apiKey;
  }

  void setInitialContext(String context) {
    _initialContext = context;
  }

  Future<String?> generateImage(String prompt) async {
    try {
      final response = await OpenAI.instance.image.create(
        prompt: prompt,
        model: 'dall-e-2',
        responseFormat: OpenAIImageResponseFormat.b64Json,
      );

      if (response.data.isNotEmpty) {
        // Return the base64 encoded image data
        return response.data[0].b64Json;
      }
      return null;
    } catch (e) {
      throw ApiException('Failed to connect to OpenAI API: $e', serviceName: 'OpenAI');
    }
  }

  String? _initialContext;
  
  Future<String> getResponse(String userInput, String recentContext) async {
    // Combine the initial context with recent context for better continuity
    final String fullContext = _initialContext != null 
        ? "$_initialContext\n\nRecent conversation:\n$recentContext"
        : recentContext;
    
    // Build messages array for OpenAI
    final List<OpenAIChatCompletionChoiceMessageModel> messages = [
        OpenAIChatCompletionChoiceMessageModel(
        role: OpenAIChatMessageRole.system,
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(
            "You are a text adventure game engine. Continue the story based on the history and the latest user input. With each response, provide context for image generation by ending your response with a line like 'GENERATE IMAGE: [art style] [detailed prompt for image]'. Choose one of these art styles appropriate for the scene's tone: ${artStyles.join(', ')}. When providing image generation context, mention explicit details of the appearance of characters included, if known. Do not over-emphasize appearance in the main text."
          )
        ]
      ),
    ];
    
    // Add context if available
    if (fullContext.isNotEmpty) {
      messages.add(
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.user,
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text("Previous story turns (most recent last):\n$fullContext")
          ]
        )
      );
    }
    
    // Add user's current action
    messages.add(
      OpenAIChatCompletionChoiceMessageModel(
        role: OpenAIChatMessageRole.user,
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text("User's current action: $userInput")
        ]
      )
    );
    try {
      final response = await OpenAI.instance.chat.create(
        model: 'gpt-4.1-mini', // or 'gpt-3.5-turbo' depending on requirements
        messages: messages,
        temperature: 0.7,
        maxTokens: 900, // Adjust as needed
      );

      if (response.choices.isNotEmpty) {
        final contentItem = response.choices.first.message.content?.first;
        final contentText = (contentItem is OpenAIChatCompletionChoiceMessageContentItemModel)
            ? contentItem.text?.trim()
            : null;
        return contentText ?? "Error: No content in OpenAI response.";
      }
      
      return "Error: No response from OpenAI.";
    } on RequestFailedException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        throw ApiException('Authentication error with OpenAI API. Please check your API key.',
            serviceName: 'OpenAI', isAuthError: true);
      } else if (e.statusCode == 429) {
        throw ApiException('OpenAI API rate limit exceeded. Please try again later or check your plan.',
            serviceName: 'OpenAI', isLimitError: true);
      }
      throw ApiException('Failed to connect to OpenAI API: $e', serviceName: 'OpenAI');
    } catch (e) {
      throw ApiException('Failed to connect to OpenAI API: $e', serviceName: 'OpenAI');
    }
  }
}
