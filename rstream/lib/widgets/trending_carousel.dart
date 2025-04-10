import 'dart:async';
import 'package:flutter/material.dart';
import '../models/content.dart';
import '../config/theme.dart';

class TrendingCarousel extends StatefulWidget {
  final List<Content> content;
  final Duration autoPlayInterval;

  const TrendingCarousel({
    super.key,
    required this.content,
    this.autoPlayInterval = const Duration(seconds: 5),
  });

  @override
  State<TrendingCarousel> createState() => _TrendingCarouselState();
}

class _TrendingCarouselState extends State<TrendingCarousel> {
  late PageController _pageController;
  late Timer _autoPlayTimer;
  int _currentPage = 0;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.8,
      initialPage: _currentPage,
    );
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _autoPlayTimer = Timer.periodic(widget.autoPlayInterval, (timer) {
      if (!_isHovered && mounted) {
        if (_currentPage < widget.content.length - 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.content.isEmpty) {
      return const SizedBox.shrink();
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        height: 400,
        margin: const EdgeInsets.only(top: 16),
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemCount: widget.content.length,
              itemBuilder: (context, index) {
                return _TrendingCard(
                  content: widget.content[index],
                  isActive: index == _currentPage,
                );
              },
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: _buildIndicators(),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.content.length,
        (index) => Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == index
                ? AppTheme.primaryRed
                : Colors.grey.withOpacity(0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Positioned.fill(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavigationButton(
            icon: Icons.chevron_left,
            onPressed: () {
              if (_currentPage > 0) {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              }
            },
          ),
          _buildNavigationButton(
            icon: Icons.chevron_right,
            onPressed: () {
              if (_currentPage < widget.content.length - 1) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AnimatedOpacity(
        opacity: _isHovered ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Material(
          color: Colors.black.withOpacity(0.5),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Icon(
                icon,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _autoPlayTimer.cancel();
    super.dispose();
  }
}

class _TrendingCard extends StatelessWidget {
  final Content content;
  final bool isActive;

  const _TrendingCard({
    required this.content,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      margin: EdgeInsets.symmetric(
        horizontal: 8,
        vertical: isActive ? 16 : 32,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            Image.network(
              content.thumbnailUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: AppTheme.surfaceColor,
                  child: const Icon(
                    Icons.error_outline,
                    color: AppTheme.primaryRed,
                    size: 48,
                  ),
                );
              },
            ),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),

            // Content info
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    content.title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    content.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildPlayButton(context),
                      const SizedBox(width: 16),
                      _buildInfoButton(context),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        // Navigate to content player
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryRed,
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        ),
      ),
      icon: const Icon(Icons.play_arrow),
      label: const Text('Play Now'),
    );
  }

  Widget _buildInfoButton(BuildContext context) {
    return OutlinedButton(
      onPressed: () {
        // Navigate to content details
      },
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.white),
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        ),
      ),
      child: const Text(
        'More Info',
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}
