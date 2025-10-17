# Components and Widgets Documentation

## Overview

This document details the UI components and widgets that make up Alex AI Companion's user interface, including screens, widgets, and styling.

## Main Components

### ChatScreen

The primary interface component that handles the chat experience.

#### Location
`lib/components/chat_screen.dart`

#### Key Features
- **Real-time Chat Interface**: Displays conversation messages
- **Speech Recognition Integration**: Voice input capabilities
- **Message Management**: Handles sending and receiving messages
- **Context Awareness**: Maintains conversation continuity
- **Responsive Design**: Adapts to different screen sizes

#### State Management

```dart
class _ChatScreenState extends State<ChatScreen> {
  // Core state variables
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  // Speech recognition state
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechEnabled = false;
  String _lastWords = '';
}
```

#### Key Methods

##### `_sendMessage(String message)`
Handles sending user messages and receiving AI responses.

```dart
Future<void> _sendMessage(String message) async
```

**Process**:
1. Validates message is not empty
2. Stops speech recognition if active
3. Saves user message to conversation history
4. Shows loading state
5. Gets AI response from OllamaService
6. Updates UI with AI response
7. Saves conversation context
8. Triggers summarization if needed

##### `_getAIResponse(String userMessage)`
Retrieves AI response from Ollama service.

```dart
Future<String> _getAIResponse(String userMessage) async
```

##### Speech Recognition Methods

- `_startListening()`: Begins speech recognition
- `_stopListening()`: Ends speech recognition session
- `_onSpeechResult()`: Processes speech recognition results
- `_onSpeechError()`: Handles speech recognition errors

##### Conversation Management

- `_checkAndTriggerSummarization()`: Triggers conversation summarization
- `_performSummarization()`: Creates conversation summary
- `_triggerSummarizationIfNeeded()`: Summarization on app close

#### UI Structure

##### Main Layout
```dart
Scaffold(
  body: Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(...) // Subtle background gradient
    ),
    child: Stack(
      children: [
        // Chat content area
        Positioned.fill(
          top: 0,
          bottom: 120,
          child: _buildChatContent()
        ),
        // Input area at bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildInputArea()
        )
      ]
    )
  )
)
```

##### Empty State
- Centered welcome message: "Hey, whatsup?"
- Glowing effect background
- Responsive text sizing

##### Input Area
- Rounded text field with hint text
- Microphone button (when speech enabled)
- Send button with gradient styling

## Widget Components

### ChatMessage

Displays individual chat messages with markdown support and visual effects.

#### Location
`lib/widgets/chat_message.dart`

#### Features
- **Markdown Rendering**: Supports bold, italic, and other markdown elements
- **Visual Effects**: Glowing background and shadow effects
- **Responsive Design**: Adapts to screen width
- **Loading States**: Visual feedback during AI processing
- **Text Selection**: Selectable text for copying

#### Properties

```dart
class ChatMessage extends StatelessWidget {
  final String text;        // Message content
  final bool isUser;        // Message origin (user/AI)
  final DateTime timestamp; // Message timestamp
  final bool isLoading;     // Loading state indicator
}
```

#### Visual Design

##### Background Effects
- **Glowing Circle**: Subtle shadow effects behind messages
- **Dynamic Colors**: Blue glow during loading, primary color after response
- **Responsive Size**: 180px diameter with blur effects

##### Text Styling
- **Font**: Google Fonts Playfair Display
- **Size**: 22px for optimal readability
- **Shadows**: Subtle text shadows for depth
- **Markdown Support**: Bold, italic, and header styling

##### Layout Constraints
- **Max Width**: 80% of screen width
- **Centered Alignment**: Messages centered on screen
- **Selectable Text**: Users can select and copy message content

#### Markdown Support

##### Supported Elements
- **Bold Text**: `**bold**` → Bold weight font
- **Italic Text**: `*italic*` → Italic style font
- **Headers**: `# Header` → Regular text (no special sizing)
- **Paragraphs**: Regular text formatting

##### Custom Styling
All markdown elements use consistent styling:
- Same font family (Playfair Display)
- Consistent color scheme
- Matching shadow effects
- Responsive sizing

### FloatingSnackbar

Custom notification widget that appears at the top of the screen.

#### Location
`lib/widgets/floating_snackbar.dart`

#### Features
- **Top Positioning**: Appears at top of screen with safe area padding
- **Smooth Animation**: Slide-down animation with opacity transition
- **Action Buttons**: Optional action button with custom label
- **Auto Dismiss**: Automatically disappears after specified duration
- **Manual Dismiss**: Close button for manual dismissal

#### Properties

```dart
class FloatingSnackbar extends StatefulWidget {
  final String message;           // Main notification text
  final String? actionLabel;      // Optional action button text
  final VoidCallback? onActionPressed; // Action button callback
  final Duration duration;        // Auto-dismiss duration
  final bool showCloseButton;     // Show/hide close button
}
```

#### Static Method

##### `show(BuildContext context, ...)`
Displays the snackbar using Flutter's Overlay system.

```dart
static void show(
  BuildContext context, {
  required String message,
  String? actionLabel,
  VoidCallback? onActionPressed,
  Duration duration = const Duration(seconds: 4),
  bool showCloseButton = true,
})
```

**Usage Example**:
```dart
FloatingSnackbar.show(
  context,
  message: 'Speech recognition not available',
  actionLabel: 'Settings',
  onActionPressed: () => openAppSettings(),
  duration: const Duration(seconds: 6),
);
```

#### Animation System

##### Animation Controller
- **Duration**: 300ms slide and opacity animation
- **Curve**: EaseOut curve for smooth appearance
- **Reverse Animation**: Smooth dismissal animation

##### Visual Effects
- **Slide Transition**: Slides down from above screen
- **Opacity Animation**: Fades in and out smoothly
- **Transform Offset**: -20px offset for subtle movement

#### Styling

##### Container Design
- **Rounded Corners**: 16px border radius
- **Background**: Theme-aware surface color
- **Border**: Subtle outline border
- **Shadows**: Multi-layer shadow effects for depth

##### Typography
- **Font**: Google Fonts Playfair Display
- **Size**: 14px for comfortable reading
- **Color**: Theme-aware text color
- **Line Height**: 1.4 for optimal readability

##### Action Button
- **Style**: TextButton with minimal padding
- **Color**: Primary theme color
- **Font Weight**: Semi-bold for emphasis
- **Tap Target**: Optimized for touch interaction

### PinEntryDialog

Secure PIN entry dialog with numeric keypad for app access protection.

#### Location
`lib/widgets/pin_entry_dialog.dart`

#### Features
- **Secure PIN Entry**: 4-digit PIN input with visual feedback
- **Numeric Keypad**: Custom on-screen numeric keypad
- **Keyboard Support**: Hardware keyboard input support
- **Visual Feedback**: Animated PIN dots and loading states
- **Error Handling**: Clear error messages for incorrect PINs
- **Responsive Design**: Adapts to mobile and desktop screen sizes
- **Theme Integration**: Consistent with app theme and styling

#### Properties

```dart
class PinEntryDialog extends StatefulWidget {
  final String title;              // Dialog title text
  final String subtitle;           // Dialog subtitle text
  final VoidCallback? onSuccess;   // Callback when PIN is verified
  final bool showBackButton;       // Show alternative access button
}
```

#### Key Methods

##### `_addDigit(String digit)`
Adds a digit to the entered PIN.

```dart
void _addDigit(String digit)
```

##### `_removeDigit()`
Removes the last digit from entered PIN.

```dart
void _removeDigit()
```

##### `_verifyPin()`
Verifies the entered PIN against stored hash.

```dart
Future<void> _verifyPin() async
```

#### UI Structure

##### Dialog Layout
```dart
Scaffold(
  backgroundColor: Colors.transparent,
  body: Container(
    decoration: BoxDecoration(gradient: LinearGradient(...)),
    child: SafeArea(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          children: [
            // Header with title and subtitle
            // PIN display dots
            // Numeric keypad
            // Error messages and loading indicators
          ]
        )
      )
    )
  )
)
```

##### PIN Display
- **Visual Dots**: 4 circular indicators showing entered digits
- **Filled State**: Primary color when digit is entered
- **Empty State**: Outline color when digit is not entered
- **Animation**: Smooth color transitions

##### Numeric Keypad
```dart
const keypadLayout = [
  ['1', '2', '3'],
  ['4', '5', '6'],
  ['7', '8', '9'],
  [' ', '0', '⌫'],  // Backspace button
];
```

##### Keypad Features
- **Circular Buttons**: Consistent button shape and sizing
- **Responsive Sizing**: Adapts to screen size and platform
- **Visual Feedback**: Shadow effects and press animations
- **Backspace Button**: Icon-based delete functionality
- **Empty Space**: Proper spacing in bottom row

#### Keyboard Support

##### Hardware Keyboard Input
- **Number Keys**: 0-9 digit input support
- **Numpad Support**: Extended keyboard numpad support
- **Backspace**: Delete key support
- **Enter Key**: Submit PIN when 4 digits entered

##### Input Handling
```dart
RawKeyboardListener(
  focusNode: _focusNode,
  onKey: (RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      // Handle number keys, backspace, enter
    }
  },
  child: const SizedBox.shrink(),
)
```

#### Security Features

##### PIN Verification
- **Hash Comparison**: Compares against SHA-256 hashed PIN
- **No Plaintext Storage**: PINs never stored in plaintext
- **Verification Delay**: Brief delay for better UX during verification
- **Error Feedback**: Clear messaging for incorrect attempts

##### Auto-Verification
- **4-Digit Auto-Submit**: Automatically verifies when 4 digits entered
- **Loading State**: Visual feedback during verification process
- **Success Callback**: Triggers onSuccess callback when verified

#### Responsive Design

##### Mobile Layout
- **Larger Touch Targets**: 80px button size for easy finger navigation
- **Generous Padding**: 32px padding for comfortable spacing
- **Optimized Text Sizes**: 28px title, 16px subtitle

##### Desktop Layout
- **Smaller Buttons**: 60px button size for mouse interaction
- **Reduced Padding**: 24px padding for efficient use of space
- **Adjusted Text Sizes**: 32px title, 18px subtitle

#### Error Handling

##### Error States
- **Incorrect PIN**: Clear error message with red styling
- **Empty PIN**: No verification until 4 digits entered
- **Verification Failure**: Reset PIN and show retry option

##### Visual Feedback
- **Error Text**: Styled with error color and appropriate font size
- **Loading Indicator**: Circular progress indicator during verification
- **Reset State**: PIN field clears on incorrect entry

#### Static Method

##### `showPinEntryDialog(BuildContext context, ...)`
Displays the PIN entry dialog using Navigator.

```dart
static Future<bool> showPinEntryDialog(
  BuildContext context, {
  String title = 'Enter PIN',
  String subtitle = 'Please enter your 4-digit PIN to continue',
  VoidCallback? onSuccess,
  bool showBackButton = false,
}) async
```

**Usage Example**:
```dart
final pinCorrect = await showPinEntryDialog(
  context,
  title: 'Welcome Back',
  subtitle: 'Enter your PIN to access the app',
  onSuccess: () => print('PIN verified successfully'),
  showBackButton: true,
);

if (pinCorrect) {
  // PIN was correct, continue with app access
} else {
  // PIN was incorrect or dialog was cancelled
}
```

#### Integration with SettingsService

##### PIN Management
- **Verification**: Uses `SettingsService.verifyPin()` for authentication
- **Hash Storage**: Integrates with secure PIN storage system
- **Settings Integration**: Respects PIN lock enabled/disabled state

##### Security Integration
```dart
if (SettingsService.verifyPin(_enteredPin)) {
  // PIN is correct
  Navigator.of(context).pop(true);
  widget.onSuccess?.call();
} else {
  // PIN is incorrect
  _enteredPin = '';
  _errorMessage = 'Incorrect PIN. Please try again.';
}
```

## Styling and Theming

### AppTheme

Defines consistent theming across the application.

#### Location
`lib/constants/app_theme.dart`

#### Theme Components

##### Color Scheme
- **Light Theme**: Clean, modern colors for daytime use
- **Dark Theme**: Eye-friendly colors for low-light environments
- **System Detection**: Automatically follows system theme preference

##### Typography
- **Primary Font**: Google Fonts Playfair Display
- **Fallback**: System fonts for reliability
- **Responsive Sizing**: Adapts to screen size and accessibility settings

##### Component Styling
- **Buttons**: Gradient backgrounds with shadow effects
- **Input Fields**: Rounded borders with subtle outlines
- **Cards**: Elevated surfaces with soft shadows

### Design System

#### Color Palette
- **Primary Colors**: Theme-aware primary color scheme
- **Surface Colors**: Elevated surfaces for content
- **Text Colors**: High contrast for readability
- **Accent Colors**: Subtle accent colors for highlights

#### Spacing System
- **Consistent Margins**: Standardized spacing throughout
- **Responsive Padding**: Adapts to screen size
- **Component Spacing**: Consistent gaps between elements

#### Typography Scale
- **Headings**: Hierarchical text sizing
- **Body Text**: Optimal reading size (22px for messages)
- **Captions**: Smaller text for secondary information

## Responsive Design

### Screen Adaptations

#### Mobile Layout
- **Portrait Mode**: Optimized for one-handed use
- **Landscape Mode**: Expanded chat area
- **Touch Targets**: Minimum 44px touch targets

#### Desktop Layout
- **Window Sizing**: Responsive to window size
- **Keyboard Navigation**: Full keyboard support
- **Mouse Interaction**: Hover states and mouse optimization

#### Web Layout
- **Browser Compatibility**: Works across modern browsers
- **Viewport Adaptation**: Responsive to screen size
- **PWA Support**: Progressive Web App capabilities

### Accessibility Features

#### Visual Accessibility
- **High Contrast**: WCAG compliant color ratios
- **Text Scaling**: Respects system font size settings
- **Color Blind Support**: Color choices that work with color blindness

#### Motor Accessibility
- **Large Touch Targets**: Easy finger navigation
- **Voice Control**: Complete voice input support
- **Keyboard Navigation**: Full keyboard accessibility

#### Cognitive Accessibility
- **Clear Visual Hierarchy**: Logical information organization
- **Consistent Navigation**: Predictable interface patterns
- **Error Prevention**: Clear validation and error handling

## Animation System

### Transition Types

#### Page Transitions
- **Smooth Animations**: 300ms duration for state changes
- **Curve Animation**: EaseOut curve for natural movement
- **Staggered Animation**: Coordinated multi-element animations

#### Loading States
- **Pulse Animation**: Subtle loading indicators
- **Progress Feedback**: Clear indication of ongoing operations
- **Skeleton Screens**: Placeholder content during loading

### Performance Optimization

#### Animation Best Practices
- **60fps Target**: Smooth animation performance
- **Hardware Acceleration**: GPU-accelerated animations
- **Memory Management**: Proper cleanup of animation controllers

## Integration Patterns

### Component Communication

#### State Management
- **Provider Pattern**: Centralized state management (future)
- **Callback Pattern**: Direct method callbacks
- **Stream Pattern**: Reactive state updates (future)

#### Data Flow
- **Unidirectional**: Clear data flow from parent to child
- **Immutable Data**: Predictable state changes
- **Type Safety**: Strong typing for all data structures

### Widget Composition

#### Reusable Patterns
- **Container Widgets**: Consistent styling containers
- **Text Widgets**: Standardized text display
- **Button Widgets**: Consistent button behavior

#### Layout Patterns
- **Stack Layout**: Overlay-based layouts for complex UIs
- **Flex Layout**: Responsive column and row layouts
- **Positioned Layout**: Precise element positioning

## Testing Components

### Widget Testing

#### Test Structure
```dart
testWidgets('ChatMessage displays text correctly', (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ChatMessage(
        text: 'Test message',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    ),
  );

  expect(find.text('Test message'), findsOneWidget);
});
```

### Integration Testing

#### Screen Testing
- **User Interaction**: Test complete user workflows
- **State Changes**: Verify state management
- **Error Handling**: Test error scenarios

## Future Enhancements

### Planned Components

#### MessageList
- **Virtual Scrolling**: Efficient handling of large message lists
- **Message Grouping**: Group related messages
- **Search Functionality**: In-conversation search

#### SettingsScreen
- **User Preferences**: Customizable app settings
- **Theme Selection**: Manual theme override
- **Accessibility Options**: Enhanced accessibility controls

### Performance Improvements

#### Optimization Opportunities
- **Widget Caching**: Cache expensive widget trees
- **Lazy Loading**: Load content as needed
- **Memory Management**: Efficient widget disposal

This comprehensive component documentation provides a complete understanding of the UI architecture and implementation details for Alex AI Companion.