import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/service_locator.dart';
import '../../../data/models/subscription.dart';
import '../../../data/models/user.dart';

// Events
abstract class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();

  @override
  List<Object?> get props => [];
}

class LoadSubscriptions extends SubscriptionEvent {
  const LoadSubscriptions();
}

class PurchaseSubscription extends SubscriptionEvent {
  final Subscription subscription;
  final BillingCycle billingCycle;
  final PaymentMethod paymentMethod;
  final String userId;

  const PurchaseSubscription({
    required this.subscription,
    required this.billingCycle,
    required this.paymentMethod,
    required this.userId,
  });

  @override
  List<Object?> get props => [subscription, billingCycle, paymentMethod, userId];
}

class CancelSubscription extends SubscriptionEvent {
  final String subscriptionPurchaseId;

  const CancelSubscription({required this.subscriptionPurchaseId});

  @override
  List<Object?> get props => [subscriptionPurchaseId];
}

class CheckSubscriptionStatus extends SubscriptionEvent {
  final String userId;

  const CheckSubscriptionStatus({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class RestoreSubscription extends SubscriptionEvent {
  final String userId;

  const RestoreSubscription({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class UpdateSubscriptionPaymentMethod extends SubscriptionEvent {
  final String subscriptionPurchaseId;
  final PaymentMethod newPaymentMethod;

  const UpdateSubscriptionPaymentMethod({
    required this.subscriptionPurchaseId,
    required this.newPaymentMethod,
  });

  @override
  List<Object?> get props => [subscriptionPurchaseId, newPaymentMethod];
}

class ToggleAutoRenew extends SubscriptionEvent {
  final String subscriptionPurchaseId;
  final bool autoRenew;

  const ToggleAutoRenew({
    required this.subscriptionPurchaseId,
    required this.autoRenew,
  });

  @override
  List<Object?> get props => [subscriptionPurchaseId, autoRenew];
}

// States
abstract class SubscriptionState extends Equatable {
  const SubscriptionState();

  @override
  List<Object?> get props => [];
}

class SubscriptionInitial extends SubscriptionState {}

class SubscriptionLoading extends SubscriptionState {}

class SubscriptionLoaded extends SubscriptionState {
  final List<Subscription> availableSubscriptions;

  const SubscriptionLoaded({required this.availableSubscriptions});

  @override
  List<Object?> get props => [availableSubscriptions];
}

class SubscriptionPurchased extends SubscriptionState {
  final SubscriptionPurchase purchase;

  const SubscriptionPurchased({required this.purchase});

  @override
  List<Object?> get props => [purchase];
}

class SubscriptionCancelled extends SubscriptionState {
  final String subscriptionPurchaseId;

  const SubscriptionCancelled({required this.subscriptionPurchaseId});

  @override
  List<Object?> get props => [subscriptionPurchaseId];
}

class SubscriptionError extends SubscriptionState {
  final String message;
  final Object? error;

  const SubscriptionError({required this.message, this.error});

  @override
  List<Object?> get props => [message, error];
}

class SubscriptionActive extends SubscriptionState {
  final SubscriptionPurchase activePurchase;
  final Subscription subscription;
  final int daysRemaining;

  const SubscriptionActive({
    required this.activePurchase,
    required this.subscription,
    required this.daysRemaining,
  });

  @override
  List<Object?> get props => [activePurchase, subscription, daysRemaining];
}

class SubscriptionInactive extends SubscriptionState {
  final List<Subscription> recommendedSubscriptions;

  const SubscriptionInactive({required this.recommendedSubscriptions});

  @override
  List<Object?> get props => [recommendedSubscriptions];
}

class SubscriptionAutoRenewUpdated extends SubscriptionState {
  final String subscriptionPurchaseId;
  final bool autoRenew;

  const SubscriptionAutoRenewUpdated({
    required this.subscriptionPurchaseId,
    required this.autoRenew,
  });

  @override
  List<Object?> get props => [subscriptionPurchaseId, autoRenew];
}

class SubscriptionPaymentMethodUpdated extends SubscriptionState {
  final String subscriptionPurchaseId;
  final PaymentMethod paymentMethod;

  const SubscriptionPaymentMethodUpdated({
    required this.subscriptionPurchaseId,
    required this.paymentMethod,
  });

  @override
  List<Object?> get props => [subscriptionPurchaseId, paymentMethod];
}

// BLoC
class SubscriptionBloc extends HydratedBloc<SubscriptionEvent, SubscriptionState> {
  final Logger _logger = sl<Logger>();
  List<Subscription> _availableSubscriptions = [];
  List<SubscriptionPurchase> _userPurchases = [];

  SubscriptionBloc() : super(SubscriptionInitial()) {
    on<LoadSubscriptions>(_onLoadSubscriptions);
    on<PurchaseSubscription>(_onPurchaseSubscription);
    on<CancelSubscription>(_onCancelSubscription);
    on<CheckSubscriptionStatus>(_onCheckSubscriptionStatus);
    on<RestoreSubscription>(_onRestoreSubscription);
    on<UpdateSubscriptionPaymentMethod>(_onUpdateSubscriptionPaymentMethod);
    on<ToggleAutoRenew>(_onToggleAutoRenew);
  }

  Future<void> _onLoadSubscriptions(
    LoadSubscriptions event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      emit(SubscriptionLoading());
      
      // In a real app, we would fetch this from an API
      // For now, we'll use the predefined plans
      _availableSubscriptions = Subscription.allPlans;
      
      emit(SubscriptionLoaded(availableSubscriptions: _availableSubscriptions));
    } catch (e, stackTrace) {
      _logger.e('Error loading subscriptions', error: e, stackTrace: stackTrace);
      emit(SubscriptionError(message: 'Failed to load subscription plans: ${e.toString()}', error: e));
    }
  }

  Future<void> _onPurchaseSubscription(
    PurchaseSubscription event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      emit(SubscriptionLoading());
      
      // In a real app, we would process payment through a payment gateway
      // and store the purchase in a backend database
      
      // Create subscription purchase record
      final purchase = SubscriptionPurchase.create(
        userId: event.userId,
        subscription: event.subscription,
        billingCycle: event.billingCycle,
        paymentMethod: event.paymentMethod,
      );
      
      // Add to user purchases
      _userPurchases.add(purchase);
      
      // In a real app, we would save this to a database
      // For now, we'll rely on HydratedBloc to persist it
      
      emit(SubscriptionPurchased(purchase: purchase));
      
      // Also update the active status
      emit(SubscriptionActive(
        activePurchase: purchase,
        subscription: event.subscription,
        daysRemaining: purchase.daysRemaining,
      ));
    } catch (e, stackTrace) {
      _logger.e('Error purchasing subscription', error: e, stackTrace: stackTrace);
      emit(SubscriptionError(message: 'Failed to purchase subscription: ${e.toString()}', error: e));
    }
  }

  Future<void> _onCancelSubscription(
    CancelSubscription event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      emit(SubscriptionLoading());
      
      // Find the subscription purchase
      final purchaseIndex = _userPurchases.indexWhere((p) => p.id == event.subscriptionPurchaseId);
      
      if (purchaseIndex == -1) {
        emit(SubscriptionError(message: 'Subscription not found'));
        return;
      }
      
      // Update the subscription to inactive
      final purchase = _userPurchases[purchaseIndex];
      final updatedPurchase = purchase.copyWith(
        isActive: false,
        autoRenew: false,
        updatedAt: DateTime.now(),
      );
      
      // Update the list
      _userPurchases[purchaseIndex] = updatedPurchase;
      
      emit(SubscriptionCancelled(subscriptionPurchaseId: event.subscriptionPurchaseId));
      
      // Also update to inactive status
      emit(SubscriptionInactive(recommendedSubscriptions: _availableSubscriptions));
    } catch (e, stackTrace) {
      _logger.e('Error cancelling subscription', error: e, stackTrace: stackTrace);
      emit(SubscriptionError(message: 'Failed to cancel subscription: ${e.toString()}', error: e));
    }
  }

  Future<void> _onCheckSubscriptionStatus(
    CheckSubscriptionStatus event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      emit(SubscriptionLoading());
      
      // Filter purchases for this user
      final userPurchases = _userPurchases.where((p) => p.userId == event.userId).toList();
      
      // Find active subscription
      final activePurchase = userPurchases.where((p) => 
        p.isActive && 
        !p.isExpired
      ).toList();
      
      if (activePurchase.isEmpty) {
        emit(SubscriptionInactive(recommendedSubscriptions: _availableSubscriptions));
        return;
      }
      
      // Sort by end date to get the furthest expiring subscription
      activePurchase.sort((a, b) => b.endDate.compareTo(a.endDate));
      
      final purchase = activePurchase.first;
      final subscription = _availableSubscriptions.firstWhere(
        (s) => s.id == purchase.subscriptionId,
        orElse: () => Subscription.basicPlan,
      );
      
      emit(SubscriptionActive(
        activePurchase: purchase,
        subscription: subscription,
        daysRemaining: purchase.daysRemaining,
      ));
    } catch (e, stackTrace) {
      _logger.e('Error checking subscription status', error: e, stackTrace: stackTrace);
      emit(SubscriptionError(message: 'Failed to check subscription status: ${e.toString()}', error: e));
    }
  }

  Future<void> _onRestoreSubscription(
    RestoreSubscription event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      emit(SubscriptionLoading());
      
      // In a real app, we would verify purchases with the app store
      // For now, we'll just check our local records
      
      // Check if user has any purchases
      final userPurchases = _userPurchases.where((p) => p.userId == event.userId).toList();
      
      if (userPurchases.isEmpty) {
        emit(SubscriptionError(message: 'No subscriptions found to restore'));
        return;
      }
      
      // Find the most recent active purchase
      userPurchases.sort((a, b) => b.endDate.compareTo(a.endDate));
      
      final purchase = userPurchases.first;
      final subscription = _availableSubscriptions.firstWhere(
        (s) => s.id == purchase.subscriptionId,
        orElse: () => Subscription.basicPlan,
      );
      
      // If it's expired, we'll need to reactivate it
      if (purchase.isExpired) {
        // In a real app, we would process payment again
        // For now, we'll just extend the date
        
        final now = DateTime.now();
        final updatedPurchase = purchase.copyWith(
          isActive: true,
          startDate: now,
          endDate: now.add(const Duration(days: 30)),
          updatedAt: now,
        );
        
        // Update the list
        final index = _userPurchases.indexWhere((p) => p.id == purchase.id);
        if (index != -1) {
          _userPurchases[index] = updatedPurchase;
        }
        
        emit(SubscriptionPurchased(purchase: updatedPurchase));
        
        emit(SubscriptionActive(
          activePurchase: updatedPurchase,
          subscription: subscription,
          daysRemaining: updatedPurchase.daysRemaining,
        ));
      } else {
        // It's still active, just emit the active state
        emit(SubscriptionActive(
          activePurchase: purchase,
          subscription: subscription,
          daysRemaining: purchase.daysRemaining,
        ));
      }
    } catch (e, stackTrace) {
      _logger.e('Error restoring subscription', error: e, stackTrace: stackTrace);
      emit(SubscriptionError(message: 'Failed to restore subscription: ${e.toString()}', error: e));
    }
  }

  Future<void> _onUpdateSubscriptionPaymentMethod(
    UpdateSubscriptionPaymentMethod event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      emit(SubscriptionLoading());
      
      // Find the subscription purchase
      final purchaseIndex = _userPurchases.indexWhere((p) => p.id == event.subscriptionPurchaseId);
      
      if (purchaseIndex == -1) {
        emit(SubscriptionError(message: 'Subscription not found'));
        return;
      }
      
      // Update the payment method
      final purchase = _userPurchases[purchaseIndex];
      final updatedPurchase = purchase.copyWith(
        paymentMethod: event.newPaymentMethod,
        updatedAt: DateTime.now(),
      );
      
      // Update the list
      _userPurchases[purchaseIndex] = updatedPurchase;
      
      emit(SubscriptionPaymentMethodUpdated(
        subscriptionPurchaseId: event.subscriptionPurchaseId,
        paymentMethod: event.newPaymentMethod,
      ));
    } catch (e, stackTrace) {
      _logger.e('Error updating payment method', error: e, stackTrace: stackTrace);
      emit(SubscriptionError(message: 'Failed to update payment method: ${e.toString()}', error: e));
    }
  }

  Future<void> _onToggleAutoRenew(
    ToggleAutoRenew event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      emit(SubscriptionLoading());
      
      // Find the subscription purchase
      final purchaseIndex = _userPurchases.indexWhere((p) => p.id == event.subscriptionPurchaseId);
      
      if (purchaseIndex == -1) {
        emit(SubscriptionError(message: 'Subscription not found'));
        return;
      }
      
      // Update auto-renew setting
      final purchase = _userPurchases[purchaseIndex];
      final updatedPurchase = purchase.copyWith(
        autoRenew: event.autoRenew,
        updatedAt: DateTime.now(),
      );
      
      // Update the list
      _userPurchases[purchaseIndex] = updatedPurchase;
      
      emit(SubscriptionAutoRenewUpdated(
        subscriptionPurchaseId: event.subscriptionPurchaseId,
        autoRenew: event.autoRenew,
      ));
    } catch (e, stackTrace) {
      _logger.e('Error toggling auto-renew', error: e, stackTrace: stackTrace);
      emit(SubscriptionError(message: 'Failed to toggle auto-renew: ${e.toString()}', error: e));
    }
  }

  @override
  SubscriptionState? fromJson(Map<String, dynamic> json) {
    try {
      final subscriptions = (json['availableSubscriptions'] as List?)
          ?.map((e) => Subscription.fromJson(e as Map<String, dynamic>))
          .toList() ?? [];
      
      final purchases = (json['userPurchases'] as List?)
          ?.map((e) => SubscriptionPurchase.fromJson(e as Map<String, dynamic>))
          .toList() ?? [];
      
      _availableSubscriptions = subscriptions.isEmpty ? Subscription.allPlans : subscriptions;
      _userPurchases = purchases;
      
      if (json['currentState'] == 'loaded') {
        return SubscriptionLoaded(availableSubscriptions: _availableSubscriptions);
      } else if (json['currentState'] == 'active' && json['activePurchaseId'] != null) {
        final purchaseId = json['activePurchaseId'] as String;
        final purchase = _userPurchases.firstWhere(
          (p) => p.id == purchaseId,
          orElse: () => purchases.first,
        );
        
        final subscription = _availableSubscriptions.firstWhere(
          (s) => s.id == purchase.subscriptionId,
          orElse: () => Subscription.basicPlan,
        );
        
        return SubscriptionActive(
          activePurchase: purchase,
          subscription: subscription,
          daysRemaining: purchase.daysRemaining,
        );
      }
      
      return SubscriptionLoaded(availableSubscriptions: _availableSubscriptions);
    } catch (e, stackTrace) {
      _logger.e('Error deserializing subscription state', error: e, stackTrace: stackTrace);
      return SubscriptionInitial();
    }
  }

  @override
  Map<String, dynamic>? toJson(SubscriptionState state) {
    try {
      final Map<String, dynamic> json = {
        'availableSubscriptions': _availableSubscriptions.map((s) => s.toJson()).toList(),
        'userPurchases': _userPurchases.map((p) => p.toJson()).toList(),
      };
      
      if (state is SubscriptionLoaded) {
        json['currentState'] = 'loaded';
      } else if (state is SubscriptionActive) {
        json['currentState'] = 'active';
        json['activePurchaseId'] = state.activePurchase.id;
      } else if (state is SubscriptionInactive) {
        json['currentState'] = 'inactive';
      }
      
      return json;
    } catch (e, stackTrace) {
      _logger.e('Error serializing subscription state', error: e, stackTrace: stackTrace);
      return null;
    }
  }
}
