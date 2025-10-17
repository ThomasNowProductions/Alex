# Architecture Documentation

## Overview

Alex AI Companion follows a modern, layered architecture that separates concerns and promotes maintainability, testability, and scalability.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter UI Layer                         │
├─────────────────────────────────────────────────────────────┤
│  Components    │  Widgets    │  Screens    │  Constants    │
├─────────────────────────────────────────────────────────────┤
│                 Service Layer                               │
├─────────────────────────────────────────────────────────────┤
│  Conversation  │  Ollama     │  Summarization  │  Memory   │
│  Management    │  Service    │  Service        │  Manager  │
├─────────────────────────────────────────────────────────────┤
│  Settings      │  Safety     │  Memory         │  Utils    │
│  Service       │  Service    │  Monitor        │           │
├─────────────────────────────────────────────────────────────┤
│                 Data Layer                                  │
├─────────────────────────────────────────────────────────────┤
│   Models       │  Local Storage    │  API Integration      │
│  Memory        │  Settings         │  Security             │
│  Segments      │  Files            │  Features             │
└─────────────────────────────────────────────────────────────┘
```

## Layer Descriptions

### 1. UI Layer (Presentation)

**Components** (`lib/components/`)
- Main application screens and user interface logic
- State management for UI components
- Event handling and user interactions

**Widgets** (`lib/widgets/`)
- Reusable UI components
- Custom widgets for specific functionality
- UI building blocks

**Screens** (`lib/screens/`)
- Top-level application screens
- Navigation and routing logic

**Constants** (`lib/constants/`)
- Application-wide constants and configuration
- Theme definitions and styling constants

### 2. Service Layer (Business Logic)

**Core Services** (`lib/services/`)
- `ConversationService`: Manages conversation history and persistence
- `OllamaService`: Handles AI API communication
- `SummarizationService`: Provides conversation summarization
- `MemoryManager`: Advanced memory management with importance scoring
- `SettingsService`: User preferences and configuration management
- `SafetyService`: Content filtering and safety monitoring

**Monitoring Services** (`lib/services/`)
- `MemoryMonitor`: Performance monitoring and metrics collection

**Utility Services** (`lib/utils/`)
- `Logger`: Comprehensive logging system for debugging and monitoring
- `SpeechUtils`: Speech recognition functionality
- `PermissionUtils`: Platform-specific permission handling
- `PlatformUtils`: Cross-platform compatibility utilities

### 3. Data Layer (Data Management)

**Models** (`lib/models/`)
- `ConversationContext`: Complete conversation state
- `ConversationMessage`: Individual message representation
- `MemoryConfig`: Configuration for memory management system
- `MemorySegment`: Hierarchical memory storage with importance levels

**Storage**
- Local file storage using `path_provider`
- JSON serialization for data persistence
- Application documents directory for data storage
- Settings storage in `user_settings.json`
- Secure PIN hash storage with SHA-256 encryption

## Component Relationships

### Chat Screen Flow

```
User Input/Speech
       ↓
┌─────────────────────────────────┐
│      ChatScreen Component       │
│  - Manages UI state             │
│  - Handles user input           │
│  - Coordinates with services    │
└─────────────────────────────────┘
       ↓
┌─────────────────────────────────┐
│      ConversationService        │
│  - Stores messages              │
│  - Manages context              │
│  - Persists to local storage   │
└─────────────────────────────────┘
       ↓
┌─────────────────────────────────┐
│       OllamaService             │
│  - Calls AI API                 │
│  - Includes conversation context│
│  - Returns AI responses         │
└─────────────────────────────────┘
```

### Data Flow

1. **User Input** → ChatScreen receives text/speech input
2. **Message Storage** → ConversationService stores message locally
3. **Context Building** → OllamaService builds context from recent messages
4. **AI Processing** → Ollama Cloud API processes request with context
5. **Response Storage** → AI response stored via ConversationService
6. **UI Update** → ChatScreen displays new messages

## Design Patterns

### 1. Service Layer Pattern

Separates business logic from UI concerns:

```dart
// UI Layer - Only handles presentation
class ChatScreen extends StatefulWidget {
  // UI-specific logic only
}

// Service Layer - Handles business logic
class ConversationService {
  // Business logic for conversation management
}
```

### 2. Repository Pattern (Conceptual)

Data access is centralized through services:

```dart
// Single source of truth for conversation data
class ConversationService {
  static ConversationContext _context;

  static Future<void> loadContext() async { /* Load from storage */ }
  static Future<void> saveContext() async { /* Save to storage */ }
}
```

### 3. Observer Pattern (Events)

UI components react to service state changes:

```dart
// Services notify UI of state changes
setState(() {
  _messages.add(newMessage);
});
```

## Platform Architecture

### Cross-Platform Compatibility

The app supports multiple platforms through Flutter's compilation targets:

- **Android**: Kotlin/Java native code
- **iOS**: Swift/Objective-C native code
- **Web**: JavaScript/HTML compilation
- **Desktop**: Linux (GTK), macOS (Cocoa), Windows (Win32)

### Platform-Specific Implementations

#### Speech Recognition
- **Mobile**: Uses `speech_to_text` plugin with platform APIs
- **Web**: Web Speech API (when available)
- **Desktop**: Limited support with platform notifications

#### File Storage
- **Mobile/Desktop**: Application documents directory
- **Web**: Local storage or IndexedDB

## Security Architecture

### Data Protection

1. **Local Storage Security**
   - Conversation data stored locally only
   - No transmission of personal data
   - JSON serialization for structured data
   - Secure settings storage in encrypted format

2. **API Security**
   - Bearer token authentication
   - Environment variable storage for API keys
   - HTTPS-only communication
   - Support for both inbuilt and custom API keys

3. **PIN Lock Security**
   - SHA-256 PIN hashing for secure storage
   - Optional PIN protection for app access
   - Configurable PIN lock settings
   - Secure PIN verification system

4. **Permission Handling**
   - Microphone permission requests
   - Platform-specific permission management
   - Graceful degradation when permissions denied

### Safety and Content Filtering

1. **Content Safety**
   - Sensitive keyword detection and filtering
   - Crisis intervention resource integration
   - Safe response generation for sensitive content
   - Configurable safety thresholds and responses

2. **Resource Management**
   - Help resource loading from JSON assets
   - Fallback resources for offline scenarios
   - Category-based resource organization

## Performance Architecture

### Memory Management

1. **Conversation Context**
   - Automatic truncation of old messages
   - Summarization for long conversations
   - Configurable message limits

2. **Advanced Memory System**
   - Hierarchical memory organization (short-term, medium-term, long-term, critical)
   - Importance-based message scoring and filtering
   - Automatic memory consolidation and cleanup
   - Memory compression for storage efficiency
   - Performance monitoring and metrics collection

3. **UI Performance**
   - Efficient list rendering for messages
   - Async operations for smooth UX
   - Proper widget disposal

### Optimization Strategies

1. **Lazy Loading**
   - Conversation history loaded on demand
   - Pagination for large conversation sets

2. **Intelligent Caching**
   - Memory segment caching based on importance
   - API response caching (future enhancement)
   - Local storage for offline functionality

3. **Background Processing**
   - Conversation summarization in background
   - Non-blocking save operations
   - Automatic memory consolidation scheduling

4. **Token Efficiency**
   - Configurable memory management for reduced API usage
   - Importance filtering to minimize token consumption
   - Smart context selection for API requests

## Scalability Considerations

### Current Limitations

1. **Single User**
   - Designed for single-user conversations
   - Local storage per device

2. **API Dependency**
   - Requires internet connection for AI features
   - Dependent on Ollama Cloud API availability

### Future Enhancements

1. **Multi-User Support**
   - User profile management
   - Separate conversation contexts

2. **Offline Mode**
   - Local AI model integration
   - Cached response system

3. **Cloud Sync**
   - Cross-device conversation sync
   - Cloud backup and restore

## Development Architecture

### Code Organization

```
lib/
├── components/     # Feature-based UI components
├── constants/      # Application configuration
├── models/         # Data structures
├── services/       # Business logic layer
├── utils/          # Utility functions
└── widgets/        # Reusable UI components
```

### Dependency Management

- **Flutter SDK**: Core framework
- **Dart Packages**: Third-party dependencies via pubspec.yaml
- **Environment Variables**: Configuration management
- **Asset Management**: Images, fonts, and configuration files

## Testing Architecture

### Test Organization

```
test/
├── widget_test.dart      # UI component tests
├── service/              # Service layer tests
├── model/                # Data model tests
└── integration/          # End-to-end tests
```

### Testing Strategies

1. **Unit Tests**: Individual function and class testing
2. **Widget Tests**: UI component behavior testing
3. **Integration Tests**: Full workflow testing
4. **Mock Testing**: API and external dependency mocking

## Deployment Architecture

### Build Targets

- **APK**: Android Package for mobile distribution
- **AAB**: Android App Bundle for Google Play
- **IPA**: iOS App for App Store distribution
- **Web**: Static web application
- **Desktop**: Native desktop applications

### CI/CD Pipeline (Future)

1. **Code Quality**: Linting and formatting checks
2. **Testing**: Automated test execution
3. **Building**: Multi-platform builds
4. **Distribution**: App store and web deployment

## Architecture Benefits

### Maintainability
- Clear separation of concerns
- Modular component design
- Comprehensive documentation

### Testability
- Isolated service layer testing
- Mockable external dependencies
- Comprehensive test coverage

### Scalability
- Service-based architecture
- Platform abstraction layer
- Extensible design patterns

### Reliability
- Error handling at all layers
- Graceful degradation strategies
- Comprehensive logging and debugging

## Architecture Decisions

### Key Decisions

1. **Service Layer**: Separates business logic from UI
2. **Local Storage**: Privacy-focused data management
3. **Cross-Platform**: Maximum device compatibility
4. **API Integration**: Cloud-based AI capabilities
5. **Real-time Updates**: Live conversation experience

### Trade-offs

1. **Complexity vs. Simplicity**: Feature-rich vs. minimal viable product
2. **Online vs. Offline**: API dependency vs. self-contained
3. **Local vs. Cloud**: Privacy vs. synchronization features
4. **Generic vs. Specific**: Flexibility vs. optimized performance

This architecture provides a solid foundation for the AI companion application while allowing for future enhancements and scalability.