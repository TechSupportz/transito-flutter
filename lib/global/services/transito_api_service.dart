import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:transito/global/providers/alerts_provider.dart';
import 'package:transito/global/services/api_exceptions.dart';
import 'package:transito/global/services/base_api_service.dart';
import 'package:transito/models/api/lta/arrival_info.dart';
import 'package:transito/models/api/transito/announcements.dart';
import 'package:transito/models/api/transito/bus_routes.dart';
import 'package:transito/models/api/transito/bus_services.dart';
import 'package:transito/models/api/transito/bus_stops.dart';
import 'package:transito/models/api/transito/nearby_bus_stops.dart';
import 'package:transito/models/api/transito/onemap/onemap_search.dart';
import 'package:transito/models/secret.dart';

class TransitoApiService extends BaseApiService {
  TransitoApiService._internal();

  static final TransitoApiService _instance = TransitoApiService._internal();

  factory TransitoApiService() => _instance;

  bool _usingBetaServer = false;

  /// Bumped on every server switch so responses from the previous server cannot change Outages.
  int _serverGeneration = 0;

  void updateUsingBetaServer(bool usingBetaServer) {
    if (_usingBetaServer == usingBetaServer) return;
    _usingBetaServer = usingBetaServer;
    _serverGeneration++;
    AlertsProvider().resetServerState();
  }

  String get _baseUrl => _usingBetaServer ? Secret.BETA_API_URL : Secret.API_URL;

  /// Fetches and parses [uri], reporting the server (and [upstream], when the server proxies it) as
  /// available only once the response has parsed into a usable model.
  Future<T> _fetch<T>(
    Uri uri,
    T Function(Map<String, dynamic> json) parse, {
    OutageSource? upstream,
  }) async {
    final int generation = _serverGeneration;
    final AlertsProvider alerts = AlertsProvider();

    try {
      final http.Response response = await get(uri);
      final T result = _parse(uri, () => parse(decodeJson(response.body, uri)));
      if (generation == _serverGeneration) {
        alerts.reportSuccess(OutageSource.server);
        if (upstream != null) alerts.reportSuccess(upstream);
      }
      return result;
    } catch (error) {
      if (generation == _serverGeneration) {
        // A NUS upstream failure or timeout still means the server itself responded
        if (AlertsProvider.isNusUpstreamResponse(error)) {
          alerts.reportSuccess(OutageSource.server);
        } else {
          alerts.reportFailure(OutageSource.server, error);
        }
        if (upstream != null) alerts.reportFailure(upstream, error);
      }
      rethrow;
    }
  }

  /// A response that decodes but does not match the expected model is the server's fault.
  T _parse<T>(Uri uri, T Function() parse) {
    try {
      return parse();
    } on ApiParsingException {
      rethrow;
    } catch (error) {
      throw ApiParsingException('Unexpected response shape', uri: uri, cause: error);
    }
  }

  Future<List<Announcement>> getAnnouncements() async {
    final Uri uri = Uri.parse('$_baseUrl/alerts');
    return _fetch(uri, (data) => AlertsApiResponse.fromJson(data).data.announcements);
  }

  Future<List<BusStopServiceDetailed>> getBusStopServices(String code) async {
    final Uri uri = Uri.parse('$_baseUrl/bus-stop/$code/services');
    return _fetch(uri, (data) => BusStopServicesApiResponse.fromJson(data).data);
  }

  Future<BusStop> getBusStop(String code) async {
    final Uri uri = Uri.parse('$_baseUrl/bus-stop/$code');
    return _fetch(uri, (data) => BusStopDetailsApiResponse.fromJson(data).data);
  }

  Future<List<NearbyBusStop>> getNearbyBusStops(LatLng position) async {
    final Uri uri = Uri.parse(
      '$_baseUrl/bus-stops/nearby?latitude=${position.latitude}&longitude=${position.longitude}',
    );
    return _fetch(uri, (data) => NearbyBusStopsApiResponse.fromJson(data).data);
  }

  Future<OneMapSearch> searchPlaces(String query, int page) async {
    final Uri uri = Uri.parse('$_baseUrl/onemap/search?query=$query&page=$page');
    return _fetch(uri, (data) => OneMapSearch.fromJson(data));
  }

  Future<BusStopSearchApiResponse> searchBusStops(String query) async {
    final Uri uri = Uri.parse('$_baseUrl/search/bus-stops?query=$query');
    return _fetch(uri, (data) => BusStopSearchApiResponse.fromJson(data));
  }

  Future<BusServiceSearchApiResponse> searchBusServices(String query) async {
    final Uri uri = Uri.parse('$_baseUrl/search/bus-services?query=$query');
    return _fetch(uri, (data) => BusServiceSearchApiResponse.fromJson(data));
  }

  Future<BusService> getBusService(String serviceNo) async {
    final Uri uri = Uri.parse('$_baseUrl/bus-service/$serviceNo');
    return _fetch(uri, (data) => BusServiceDetailsApiResponse.fromJson(data).data);
  }

  Future<List<List<BusRouteInfo>>> getBusRoutes(String serviceNo) async {
    final Uri uri = Uri.parse('$_baseUrl/bus-service/$serviceNo?includeRoutes');
    return _fetch(uri, (data) => BusServiceDetailsApiResponse.fromJson(data).data.routes!);
  }

  Future<BusArrivalInfo> getNUSBusArrival(String busStopCode) async {
    final Uri uri = Uri.parse('$_baseUrl/bus-arrivals/nus/${Uri.encodeComponent(busStopCode)}');
    return _fetch(uri, BusArrivalInfo.fromJson, upstream: OutageSource.nus);
  }
}
