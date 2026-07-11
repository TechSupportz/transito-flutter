import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:transito/models/app/app_typography.dart';
import 'package:transito/widgets/common/app_symbol.dart';

const double favouriteCardHeaderExtent = 56;
const double favouriteCardHeaderWithAliasExtent = 76;

double favouriteCardHeaderHeight({required bool hasAlias}) =>
    hasAlias ? favouriteCardHeaderWithAliasExtent : favouriteCardHeaderExtent;

class FavouriteCardHeader extends StatelessWidget {
  const FavouriteCardHeader({
    super.key,
    required this.busStopName,
    required this.alias,
    required this.isExpanded,
    required this.isCollapsible,
    required this.onNameTap,
    this.onToggle,
  });

  final String busStopName;
  final String? alias;
  final bool isExpanded;
  final bool isCollapsible;
  final VoidCallback onNameTap;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final String displayName = alias ?? busStopName;
    final bool showBusStopName = alias != null;

    return SizedBox(
      height: favouriteCardHeaderHeight(hasAlias: alias != null),
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Semantics(
                button: true,
                label: 'Open bus stop information for $displayName',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onNameTap,
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
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 450),
                        reverseDuration: const Duration(milliseconds: 300),
                        switchInCurve: Easing.emphasizedDecelerate,
                        switchOutCurve: Easing.emphasizedAccelerate,
                        transitionBuilder: (child, animation) => ClipRect(
                          child: SizeTransition(
                            sizeFactor: animation,
                            axisAlignment: -1,
                            child: FadeTransition(opacity: animation, child: child),
                          ),
                        ),
                        child: showBusStopName
                            ? Text(
                                busStopName,
                                key: const ValueKey('bus-stop-name'),
                                overflow: TextOverflow.fade,
                                maxLines: 1,
                                softWrap: false,
                                style: AppTypography.body.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            : const SizedBox.shrink(key: ValueKey('hidden-bus-stop-name')),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (isCollapsible)
              Semantics(
                button: true,
                expanded: isExpanded,
                label: '${isExpanded ? 'Collapse' : 'Expand'} $displayName',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onToggle,
                  child: AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 350),
                    curve: Easing.emphasizedDecelerate,
                    child: const SizedBox.square(
                      dimension: 40,
                      child: Center(
                        child: AppSymbol(Symbols.expand_more_rounded, size: 30),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

@Preview(name: 'Favourite card headers', group: 'Favourites', size: Size(390, 220))
Widget favouriteCardHeaderPreview() {
  return MaterialApp(
    theme: ThemeData(useMaterial3: true),
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          spacing: 12,
          children: [
            Material(
              color: ThemeData.light().colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              child: FavouriteCardHeader(
                busStopName: 'Opp Blk 123',
                alias: 'Home',
                isExpanded: true,
                isCollapsible: true,
                onNameTap: () {},
                onToggle: () {},
              ),
            ),
            Material(
              color: ThemeData.light().colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              child: FavouriteCardHeader(
                busStopName: 'Blk 456',
                alias: 'Work',
                isExpanded: false,
                isCollapsible: true,
                onNameTap: () {},
                onToggle: () {},
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
