import 'dart:async';

import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:transito/global/services/bus_arrival_service.dart';
import 'package:transito/global/services/settings_service.dart';
import 'package:transito/models/api/lta/arrival_info.dart';
import 'package:transito/models/api/transito/bus_stops.dart';
import 'package:transito/models/app/app_typography.dart';
import 'package:transito/models/user/user_settings.dart';
import 'package:transito/screens/bus_info/bus_stop_info_screen.dart';
import 'package:transito/screens/bus_info/bus_timing_screen.dart';
import 'package:transito/widgets/bus_timings/bus_timing_row.dart';
import 'package:transito/widgets/common/error_text.dart';
import 'package:transito/widgets/favourites/favourite_card_header.dart';
import 'package:transito/widgets/favourites/favourite_timing_rows_skeleton.dart';

class FavouritesTimingCard extends StatefulWidget {
  const FavouritesTimingCard({
    super.key,
    required this.code,
    required this.name,
    required this.address,
    required this.services,
    required this.busStopLocation,
    required this.sources,
    required this.isActive,
    this.alias,
    this.isCollapsible = false,
    this.initiallyExpanded = true,
    this.placeholderTimingRowCount,
    this.onDisplayedTimingRowCountChanged,
    this.isExpanded,
    this.onExpansionChanged,
    this.settingsSnapshot,
  });

  final String code;
  final String name;
  final String? alias;
  final String address;
  final List<String?> services;
  final LatLng busStopLocation;
  final BusStopProviderSources? sources;
  final ValueListenable<bool> isActive;
  final bool isCollapsible;
  final bool initiallyExpanded;
  final int? placeholderTimingRowCount;
  final ValueChanged<int>? onDisplayedTimingRowCountChanged;
  final bool? isExpanded;
  final ValueChanged<bool>? onExpansionChanged;
  final AsyncSnapshot<UserSettings>? settingsSnapshot;

  @override
  State<FavouritesTimingCard> createState() => _FavouritesTimingCardState();
}

class _FavouritesTimingCardState extends State<FavouritesTimingCard> {
  late Future<List<ServiceInfo>> futureBusArrivalInfo;
  late bool _isExpanded;
  Timer? _timer;
  int? _lastReportedTimingRowCount;

  bool get _shouldFetchArrivals => widget.isActive.value && (!widget.isCollapsible || _isExpanded);

  String get _displayName => widget.alias ?? widget.name;

  int get _reservedTimingRowCount =>
      _lastReportedTimingRowCount ?? widget.placeholderTimingRowCount ?? widget.services.length;

  // function to fetch bus arrival info
  Future<BusArrivalInfo> fetchArrivalTimings({
    required String code,
    required BusStopProviderSources? sources,
  }) async {
    debugPrint("Fetching favourite arrival timings");
    final BusArrivalInfo info = await BusArrivalService().getBusArrival(
      code,
      sources: sources,
    );
    debugPrint("Favourites Timing fetched");
    return info;
  }

  // function to properly sort the bus arrival info according to the Bus Service number and to filter it based on users favourite services
  List<ServiceInfo> filterBusArrivalInfo(BusArrivalInfo value, List<String?> services) {
    final List<ServiceInfo> filteredList = value.services
        .where((serviceInfo) => services.contains(serviceInfo.serviceNum))
        .toList();
    filteredList.sort((a, b) => compareNatural(a.serviceNum, b.serviceNum));

    return filteredList;
  }

  Future<List<ServiceInfo>> _getFilteredArrivalTimings() {
    final String code = widget.code;
    final BusStopProviderSources? sources = widget.sources;
    final List<String?> services = List.unmodifiable(widget.services);

    return fetchArrivalTimings(
      code: code,
      sources: sources,
    ).then((value) => filterBusArrivalInfo(value, services));
  }

  void _refreshArrivalTimings() {
    if (!mounted || !_shouldFetchArrivals) return;

    setState(() {
      futureBusArrivalInfo = _getFilteredArrivalTimings();
    });
  }

  void _startTimer() {
    _timer?.cancel();
    if (!_shouldFetchArrivals) return;

    _timer = Timer.periodic(
      const Duration(seconds: 20),
      (Timer timer) => _refreshArrivalTimings(),
    );
  }

  void _handleActivityChanged() {
    if (_shouldFetchArrivals) {
      _refreshArrivalTimings();
      _startTimer();
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  bool _arrivalQueryChanged(FavouritesTimingCard oldWidget) {
    return oldWidget.code != widget.code ||
        !const ListEquality<String?>().equals(oldWidget.services, widget.services) ||
        oldWidget.sources?.lta != widget.sources?.lta ||
        oldWidget.sources?.nus != widget.sources?.nus;
  }

  // function to fetch bus arrival info and update the state of the widget, and to set a timer to refresh it periodically
  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded ?? (!widget.isCollapsible || widget.initiallyExpanded);
    futureBusArrivalInfo = _shouldFetchArrivals
        ? _getFilteredArrivalTimings()
        : Future<List<ServiceInfo>>.value(const <ServiceInfo>[]);
    widget.isActive.addListener(_handleActivityChanged);
    if (_shouldFetchArrivals) {
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(covariant FavouritesTimingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool arrivalQueryChanged = _arrivalQueryChanged(oldWidget);
    final bool controlledExpansionChanged =
        widget.isExpanded != null && oldWidget.isExpanded != widget.isExpanded;

    if (controlledExpansionChanged) {
      _isExpanded = widget.isExpanded!;
    }

    if (oldWidget.isActive != widget.isActive) {
      oldWidget.isActive.removeListener(_handleActivityChanged);
      widget.isActive.addListener(_handleActivityChanged);
      _handleActivityChanged();
    }

    if (widget.isExpanded == null &&
        (oldWidget.isCollapsible != widget.isCollapsible ||
            oldWidget.initiallyExpanded != widget.initiallyExpanded)) {
      _isExpanded = !widget.isCollapsible || widget.initiallyExpanded;
      if (_shouldFetchArrivals) {
        futureBusArrivalInfo = _getFilteredArrivalTimings();
        _startTimer();
      } else {
        _timer?.cancel();
        _timer = null;
      }
    }

    if (controlledExpansionChanged) {
      if (_shouldFetchArrivals) {
        futureBusArrivalInfo = _getFilteredArrivalTimings();
        _startTimer();
      } else {
        _timer?.cancel();
        _timer = null;
      }
    }

    if (arrivalQueryChanged) {
      _lastReportedTimingRowCount = null;
    }

    if (arrivalQueryChanged && _shouldFetchArrivals) {
      futureBusArrivalInfo = _getFilteredArrivalTimings();
    }
  }

  void _toggleExpansion() {
    if (!widget.isCollapsible) return;

    if (widget.onExpansionChanged != null) {
      widget.onExpansionChanged!(!_isExpanded);
      return;
    }

    setState(() {
      _isExpanded = !_isExpanded;
      if (_shouldFetchArrivals) {
        futureBusArrivalInfo = _getFilteredArrivalTimings();
      }
    });

    if (_shouldFetchArrivals) {
      _startTimer();
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _openBusTimingScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BusTimingScreen(
          code: widget.code,
          name: widget.name,
          address: widget.address,
          busStopLocation: widget.busStopLocation,
          sources: widget.sources,
        ),
        settings: const RouteSettings(name: "BusTimingScreen"),
      ),
    );
  }

  void _openBusStopInfoScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BusStopInfoScreen(
          code: widget.code,
          name: widget.name,
          address: widget.address,
          busStopLocation: widget.busStopLocation,
          sources: widget.sources,
        ),
        settings: const RouteSettings(name: 'BusStopInfoScreen'),
      ),
    );
  }

  void _reportDisplayedTimingRowCount(int rowCount) {
    if (rowCount == 0 || rowCount == _lastReportedTimingRowCount) return;

    _lastReportedTimingRowCount = rowCount;
    final ValueChanged<int>? onChanged = widget.onDisplayedTimingRowCountChanged;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) onChanged?.call(rowCount);
    });
  }

  Widget _buildReservedTimingMessage(Widget child) {
    return SizedBox(
      height: favouriteTimingRowsHeight(_reservedTimingRowCount),
      child: Center(child: child),
    );
  }

  @override
  void dispose() {
    widget.isActive.removeListener(_handleActivityChanged);
    _timer?.cancel();
    super.dispose();
  }

  Widget _buildArrivalContent(AsyncSnapshot<UserSettings> settingsSnapshot) {
    if (settingsSnapshot.hasError) {
      debugPrint('<=== ERROR ${settingsSnapshot.error} ===>');
      return _buildReservedTimingMessage(
        const ErrorText(
          enableBackground: true,
          style: ErrorTextStyle.inline,
          icon: Symbols.error_rounded,
        ),
      );
    }

    if (!settingsSnapshot.hasData) {
      return FavouriteTimingRowsSkeleton(rowCount: _reservedTimingRowCount);
    }

    final UserSettings userSettings = settingsSnapshot.data!;
    return FutureBuilder<List<ServiceInfo>>(
      future: futureBusArrivalInfo,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data!.isNotEmpty) {
            _reportDisplayedTimingRowCount(snapshot.data!.length);
          }

          return snapshot.data!.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(bottom: favouriteTimingRowsBottomPadding),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int index = 0; index < snapshot.data!.length; index++) ...[
                        ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: favouriteTimingRowExtent),
                          child: Transform.scale(
                            scale: 0.9,
                            child: BusTimingRow(
                              busStopCode: widget.code,
                              serviceInfo: snapshot.data![index],
                              userLatLng: widget.busStopLocation,
                              isETAminutes: userSettings.isETAminutes,
                            ),
                          ),
                        ),
                        if (index < snapshot.data!.length - 1)
                          const SizedBox(height: favouriteTimingRowSpacing),
                      ],
                    ],
                  ),
                )
              : _buildReservedTimingMessage(
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 8,
                      bottom: 24,
                      left: 16,
                      right: 16,
                    ),
                    child: Text(
                      Jiffy.now().hour > 5
                          ? '🦥 Your favourites are lepaking 🦥'
                          : '💤 Buses are sleeping 💤',
                      style: AppBusTypography.emptyTimingsMessage,
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
        } else if (snapshot.hasError) {
          debugPrint('<=== ERROR ${snapshot.error} ===>');
          return _buildReservedTimingMessage(
            const ErrorText(
              style: ErrorTextStyle.inline,
              title: "Couldn't load timings",
            ),
          );
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return FavouriteTimingRowsSkeleton(rowCount: _reservedTimingRowCount);
        } else {
          return const SizedBox(height: 10);
        }
      },
    );
  }

  Widget _buildCard(BuildContext context, AsyncSnapshot<UserSettings> settingsSnapshot) {
    return Tooltip(
      preferBelow: false,
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainer),
      textStyle: AppBusTypography.favouriteStopTooltip,
      showDuration: const Duration(milliseconds: 350),
      message: _displayName,
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            FavouriteCardHeader(
              busStopName: widget.name,
              alias: widget.alias,
              isExpanded: _isExpanded,
              isCollapsible: widget.isCollapsible,
              onNameTap: _openBusStopInfoScreen,
              onToggle: widget.isCollapsible ? _toggleExpansion : null,
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
              child: _isExpanded
                  ? KeyedSubtree(
                      key: const ValueKey('expanded-arrivals'),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _openBusTimingScreen,
                        child: _buildArrivalContent(settingsSnapshot),
                      ),
                    )
                  : const SizedBox(
                      key: ValueKey('collapsed-arrivals'),
                      height: 8,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncSnapshot<UserSettings>? settingsSnapshot = widget.settingsSnapshot;
    if (settingsSnapshot != null) {
      return _buildCard(context, settingsSnapshot);
    }

    final User? user = context.watch<User?>();
    return StreamBuilder<UserSettings>(
      stream: SettingsService().streamSettings(user?.uid),
      builder: (context, snapshot) => _buildCard(context, snapshot),
    );
  }
}
