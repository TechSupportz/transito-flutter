import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:transito/models/app/app_typography.dart';
import 'package:transito/widgets/common/app_symbol.dart';

class FavouriteNameCard extends StatelessWidget {
  const FavouriteNameCard({
    super.key,
    required this.busStopName,
    required this.onTap,
    this.alias,
    this.reorderIndex,
  });

  final String busStopName;
  final String? alias;
  final int? reorderIndex;

  // onTap function passed in from parent
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String displayName = alias ?? busStopName;
    final Widget dragHandle = Icon(
      Symbols.drag_indicator_rounded,
      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
    );

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
                  if (reorderIndex case final int index)
                    ReorderableDragStartListener(index: index, child: dragHandle)
                  else
                    dragHandle,
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          displayName,
                          overflow: TextOverflow.fade,
                          maxLines: 1,
                          softWrap: false,
                          style: AppBusTypography.favouriteStopTitle.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        if (alias != null)
                          Text(
                            busStopName,
                            overflow: TextOverflow.fade,
                            maxLines: 1,
                            softWrap: false,
                            style: AppTypography.body.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const AppSymbol(Symbols.edit, fill: true),
              onPressed: onTap,
            ),
          ],
        ),
      ),
    );
  }
}

void previewFavouriteNameCardTap() {}

@Preview(name: 'Favourite name cards', group: 'Favourites', size: Size(390, 230))
Widget favouriteNameCardPreview() {
  return MaterialApp(
    theme: ThemeData(useMaterial3: true),
    home: const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          spacing: 12,
          children: [
            FavouriteNameCard(
              busStopName: 'Siglap Stn/Opp Victoria Sch',
              alias: 'Weeee',
              onTap: previewFavouriteNameCardTap,
            ),
            FavouriteNameCard(
              busStopName: 'Opp Bayshore Stn Exit 3',
              onTap: previewFavouriteNameCardTap,
            ),
          ],
        ),
      ),
    ),
  );
}
