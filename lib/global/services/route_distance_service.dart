import 'dart:convert';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transito/models/app/route_distance_index.dart';

/// Keeps a local copy of the Route Distance Index that transito-server publishes to Firebase
/// Storage. Timing rows read [index] synchronously and fall back to straight-line distances until
/// it is available, so nothing here ever blocks a timing request.
class RouteDistanceService with WidgetsBindingObserver {
  RouteDistanceService._internal();

  static final RouteDistanceService _instance = RouteDistanceService._internal();

  factory RouteDistanceService() => _instance;

  // The path and cache file carry the schema version so older app versions keep reading theirs
  static const String _storagePath = 'route-distances/v${RouteDistanceIndex.schemaVersion}.json.gz';
  static const String _cacheFileName =
      'route_distances_v${RouteDistanceIndex.schemaVersion}.json.gz';
  static const String _hashKey = 'routeDistanceIndexHash';
  static const String _checkedAtKey = 'routeDistanceIndexCheckedAt';
  static const Duration _checkInterval = Duration(days: 1);
  static const Duration _retryInterval = Duration(minutes: 5);
  static const int _maxDownloadBytes = 5 * 1024 * 1024;

  RouteDistanceIndex? _index;
  bool _hasLoadedCache = false;
  Future<void>? _refreshing;
  DateTime? _attemptedAt;

  RouteDistanceIndex? get index => _index;

  /// Loads the cached index and keeps it current while the app runs.
  void start() {
    WidgetsBinding.instance.addObserver(this);
    refresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }

  /// Downloads a newer index at most once per [_checkInterval], retrying failures after
  /// [_retryInterval].
  Future<void> refresh() => _refreshing ??= _refresh().whenComplete(() => _refreshing = null);

  Future<void> _refresh() async {
    final File cacheFile = File(
      '${(await getApplicationSupportDirectory()).path}/$_cacheFileName',
    );

    if (!_hasLoadedCache) {
      _hasLoadedCache = true;
      try {
        if (await cacheFile.exists()) {
          _index = await compute(_decodeIndex, await cacheFile.readAsBytes());
        }
      } catch (error) {
        debugPrint('Failed to load cached route distance index: $error');
      }
    }

    final DateTime? attemptedAt = _attemptedAt;
    if (attemptedAt != null && DateTime.now().difference(attemptedAt) < _retryInterval) return;
    _attemptedAt = DateTime.now();

    try {
      await _downloadIfStale(cacheFile);
    } catch (error) {
      debugPrint('Failed to refresh route distance index: $error');
    }
  }

  Future<void> _downloadIfStale(File cacheFile) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int? checkedAt = prefs.getInt(_checkedAtKey);
    final int now = DateTime.now().millisecondsSinceEpoch;
    if (_index != null && checkedAt != null && now - checkedAt < _checkInterval.inMilliseconds) {
      return;
    }

    final Reference ref = FirebaseStorage.instance.ref(_storagePath);
    final String? remoteHash = (await ref.getMetadata()).md5Hash;

    if (_index == null || remoteHash == null || remoteHash != prefs.getString(_hashKey)) {
      final Uint8List? bytes = await ref.getData(_maxDownloadBytes);
      if (bytes == null) throw StateError('Route distance index download returned no data');

      // Decode before caching so a malformed upload never replaces a working local copy
      final RouteDistanceIndex index = await compute(_decodeIndex, bytes);
      final File tempFile = File('${cacheFile.path}.tmp');
      await tempFile.writeAsBytes(bytes, flush: true);
      await tempFile.rename(cacheFile.path);

      _index = index;
      if (remoteHash != null) await prefs.setString(_hashKey, remoteHash);
      debugPrint('Updated route distance index');
    }

    await prefs.setInt(_checkedAtKey, now);
  }
}

RouteDistanceIndex _decodeIndex(Uint8List bytes) {
  final Object? json = jsonDecode(utf8.decode(gzip.decode(bytes)));
  return RouteDistanceIndex.fromJson(json as Map<String, dynamic>);
}
