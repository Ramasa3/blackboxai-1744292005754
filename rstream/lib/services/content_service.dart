import 'dart:async';
import '../models/content.dart';
import '../config/constants.dart';
import 'network_service.dart';
import 'storage_service.dart';
import 'database_service.dart';
import 'analytics_service.dart';
import 'error_service.dart';

class ContentService {
  static final ContentService _instance = ContentService._internal();
  final NetworkService _networkService = NetworkService();
  final StorageService _storageService = StorageService();
  final DatabaseService _databaseService = DatabaseService();
  final AnalyticsService _analyticsService = AnalyticsService();
  final ErrorService _errorService = ErrorService();

  final _contentController = StreamController<ContentState>.broadcast();
  Stream<ContentState> get contentStream => _contentController.stream;

  final _watchHistoryController = StreamController<List<Content>>.broadcast();
  Stream<List<Content>> get watchHistoryStream => _watchHistoryController.stream;

  final _recommendationsController = StreamController<List<Content>>.broadcast();
  Stream<List<Content>> get recommendationsStream => _recommendationsController.stream;

  factory ContentService() {
    return _instance;
  }

  ContentService._internal();

  Future<void> init() async {
    // Load initial watch history
    await _loadWatchHistory();
    
    // Start periodic content updates
    _startPeriodicUpdates();
  }

  void _startPeriodicUpdates() {
    Timer.periodic(const Duration(minutes: 15), (_) {
      _updateContentCatalog();
    });
  }

  Future<void> _updateContentCatalog() async {
    try {
      final lastUpdate = _storageService.getFromCache('last_content_update');
      if (lastUpdate != null) {
        final response = await _networkService.get(
          '/api/content/updates',
          queryParameters: {'since': lastUpdate},
        );

        final updates = response.data['updates'] as List;
        if (updates.isNotEmpty) {
          await _processContentUpdates(updates);
        }
      }

      await _storageService.saveToCacheWithExpiry(
        'last_content_update',
        DateTime.now().toIso8601String(),
        const Duration(days: 1),
      );
    } catch (e, s) {
      await _errorService.reportHandledException(
        e,
        s,
        context: 'Updating content catalog',
      );
    }
  }

  Future<void> _processContentUpdates(List<dynamic> updates) async {
    for (final update in updates) {
      final content = Content.fromMap(update['content']);
      final action = update['action'];

      switch (action) {
        case 'add':
        case 'update':
          await _databaseService.saveContent(content);
          break;
        case 'delete':
          await _databaseService.deleteContent(content.id);
          break;
      }
    }
  }

  Future<List<Content>> getMovies({
    List<String>? categories,
    bool? isHdOnly,
    String? sortBy,
    int page = 1,
    String? searchQuery,
  }) async {
    try {
      final response = await _networkService.get(
        '/api/movies',
        queryParameters: {
          if (categories != null) 'categories': categories.join(','),
          if (isHdOnly != null) 'hd_only': isHdOnly,
          if (sortBy != null) 'sort_by': sortBy,
          'page': page,
          if (searchQuery != null) 'query': searchQuery,
        },
        useCache: true,
        cacheDuration: const Duration(minutes: 30),
      );

      final movies = (response.data['items'] as List)
          .map((item) => Content.fromMap(item))
          .toList();

      await _databaseService.saveContentBatch(movies);
      return movies;
    } catch (e) {
      // Try to get from local database if network request fails
      return _databaseService.getContentByType(ContentType.movie);
    }
  }

  Future<List<Content>> getSeries({
    List<String>? categories,
    bool? isHdOnly,
    String? sortBy,
    int page = 1,
    String? searchQuery,
  }) async {
    try {
      final response = await _networkService.get(
        '/api/series',
        queryParameters: {
          if (categories != null) 'categories': categories.join(','),
          if (isHdOnly != null) 'hd_only': isHdOnly,
          if (sortBy != null) 'sort_by': sortBy,
          'page': page,
          if (searchQuery != null) 'query': searchQuery,
        },
        useCache: true,
        cacheDuration: const Duration(minutes: 30),
      );

      final series = (response.data['items'] as List)
          .map((item) => Content.fromMap(item))
          .toList();

      await _databaseService.saveContentBatch(series);
      return series;
    } catch (e) {
      return _databaseService.getContentByType(ContentType.series);
    }
  }

  Future<List<Content>> getChannels({
    List<String>? categories,
    bool? isHdOnly,
    String? sortBy,
    String? searchQuery,
  }) async {
    try {
      final response = await _networkService.get(
        '/api/channels',
        queryParameters: {
          if (categories != null) 'categories': categories.join(','),
          if (isHdOnly != null) 'hd_only': isHdOnly,
          if (sortBy != null) 'sort_by': sortBy,
          if (searchQuery != null) 'query': searchQuery,
        },
        useCache: true,
        cacheDuration: const Duration(minutes: 5),
      );

      return (response.data['items'] as List)
          .map((item) => Content.fromMap(item))
          .toList();
    } catch (e) {
      return _databaseService.getContentByType(ContentType.channel);
    }
  }

  Future<Content> getContentDetails(String contentId) async {
    try {
      // Try to get from local database first
      final localContent = await _databaseService.getContent(contentId);
      if (localContent != null) return localContent;

      final response = await _networkService.get(
        '/api/content/$contentId',
        useCache: true,
        cacheDuration: const Duration(hours: 1),
      );

      final content = Content.fromMap(response.data);
      await _databaseService.saveContent(content);
      return content;
    } catch (e, s) {
      await _errorService.reportHandledException(
        e,
        s,
        context: 'Getting content details',
        parameters: {'contentId': contentId},
      );
      rethrow;
    }
  }

  Future<void> updateWatchProgress(
    String contentId,
    Duration position, {
    bool completed = false,
  }) async {
    try {
      await _networkService.post(
        '/api/watch-progress',
        data: {
          'content_id': contentId,
          'position': position.inSeconds,
          'completed': completed,
        },
      );

      await _databaseService.saveWatchHistory(
        'current_user_id', // Replace with actual user ID
        contentId,
        position,
      );

      await _loadWatchHistory();
    } catch (e, s) {
      await _errorService.reportHandledException(
        e,
        s,
        context: 'Updating watch progress',
        parameters: {
          'contentId': contentId,
          'position': position.inSeconds,
        },
      );
    }
  }

  Future<void> _loadWatchHistory() async {
    try {
      final history = await _databaseService.getWatchHistory('current_user_id');
      final contents = await Future.wait(
        history.map((item) => getContentDetails(item['content_id'] as String)),
      );
      _watchHistoryController.add(contents);
    } catch (e) {
      _watchHistoryController.add([]);
    }
  }

  Future<List<Content>> getRecommendations(String contentId) async {
    try {
      final response = await _networkService.get(
        '/api/recommendations/$contentId',
        useCache: true,
        cacheDuration: const Duration(hours: 1),
      );

      final recommendations = (response.data['items'] as List)
          .map((item) => Content.fromMap(item))
          .toList();

      _recommendationsController.add(recommendations);
      return recommendations;
    } catch (e) {
      return [];
    }
  }

  Future<String> getStreamUrl(Content content) async {
    try {
      final response = await _networkService.get(
        '/api/content/${content.id}/stream',
      );

      return response.data['url'] as String;
    } catch (e, s) {
      await _errorService.reportHandledException(
        e,
        s,
        context: 'Getting stream URL',
        parameters: {'contentId': content.id},
      );
      rethrow;
    }
  }

  void dispose() {
    _contentController.close();
    _watchHistoryController.close();
    _recommendationsController.close();
  }
}

class ContentState {
  final List<Content> items;
  final bool isLoading;
  final String? error;

  ContentState({
    required this.items,
    this.isLoading = false,
    this.error,
  });

  factory ContentState.loading() {
    return ContentState(
      items: [],
      isLoading: true,
    );
  }

  factory ContentState.error(String message) {
    return ContentState(
      items: [],
      error: message,
    );
  }

  factory ContentState.success(List<Content> items) {
    return ContentState(items: items);
  }
}

class ContentException implements Exception {
  final String message;
  final dynamic error;

  ContentException(this.message, {this.error});

  @override
  String toString() {
    return 'ContentException: $message${error != null ? ' ($error)' : ''}';
  }
}
