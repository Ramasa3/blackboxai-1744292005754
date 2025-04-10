class Subscription {
  final String id;
  final String userId;
  final SubscriptionPlan plan;
  final DateTime startDate;
  final DateTime endDate;
  final SubscriptionStatus status;
  final PaymentInfo? paymentInfo;
  final bool isAutoRenew;
  final List<String>? features;

  Subscription({
    required this.id,
    required this.userId,
    required this.plan,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.paymentInfo,
    this.isAutoRenew = false,
    this.features,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      plan: SubscriptionPlan.values.firstWhere(
        (plan) => plan.toString().split('.').last == json['plan'],
        orElse: () => SubscriptionPlan.basic,
      ),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      status: SubscriptionStatus.values.firstWhere(
        (status) => status.toString().split('.').last == json['status'],
        orElse: () => SubscriptionStatus.inactive,
      ),
      paymentInfo: json['payment_info'] != null
          ? PaymentInfo.fromJson(json['payment_info'] as Map<String, dynamic>)
          : null,
      isAutoRenew: json['is_auto_renew'] as bool? ?? false,
      features: json['features'] != null
          ? List<String>.from(json['features'] as List)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'plan': plan.toString().split('.').last,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'status': status.toString().split('.').last,
      'payment_info': paymentInfo?.toJson(),
      'is_auto_renew': isAutoRenew,
      'features': features,
    };
  }

  bool get isActive => status == SubscriptionStatus.active;
  
  bool get isExpired => endDate.isBefore(DateTime.now());
  
  Duration get remainingDuration => endDate.difference(DateTime.now());
  
  bool get needsRenewal => remainingDuration.inDays <= 7;

  Subscription copyWith({
    String? id,
    String? userId,
    SubscriptionPlan? plan,
    DateTime? startDate,
    DateTime? endDate,
    SubscriptionStatus? status,
    PaymentInfo? paymentInfo,
    bool? isAutoRenew,
    List<String>? features,
  }) {
    return Subscription(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      plan: plan ?? this.plan,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      paymentInfo: paymentInfo ?? this.paymentInfo,
      isAutoRenew: isAutoRenew ?? this.isAutoRenew,
      features: features ?? this.features,
    );
  }
}

class PaymentInfo {
  final String id;
  final String method;
  final String lastFourDigits;
  final DateTime expiryDate;
  final bool isDefault;

  PaymentInfo({
    required this.id,
    required this.method,
    required this.lastFourDigits,
    required this.expiryDate,
    this.isDefault = false,
  });

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      id: json['id'] as String,
      method: json['method'] as String,
      lastFourDigits: json['last_four_digits'] as String,
      expiryDate: DateTime.parse(json['expiry_date'] as String),
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'method': method,
      'last_four_digits': lastFourDigits,
      'expiry_date': expiryDate.toIso8601String(),
      'is_default': isDefault,
    };
  }
}

enum SubscriptionPlan {
  basic,
  standard,
  premium,
  free
}

enum SubscriptionStatus {
  active,
  inactive,
  cancelled,
  suspended,
  pending
}

class SubscriptionFeatures {
  static const Map<SubscriptionPlan, Map<String, dynamic>> features = {
    SubscriptionPlan.basic: {
      'maxDevices': 1,
      'quality': 'HD',
      'downloadAllowed': false,
      'watchPartyAllowed': false,
      'adsEnabled': true,
      'pricePerMonth': 9.99,
    },
    SubscriptionPlan.standard: {
      'maxDevices': 2,
      'quality': 'Full HD',
      'downloadAllowed': true,
      'watchPartyAllowed': true,
      'adsEnabled': false,
      'pricePerMonth': 14.99,
    },
    SubscriptionPlan.premium: {
      'maxDevices': 4,
      'quality': '4K Ultra HD',
      'downloadAllowed': true,
      'watchPartyAllowed': true,
      'adsEnabled': false,
      'pricePerMonth': 19.99,
    },
    SubscriptionPlan.free: {
      'maxDevices': 1,
      'quality': 'SD',
      'downloadAllowed': false,
      'watchPartyAllowed': false,
      'adsEnabled': true,
      'pricePerMonth': 0.00,
    },
  };

  static Map<String, dynamic> getFeatures(SubscriptionPlan plan) {
    return features[plan] ?? features[SubscriptionPlan.free]!;
  }

  static double getPrice(SubscriptionPlan plan) {
    return features[plan]?['pricePerMonth'] ?? 0.00;
  }

  static bool isFeatureAvailable(SubscriptionPlan plan, String feature) {
    return features[plan]?[feature] ?? false;
  }
}
