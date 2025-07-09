import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';

import '../../../core/constants.dart';
import '../../../core/services/service_locator.dart';
import '../../../data/models/subscription.dart';
import '../../common/widgets/glassmorphic_widgets.dart';
import '../bloc/subscription_bloc.dart';
import '../widgets/subscription_feature_item.dart';

class PricingPage extends StatefulWidget {
  const PricingPage({Key? key}) : super(key: key);

  @override
  State<PricingPage> createState() => _PricingPageState();
}

class _PricingPageState extends State<PricingPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late PageController _pageController;
  int _currentPage = 1; // Start with Standard plan selected
  BillingCycle _selectedBillingCycle = BillingCycle.monthly;
  
  // Get subscription plans
  final List<Subscription> _subscriptionPlans = Subscription.allPlans;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward();
    
    _pageController = PageController(
      initialPage: _currentPage,
      viewportFraction: 0.85,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassmorphicAppBar(
        title: 'Choose Your Plan',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF008751).withOpacity(0.8), // Green (Zimbabwe flag)
              const Color(0xFF000000).withOpacity(0.9), // Black (Zimbabwe flag)
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Billing cycle selector
              _buildBillingCycleSelector(theme),
              
              // Subscription cards carousel
              Expanded(
                child: isTablet
                    ? _buildTabletLayout(theme)
                    : _buildMobileLayout(theme),
              ),
              
              // Bottom info and help
              _buildBottomInfo(theme),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMobileLayout(ThemeData theme) {
    return Column(
      children: [
        // Subscription cards carousel
        SizedBox(
          height: 480,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _subscriptionPlans.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final isSelected = index == _currentPage;
              final subscription = _subscriptionPlans[index];
              
              // Apply a scale effect to the current card
              return TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: isSelected ? 0.8 : 1.0,
                  end: isSelected ? 1.0 : 0.8,
                ),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: _buildSubscriptionCard(subscription, theme, index),
              );
            },
          ),
        ),
        
        // Page indicator
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _subscriptionPlans.length,
              (index) => _buildPageIndicator(index, theme),
            ),
          ),
        ),
        
        // Purchase button
        _buildPurchaseButton(theme),
      ],
    );
  }
  
  Widget _buildTabletLayout(ThemeData theme) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Row(
              children: List.generate(
                _subscriptionPlans.length,
                (index) {
                  final subscription = _subscriptionPlans[index];
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentPage = index;
                          });
                        },
                        child: _buildSubscriptionCard(subscription, theme, index),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        
        // Purchase button
        _buildPurchaseButton(theme),
      ],
    );
  }
  
  Widget _buildBillingCycleSelector(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: GlassmorphicCard(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildBillingCycleOption(
              theme,
              BillingCycle.monthly,
              'Monthly',
              'Full price',
            ),
            _buildBillingCycleOption(
              theme,
              BillingCycle.quarterly,
              'Quarterly',
              'Save 10%',
            ),
            _buildBillingCycleOption(
              theme,
              BillingCycle.annually,
              'Annually',
              'Save 16%',
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBillingCycleOption(
    ThemeData theme,
    BillingCycle cycle,
    String label,
    String sublabel,
  ) {
    final isSelected = _selectedBillingCycle == cycle;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedBillingCycle = cycle;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.secondary.withOpacity(0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(
                  color: theme.colorScheme.secondary,
                  width: 1,
                )
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            Text(
              sublabel,
              style: TextStyle(
                color: isSelected ? Colors.white70 : Colors.white30,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSubscriptionCard(Subscription subscription, ThemeData theme, int index) {
    final isSelected = index == _currentPage;
    final isPopular = subscription.isPopular;
    
    // Calculate price based on billing cycle
    double price;
    String billingLabel;
    
    switch (_selectedBillingCycle) {
      case BillingCycle.monthly:
        price = subscription.monthlyPrice;
        billingLabel = '/month';
        break;
      case BillingCycle.quarterly:
        price = subscription.quarterlyPrice;
        billingLabel = '/quarter';
        break;
      case BillingCycle.annually:
        price = subscription.annualPrice;
        billingLabel = '/year';
        break;
    }
    
    // Animation for card entrance
    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          0.1 * index,
          0.1 * index + 0.5,
          curve: Curves.easeOut,
        ),
      ),
    );
    
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(animation),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            GlassmorphicCard(
              height: 450,
              color: isPopular
                  ? theme.colorScheme.secondary.withOpacity(0.3)
                  : null,
              border: isSelected
                  ? Border.all(
                      color: isPopular
                          ? theme.colorScheme.secondary
                          : Colors.white.withOpacity(0.5),
                      width: 2,
                    )
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Plan name and badge
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          subscription.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (subscription.badgeText != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isPopular
                                  ? theme.colorScheme.secondary
                                  : Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              subscription.badgeText!,
                              style: TextStyle(
                                color: isPopular ? Colors.black : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Price
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '\$',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          price.toStringAsFixed(2),
                          style: theme.textTheme.headlineLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          billingLabel,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Description
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      subscription.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  
                  // Features
                  Expanded(
                    child: ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: subscription.features.length,
                      itemBuilder: (context, index) {
                        final feature = subscription.features[index];
                        return SubscriptionFeatureItem(
                          feature: feature,
                          isAvailable: feature.isAvailable,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            // Popular badge
            if (isPopular)
              Positioned(
                top: -15,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star,
                        color: Colors.black,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'MOST POPULAR',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPageIndicator(int index, ThemeData theme) {
    final isSelected = index == _currentPage;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isSelected ? 24 : 8,
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.secondary
            : Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
  
  Widget _buildPurchaseButton(ThemeData theme) {
    final subscription = _subscriptionPlans[_currentPage];
    
    // Calculate price based on billing cycle
    double price;
    String billingText;
    
    switch (_selectedBillingCycle) {
      case BillingCycle.monthly:
        price = subscription.monthlyPrice;
        billingText = 'monthly';
        break;
      case BillingCycle.quarterly:
        price = subscription.quarterlyPrice;
        billingText = 'quarterly';
        break;
      case BillingCycle.annually:
        price = subscription.annualPrice;
        billingText = 'annual';
        break;
    }
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          AnimatedGlassmorphicButton(
            height: 56,
            color: theme.colorScheme.secondary,
            onPressed: () {
              _handleSubscriptionPurchase(subscription);
            },
            child: Text(
              'Subscribe for \$${price.toStringAsFixed(2)} $billingText',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Cancel anytime. No commitment required.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildBottomInfo(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Secure payment processing',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {
                  // Navigate to terms of service
                },
                child: Text(
                  'Terms of Service',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ),
              const Text(
                '•',
                style: TextStyle(color: Colors.white70),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to privacy policy
                },
                child: Text(
                  'Privacy Policy',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  void _handleSubscriptionPurchase(Subscription subscription) {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    // Simulate payment processing
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop(); // Close loading dialog
      
      // Show success animation
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Lottie.asset(
                  'assets/animations/success.json',
                  fit: BoxFit.contain,
                  onLoaded: (composition) {
                    Future.delayed(composition.duration, () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop(); // Return to previous screen
                    });
                  },
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 100,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Subscription Activated!',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Thank you for subscribing to ${subscription.name}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
      
      // In a real app, we would dispatch an event to the subscription bloc
      // context.read<SubscriptionBloc>().add(
      //   SubscriptionPurchased(
      //     subscription: subscription,
      //     billingCycle: _selectedBillingCycle,
      //   ),
      // );
    });
  }
}
