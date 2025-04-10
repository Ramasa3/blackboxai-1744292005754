class AppConstants {
  // App Information
  static const String appName = 'RStream';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
  
  // API Configuration
  static const String apiBaseUrl = 'https://api.rstream.com';
  static const int apiTimeout = 30000; // milliseconds
  static const String apiVersion = 'v1';
  
  // WebSocket Configuration
  static const String wsBaseUrl = 'wss://ws.rstream.com';
  static const int wsReconnectDelay = 5000; // milliseconds
  static const int wsHeartbeatInterval = 30000; // milliseconds
  
  // Cache Configuration
  static const int maxCacheSize = 100 * 1024 * 1024; // 100 MB
  static const Duration cacheDuration = Duration(days: 7);
  
  // Content Configuration
  static const int maxDownloadsPerUser = 10;
  static const List<String> supportedVideoFormats = [
    'mp4',
    'mkv',
    'webm',
    'm3u8',
  ];
  
  static const List<String> movieCategories = [
    'Action',
    'Adventure',
    'Animation',
    'Comedy',
    'Crime',
    'Documentary',
    'Drama',
    'Family',
    'Fantasy',
    'Horror',
    'Mystery',
    'Romance',
    'Sci-Fi',
    'Thriller',
    'War',
    'Western',
  ];
  
  static const List<String> seriesCategories = [
    'Action & Adventure',
    'Animation',
    'Comedy',
    'Crime',
    'Documentary',
    'Drama',
    'Family',
    'Kids',
    'Mystery',
    'Reality',
    'Sci-Fi & Fantasy',
    'Soap',
    'Talk',
    'War & Politics',
    'Western',
  ];
  
  static const List<String> channelCategories = [
    'Entertainment',
    'News',
    'Sports',
    'Movies',
    'Music',
    'Kids',
    'Documentary',
    'Lifestyle',
    'Education',
    'Religious',
  ];

  // Watch Party Configuration
  static const int maxWatchPartySize = 10;
  static const Duration maxPlaybackDelay = Duration(milliseconds: 1000);
  static const Duration syncThreshold = Duration(milliseconds: 2000);
  static const int maxChatMessagesStored = 100;
  
  // Subscription Configuration
  static const Map<String, dynamic> subscriptionPlans = {
    'free': {
      'name': 'Free',
      'price': 0.0,
      'features': [
        'Limited content access',
        'SD quality',
        'Single device',
        'Ad-supported',
      ],
    },
    'basic': {
      'name': 'Basic',
      'price': 9.99,
      'features': [
        'Full content access',
        'HD quality',
        'Single device',
        'Ad-free',
      ],
    },
    'standard': {
      'name': 'Standard',
      'price': 14.99,
      'features': [
        'Full content access',
        'Full HD quality',
        'Two devices',
        'Ad-free',
        'Download content',
        'Watch party',
      ],
    },
    'premium': {
      'name': 'Premium',
      'price': 19.99,
      'features': [
        'Full content access',
        '4K Ultra HD quality',
        'Four devices',
        'Ad-free',
        'Download content',
        'Watch party',
        'Priority support',
        'Early access',
      ],
    },
  };

  // Video Quality Settings
  static const Map<String, Map<String, dynamic>> videoQualities = {
    'auto': {
      'name': 'Auto',
      'resolution': 'Adaptive',
      'bitrate': 'Adaptive',
    },
    '4k': {
      'name': '4K Ultra HD',
      'resolution': '3840x2160',
      'bitrate': '15-20 Mbps',
    },
    '1080p': {
      'name': 'Full HD',
      'resolution': '1920x1080',
      'bitrate': '8-10 Mbps',
    },
    '720p': {
      'name': 'HD',
      'resolution': '1280x720',
      'bitrate': '5-7 Mbps',
    },
    '480p': {
      'name': 'SD',
      'resolution': '854x480',
      'bitrate': '2-4 Mbps',
    },
  };

  // Error Messages
  static const Map<String, String> errorMessages = {
    'network_error': 'Network connection error. Please check your internet connection.',
    'server_error': 'Server error. Please try again later.',
    'auth_error': 'Authentication error. Please log in again.',
    'subscription_error': 'Subscription error. Please check your subscription status.',
    'playback_error': 'Playback error. Please try again.',
    'download_error': 'Download error. Please try again.',
    'storage_error': 'Storage error. Please free up space and try again.',
  };

  // Analytics Events
  static const Map<String, String> analyticsEvents = {
    'app_open': 'App Opened',
    'user_login': 'User Login',
    'user_register': 'User Registration',
    'content_view': 'Content Viewed',
    'content_play': 'Content Played',
    'content_complete': 'Content Completed',
    'subscription_start': 'Subscription Started',
    'subscription_cancel': 'Subscription Cancelled',
    'watch_party_create': 'Watch Party Created',
    'watch_party_join': 'Watch Party Joined',
    'download_start': 'Download Started',
    'download_complete': 'Download Completed',
    'search_perform': 'Search Performed',
  };

  // Support Information
  static const String supportEmail = 'support@rstream.com';
  static const String supportPhone = '+1-800-RSTREAM';
  static const String supportWebsite = 'https://support.rstream.com';
  static const String supportHours = '24/7';

  // Legal Information
  static const String termsUrl = 'https://rstream.com/terms';
  static const String privacyUrl = 'https://rstream.com/privacy';
  static const String copyrightText = '© 2023 RStream. All rights reserved.';

  // Social Media Links
  static const Map<String, String> socialMediaLinks = {
    'facebook': 'https://facebook.com/rstream',
    'twitter': 'https://twitter.com/rstream',
    'instagram': 'https://instagram.com/rstream',
    'youtube': 'https://youtube.com/rstream',
  };

  // App Store Links
  static const String appStoreUrl = 'https://apps.apple.com/app/rstream';
  static const String playStoreUrl = 'https://play.google.com/store/apps/rstream';

  // Feature Flags
  static const Map<String, bool> featureFlags = {
    'enable_downloads': true,
    'enable_watch_party': true,
    'enable_chat': true,
    'enable_notifications': true,
    'enable_picture_in_picture': true,
    'enable_background_play': true,
    'enable_offline_mode': true,
    'enable_social_features': true,
    'enable_analytics': true,
  };
}
