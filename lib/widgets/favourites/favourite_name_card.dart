import 'package:flutter/material.dart';

import '../../models/app/app_colors.dart';

class FavouriteNameCard extends StatelessWidget {
  const FavouriteNameCard({
    Key? key,
    required this.busStopName,
    required this.onTap,
  }) : super(key: key);

  final String busStopName;

  // onTap function passed in from parent
  final Function onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                busStopName,
                overflow: TextOverflow.fade,
                maxLines: 1,
                softWrap: false,
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.kindaGrey),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => onTap(),
            ),
          ],
        ),
      ),
    );
  }
}
