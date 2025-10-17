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

### MemoryManager

Advanced memory management system with intelligent importance scoring and hierarchical memory organization.

#### Key Features
- **Importance Scoring**: Automatically scores message importance based on multiple factors
- **Hierarchical Memory**: Organizes memories into short-term, medium-term, long-term, and critical categories
- **Automatic Consolidation**: Consolidates related memories to optimize storage
- **Topic Detection**: Extracts topics from conversations for better organization
- **Memory Compression**: Compresses old memories to save space
- **Auto Cleanup**: Removes expired and low-importance memories

#### Configuration

##### MemoryConfig Model
```dart
class MemoryConfig {
  final bool enableAutoConsolidation;
  final Duration consolidationInterval;
  final int maxShortTermMessages;
  final int maxMediumTermSegments;
  final int maxLongTermSegments;
  final double criticalImportanceThreshold;
  final double longTermImportanceThreshold;
  final double mediumTermImportanceThreshold;
  final double minMessageImportance;
  final int minMessageLength;
  final List<String> priorityKeywords;
  final bool enableMemoryCompression;
  final int maxSummarizationLength;
}
```

#### API Reference

##### `processMessages(List<ConversationMessage> messages, ConversationContext context)`
Processes new messages and creates appropriate memory segments.

```dart
Future<void> processMessages(List<ConversationMessage> newMessages, ConversationContext context) async
```

##### `getRelevantMemories(String query, {int limit = 10})`
Retrieves memories most relevant to a given query.

```dart
List<MemorySegment> getRelevantMemories(String query, {int limit = 10})
```

##### `getMemoryMetrics()`
Returns current memory usage metrics.

```dart
MemoryMetrics getMemoryMetrics()
```

#### Memory Types

- **Critical**: Extremely important memories (importance ≥ 0.8)
- **Long-term**: Important memories preserved for extended periods (importance ≥ 0.6)
- **Medium-term**: Moderately important memories (importance ≥ 0.4)
- **Short-term**: Temporary memories for recent context (importance < 0.4)

#### Importance Factors

Messages are scored based on:
- Message length and complexity
- Priority keywords presence
- Question indicators
- User vs AI messages
- Recency (recent messages score higher)
- Emotional content indicators
- Personal information indicators

### SettingsService

Manages user settings, preferences, and application configuration.

#### Key Features
- **Persistent Storage**: Saves settings to local JSON file
- **Theme Management**: Light, dark, and system theme modes
- **PIN Lock Security**: Secure PIN-based app locking with SHA-256 hashing
- **API Key Management**: Support for both inbuilt and custom API keys
- **Settings Migration**: Handles settings updates and migrations

#### Storage Format

Settings are stored in `user_settings.json`:
```json
{
  "themeMode": "system",
  "pinLockEnabled": false,
  "pinCode": "hashed_pin_value",
  "apiKeySource": "inbuilt",
  "customApiKey": "custom_key_if_used"
}
```

#### API Reference

##### `loadSettings()`
Loads settings from local storage.

```dart
static Future<void> loadSettings() async
```

##### `saveSettings()`
Persists current settings to storage.

```dart
static Future<void> saveSettings() async
```

##### `setSetting(String key, dynamic value)`
Updates a specific setting value.

```dart
static void setSetting(String key, dynamic value)
```

##### `setPinLock(String pin)`
Enables PIN lock with hashed password.

```dart
static void setPinLock(String pin)
```

##### `verifyPin(String pin)`
Verifies PIN against stored hash.

```dart
static bool verifyPin(String pin)
```

##### `getCurrentApiKey()`
Returns the appropriate API key based on configuration.

```dart
static String getCurrentApiKey()
```

#### Security Features

- **PIN Hashing**: Uses SHA-256 for secure PIN storage
- **No Plaintext Storage**: Sensitive data is never stored in plaintext
- **Secure Defaults**: Secure defaults for all settings

### SafetyService

Monitors and filters content for safety and appropriateness.

#### Key Features
- **Content Filtering**: Scans messages for sensitive or inappropriate content
- **Keyword Detection**: Identifies sensitive keywords and phrases
- **Safety Scoring**: Assigns safety scores to messages
- **Filtering Actions**: Takes appropriate actions based on safety levels
- **Help Resources**: Provides crisis intervention and mental health resources

#### Configuration

Uses `assets/sensitive_keywords.json` for filtering configuration:
```json
{
  "keywords": [
    "kill myself", "end it all", "take my life",
    "self harm", "hurt myself", "suicide",
    "want to die", "not worth living"
  ]
}
```

#### Help Resources

Uses `assets/help_resources.json` for crisis intervention resources:
```json
{
  "resources": {
    "crisis": [
      "988 Suicide & Crisis Lifeline (US): Call or text 988",
      "Crisis Text Line: Text HOME to 741741"
    ],
    "mental_health": [
      "National Alliance on Mental Illness (NAMI): 1-800-950-6264"
    ],
    "emergency": [
      "Emergency Services: Call 911 (US) or your local emergency number"
    ]
  }
}
```

#### API Reference

##### `initialize()`
Initializes the safety service by loading keywords and resources.

```dart
static Future<void> initialize() async
```

##### `containsSensitiveContent(String message)`
Checks if a message contains sensitive content.

```dart
static bool containsSensitiveContent(String message)
```

##### `getHelpResources()`
Returns all available help resources.

```dart
static List<String> getHelpResources()
```

##### `getHelpResourcesByCategory(String category)`
Returns help resources for a specific category.

```dart
static List<String> getHelpResourcesByCategory(String category)
```

##### `generateSafeResponse()`
Generates a supportive response for sensitive situations.

```dart
static String generateSafeResponse()
```

#### Safety Features

- **Fallback Keywords**: Uses built-in sensitive keywords if file loading fails
- **Fallback Resources**: Provides default crisis intervention resources
- **Comprehensive Coverage**: Covers suicide prevention, self-harm, and mental health crises
- **Immediate Response**: Provides instant access to help resources

### MemoryMonitor

Monitors memory performance and provides metrics for optimization.

#### Key Features
- **Performance Tracking**: Monitors memory usage and performance metrics
- **Trend Analysis**: Tracks memory usage trends over time
- **Snapshot Management**: Takes periodic performance snapshots
- **Export Capabilities**: Exports performance data for analysis

#### Monitoring Metrics

##### MemoryPerformanceSnapshot
```dart
class MemoryPerformanceSnapshot {
  final DateTime timestamp;
  final int totalSegments;
  final int memoryUsage;        // Approximate bytes
  final int consolidationCount;
  final double averageResponseTime; // Milliseconds
  final double cacheHitRate;    // 0.0 to 1.0
}
```

#### API Reference

##### `startMonitoring({Duration interval = Duration(minutes: 5)})`
Starts periodic memory performance monitoring.

```dart
static void startMonitoring({Duration interval = const Duration(minutes: 5)})
```

##### `stopMonitoring()`
Stops memory performance monitoring.

```dart
static void stopMonitoring()
```

##### `getPerformanceHistory()`
Returns list of all performance snapshots.

```dart
static List<MemoryPerformanceSnapshot> getPerformanceHistory()
```

##### `getCurrentMetrics()`
Returns the most recent performance metrics.

```dart
static MemoryPerformanceSnapshot? getCurrentMetrics()
```

##### `getUsageTrend()`
Returns current memory usage trend.

```dart
static MemoryUsageTrend getUsageTrend()
```

##### `exportPerformanceData()`
Exports all performance data as JSON.

```dart
static Map<String, dynamic> exportPerformanceData()
```

#### Usage Trends

- **Increasing**: Memory usage growing significantly
- **Decreasing**: Memory usage reducing significantly
- **Stable**: Memory usage relatively constant

#### Performance Metrics

- **Memory Usage**: Approximate memory consumption in bytes
- **Response Time**: Average API response time in milliseconds
- **Cache Hit Rate**: Effectiveness of memory caching (0.0-1.0)
- **Consolidation Count**: Number of memory consolidation operations

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