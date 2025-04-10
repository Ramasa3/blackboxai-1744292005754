import 'dart:async';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../config/constants.dart';
import '../models/subscription.dart';
import 'analytics_service.dart';
import 'error_service.dart';

class PurchaseService {
  static final PurchaseService _instance = PurchaseService._internal();
  final AnalyticsService _analyticsService = AnalyticsService();
  final ErrorService _errorService = ErrorService();
  
  final _purchaseController = StreamController<PurchaseState>.broadcast();
  Stream<PurchaseState> get purchaseStream => _purchaseController.stream;

  factory PurchaseService() {
    return _instance;
  }

  PurchaseService._internal();

  Future<void> init() async {
    try {
      await Purchases.setDebugLogsEnabled(kDebugMode);
      await Purchases.setup(AppConstants.revenueCatApiKey);
      
      // Configure observer mode for Amazon
      if (await _isAmazonDevice()) {
        await Purchases.enableAmazonObserverMode();
      }

      // Setup default attributes
      await Purchases.setAttributes({
        'app_version': AppConstants.appVersion,
        'build_number': AppConstants.appBuildNumber,
      });

    } catch (e, s) {
      await _errorService.reportHandledException(
        e,
        s,
        context: 'Initializing purchase service',
      );
    }
  }

  Future<bool> _isAmazonDevice() async {
    // Implement Amazon device detection
    return false;
  }

  Future<List<Package>> getAvailablePackages() async {
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      
      if (current == null) {
        throw PurchaseException('No offerings available');
      }

      return current.availablePackages;
    } catch (e, s) {
      await _errorService.reportHandledException(
        e,
        s,
        context: 'Getting available packages',
      );
      rethrow;
    }
  }

  Future<CustomerInfo> purchasePackage(Package package) async {
    try {
      _purchaseController.add(PurchaseState.processing);
      
      final purchaseResult = await Purchases.purchasePackage(package);
      
      await _analyticsService.logEvent(
        name: 'subscription_purchased',
        parameters: {
          'package_id': package.identifier,
          'offering_id': package.offeringIdentifier,
        },
      );

      _purchaseController.add(PurchaseState.completed);
      
      return purchaseResult.customerInfo;
    } catch (e, s) {
      _purchaseController.add(PurchaseState.error);
      
      if (e is PurchasesErrorCode) {
        if (e != PurchasesErrorCode.purchaseCancelledError) {
          await _errorService.reportHandledException(
            e,
            s,
            context: 'Purchasing package',
            parameters: {
              'package_id': package.identifier,
              'offering_id': package.offeringIdentifier,
            },
          );
        }
      }
      
      rethrow;
    }
  }

  Future<CustomerInfo> restorePurchases() async {
    try {
      _purchaseController.add(PurchaseState.restoring);
      
      final customerInfo = await Purchases.restorePurchases();
      
      await _analyticsService.logEvent(
        name: 'purchases_restored',
        parameters: {
          'success': true,
        },
      );

      _purchaseController.add(PurchaseState.completed);
      
      return customerInfo;
    } catch (e, s) {
      _purchaseController.add(PurchaseState.error);
      
      await _errorService.reportHandledException(
        e,
        s,
        context: 'Restoring purchases',
      );
      
      rethrow;
    }
  }

  Future<CustomerInfo> getCurrentCustomerInfo() async {
    try {
      return await Purchases.getCustomerInfo();
    } catch (e, s) {
      await _errorService.reportHandledException(
        e,
        s,
        context: 'Getting customer info',
      );
      rethrow;
    }
  }

  Future<void> setUserId(String userId) async {
    try {
      await Purchases.logIn(userId);
    } catch (e, s) {
      await _errorService.reportHandledException(
        e,
        s,
        context: 'Setting user ID',
        parameters: {'user_id': userId},
      );
    }
  }

  Future<void> logOut() async {
    try {
      await Purchases.logOut();
    } catch (e, s) {
      await _errorService.reportHandledException(
        e,
        s,
        context: 'Logging out purchases',
      );
    }
  }

  Future<bool> isSubscriptionActive() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.active.isNotEmpty;
    } catch (e, s) {
      await _errorService.reportHandledException(
        e,
        s,
        context: 'Checking subscription status',
      );
      return false;
    }
  }

  Future<SubscriptionPlan?> getCurrentPlan() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final activeEntitlement = customerInfo.entitlements.active.values.firstOrNull;
      
      if (activeEntitlement == null) return null;

      return _mapEntitlementToPlan(activeEntitlement);
    } catch (e, s) {
      await _errorService.reportHandledException(
        e,
        s,
        context: 'Getting current plan',
      );
      return null;
    }
  }

  SubscriptionPlan _mapEntitlementToPlan(EntitlementInfo entitlement) {
    switch (entitlement.identifier.toLowerCase()) {
      case 'premium':
        return SubscriptionPlan.premium;
      case 'standard':
        return SubscriptionPlan.standard;
      case 'basic':
        return SubscriptionPlan.basic;
      default:
        return SubscriptionPlan.free;
    }
  }

  Future<void> setAttributes(Map<String, String> attributes) async {
    try {
      await Purchases.setAttributes(attributes);
    } catch (e, s) {
      await _errorService.reportHandledException(
        e,
        s,
        context: 'Setting attributes',
        parameters: attributes,
      );
    }
  }

  Future<void> setEmail(String email) async {
    try {
      await Purchases.setEmail(email);
    } catch (e, s) {
      await _errorService.reportHandledException(
        e,
        s,
        context: 'Setting email',
        parameters: {'email': email},
      );
    }
  }

  Future<void> setPhoneNumber(String phoneNumber) async {
    try {
      await Purchases.setPhoneNumber(phoneNumber);
    } catch (e, s) {
      await _errorService.reportHandledException(
        e,
        s,
        context: 'Setting phone number',
        parameters: {'phone_number': phoneNumber},
      );
    }
  }

  Future<void> presentCodeRedemptionSheet() async {
    try {
      await Purchases.presentCodeRedemptionSheet();
    } catch (e, s) {
      await _errorService.reportHandledException(
        e,
        s,
        context: 'Presenting code redemption sheet',
      );
    }
  }

  void dispose() {
    _purchaseController.close();
  }
}

enum PurchaseState {
  initial,
  processing,
  restoring,
  completed,
  error,
}

class PurchaseException implements Exception {
  final String message;
  final dynamic error;

  PurchaseException(this.message, {this.error});

  @override
  String toString() {
    return 'PurchaseException: $message${error != null ? ' ($error)' : ''}';
  }
}

extension PackageExtension on Package {
  String get localizedPrice {
    return product.priceString;
  }

  String get localizedPeriod {
    switch (packageType) {
      case PackageType.monthly:
        return 'month';
      case PackageType.annual:
        return 'year';
      case PackageType.lifetime:
        return 'lifetime';
      default:
        return '';
    }
  }

  String get description {
    return product.description;
  }

  bool get isPopular {
    return identifier.toLowerCase().contains('popular');
  }

  bool get isBestValue {
    return identifier.toLowerCase().contains('best_value');
  }

  double get savings {
    if (packageType == PackageType.annual) {
      final monthlyPrice = product.price / 12;
      final monthlyPackage = offering?.monthly;
      if (monthlyPackage != null) {
        final savings = ((monthlyPackage.product.price * 12) - product.price) / (monthlyPackage.product.price * 12) * 100;
        return savings;
      }
    }
    return 0;
  }
}
