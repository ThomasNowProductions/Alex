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

### MemoryConfig

Configuration settings for the memory management system, including thresholds, limits, and performance tuning options.

#### Properties

```dart
class MemoryConfig {
  final int maxShortTermMessages;           // Maximum short-term messages to keep
  final int maxMediumTermSegments;          // Maximum medium-term segments
  final int maxLongTermSegments;            // Maximum long-term segments
  final double criticalImportanceThreshold; // Threshold for critical memories
  final double longTermImportanceThreshold; // Threshold for long-term memories
  final double mediumTermImportanceThreshold; // Threshold for medium-term memories
  final Duration shortTermExpiry;           // When short-term memories expire
  final Duration mediumTermExpiry;          // When medium-term memories expire
  final Duration longTermExpiry;            // When long-term memories expire
  final Duration consolidationInterval;     // How often to consolidate memories
  final int maxSummarizationLength;         // Maximum length for summaries
  final bool enableAutoConsolidation;       // Whether to auto-consolidate
  final bool enableMemoryCompression;       // Whether to compress old memories
  final double minMessageImportance;        // Minimum importance for storage
  final int minMessageLength;               // Minimum length for storage
  final List<String> priorityKeywords;      // Keywords that boost importance
}
```

#### Preset Configurations

##### Standard Configuration
```dart
static const MemoryConfig standard = MemoryConfig(); // Default balanced settings
```

##### Minimal Configuration
```dart
static const MemoryConfig minimal = MemoryConfig(
  maxShortTermMessages: 50,
  maxMediumTermSegments: 20,
  maxLongTermSegments: 10,
  enableAutoConsolidation: false,
  enableMemoryCompression: false,
);
```

##### Comprehensive Configuration
```dart
static const MemoryConfig comprehensive = MemoryConfig(
  maxShortTermMessages: 200,
  maxMediumTermSegments: 100,
  maxLongTermSegments: 50,
  consolidationInterval: Duration(hours: 3),
  enableAutoConsolidation: true,
  enableMemoryCompression: true,
);
```

##### Token-Efficient Configuration
```dart
static const MemoryConfig tokenEfficient = MemoryConfig(
  // Optimized for minimal API token usage
  maxShortTermMessages: 30,
  maxMediumTermSegments: 15,
  maxLongTermSegments: 8,
  minMessageImportance: 0.3,
  minMessageLength: 10,
  enableAutoConsolidation: false,
  consolidationInterval: Duration(hours: 24),
);
```

#### JSON Serialization

```dart
// To JSON
Map<String, dynamic> toJson() => {
  'maxShortTermMessages': maxShortTermMessages,
  'maxMediumTermSegments': maxMediumTermSegments,
  'criticalImportanceThreshold': criticalImportanceThreshold,
  // ... other properties
};

// From JSON
factory MemoryConfig.fromJson(Map<String, dynamic> json) => MemoryConfig(
  maxShortTermMessages: json['maxShortTermMessages'] ?? 100,
  // ... other properties with defaults
);
```

### MemorySegment

Represents a hierarchical memory segment with importance scoring, metadata, and lifecycle management.

#### Properties

```dart
class MemorySegment {
  final String id;                    // Unique identifier
  final String content;               // Memory content/summary
  final MemoryType type;              // Memory hierarchy level
  final double importance;            // Importance score (0.0-1.0)
  final DateTime created;             // Creation timestamp
  final DateTime lastAccessed;        // Last access timestamp
  final int accessCount;              // Number of times accessed
  final List<String> topics;          // Associated topics/tags
  final Map<String, dynamic> metadata; // Additional metadata
}
```

#### Memory Types

```dart
enum MemoryType {
  shortTerm,    // Recent conversations, expires in 24 hours
  mediumTerm,   // Important topics, expires in 7 days
  longTerm,     // Core preferences and facts, expires in 30 days
  critical,     // Essential information, never expires
}
```

#### Key Methods

##### `isExpired` (getter)
Checks if the memory segment has expired based on its type.

```dart
bool get isExpired {
  final age = DateTime.now().difference(created);
  switch (type) {
    case MemoryType.shortTerm: return age > Duration(hours: 24);
    case MemoryType.mediumTerm: return age > Duration(days: 7);
    case MemoryType.longTerm: return age > Duration(days: 30);
    case MemoryType.critical: return false; // Never expires
  }
}
```

##### `relevanceScore` (getter)
Calculates current relevance based on importance, access patterns, and age.

```dart
double get relevanceScore {
  // Decay based on time since last access
  double decayFactor = 1.0 / (1.0 + ageDays * 0.1);
  // Boost based on access count
  double accessBoost = 1.0 + (accessCount * 0.1);
  return importance * decayFactor * accessBoost;
}
```

##### `copyWith(Map<String, dynamic> updates)`
Creates a copy with updated properties.

```dart
MemorySegment copyWith({
  DateTime? lastAccessed,
  int? accessCount,
  // ... other properties
});
```

#### JSON Serialization

```dart
// To JSON
Map<String, dynamic> toJson() => {
  'id': id,
  'content': content,
  'type': type.toString(),
  'importance': importance,
  'created': created.toIso8601String(),
  'lastAccessed': lastAccessed.toIso8601String(),
  'accessCount': accessCount,
  'topics': topics,
  'metadata': metadata,
};

// From JSON
factory MemorySegment.fromJson(Map<String, dynamic> json) => MemorySegment(
  id: json['id'],
  content: json['content'],
  type: MemoryType.values.firstWhere(
    (e) => e.toString() == json['type'],
    orElse: () => MemoryType.shortTerm,
  ),
  // ... other properties
);
```

#### Usage Example

```dart
// Create a memory segment
MemorySegment segment = MemorySegment(
  id: 'unique-id',
  content: 'User discussed their interest in machine learning',
  type: MemoryType.longTerm,
  importance: 0.8,
  created: DateTime.now(),
  lastAccessed: DateTime.now(),
  accessCount: 1,
  topics: ['technology', 'interests', 'career'],
  metadata: {
    'messageCount': 3,
    'containsUserMessages': true,
  },
);
```

### MemoryMetrics

Tracks memory system performance and usage statistics.

#### Properties

```dart
class MemoryMetrics {
  final int totalSegments;           // Total number of memory segments
  final int shortTermCount;          // Number of short-term segments
  final int mediumTermCount;         // Number of medium-term segments
  final int longTermCount;           // Number of long-term segments
  final int criticalCount;           // Number of critical segments
  final double averageImportance;    // Average importance across all segments
  final DateTime lastConsolidation;  // Last consolidation timestamp
  final int totalAccessCount;        // Total access count across all segments
}
```

#### JSON Serialization

```dart
// To JSON
Map<String, dynamic> toJson() => {
  'totalSegments': totalSegments,
  'shortTermCount': shortTermCount,
  'averageImportance': averageImportance,
  // ... other properties
};

// From JSON
factory MemoryMetrics.fromJson(Map<String, dynamic> json) => MemoryMetrics(
  totalSegments: json['totalSegments'] ?? 0,
  // ... other properties
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