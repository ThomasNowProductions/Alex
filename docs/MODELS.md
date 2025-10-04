# Models and Data Structures

## Overview

This document describes the data models and structures used throughout Alex AI Companion, including conversation management, message handling, and context persistence.

## Core Models

### ConversationMessage

Represents a single message in a conversation between the user and Alex.

#### Properties

```dart
class ConversationMessage {
  final String text;        // The message content
  final bool isUser;        // true if from user, false if from Alex
  final DateTime timestamp; // When the message was created
}
```

#### JSON Serialization

```dart
// To JSON
Map<String, dynamic> toJson() => {
  'text': text,
  'isUser': isUser,
  'timestamp': timestamp.toIso8601String(),
};

// From JSON
factory ConversationMessage.fromJson(Map<String, dynamic> json) => ConversationMessage(
  text: json['text'],
  isUser: json['isUser'],
  timestamp: DateTime.parse(json['timestamp']),
);
```

#### Usage Example

```dart
// Create a user message
ConversationMessage userMessage = ConversationMessage(
  text: "Hello, Alex!",
  isUser: true,
  timestamp: DateTime.now(),
);

// Create an AI response
ConversationMessage aiResponse = ConversationMessage(
  text: "Hi there! How are you doing today?",
  isUser: false,
  timestamp: DateTime.now(),
);
```

### ConversationContext

Contains the complete state of a conversation, including all messages, summary, and metadata.

#### Properties

```dart
class ConversationContext {
  final List<ConversationMessage> messages;  // All messages in conversation
  final String summary;                       // AI-generated conversation summary
  final DateTime lastUpdated;                 // Last modification timestamp
}
```

#### JSON Serialization

```dart
// To JSON
Map<String, dynamic> toJson() => {
  'messages': messages.map((m) => m.toJson()).toList(),
  'summary': summary,
  'lastUpdated': lastUpdated.toIso8601String(),
};

// From JSON
factory ConversationContext.fromJson(Map<String, dynamic> json) => ConversationContext(
  messages: (json['messages'] as List<dynamic>?)
      ?.map((m) => ConversationMessage.fromJson(m as Map<String, dynamic>))
      .toList() ?? [],
  summary: json['summary'] ?? '',
  lastUpdated: DateTime.parse(json['lastUpdated']),
);
```

#### Usage Example

```dart
// Create conversation context
ConversationContext context = ConversationContext(
  messages: [userMessage, aiResponse],
  summary: "User greeted Alex and discussed their day.",
  lastUpdated: DateTime.now(),
);
```

## Data Flow

### Message Lifecycle

```
User Input/Speech
       ↓
┌─────────────────────────────────┐
│   ConversationMessage Created   │
│   - text: User's message        │
│   - isUser: true                │
│   - timestamp: current time     │
└─────────────────────────────────┘
       ↓
┌─────────────────────────────────┐
│   Added to ConversationContext  │
│   - Appended to messages list   │
│   - Context updated             │
└─────────────────────────────────┘
       ↓
┌─────────────────────────────────┐
│   Persisted to Local Storage    │
│   - Serialized to JSON          │
│   - Saved to file system        │
└─────────────────────────────────┘
```

### Context Management

#### Message Storage
- **In-Memory**: Active conversation context in `ConversationService`
- **Persistent**: JSON file in application documents directory
- **Synchronization**: Automatic save/load operations

#### Memory Optimization
- **Context Window**: Last 50 messages kept in active memory
- **Summarization**: Long conversations automatically summarized
- **Cleanup**: Old messages archived in summaries

## Storage Format

### File Structure

```
Application Documents Directory/
└── conversation_context.json
```

### JSON Schema

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "messages": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "text": { "type": "string" },
          "isUser": { "type": "boolean" },
          "timestamp": { "type": "string", "format": "date-time" }
        },
        "required": ["text", "isUser", "timestamp"]
      }
    },
    "summary": { "type": "string" },
    "lastUpdated": { "type": "string", "format": "date-time" }
  },
  "required": ["messages", "summary", "lastUpdated"]
}
```

### Example Data

```json
{
  "messages": [
    {
      "text": "Hey Alex, how was your day?",
      "isUser": true,
      "timestamp": "2024-01-15T10:30:00.000Z"
    },
    {
      "text": "My day was great! I had some interesting conversations and learned a few new things. How about yours?",
      "isUser": false,
      "timestamp": "2024-01-15T10:30:05.000Z"
    },
    {
      "text": "Mine was pretty good too. I went for a walk and read an interesting book.",
      "isUser": true,
      "timestamp": "2024-01-15T10:30:15.000Z"
    }
  ],
  "summary": "User and Alex discussed their respective days. User went for a walk and read a book, while Alex had interesting conversations and learned new things.",
  "lastUpdated": "2024-01-15T10:30:15.000Z"
}
```

## Utility Classes

### SpeechUtils

Handles speech recognition functionality across platforms.

#### Key Methods

##### `initializeSpeech({Function onError, Function onStatus})`

Initializes the speech recognition system.

```dart
static Future<bool> initializeSpeech({
  required Function(dynamic) onError,
  required Function(String) onStatus,
}) async
```

**Parameters**:
- `onError`: Callback for speech recognition errors
- `onStatus`: Callback for status changes

**Returns**: `true` if initialization successful, `false` otherwise

##### `startListening({SpeechToText speech, Function onResult})`

Begins listening for speech input.

```dart
static Future<bool> startListening({
  required stt.SpeechToText speech,
  required Function(dynamic) onResult,
}) async
```

**Parameters**:
- `speech`: SpeechToText instance
- `onResult`: Callback for speech recognition results

**Returns**: `true` if listening started successfully

##### `stopListening(SpeechToText speech)`

Stops the current speech recognition session.

```dart
static Future<void> stopListening(stt.SpeechToText speech) async
```

##### `handleSpeechError(BuildContext context, dynamic error)`

Processes and displays speech recognition errors.

```dart
static void handleSpeechError(BuildContext context, dynamic error)
```

**Error Types**:
- No speech input detected
- Recognizer not available
- Permission denied
- Network errors
- Timeout errors

### PermissionUtils

Manages platform-specific permissions.

#### Key Methods

##### `requestMicrophonePermission(BuildContext context)`

Requests microphone permission on Android devices.

```dart
static Future<bool> requestMicrophonePermission(BuildContext context) async
```

**Returns**: `true` if permission granted, `false` otherwise

### PlatformUtils

Provides cross-platform compatibility utilities.

#### Key Properties

```dart
static bool get isAndroid => Platform.isAndroid;
static bool get isIOS => Platform.isIOS;
static bool get isWeb => kIsWeb;
static bool get isDesktop => Platform.isLinux || Platform.isMacOS || Platform.isWindows;
```

#### Key Methods

##### `getSpeechRecognitionMessage()`

Returns platform-specific speech recognition availability message.

```dart
static String getSpeechRecognitionMessage()
```

## Constants and Configuration

### AppConstants

Centralized application configuration and constants.

#### Speech Recognition Settings

```dart
// Timing configuration
static const Duration speechListenDuration = Duration(seconds: 30);
static const Duration speechPauseDuration = Duration(seconds: 5);

// Thresholds
static const int summarizationThreshold = 10;
static const int summarizationUpdateThreshold = 25;
static const int maxMessagesForContext = 50;
```

#### UI Configuration

```dart
// Layout constants
static const double chatBubbleMaxWidth = 0.8;
static const double glowEffectWidth = 180;
static const EdgeInsets inputPadding = EdgeInsets.all(20);
static const EdgeInsets messageMargin = EdgeInsets.only(bottom: 24);
```

#### File Paths

```dart
static const String conversationContextFile = 'conversation_context.json';
static const String envFileName = 'assets/.env';
```

### AppTheme

Defines light and dark theme configurations.

#### Theme Structure

- **Color Schemes**: Primary, secondary, surface colors
- **Typography**: Font families and text styles
- **Component Themes**: Button, input field, and card styling
- **Animation**: Transition durations and curves

## Data Validation

### Input Validation

#### Message Validation
- **Text Content**: Non-empty string validation
- **Length Limits**: Reasonable message length constraints
- **Content Filtering**: Basic profanity and spam detection

#### Context Validation
- **JSON Structure**: Valid JSON format validation
- **Required Fields**: Ensure all required fields present
- **Data Types**: Type checking for all fields

### Error Recovery

#### Data Corruption Handling
1. **Backup Recovery**: Attempt to recover from backup files
2. **Partial Recovery**: Extract valid data from corrupted files
3. **Fresh Start**: Initialize empty context if recovery fails

#### Network Error Handling
1. **Retry Logic**: Automatic retry for transient failures
2. **Offline Mode**: Graceful degradation when offline
3. **Cache Strategy**: Use cached data when available

## Performance Considerations

### Memory Management

#### Conversation Data
- **Lazy Loading**: Load conversation history on demand
- **Pagination**: Handle large conversation sets efficiently
- **Cleanup**: Automatic removal of old, summarized data

#### Speech Recognition
- **Resource Management**: Proper disposal of speech recognition resources
- **Background Processing**: Non-blocking speech processing
- **Timeout Handling**: Prevent resource leaks from long-running operations

### Storage Optimization

#### File Size Management
- **Compression**: Consider JSON compression for large files
- **Incremental Saves**: Save only changes when possible
- **Cleanup Schedules**: Regular cleanup of old data

#### Access Patterns
- **Read Optimization**: Efficient loading of recent messages
- **Write Optimization**: Batch write operations when possible
- **Cache Strategy**: Keep frequently accessed data in memory

## Security Considerations

### Data Protection

#### Local Storage Security
- **Encryption**: Consider encryption for sensitive data
- **Access Control**: Platform-specific file access permissions
- **Data Sanitization**: Remove sensitive data when requested

#### API Communication
- **Secure Transport**: HTTPS-only communication
- **Authentication**: Secure API key management
- **Data Minimization**: Send only necessary data to APIs

### Privacy Protection

#### Data Collection
- **Minimal Collection**: Only necessary conversation data stored
- **Local Processing**: All data processing happens locally
- **User Control**: Easy data deletion and export options

#### Compliance
- **GDPR Considerations**: Data protection compliance
- **Children's Privacy**: Age-appropriate data handling
- **Data Portability**: Export conversation history

## Testing Data Structures

### Mock Data

#### Sample Conversation

```dart
List<ConversationMessage> sampleMessages = [
  ConversationMessage(
    text: "Hello Alex!",
    isUser: true,
    timestamp: DateTime.parse("2024-01-15T10:00:00Z"),
  ),
  ConversationMessage(
    text: "Hi! Great to hear from you. How are you doing?",
    isUser: false,
    timestamp: DateTime.parse("2024-01-15T10:00:05Z"),
  ),
];
```

#### Test Context

```dart
ConversationContext testContext = ConversationContext(
  messages: sampleMessages,
  summary: "User initiated conversation with greeting.",
  lastUpdated: DateTime.now(),
);
```

## Future Enhancements

### Potential Model Extensions

1. **User Profiles**
   ```dart
   class UserProfile {
     final String name;
     final String avatar;
     final Map<String, dynamic> preferences;
   }
   ```

2. **Conversation Categories**
   ```dart
   class ConversationCategory {
     final String name;
     final String description;
     final List<String> keywords;
   }
   ```

3. **Message Metadata**
   ```dart
   class MessageMetadata {
     final String language;
     final double confidence;
     final Map<String, dynamic> entities;
   }
   ```

### Data Migration

#### Version Management
- **Schema Versioning**: Track data structure versions
- **Migration Scripts**: Automated data structure updates
- **Backward Compatibility**: Support for older data formats

This comprehensive model documentation provides a complete understanding of the data structures and their usage throughout the Alex AI Companion application.