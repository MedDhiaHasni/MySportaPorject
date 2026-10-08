// lib/Widgets/star_rating.dart

import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';

class StarRating extends StatelessWidget {
  final double rating;
  final int starCount;
  final double size;
  final bool interactive;
  final Function(double)? onRatingChanged;
  final Color activeColor;
  final Color inactiveColor;
  final bool showRatingNumber;

  const StarRating({
    super.key,
    required this.rating,
    this.starCount = 5,
    this.size = 20,
    this.interactive = false,
    this.onRatingChanged,
    this.activeColor = Colors.amber,
    this.inactiveColor = Colors.grey,
    this.showRatingNumber = false,
  });

  @override
  Widget build(BuildContext context) {
    if (interactive) {
      return _buildInteractiveStars();
    }
    return _buildStaticStars();
  }

  Widget _buildStaticStars() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(starCount, (index) {
            final starValue = index + 1.0;
            double fillPercentage = 0.0;

            if (rating >= starValue) {
              fillPercentage = 1.0;
            } else if (rating >= starValue - 0.5) {
              fillPercentage = 0.5;
            } else {
              fillPercentage = 0.0;
            }

            return _buildStarIcon(fillPercentage);
          }),
        ),
        if (showRatingNumber) ...[
          const SizedBox(width: 8),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: size * 0.8,
              fontWeight: FontWeight.bold,
              color: kTextDark,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInteractiveStars() {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(starCount, (index) {
            return GestureDetector(
              onTap: () => onRatingChanged?.call(index + 1.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  rating >= index + 1 ? Icons.star : Icons.star_border,
                  size: size,
                  color: rating >= index + 1 ? activeColor : inactiveColor,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap to rate (${rating.toStringAsFixed(1)} ★)',
          style: TextStyle(
            fontSize: 12,
            color: kTextLight,
          ),
        ),
      ],
    );
  }

  Widget _buildStarIcon(double fillPercentage) {
    if (fillPercentage >= 0.75) {
      return Icon(Icons.star, size: size, color: activeColor);
    } else if (fillPercentage >= 0.25) {
      return Icon(Icons.star_half, size: size, color: activeColor);
    } else {
      return Icon(Icons.star_border, size: size, color: activeColor);
    }
  }
}

// 
// RATING SUMMARY WIDGET - Shows average rating with distribution
// 
class RatingSummaryWidget extends StatelessWidget {
  final double averageRating;
  final int totalRatings;
  final Map<int, int>? distribution;

  const RatingSummaryWidget({
    super.key,
    required this.averageRating,
    required this.totalRatings,
    this.distribution,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left: Average rating
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Text(
                  averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: kTextDark,
                  ),
                ),
                const SizedBox(height: 4),
                StarRating(rating: averageRating, size: 16),
                const SizedBox(height: 4),
                Text(
                  '$totalRatings ${totalRatings == 1 ? 'rating' : 'ratings'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: kTextMid,
                  ),
                ),
              ],
            ),
          ),
          // Right: Rating distribution (if available)
          if (distribution != null) ...[
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Column(
                children: List.generate(5, (index) {
                  final starCount = 5 - index;
                  final count = distribution?[starCount] ?? 0;
                  final double percentage = totalRatings > 0 ? count / totalRatings : 0.0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 35,
                          child: Text(
                            '$starCount ★',
                            style: const TextStyle(
                              fontSize: 11,
                              color: kTextMid,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage,
                              backgroundColor: Colors.grey.shade200,
                              color: Colors.amber,
                              minHeight: 6,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 35,
                          child: Text(
                            '($count)',
                            style: const TextStyle(
                              fontSize: 10,
                              color: kTextLight,
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ],
      ),
    );
  }
}