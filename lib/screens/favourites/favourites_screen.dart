import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:transito/global/providers/common_provider.dart';
import 'package:transito/global/providers/quick_start_tour_provider.dart';
import 'package:transito/global/services/favourites_service.dart';
import 'package:transito/global/services/settings_service.dart';
import 'package:transito/models/favourites/favourite.dart';
import 'package:transito/models/user/user_settings.dart';
import 'package:transito/screens/favourites/manage_favourites_screen.dart';
import 'package:transito/widgets/common/app_symbol.dart';
import 'package:transito/widgets/common/error_text.dart';
import 'package:transito/widgets/favourites/favourite_card_header.dart';
import 'package:transito/widgets/favourites/favourite_timing_rows_skeleton.dart';
import 'package:transito/widgets/favourites/favourites_timing_card.dart';

class FavouritesScreenController extends ChangeNotifier {
  void manageFavourites() => notifyListeners();
}

class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({super.key, this.controller, required this.isActive});
  final FavouritesScreenController? controller;
  final ValueListenable<bool> isActive;

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  late final VoidCallback _controllerListener;
  final ValueNotifier<bool> _isFabVisible = ValueNotifier<bool>(true);

  // sets the state of the FAB to hide or show depending if the user is scrolling in order to prevent blocking content
  bool hideFabOnScroll(UserScrollNotification notification) {
    if (notification.direction == ScrollDirection.forward) {
      _isFabVisible.value = true;
    } else if (notification.direction == ScrollDirection.reverse) {
      _isFabVisible.value = false;
    }
    return true;
  }

  // function to open the manage favourites screen
  void goToManageFavouritesScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ManageFavouritesScreen(),
        settings: const RouteSettings(name: 'ManageFavouritesScreen'),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _controllerListener = () => goToManageFavouritesScreen(context);
    widget.controller?.addListener(_controllerListener);
  }

  @override
  void didUpdateWidget(covariant FavouritesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_controllerListener);
      widget.controller?.addListener(_controllerListener);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_controllerListener);
    _isFabVisible.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String userId = context.watch<User>().uid;
    bool supportsLiquidGlass = context.watch<CommonProvider>().supportsLiquidGlass;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favourites'),
      ),
      // if the user has favourites display them via the favourites_timing_card widget, otherwise display a message
      body: StreamBuilder<UserSettings>(
        key: QuickStartTargetScope.keyOf(context, QuickStartTarget.favouritesOverview),
        stream: SettingsService().streamSettings(userId),
        builder: (context, settingsSnapshot) {
          final bool initiallyExpanded =
              !(settingsSnapshot.data?.defaultCollapsedFavourites ?? false);

          return StreamBuilder<List<Favourite>>(
            stream: FavouritesService().streamFavourites(userId),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final List<Favourite> favouritesList = snapshot.data!;
                if (favouritesList.isEmpty) {
                  return const ErrorText(
                    title: "This place is real empty",
                    message: "Try adding some favourites!",
                    icon: Symbols.heart_plus_rounded,
                  );
                }

                final Widget favourites = _FavouriteCardsList(
                  favourites: favouritesList,
                  isActive: widget.isActive,
                  initiallyExpanded: initiallyExpanded,
                  settingsSnapshot: settingsSnapshot,
                  bottomPadding: supportsLiquidGlass ? 115 : 32,
                );

                return supportsLiquidGlass
                    ? favourites
                    : NotificationListener<UserScrollNotification>(
                        onNotification: hideFabOnScroll,
                        child: favourites,
                      );
              } else if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              } else {
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 3),
                );
              }
            },
          );
        },
      ),
      // floating action button to open the manage favourites screen
      floatingActionButton: supportsLiquidGlass
          ? null
          : ValueListenableBuilder<bool>(
              valueListenable: _isFabVisible,
              builder: (context, isVisible, child) => isVisible ? child! : const SizedBox.shrink(),
              child: FloatingActionButton(
                heroTag: 'favouritesFAB',
                onPressed: () => goToManageFavouritesScreen(context),
                child: const AppSymbol(Symbols.edit_rounded, fill: true),
              ),
            ),
    );
  }
}

class _FavouriteCardsList extends StatefulWidget {
  const _FavouriteCardsList({
    required this.favourites,
    required this.isActive,
    required this.initiallyExpanded,
    required this.settingsSnapshot,
    required this.bottomPadding,
  });

  final List<Favourite> favourites;
  final ValueListenable<bool> isActive;
  final bool initiallyExpanded;
  final AsyncSnapshot<UserSettings> settingsSnapshot;
  final double bottomPadding;

  @override
  State<_FavouriteCardsList> createState() => _FavouriteCardsListState();
}

class _FavouriteCardsListState extends State<_FavouriteCardsList> with TickerProviderStateMixin {
  static const double _cardSpacing = 16;
  static const double _collapsedTimingBodyExtent = 8;

  final Map<String, _TimingRowCountCacheEntry> _timingRowCountCache = {};
  final Map<String, bool> _expandedByBusStopCode = {};
  final Map<String, double> _expansionProgressByBusStopCode = {};
  final Map<String, AnimationController> _expansionControllers = {};

  int _placeholderTimingRowCount(Favourite favourite) {
    final _TimingRowCountCacheEntry? entry = _timingRowCountCache[favourite.busStopCode];
    if (entry == null || entry.selectedServiceCount != favourite.services.length) {
      return favourite.services.length;
    }

    return entry.displayedRowCount;
  }

  void _cacheDisplayedTimingRowCount(Favourite favourite, int displayedRowCount) {
    if (displayedRowCount == 0) return;

    final _TimingRowCountCacheEntry nextEntry = _TimingRowCountCacheEntry(
      selectedServiceCount: favourite.services.length,
      displayedRowCount: displayedRowCount,
    );
    final _TimingRowCountCacheEntry? currentEntry = _timingRowCountCache[favourite.busStopCode];
    if (currentEntry?.selectedServiceCount == nextEntry.selectedServiceCount &&
        currentEntry?.displayedRowCount == nextEntry.displayedRowCount) {
      return;
    }

    setState(() {
      _timingRowCountCache[favourite.busStopCode] = nextEntry;
    });
  }

  bool _isExpanded(Favourite favourite) {
    return _expandedByBusStopCode.putIfAbsent(
      favourite.busStopCode,
      () => widget.initiallyExpanded,
    );
  }

  double _expansionProgress(Favourite favourite) {
    return _expansionProgressByBusStopCode.putIfAbsent(
      favourite.busStopCode,
      () => _isExpanded(favourite) ? 1 : 0,
    );
  }

  AnimationController _replaceExpansionController(Favourite favourite) {
    _expansionControllers.remove(favourite.busStopCode)?.dispose();
    late final AnimationController controller;
    controller =
        AnimationController(
          vsync: this,
          value: _expansionProgress(favourite),
        )..addListener(() {
          _expansionProgressByBusStopCode[favourite.busStopCode] = controller.value;
          if (mounted) setState(() {});
        });
    _expansionControllers[favourite.busStopCode] = controller;
    return controller;
  }

  void _handleExpansionChanged(Favourite favourite, bool isExpanded) {
    final AnimationController controller = _replaceExpansionController(favourite);
    setState(() {
      _expandedByBusStopCode[favourite.busStopCode] = isExpanded;
    });

    controller.animateTo(
      isExpanded ? 1 : 0,
      duration: Duration(milliseconds: isExpanded ? 450 : 300),
      curve: isExpanded ? Easing.emphasizedDecelerate : Easing.emphasizedAccelerate,
    );
  }

  double _itemExtent(int index, SliverLayoutDimensions dimensions) {
    final Favourite favourite = widget.favourites[index];
    final double expansionProgress = _expansionProgress(favourite);
    final double headerExtent = favouriteCardHeaderHeight(hasAlias: favourite.alias != null);
    final double expandedExtent =
        headerExtent + favouriteTimingRowsHeight(_placeholderTimingRowCount(favourite));
    final double collapsedExtent = headerExtent + _collapsedTimingBodyExtent;
    final double cardExtent =
        collapsedExtent + ((expandedExtent - collapsedExtent) * expansionProgress);
    final double spacing = index < widget.favourites.length - 1 ? _cardSpacing : 0;
    return cardExtent + spacing;
  }

  int? _findChildIndex(Key key) {
    if (key is! ValueKey<String>) return null;
    final int index = widget.favourites.indexWhere(
      (Favourite favourite) => favourite.busStopCode == key.value,
    );
    return index == -1 ? null : index;
  }

  void _disposeExpansionControllers() {
    for (final AnimationController controller in _expansionControllers.values) {
      controller.dispose();
    }
    _expansionControllers.clear();
  }

  @override
  void didUpdateWidget(covariant _FavouriteCardsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initiallyExpanded != widget.initiallyExpanded) {
      _disposeExpansionControllers();
      _expandedByBusStopCode.clear();
      _expansionProgressByBusStopCode.clear();
    }

    final Set<String> currentCodes = widget.favourites
        .map((Favourite favourite) => favourite.busStopCode)
        .toSet();
    final List<String> removedCodes = _expandedByBusStopCode.keys
        .where((String code) => !currentCodes.contains(code))
        .toList();
    for (final String code in removedCodes) {
      _expansionControllers.remove(code)?.dispose();
      _expandedByBusStopCode.remove(code);
      _expansionProgressByBusStopCode.remove(code);
      _timingRowCountCache.remove(code);
    }
  }

  @override
  void dispose() {
    _disposeExpansionControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemExtentBuilder: (int index, SliverLayoutDimensions dimensions) =>
          _itemExtent(index, dimensions),
      findChildIndexCallback: _findChildIndex,
      itemBuilder: (context, int index) {
        final Favourite favourite = widget.favourites[index];
        final bool isExpanded = _isExpanded(favourite);
        final double bottomSpacing = index < widget.favourites.length - 1 ? _cardSpacing : 0;

        return Padding(
          key: ValueKey<String>(favourite.busStopCode),
          padding: EdgeInsets.only(bottom: bottomSpacing),
          child: FavouritesTimingCard(
            isActive: widget.isActive,
            code: favourite.busStopCode,
            name: favourite.busStopName,
            alias: favourite.alias,
            address: favourite.busStopAddress,
            busStopLocation: favourite.busStopLocation,
            services: favourite.services,
            sources: favourite.sources,
            isCollapsible: true,
            initiallyExpanded: widget.initiallyExpanded,
            isExpanded: isExpanded,
            onExpansionChanged: (bool expanded) => _handleExpansionChanged(favourite, expanded),
            placeholderTimingRowCount: _placeholderTimingRowCount(favourite),
            onDisplayedTimingRowCountChanged: (int rowCount) =>
                _cacheDisplayedTimingRowCount(favourite, rowCount),
            settingsSnapshot: widget.settingsSnapshot,
          ),
        );
      },
      padding: EdgeInsets.only(
        top: 12,
        bottom: widget.bottomPadding,
        left: 12,
        right: 12,
      ),
      itemCount: widget.favourites.length,
    );
  }
}

class _TimingRowCountCacheEntry {
  const _TimingRowCountCacheEntry({
    required this.selectedServiceCount,
    required this.displayedRowCount,
  });

  final int selectedServiceCount;
  final int displayedRowCount;
}
