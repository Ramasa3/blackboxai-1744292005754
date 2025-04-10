import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../config/theme.dart';
import '../config/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoPlayVideos = true;
  bool _enableNotifications = true;
  bool _enableWatchPartyInvites = true;
  String _selectedQuality = 'Auto';
  String _selectedLanguage = 'English';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Load user settings from local storage or backend
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      // Save settings to local storage or backend
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.primaryBlack,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryRed,
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPlaybackSettings(),
                  _buildNotificationSettings(),
                  _buildSocialSettings(),
                  _buildAppearanceSettings(),
                  _buildStorageSettings(),
                  _buildAboutSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildPlaybackSettings() {
    return _buildSection(
      'Playback',
      [
        SwitchListTile(
          value: _autoPlayVideos,
          onChanged: (value) {
            setState(() => _autoPlayVideos = value);
            _saveSettings();
          },
          title: const Text('Auto-play videos'),
          subtitle: const Text('Automatically play next episode or recommended content'),
          activeColor: AppTheme.primaryRed,
        ),
        ListTile(
          title: const Text('Streaming Quality'),
          subtitle: Text(_selectedQuality),
          trailing: const Icon(Icons.chevron_right),
          onTap: _showQualityDialog,
        ),
        ListTile(
          title: const Text('Download Quality'),
          subtitle: const Text('Standard'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // Show download quality options
          },
        ),
      ],
    );
  }

  Widget _buildNotificationSettings() {
    return _buildSection(
      'Notifications',
      [
        SwitchListTile(
          value: _enableNotifications,
          onChanged: (value) {
            setState(() => _enableNotifications = value);
            _saveSettings();
          },
          title: const Text('Enable Notifications'),
          subtitle: const Text('Receive updates about new content and features'),
          activeColor: AppTheme.primaryRed,
        ),
        ListTile(
          title: const Text('Notification Types'),
          subtitle: const Text('Customize notification preferences'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // Navigate to notification types screen
          },
        ),
      ],
    );
  }

  Widget _buildSocialSettings() {
    return _buildSection(
      'Social',
      [
        SwitchListTile(
          value: _enableWatchPartyInvites,
          onChanged: (value) {
            setState(() => _enableWatchPartyInvites = value);
            _saveSettings();
          },
          title: const Text('Watch Party Invites'),
          subtitle: const Text('Allow friends to invite you to watch parties'),
          activeColor: AppTheme.primaryRed,
        ),
        ListTile(
          title: const Text('Connected Accounts'),
          subtitle: const Text('Manage social media connections'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // Navigate to connected accounts screen
          },
        ),
      ],
    );
  }

  Widget _buildAppearanceSettings() {
    return _buildSection(
      'Appearance',
      [
        ListTile(
          title: const Text('Language'),
          subtitle: Text(_selectedLanguage),
          trailing: const Icon(Icons.chevron_right),
          onTap: _showLanguageDialog,
        ),
        ListTile(
          title: const Text('Theme'),
          subtitle: const Text('Dark'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // Show theme options
          },
        ),
      ],
    );
  }

  Widget _buildStorageSettings() {
    return _buildSection(
      'Storage',
      [
        ListTile(
          title: const Text('Clear Cache'),
          subtitle: const Text('Free up space by clearing cached data'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _showClearCacheDialog,
        ),
        ListTile(
          title: const Text('Manage Downloads'),
          subtitle: const Text('View and delete downloaded content'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // Navigate to downloads management screen
          },
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return _buildSection(
      'About',
      [
        ListTile(
          title: const Text('App Version'),
          subtitle: const Text(AppConstants.appVersion),
        ),
        ListTile(
          title: const Text('Terms of Service'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // Open terms of service
          },
        ),
        ListTile(
          title: const Text('Privacy Policy'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // Open privacy policy
          },
        ),
        ListTile(
          title: const Text('Help & Support'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // Navigate to help & support screen
          },
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            style: const TextStyle(
              color: AppTheme.primaryRed,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
        const Divider(color: Colors.grey),
      ],
    );
  }

  void _showQualityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text(
          'Streaming Quality',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            'Auto',
            'Low (480p)',
            'Medium (720p)',
            'High (1080p)',
            '4K Ultra HD',
          ].map((quality) {
            return RadioListTile<String>(
              value: quality,
              groupValue: _selectedQuality,
              onChanged: (value) {
                setState(() => _selectedQuality = value!);
                Navigator.pop(context);
                _saveSettings();
              },
              title: Text(
                quality,
                style: const TextStyle(color: Colors.white),
              ),
              activeColor: AppTheme.primaryRed,
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text(
          'Language',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            'English',
            'Spanish',
            'French',
            'German',
            'Japanese',
          ].map((language) {
            return RadioListTile<String>(
              value: language,
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() => _selectedLanguage = value!);
                Navigator.pop(context);
                _saveSettings();
              },
              title: Text(
                language,
                style: const TextStyle(color: Colors.white),
              ),
              activeColor: AppTheme.primaryRed,
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text(
          'Clear Cache',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to clear the app cache? This will free up storage space but may affect app performance temporarily.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Implement cache clearing
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
