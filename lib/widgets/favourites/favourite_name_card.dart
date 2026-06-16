import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:transito/models/app/app_typography.dart';
import 'package:transito/widgets/common/app_symbol.dart';

class FavouriteNameCard extends StatelessWidget {
  const FavouriteNameCard({
    super.key,
    required this.busStopName,
    required this.onTap,
  });

  final String busStopName;

  // onTap function passed in from parent
  final Function onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(
                    Symbols.drag_indicator_rounded,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  SizedBox(width: 8),
                  Text(
                    busStopName,
                    overflow: TextOverflow.fade,
                    maxLines: 1,
                    softWrap: false,
                    style: AppBusTypography.favouriteStopTitle.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const AppSymbol(Symbols.edit, fill: true),
              onPressed: () => onTap(),
            ),
          ],
        ),
      ),
    );
  }
}
