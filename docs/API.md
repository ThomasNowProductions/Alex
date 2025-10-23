# API Documentation

## Overview

Alex AI Companion integrates with the Ollama Cloud API to provide intelligent responses and conversation summarization capabilities.

## Authentication

### API Key Configuration

The application requires an Ollama Cloud API key for all AI functionality:

```env
OLLAMA_API_KEY=your-actual-api-key-here
```

**Important**: Never commit API keys to version control. Use environment variables or secure key management.

## Endpoints

### Chat Completion

**Endpoint**: `POST /chat`

Generates AI responses based on conversation context and user input.

**Headers**:
```
Content-Type: application/json
Authorization: Bearer {OLLAMA_API_KEY}
```

**Request Body**:
```json
{
  "model": "deepseek-v3.1:671b",
  "messages": [
    {
      "role": "system",
      "content": "Enhanced system prompt with conversation context"
    },
    {
      "role": "user",
      "content": "User's message"
    }
  ],
  "stream": false
}
```

**Response**:
```json
{
  "message": {
    "content": "AI response text"
  }
}
```

## Services

### OllamaService

Primary service for AI chat completions.

**Key Methods**:

#### `getCompletion(String prompt)`

Generates an AI response for the given user prompt and provides any supporting web search context.

```dart
final aiResponse = await OllamaService.getCompletion("Hello, Alex!");
print(aiResponse.content); // model reply
print(aiResponse.webResults); // optional live search results
```

**Features**:
- Automatic system prompt loading from `assets/system_prompt.json`
- Conversation context integration
- Optional Ollama `web_search`/`web_fetch` enrichment with adjustable limits
- Error handling for API failures
- Environment variable configuration

### SummarizationService

Handles conversation summarization for long-term memory management.

#### `summarizeConversation(List<ConversationMessage> messages)`

Creates a structured summary of conversation history.

```dart
String summary = await SummarizationService.summarizeConversation(messages);
```

**Summary Format**:
```json
{
  "keyTopics": ["topic1", "topic2"],
  "importantFacts": ["fact1", "fact2"],
  "userPreferences": ["preference1"],
  "goalsAndPlans": ["goal1"],
  "recurringThemes": ["theme1"],
  "contextualDetails": ["detail1"],
  "summary": "Concise paragraph summary"
}
```

## Models

### ConversationMessage

Represents a single message in the conversation.

```dart
class ConversationMessage {
  final String text;
  final bool isUser;        // true for user messages, false for AI
  final DateTime timestamp;
}
```

### ConversationContext

Contains the complete conversation state.

```dart
class ConversationContext {
  final List<ConversationMessage> messages;
  final String summary;     // AI-generated conversation summary
  final DateTime lastUpdated;
}
```

## Error Handling

### Common Error Scenarios

1. **Invalid API Key**
   ```
   Exception: Please set your OLLAMA_API_KEY in assets/.env file
   ```

2. **Network Errors**
   ```
   Exception: Error connecting to Ollama Cloud API: [specific error]
   ```

3. **API Rate Limits**
   - Implement retry logic with exponential backoff
   - Consider caching recent responses

4. **Invalid Response Format**
   ```
   Exception: Failed to get AI response: [status code] - [response body]
   ```

## Configuration

### Environment Variables

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `OLLAMA_BASE_URL` | API base URL | No | `https://ollama.com/api` |
| `OLLAMA_API_KEY` | Authentication key | Yes | - |
| `OLLAMA_MODEL` | AI model selection | No | `deepseek-v3.1:671b` |

> **💡 Recommendation**: We recommend using `deepseek-v3.1:671b` as your AI model for optimal performance and response quality. This model provides excellent context understanding and personality consistency for the Alex AI Companion experience.

### System Prompt

The AI personality is defined in `assets/system_prompt.json`:

```json
{
  "systemPrompt": "You are Alex, a loyal AI best friend with a rich, consistent personality..."
}
```

## Best Practices

### API Usage

1. **Key Security**: Store API keys securely, never in code
2. **Error Handling**: Implement comprehensive error handling for all API calls
3. **Rate Limiting**: Respect API rate limits and implement retry logic
4. **Context Management**: Keep conversation context concise to avoid token limits
5. **Fallback Handling**: Provide graceful degradation when API is unavailable

### Performance

1. **Context Truncation**: Limit conversation history to recent messages
2. **Caching**: Cache frequent API responses when appropriate
3. **Async Operations**: Use async/await for all API calls
4. **Memory Management**: Clear large conversation contexts periodically

## Testing

### Mock API Responses

For testing without API calls:

```dart
// Mock implementation example
class MockOllamaService {
  static Future<AIResponse> getCompletion(String prompt) async {
    await Future.delayed(Duration(seconds: 1)); // Simulate network delay
    return AIResponse(
      content: "Mock response for: $prompt",
      webResults: const [],
    );
  }
}
```

## Troubleshooting

### Common Issues

1. **Authentication Failures**
   - Verify API key is correctly set in environment variables
   - Check API key validity and permissions

2. **Network Connectivity**
   - Verify internet connection
   - Check firewall and proxy settings
   - Validate API endpoint URL

3. **Response Timeouts**
   - Implement appropriate timeout values
   - Consider retry mechanisms for transient failures

4. **Context Length Issues**
   - Monitor conversation context size
   - Implement context truncation strategies
   - Consider summarization for long conversations