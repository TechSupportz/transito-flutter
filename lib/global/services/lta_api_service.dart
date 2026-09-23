import 'package:transito/global/providers/alerts_provider.dart';
import 'package:transito/global/services/api_exceptions.dart';
import 'package:transito/global/services/base_api_service.dart';
import 'package:transito/models/api/lta/arrival_info.dart';
import 'package:transito/models/secret.dart';

class LtaApiService extends BaseApiService {
  LtaApiService._internal();

  static final LtaApiService _instance = LtaApiService._internal();

  factory LtaApiService() => _instance;

  static const String _baseUrl = 'https://datamall2.mytransport.sg/ltaodataservice/v3';

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'AccountKey': Secret.LTA_API_KEY,
  };

  Future<BusArrivalInfo> getLTABusArrival(String busStopCode) async {
    try {
      final Uri uri = Uri.parse('$_baseUrl/BusArrival?BusStopCode=$busStopCode');
      final response = await get(uri, headers: _headers);
      final Map<String, dynamic> data = decodeJson(response.body, uri);
      final BusArrivalInfo info = BusArrivalInfo.fromJson(data);
      AlertsProvider().reportSuccess(OutageSource.lta);
      return info;
    } catch (error) {
      // Valid JSON in the wrong shape fails in fromJson; LTA sent a body we cannot use
      final bool isApiError =
          error is ApiException || error is NetworkException || error is ApiParsingException;
      AlertsProvider().reportFailure(
        OutageSource.lta,
        isApiError ? error : ApiParsingException('Unexpected response shape', cause: error),
      );
      rethrow;
    }
  }
}
