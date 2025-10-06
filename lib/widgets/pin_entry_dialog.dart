import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/settings_service.dart';

// Add this import for keyboard key handling

/// A dialog widget for PIN entry with a numeric keypad
class PinEntryDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onSuccess;
  final bool showBackButton;

  const PinEntryDialog({
    super.key,
    this.title = 'Enter PIN',
    this.subtitle = 'Please enter your 4-digit PIN to continue',
    this.onSuccess,
    this.showBackButton = false,
  });

  @override
  State<PinEntryDialog> createState() => _PinEntryDialogState();
}

class _PinEntryDialogState extends State<PinEntryDialog> {
  String _enteredPin = '';
  String _errorMessage = '';
  bool _isVerifying = false;
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Show soft keyboard for PIN entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChannels.textInput.invokeMethod('TextInput.show');
      // Focus the text field for keyboard input
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _addDigit(String digit) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += digit;
        _errorMessage = '';

        // Auto-verify when 4 digits are entered
        if (_enteredPin.length == 4) {
          _verifyPin();
        }
      });
    }
  }

  void _removeDigit() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = '';
      });
    }
  }

  void _verifyPin() async {
    if (_enteredPin.length != 4) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = '';
    });

    // Add a small delay for better UX
    await Future.delayed(const Duration(milliseconds: 300));

    if (SettingsService.verifyPin(_enteredPin)) {
      if (mounted) {
        Navigator.of(context).pop(true);
        widget.onSuccess?.call();
      }
    } else {
      setState(() {
        _enteredPin = '';
        _errorMessage = 'Incorrect PIN. Please try again.';
        _isVerifying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => widget.showBackButton,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 320,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Text(
                  widget.title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.subtitle,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // PIN Display
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index < _enteredPin.length
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                        ),
                      );
                    }),
                  ),
                ),

                // Keyboard input support using RawKeyboardListener
                RawKeyboardListener(
                  focusNode: _focusNode,
                  onKey: (RawKeyEvent event) {
                    if (_isVerifying) return;

                    if (event is RawKeyDownEvent) {
                      final key = event.logicalKey;

                      // Handle number keys
                      if (key == LogicalKeyboardKey.digit0 || key == LogicalKeyboardKey.numpad0) {
                        _addDigit('0');
                      } else if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.numpad1) {
                        _addDigit('1');
                      } else if (key == LogicalKeyboardKey.digit2 || key == LogicalKeyboardKey.numpad2) {
                        _addDigit('2');
                      } else if (key == LogicalKeyboardKey.digit3 || key == LogicalKeyboardKey.numpad3) {
                        _addDigit('3');
                      } else if (key == LogicalKeyboardKey.digit4 || key == LogicalKeyboardKey.numpad4) {
                        _addDigit('4');
                      } else if (key == LogicalKeyboardKey.digit5 || key == LogicalKeyboardKey.numpad5) {
                        _addDigit('5');
                      } else if (key == LogicalKeyboardKey.digit6 || key == LogicalKeyboardKey.numpad6) {
                        _addDigit('6');
                      } else if (key == LogicalKeyboardKey.digit7 || key == LogicalKeyboardKey.numpad7) {
                        _addDigit('7');
                      } else if (key == LogicalKeyboardKey.digit8 || key == LogicalKeyboardKey.numpad8) {
                        _addDigit('8');
                      } else if (key == LogicalKeyboardKey.digit9 || key == LogicalKeyboardKey.numpad9) {
                        _addDigit('9');
                      }
                      // Handle backspace
                      else if (key == LogicalKeyboardKey.backspace) {
                        _removeDigit();
                      }
                      // Handle Enter key for verification
                      else if (key == LogicalKeyboardKey.enter && _enteredPin.length == 4) {
                        _verifyPin();
                      }
                    }
                  },
                  child: const SizedBox.shrink(), // Invisible child
                ),

                // Error Message
                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.error,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],

                // Loading Indicator
                if (_isVerifying) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Numeric Keypad
                _buildKeypad(),

                // Back Button (if enabled)
                if (widget.showBackButton) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      'Use Different Method',
                      style: GoogleFonts.playfairDisplay(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    const keypadLayout = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      [' ', '0', '⌫'],
    ];

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: keypadLayout.map((row) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((key) {
              if (key == ' ') {
                return const SizedBox(width: 60, height: 60);
              }

              return GestureDetector(
                onTap: () {
                  if (key == '⌫') {
                    _removeDigit();
                  } else {
                    _addDigit(key);
                  }
                },
                child: Container(
                  width: 60,
                  height: 60,
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getKeyColor(key),
                  ),
                  child: Center(
                    child: key == '⌫'
                        ? Icon(
                            Icons.backspace_outlined,
                            color: Theme.of(context).colorScheme.onPrimary,
                            size: 20,
                          )
                        : Text(
                            key,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  Color _getKeyColor(String key) {
    if (key == '⌫') {
      return Colors.grey.shade600;
    }
    return Theme.of(context).colorScheme.primary;
  }
}

/// Show PIN entry dialog and return true if PIN is correct
Future<bool> showPinEntryDialog(
  BuildContext context, {
  String title = 'Enter PIN',
  String subtitle = 'Please enter your 4-digit PIN to continue',
  VoidCallback? onSuccess,
  bool showBackButton = false,
}) async {
  return await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => PinEntryDialog(
      title: title,
      subtitle: subtitle,
      onSuccess: onSuccess,
      showBackButton: showBackButton,
    ),
  ) ??
  false;
}