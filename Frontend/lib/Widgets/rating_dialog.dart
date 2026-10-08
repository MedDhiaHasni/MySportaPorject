// lib/Widgets/rating_dialog.dart

import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Widgets/star_rating.dart';

class RatingDialog extends StatefulWidget {
  final String venueName;
  final double? existingRating;
  final bool isLoading;

  const RatingDialog({
    super.key,
    required this.venueName,
    this.existingRating,
    this.isLoading = false,
  });

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  double _rating = 0;

  @override
  void initState() {
    super.initState();
    if (widget.existingRating != null) {
      _rating = widget.existingRating!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.star_rate_rounded,
                size: 32,
                color: kPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              widget.existingRating != null ? 'Update Your Rating' : 'Rate Your Experience',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kTextDark,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              widget.venueName,
              style: const TextStyle(
                fontSize: 14,
                color: kTextMid,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Stars
            StarRating(
              rating: _rating,
              starCount: 5,
              size: 44,
              interactive: true,
              onRatingChanged: (value) {
                setState(() {
                  _rating = value;
                });
              },
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: widget.isLoading ? null : () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.isLoading || _rating == 0
                        ? null
                        : () {
                            Navigator.pop(context, {
                              'rating': _rating,
                            });
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: widget.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(widget.existingRating != null ? 'Update' : 'Submit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}