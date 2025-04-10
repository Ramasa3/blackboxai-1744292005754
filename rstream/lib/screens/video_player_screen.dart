import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../models/content.dart';
import '../config/theme.dart';

class VideoPlayerScreen extends StatefulWidget {
  final Content content;
  final bool autoPlay;

  const VideoPlayerScreen({
    super.key,
    required this.content,
    this.autoPlay = true,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isControlsVisible = true;
  bool _isLoading = true;
  bool _isBuffering = false;
  bool _isFullScreen = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _initializePlayer() async {
    try {
      final streamUrl = _getStreamUrl();
      _controller = VideoPlayerController.network(streamUrl);

      await _controller.initialize();
      _controller.addListener(_videoListener);

      if (widget.autoPlay) {
        await _controller.play();
      }

      setState(() {
        _duration = _controller.value.duration;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load video');
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

  void _videoListener() {
    if (!mounted) return;

    setState(() {
      _position = _controller.value.position;
      _isBuffering = _controller.value.isBuffering;
    });

    // Hide controls after 3 seconds of inactivity
    if (_isControlsVisible) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _isControlsVisible && _controller.value.isPlaying) {
          setState(() => _isControlsVisible = false);
        }
      });
    }
  }

  void _toggleControls() {
    setState(() => _isControlsVisible = !_isControlsVisible);
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  void _toggleFullScreen() {
    setState(() => _isFullScreen = !_isFullScreen);
    if (_isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _seekTo(Duration position) {
    _controller.seekTo(position);
  }

  void _skipForward() {
    final newPosition = _position + const Duration(seconds: 10);
    if (newPosition < _duration) {
      _seekTo(newPosition);
    }
  }

  void _skipBackward() {
    final newPosition = _position - const Duration(seconds: 10);
    if (newPosition > Duration.zero) {
      _seekTo(newPosition);
    } else {
      _seekTo(Duration.zero);
    }
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
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryRed,
              ),
            )
          : GestureDetector(
              onTap: _toggleControls,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Video player
                  Center(
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                  ),

                  // Buffering indicator
                  if (_isBuffering)
                    const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryRed,
                      ),
                    ),

                  // Controls overlay
                  if (_isControlsVisible)
                    _buildControls(),
                ],
              ),
            ),
    );
  }

  Widget _buildControls() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Top bar
          _buildTopBar(),

          // Center controls
          _buildCenterControls(),

          // Bottom bar
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                widget.content.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                color: Colors.white,
              ),
              onPressed: _toggleFullScreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterControls() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            iconSize: 48,
            icon: const Icon(Icons.replay_10, color: Colors.white),
            onPressed: _skipBackward,
          ),
          const SizedBox(width: 32),
          IconButton(
            iconSize: 64,
            icon: Icon(
              _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
            ),
            onPressed: _togglePlayPause,
          ),
          const SizedBox(width: 32),
          IconButton(
            iconSize: 48,
            icon: const Icon(Icons.forward_10, color: Colors.white),
            onPressed: _skipForward,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Progress bar
            _buildProgressBar(),
            const SizedBox(height: 8),
            // Time and controls
            Row(
              children: [
                Text(
                  _formatDuration(_position),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(width: 8),
                Text(
                  '/',
                  style: TextStyle(color: Colors.grey[400]),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDuration(_duration),
                  style: const TextStyle(color: Colors.white),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: () {
                    // Show quality settings
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 2,
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 6,
        ),
        overlayShape: const RoundSliderOverlayShape(
          overlayRadius: 12,
        ),
        activeTrackColor: AppTheme.primaryRed,
        inactiveTrackColor: Colors.grey[700],
        thumbColor: AppTheme.primaryRed,
        overlayColor: AppTheme.primaryRed.withOpacity(0.3),
      ),
      child: Slider(
        value: _position.inMilliseconds.toDouble(),
        min: 0,
        max: _duration.inMilliseconds.toDouble(),
        onChanged: (value) {
          _seekTo(Duration(milliseconds: value.toInt()));
        },
      ),
    );
  }

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

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }
}
