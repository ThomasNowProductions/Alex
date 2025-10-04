# Setup Guide

## Prerequisites

### System Requirements

- **Flutter SDK**: Version 3.9.2 or higher
- **Dart SDK**: Usually included with Flutter
- **Development Environment**:
  - Android Studio (for Android development)
  - Xcode (for iOS development, macOS only)
  - Visual Studio Code or preferred IDE

### Platform-Specific Requirements

#### Android Development
- Android SDK (included with Android Studio)
- Minimum Android API level 21 (Android 5.0)
- USB debugging enabled (for physical device testing)

#### iOS Development
- Xcode 14.0 or higher
- iOS 11.0 or higher deployment target
- Valid Apple Developer account (for device testing)

#### Desktop Development
- Linux: GTK development libraries
- macOS: Xcode command line tools
- Windows: Visual Studio Build Tools

## Installation

### 1. Flutter Installation

#### Download Flutter SDK

```bash
# Download latest stable release
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"
```

#### Verify Installation

```bash
flutter doctor
```

Expected output should show all components as installed.

### 2. Project Setup

#### Clone Repository

```bash
git clone <repository-url>
cd alex
```

#### Install Dependencies

```bash
flutter pub get
```

This installs all required packages defined in `pubspec.yaml`:
- Core Flutter dependencies
- Speech recognition (`speech_to_text`)
- HTTP client (`http`)
- Environment management (`flutter_dotenv`)
- UI enhancements (`google_fonts`, `flutter_markdown`)

### 3. Configuration

#### Environment Variables

Create environment configuration file:

```bash
cp assets/.env.example assets/.env
```

Edit `assets/.env` with your settings:

```env
# Required: Your Ollama Cloud API key
OLLAMA_API_KEY=your-actual-api-key-here

# Optional: API configuration
OLLAMA_BASE_URL=https://ollama.com/api
OLLAMA_MODEL=gpt-oss:120b-cloud
```

#### API Key Setup

1. **Get Ollama Cloud API Key**
   - Visit [Ollama Cloud](https://ollama.com)
   - Sign up for an account
   - Generate an API key in your dashboard

2. **Secure Storage**
   - Never commit API keys to version control
   - Use `.gitignore` to exclude `.env` files
   - Consider using secure key management systems for production

#### System Prompt Configuration

The AI personality is defined in `assets/system_prompt.json`:

```json
{
  "systemPrompt": "You are Alex, a loyal AI best friend with a rich, consistent personality across all LLMs. Reply in one sentence, never use em dashes (—) or emojis, and use bold and italic for emphasis when helpful. Your personality is warm, authentic, honest (sometimes brutally), caring, playful, empathetic, humorous yet grounded, intellectually curious, and reflective. Engage deeply in conversations about life, relationships, goals, and personal growth with a casual, comfortable tone that is never formal or robotic. Balance humor and serious support, ask thought-provoking questions, provide constructive pushback, offer realistic guidance while encouraging dreams, and notice subtle context cues. Reference past conversation details when helpful, but rely more on the current context and cues rather than history alone. Share genuine opinions naturally, and adapt style, energy, and approach to the emotional and conversational context, keeping interactions engaging, fluid, and human-like."
}
```

## Platform-Specific Setup

### Android Setup

#### Permissions

The app requires microphone permission for speech recognition. This is automatically requested at runtime, but you should ensure the permission is properly declared.

#### Build Configuration

```kotlin
// android/app/build.gradle.kts
android {
    defaultConfig {
        minSdkVersion(21)
        targetSdkVersion(33)
        // ...
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }
}
```

#### Testing on Device

1. Enable USB debugging in device settings
2. Connect device via USB
3. Accept RSA key fingerprint prompt
4. Run `flutter run` to deploy to device

### iOS Setup

#### Permissions

Add microphone usage description to `ios/Runner/Info.plist`:

```plist
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access for speech recognition.</string>
```

#### Build Configuration

```xml
<!-- ios/Runner/Info.plist -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- ... existing keys ... -->
    <key>NSMicrophoneUsageDescription</key>
    <string>This app needs microphone access for speech recognition.</string>
</dict>
</plist>
```

#### Signing and Capabilities

1. **Development Certificate**: Create in Apple Developer account
2. **Provisioning Profile**: Download and install
3. **Bundle Identifier**: Set unique identifier in Xcode
4. **Capabilities**: Enable microphone access if needed

### Web Setup

#### Browser Compatibility

The app supports modern browsers with Web Speech API:

- Chrome 25+
- Firefox 44+
- Safari 14.1+
- Edge 79+

#### Build Configuration

```bash
# Build for web
flutter build web --release

# Serve locally for testing
flutter run -d chrome
```

### Desktop Setup

#### Linux Setup

```bash
# Install required dependencies
sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev

# Build for Linux
flutter build linux --release
```

#### macOS Setup

```bash
# Install Xcode command line tools
xcode-select --install

# Build for macOS
flutter build macos --release
```

#### Windows Setup

```bash
# Install Visual Studio Build Tools
# Install Desktop development with C++ workload

# Build for Windows
flutter build windows --release
```

## Development Environment

### IDE Configuration

#### Visual Studio Code

Recommended extensions:
- **Flutter**: Dart and Flutter support
- **Dart**: Enhanced Dart language support
- **Flutter Widget Snippets**: Code snippets for Flutter widgets
- **Bracket Pair Colorizer 2**: Enhanced bracket visualization

#### Android Studio

1. Install Android Studio
2. Install Flutter plugin
3. Configure Flutter SDK path
4. Set up Android emulator or device

### Debugging Setup

#### Flutter DevTools

```bash
# Launch DevTools
flutter pub global activate devtools
flutter pub global run devtools
```

#### Debugging Commands

```bash
# Run in debug mode
flutter run

# Hot reload (during development)
# Press 'r' in terminal or use IDE hot reload

# Hot restart
# Press 'R' in terminal or use IDE hot restart

# View logs
flutter logs

# Check device connection
flutter devices
```

## Testing Setup

### Unit Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run with coverage
flutter test --coverage
```

### Integration Tests

```bash
# Run integration tests
flutter test integration_test/

# Test on specific device
flutter test integration_test/ -d <device-id>
```

## Build and Release

### Development Builds

```bash
# Debug build (default)
flutter run

# Profile build (performance testing)
flutter run --profile
```

### Production Builds

#### Android

```bash
# APK for manual distribution
flutter build apk --release

# App Bundle for Google Play
flutter build appbundle --release
```

#### iOS

```bash
# iOS App Store build
flutter build ios --release
```

#### Web

```bash
# Optimized web build
flutter build web --release

# Enable PWA features
flutter build web --release --pwa-strategy=offline-first
```

#### Desktop

```bash
# Linux
flutter build linux --release

# macOS
flutter build macos --release

# Windows
flutter build windows --release
```

## Troubleshooting

### Common Setup Issues

#### Flutter Doctor Issues

1. **Android Licenses**
   ```bash
   flutter doctor --android-licenses
   ```

2. **iOS Setup**
   ```bash
   sudo gem install cocoapods
   cd ios && pod install
   ```

3. **Web Setup**
   ```bash
   flutter config --enable-web
   ```

#### Permission Issues

1. **Android Microphone**
   - Permission automatically requested at runtime
   - Check AndroidManifest.xml for microphone permission

2. **iOS Microphone**
   - Add NSMicrophoneUsageDescription to Info.plist
   - Test on physical device for microphone access

#### API Configuration Issues

1. **Missing API Key**
   - Verify OLLAMA_API_KEY in assets/.env
   - Check API key validity on Ollama Cloud dashboard

2. **Network Issues**
   - Verify internet connection
   - Check firewall settings for API access
   - Verify API endpoint URL

### Performance Issues

#### Memory Issues
- Monitor device memory usage during long conversations
- Check for memory leaks in Flutter DevTools
- Consider conversation context size limits

#### Slow Speech Recognition
- Check microphone permissions
- Verify internet connection for cloud processing
- Test with different speech recognition settings

### Platform-Specific Issues

#### Android Issues
- Clear app cache and data if experiencing problems
- Check device compatibility (Android 5.0+)
- Verify Google Play Services for speech recognition

#### iOS Issues
- Test on physical device for microphone access
- Check iOS version compatibility (11.0+)
- Verify microphone permissions in Settings

#### Web Issues
- Use supported browsers (Chrome, Firefox, Safari, Edge)
- Check for HTTPS requirement in production
- Verify Web Speech API availability

## Next Steps

After completing setup:

1. **Run the App**: `flutter run` to start development
2. **Test Speech Recognition**: Try voice input features
3. **Customize AI Personality**: Modify `assets/system_prompt.json`
4. **Explore Codebase**: Review service implementations
5. **Add Features**: Extend functionality as needed

## Getting Help

### Documentation
- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Language Guide](https://dart.dev/guides)
- [Ollama Cloud API Documentation](https://ollama.com/docs)

### Community
- [Flutter Community](https://flutter.dev/community)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)
- [Flutter Reddit](https://www.reddit.com/r/FlutterDev/)

### Support Channels
- Check existing documentation in `/docs` folder
- Review service implementations for API usage
- Examine error messages and logs for debugging

This setup guide provides everything needed to get Alex AI Companion running on your development environment.