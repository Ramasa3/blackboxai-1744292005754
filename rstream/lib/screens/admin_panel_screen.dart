import 'package:flutter/material.dart';
import '../models/content.dart';
import '../models/user.dart';
import '../models/subscription.dart';
import '../services/content_service.dart';
import '../services/auth_service.dart';
import '../services/subscription_service.dart';
import '../config/theme.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final ContentService _contentService = ContentService();
  final AuthService _authService = AuthService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  
  int _selectedIndex = 0;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: AppTheme.primaryBlack,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.logout();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: Row(
        children: [
          _buildSidebar(),
          const VerticalDivider(
            width: 1,
            color: Colors.grey,
          ),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return NavigationRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() => _selectedIndex = index);
      },
      labelType: NavigationRailLabelType.all,
      backgroundColor: AppTheme.primaryBlack,
      selectedIconTheme: const IconThemeData(
        color: AppTheme.primaryRed,
      ),
      unselectedIconTheme: const IconThemeData(
        color: Colors.grey,
      ),
      selectedLabelTextStyle: const TextStyle(
        color: AppTheme.primaryRed,
      ),
      unselectedLabelTextStyle: const TextStyle(
        color: Colors.grey,
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.movie),
          label: Text('Content'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.people),
          label: Text('Users'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.card_membership),
          label: Text('Subscriptions'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.analytics),
          label: Text('Analytics'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings),
          label: Text('Settings'),
        ),
      ],
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildContentManagement();
      case 1:
        return _buildUserManagement();
      case 2:
        return _buildSubscriptionManagement();
      case 3:
        return _buildAnalytics();
      case 4:
        return _buildSettings();
      default:
        return const Center(
          child: Text(
            'Unknown section',
            style: TextStyle(color: Colors.white),
          ),
        );
    }
  }

  Widget _buildContentManagement() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Content Management',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // Show add content dialog
                  _showAddContentDialog();
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Content'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildContentTabs(),
        ],
      ),
    );
  }

  Widget _buildContentTabs() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Movies'),
              Tab(text: 'Series'),
              Tab(text: 'Channels'),
            ],
            indicatorColor: AppTheme.primaryRed,
            labelColor: AppTheme.primaryRed,
            unselectedLabelColor: Colors.grey,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              children: [
                _buildContentList(ContentType.movie),
                _buildContentList(ContentType.series),
                _buildContentList(ContentType.channel),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentList(ContentType type) {
    return StreamBuilder<List<Content>>(
      stream: _getContentStream(type),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading ${type.toString().split('.').last}s',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppTheme.primaryRed,
            ),
          );
        }

        final content = snapshot.data!;
        return ListView.builder(
          itemCount: content.length,
          itemBuilder: (context, index) {
            return _ContentListItem(
              content: content[index],
              onEdit: () => _showEditContentDialog(content[index]),
              onDelete: () => _showDeleteContentDialog(content[index]),
            );
          },
        );
      },
    );
  }

  Widget _buildUserManagement() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Management',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          // Add user management UI here
        ],
      ),
    );
  }

  Widget _buildSubscriptionManagement() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Subscription Management',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          // Add subscription management UI here
        ],
      ),
    );
  }

  Widget _buildAnalytics() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analytics',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          // Add analytics UI here
        ],
      ),
    );
  }

  Widget _buildSettings() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          // Add settings UI here
        ],
      ),
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

  void _showAddContentDialog() {
    // Implement add content dialog
  }

  void _showEditContentDialog(Content content) {
    // Implement edit content dialog
  }

  void _showDeleteContentDialog(Content content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: Text(
          'Delete ${content.title}',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete this ${content.type.toString().split('.').last.toLowerCase()}?',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Implement delete functionality
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _ContentListItem extends StatelessWidget {
  final Content content;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ContentListItem({
    required this.content,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.surfaceColor,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.network(
            content.thumbnailUrl,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 60,
                height: 60,
                color: Colors.grey[800],
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                ),
              );
            },
          ),
        ),
        title: Text(
          content.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          content.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.grey[400],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
