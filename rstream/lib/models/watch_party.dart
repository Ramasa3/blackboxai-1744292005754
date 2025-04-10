import 'dart:convert';

class WatchParty {
  final String id;
  final String hostId;
  final String contentId;
  final ContentInfo contentInfo;
  final List<PartyMember> members;
  final List<ChatMessage> chatHistory;
  final DateTime createdAt;
  final WatchPartyStatus status;
  final PlaybackState playbackState;
  final Map<String, dynamic>? settings;

  WatchParty({
    required this.id,
    required this.hostId,
    required this.contentId,
    required this.contentInfo,
    required this.members,
    required this.chatHistory,
    required this.createdAt,
    required this.status,
    required this.playbackState,
    this.settings,
  });

  factory WatchParty.fromJson(Map<String, dynamic> json) {
    return WatchParty(
      id: json['id'] as String,
      hostId: json['host_id'] as String,
      contentId: json['content_id'] as String,
      contentInfo: ContentInfo.fromJson(json['content_info'] as Map<String, dynamic>),
      members: (json['members'] as List)
          .map((member) => PartyMember.fromJson(member as Map<String, dynamic>))
          .toList(),
      chatHistory: (json['chat_history'] as List)
          .map((message) => ChatMessage.fromJson(message as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      status: WatchPartyStatus.values.firstWhere(
        (status) => status.toString().split('.').last == json['status'],
        orElse: () => WatchPartyStatus.active,
      ),
      playbackState: PlaybackState.fromJson(json['playback_state'] as Map<String, dynamic>),
      settings: json['settings'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'host_id': hostId,
      'content_id': contentId,
      'content_info': contentInfo.toJson(),
      'members': members.map((member) => member.toJson()).toList(),
      'chat_history': chatHistory.map((message) => message.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'status': status.toString().split('.').last,
      'playback_state': playbackState.toJson(),
      'settings': settings,
    };
  }

  bool get isActive => status == WatchPartyStatus.active;
  
  bool get isPaused => playbackState.isPaused;
  
  int get memberCount => members.length;
  
  bool isHost(String userId) => hostId == userId;
  
  bool isMember(String userId) => members.any((member) => member.userId == userId);
}

class ContentInfo {
  final String title;
  final String type;
  final Duration duration;
  final String thumbnailUrl;

  ContentInfo({
    required this.title,
    required this.type,
    required this.duration,
    required this.thumbnailUrl,
  });

  factory ContentInfo.fromJson(Map<String, dynamic> json) {
    return ContentInfo(
      title: json['title'] as String,
      type: json['type'] as String,
      duration: Duration(seconds: json['duration'] as int),
      thumbnailUrl: json['thumbnail_url'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'type': type,
      'duration': duration.inSeconds,
      'thumbnail_url': thumbnailUrl,
    };
  }
}

class PartyMember {
  final String userId;
  final String username;
  final String? avatarUrl;
  final bool isHost;
  final DateTime joinedAt;
  final MemberStatus status;

  PartyMember({
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.isHost,
    required this.joinedAt,
    required this.status,
  });

  factory PartyMember.fromJson(Map<String, dynamic> json) {
    return PartyMember(
      userId: json['user_id'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatar_url'] as String?,
      isHost: json['is_host'] as bool,
      joinedAt: DateTime.parse(json['joined_at'] as String),
      status: MemberStatus.values.firstWhere(
        (status) => status.toString().split('.').last == json['status'],
        orElse: () => MemberStatus.active,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'avatar_url': avatarUrl,
      'is_host': isHost,
      'joined_at': joinedAt.toIso8601String(),
      'status': status.toString().split('.').last,
    };
  }
}

class ChatMessage {
  final String id;
  final String userId;
  final String username;
  final String message;
  final DateTime timestamp;
  final MessageType type;
  final Map<String, dynamic>? metadata;

  ChatMessage({
    required this.id,
    required this.userId,
    required this.username,
    required this.message,
    required this.timestamp,
    required this.type,
    this.metadata,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      username: json['username'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: MessageType.values.firstWhere(
        (type) => type.toString().split('.').last == json['type'],
        orElse: () => MessageType.text,
      ),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'username': username,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'type': type.toString().split('.').last,
      'metadata': metadata,
    };
  }
}

class PlaybackState {
  final Duration currentTime;
  final bool isPaused;
  final double playbackRate;
  final DateTime lastUpdated;

  PlaybackState({
    required this.currentTime,
    required this.isPaused,
    required this.playbackRate,
    required this.lastUpdated,
  });

  factory PlaybackState.fromJson(Map<String, dynamic> json) {
    return PlaybackState(
      currentTime: Duration(milliseconds: json['current_time'] as int),
      isPaused: json['is_paused'] as bool,
      playbackRate: (json['playback_rate'] as num).toDouble(),
      lastUpdated: DateTime.parse(json['last_updated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_time': currentTime.inMilliseconds,
      'is_paused': isPaused,
      'playback_rate': playbackRate,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  PlaybackState copyWith({
    Duration? currentTime,
    bool? isPaused,
    double? playbackRate,
    DateTime? lastUpdated,
  }) {
    return PlaybackState(
      currentTime: currentTime ?? this.currentTime,
      isPaused: isPaused ?? this.isPaused,
      playbackRate: playbackRate ?? this.playbackRate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

enum WatchPartyStatus {
  active,
  ended,
  paused,
  error
}

enum MemberStatus {
  active,
  inactive,
  left,
  kicked
}

enum MessageType {
  text,
  emoji,
  system,
  action
}
