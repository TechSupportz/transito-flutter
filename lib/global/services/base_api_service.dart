import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:transito/global/services/api_exceptions.dart';

abstract class BaseApiService {
  static const Duration requestTimeout = Duration(seconds: 15);

  Future<http.Response> get(Uri uri, {Map<String, String>? headers}) async {
    // Abort a request that hangs so callers waiting on it, such as polling, can carry on and the
    // service reports it as an Outage. The client only honours the abort once it has a connection,
    // so the deadline also covers a stalled DNS, TCP or TLS setup; aborting then still cancels the
    // request if that connection arrives later.
    final Completer<void> abort = Completer();
    final Timer abortTimer = Timer(requestTimeout, abort.complete);
    try {
      final request = http.AbortableRequest('GET', uri, abortTrigger: abort.future);
      if (headers != null) request.headers.addAll(headers);
      final response = await request.send().then(http.Response.fromStream).timeout(requestTimeout);
      if (response.statusCode != 200) {
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Unexpected response status',
          uri: uri,
          responseBody: response.body,
        );
      }
      return response;
    } on http.RequestAbortedException catch (error) {
      throw NetworkException('Request timed out', uri: uri, cause: error, isTimeout: true);
    } on TimeoutException catch (error) {
      if (!abort.isCompleted) abort.complete();
      throw NetworkException('Request timed out', uri: uri, cause: error, isTimeout: true);
    } on SocketException catch (error) {
      throw NetworkException('Network error', uri: uri, cause: error, isTimeout: _isTimeout(error));
    } on http.ClientException catch (error) {
      throw NetworkException(
        'HTTP client error',
        uri: uri,
        cause: error,
        isTimeout: _isTimeout(error),
      );
    } finally {
      abortTimer.cancel();
    }
  }

  bool _isTimeout(Object error) => error.toString().toLowerCase().contains('timed out');

  Map<String, dynamic> decodeJson(String body, Uri uri) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw ApiParsingException('Unexpected response format', uri: uri);
    } on FormatException catch (error) {
      throw ApiParsingException('Failed to parse response', uri: uri, cause: error);
    }
  }
}
