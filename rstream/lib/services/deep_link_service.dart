import 'dart:async';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:uni_links/uni_links.dart';
import '../config/constants.dart';
import 'analytics_service.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  final FirebaseDynamicLinks _dynamicLinks = FirebaseDynamicLinks.instance;
  final AnalyticsService _analyticsService = AnalyticsService();
  
  StreamSubscription? _dynamicLinkSubscription;
  StreamSubscription? _uniLinkSubscription;
  
  final _deepLinkController = StreamController<DeepLinkData>.broadcast();
  Stream<DeepLinkData> get deepLinkStream => _deepLinkController.stream;

  factory DeepLinkService() {
    return _instance;
  }

  DeepLinkService._internal();

  Future<void> init() async {
    // Handle initial dynamic link
    final initialLink = await _dynamicLinks.getInitialLink();
    if (initialLink != null) {
      _handleDynamicLink(initialLink);
    }

    // Listen for dynamic links while app is running
    _dynamicLinkSubscription = _dynamicLinks.onLink.listen(
      _handleDynamicLink,
      onError: (error) {
        _analyticsService.logError(
          error,
          StackTrace.current,
          context: 'Dynamic link listener',
        );
      },
    );

    // Handle initial uni links
    try {
      final initialUniLink = await getInitialLink();
      if (initialUniLink != null) {
        _handleUniLink(initialUniLink);
      }
    } catch (e) {
      _analyticsService.logError(
        e,
        StackTrace.current,
        context: 'Initial uni link',
      );
    }

    // Listen for uni links while app is running
    _uniLinkSubscription = uriLinkStream.listen(
      _handleUniLink,
      onError: (error) {
        _analyticsService.logError(
          error,
          StackTrace.current,
          context: 'Uni link listener',
        );
      },
    );
  }

  void _handleDynamicLink(PendingDynamicLinkData data) {
    final deepLink = data.link;
    final deepLinkData = _parseDeepLink(deepLink);
    
    if (deepLinkData != null) {
      _analyticsService.logEvent(
        name: 'deep_link_opened',
        parameters: {
          'type': deepLinkData.type,
          'id': deepLinkData.id,
          'source': 'dynamic_link',
        },
      );
      
      _deepLinkController.add(deepLinkData);
    }
  }

  void _handleUniLink(Uri uri) {
    final deepLinkData = _parseDeepLink(uri);
    
    if (deepLinkData != null) {
      _analyticsService.logEvent(
        name: 'deep_link_opened',
        parameters: {
          'type': deepLinkData.type,
          'id': deepLinkData.id,
          'source': 'uni_link',
        },
      );
      
      _deepLinkController.add(deepLinkData);
    }
  }

  DeepLinkData? _parseDeepLink(Uri uri) {
    final pathSegments = uri.pathSegments;
    
    if (pathSegments.isEmpty) return null;

    final type = pathSegments[0];
    String? id;
    Map<String, String> params = {};

    if (pathSegments.length > 1) {
      id = pathSegments[1];
    }

    uri.queryParameters.forEach((key, value) {
      params[key] = value;
    });

    switch (type) {
      case 'content':
        return DeepLinkData(
          type: DeepLinkType.content,
          id: id!,
          params: params,
        );
      
      case 'watch-party':
        return DeepLinkData(
          type: DeepLinkType.watchParty,
          id: id!,
          params: params,
        );
      
      case 'profile':
        return DeepLinkData(
          type: DeepLinkType.profile,
          id: id!,
          params: params,
        );
      
      case 'category':
        return DeepLinkData(
          type: DeepLinkType.category,
          id: id ?? params['name'] ?? '',
          params: params,
        );
      
      default:
        return null;
    }
  }

  Future<Uri> createDynamicLink({
    required DeepLinkType type,
    required String id,
    Map<String, String>? params,
    bool short = true,
  }) async {
    final path = '${type.toString().split('.').last}/$id';
    final dynamicLinkParams = DynamicLinkParameters(
      uriPrefix: AppConstants.dynamicLinkPrefix,
      link: Uri.parse('${AppConstants.appScheme}://$path'),
      androidParameters: const AndroidParameters(
        packageName: AppConstants.androidPackageName,
        minimumVersion: 1,
      ),
      iosParameters: const IOSParameters(
        bundleId: AppConstants.iosBundleId,
        minimumVersion: '1.0.0',
        appStoreId: AppConstants.appStoreId,
      ),
      socialMetaTagParameters: SocialMetaTagParameters(
        title: _getShareTitle(type, id),
        description: _getShareDescription(type, id),
        imageUrl: Uri.parse(_getShareImageUrl(type, id)),
      ),
    );

    if (short) {
      final shortLink = await _dynamicLinks.buildShortLink(dynamicLinkParams);
      return shortLink.shortUrl;
    } else {
      return await _dynamicLinks.buildLink(dynamicLinkParams);
    }
  }

  String _getShareTitle(DeepLinkType type, String id) {
    switch (type) {
      case DeepLinkType.content:
        return 'Check out this content on RStream';
      case DeepLinkType.watchParty:
        return 'Join my Watch Party on RStream';
      case DeepLinkType.profile:
        return 'Check out my profile on RStream';
      case DeepLinkType.category:
        return 'Explore $id on RStream';
      default:
        return 'RStream';
    }
  }

  String _getShareDescription(DeepLinkType type, String id) {
    switch (type) {
      case DeepLinkType.content:
        return 'Watch amazing content on RStream';
      case DeepLinkType.watchParty:
        return 'Watch together with friends on RStream';
      case DeepLinkType.profile:
        return 'Connect with me on RStream';
      case DeepLinkType.category:
        return 'Discover more $id content on RStream';
      default:
        return 'Stream your favorite content';
    }
  }

  String _getShareImageUrl(DeepLinkType type, String id) {
    // Replace with actual image URLs based on content type
    return '${AppConstants.apiBaseUrl}/share/${type.toString().split('.').last}/$id/image';
  }

  void dispose() {
    _dynamicLinkSubscription?.cancel();
    _uniLinkSubscription?.cancel();
    _deepLinkController.close();
  }
}

enum DeepLinkType {
  content,
  watchParty,
  profile,
  category,
}

class DeepLinkData {
  final DeepLinkType type;
  final String id;
  final Map<String, String> params;

  DeepLinkData({
    required this.type,
    required this.id,
    this.params = const {},
  });

  @override
  String toString() {
    return 'DeepLinkData{type: $type, id: $id, params: $params}';
  }
}

class DeepLinkException implements Exception {
  final String message;
  final dynamic error;

  DeepLinkException(this.message, {this.error});

  @override
  String toString() {
    return 'DeepLinkException: $message';
  }
}
