import 'dart:async';
import '../models/content.dart';
import '../config/constants.dart';
import 'storage_service.dart';
import 'network_service.dart';
import 'analytics_service.dart';
import 'database_service.dart';

class SearchService {
  static final SearchService _instance = SearchService._internal();
  final StorageService _storageService = StorageService();
  final NetworkService _networkService = NetworkService();
  final AnalyticsService _analyticsService = AnalyticsService();
  final DatabaseService _databaseService = DatabaseService();

  final _searchResultsController = StreamController<SearchResults>.broadcast();
  Stream<SearchResults> get searchResultsStream => _searchResultsController.stream;

  final _searchHistoryController = StreamController<List<String>>.broadcast();
  Stream<List<String>> get searchHistoryStream => _searchHistoryController.stream;

  Timer? _debounceTimer;
  String _lastQuery = '';
  bool _isSearching = false;

  factory SearchService() {
    return _instance;
  }

  SearchService._internal();

  Future<void> init() async {
    // Load initial search history
    final history = _storageService.getRecentSearches();
    _searchHistoryController.add(history);
  }

  Future<void> search(
    String query, {
    List<ContentType>? types,
    List<String>? categories,
    bool? isHdOnly,
    String? sortBy,
    bool useCache = true,
  }) async {
    if (query == _lastQuery && _isSearching) return;
    _lastQuery = query;

    // Cancel previous debounce timer
    _debounceTimer?.cancel();

    // Clear results if query is empty
    if (query.isEmpty) {
      _searchResultsController.add(SearchResults.empty());
      return;
    }

    // Debounce search
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        _isSearching = true;
        _searchResultsController.add(SearchResults.loading());

        // Check cache first
        if (useCache) {
          final cachedResults = await _getCachedResults(query);
          if (cachedResults != null) {
            _searchResultsController.add(cachedResults);
            return;
          }
        }

        // Perform API search
        final results = await _performSearch(
          query,
          types: types,
          categories: categories,
          isHdOnly: isHdOnly,
          sortBy: sortBy,
        );

        // Save to search history
        if (results.totalResults > 0) {
          await _saveToSearchHistory(query);
        }

        // Cache results
        await _cacheResults(query, results);

        // Log search analytics
        _analyticsService.logSearch(
          query: query,
          resultCount: results.totalResults,
        );

        _searchResultsController.add(results);
      } catch (e) {
        _searchResultsController.add(SearchResults.error(e.toString()));
      } finally {
        _isSearching = false;
      }
    });
  }

  Future<SearchResults?> _getCachedResults(String query) async {
    final cached = _storageService.getFromCache('search_$query');
    if (cached != null) {
      return SearchResults.fromMap(cached as Map<String, dynamic>);
    }
    return null;
  }

  Future<void> _cacheResults(String query, SearchResults results) async {
    await _storageService.saveToCacheWithExpiry(
      'search_$query',
      results.toMap(),
      const Duration(hours: 1),
    );
  }

  Future<SearchResults> _performSearch(
    String query, {
    List<ContentType>? types,
    List<String>? categories,
    bool? isHdOnly,
    String? sortBy,
  }) async {
    try {
      final response = await _networkService.get(
        '/api/search',
        queryParameters: {
          'query': query,
          if (types != null) 'types': types.map((t) => t.toString()).join(','),
          if (categories != null) 'categories': categories.join(','),
          if (isHdOnly != null) 'hd_only': isHdOnly,
          if (sortBy != null) 'sort_by': sortBy,
        },
      );

      final results = SearchResults.fromMap(response.data);

      // Save results to local database for offline access
      await _saveResultsToDatabase(results);

      return results;
    } catch (e) {
      // Try to get results from local database if network request fails
      return await _getOfflineResults(query);
    }
  }

  Future<void> _saveResultsToDatabase(SearchResults results) async {
    await _databaseService.saveContentBatch(results.items);
  }

  Future<SearchResults> _getOfflineResults(String query) async {
    try {
      final results = await _databaseService.searchContent(query);
      return SearchResults(
        items: results,
        totalResults: results.length,
        page: 1,
        totalPages: 1,
        isOffline: true,
      );
    } catch (e) {
      throw SearchException('Failed to get offline results: $e');
    }
  }

  Future<void> _saveToSearchHistory(String query) async {
    if (!_storageService.getSettings()['saveSearchHistory']) return;

    await _storageService.addRecentSearch(query);
    final history = _storageService.getRecentSearches();
    _searchHistoryController.add(history);
  }

  Future<List<String>> getSearchSuggestions(String query) async {
    if (query.isEmpty) return [];

    try {
      final response = await _networkService.get(
        '/api/search/suggestions',
        queryParameters: {'query': query},
        useCache: true,
        cacheDuration: const Duration(hours: 24),
      );

      return List<String>.from(response.data['suggestions']);
    } catch (e) {
      // Return empty list if request fails
      return [];
    }
  }

  Future<void> clearSearchHistory() async {
    await _storageService.clearRecentSearches();
    _searchHistoryController.add([]);
  }

  Future<void> removeFromSearchHistory(String query) async {
    final history = _storageService.getRecentSearches();
    history.remove(query);
    await _storageService.saveRecentSearches(history);
    _searchHistoryController.add(history);
  }

  void cancelSearch() {
    _debounceTimer?.cancel();
    _isSearching = false;
    _searchResultsController.add(SearchResults.empty());
  }

  void dispose() {
    _debounceTimer?.cancel();
    _searchResultsController.close();
    _searchHistoryController.close();
  }
}

class SearchResults {
  final List<Content> items;
  final int totalResults;
  final int page;
  final int totalPages;
  final bool isLoading;
  final String? error;
  final bool isOffline;

  SearchResults({
    required this.items,
    required this.totalResults,
    required this.page,
    required this.totalPages,
    this.isLoading = false,
    this.error,
    this.isOffline = false,
  });

  factory SearchResults.empty() {
    return SearchResults(
      items: [],
      totalResults: 0,
      page: 1,
      totalPages: 1,
    );
  }

  factory SearchResults.loading() {
    return SearchResults(
      items: [],
      totalResults: 0,
      page: 1,
      totalPages: 1,
      isLoading: true,
    );
  }

  factory SearchResults.error(String message) {
    return SearchResults(
      items: [],
      totalResults: 0,
      page: 1,
      totalPages: 1,
      error: message,
    );
  }

  factory SearchResults.fromMap(Map<String, dynamic> map) {
    return SearchResults(
      items: (map['items'] as List)
          .map((item) => Content.fromMap(item))
          .toList(),
      totalResults: map['total_results'] ?? 0,
      page: map['page'] ?? 1,
      totalPages: map['total_pages'] ?? 1,
      isOffline: map['is_offline'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'items': items.map((item) => item.toMap()).toList(),
      'total_results': totalResults,
      'page': page,
      'total_pages': totalPages,
      'is_offline': isOffline,
    };
  }

  bool get hasMore => page < totalPages;
  bool get isEmpty => items.isEmpty && !isLoading && error == null;
  bool get hasError => error != null;
}

class SearchException implements Exception {
  final String message;
  final dynamic error;

  SearchException(this.message, {this.error});

  @override
  String toString() {
    return 'SearchException: $message${error != null ? ' ($error)' : ''}';
  }
}
