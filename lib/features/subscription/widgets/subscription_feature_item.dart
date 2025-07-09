import 'package:flutter/material.dart';
import '../../../data/models/subscription.dart';

class SubscriptionFeatureItem extends StatelessWidget {
  final SubscriptionFeature feature;
  final bool isAvailable;

  const SubscriptionFeatureItem({
    Key? key,
    required this.feature,
    required this.isAvailable,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Get icon data based on iconName
    IconData iconData = Icons.check_circle;
    if (feature.iconName != null) {
      switch (feature.iconName) {
        case 'book':
          iconData = Icons.book;
          break;
        case 'download':
          iconData = Icons.download;
          break;
        case 'quiz':
          iconData = Icons.quiz;
          break;
        case 'smart_toy':
          iconData = Icons.smart_toy;
          break;
        case 'store':
          iconData = Icons.store;
          break;
        case 'analytics':
          iconData = Icons.analytics;
          break;
        default:
          iconData = Icons.check_circle;
      }
    }
    
    // Build description text with limit if applicable
    String descriptionText = feature.description;
    if (feature.limit != null && isAvailable) {
      // If the limit is already mentioned in the description, don't add it again
      if (!descriptionText.contains(feature.limit.toString())) {
        descriptionText += ' (Limit: ${feature.limit})';
      }
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Feature icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isAvailable 
                  ? Colors.white.withOpacity(0.2)
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              iconData,
              size: 18,
              color: isAvailable 
                  ? Colors.white
                  : Colors.white.withOpacity(0.5),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Feature name and description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  descriptionText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isAvailable 
                        ? Colors.white70
                        : Colors.white38,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Availability indicator
          Icon(
            isAvailable ? Icons.check_circle : Icons.cancel,
            size: 20,
            color: isAvailable 
                ? Colors.green
                : Colors.red.withOpacity(0.7),
          ),
        ],
      ),
    );
  }
}
