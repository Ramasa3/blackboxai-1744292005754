import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/watch_party.dart';
import '../models/user.dart';
import 'database_service.dart';

class WatchPartyService {
  static final WatchPartyService _instance = WatchPartyService._internal();
  final DatabaseService _db = DatabaseService();
  
  // WebSocket connection
  WebSocketChannel? _channel;
  
  // Stream controllers
  final _partyStateController = StreamController<WatchParty>.broadcast();
  final _chatMessageController = StreamController<ChatMessage>.broadcast();
  final _playbackStateController = StreamController<PlaybackState>.broadcast();
  final _memberUpdateController = StreamController<List<PartyMember>>.broadcast();
  
  // Active watch party
  WatchParty? _currentParty;
  
  // Sync threshold
  static const Duration _syncThreshold = Duration(milliseconds: 1000);
  
  // Heartbeat interval
  static const Duration _heartbeatInterval = Duration(seconds: 30);
  Timer? _heartbeatTimer;

  factory WatchPartyService() {
    return _instance;
  }

  WatchPartyService._internal();

  // Stream getters
  Stream<WatchParty> get partyStateStream => _partyStateController.stream;
  Stream<ChatMessage> get chatMessageStream => _chatMessageController.stream;
  Stream<PlaybackState> get playbackStateStream => _playbackStateController.stream;
  Stream<List<PartyMember>> get memberUpdateStream => _memberUpdateController.stream;

  // Create new watch party
  Future<WatchParty> createWatchParty({
    required String hostId,
    required String contentId,
    required ContentInfo contentInfo,
    Map<String, dynamic>? settings,
  }) async {
    try {
      final party = WatchParty(
        id: _generatePartyId(),
        hostId: hostId,
        contentId: contentId,
        contentInfo: contentInfo,
        members: [
          PartyMember(
            userId: hostId,
            username: 'Host', // Replace with actual username
            isHost: true,
            joinedAt: DateTime.now(),
            status: MemberStatus.active,
          )
        ],
        chatHistory: [],
        createdAt: DateTime.now(),
        status: WatchPartyStatus.active,
        playbackState: PlaybackState(
          currentTime: Duration.zero,
          isPaused: true,
          playbackRate: 1.0,
          lastUpdated: DateTime.now(),
        ),
        settings: settings,
      );

      final partyId = await _db.createWatchParty(party);
      await _connectToParty(partyId);
      
      _currentParty = party;
      _partyStateController.add(party);

      return party;
    } catch (e) {
      throw WatchPartyException('Failed to create watch party: ${e.toString()}');
    }
  }

  // Join existing watch party
  Future<void> joinParty({
    required String partyId,
    required String userId,
    required String username,
  }) async {
    try {
      final party = await _db.getWatchParty(partyId);
      if (party == null) {
        throw WatchPartyException('Watch party not found');
      }

      if (party.status != WatchPartyStatus.active) {
        throw WatchPartyException('Watch party is not active');
      }

      await _connectToParty(partyId);

      // Add member to party
      final newMember = PartyMember(
        userId: userId,
        username: username,
        isHost: false,
        joinedAt: DateTime.now(),
        status: MemberStatus.active,
      );

      _sendMessage({
        'type': 'member_joined',
        'member': newMember.toJson(),
      });

      _currentParty = party;
      _partyStateController.add(party);
    } catch (e) {
      throw WatchPartyException('Failed to join watch party: ${e.toString()}');
    }
  }

  // Leave watch party
  Future<void> leaveParty(String userId) async {
    try {
      if (_currentParty == null) return;

      _sendMessage({
        'type': 'member_left',
        'userId': userId,
      });

      await _disconnectFromParty();
      _currentParty = null;
    } catch (e) {
      throw WatchPartyException('Failed to leave watch party: ${e.toString()}');
    }
  }

  // Send chat message
  void sendChatMessage(ChatMessage message) {
    try {
      _sendMessage({
        'type': 'chat_message',
        'message': message.toJson(),
      });

      _chatMessageController.add(message);
    } catch (e) {
      throw WatchPartyException('Failed to send message: ${e.toString()}');
    }
  }

  // Update playback state
  void updatePlaybackState(PlaybackState state) {
    try {
      _sendMessage({
        'type': 'playback_update',
        'state': state.toJson(),
      });

      _playbackStateController.add(state);
    } catch (e) {
      throw WatchPartyException('Failed to update playback state: ${e.toString()}');
    }
  }

  // Sync playback with host
  Future<void> syncWithHost() async {
    try {
      if (_currentParty == null) return;

      _sendMessage({
        'type': 'sync_request',
      });
    } catch (e) {
      throw WatchPartyException('Failed to sync with host: ${e.toString()}');
    }
  }

  // WebSocket connection management
  Future<void> _connectToParty(String partyId) async {
    try {
      final uri = Uri.parse('ws://your-websocket-server/watch-party/$partyId');
      _channel = WebSocketChannel.connect(uri);

      _channel!.stream.listen(
        (message) => _handleWebSocketMessage(message),
        onError: (error) => _handleWebSocketError(error),
        onDone: () => _handleWebSocketClosed(),
      );

      // Start heartbeat
      _startHeartbeat();
    } catch (e) {
      throw WatchPartyException('Failed to connect to watch party: ${e.toString()}');
    }
  }

  Future<void> _disconnectFromParty() async {
    _stopHeartbeat();
    await _channel?.sink.close();
    _channel = null;
  }

  void _sendMessage(Map<String, dynamic> message) {
    if (_channel == null) return;
    _channel!.sink.add(message);
  }

  // WebSocket message handlers
  void _handleWebSocketMessage(dynamic message) {
    final data = message as Map<String, dynamic>;
    
    switch (data['type']) {
      case 'chat_message':
        final chatMessage = ChatMessage.fromJson(data['message']);
        _chatMessageController.add(chatMessage);
        break;
      
      case 'playback_update':
        final playbackState = PlaybackState.fromJson(data['state']);
        _playbackStateController.add(playbackState);
        break;
      
      case 'member_joined':
      case 'member_left':
        if (_currentParty != null) {
          _memberUpdateController.add(_currentParty!.members);
        }
        break;
      
      case 'party_ended':
        _handlePartyEnded();
        break;
    }
  }

  void _handleWebSocketError(dynamic error) {
    // Implement error handling
    print('WebSocket error: $error');
  }

  void _handleWebSocketClosed() {
    _stopHeartbeat();
    // Implement reconnection logic if needed
  }

  void _handlePartyEnded() {
    _disconnectFromParty();
    _currentParty = null;
  }

  // Heartbeat management
  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      _sendMessage({'type': 'heartbeat'});
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  // Helper methods
  String _generatePartyId() {
    return 'party_${DateTime.now().millisecondsSinceEpoch}';
  }

  // Check if current time is within sync threshold
  bool _isWithinSyncThreshold(Duration time1, Duration time2) {
    return (time1 - time2).abs() <= _syncThreshold;
  }

  // Dispose resources
  void dispose() {
    _disconnectFromParty();
    _partyStateController.close();
    _chatMessageController.close();
    _playbackStateController.close();
    _memberUpdateController.close();
  }
}

class WatchPartyException implements Exception {
  final String message;

  WatchPartyException(this.message);

  @override
  String toString() => message;
}
