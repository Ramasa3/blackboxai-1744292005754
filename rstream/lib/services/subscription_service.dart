import 'dart:async';
import '../models/subscription.dart';
import '../models/user.dart';
import 'database_service.dart';
import 'package:geolocator/geolocator.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  final DatabaseService _db = DatabaseService();
  
  // Stream controller for subscription updates
  final _subscriptionController = StreamController<Subscription?>.broadcast();

  // Subscription plans configuration
  static const Map<SubscriptionPlan, Map<String, dynamic>> _planFeatures = {
    SubscriptionPlan.basic: {
      'price': 9.99,
      'maxDevices': 1,
      'quality': 'HD',
      'downloadAllowed': false,
      'watchPartyAllowed': false,
    },
    SubscriptionPlan.standard: {
      'price': 14.99,
      'maxDevices': 2,
      'quality': 'Full HD',
      'downloadAllowed': true,
      'watchPartyAllowed': true,
    },
    SubscriptionPlan.premium: {
      'price': 19.99,
      'maxDevices': 4,
      'quality': '4K Ultra HD',
      'downloadAllowed': true,
      'watchPartyAllowed': true,
    },
    SubscriptionPlan.free: {
      'price': 0.00,
      'maxDevices': 1,
      'quality': 'SD',
      'downloadAllowed': false,
      'watchPartyAllowed': false,
    },
  };

  factory SubscriptionService() {
    return _instance;
  }

  SubscriptionService._internal();

  // Stream getter
  Stream<Subscription?> get subscriptionStream => _subscriptionController.stream;

  // Get user's current subscription
  Future<Subscription?> getCurrentSubscription(String userId) async {
    try {
      final subscription = await _db.getUserSubscription(userId);
      _subscriptionController.add(subscription);
      return subscription;
    } catch (e) {
      throw SubscriptionException('Failed to fetch subscription: ${e.toString()}');
    }
  }

  // Subscribe user to a plan
  Future<Subscription> subscribe({
    required String userId,
    required SubscriptionPlan plan,
    required PaymentInfo paymentInfo,
    bool autoRenew = true,
  }) async {
    try {
      // Check if user already has an active subscription
      final currentSub = await getCurrentSubscription(userId);
      if (currentSub != null && currentSub.isActive) {
        throw SubscriptionException('User already has an active subscription');
      }

      final subscription = Subscription(
        id: _generateSubscriptionId(),
        userId: userId,
        plan: plan,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        status: SubscriptionStatus.active,
        paymentInfo: paymentInfo,
        isAutoRenew: autoRenew,
        features: _getPlanFeatures(plan),
      );

      await _db.insertSubscription(subscription);
      _subscriptionController.add(subscription);

      return subscription;
    } catch (e) {
      throw SubscriptionException('Failed to create subscription: ${e.toString()}');
    }
  }

  // Cancel subscription
  Future<void> cancelSubscription(String subscriptionId) async {
    try {
      final subscription = await _getSubscription(subscriptionId);
      if (subscription == null) {
        throw SubscriptionException('Subscription not found');
      }

      final updatedSubscription = subscription.copyWith(
        status: SubscriptionStatus.cancelled,
        isAutoRenew: false,
      );

      await _db.insertSubscription(updatedSubscription);
      _subscriptionController.add(updatedSubscription);
    } catch (e) {
      throw SubscriptionException('Failed to cancel subscription: ${e.toString()}');
    }
  }

  // Renew subscription
  Future<Subscription> renewSubscription(String subscriptionId) async {
    try {
      final subscription = await _getSubscription(subscriptionId);
      if (subscription == null) {
        throw SubscriptionException('Subscription not found');
      }

      final updatedSubscription = subscription.copyWith(
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        status: SubscriptionStatus.active,
      );

      await _db.insertSubscription(updatedSubscription);
      _subscriptionController.add(updatedSubscription);

      return updatedSubscription;
    } catch (e) {
      throw SubscriptionException('Failed to renew subscription: ${e.toString()}');
    }
  }

  // Change subscription plan
  Future<Subscription> changePlan({
    required String subscriptionId,
    required SubscriptionPlan newPlan,
  }) async {
    try {
      final subscription = await _getSubscription(subscriptionId);
      if (subscription == null) {
        throw SubscriptionException('Subscription not found');
      }

      final updatedSubscription = subscription.copyWith(
        plan: newPlan,
        features: _getPlanFeatures(newPlan),
      );

      await _db.insertSubscription(updatedSubscription);
      _subscriptionController.add(updatedSubscription);

      return updatedSubscription;
    } catch (e) {
      throw SubscriptionException('Failed to change plan: ${e.toString()}');
    }
  }

  // Check if user is eligible for free subscription
  Future<bool> checkFreeSubscriptionEligibility(String userId) async {
    try {
      // Get user's location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Define eligible coordinates (example: within 5km radius)
      const eligibleRadius = 5000; // meters
      const targetLat = 0.0; // Replace with actual target latitude
      const targetLon = 0.0; // Replace with actual target longitude

      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        targetLat,
        targetLon,
      );

      return distance <= eligibleRadius;
    } catch (e) {
      throw SubscriptionException('Failed to check eligibility: ${e.toString()}');
    }
  }

  // Get subscription plan features
  Map<String, dynamic> getPlanFeatures(SubscriptionPlan plan) {
    return _planFeatures[plan] ?? _planFeatures[SubscriptionPlan.free]!;
  }

  // Get all available subscription plans
  List<Map<String, dynamic>> getAvailablePlans() {
    return SubscriptionPlan.values.map((plan) {
      final features = _planFeatures[plan]!;
      return {
        'plan': plan,
        ...features,
      };
    }).toList();
  }

  // Check if feature is available for subscription
  bool isFeatureAvailable(Subscription subscription, String feature) {
    final features = subscription.features;
    return features?.contains(feature) ?? false;
  }

  // Helper methods
  Future<Subscription?> _getSubscription(String subscriptionId) async {
    // Implement fetching specific subscription by ID
    // This is a placeholder implementation
    return null;
  }

  List<String> _getPlanFeatures(SubscriptionPlan plan) {
    final features = _planFeatures[plan];
    if (features == null) return [];

    return features.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .toList();
  }

  String _generateSubscriptionId() {
    return 'sub_${DateTime.now().millisecondsSinceEpoch}';
  }

  // Dispose resources
  void dispose() {
    _subscriptionController.close();
  }
}

class SubscriptionException implements Exception {
  final String message;

  SubscriptionException(this.message);

  @override
  String toString() => message;
}
