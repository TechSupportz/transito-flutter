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

  void updateUsingBetaServer(bool usingBetaServer) {
    if (_usingBetaServer == usingBetaServer) return;
    _usingBetaServer = usingBetaServer;
    AlertsProvider().resetServerState();
  }

  String get _baseUrl => _usingBetaServer ? Secret.BETA_API_URL : Secret.API_URL;

  @override
  Future<http.Response> get(Uri uri, {Map<String, String>? headers}) async {
    try {
      final response = await super.get(uri, headers: headers);
      AlertsProvider().reportSuccess(OutageSource.server);
      return response;
    } catch (error) {
      // A NUS upstream failure still means the server itself responded
      if (AlertsProvider.isNusUpstreamFailure(error)) {
        AlertsProvider().reportSuccess(OutageSource.server);
      } else {
        AlertsProvider().reportFailure(OutageSource.server, error);
      }
      rethrow;
    }
  }

  @override
  Map<String, dynamic> decodeJson(String body, Uri uri) {
    try {
      return super.decodeJson(body, uri);
    } on ApiParsingException catch (error) {
      AlertsProvider().reportFailure(OutageSource.server, error);
      rethrow;
    }
  }

  Future<List<Announcement>> getAnnouncements() async {
    final Uri uri = Uri.parse('$_baseUrl/alerts');
    final response = await get(uri);
    final Map<String, dynamic> data = decodeJson(response.body, uri);
    return AlertsApiResponse.fromJson(data).data.announcements;
  }

  Future<List<BusStopServiceDetailed>> getBusStopServices(String code) async {
    final Uri uri = Uri.parse('$_baseUrl/bus-stop/$code/services');
    final response = await get(uri);
    final Map<String, dynamic> data = decodeJson(response.body, uri);
    return BusStopServicesApiResponse.fromJson(data).data;
  }

  Future<BusStop> getBusStop(String code) async {
    final Uri uri = Uri.parse('$_baseUrl/bus-stop/$code');
    final response = await get(uri);
    final Map<String, dynamic> data = decodeJson(response.body, uri);
    return BusStopDetailsApiResponse.fromJson(data).data;
  }

  Future<List<NearbyBusStop>> getNearbyBusStops(LatLng position) async {
    final Uri uri = Uri.parse(
      '$_baseUrl/bus-stops/nearby?latitude=${position.latitude}&longitude=${position.longitude}',
    );
    final response = await get(uri);
    final Map<String, dynamic> data = decodeJson(response.body, uri);
    return NearbyBusStopsApiResponse.fromJson(data).data;
  }

  Future<OneMapSearch> searchPlaces(String query, int page) async {
    final Uri uri = Uri.parse('$_baseUrl/onemap/search?query=$query&page=$page');
    final response = await get(uri);
    final Map<String, dynamic> data = decodeJson(response.body, uri);
    return OneMapSearch.fromJson(data);
  }

  Future<BusStopSearchApiResponse> searchBusStops(String query) async {
    final Uri uri = Uri.parse('$_baseUrl/search/bus-stops?query=$query');
    final response = await get(uri);
    final Map<String, dynamic> data = decodeJson(response.body, uri);
    return BusStopSearchApiResponse.fromJson(data);
  }

  Future<BusServiceSearchApiResponse> searchBusServices(String query) async {
    final Uri uri = Uri.parse('$_baseUrl/search/bus-services?query=$query');
    final response = await get(uri);
    final Map<String, dynamic> data = decodeJson(response.body, uri);
    return BusServiceSearchApiResponse.fromJson(data);
  }

  Future<BusService> getBusService(String serviceNo) async {
    final Uri uri = Uri.parse('$_baseUrl/bus-service/$serviceNo');
    final response = await get(uri);
    final Map<String, dynamic> data = decodeJson(response.body, uri);
    return BusServiceDetailsApiResponse.fromJson(data).data;
  }

  Future<List<List<BusRouteInfo>>> getBusRoutes(String serviceNo) async {
    final Uri uri = Uri.parse('$_baseUrl/bus-service/$serviceNo?includeRoutes');
    final response = await get(uri);
    final Map<String, dynamic> data = decodeJson(response.body, uri);
    return BusServiceDetailsApiResponse.fromJson(data).data.routes!;
  }

  Future<BusArrivalInfo> getNUSBusArrival(String busStopCode) async {
    final Uri uri = Uri.parse('$_baseUrl/bus-arrivals/nus/${Uri.encodeComponent(busStopCode)}');
    final http.Response response;
    try {
      response = await get(uri);
    } catch (error) {
      AlertsProvider().reportFailure(OutageSource.nus, error);
      rethrow;
    }

    // The server has already validated the NUS response, so a malformed body here is the server's
    final Map<String, dynamic> data = decodeJson(response.body, uri);
    final BusArrivalInfo info;
    try {
      info = BusArrivalInfo.fromJson(data);
    } catch (error) {
      AlertsProvider().reportFailure(
        OutageSource.server,
        ApiParsingException('Unexpected response shape', uri: uri, cause: error),
      );
      rethrow;
    }
    AlertsProvider().reportSuccess(OutageSource.nus);
    return info;
  }
}
