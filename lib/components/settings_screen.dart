import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/settings_service.dart';
import '../services/summarization_service.dart';
import '../utils/logger.dart';

/// Settings screen for app preferences and configuration
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withOpacity(0.95),
            ],
          ),
        ),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        // Settings sections
        _buildThemeSection(),
        const SizedBox(height: 24),
        _buildColorPaletteSection(),
        const SizedBox(height: 24),
        _buildApiSection(),
        const SizedBox(height: 24),
        _buildSecuritySection(),
        const SizedBox(height: 24),
        _buildDataSection(),
      ],
    );
  }


  Widget _buildThemeSection() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Icon(
                  Icons.palette_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Appearance',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(20),
            child: _buildThemeModeSetting(),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPaletteSection() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Icon(
                  Icons.color_lens_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Color Palette',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Primary Color',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Choose the main color theme for the app',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildColorOption(
                        title: 'Blue',
                        color: Colors.blue,
                        value: 'blue',
                        settingKey: 'primaryColor',
                      ),
                      Divider(
                        height: 1,
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      ),
                      _buildColorOption(
                        title: 'Purple',
                        color: Colors.purple,
                        value: 'purple',
                        settingKey: 'primaryColor',
                      ),
                      Divider(
                        height: 1,
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      ),
                      _buildColorOption(
                        title: 'Green',
                        color: Colors.green,
                        value: 'green',
                        settingKey: 'primaryColor',
                      ),
                      Divider(
                        height: 1,
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      ),
                      _buildColorOption(
                        title: 'Orange',
                        color: Colors.orange,
                        value: 'orange',
                        settingKey: 'primaryColor',
                      ),
                      Divider(
                        height: 1,
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      ),
                      _buildColorOption(
                        title: 'Pink',
                        color: Colors.pink,
                        value: 'pink',
                        settingKey: 'primaryColor',
                      ),
                      Divider(
                        height: 1,
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      ),
                      _buildColorOption(
                        title: 'Teal',
                        color: Colors.teal,
                        value: 'teal',
                        settingKey: 'primaryColor',
                      ),
                      Divider(
                        height: 1,
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      ),
                      _buildColorOption(
                        title: 'Indigo',
                        color: Colors.indigo,
                        value: 'indigo',
                        settingKey: 'primaryColor',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorOption({
    required String title,
    required Color color,
    required String value,
    required String settingKey,
  }) {
    final isSelected = SettingsService.settings[settingKey] == value;

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? color.withOpacity(0.08)
            : null,
      ),
      child: ListTile(
        leading: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected
                  ? color
                  : Theme.of(context).colorScheme.outline.withOpacity(0.3),
              width: 2,
            ),
          ),
          width: 32,
          height: 32,
        ),
        title: Text(
          title,
          style: GoogleFonts.playfairDisplay(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        trailing: isSelected
            ? Container(
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                width: 24,
                height: 24,
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              )
            : null,
        onTap: () => _updateSetting(settingKey, value),
      ),
    );
  }

  Widget _buildApiSection() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Icon(
                  Icons.api_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'API Configuration',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(20),
            child: _buildApiKeySetting(),
          ),
        ],
      ),
    );
  }

  Widget _buildApiKeySetting() {
    final apiKeySource = SettingsService.apiKeySource;
    final hasCustomApiKey = SettingsService.customApiKey.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'API Key Source',
          style: GoogleFonts.playfairDisplay(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Choose whether to use the inbuilt API key or provide your own custom key',
          style: GoogleFonts.playfairDisplay(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.error.withOpacity(0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.warning_amber_outlined,
                color: Theme.of(context).colorScheme.error,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '⚠️ Inbuilt API key will hit rate limits much sooner. Custom keys provide higher limits and better performance.',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.error,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              _buildApiSourceOption(
                title: 'Inbuilt API Key',
                subtitle: 'Use the pre-configured API key',
                value: 'inbuilt',
                icon: Icons.key_outlined,
              ),
              Divider(
                height: 1,
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
              _buildApiSourceOption(
                title: 'Custom API Key',
                subtitle: hasCustomApiKey ? 'Custom key is configured' : 'Enter your own API key',
                value: 'custom',
                icon: Icons.edit_outlined,
              ),
            ],
          ),
        ),
        if (apiKeySource == 'custom') ...[
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _showCustomApiKeyDialog,
              icon: const Icon(Icons.key),
              label: Text(
                hasCustomApiKey ? 'Update Custom API Key' : 'Set Custom API Key',
                style: GoogleFonts.playfairDisplay(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildApiSourceOption({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
  }) {
    final isSelected = SettingsService.apiKeySource == value;

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primary.withOpacity(0.08)
            : null,
      ),
      child: ListTile(
        leading: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
          ),
          width: 40,
          height: 40,
          child: Icon(
            icon,
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.playfairDisplay(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.playfairDisplay(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            height: 1.3,
          ),
        ),
        trailing: isSelected
            ? Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                width: 24,
                height: 24,
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              )
            : null,
        onTap: () => _updateSetting('apiKeySource', value),
      ),
    );
  }

  void _showCustomApiKeyDialog() {
    final TextEditingController apiKeyController = TextEditingController(
      text: SettingsService.customApiKey,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Custom API Key',
            style: GoogleFonts.playfairDisplay(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter your custom Ollama API key. You can get one from https://ollama.com/settings/keys',
                style: GoogleFonts.playfairDisplay(),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.security_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '🔒 Your API key is stored securely on your device only and is never transmitted to our servers.',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.primary,
                          height: 1.3,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: apiKeyController,
                decoration: InputDecoration(
                  labelText: 'API Key',
                  labelStyle: GoogleFonts.playfairDisplay(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'Enter your API key...',
                ),
                style: GoogleFonts.playfairDisplay(),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.playfairDisplay(),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final apiKey = apiKeyController.text.trim();
                if (apiKey.isNotEmpty) {
                  SettingsService.setCustomApiKey(apiKey);
                  Navigator.of(context).pop();
                  _showSuccessSnackBar('Custom API key updated successfully');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: Text(
                'Save',
                style: GoogleFonts.playfairDisplay(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSecuritySection() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Icon(
                  Icons.security_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Security',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(20),
            child: _buildPinLockSetting(),
          ),
        ],
      ),
    );
  }

  Widget _buildPinLockSetting() {
    final isPinLockEnabled = SettingsService.pinLockEnabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PIN Lock',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isPinLockEnabled
                        ? 'App is protected with a PIN code'
                        : 'Secure your app with a 4-digit PIN',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: isPinLockEnabled,
              onChanged: (value) {
                if (value) {
                  _showSetPinDialog();
                } else {
                  _showDisablePinDialog();
                }
              },
            ),
          ],
        ),
        if (isPinLockEnabled) ...[
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _showChangePinDialog,
              icon: const Icon(Icons.edit_outlined),
              label: Text(
                'Change PIN',
                style: GoogleFonts.playfairDisplay(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDataSection() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Icon(
                  Icons.storage_outlined,
                  color: Theme.of(context).colorScheme.error,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Data Management',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(20),
            child: _buildDeleteHistoryButton(),
          ),
        ],
      ),
    );
  }


  Widget _buildThemeModeSetting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Theme Preference',
          style: GoogleFonts.playfairDisplay(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Choose how the app looks and feels',
          style: GoogleFonts.playfairDisplay(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              _buildThemeOption(
                title: 'System',
                subtitle: 'Follow system theme',
                value: 'system',
                icon: Icons.smartphone_outlined,
              ),
              Divider(
                height: 1,
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
              _buildThemeOption(
                title: 'Light',
                subtitle: 'Always use light theme',
                value: 'light',
                icon: Icons.light_mode_outlined,
              ),
              Divider(
                height: 1,
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
              _buildThemeOption(
                title: 'Dark',
                subtitle: 'Always use dark theme',
                value: 'dark',
                icon: Icons.dark_mode_outlined,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThemeOption({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
  }) {
    final isSelected = SettingsService.themeMode == value;

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primary.withOpacity(0.08)
            : null,
      ),
      child: ListTile(
        leading: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
          ),
          width: 40,
          height: 40,
          child: Icon(
            icon,
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.playfairDisplay(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.playfairDisplay(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            height: 1.3,
          ),
        ),
        trailing: isSelected
            ? Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                width: 24,
                height: 24,
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              )
            : null,
        onTap: () => _updateSetting('themeMode', value),
      ),
    );
  }


  Widget _buildDeleteHistoryButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Clear Data',
          style: GoogleFonts.playfairDisplay(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Permanently delete Alex, including all conversation history and memories. This action cannot be undone.',
          style: GoogleFonts.playfairDisplay(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: _showDeleteConfirmationDialog,
            icon: const Icon(Icons.warning_amber_outlined),
            label: Text(
              'Permanently Delete Alex',
              style: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }


  void _updateSetting(String key, dynamic value) {
    setState(() {
      SettingsService.setSetting(key, value);
      SettingsService.saveSettings();
    });
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Permanently Delete Alex?',
            style: GoogleFonts.playfairDisplay(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'This action cannot be undone. Alex and all conversation history will be permanently deleted.',
            style: GoogleFonts.playfairDisplay(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.playfairDisplay(),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAllHistory();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Delete Permanently',
                style: GoogleFonts.playfairDisplay(),
              ),
            ),
          ],
        );
      },
    );
  }

  void _deleteAllHistory() async {
    try {
      await SettingsService.clearAllHistory();
      // Also clear all cached memories from summarization service
      SummarizationService.clearAllMemories();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Alex permanently deleted. All memories and conversation history removed.',
              style: GoogleFonts.playfairDisplay(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      AppLogger.e('Error deleting history', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to permanently delete Alex. Please try again.',
              style: GoogleFonts.playfairDisplay(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSetPinDialog() {
    String newPin = '';
    String confirmPin = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Set PIN Lock',
                style: GoogleFonts.playfairDisplay(
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Enter a 4-digit PIN to secure your app',
                    style: GoogleFonts.playfairDisplay(),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'New PIN',
                      labelStyle: GoogleFonts.playfairDisplay(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: '1234',
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    style: GoogleFonts.playfairDisplay(),
                    onChanged: (value) => setState(() => newPin = value),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Confirm PIN',
                      labelStyle: GoogleFonts.playfairDisplay(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: '1234',
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    style: GoogleFonts.playfairDisplay(),
                    onChanged: (value) => setState(() => confirmPin = value),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.playfairDisplay(),
                  ),
                ),
                ElevatedButton(
                  onPressed: (newPin.length == 4 && newPin == confirmPin)
                      ? () {
                          SettingsService.setPinLock(newPin);
                          Navigator.of(context).pop();
                          _showSuccessSnackBar('PIN lock enabled successfully');
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  child: Text(
                    'Set PIN',
                    style: GoogleFonts.playfairDisplay(),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDisablePinDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Disable PIN Lock?',
            style: GoogleFonts.playfairDisplay(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Are you sure you want to disable PIN lock? Your app will no longer require a PIN to access.',
            style: GoogleFonts.playfairDisplay(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.playfairDisplay(),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                SettingsService.disablePinLock();
                Navigator.of(context).pop();
                _showSuccessSnackBar('PIN lock disabled');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Disable',
                style: GoogleFonts.playfairDisplay(),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showChangePinDialog() {
    String currentPin = '';
    String newPin = '';
    String confirmPin = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Change PIN',
                style: GoogleFonts.playfairDisplay(
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Current PIN',
                      labelStyle: GoogleFonts.playfairDisplay(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    style: GoogleFonts.playfairDisplay(),
                    onChanged: (value) => setState(() => currentPin = value),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'New PIN',
                      labelStyle: GoogleFonts.playfairDisplay(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: '1234',
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    style: GoogleFonts.playfairDisplay(),
                    onChanged: (value) => setState(() => newPin = value),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Confirm New PIN',
                      labelStyle: GoogleFonts.playfairDisplay(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: '1234',
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    style: GoogleFonts.playfairDisplay(),
                    onChanged: (value) => setState(() => confirmPin = value),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.playfairDisplay(),
                  ),
                ),
                ElevatedButton(
                  onPressed: (currentPin.length == 4 &&
                           newPin.length == 4 &&
                           newPin == confirmPin &&
                           SettingsService.verifyPin(currentPin))
                      ? () {
                          SettingsService.setPinLock(newPin);
                          Navigator.of(context).pop();
                          _showSuccessSnackBar('PIN changed successfully');
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  child: Text(
                    'Change PIN',
                    style: GoogleFonts.playfairDisplay(),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.playfairDisplay(),
        ),
        backgroundColor: Colors.green,
      ),
    );
  }
}