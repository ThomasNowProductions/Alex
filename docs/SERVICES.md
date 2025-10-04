# Services Documentation

## Overview

The service layer contains the core business logic for Alex AI Companion, handling AI integration, conversation management, and data persistence.

## Core Services

### ConversationService

Manages conversation history, context persistence, and message storage.

#### Key Features
- **Persistent Storage**: Saves conversations to local device storage
- **Context Management**: Maintains conversation history and summaries
- **Message Handling**: Adds, retrieves, and manages conversation messages
- **Memory Optimization**: Handles large conversation truncation

#### API Reference

##### `loadContext()`
Loads conversation context from local storage.

```dart
static Future<void> loadContext() async
```

**Behavior**:
- Reads `conversation_context.json` from application documents directory
- Deserializes JSON data into ConversationContext object
- Handles file not found and corruption gracefully
- Initializes empty context if no existing data

##### `saveContext()`
Persists current conversation context to local storage.

```dart
static Future<void> saveContext() async
```

**Behavior**:
- Serializes ConversationContext to JSON format
- Writes to application documents directory
- Handles storage errors gracefully
- Non-blocking operation for smooth UX

##### `addMessage(String text, bool isUser)`
Adds a new message to the conversation.

```dart
static void addMessage(String text, bool isUser)
```

**Parameters**:
- `text`: Message content
- `isUser`: `true` for user messages, `false` for AI responses

**Behavior**:
- Creates new ConversationMessage with current timestamp
- Appends to existing message list
- Updates conversation context
- Maintains message order

##### `updateSummary(String summary)`
Updates the conversation summary.

```dart
static void updateSummary(String summary)
```

**Behavior**:
- Updates the summary field in conversation context
- Maintains message history
- Updates last modified timestamp

##### `clearContext()`
Clears all conversation data.

```dart
static void clearContext()
```

**Behavior**:
- Removes all messages and summary
- Resets to initial state
- Updates timestamp

##### `getRecentMessages({int limit = 50})`
Retrieves recent messages for context.

```dart
static List<ConversationMessage> getRecentMessages({int limit = 50})
```

**Parameters**:
- `limit`: Maximum number of messages to return (default: 50)

**Returns**: List of recent messages, most recent first

#### Storage Format

Conversation data is stored as JSON in `conversation_context.json`:

```json
{
  "messages": [
    {
      "text": "Hello, Alex!",
      "isUser": true,
      "timestamp": "2024-01-15T10:30:00.000Z"
    },
    {
      "text": "Hi there! How are you doing?",
      "isUser": false,
      "timestamp": "2024-01-15T10:30:05.000Z"
    }
  ],
  "summary": "User greeted Alex and asked about their wellbeing.",
  "lastUpdated": "2024-01-15T10:30:05.000Z"
}
```

### OllamaService

Handles communication with the Ollama Cloud API for AI responses.

#### Key Features
- **API Integration**: Communicates with Ollama Cloud API
- **Context Enhancement**: Includes conversation history in prompts
- **System Prompt Management**: Loads personality from JSON file
- **Error Handling**: Comprehensive error management and recovery

#### Configuration

##### Environment Variables
```env
OLLAMA_BASE_URL=https://ollama.com/api
OLLAMA_API_KEY=your-api-key-here
OLLAMA_MODEL=gpt-oss:120b-cloud
```

##### System Prompt File (`assets/system_prompt.json`)
```json
{
  "systemPrompt": "You are Alex, a loyal AI best friend..."
}
```

#### API Reference

##### `getCompletion(String prompt)`
Generates AI response for user input.

```dart
static Future<String> getCompletion(String prompt) async
```

**Parameters**:
- `prompt`: User's message text

**Returns**: AI-generated response string

**Process**:
1. Validates API key configuration
2. Loads system prompt from assets
3. Builds conversation context
4. Makes API request to Ollama Cloud
5. Returns processed response

**Error Handling**:
- Throws exception for missing/invalid API key
- Handles network connectivity issues
- Manages API rate limits and errors

#### Context Building

The service automatically builds conversation context:

```dart
String _buildContextPrompt(ConversationContext context) {
  // Includes recent messages (last 10)
  // Adds conversation summary if available
  // Provides context instructions for AI
}
```

### SummarizationService

Provides intelligent conversation summarization for long-term memory.

#### Key Features
- **Smart Summarization**: Extracts key information from conversations
- **Structured Output**: Returns JSON-formatted summaries
- **Context Preservation**: Maintains important conversation details
- **Automatic Triggers**: Summarizes based on message count thresholds

#### API Reference

##### `summarizeConversation(List<ConversationMessage> messages)`
Creates structured summary of conversation.

```dart
static Future<String> summarizeConversation(List<ConversationMessage> messages) async
```

**Parameters**:
- `messages`: List of conversation messages to summarize

**Returns**: JSON-formatted summary string

**Summary Structure**:
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

#### Summarization Triggers

Automatic summarization occurs when:
- Message count exceeds `summarizationThreshold` (10 messages)
- Message count exceeds `summarizationUpdateThreshold` (25 messages)
- App is closing with sufficient conversation history

## Utility Services

### SpeechUtils

Handles speech recognition functionality across platforms.

#### Features
- **Cross-Platform Support**: Works on mobile and web platforms
- **Error Handling**: Platform-specific error management
- **Status Management**: Speech recognition state tracking

#### Key Methods

##### `initializeSpeech({Function onError, Function onStatus})`
Initializes speech recognition system.

```dart
static Future<bool> initializeSpeech({
  Function? onError,
  Function? onStatus
}) async
```

##### `startListening(SpeechToText speech, {Function onResult})`
Begins speech recognition.

```dart
static Future<void> startListening(
  stt.SpeechToText speech, {
  Function? onResult
}) async
```

##### `stopListening(SpeechToText speech)`
Stops speech recognition.

```dart
static Future<void> stopListening(stt.SpeechToText speech) async
```

### PermissionUtils

Manages platform-specific permissions.

#### Features
- **Microphone Permissions**: Android microphone access
- **Permission Requests**: User-friendly permission prompts
- **Graceful Degradation**: Handles denied permissions

#### Key Methods

##### `requestMicrophonePermission(BuildContext context)`
Requests microphone permission on Android.

```dart
static Future<bool> requestMicrophonePermission(BuildContext context) async
```

### PlatformUtils

Provides cross-platform compatibility utilities.

#### Features
- **Platform Detection**: Identifies current platform
- **Feature Support**: Checks platform capabilities
- **Platform-Specific Logic**: Conditional behavior based on platform

#### Key Properties

```dart
static bool get isAndroid => Platform.isAndroid;
static bool get isIOS => Platform.isIOS;
static bool get isWeb => kIsWeb;
static bool get isDesktop => Platform.isLinux || Platform.isMacOS || Platform.isWindows;
```

## Service Integration

### Service Dependencies

```
┌─────────────────────────────────────┐
│           ChatScreen                │
├─────────────────────────────────────┤
│  ↓ Uses        ↓ Uses       ↓ Uses  │
│ ┌───────────┐ ┌───────────┐ ┌──────┐ │
│ │OllamaSvc  │ │ConvSvc    │ │Speech│ │
│ │           │ │           │ │Utils │ │
│ └───────────┘ └───────────┘ └──────┘ │
│  ↓ Uses        ↓ Uses                │
│ ┌───────────┐ ┌───────────┐           │
│ │SummSvc    │ │Storage    │           │
│ └───────────┘ └───────────┘           │
└─────────────────────────────────────┘
```

### Initialization Flow

1. **App Startup**
   - Load environment variables
   - Initialize Flutter widgets
   - Start ChatScreen

2. **ChatScreen Initialization**
   - Initialize ConversationService (load context)
   - Initialize speech recognition
   - Set up event handlers

3. **Service Ready**
   - All services operational
   - Ready for user interaction

## Error Handling

### Common Error Scenarios

#### Network Issues
- API connectivity problems
- Timeout handling
- Retry mechanisms

#### Storage Issues
- File system access problems
- JSON serialization errors
- Disk space limitations

#### Permission Issues
- Microphone access denied
- Graceful degradation strategies

#### Platform Limitations
- Speech recognition not available
- Platform-specific feature limitations

### Error Recovery

1. **Automatic Recovery**
   - Retry failed operations
   - Fallback to cached data
   - Graceful error messages

2. **User Intervention**
   - Clear error messages
   - Actionable error descriptions
   - Recovery suggestions

## Performance Considerations

### Memory Management
- Conversation context size limits
- Automatic cleanup of old messages
- Efficient JSON serialization

### Network Optimization
- Minimized API payload size
- Context truncation for large conversations
- Response caching strategies

### UI Responsiveness
- Async service operations
- Non-blocking file I/O
- Background processing for heavy operations

## Best Practices

### Service Design
1. **Single Responsibility**: Each service has one primary purpose
2. **Dependency Injection**: Services are loosely coupled
3. **Error Handling**: Comprehensive error management
4. **Async Operations**: Non-blocking service methods

### Data Management
1. **Consistent Storage**: Standardized JSON format
2. **Data Validation**: Input validation and sanitization
3. **Backup Strategies**: Data integrity protection
4. **Privacy Protection**: Local-only data storage

### API Integration
1. **Secure Communication**: HTTPS-only API calls
2. **Authentication**: Secure API key management
3. **Rate Limiting**: Respect API limitations
4. **Fallback Planning**: Offline functionality planning

This service layer provides a robust, maintainable foundation for the AI companion application.