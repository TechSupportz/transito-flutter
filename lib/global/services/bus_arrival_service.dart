import 'package:flutter/foundation.dart';
import 'package:transito/global/services/lta_api_service.dart';
import 'package:transito/global/services/transito_api_service.dart';
import 'package:transito/models/api/lta/arrival_info.dart';
import 'package:transito/models/api/transito/bus_stops.dart';

class BusArrivalService {
  BusArrivalService._internal();

  static final BusArrivalService _instance = BusArrivalService._internal();

  factory BusArrivalService() => _instance;

  Future<BusArrivalInfo> getBusArrival(
    String busStopCode, {
    required BusStopProviderSources? sources,
    bool isBusTimingScreen = false,
  }) async {
    final List<Future<_BusArrivalFetchResult>> fetches = [];

    if (sources == null) {
      fetches.add(
        _fetchArrival(
          providerName: 'LTA',
          fetch: () =>
              LtaApiService().getLTABusArrival(busStopCode, isBusTimingScreen: isBusTimingScreen),
        ),
      );
    } else {
      final String? ltaCode = _emptyToNull(sources.lta);
      final String? nusCode = _emptyToNull(sources.nus);

      if (ltaCode != null) {
        fetches.add(
          _fetchArrival(
            providerName: 'LTA',
            fetch: () =>
                LtaApiService().getLTABusArrival(ltaCode, isBusTimingScreen: isBusTimingScreen),
          ),
        );
      }

      if (nusCode != null) {
        fetches.add(
          _fetchArrival(
            providerName: 'NUS',
            fetch: () => TransitoApiService().getNUSBusArrival(nusCode),
          ),
        );
      }
    }

    if (fetches.isEmpty) {
      throw ArgumentError('Bus stop must have at least one provider source');
    }

    final List<_BusArrivalFetchResult> results = await Future.wait(fetches);
    final List<ServiceInfo> services = [];
    final List<_BusArrivalFetchResult> failedResults = [];

    for (final _BusArrivalFetchResult result in results) {
      final BusArrivalInfo? info = result.info;
      if (info != null) {
        services.addAll(info.services);
      } else {
        failedResults.add(result);
      }
    }

    if (services.isEmpty && failedResults.length == results.length) {
      throw failedResults.first.error!;
    }

    for (final _BusArrivalFetchResult failedResult in failedResults) {
      debugPrint(
        'Failed to fetch ${failedResult.providerName} bus arrivals: ${failedResult.error}',
      );
    }

    return BusArrivalInfo(metadata: '', busStopCode: busStopCode, services: services);
  }

  Future<_BusArrivalFetchResult> _fetchArrival({
    required String providerName,
    required Future<BusArrivalInfo> Function() fetch,
  }) async {
    try {
      return _BusArrivalFetchResult(providerName: providerName, info: await fetch());
    } catch (error) {
      return _BusArrivalFetchResult(providerName: providerName, error: error);
    }
  }

  String? _emptyToNull(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    return value;
  }
}

class _BusArrivalFetchResult {
  _BusArrivalFetchResult({required this.providerName, this.info, this.error});

  final String providerName;
  final BusArrivalInfo? info;
  final Object? error;
}
