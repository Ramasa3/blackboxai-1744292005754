import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '../models/content.dart';
import '../config/constants.dart';
import 'storage_service.dart';
import 'analytics_service.dart';

class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  final StorageService _storageService = StorageService();
  final AnalyticsService _analyticsService = AnalyticsService();
  final Map<String, CancelToken> _downloadTokens = {};
  final Map<String, StreamController<double>> _progressControllers = {};
  final _downloadQueueController = StreamController<List<String>>.broadcast();

  Stream<List<String>> get downloadQueue => _downloadQueueController.stream;
  List<String> _currentDownloads = [];

  factory DownloadService() {
    return _instance;
  }

  DownloadService._internal();

  Future<void> init() async {
    // Load any pending downloads from storage
    _currentDownloads = await _loadPendingDownloads();
    _downloadQueueController.add(_currentDownloads);
  }

  Future<List<String>> _loadPendingDownloads() async {
    final downloads = _storageService.getDownloadedContent();
    return downloads
        .where((download) => download['status'] == 'pending')
        .map((download) => download['id'] as String)
        .toList();
  }

  Stream<double> downloadContent({
    required Content content,
    required String quality,
  }) {
    if (_currentDownloads.length >= AppConstants.maxDownloadsPerUser) {
      throw Exception('Maximum download limit reached');
    }

    if (_downloadTokens.containsKey(content.id)) {
      throw Exception('Content is already being downloaded');
    }

    final progressController = StreamController<double>.broadcast();
    _progressControllers[content.id] = progressController;
    _downloadTokens[content.id] = CancelToken();

    _startDownload(content, quality);

    return progressController.stream;
  }

  Future<void> _startDownload(Content content, String quality) async {
    try {
      _currentDownloads.add(content.id);
      _downloadQueueController.add(_currentDownloads);

      _analyticsService.logDownloadStart(
        content: content,
        quality: quality,
      );

      final String url = await _getDownloadUrl(content, quality);
      final String fileName = '${content.id}_$quality.mp4';
      final directory = await _getDownloadDirectory();
      final savePath = '${directory.path}/$fileName';

      final dio = Dio();
      final cancelToken = _downloadTokens[content.id]!;
      final progressController = _progressControllers[content.id]!;

      await dio.download(
        url,
        savePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            progressController.add(progress);
          }
        },
      );

      // Save download info
      await _saveDownloadInfo(content, quality, savePath);

      _analyticsService.logDownloadComplete(
        content: content,
        quality: quality,
        fileSize: await File(savePath).length(),
      );

      progressController.add(1.0);
    } catch (e) {
      _handleDownloadError(content.id, e);
    } finally {
      _cleanupDownload(content.id);
    }
  }

  Future<String> _getDownloadUrl(Content content, String quality) async {
    // Implement URL generation based on content type and quality
    if (content is Movie) {
      return '${content.streamUrl}?quality=$quality';
    } else if (content is Episode) {
      return '${content.streamUrl}?quality=$quality';
    } else {
      throw Exception('Content type does not support downloading');
    }
  }

  Future<Directory> _getDownloadDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final downloadDir = Directory('${directory.path}/downloads');
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    return downloadDir;
  }

  Future<void> _saveDownloadInfo(
    Content content,
    String quality,
    String filePath,
  ) async {
    final downloadInfo = {
      'id': content.id,
      'title': content.title,
      'type': content.type.toString(),
      'quality': quality,
      'filePath': filePath,
      'downloadDate': DateTime.now().toIso8601String(),
      'size': await File(filePath).length(),
      'status': 'completed',
    };

    await _storageService.addDownloadedContent(downloadInfo);
  }

  void _handleDownloadError(String contentId, dynamic error) {
    final progressController = _progressControllers[contentId];
    if (progressController != null && !progressController.isClosed) {
      progressController.addError(error);
    }
  }

  void _cleanupDownload(String contentId) {
    _downloadTokens.remove(contentId);
    _progressControllers[contentId]?.close();
    _progressControllers.remove(contentId);
    _currentDownloads.remove(contentId);
    _downloadQueueController.add(_currentDownloads);
  }

  Future<void> cancelDownload(String contentId) async {
    final cancelToken = _downloadTokens[contentId];
    if (cancelToken != null && !cancelToken.isCancelled) {
      cancelToken.cancel('Download cancelled by user');
    }
  }

  Future<void> pauseDownload(String contentId) async {
    // Implement download pausing logic
  }

  Future<void> resumeDownload(String contentId) async {
    // Implement download resuming logic
  }

  Future<void> deleteDownload(String contentId) async {
    try {
      final downloads = _storageService.getDownloadedContent();
      final download = downloads.firstWhere(
        (d) => d['id'] == contentId,
        orElse: () => throw Exception('Download not found'),
      );

      final filePath = download['filePath'] as String;
      final file = File(filePath);
      
      if (await file.exists()) {
        await file.delete();
      }

      await _storageService.removeDownloadedContent(contentId);
    } catch (e) {
      _analyticsService.logError(
        e,
        StackTrace.current,
        context: 'Deleting download',
        parameters: {'contentId': contentId},
      );
      rethrow;
    }
  }

  Future<void> deleteAllDownloads() async {
    try {
      final downloads = _storageService.getDownloadedContent();
      for (final download in downloads) {
        await deleteDownload(download['id'] as String);
      }
    } catch (e) {
      _analyticsService.logError(
        e,
        StackTrace.current,
        context: 'Deleting all downloads',
      );
      rethrow;
    }
  }

  Future<int> getDownloadSize(String contentId) async {
    try {
      final downloads = _storageService.getDownloadedContent();
      final download = downloads.firstWhere(
        (d) => d['id'] == contentId,
        orElse: () => throw Exception('Download not found'),
      );

      final filePath = download['filePath'] as String;
      final file = File(filePath);
      
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Future<int> getTotalDownloadSize() async {
    try {
      final downloads = _storageService.getDownloadedContent();
      int totalSize = 0;
      
      for (final download in downloads) {
        final filePath = download['filePath'] as String;
        final file = File(filePath);
        
        if (await file.exists()) {
          totalSize += await file.length();
        }
      }
      
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  Future<bool> isContentDownloaded(String contentId) async {
    try {
      final downloads = _storageService.getDownloadedContent();
      final download = downloads.firstWhere(
        (d) => d['id'] == contentId,
        orElse: () => throw Exception('Download not found'),
      );

      final filePath = download['filePath'] as String;
      final file = File(filePath);
      
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  Future<String?> getDownloadedFilePath(String contentId) async {
    try {
      final downloads = _storageService.getDownloadedContent();
      final download = downloads.firstWhere(
        (d) => d['id'] == contentId,
        orElse: () => throw Exception('Download not found'),
      );

      final filePath = download['filePath'] as String;
      final file = File(filePath);
      
      if (await file.exists()) {
        return filePath;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    for (final controller in _progressControllers.values) {
      controller.close();
    }
    _downloadQueueController.close();
  }
}

class DownloadException implements Exception {
  final String message;
  final String? contentId;
  final dynamic error;

  DownloadException(this.message, {this.contentId, this.error});

  @override
  String toString() {
    return 'DownloadException: $message${contentId != null ? ' (Content ID: $contentId)' : ''}';
  }
}
