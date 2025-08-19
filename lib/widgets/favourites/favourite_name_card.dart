import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
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
              child: Text(
                busStopName,
                overflow: TextOverflow.fade,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
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
