import 'package:latlong2/latlong.dart';
import 'package:transito/global/services/base_api_service.dart';
import 'package:transito/models/api/lta/arrival_info.dart';
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

  String get _baseUrl => Secret.API_URL;

  Future<List<String>> getBusStopServices(String code) async {
    final Uri uri = Uri.parse('$_baseUrl/bus-stop/$code/services');
    final response = await get(uri);
    final Map<String, dynamic> data = decodeJson(response.body, uri);
    return BusStopServicesApiResponse.fromJson(data).data;
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
    final Uri uri =
        Uri.parse('$_baseUrl/onemap/search?query=$query&page=$page');
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
    final response = await get(uri);
    final Map<String, dynamic> data = decodeJson(response.body, uri);
    return BusArrivalInfo.fromJson(data);
  }
}
