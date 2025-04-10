import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/auth_service.dart';

class CustomAppBar extends StatelessWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      expandedHeight: 60.0,
      backgroundColor: AppTheme.primaryBlack,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.network(
          'https://via.placeholder.com/40', // Replace with actual logo
          width: 40,
          height: 40,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          color: Colors.white,
          onPressed: () {
            // Implement search functionality
          },
        ),
        IconButton(
          icon: const Icon(Icons.notifications),
          color: Colors.white,
          onPressed: () {
            // Implement notifications
          },
        ),
        StreamBuilder<User?>(
          stream: AuthService().authStateChanges,
          builder: (context, snapshot) {
            return GestureDetector(
              onTap: () {
                // Navigate to profile or login screen
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: AppTheme.primaryRed,
                  radius: 16,
                  child: snapshot.hasData
                      ? ClipOval(
                          child: Image.network(
                            snapshot.data?.profileImage ??
                                'https://via.placeholder.com/32',
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(
          color: Colors.grey[900],
          height: 1.0,
        ),
      ),
    );
  }
}
