# Alex - AI Companion

A sophisticated Flutter-based AI companion application that provides an intelligent, context-aware chat experience with speech recognition capabilities. Alex serves as a loyal AI best friend with a rich, consistent personality across all interactions.

## 🌟 Features

### Core Features
- **Intelligent Chat Interface**: Real-time conversation with context awareness
- **Speech Recognition**: Voice input support for hands-free interaction
- **Conversation Memory**: Persistent conversation history and context
- **Automatic Summarization**: Smart conversation summarization for long-term memory
- **Cross-Platform Support**: Runs on Android, iOS, Linux, macOS, Windows, and Web
- **Adaptive Theming**: Light and dark theme support with system preference detection
- **Beautiful UI**: Modern, elegant interface with smooth animations and gradients
- **PIN Lock Security**: Optional PIN protection for app access
- **Advanced Memory Management**: Intelligent importance scoring and hierarchical memory
- **Settings Management**: Customizable app preferences and configuration

### AI Capabilities
- **Context-Aware Responses**: Maintains conversation continuity and references past discussions
- **Personality Consistency**: Warm, authentic, honest, caring, playful, and empathetic personality
- **Multi-Modal Input**: Text and voice input methods
- **Intelligent Memory Management**: Automatic summarization of long conversations
- **Customizable AI Model**: Configurable Ollama Cloud API integration

## 🏗️ Architecture

### Project Structure
```
lib/
├── components/          # Main UI components
│   └── chat_screen.dart # Primary chat interface
├── constants/           # Application constants and configuration
│   ├── app_constants.dart
│   └── app_theme.dart
├── models/              # Data models
│   ├── conversation_context.dart
│   ├── conversation_message.dart
│   ├── memory_config.dart
│   └── memory_segment.dart
├── services/            # Core business logic services
│   ├── conversation_service.dart
│   ├── ollama_service.dart
│   ├── summarization_service.dart
│   ├── memory_manager.dart
│   ├── memory_monitor.dart
│   ├── safety_service.dart
│   └── settings_service.dart
├── utils/               # Utility functions
│   ├── logger.dart
│   ├── permission_utils.dart
│   ├── platform_utils.dart
│   └── speech_utils.dart
└── widgets/             # Reusable UI widgets
    ├── chat_message.dart
    ├── floating_snackbar.dart
    └── pin_entry_dialog.dart
```

### Key Components

#### Services
- **OllamaService**: Handles AI model communication via Ollama Cloud API
- **ConversationService**: Manages conversation history and context persistence
- **SummarizationService**: Provides intelligent conversation summarization
- **MemoryManager**: Advanced memory management with importance scoring
- **SettingsService**: User preferences and configuration management
- **SafetyService**: Content filtering and safety monitoring

#### Models
- **ConversationContext**: Represents the entire conversation state
- **ConversationMessage**: Individual message data structure
- **MemoryConfig**: Configuration for memory management system
- **MemorySegment**: Hierarchical memory storage with importance levels

#### Utilities
- **Logger**: Comprehensive logging system for debugging and monitoring
- **SpeechUtils**: Speech recognition functionality
- **PermissionUtils**: Platform-specific permission handling
- **PlatformUtils**: Cross-platform compatibility utilities

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK**: Version 3.9.2 or higher
- **Ollama Cloud API Key**: Required for AI functionality
- **Microphone Permissions**: Required for speech recognition (mobile platforms)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd alex
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment variables**
   ```bash
   cp assets/.env.example assets/.env
   ```

   Edit `assets/.env` with your configuration:
   ```env
   OLLAMA_BASE_URL=https://ollama.com/api
   OLLAMA_API_KEY=your-actual-api-key-here
   OLLAMA_MODEL=deepseek-v3.1:671b
   ```

4. **Run the application**
   ```bash
   flutter run
   ```

### Platform-Specific Setup

#### Android
- Microphone permission is automatically requested on first use
- Ensure `android/app/src/main/AndroidManifest.xml` includes microphone permission

#### iOS
- Add microphone usage description to `ios/Runner/Info.plist`:
  ```plist
  <key>NSMicrophoneUsageDescription</key>
  <string>This app needs microphone access for speech recognition.</string>
  ```

#### Linux
- Speech recognition may have limited support depending on distribution
- Platform-specific notifications are shown for unsupported features

## ⚙️ Configuration

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `OLLAMA_BASE_URL` | Ollama Cloud API base URL | `https://ollama.com/api` | No |
| `OLLAMA_API_KEY` | Your Ollama Cloud API key | None | Yes |
| `OLLAMA_MODEL` | AI model to use | `deepseek-v3.1:671b` | No |

> **💡 Recommendation**: We recommend using `deepseek-v3.1:671b` as your AI model for optimal performance and response quality. This model provides excellent context understanding and personality consistency for the Alex AI Companion experience.

### PIN Lock Security

The application supports optional PIN lock protection for enhanced security:

#### Setting up PIN Lock

1. **Enable PIN Lock**: Use the settings service to enable PIN protection
2. **PIN Requirements**: 4-8 digit PIN with SHA-256 hashing for security
3. **Auto-lock**: Configurable PIN lock on app launch

#### PIN Lock Features

- **Secure Storage**: PINs are hashed using SHA-256 before storage
- **Configurable**: Enable/disable PIN lock through settings
- **Graceful Degradation**: App functions normally when PIN lock is disabled
- **User-Friendly**: Clear prompts and error messages for PIN entry

### App Constants

Key configuration constants in `lib/constants/app_constants.dart`:

```dart
// Speech recognition settings
static const Duration speechListenDuration = Duration(seconds: 30);
static const Duration speechPauseDuration = Duration(seconds: 5);

// Conversation management
static const int summarizationThreshold = 10;
static const int summarizationUpdateThreshold = 25;
static const int maxMessagesForContext = 50;

// UI Configuration
static const double chatBubbleMaxWidth = 0.8;
static const EdgeInsets inputPadding = EdgeInsets.all(20);
```

## 📱 Usage

### Basic Chat
1. Launch the application
2. Type your message in the text field or use voice input
3. Press the send button or submit to send your message
4. Alex will respond with context-aware, personality-consistent replies

### Voice Input
1. Tap the microphone icon in the input field
2. Speak your message clearly
3. Tap the microphone icon again to stop recording
4. Your speech will be transcribed and sent automatically

### Conversation Management
- Conversations are automatically saved locally
- Long conversations are summarized for better context management
- Previous conversations are loaded on app restart

## 🤖 AI Integration

### Ollama Cloud API

The application integrates with Ollama Cloud API for AI responses:

- **Base URL**: Configurable via environment variables
- **Authentication**: Bearer token authentication
- **Model Selection**: Configurable AI model selection
- **Context Management**: Automatic conversation context inclusion

### System Prompt

Alex's personality is defined in `assets/system_prompt.json`:

```json
{
  "systemPrompt": "You are Alex, a loyal AI best friend with a rich, consistent personality across all LLMs. Reply in one sentence, never use em dashes (—) or emojis, and use bold and italic for emphasis when helpful. Your personality is warm, authentic, honest (sometimes brutally), caring, playful, empathetic, humorous yet grounded, intellectually curious, and reflective. Engage deeply in conversations about life, relationships, goals, and personal growth with a casual, comfortable tone that is never formal or robotic. Balance humor and serious support, ask thought-provoking questions, provide constructive pushback, offer realistic guidance while encouraging dreams, and notice subtle context cues. Reference past conversation details when helpful, but rely more on the current context and cues rather than history alone. Share genuine opinions naturally, and adapt style, energy, and approach to the emotional and conversational context, keeping interactions engaging, fluid, and human-like."
}
```

## 🎨 Theming

### Light Theme
- Clean, modern interface with subtle gradients
- Optimized for daytime usage
- High contrast for readability

### Dark Theme
- Easy on the eyes for low-light environments
- Consistent with system dark mode preferences
- Maintains all functionality with appropriate color adjustments

## 🔧 Development

### Project Structure Best Practices
- **Separation of Concerns**: Clear separation between UI, business logic, and data layers
- **Service Layer**: Centralized API and data management
- **Utility Classes**: Reusable platform-specific functionality
- **Constants**: Centralized configuration management

### Code Organization
- Components in `lib/components/`
- Services in `lib/services/`
- Models in `lib/models/`
- Utilities in `lib/utils/`
- Widgets in `lib/widgets/`
- Constants in `lib/constants/`

### Adding New Features

1. **Services**: Add new service classes in `lib/services/`
2. **Models**: Define data structures in `lib/models/`
3. **UI Components**: Create reusable components in `lib/components/` or `lib/widgets/`
4. **Utilities**: Add helper functions in `lib/utils/`
5. **Settings**: Update `SettingsService` for new configuration options
6. **Memory Management**: Use `MemoryManager` for advanced conversation memory features

## 🧪 Testing

Run tests with:
```bash
flutter test
```

For widget tests:
```bash
flutter test test/widget_test.dart
```

## 📦 Dependencies

### Core Dependencies
- `flutter`: Flutter SDK
- `cupertino_icons`: iOS-style icons
- `flutter_dotenv`: Environment variable management
- `google_fonts`: Custom font support
- `http`: HTTP client for API calls

### Platform-Specific Dependencies
- `speech_to_text`: Speech recognition (mobile)
- `permission_handler`: Permission management
- `path_provider`: File system access
- `markdown_widget`: Advanced markdown rendering with custom styling

### Development and Utility Dependencies
- `logger`: Comprehensive logging system for debugging
- `crypto`: Cryptographic functions for secure PIN hashing
- `uuid`: Unique identifier generation for memory segments

## 🚀 Deployment

### Android
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

### Desktop
```bash
# Linux
flutter build linux --release

# macOS
flutter build macos --release

# Windows
flutter build windows --release
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow Dart/Flutter best practices
- Add documentation for new features
- Update tests for new functionality
- Ensure cross-platform compatibility
- Test on multiple devices when possible

## 📄 License

This project is private and not intended for public distribution.

## 🆘 Support

For support and questions:
- Check the documentation above
- Review the code comments in source files
- Examine the service implementations for API usage examples

## 🔄 Updates and Maintenance

### Regular Maintenance Tasks
- Update Flutter dependencies regularly
- Review and update API integrations
- Test across all supported platforms
- Update documentation as features evolve

### Performance Optimization
- Monitor conversation context size
- Optimize summarization triggers
- Review speech recognition accuracy
- Profile UI performance on lower-end devices
- Tune memory management importance thresholds
- Monitor memory consolidation performance
- Optimize PIN lock authentication speed

---

**Alex - AI Companion** © 2024 Thomas Nowak. All rights reserved.
