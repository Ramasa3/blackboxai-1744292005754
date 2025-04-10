import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../models/watch_party.dart';
import '../models/content.dart';
import '../services/watch_party_service.dart';
import '../config/theme.dart';

class WatchPartyScreen extends StatefulWidget {
  final String partyId;
  final Content content;

  const WatchPartyScreen({
    super.key,
    required this.partyId,
    required this.content,
  });

  @override
  State<WatchPartyScreen> createState() => _WatchPartyScreenState();
}

class _WatchPartyScreenState extends State<WatchPartyScreen> {
  final WatchPartyService _watchPartyService = WatchPartyService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  WatchParty? _currentParty;
  bool _isLoading = true;
  bool _isChatExpanded = true;

  @override
  void initState() {
    super.initState();
    _initializeWatchParty();
  }

  Future<void> _initializeWatchParty() async {
    try {
      setState(() => _isLoading = true);

      // Initialize video player
      final videoController = VideoPlayerController.network(
        _getStreamUrl(),
      );
      await videoController.initialize();
      _videoController = videoController;

      // Initialize Chewie controller
      _chewieController = ChewieController(
        videoPlayerController: videoController,
        autoPlay: false,
        looping: false,
        aspectRatio: 16 / 9,
        allowMuting: true,
        allowPlaybackSpeedChanging: false,
        showControls: true,
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(
              color: AppTheme.primaryRed,
            ),
          ),
        ),
        materialProgressColors: ChewieProgressColors(
          playedColor: AppTheme.primaryRed,
          handleColor: AppTheme.primaryRed,
          backgroundColor: Colors.grey[800]!,
          bufferedColor: Colors.grey[600]!,
        ),
      );

      // Join watch party
      await _watchPartyService.joinParty(
        partyId: widget.partyId,
        userId: 'current_user_id', // Replace with actual user ID
        username: 'Username', // Replace with actual username
      );

      // Listen to playback state updates
      _watchPartyService.playbackStateStream.listen((state) {
        if (_videoController != null && mounted) {
          final currentPosition = _videoController!.value.position;
          final targetPosition = state.currentTime;

          if ((currentPosition - targetPosition).abs() > const Duration(seconds: 2)) {
            _videoController!.seekTo(targetPosition);
          }

          if (state.isPaused && _videoController!.value.isPlaying) {
            _videoController!.pause();
          } else if (!state.isPaused && !_videoController!.value.isPlaying) {
            _videoController!.play();
          }
        }
      });

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to initialize watch party');
    }
  }

  String _getStreamUrl() {
    if (widget.content is Movie) {
      return (widget.content as Movie).streamUrl;
    } else if (widget.content is Episode) {
      return (widget.content as Episode).streamUrl;
    } else if (widget.content is Channel) {
      return (widget.content as Channel).streamUrl;
    }
    throw Exception('Invalid content type');
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryRed,
              ),
            )
          : Row(
              children: [
                Expanded(
                  flex: _isChatExpanded ? 7 : 9,
                  child: _buildVideoSection(),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _isChatExpanded ? 300 : 100,
                  child: _buildChatSection(),
                ),
              ],
            ),
    );
  }

  Widget _buildVideoSection() {
    if (_chewieController == null) {
      return const Center(
        child: Text(
          'Failed to load video player',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Chewie(
            controller: _chewieController!,
          ),
        ),
        _buildPartyControls(),
      ],
    );
  }

  Widget _buildPartyControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.surfaceColor,
      child: Row(
        children: [
          StreamBuilder<WatchParty>(
            stream: _watchPartyService.partyStateStream,
            builder: (context, snapshot) {
              final party = snapshot.data;
              return Text(
                'Members: ${party?.members.length ?? 0}',
                style: const TextStyle(color: Colors.white),
              );
            },
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.sync, color: Colors.white),
            onPressed: () {
              _watchPartyService.syncWithHost();
            },
          ),
          IconButton(
            icon: Icon(
              _isChatExpanded ? Icons.chat : Icons.chat_outlined,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() => _isChatExpanded = !_isChatExpanded);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChatSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(
          left: BorderSide(
            color: Colors.grey[800]!,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildChatHeader(),
          if (_isChatExpanded) ...[
            Expanded(
              child: _buildChatMessages(),
            ),
            _buildChatInput(),
          ],
        ],
      ),
    );
  }

  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlack,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[800]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (_isChatExpanded) ...[
            const Text(
              'Chat',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
          ],
          IconButton(
            icon: Icon(
              _isChatExpanded
                  ? Icons.keyboard_arrow_right
                  : Icons.keyboard_arrow_left,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() => _isChatExpanded = !_isChatExpanded);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessages() {
    return StreamBuilder<List<ChatMessage>>(
      stream: _watchPartyService.chatMessageStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Failed to load chat messages',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        final messages = snapshot.data ?? [];

        return ListView.builder(
          controller: _chatScrollController,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            return _ChatMessageWidget(message: message);
          },
        );
      },
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlack,
        border: Border(
          top: BorderSide(
            color: Colors.grey[800]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppTheme.surfaceColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send, color: AppTheme.primaryRed),
            onPressed: () {
              final message = _messageController.text.trim();
              if (message.isNotEmpty) {
                _watchPartyService.sendChatMessage(
                  ChatMessage(
                    id: DateTime.now().toString(),
                    userId: 'current_user_id', // Replace with actual user ID
                    username: 'Username', // Replace with actual username
                    message: message,
                    timestamp: DateTime.now(),
                    type: MessageType.text,
                  ),
                );
                _messageController.clear();
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    _messageController.dispose();
    _chatScrollController.dispose();
    _watchPartyService.leaveParty('current_user_id'); // Replace with actual user ID
    super.dispose();
  }
}

class _ChatMessageWidget extends StatelessWidget {
  final ChatMessage message;

  const _ChatMessageWidget({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                message.username,
                style: const TextStyle(
                  color: AppTheme.primaryRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatTime(message.timestamp),
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            message.message,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
