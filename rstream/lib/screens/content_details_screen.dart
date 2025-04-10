import 'package:flutter/material.dart';
import '../models/content.dart';
import '../services/content_service.dart';
import '../services/watch_party_service.dart';
import '../config/theme.dart';

class ContentDetailsScreen extends StatefulWidget {
  final Content content;

  const ContentDetailsScreen({
    super.key,
    required this.content,
  });

  @override
  State<ContentDetailsScreen> createState() => _ContentDetailsScreenState();
}

class _ContentDetailsScreenState extends State<ContentDetailsScreen> {
  final ContentService _contentService = ContentService();
  final WatchPartyService _watchPartyService = WatchPartyService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitle(),
                  const SizedBox(height: 16),
                  _buildActions(),
                  const SizedBox(height: 24),
                  _buildDescription(),
                  const SizedBox(height: 24),
                  _buildMetadata(),
                  const SizedBox(height: 24),
                  if (widget.content is Series) _buildEpisodesList(),
                  if (widget.content is Channel) _buildProgramGuide(),
                  _buildSimilarContent(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              widget.content.thumbnailUrl,
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
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.content.title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildRatingBadge(),
            const SizedBox(width: 16),
            _buildQualityBadge(),
            const SizedBox(width: 16),
            if (widget.content is Movie)
              Text(
                '${(widget.content as Movie).duration.inMinutes} min',
                style: TextStyle(
                  color: Colors.grey[400],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.amber,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star,
            color: Colors.black,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            widget.content.rating.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityBadge() {
    String quality = 'HD';
    if (widget.content is Movie) {
      quality = (widget.content as Movie).isHD ? 'HD' : 'SD';
    } else if (widget.content is Series) {
      quality = (widget.content as Series).isHD ? 'HD' : 'SD';
    } else if (widget.content is Channel) {
      quality = (widget.content as Channel).isHD ? 'HD' : 'SD';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Colors.grey[700]!,
        ),
      ),
      child: Text(
        quality,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/player',
                arguments: widget.content,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Play'),
          ),
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: const Icon(Icons.add, color: Colors.white),
          onPressed: () {
            // Add to watchlist
          },
        ),
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: () {
            // Share content
          },
        ),
        IconButton(
          icon: const Icon(Icons.group, color: Colors.white),
          onPressed: () {
            _createWatchParty();
          },
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.content.description,
          style: TextStyle(
            color: Colors.grey[400],
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildMetadata() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildMetadataItem('Genre', widget.content.categories.join(', ')),
        if (widget.content is Movie) ...[
          _buildMetadataItem('Director', (widget.content as Movie).director),
          _buildMetadataItem('Cast', (widget.content as Movie).cast.join(', ')),
          _buildMetadataItem(
            'Release Year',
            (widget.content as Movie).releaseYear.toString(),
          ),
        ],
        if (widget.content is Series)
          _buildMetadataItem(
            'Status',
            (widget.content as Series).isComplete ? 'Completed' : 'Ongoing',
          ),
        if (widget.content is Channel)
          _buildMetadataItem(
            'Status',
            (widget.content as Channel).isLive ? 'Live' : 'Off Air',
          ),
      ],
    );
  }

  Widget _buildMetadataItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodesList() {
    final series = widget.content as Series;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Episodes',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        for (final season in series.seasons)
          ExpansionTile(
            title: Text(
              'Season ${season.number}',
              style: const TextStyle(color: Colors.white),
            ),
            children: season.episodes.map((episode) {
              return ListTile(
                leading: Container(
                  width: 120,
                  height: 68,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(episode.thumbnail ?? series.thumbnailUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                title: Text(
                  episode.title,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'Episode ${episode.number} • ${episode.duration.inMinutes} min',
                  style: TextStyle(color: Colors.grey[400]),
                ),
                onTap: () {
                  // Play episode
                },
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildProgramGuide() {
    final channel = widget.content as Channel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Program Guide',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (channel.currentProgram != null)
          Card(
            color: AppTheme.surfaceColor,
            child: ListTile(
              title: Text(
                channel.currentProgram!['title'] as String,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                'Now Playing',
                style: TextStyle(color: Colors.grey[400]),
              ),
              trailing: const Icon(
                Icons.live_tv,
                color: AppTheme.primaryRed,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSimilarContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Similar Content',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: StreamBuilder<List<Content>>(
            stream: _contentService.getContentStream(widget.content.type),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryRed,
                  ),
                );
              }

              final similarContent = snapshot.data!
                  .where((content) =>
                      content.id != widget.content.id &&
                      content.categories
                          .any((category) => widget.content.categories.contains(category)))
                  .take(10)
                  .toList();

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: similarContent.length,
                itemBuilder: (context, index) {
                  final content = similarContent[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ContentDetailsScreen(
                            content: content,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              content.thumbnailUrl,
                              height: 160,
                              width: 140,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            content.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _createWatchParty() async {
    setState(() => _isLoading = true);
    try {
      final party = await _watchPartyService.createWatchParty(
        hostId: 'current_user_id', // Replace with actual user ID
        contentId: widget.content.id,
        contentInfo: ContentInfo(
          title: widget.content.title,
          type: widget.content.type.toString().split('.').last,
          duration: widget.content is Movie
              ? (widget.content as Movie).duration
              : const Duration(hours: 2), // Default duration for other types
          thumbnailUrl: widget.content.thumbnailUrl,
        ),
      );

      if (mounted) {
        Navigator.pushNamed(
          context,
          '/watch-party',
          arguments: {
            'partyId': party.id,
            'content': widget.content,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create watch party: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
