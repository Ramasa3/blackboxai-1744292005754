import 'package:flutter/material.dart';
import '../models/subscription.dart';
import '../services/subscription_service.dart';
import '../config/theme.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  bool _isLoading = false;
  SubscriptionPlan? _selectedPlan;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Plans'),
        backgroundColor: AppTheme.primaryBlack,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryRed,
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(),
                  _buildSubscriptionPlans(),
                  _buildCurrentSubscription(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primaryRed,
            AppTheme.primaryRed.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.star,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Choose Your Plan',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select the perfect plan for your entertainment needs',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionPlans() {
    final plans = _subscriptionService.getAvailablePlans();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: plans.map((plan) {
          final planType = plan['plan'] as SubscriptionPlan;
          final isSelected = _selectedPlan == planType;

          return _SubscriptionPlanCard(
            plan: planType,
            features: plan,
            isSelected: isSelected,
            onSelected: (plan) {
              setState(() => _selectedPlan = plan);
              _showSubscriptionDialog(plan);
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCurrentSubscription() {
    return StreamBuilder<Subscription?>(
      stream: _subscriptionService.subscriptionStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final subscription = snapshot.data;
        if (subscription == null) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[800]!,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Current Subscription',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildSubscriptionDetail(
                'Plan',
                subscription.plan.toString().split('.').last,
              ),
              _buildSubscriptionDetail(
                'Status',
                subscription.status.toString().split('.').last,
              ),
              _buildSubscriptionDetail(
                'Valid Until',
                _formatDate(subscription.endDate),
              ),
              const SizedBox(height: 16),
              if (subscription.isActive)
                ElevatedButton(
                  onPressed: () => _showCancelDialog(subscription),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text('Cancel Subscription'),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubscriptionDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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

  void _showSubscriptionDialog(SubscriptionPlan plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: Text(
          'Confirm Subscription',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
              ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are about to subscribe to the ${plan.toString().split('.').last} plan.',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              'Price: \$${SubscriptionFeatures.getPrice(plan)}/month',
              style: const TextStyle(
                color: AppTheme.primaryRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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
              await _subscribe(plan);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
            ),
            child: const Text('Subscribe'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(Subscription subscription) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: Text(
          'Cancel Subscription',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
              ),
        ),
        content: const Text(
          'Are you sure you want to cancel your subscription? You will lose access to premium features at the end of your current billing period.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Keep Subscription',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _cancelSubscription(subscription.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
            ),
            child: const Text('Cancel Subscription'),
          ),
        ],
      ),
    );
  }

  Future<void> _subscribe(SubscriptionPlan plan) async {
    try {
      setState(() => _isLoading = true);

      // Simulated payment info
      final paymentInfo = PaymentInfo(
        id: 'payment_${DateTime.now().millisecondsSinceEpoch}',
        method: 'Credit Card',
        lastFourDigits: '4242',
        expiryDate: DateTime.now().add(const Duration(days: 365)),
      );

      await _subscriptionService.subscribe(
        userId: 'current_user_id', // Replace with actual user ID
        plan: plan,
        paymentInfo: paymentInfo,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully subscribed!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to subscribe: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelSubscription(String subscriptionId) async {
    try {
      setState(() => _isLoading = true);
      await _subscriptionService.cancelSubscription(subscriptionId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel subscription: ${e.toString()}'),
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

class _SubscriptionPlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final Map<String, dynamic> features;
  final bool isSelected;
  final Function(SubscriptionPlan) onSelected;

  const _SubscriptionPlanCard({
    required this.plan,
    required this.features,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onSelected(plan),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryRed.withOpacity(0.1) : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryRed : Colors.grey[800]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  plan.toString().split('.').last,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: AppTheme.primaryRed,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '\$${features['price']}/month',
              style: TextStyle(
                color: isSelected ? AppTheme.primaryRed : Colors.grey[400],
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildFeatureItem('Quality', features['quality']),
            _buildFeatureItem('Devices', '${features['maxDevices']} device(s)'),
            _buildFeatureItem(
              'Downloads',
              features['downloadAllowed'] ? 'Available' : 'Not available',
            ),
            _buildFeatureItem(
              'Watch Party',
              features['watchPartyAllowed'] ? 'Available' : 'Not available',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.check,
            color: isSelected ? AppTheme.primaryRed : Colors.grey[400],
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: $value',
            style: TextStyle(
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}
