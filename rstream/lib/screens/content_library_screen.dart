import 'package:flutter/material.dart';
import '../models/content.dart';
import '../services/content_service.dart';
import '../widgets/content_card.dart';
import '../widgets/category_selector.dart';
import '../config/theme.dart';
import '../config/constants.dart';

class ContentLibraryScreen extends StatefulWidget {
  const ContentLibraryScreen({super.key});

  @override
  State<ContentLibraryScreen> createState() => _ContentLibraryScreenState();
}

class _ContentLibraryScreenState extends State<ContentLibraryScreen> with SingleTickerProviderStateMixin {
  final ContentService _contentService = ContentService();
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isLoading = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadContent();
  }

  Future<void> _loadContent() async {
    try {
      setState(() => _isLoading = true);
      await _contentService.init();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load content');
    }
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _selectedCategory = 'All';
        _searchQuery = '';
        _searchController.clear();
      });
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
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            _buildAppBar(),
            _buildSearchBar(),
            _buildTabBar(),
            if (!_isSearching) _buildCategoryBar(),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildContentGrid(ContentType.movie),
            _buildContentGrid(ContentType.series),
            _buildContentGrid(ContentType.channel),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      pinned: true,
      title: Text(
        'Content Library',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
      ),
      actions: [
        IconButton(
          icon: Icon(_isSearching ? Icons.close : Icons.search),
          onPressed: () {
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchQuery = '';
                _searchController.clear();
              }
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () {
            // Show filter options
          },
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    if (!_isSearching) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search content...',
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            filled: true,
            fillColor: AppTheme.surfaceColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (value) {
            setState(() => _searchQuery = value);
          },
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverAppBarDelegate(
        TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryRed,
          indicatorWeight: 3,
          labelColor: AppTheme.primaryRed,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Movies'),
            Tab(text: 'Series'),
            Tab(text: 'Channels'),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBar() {
    return SliverToBoxAdapter(
      child: CategorySelector(
        selectedCategory: _selectedCategory,
        onCategorySelected: (category) {
          setState(() => _selectedCategory = category);
        },
      ),
    );
  }

  Widget _buildContentGrid(ContentType type) {
    return StreamBuilder<List<Content>>(
      stream: _getContentStream(type),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Failed to load ${type.toString().split('.').last}s',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        if (!snapshot.hasData && _isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppTheme.primaryRed,
            ),
          );
        }

        final content = snapshot.data ?? [];
        final filteredContent = _filterContent(content);

        if (filteredContent.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: Colors.grey[600],
                ),
                const SizedBox(height: 16),
                Text(
                  'No content found',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: filteredContent.length,
          itemBuilder: (context, index) {
            return ContentCard(content: filteredContent[index]);
          },
        );
      },
    );
  }

  Stream<List<Content>> _getContentStream(ContentType type) {
    switch (type) {
      case ContentType.movie:
        return _contentService.moviesStream;
      case ContentType.series:
        return _contentService.seriesStream;
      case ContentType.channel:
        return _contentService.channelsStream;
    }
  }

  List<Content> _filterContent(List<Content> content) {
    var filtered = content;

    // Apply category filter
    if (_selectedCategory != 'All') {
      filtered = filtered
          .where((item) => item.categories.contains(_selectedCategory))
          .toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where((item) =>
              item.title.toLowerCase().contains(query) ||
              item.description.toLowerCase().contains(query))
          .toList();
    }

    return filtered;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppTheme.backgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
