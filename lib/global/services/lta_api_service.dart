import 'package:transito/global/services/base_api_service.dart';
import 'package:transito/models/api/lta/arrival_info.dart';
import 'package:transito/models/secret.dart';

class LtaApiService extends BaseApiService {
  LtaApiService._internal();

  static final LtaApiService _instance = LtaApiService._internal();

  factory LtaApiService() => _instance;

  static const String _baseUrl =
      'https://datamall2.mytransport.sg/ltaodataservice/v3';

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'AccountKey': Secret.LTA_API_KEY,
      };

  Future<BusArrivalInfo> getBusArrival(String busStopCode) async {
    final Uri uri = Uri.parse('$_baseUrl/BusArrival?BusStopCode=$busStopCode');
    final response = await get(uri, headers: _headers);
    final Map<String, dynamic> data = decodeJson(response.body, uri);
    return BusArrivalInfo.fromJson(data);
  }
}
