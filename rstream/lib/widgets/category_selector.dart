import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../config/constants.dart';

class CategorySelector extends StatelessWidget {
  final String selectedCategory;
  final Function(String) onCategorySelected;

  const CategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Categories',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                _buildCategoryChip(
                  'All',
                  Icons.apps,
                ),
                ...AppConstants.movieCategories.map((category) {
                  return _buildCategoryChip(
                    category,
                    _getCategoryIcon(category),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category, IconData icon) {
    final isSelected = selectedCategory == category;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              category,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.surfaceColor,
        selectedColor: AppTheme.primaryRed,
        onSelected: (bool selected) {
          onCategorySelected(category);
        },
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? AppTheme.primaryRed : Colors.grey.withOpacity(0.3),
          ),
        ),
        elevation: isSelected ? 4 : 0,
        pressElevation: 2,
        showCheckmark: false,
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'action':
        return Icons.local_fire_department;
      case 'comedy':
        return Icons.sentiment_very_satisfied;
      case 'drama':
        return Icons.theater_comedy;
      case 'horror':
        return Icons.ghost;
      case 'sci-fi':
        return Icons.rocket_launch;
      case 'documentary':
        return Icons.camera_alt;
      case 'animation':
        return Icons.animation;
      case 'thriller':
        return Icons.psychology;
      case 'tv shows':
        return Icons.tv;
      case 'web series':
        return Icons.web;
      case 'anime':
        return Icons.animation;
      case 'reality shows':
        return Icons.people;
      case 'kids shows':
        return Icons.child_care;
      case 'news':
        return Icons.newspaper;
      case 'sports':
        return Icons.sports_basketball;
      case 'entertainment':
        return Icons.movie_filter;
      case 'music':
        return Icons.music_note;
      case 'lifestyle':
        return Icons.lifestyle;
      default:
        return Icons.category;
    }
  }
}

class CategoryBadge extends StatelessWidget {
  final String category;
  final Color color;
  final VoidCallback? onTap;

  const CategoryBadge({
    super.key,
    required this.category,
    this.color = AppTheme.primaryRed,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getCategoryIcon(category),
              size: 14,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              category,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'action':
        return Icons.local_fire_department;
      case 'comedy':
        return Icons.sentiment_very_satisfied;
      case 'drama':
        return Icons.theater_comedy;
      case 'horror':
        return Icons.ghost;
      case 'sci-fi':
        return Icons.rocket_launch;
      case 'documentary':
        return Icons.camera_alt;
      case 'animation':
        return Icons.animation;
      case 'thriller':
        return Icons.psychology;
      default:
        return Icons.category;
    }
  }
}
