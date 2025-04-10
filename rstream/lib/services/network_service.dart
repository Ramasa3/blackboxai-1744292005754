import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../config/constants.dart';
import 'analytics_service.dart';
import 'storage_service.dart';

class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  late Dio _dio;
  final StorageService _storageService = StorageService();
  final AnalyticsService _analyticsService = AnalyticsService();
  final Connectivity _connectivity = Connectivity();
  StreamSubscription? _connectivitySubscription;
  bool _isConnected = true;

  final _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;

  factory NetworkService() {
    return _instance;
  }

  NetworkService._internal() {
    _initializeDio();
  }

  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(milliseconds: AppConstants.apiTimeout),
        receiveTimeout: const Duration(milliseconds: AppConstants.apiTimeout),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );

    // Add cache interceptor
    _dio.interceptors.add(
      _CacheInterceptor(_storageService),
    );
  }

  Future<void> init() async {
    // Initialize connectivity monitoring
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    
    // Check initial connection status
    final result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    _isConnected = result != ConnectivityResult.none;
    _connectionController.add(_isConnected);
  }

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Add auth token if available
    final token = _storageService.getAuthToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // Add API version
    options.headers['X-API-Version'] = AppConstants.apiVersion;

    // Add request timestamp
    options.extra['timestamp'] = DateTime.now();

    return handler.next(options);
  }

  void _onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    // Log response time
    final requestTime = response.requestOptions.extra['timestamp'] as DateTime;
    final responseTime = DateTime.now();
    final duration = responseTime.difference(requestTime);

    _analyticsService.logNetworkRequest(
      endpoint: response.requestOptions.path,
      duration: duration,
      success: true,
    );

    return handler.next(response);
  }

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    // Log error
    final requestTime = error.requestOptions.extra['timestamp'] as DateTime;
    final responseTime = DateTime.now();
    final duration = responseTime.difference(requestTime);

    _analyticsService.logNetworkRequest(
      endpoint: error.requestOptions.path,
      duration: duration,
      success: false,
      errorMessage: error.message,
    );

    // Handle specific error cases
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return handler.reject(
        TimeoutException('Request timed out'),
      );
    }

    if (error.response?.statusCode == 401) {
      // Handle unauthorized access
      _storageService.removeAuthToken();
      // Notify auth service or handle as needed
    }

    return handler.next(error);
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool useCache = false,
    Duration cacheDuration = const Duration(minutes: 5),
  }) async {
    options ??= Options();
    options.extra ??= {};
    options.extra!['use_cache'] = useCache;
    options.extra!['cache_duration'] = cacheDuration;

    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<bool> checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  void cancelAllRequests() {
    _dio.close(force: true);
    _initializeDio();
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _connectionController.close();
    _dio.close(force: true);
  }
}

class _CacheInterceptor extends Interceptor {
  final StorageService _storageService;

  _CacheInterceptor(this._storageService);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.method != 'GET' ||
        options.extra['use_cache'] != true) {
      return handler.next(options);
    }

    final cacheKey = _generateCacheKey(options);
    final cachedData = _storageService.getFromCache(cacheKey);

    if (cachedData != null) {
      return handler.resolve(
        Response(
          requestOptions: options,
          data: cachedData,
          statusCode: 200,
          extra: {'fromCache': true},
        ),
      );
    }

    return handler.next(options);
  }

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    if (response.requestOptions.method != 'GET' ||
        response.requestOptions.extra['use_cache'] != true) {
      return handler.next(response);
    }

    final cacheKey = _generateCacheKey(response.requestOptions);
    final cacheDuration = response.requestOptions.extra['cache_duration'] as Duration;

    await _storageService.saveToCacheWithExpiry(
      cacheKey,
      response.data,
      cacheDuration,
    );

    return handler.next(response);
  }

  String _generateCacheKey(RequestOptions options) {
    return '${options.method}_${options.path}_${options.queryParameters.toString()}';
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() {
    return 'ApiException: $message (Status Code: $statusCode)';
  }
}

class NetworkException implements Exception {
  final String message;
  final DioExceptionType type;

  NetworkException({
    required this.message,
    required this.type,
  });

  @override
  String toString() {
    return 'NetworkException: $message (Type: $type)';
  }
}
