import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:transito/global/services/api_exceptions.dart';

abstract class BaseApiService {
  Future<http.Response> get(Uri uri, {Map<String, String>? headers}) async {
    try {
      final response = await http.get(uri, headers: headers);
      if (response.statusCode != 200) {
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Unexpected response status',
          uri: uri,
          responseBody: response.body,
        );
      }
      return response;
    } on SocketException catch (error) {
      throw NetworkException('Network error', uri: uri, cause: error);
    } on http.ClientException catch (error) {
      throw NetworkException('HTTP client error', uri: uri, cause: error);
    }
  }

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
