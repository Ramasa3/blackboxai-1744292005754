import 'dart:async';
import 'package:flutter/material.dart';
import '../config/constants.dart';
import 'storage_service.dart';

class PreferencesService {
  static final PreferencesService _instance = PreferencesService._internal();
  final StorageService _storageService = StorageService();
  
  final _preferencesController = StreamController<AppPreferences>.broadcast();
  Stream<AppPreferences> get preferencesStream => _preferencesController.stream;
  
  late AppPreferences _preferences;

  factory PreferencesService() {
    return _instance;
  }

  PreferencesService._internal();

  Future<void> init() async {
    _preferences = await _loadPreferences();
    _preferencesController.add(_preferences);
  }

  Future<AppPreferences> _loadPreferences() async {
    final settings = _storageService.getSettings();
    
    return AppPreferences(
      // Playback preferences
      autoPlayVideos: settings['autoPlayVideos'] ?? true,
      defaultPlaybackQuality: settings['streamingQuality'] ?? 'Auto',
      defaultPlaybackSpeed: settings['playbackSpeed'] ?? 1.0,
      enablePictureInPicture: settings['enablePictureInPicture'] ?? true,
      enableBackgroundPlay: settings['enableBackgroundPlay'] ?? false,
      
      // Download preferences
      downloadQuality: settings['downloadQuality'] ?? 'HD',
      downloadOverWifiOnly: settings['downloadOverWifiOnly'] ?? true,
      maxDownloadQuality: settings['maxDownloadQuality'] ?? '1080p',
      
      // Notification preferences
      enableNotifications: settings['enableNotifications'] ?? true,
      enableWatchPartyInvites: settings['enableWatchPartyInvites'] ?? true,
      enableNewContentNotifications: settings['enableNewContentNotifications'] ?? true,
      enableSubscriptionNotifications: settings['enableSubscriptionNotifications'] ?? true,
      
      // Display preferences
      themeMode: _parseThemeMode(settings['theme'] ?? 'dark'),
      language: settings['language'] ?? 'English',
      subtitlesEnabled: settings['subtitlesEnabled'] ?? false,
      subtitlesLanguage: settings['subtitlesLanguage'] ?? 'English',
      subtitleSize: settings['subtitleSize'] ?? 16.0,
      
      // Social preferences
      showOnlineStatus: settings['showOnlineStatus'] ?? true,
      allowWatchPartyInvites: settings['allowWatchPartyInvites'] ?? true,
      shareWatchHistory: settings['shareWatchHistory'] ?? false,
      
      // Privacy preferences
      enableAnalytics: settings['enableAnalytics'] ?? true,
      saveWatchHistory: settings['saveWatchHistory'] ?? true,
      saveSearchHistory: settings['saveSearchHistory'] ?? true,
      
      // Cache preferences
      maxCacheSize: settings['maxCacheSize'] ?? AppConstants.maxCacheSize,
      autoClearCache: settings['autoClearCache'] ?? false,
      
      // Content preferences
      contentMaturityLevel: settings['contentMaturityLevel'] ?? 'All',
      preferredCategories: _parseStringList(settings['preferredCategories']),
      excludedCategories: _parseStringList(settings['excludedCategories']),
    );
  }

  ThemeMode _parseThemeMode(String theme) {
    switch (theme.toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.dark;
    }
  }

  List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.cast<String>();
    if (value is String) return value.split(',').map((e) => e.trim()).toList();
    return [];
  }

  Future<void> updatePreferences(AppPreferences preferences) async {
    _preferences = preferences;
    await _savePreferences();
    _preferencesController.add(_preferences);
  }

  Future<void> _savePreferences() async {
    final settings = {
      // Playback settings
      'autoPlayVideos': _preferences.autoPlayVideos,
      'streamingQuality': _preferences.defaultPlaybackQuality,
      'playbackSpeed': _preferences.defaultPlaybackSpeed,
      'enablePictureInPicture': _preferences.enablePictureInPicture,
      'enableBackgroundPlay': _preferences.enableBackgroundPlay,
      
      // Download settings
      'downloadQuality': _preferences.downloadQuality,
      'downloadOverWifiOnly': _preferences.downloadOverWifiOnly,
      'maxDownloadQuality': _preferences.maxDownloadQuality,
      
      // Notification settings
      'enableNotifications': _preferences.enableNotifications,
      'enableWatchPartyInvites': _preferences.enableWatchPartyInvites,
      'enableNewContentNotifications': _preferences.enableNewContentNotifications,
      'enableSubscriptionNotifications': _preferences.enableSubscriptionNotifications,
      
      // Display settings
      'theme': _preferences.themeMode.toString().split('.').last,
      'language': _preferences.language,
      'subtitlesEnabled': _preferences.subtitlesEnabled,
      'subtitlesLanguage': _preferences.subtitlesLanguage,
      'subtitleSize': _preferences.subtitleSize,
      
      // Social settings
      'showOnlineStatus': _preferences.showOnlineStatus,
      'allowWatchPartyInvites': _preferences.allowWatchPartyInvites,
      'shareWatchHistory': _preferences.shareWatchHistory,
      
      // Privacy settings
      'enableAnalytics': _preferences.enableAnalytics,
      'saveWatchHistory': _preferences.saveWatchHistory,
      'saveSearchHistory': _preferences.saveSearchHistory,
      
      // Cache settings
      'maxCacheSize': _preferences.maxCacheSize,
      'autoClearCache': _preferences.autoClearCache,
      
      // Content settings
      'contentMaturityLevel': _preferences.contentMaturityLevel,
      'preferredCategories': _preferences.preferredCategories.join(','),
      'excludedCategories': _preferences.excludedCategories.join(','),
    };

    await _storageService.saveSettings(settings);
  }

  Future<void> resetPreferences() async {
    _preferences = AppPreferences();
    await _savePreferences();
    _preferencesController.add(_preferences);
  }

  AppPreferences get currentPreferences => _preferences;

  void dispose() {
    _preferencesController.close();
  }
}

class AppPreferences {
  // Playback preferences
  final bool autoPlayVideos;
  final String defaultPlaybackQuality;
  final double defaultPlaybackSpeed;
  final bool enablePictureInPicture;
  final bool enableBackgroundPlay;

  // Download preferences
  final String downloadQuality;
  final bool downloadOverWifiOnly;
  final String maxDownloadQuality;

  // Notification preferences
  final bool enableNotifications;
  final bool enableWatchPartyInvites;
  final bool enableNewContentNotifications;
  final bool enableSubscriptionNotifications;

  // Display preferences
  final ThemeMode themeMode;
  final String language;
  final bool subtitlesEnabled;
  final String subtitlesLanguage;
  final double subtitleSize;

  // Social preferences
  final bool showOnlineStatus;
  final bool allowWatchPartyInvites;
  final bool shareWatchHistory;

  // Privacy preferences
  final bool enableAnalytics;
  final bool saveWatchHistory;
  final bool saveSearchHistory;

  // Cache preferences
  final int maxCacheSize;
  final bool autoClearCache;

  // Content preferences
  final String contentMaturityLevel;
  final List<String> preferredCategories;
  final List<String> excludedCategories;

  AppPreferences({
    // Playback defaults
    this.autoPlayVideos = true,
    this.defaultPlaybackQuality = 'Auto',
    this.defaultPlaybackSpeed = 1.0,
    this.enablePictureInPicture = true,
    this.enableBackgroundPlay = false,
    
    // Download defaults
    this.downloadQuality = 'HD',
    this.downloadOverWifiOnly = true,
    this.maxDownloadQuality = '1080p',
    
    // Notification defaults
    this.enableNotifications = true,
    this.enableWatchPartyInvites = true,
    this.enableNewContentNotifications = true,
    this.enableSubscriptionNotifications = true,
    
    // Display defaults
    this.themeMode = ThemeMode.dark,
    this.language = 'English',
    this.subtitlesEnabled = false,
    this.subtitlesLanguage = 'English',
    this.subtitleSize = 16.0,
    
    // Social defaults
    this.showOnlineStatus = true,
    this.allowWatchPartyInvites = true,
    this.shareWatchHistory = false,
    
    // Privacy defaults
    this.enableAnalytics = true,
    this.saveWatchHistory = true,
    this.saveSearchHistory = true,
    
    // Cache defaults
    this.maxCacheSize = AppConstants.maxCacheSize,
    this.autoClearCache = false,
    
    // Content defaults
    this.contentMaturityLevel = 'All',
    this.preferredCategories = const [],
    this.excludedCategories = const [],
  });

  AppPreferences copyWith({
    bool? autoPlayVideos,
    String? defaultPlaybackQuality,
    double? defaultPlaybackSpeed,
    bool? enablePictureInPicture,
    bool? enableBackgroundPlay,
    String? downloadQuality,
    bool? downloadOverWifiOnly,
    String? maxDownloadQuality,
    bool? enableNotifications,
    bool? enableWatchPartyInvites,
    bool? enableNewContentNotifications,
    bool? enableSubscriptionNotifications,
    ThemeMode? themeMode,
    String? language,
    bool? subtitlesEnabled,
    String? subtitlesLanguage,
    double? subtitleSize,
    bool? showOnlineStatus,
    bool? allowWatchPartyInvites,
    bool? shareWatchHistory,
    bool? enableAnalytics,
    bool? saveWatchHistory,
    bool? saveSearchHistory,
    int? maxCacheSize,
    bool? autoClearCache,
    String? contentMaturityLevel,
    List<String>? preferredCategories,
    List<String>? excludedCategories,
  }) {
    return AppPreferences(
      autoPlayVideos: autoPlayVideos ?? this.autoPlayVideos,
      defaultPlaybackQuality: defaultPlaybackQuality ?? this.defaultPlaybackQuality,
      defaultPlaybackSpeed: defaultPlaybackSpeed ?? this.defaultPlaybackSpeed,
      enablePictureInPicture: enablePictureInPicture ?? this.enablePictureInPicture,
      enableBackgroundPlay: enableBackgroundPlay ?? this.enableBackgroundPlay,
      downloadQuality: downloadQuality ?? this.downloadQuality,
      downloadOverWifiOnly: downloadOverWifiOnly ?? this.downloadOverWifiOnly,
      maxDownloadQuality: maxDownloadQuality ?? this.maxDownloadQuality,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enableWatchPartyInvites: enableWatchPartyInvites ?? this.enableWatchPartyInvites,
      enableNewContentNotifications: enableNewContentNotifications ?? this.enableNewContentNotifications,
      enableSubscriptionNotifications: enableSubscriptionNotifications ?? this.enableSubscriptionNotifications,
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      subtitlesEnabled: subtitlesEnabled ?? this.subtitlesEnabled,
      subtitlesLanguage: subtitlesLanguage ?? this.subtitlesLanguage,
      subtitleSize: subtitleSize ?? this.subtitleSize,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      allowWatchPartyInvites: allowWatchPartyInvites ?? this.allowWatchPartyInvites,
      shareWatchHistory: shareWatchHistory ?? this.shareWatchHistory,
      enableAnalytics: enableAnalytics ?? this.enableAnalytics,
      saveWatchHistory: saveWatchHistory ?? this.saveWatchHistory,
      saveSearchHistory: saveSearchHistory ?? this.saveSearchHistory,
      maxCacheSize: maxCacheSize ?? this.maxCacheSize,
      autoClearCache: autoClearCache ?? this.autoClearCache,
      contentMaturityLevel: contentMaturityLevel ?? this.contentMaturityLevel,
      preferredCategories: preferredCategories ?? this.preferredCategories,
      excludedCategories: excludedCategories ?? this.excludedCategories,
    );
  }
}
