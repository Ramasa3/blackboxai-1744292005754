import 'package:flutter/material.dart';
import '../models/content.dart';
import '../services/content_service.dart';
import '../config/theme.dart';
import '../widgets/content_card.dart';
import '../widgets/trending_carousel.dart';
import '../widgets/category_selector.dart';
import '../widgets/custom_app_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final ContentService _contentService = ContentService();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
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
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          const CustomAppBar(),
          SliverToBoxAdapter(
            child: _buildTrendingSection(),
          ),
          SliverToBoxAdapter(
            child: CategorySelector(
              selectedCategory: _selectedCategory,
              onCategorySelected: (category) {
                setState(() => _selectedCategory = category);
              },
            ),
          ),
          _buildContentGrid(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildTrendingSection() {
    return StreamBuilder<List<Content>>(
      stream: _contentService.trendingStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('Failed to load trending content'),
          );
        }

        if (!snapshot.hasData && _isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppTheme.primaryRed,
            ),
          );
        }

        final trendingContent = snapshot.data ?? [];
        return TrendingCarousel(content: trendingContent);
      },
    );
  }

  Widget _buildContentGrid() {
    return StreamBuilder<List<Content>>(
      stream: _contentService.moviesStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Center(
              child: Text(
                'Failed to load content',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          );
        }

        if (!snapshot.hasData && _isLoading) {
          return const SliverToBoxAdapter(
            child: Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryRed,
              ),
            ),
          );
        }

        final content = snapshot.data ?? [];
        final filteredContent = _selectedCategory == 'All'
            ? content
            : content
                .where((item) => item.categories.contains(_selectedCategory))
                .toList();

        return SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = filteredContent[index];
                return ContentCard(content: item);
              },
              childCount: filteredContent.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryBlack,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        selectedItemColor: AppTheme.primaryRed,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.movie),
            label: 'Movies',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.tv),
            label: 'Series',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.live_tv),
            label: 'Live',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: 0,
        onTap: (index) {
          // Handle navigation
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
