import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'subscription.g.dart';

/// Defines the available subscription tiers in the ZimLearn app
@HiveType(typeId: 20)
enum SubscriptionTier {
  @HiveField(0)
  basic,    // $1/month
  
  @HiveField(1)
  standard, // $2/month
  
  @HiveField(2)
  premium,  // $3/month
  
  @HiveField(3)
  family,   // Special tier for family accounts
}

/// Defines the available billing cycles for subscriptions
@HiveType(typeId: 21)
enum BillingCycle {
  @HiveField(0)
  monthly,
  
  @HiveField(1)
  quarterly,
  
  @HiveField(2)
  annually,
}

/// Defines the available payment methods for subscriptions
@HiveType(typeId: 22)
enum PaymentMethod {
  @HiveField(0)
  creditCard,
  
  @HiveField(1)
  paypal,
  
  @HiveField(2)
  mobileMoney,
  
  @HiveField(3)
  bankTransfer,
  
  @HiveField(4)
  inAppPurchase,
}

/// Defines a single feature available in a subscription tier
@HiveType(typeId: 23)
class SubscriptionFeature extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String description;
  
  @HiveField(3)
  final bool isAvailable;
  
  @HiveField(4)
  final int? limit;
  
  @HiveField(5)
  final String? iconName;

  const SubscriptionFeature({
    required this.id,
    required this.name,
    required this.description,
    required this.isAvailable,
    this.limit,
    this.iconName,
  });

  @override
  List<Object?> get props => [id, name, description, isAvailable, limit, iconName];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'isAvailable': isAvailable,
      'limit': limit,
      'iconName': iconName,
    };
  }

  factory SubscriptionFeature.fromJson(Map<String, dynamic> json) {
    return SubscriptionFeature(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      isAvailable: json['isAvailable'] ?? false,
      limit: json['limit'],
      iconName: json['iconName'],
    );
  }
}

/// Main subscription model that defines a subscription plan
@HiveType(typeId: 24)
class Subscription extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final SubscriptionTier tier;
  
  @HiveField(2)
  final double monthlyPrice;
  
  @HiveField(3)
  final String name;
  
  @HiveField(4)
  final String description;
  
  @HiveField(5)
  final List<SubscriptionFeature> features;
  
  @HiveField(6)
  final bool isPopular;
  
  @HiveField(7)
  final String? tagline;
  
  @HiveField(8)
  final String? badgeText;
  
  @HiveField(9)
  final DateTime createdAt;
  
  @HiveField(10)
  final DateTime updatedAt;

  const Subscription({
    required this.id,
    required this.tier,
    required this.monthlyPrice,
    required this.name,
    required this.description,
    required this.features,
    this.isPopular = false,
    this.tagline,
    this.badgeText,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        tier,
        monthlyPrice,
        name,
        description,
        features,
        isPopular,
        tagline,
        badgeText,
        createdAt,
        updatedAt,
      ];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tier': tier.name,
      'monthlyPrice': monthlyPrice,
      'name': name,
      'description': description,
      'features': features.map((feature) => feature.toJson()).toList(),
      'isPopular': isPopular,
      'tagline': tagline,
      'badgeText': badgeText,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'],
      tier: SubscriptionTier.values.firstWhere(
        (e) => e.name == json['tier'],
        orElse: () => SubscriptionTier.basic,
      ),
      monthlyPrice: (json['monthlyPrice'] as num).toDouble(),
      name: json['name'],
      description: json['description'],
      features: (json['features'] as List)
          .map((feature) => SubscriptionFeature.fromJson(feature))
          .toList(),
      isPopular: json['isPopular'] ?? false,
      tagline: json['tagline'],
      badgeText: json['badgeText'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // Helper methods
  double get annualPrice => monthlyPrice * 10; // 2 months free for annual
  double get quarterlyPrice => monthlyPrice * 2.7; // 10% discount for quarterly
  
  // Predefined subscriptions
  static Subscription get basicPlan {
    final now = DateTime.now();
    return Subscription(
      id: 'basic',
      tier: SubscriptionTier.basic,
      monthlyPrice: 1.0,
      name: 'Basic',
      description: 'Essential learning tools for beginners',
      features: [
        SubscriptionFeature(
          id: 'core_curriculum',
          name: 'Core ZIMSEC Curriculum',
          description: 'Access to essential subjects and lessons',
          isAvailable: true,
          iconName: 'book',
        ),
        SubscriptionFeature(
          id: 'offline_access',
          name: 'Limited Offline Access',
          description: 'Download up to 10 lessons for offline use',
          isAvailable: true,
          limit: 10,
          iconName: 'download',
        ),
        SubscriptionFeature(
          id: 'quizzes',
          name: 'Basic Quizzes',
          description: 'Access to standard quizzes and assessments',
          isAvailable: true,
          iconName: 'quiz',
        ),
        SubscriptionFeature(
          id: 'ai_tutor',
          name: 'AI Tutor',
          description: 'Limited access to AI tutor (5 questions/day)',
          isAvailable: true,
          limit: 5,
          iconName: 'smart_toy',
        ),
        SubscriptionFeature(
          id: 'business_sim',
          name: 'Business Simulation',
          description: 'Access to basic business simulation module',
          isAvailable: false,
          iconName: 'store',
        ),
        SubscriptionFeature(
          id: 'advanced_analytics',
          name: 'Advanced Analytics',
          description: 'Detailed learning progress and analytics',
          isAvailable: false,
          iconName: 'analytics',
        ),
      ],
      isPopular: false,
      badgeText: 'Basic',
      createdAt: now,
      updatedAt: now,
    );
  }
  
  static Subscription get standardPlan {
    final now = DateTime.now();
    return Subscription(
      id: 'standard',
      tier: SubscriptionTier.standard,
      monthlyPrice: 2.0,
      name: 'Standard',
      description: 'Complete learning experience with enhanced features',
      features: [
        SubscriptionFeature(
          id: 'core_curriculum',
          name: 'Full ZIMSEC Curriculum',
          description: 'Access to all subjects and lessons',
          isAvailable: true,
          iconName: 'book',
        ),
        SubscriptionFeature(
          id: 'offline_access',
          name: 'Extended Offline Access',
          description: 'Download up to 50 lessons for offline use',
          isAvailable: true,
          limit: 50,
          iconName: 'download',
        ),
        SubscriptionFeature(
          id: 'quizzes',
          name: 'Advanced Quizzes',
          description: 'Access to all quizzes and interactive assessments',
          isAvailable: true,
          iconName: 'quiz',
        ),
        SubscriptionFeature(
          id: 'ai_tutor',
          name: 'AI Tutor',
          description: 'Full access to AI tutor (20 questions/day)',
          isAvailable: true,
          limit: 20,
          iconName: 'smart_toy',
        ),
        SubscriptionFeature(
          id: 'business_sim',
          name: 'Business Simulation',
          description: 'Access to standard business simulation module',
          isAvailable: true,
          iconName: 'store',
        ),
        SubscriptionFeature(
          id: 'advanced_analytics',
          name: 'Advanced Analytics',
          description: 'Detailed learning progress and analytics',
          isAvailable: false,
          iconName: 'analytics',
        ),
      ],
      isPopular: true,
      tagline: 'Most Popular',
      badgeText: 'Standard',
      createdAt: now,
      updatedAt: now,
    );
  }
  
  static Subscription get premiumPlan {
    final now = DateTime.now();
    return Subscription(
      id: 'premium',
      tier: SubscriptionTier.premium,
      monthlyPrice: 3.0,
      name: 'Premium',
      description: 'Ultimate learning experience with all premium features',
      features: [
        SubscriptionFeature(
          id: 'core_curriculum',
          name: 'Complete ZIMSEC Curriculum',
          description: 'Access to all subjects, lessons and premium content',
          isAvailable: true,
          iconName: 'book',
        ),
        SubscriptionFeature(
          id: 'offline_access',
          name: 'Unlimited Offline Access',
          description: 'Download unlimited lessons for offline use',
          isAvailable: true,
          iconName: 'download',
        ),
        SubscriptionFeature(
          id: 'quizzes',
          name: 'Premium Quizzes',
          description: 'Access to all quizzes, assessments and practice tests',
          isAvailable: true,
          iconName: 'quiz',
        ),
        SubscriptionFeature(
          id: 'ai_tutor',
          name: 'Unlimited AI Tutor',
          description: 'Unlimited access to AI tutor with priority support',
          isAvailable: true,
          iconName: 'smart_toy',
        ),
        SubscriptionFeature(
          id: 'business_sim',
          name: 'Advanced Business Simulation',
          description: 'Access to premium business simulation with all industries',
          isAvailable: true,
          iconName: 'store',
        ),
        SubscriptionFeature(
          id: 'advanced_analytics',
          name: 'Advanced Analytics',
          description: 'Comprehensive learning analytics and personalized insights',
          isAvailable: true,
          iconName: 'analytics',
        ),
      ],
      isPopular: false,
      badgeText: 'Premium',
      createdAt: now,
      updatedAt: now,
    );
  }
  
  static List<Subscription> get allPlans => [
    basicPlan,
    standardPlan,
    premiumPlan,
  ];
}

/// Represents a user's subscription purchase
@HiveType(typeId: 25)
class SubscriptionPurchase extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String userId;
  
  @HiveField(2)
  final String subscriptionId;
  
  @HiveField(3)
  final SubscriptionTier tier;
  
  @HiveField(4)
  final BillingCycle billingCycle;
  
  @HiveField(5)
  final PaymentMethod paymentMethod;
  
  @HiveField(6)
  final double amount;
  
  @HiveField(7)
  final String? currency;
  
  @HiveField(8)
  final DateTime startDate;
  
  @HiveField(9)
  final DateTime endDate;
  
  @HiveField(10)
  final bool isActive;
  
  @HiveField(11)
  final bool autoRenew;
  
  @HiveField(12)
  final String? receiptId;
  
  @HiveField(13)
  final String? transactionId;
  
  @HiveField(14)
  final DateTime createdAt;
  
  @HiveField(15)
  final DateTime updatedAt;

  const SubscriptionPurchase({
    required this.id,
    required this.userId,
    required this.subscriptionId,
    required this.tier,
    required this.billingCycle,
    required this.paymentMethod,
    required this.amount,
    this.currency = 'USD',
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    this.autoRenew = true,
    this.receiptId,
    this.transactionId,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        subscriptionId,
        tier,
        billingCycle,
        paymentMethod,
        amount,
        currency,
        startDate,
        endDate,
        isActive,
        autoRenew,
        receiptId,
        transactionId,
        createdAt,
        updatedAt,
      ];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'subscriptionId': subscriptionId,
      'tier': tier.name,
      'billingCycle': billingCycle.name,
      'paymentMethod': paymentMethod.name,
      'amount': amount,
      'currency': currency,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
      'autoRenew': autoRenew,
      'receiptId': receiptId,
      'transactionId': transactionId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SubscriptionPurchase.fromJson(Map<String, dynamic> json) {
    return SubscriptionPurchase(
      id: json['id'],
      userId: json['userId'],
      subscriptionId: json['subscriptionId'],
      tier: SubscriptionTier.values.firstWhere(
        (e) => e.name == json['tier'],
        orElse: () => SubscriptionTier.basic,
      ),
      billingCycle: BillingCycle.values.firstWhere(
        (e) => e.name == json['billingCycle'],
        orElse: () => BillingCycle.monthly,
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == json['paymentMethod'],
        orElse: () => PaymentMethod.inAppPurchase,
      ),
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] ?? 'USD',
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      isActive: json['isActive'] ?? true,
      autoRenew: json['autoRenew'] ?? true,
      receiptId: json['receiptId'],
      transactionId: json['transactionId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  SubscriptionPurchase copyWith({
    String? userId,
    String? subscriptionId,
    SubscriptionTier? tier,
    BillingCycle? billingCycle,
    PaymentMethod? paymentMethod,
    double? amount,
    String? currency,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    bool? autoRenew,
    String? receiptId,
    String? transactionId,
    DateTime? updatedAt,
  }) {
    return SubscriptionPurchase(
      id: id,
      userId: userId ?? this.userId,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      tier: tier ?? this.tier,
      billingCycle: billingCycle ?? this.billingCycle,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      autoRenew: autoRenew ?? this.autoRenew,
      receiptId: receiptId ?? this.receiptId,
      transactionId: transactionId ?? this.transactionId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Helper methods
  bool get isExpired => DateTime.now().isAfter(endDate);
  int get daysRemaining => endDate.difference(DateTime.now()).inDays;
  bool get isTrialPeriod => tier == SubscriptionTier.basic && amount == 0;
  
  // Factory method for creating a new purchase
  static SubscriptionPurchase create({
    required String userId,
    required Subscription subscription,
    required BillingCycle billingCycle,
    required PaymentMethod paymentMethod,
    double? amount,
    String? currency,
    String? receiptId,
    String? transactionId,
    bool autoRenew = true,
  }) {
    final now = DateTime.now();
    final uuid = const Uuid().v4();
    
    // Calculate end date based on billing cycle
    DateTime endDate;
    double calculatedAmount;
    
    switch (billingCycle) {
      case BillingCycle.monthly:
        endDate = now.add(const Duration(days: 30));
        calculatedAmount = subscription.monthlyPrice;
        break;
      case BillingCycle.quarterly:
        endDate = now.add(const Duration(days: 90));
        calculatedAmount = subscription.quarterlyPrice;
        break;
      case BillingCycle.annually:
        endDate = now.add(const Duration(days: 365));
        calculatedAmount = subscription.annualPrice;
        break;
    }
    
    return SubscriptionPurchase(
      id: uuid,
      userId: userId,
      subscriptionId: subscription.id,
      tier: subscription.tier,
      billingCycle: billingCycle,
      paymentMethod: paymentMethod,
      amount: amount ?? calculatedAmount,
      currency: currency ?? 'USD',
      startDate: now,
      endDate: endDate,
      isActive: true,
      autoRenew: autoRenew,
      receiptId: receiptId,
      transactionId: transactionId,
      createdAt: now,
      updatedAt: now,
    );
  }
}
