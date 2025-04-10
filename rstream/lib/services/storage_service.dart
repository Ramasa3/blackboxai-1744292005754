import 'dart:convert';
import 'package:shared_preferences.dart';
import '../config/constants.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  late SharedPreferences _prefs;
  
  // Storage keys
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _settingsKey = 'app_settings';
  static const String _recentSearchesKey = 'recent_searches';
  static const String _watchHistoryKey = 'watch_history';
  static const String _downloadedContentKey = 'downloaded_content';
  static const String _watchlistKey = 'watchlist';
  static const String _themeKey = 'app_theme';
  static const String _languageKey = 'app_language';
  static const String _qualityKey = 'video_quality';

  factory StorageService() {
    return _instance;
  }

  StorageService._internal();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Authentication
  Future<void> saveAuthToken(String token) async {
    await _prefs.setString(_tokenKey, token);
  }

  String? getAuthToken() {
    return _prefs.getString(_tokenKey);
  }

  Future<void> removeAuthToken() async {
    await _prefs.remove(_tokenKey);
  }

  // User Data
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _prefs.setString(_userKey, jsonEncode(userData));
  }

  Map<String, dynamic>? getUserData() {
    final data = _prefs.getString(_userKey);
    if (data != null) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return null;
  }

  Future<void> removeUserData() async {
    await _prefs.remove(_userKey);
  }

  // App Settings
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    await _prefs.setString(_settingsKey, jsonEncode(settings));
  }

  Map<String, dynamic> getSettings() {
    final data = _prefs.getString(_settingsKey);
    if (data != null) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return {
      'autoPlayVideos': true,
      'enableNotifications': true,
      'enableWatchPartyInvites': true,
      'streamingQuality': 'Auto',
      'downloadQuality': 'HD',
      'language': 'English',
      'theme': 'dark',
    };
  }

  // Recent Searches
  Future<void> saveRecentSearches(List<String> searches) async {
    await _prefs.setStringList(_recentSearchesKey, searches);
  }

  List<String> getRecentSearches() {
    return _prefs.getStringList(_recentSearchesKey) ?? [];
  }

  Future<void> addRecentSearch(String search) async {
    final searches = getRecentSearches();
    if (!searches.contains(search)) {
      searches.insert(0, search);
      if (searches.length > 10) {
        searches.removeLast();
      }
      await saveRecentSearches(searches);
    }
  }

  Future<void> clearRecentSearches() async {
    await _prefs.remove(_recentSearchesKey);
  }

  // Watch History
  Future<void> saveWatchHistory(List<Map<String, dynamic>> history) async {
    await _prefs.setString(_watchHistoryKey, jsonEncode(history));
  }

  List<Map<String, dynamic>> getWatchHistory() {
    final data = _prefs.getString(_watchHistoryKey);
    if (data != null) {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<void> addToWatchHistory(Map<String, dynamic> content) async {
    final history = getWatchHistory();
    history.removeWhere((item) => item['id'] == content['id']);
    history.insert(0, content);
    if (history.length > 100) {
      history.removeLast();
    }
    await saveWatchHistory(history);
  }

  Future<void> clearWatchHistory() async {
    await _prefs.remove(_watchHistoryKey);
  }

  // Downloaded Content
  Future<void> saveDownloadedContent(List<Map<String, dynamic>> content) async {
    await _prefs.setString(_downloadedContentKey, jsonEncode(content));
  }

  List<Map<String, dynamic>> getDownloadedContent() {
    final data = _prefs.getString(_downloadedContentKey);
    if (data != null) {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<void> addDownloadedContent(Map<String, dynamic> content) async {
    final downloads = getDownloadedContent();
    if (downloads.length >= AppConstants.maxDownloadsPerUser) {
      throw Exception('Maximum download limit reached');
    }
    downloads.add(content);
    await saveDownloadedContent(downloads);
  }

  Future<void> removeDownloadedContent(String contentId) async {
    final downloads = getDownloadedContent();
    downloads.removeWhere((item) => item['id'] == contentId);
    await saveDownloadedContent(downloads);
  }

  // Watchlist
  Future<void> saveWatchlist(List<String> contentIds) async {
    await _prefs.setStringList(_watchlistKey, contentIds);
  }

  List<String> getWatchlist() {
    return _prefs.getStringList(_watchlistKey) ?? [];
  }

  Future<void> addToWatchlist(String contentId) async {
    final watchlist = getWatchlist();
    if (!watchlist.contains(contentId)) {
      watchlist.add(contentId);
      await saveWatchlist(watchlist);
    }
  }

  Future<void> removeFromWatchlist(String contentId) async {
    final watchlist = getWatchlist();
    watchlist.remove(contentId);
    await saveWatchlist(watchlist);
  }

  // Theme
  Future<void> saveTheme(String theme) async {
    await _prefs.setString(_themeKey, theme);
  }

  String getTheme() {
    return _prefs.getString(_themeKey) ?? 'dark';
  }

  // Language
  Future<void> saveLanguage(String language) async {
    await _prefs.setString(_languageKey, language);
  }

  String getLanguage() {
    return _prefs.getString(_languageKey) ?? 'English';
  }

  // Video Quality
  Future<void> saveVideoQuality(String quality) async {
    await _prefs.setString(_qualityKey, quality);
  }

  String getVideoQuality() {
    return _prefs.getString(_qualityKey) ?? 'Auto';
  }

  // Clear All Data
  Future<void> clearAll() async {
    await _prefs.clear();
  }

  // Check if First Launch
  bool isFirstLaunch() {
    return _prefs.getBool('first_launch') ?? true;
  }

  Future<void> setFirstLaunch(bool value) async {
    await _prefs.setBool('first_launch', value);
  }

  // Cache Management
  Future<void> saveToCacheWithExpiry(
    String key,
    dynamic value,
    Duration expiry,
  ) async {
    final data = {
      'value': value,
      'expiry': DateTime.now().add(expiry).millisecondsSinceEpoch,
    };
    await _prefs.setString('cache_$key', jsonEncode(data));
  }

  dynamic getFromCache(String key) {
    final data = _prefs.getString('cache_$key');
    if (data != null) {
      final decoded = jsonDecode(data);
      final expiry = DateTime.fromMillisecondsSinceEpoch(decoded['expiry']);
      if (DateTime.now().isBefore(expiry)) {
        return decoded['value'];
      } else {
        _prefs.remove('cache_$key');
      }
    }
    return null;
  }

  Future<void> clearCache() async {
    final keys = _prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('cache_')) {
        await _prefs.remove(key);
      }
    }
  }
}
