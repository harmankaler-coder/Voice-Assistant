import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:project_f/secret.dart';

class OpenAiService {
  final List<Map<String, String>> messages = [];

  // Determine if the prompt should generate an image or text
  Future<String> isArtPromptAPI(String prompt) async {
    try {
      // to determine if the command is related to image generation
      final res = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $openAIAPIKey',
        },
        body: jsonEncode({
          "model": "gpt-3.5-turbo",
          "messages": [
            {
              'role': 'user',
              'content':
              'Is this a prompt for generating an image, picture, or art: "$prompt"? Answer with "image" or "text".',
            }
          ],
        }),
      );

      // Parse the response
      String content = jsonDecode(res.body)['choices'][0]['message']['content'].trim().toLowerCase();

      // Depending on response, either call Dall-E (for images) or ChatGPT (for text)
      if (content.contains('image')) {
        final imageResponse = await dallEAPI(prompt); // Generate image
        return imageResponse;
      } else {
        final textResponse = await chatGPTAPI(prompt); // Generate text
        return textResponse;
      }
    } catch (e) {
      return e.toString();
    }
  }

  // for text generation
  Future<String> chatGPTAPI(String prompt) async {
    messages.add({
      'role': 'user',
      'content': prompt,
    });
    try {
      final res = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $openAIAPIKey',
        },
        body: jsonEncode({
          "model": "gpt-3.5-turbo",
          "messages": messages,
        }),
      );
      if (res.statusCode == 200) {
        String content = jsonDecode(res.body)['choices'][0]['message']['content'];
        content = content.trim();

        messages.add({
          'role': 'assistant',
          'content': content,
        });
        return content;
      }
      return 'An internal error occurred';
    } catch (e) {
      return e.toString();
    }
  }

  // for image generation
  Future<String> dallEAPI(String prompt) async {
    messages.add({
      'role': 'user',
      'content': prompt,
    });
    try {
      final res = await http.post(
        Uri.parse('https://api.openai.com/v1/images/generations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $openAIAPIKey',
        },
        body: jsonEncode({
          'prompt': prompt,
          'n': 1,
        }),
      );
      if (res.statusCode == 200) {
        String imageUrl = jsonDecode(res.body)['data'][0]['url'];
        imageUrl = imageUrl.trim();

        messages.add({
          'role': 'assistant',
          'content': imageUrl,
        });
        return imageUrl;
      }
      return 'An internal error occurred';
    } catch (e) {
      return e.toString();
    }
  }
}