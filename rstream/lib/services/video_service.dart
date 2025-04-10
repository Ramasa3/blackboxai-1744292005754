import 'dart:async';
import 'package:video_player/video_player.dart';
import 'package:wakelock/wakelock.dart';
import '../models/content.dart';
import 'storage_service.dart';
import 'analytics_service.dart';
import 'download_service.dart';

class VideoService {
  static final VideoService _instance = VideoService._internal();
  VideoPlayerController? _controller;
  final StorageService _storageService = StorageService();
  final AnalyticsService _analyticsService = AnalyticsService();
  final DownloadService _downloadService = DownloadService();
  
  bool _isInitialized = false;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _currentContentId;
  Timer? _progressTimer;
  Timer? _bufferingTimer;

  final _stateController = StreamController<VideoState>.broadcast();
  Stream<VideoState> get stateStream => _stateController.stream;

  factory VideoService() {
    return _instance;
  }

  VideoService._internal();

  Future<void> initializePlayer(Content content, {bool autoPlay = true}) async {
    try {
      // Dispose existing controller if any
      await dispose();

      _currentContentId = content.id;
      final url = await _getVideoUrl(content);
      
      _controller = VideoPlayerController.network(url);
      await _controller!.initialize();

      _isInitialized = true;
      _duration = _controller!.value.duration;

      // Restore previous position if any
      final savedPosition = await _getSavedPosition(content.id);
      if (savedPosition != null) {
        await seekTo(savedPosition);
      }

      // Set up listeners
      _setupListeners();

      // Enable wakelock to prevent screen from sleeping
      await Wakelock.enable();

      // Start progress tracking
      _startProgressTracking();

      if (autoPlay) {
        await play();
      }

      _emitCurrentState();
    } catch (e) {
      _analyticsService.logError(
        e,
        StackTrace.current,
        context: 'Initializing video player',
        parameters: {'contentId': content.id},
      );
      rethrow;
    }
  }

  Future<String> _getVideoUrl(Content content) async {
    // Check if content is downloaded
    final downloadedPath = await _downloadService.getDownloadedFilePath(content.id);
    if (downloadedPath != null) {
      return 'file://$downloadedPath';
    }

    // Use streaming URL
    if (content is Movie) {
      return content.streamUrl;
    } else if (content is Episode) {
      return content.streamUrl;
    } else if (content is Channel) {
      return content.streamUrl;
    }
    throw Exception('Unsupported content type');
  }

  void _setupListeners() {
    _controller?.addListener(() {
      final position = _controller?.value.position ?? Duration.zero;
      if (position != _position) {
        _position = position;
        _emitCurrentState();
      }

      // Handle buffering state
      if (_controller?.value.isBuffering ?? false) {
        _startBufferingTimer();
      }
    });
  }

  void _startProgressTracking() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_isPlaying && _currentContentId != null) {
        _saveProgress();
      }
    });
  }

  void _startBufferingTimer() {
    _bufferingTimer?.cancel();
    _bufferingTimer = Timer(const Duration(seconds: 10), () {
      if (_controller?.value.isBuffering ?? false) {
        // Handle long buffering
        _analyticsService.logError(
          'Long buffering period detected',
          StackTrace.current,
          context: 'Video playback',
          parameters: {
            'contentId': _currentContentId,
            'position': _position.inSeconds,
          },
        );
      }
    });
  }

  Future<void> play() async {
    if (!_isInitialized) return;
    await _controller?.play();
    _isPlaying = true;
    _emitCurrentState();
  }

  Future<void> pause() async {
    if (!_isInitialized) return;
    await _controller?.pause();
    _isPlaying = false;
    _emitCurrentState();
    await _saveProgress();
  }

  Future<void> seekTo(Duration position) async {
    if (!_isInitialized) return;
    await _controller?.seekTo(position);
    _position = position;
    _emitCurrentState();
  }

  Future<void> setPlaybackSpeed(double speed) async {
    if (!_isInitialized) return;
    await _controller?.setPlaybackSpeed(speed);
    _emitCurrentState();
  }

  Future<void> setVolume(double volume) async {
    if (!_isInitialized) return;
    await _controller?.setVolume(volume);
    _emitCurrentState();
  }

  Future<void> _saveProgress() async {
    if (_currentContentId == null) return;
    
    await _storageService.saveToCacheWithExpiry(
      'video_progress_${_currentContentId}',
      _position.inSeconds,
      const Duration(days: 30),
    );
  }

  Future<Duration?> _getSavedPosition(String contentId) async {
    final seconds = _storageService.getFromCache('video_progress_$contentId');
    if (seconds != null) {
      return Duration(seconds: seconds as int);
    }
    return null;
  }

  void _emitCurrentState() {
    if (!_stateController.isClosed) {
      _stateController.add(
        VideoState(
          isInitialized: _isInitialized,
          isPlaying: _isPlaying,
          position: _position,
          duration: _duration,
          isBuffering: _controller?.value.isBuffering ?? false,
          volume: _controller?.value.volume ?? 1.0,
          playbackSpeed: _controller?.value.playbackSpeed ?? 1.0,
        ),
      );
    }
  }

  Future<void> dispose() async {
    _progressTimer?.cancel();
    _bufferingTimer?.cancel();
    await _saveProgress();
    await Wakelock.disable();
    await _controller?.dispose();
    _controller = null;
    _isInitialized = false;
    _isPlaying = false;
    _position = Duration.zero;
    _duration = Duration.zero;
    _currentContentId = null;
  }

  void disposeService() {
    _stateController.close();
  }
}

class VideoState {
  final bool isInitialized;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final bool isBuffering;
  final double volume;
  final double playbackSpeed;

  VideoState({
    required this.isInitialized,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.isBuffering,
    required this.volume,
    required this.playbackSpeed,
  });

  double get progress {
    if (duration.inSeconds == 0) return 0;
    return position.inSeconds / duration.inSeconds;
  }

  String get formattedPosition => _formatDuration(position);
  String get formattedDuration => _formatDuration(duration);
  String get formattedRemaining => _formatDuration(duration - position);

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }
}

class VideoException implements Exception {
  final String message;
  final String? contentId;
  final dynamic error;

  VideoException(this.message, {this.contentId, this.error});

  @override
  String toString() {
    return 'VideoException: $message${contentId != null ? ' (Content ID: $contentId)' : ''}';
  }
}
