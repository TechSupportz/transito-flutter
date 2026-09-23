import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:transito/global/services/api_exceptions.dart';
import 'package:transito/global/services/transito_api_service.dart';
import 'package:transito/models/api/transito/announcements.dart';

/// A dependency whose unavailability is detected on this device as an Outage.
enum OutageSource { lta, nus, server }

/// Tracks the Alerts shown in the alert inbox: Outages detected from this device's own requests,
/// and Announcements published through Transito's server.
class AlertsProvider extends ChangeNotifier with WidgetsBindingObserver {
  AlertsProvider._internal({DateTime Function()? clock, this.fetchAnnouncements})
    : _clock = clock ?? DateTime.now;

  static final AlertsProvider _instance = AlertsProvider._internal();

  factory AlertsProvider() => _instance;

  @visibleForTesting
  AlertsProvider.test({
    required DateTime Function() clock,
    Future<List<Announcement>> Function()? fetchAnnouncements,
  }) : this._internal(clock: clock, fetchAnnouncements: fetchAnnouncements);

  /// How close in time another dependency must succeed for a network failure to count as an
  /// Outage rather than the device being Offline.
  static const Duration networkFailureWindow = Duration(seconds: 30);
  static const Duration resumeRefreshAfter = Duration(minutes: 30);
  static const Duration outageRefreshCooldown = Duration(minutes: 1);

  /// Critical Announcements block part of Nearby, so while one is shown the app checks for it being
  /// withdrawn early.
  static const Duration criticalRefreshInterval = Duration(minutes: 5);

  /// NUS is reached through Transito's server, so only LTA and the server can vouch for each other's
  /// network reachability.
  static const Map<OutageSource, OutageSource> _independentSource = {
    OutageSource.lta: OutageSource.server,
    OutageSource.server: OutageSource.lta,
  };

  final DateTime Function() _clock;
  final Future<List<Announcement>> Function()? fetchAnnouncements;

  final Set<OutageSource> _outages = {};
  final Map<OutageSource, DateTime> _lastSuccessAt = {};
  final Map<OutageSource, DateTime> _pendingNetworkFailureAt = {};
  List<Announcement> _announcements = [];
  DateTime? _backgroundedAt;
  DateTime? _lastRefreshAt;
  bool _isRefreshing = false;
  int _serverGeneration = 0;
  Timer? _expiryTimer;
  Timer? _criticalRefreshTimer;

  List<OutageSource> get outages => OutageSource.values.where(_outages.contains).toList();
  List<Announcement> get announcements => _announcements.where(_isActive).toList();
  List<Announcement> get criticalAnnouncements => announcements
      .where((announcement) => announcement.severity == AnnouncementSeverity.CRITICAL)
      .toList();
  bool get hasAlerts => _outages.isNotEmpty || announcements.isNotEmpty;

  bool _isActive(Announcement announcement) {
    final DateTime? expiresAt = announcement.expiresAt;
    return expiresAt == null || _clock().isBefore(expiresAt);
  }

  void _setAnnouncements(List<Announcement> announcements) {
    _announcements = announcements;
    _scheduleExpiry();
    _scheduleCriticalRefresh();
    notifyListeners();
  }

  /// Hides each Announcement at its expiry time without waiting for the next fetch.
  void _scheduleExpiry() {
    _expiryTimer?.cancel();
    final List<DateTime> upcoming =
        _announcements
            .map((announcement) => announcement.expiresAt)
            .whereType<DateTime>()
            .where((expiresAt) => expiresAt.isAfter(_clock()))
            .toList()
          ..sort();
    if (upcoming.isEmpty) return;

    _expiryTimer = Timer(upcoming.first.difference(_clock()), () {
      _setAnnouncements(_announcements.where(_isActive).toList());
    });
  }

  void _scheduleCriticalRefresh() {
    if (criticalAnnouncements.isEmpty) {
      _criticalRefreshTimer?.cancel();
      _criticalRefreshTimer = null;
      return;
    }

    _criticalRefreshTimer ??= Timer.periodic(
      criticalRefreshInterval,
      (_) => refreshAnnouncements(),
    );
  }

  void start() {
    WidgetsBinding.instance.addObserver(this);
    refreshAnnouncements();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _backgroundedAt = _clock();
    } else if (state == AppLifecycleState.resumed) {
      final DateTime? backgroundedAt = _backgroundedAt;
      _backgroundedAt = null;
      if (backgroundedAt != null && _clock().difference(backgroundedAt) >= resumeRefreshAfter) {
        refreshAnnouncements();
      }
    }
  }

  Future<void> refreshAnnouncements() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    _lastRefreshAt = _clock();
    final int generation = _serverGeneration;

    try {
      final List<Announcement> announcements =
          await (fetchAnnouncements ?? TransitoApiService().getAnnouncements)();
      if (generation == _serverGeneration) {
        _setAnnouncements(announcements);
      }
    } catch (error) {
      // Keep the last known Announcements; the request failure is reported as a server Outage.
      debugPrint('Failed to fetch announcements: $error');
    } finally {
      _isRefreshing = false;
    }

    // The server changed mid-request, so fetch again from the new one
    if (generation != _serverGeneration) refreshAnnouncements();
  }

  /// Clears server-reported state when the app switches between the production and beta servers.
  void resetServerState() {
    _serverGeneration++;
    _lastSuccessAt.remove(OutageSource.server);
    _pendingNetworkFailureAt.remove(OutageSource.server);
    _outages.removeAll([OutageSource.server, OutageSource.nus]);
    _setAnnouncements([]);
    refreshAnnouncements();
  }

  void reportSuccess(OutageSource source) {
    final DateTime now = _clock();
    _lastSuccessAt[source] = now;
    _pendingNetworkFailureAt.remove(source);

    bool changed = _outages.remove(source);

    final OutageSource? vouchedFor = _independentSource[source];
    final DateTime? pendingFailureAt = _pendingNetworkFailureAt[vouchedFor];
    if (vouchedFor != null &&
        pendingFailureAt != null &&
        now.difference(pendingFailureAt) <= networkFailureWindow) {
      _pendingNetworkFailureAt.remove(vouchedFor);
      changed = _raise(vouchedFor) || changed;
    }

    if (changed) notifyListeners();
  }

  void reportFailure(OutageSource source, Object error) {
    if (error is NetworkException) {
      // NUS is only reached through Transito's server, so its network failures are the server's
      if (error.isTimeout || source == OutageSource.nus) return;
      _reportNetworkFailure(source);
      return;
    }

    if (isOutageError(source, error) && _raise(source)) {
      notifyListeners();
    }
  }

  void _reportNetworkFailure(OutageSource source) {
    final DateTime now = _clock();
    final DateTime? independentSuccessAt = _lastSuccessAt[_independentSource[source]];
    final bool anotherSourceReachable =
        independentSuccessAt != null &&
        now.difference(independentSuccessAt) <= networkFailureWindow;

    if (!anotherSourceReachable) {
      // Possibly Offline; confirm only if another dependency succeeds shortly after
      _pendingNetworkFailureAt[source] = now;
      return;
    }

    if (_raise(source)) notifyListeners();
  }

  bool _raise(OutageSource source) {
    if (!_outages.add(source)) return false;

    final DateTime? lastRefreshAt = _lastRefreshAt;
    if (lastRefreshAt == null || _clock().difference(lastRefreshAt) >= outageRefreshCooldown) {
      refreshAnnouncements();
    }
    return true;
  }

  /// Whether a non-network [error] from [source] means that dependency is down, rather than a
  /// problem with the request itself.
  @visibleForTesting
  static bool isOutageError(OutageSource source, Object error) {
    return switch (source) {
      OutageSource.nus => isNusUpstreamFailure(error),
      OutageSource.lta || OutageSource.server =>
        error is ApiParsingException ||
            (error is ApiException && error.statusCode >= 500 && !isNusUpstreamFailure(error)),
    };
  }

  /// Transito's server marks NUS failures with a 502 and `provider: "nus"`; any other 502, such as
  /// one from the tunnel in front of the server, is a server failure.
  static bool isNusUpstreamFailure(Object error) {
    if (error is! ApiException || error.statusCode != 502) return false;

    try {
      final Object? body = jsonDecode(error.responseBody ?? '');
      return body is Map<String, dynamic> && body['provider'] == 'nus';
    } on FormatException {
      return false;
    }
  }
}
