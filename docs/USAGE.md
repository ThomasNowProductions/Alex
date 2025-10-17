# Usage Guide

## Overview

Alex AI Companion is designed for natural, conversational interaction with an AI companion that maintains context and personality across sessions.

## Getting Started

### First Launch

1. **Application Startup**
   - Launch the app from your device
   - Grant microphone permissions when prompted (mobile)
   - Wait for initialization of services

2. **PIN Lock Check** (if enabled)
   - If PIN lock is enabled, you'll be prompted to enter your 4-digit PIN
   - Enter your PIN using the on-screen numeric keypad or hardware keyboard
   - PIN is verified against secure hash storage
   - Incorrect PIN attempts show clear error messages

3. **Initial Setup**
   - Environment variables are loaded automatically
   - Conversation context is loaded from local storage
   - Speech recognition is initialized (if supported)
   - Settings and preferences are loaded from local storage

4. **Welcome Screen**
   - You'll see a centered welcome message: "Hey, whatsup?"
   - The interface shows a chat area with input field at bottom
   - Microphone button available if speech recognition is supported

## Security Features

### PIN Lock Protection

#### Setting Up PIN Lock

1. **Enable PIN Protection**
   - Access app settings to enable PIN lock
   - Choose a 4-digit PIN that's easy to remember but hard to guess
   - PIN is securely hashed and stored using SHA-256 encryption

2. **PIN Entry Interface**
   - **Visual Feedback**: 4 circular dots show PIN entry progress
   - **Numeric Keypad**: Large, touch-friendly buttons for PIN entry
   - **Keyboard Support**: Hardware keyboard input support
   - **Auto-Submit**: Automatically verifies when 4 digits are entered

3. **PIN Entry Methods**
   - **Touch Input**: Tap numbers on the on-screen keypad
   - **Hardware Keyboard**: Type numbers 0-9 on physical keyboard
   - **Backspace**: Use ⌫ button or Backspace key to correct errors
   - **Enter Key**: Press Enter to submit when 4 digits are entered

#### PIN Lock Behavior

- **App Launch**: PIN entry dialog appears before main interface
- **Verification**: PIN compared against secure hash in real-time
- **Error Handling**: Clear error messages for incorrect PIN attempts
- **Security**: Brief delay during verification for better security
- **Fallback**: Alternative access methods available if enabled

## Basic Usage

### Text Input

1. **Type Your Message**
   - Click in the text input field at the bottom
   - Type your message using the on-screen keyboard
   - Press Enter or tap the send button to submit

2. **Send Message**
   - Click the circular send button on the right
   - Or press Enter key on keyboard
   - Message is sent immediately

### Voice Input (Speech Recognition)

#### Availability
- **Supported Platforms**: Android, iOS, Web (Chrome, Edge)
- **Limited Support**: Linux, macOS (with notifications)
- **Not Supported**: Some browsers or older devices

#### Using Voice Input

1. **Activate Microphone**
   - Tap the microphone icon in the input field
   - Grant microphone permission if prompted
   - Icon turns red when listening

2. **Speak Your Message**
   - Speak clearly and at normal pace
   - Keep messages concise for best results
   - Avoid background noise when possible

3. **Stop Recording**
   - Tap the red microphone icon to stop
   - Or wait for automatic timeout (30 seconds)
   - Your speech is transcribed and displayed

4. **Send Voice Message**
   - Review transcribed text
   - Edit if necessary using keyboard
   - Tap send button or press Enter

#### Voice Input Tips

- **Clarity**: Speak clearly and at moderate pace
- **Environment**: Reduce background noise
- **Distance**: Hold device at comfortable distance
- **Language**: Use clear, standard pronunciation
- **Length**: Keep messages reasonably short

## Conversation Features

### Context Awareness

Alex maintains conversation context across sessions:

- **Message History**: Previous conversations are remembered
- **Contextual Responses**: AI responds based on conversation history
- **Personalization**: Adapts to your communication style
- **Continuity**: References previous topics naturally

### Conversation Management

#### Automatic Summarization

The app automatically summarizes long conversations:

- **Trigger Points**:
  - After 10 messages (initial summary)
  - After 25 messages (summary update)
  - On app close (if conversation is substantial)

- **Summary Storage**: Summaries are saved locally for context

#### Advanced Memory Management

The app features intelligent memory management with hierarchical organization:

- **Memory Types**:
  - **Short-term**: Recent conversations (expires in 24 hours)
  - **Medium-term**: Important topics (expires in 7 days)
  - **Long-term**: Core preferences and facts (expires in 30 days)
  - **Critical**: Essential information (never expires)

- **Importance Scoring**: Messages automatically scored based on:
  - Message length and complexity
  - Priority keywords presence
  - Question indicators
  - Emotional content
  - Personal information indicators

- **Automatic Consolidation**: Related memories consolidated to optimize storage
- **Memory Compression**: Old memories compressed for efficiency
- **Performance Monitoring**: Memory usage and performance tracking

#### Message Limits

- **Context Window**: Last 50 messages kept in active memory
- **Storage**: All messages persisted locally
- **Performance**: Older messages summarized for efficiency

### AI Personality

Alex has a consistent, friendly personality:

- **Warm and Authentic**: Friendly, genuine interaction style
- **Honest and Direct**: Truthful responses, sometimes blunt
- **Caring and Empathetic**: Supportive and understanding
- **Playful and Humorous**: Light-hearted when appropriate
- **Intellectually Curious**: Engages in deep conversations
- **Reflective**: Thoughtful and introspective responses

## Interface Guide

### Main Screen Layout

```
┌─────────────────────────────────────┐
│           Status Bar                │
├─────────────────────────────────────┤
│                                     │
│         Chat Messages               │
│         (Scrollable)                │
│                                     │
├─────────────────────────────────────┤
│  [Message Input Field]    [Send]    │
│  [███████████████]  [Mic]  [●]      │
└─────────────────────────────────────┘
```

### Visual Elements

#### Chat Messages
- **User Messages**: Standard chat bubble style
- **AI Messages**: Similar styling with Alex branding
- **Timestamps**: Subtle timestamp display
- **Loading States**: Visual feedback during AI processing

#### Input Area
- **Text Field**: Rounded rectangle with hint text
- **Microphone Button**: Circular button, red when active
- **Send Button**: Circular gradient button

#### Empty State
- **Welcome Message**: "Hey, whatsup?" with glowing effect
- **Visual Design**: Centered text with subtle shadow effects

### Theme Support

#### Light Theme
- Clean, modern interface
- Optimized for daytime use
- High contrast for readability

#### Dark Theme
- Easy on eyes for low light
- Follows system dark mode preference
- Maintains all functionality

## Advanced Features

### Conversation Persistence

#### Local Storage
- Conversations saved automatically
- Data stored in JSON format
- Accessible across app sessions

#### Data Location
- **Mobile/Desktop**: Application documents directory
- **Web**: Local browser storage
- **Privacy**: All data remains local, never transmitted

### Safety Features

#### Content Safety Monitoring

The app automatically monitors conversations for sensitive content:

- **Sensitive Content Detection**: Identifies potentially concerning messages
- **Crisis Intervention**: Provides immediate access to help resources
- **Supportive Responses**: Generates caring responses for difficult situations
- **Resource Integration**: Connects users with professional help services

#### Available Resources

When sensitive content is detected, users have access to:

- **Crisis Hotlines**: 988 Suicide & Crisis Lifeline, Crisis Text Line
- **Mental Health Support**: National Alliance on Mental Illness (NAMI)
- **Emergency Services**: Local emergency contact information
- **Professional Help**: Psychology Today therapist finder

#### Privacy and Safety

- **Local Processing**: All safety analysis happens locally
- **No Data Transmission**: Sensitive content never sent to external servers
- **User Control**: Easy access to help resources when needed
- **Compassionate Design**: Supportive rather than judgmental approach

### Error Handling

#### Network Issues
- **Offline Mode**: Graceful handling of connectivity issues
- **Retry Logic**: Automatic retry for transient failures
- **User Feedback**: Clear error messages and recovery options

#### Speech Recognition Issues
- **Permission Denied**: Clear instructions for granting permissions
- **Platform Limitations**: Notifications for unsupported platforms
- **Audio Issues**: Troubleshooting guidance for microphone problems

### Performance Optimization

#### Memory Management
- Automatic cleanup of old conversation data
- Efficient message storage and retrieval
- Background processing for heavy operations

#### Battery Optimization
- Efficient speech recognition processing
- Background task management
- Power-efficient algorithms

## Troubleshooting

### Common Issues

#### Speech Recognition Not Working

1. **Check Permissions**
   - Ensure microphone permission is granted
   - Check device settings for app permissions

2. **Platform Support**
   - Verify platform supports speech recognition
   - Try alternative browsers (for web)

3. **Audio Hardware**
   - Check microphone is not muted
   - Verify microphone is working in other apps

#### AI Responses Not Working

1. **API Configuration**
   - Verify OLLAMA_API_KEY is set correctly
   - Check API key validity

2. **Network Connection**
   - Ensure stable internet connection
   - Check firewall settings

3. **Service Status**
   - Verify Ollama Cloud API is operational
   - Check API rate limits

#### Conversation History Lost

1. **Storage Issues**
   - Check available device storage
   - Verify app has storage permissions

2. **File Corruption**
   - Check conversation_context.json file
   - Consider clearing and starting fresh

### Getting Help

#### Debug Information

1. **Flutter DevTools**
   ```bash
   flutter pub global run devtools
   ```

2. **App Logs**
   - Check console output for error messages
   - Review network request logs

3. **Device Logs**
   - Android: `adb logcat`
   - iOS: Xcode console

#### Support Resources

- **Documentation**: Check `/docs` folder for detailed guides
- **Code Comments**: Review service implementations
- **Community**: Flutter community forums and Stack Overflow

## Best Practices

### Conversation Tips

1. **Natural Communication**
   - Talk to Alex like you would a friend
   - Be conversational and authentic
   - Share context when starting new topics

2. **Message Length**
   - Keep messages concise for better recognition
   - Break long thoughts into multiple messages
   - Use clear, complete sentences

3. **Voice Usage**
   - Speak at normal pace and volume
   - Reduce background noise
   - Pause briefly between sentences

### Privacy Considerations

1. **Local Storage Only**
   - All conversations stored locally
   - No data transmitted to external servers
   - Delete app data to remove all history

2. **API Communication**
   - Only necessary data sent to AI API
   - No personal information stored externally
   - Secure, encrypted communication

### Performance Tips

1. **App Maintenance**
   - Restart app periodically for optimal performance
   - Clear cache if experiencing slowdowns
   - Keep app updated for latest optimizations

2. **Device Optimization**
   - Close background apps when using speech recognition
   - Ensure adequate free storage space
   - Keep device software updated

## Accessibility

### Voice Control
- **Hands-Free Operation**: Complete voice control support
- **Accessibility**: Alternative to typing for motor impairments
- **Language Support**: Natural language processing

### Visual Design
- **High Contrast**: Clear visual distinction between elements
- **Large Touch Targets**: Easy finger navigation
- **Readable Fonts**: Optimized typography for clarity

### Motor Accessibility
- **Large Buttons**: Easy to tap interface elements
- **Swipe Gestures**: Minimal complex gestures required
- **Voice Alternative**: Complete voice control option

## Tips and Tricks

### Productivity Features

1. **Quick Responses**
   - Use voice input for faster messaging
   - Leverage conversation context for continuity
   - Take advantage of automatic summarization

2. **Memory Management**
   - Long conversations automatically summarized
   - Context maintained across sessions
   - Important details preserved

### Customization Options

1. **AI Personality**
   - Modify `assets/system_prompt.json` for different personalities
   - Adjust response style and tone
   - Customize interaction preferences

2. **App Behavior**
   - Configure speech recognition settings
   - Adjust conversation management parameters
   - Customize UI appearance through themes

This usage guide covers all aspects of interacting with Alex AI Companion, from basic chat to advanced features and troubleshooting.