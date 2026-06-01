import 'package:transito/global/services/api_exceptions.dart';
import 'package:transito/global/services/base_api_service.dart';
import 'package:transito/models/api/lta/arrival_info.dart';
import 'package:transito/models/secret.dart';
import 'package:transito/widgets/common/lta_maintenance_warning_snackbar.dart';

class LtaApiService extends BaseApiService {
  LtaApiService._internal();

  static final LtaApiService _instance = LtaApiService._internal();

  factory LtaApiService() => _instance;

  static const String _baseUrl = 'https://datamall2.mytransport.sg/ltaodataservice/v3';

  static DateTime? _lastErrorDisplayTime;
  static bool _isPreviousScreenBusTiming = false;
  static const _debounceDuration = Duration(minutes: 1);

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'AccountKey': Secret.LTA_API_KEY,
  };

  Future<BusArrivalInfo> getLTABusArrival(
    String busStopCode, {
    bool? isBusTimingScreen = false,
  }) async {
    try {
      final Uri uri = Uri.parse('$_baseUrl/BusArrival?BusStopCode=$busStopCode');
      final response = await get(uri, headers: _headers);
      _isPreviousScreenBusTiming = isBusTimingScreen ?? false;
      final Map<String, dynamic> data = decodeJson(response.body, uri);
      return BusArrivalInfo.fromJson(data);
    } catch (error) {
      if (error is ApiException && error.statusCode == 503) {
        final now = DateTime.now();
        if ((_lastErrorDisplayTime == null ||
            now.difference(_lastErrorDisplayTime!) > _debounceDuration ||
            (!_isPreviousScreenBusTiming && isBusTimingScreen == true))) {
          _lastErrorDisplayTime = now;
          showLtaMaintenanceWarningSnackbar();
        }
      }
      rethrow;
    }
  }
}
