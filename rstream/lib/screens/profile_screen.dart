import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/subscription_service.dart';
import '../config/theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppTheme.primaryBlack,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navigate to edit profile screen
            },
          ),
        ],
      ),
      body: StreamBuilder<User?>(
        stream: _authService.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading profile',
                style: TextStyle(color: Colors.grey[400]),
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

          final user = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(user),
                const SizedBox(height: 24),
                _buildSubscriptionInfo(),
                const SizedBox(height: 24),
                _buildSettingsSection(),
                const SizedBox(height: 24),
                _buildActionButtons(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(User user) {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: AppTheme.primaryRed,
                backgroundImage: user.profileImage != null
                    ? NetworkImage(user.profileImage!)
                    : null,
                child: user.profileImage == null
                    ? const Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.white,
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryRed,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            user.username,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionInfo() {
    return StreamBuilder<Subscription?>(
      stream: _subscriptionService.subscriptionStream,
      builder: (context, snapshot) {
        final subscription = snapshot.data;
        return Card(
          color: AppTheme.surfaceColor,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Subscription',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (subscription != null) ...[
                  _buildSubscriptionDetail(
                    'Plan',
                    subscription.plan.toString().split('.').last,
                  ),
                  _buildSubscriptionDetail(
                    'Status',
                    subscription.status.toString().split('.').last,
                  ),
                  _buildSubscriptionDetail(
                    'Renewal Date',
                    _formatDate(subscription.endDate),
                  ),
                ] else
                  _buildNoSubscriptionInfo(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubscriptionDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSubscriptionInfo() {
    return Column(
      children: [
        Text(
          'No active subscription',
          style: TextStyle(
            color: Colors.grey[400],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            Navigator.pushNamed(context, '/subscription');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryRed,
            minimumSize: const Size(double.infinity, 48),
          ),
          child: const Text('Subscribe Now'),
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return Card(
      color: AppTheme.surfaceColor,
      child: Column(
        children: [
          _buildSettingsTile(
            'Account Settings',
            Icons.settings,
            onTap: () {
              // Navigate to account settings
            },
          ),
          _buildSettingsTile(
            'Watch History',
            Icons.history,
            onTap: () {
              // Navigate to watch history
            },
          ),
          _buildSettingsTile(
            'Downloads',
            Icons.download,
            onTap: () {
              // Navigate to downloads
            },
          ),
          _buildSettingsTile(
            'Notifications',
            Icons.notifications,
            onTap: () {
              // Navigate to notifications settings
            },
          ),
          _buildSettingsTile(
            'Help & Support',
            Icons.help,
            onTap: () {
              // Navigate to help & support
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    String title,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.grey[400],
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: _isLoading ? null : _handleLogout,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[700],
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Logout'),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            // Show delete account confirmation dialog
            _showDeleteAccountDialog();
          },
          child: const Text(
            'Delete Account',
            style: TextStyle(
              color: Colors.red,
            ),
          ),
        ),
      ],
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text(
          'Delete Account',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
          style: TextStyle(color: Colors.white),
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
            onPressed: () {
              Navigator.pop(context);
              // Implement delete account functionality
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

  Future<void> _handleLogout() async {
    setState(() => _isLoading = true);
    try {
      await _authService.logout();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
