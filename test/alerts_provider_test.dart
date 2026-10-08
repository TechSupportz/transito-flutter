import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:transito/global/providers/alerts_provider.dart';
import 'package:transito/global/services/api_exceptions.dart';
import 'package:transito/models/api/transito/announcements.dart';

void main() {
  late DateTime now;
  late AlertsProvider alerts;

  setUp(() {
    now = DateTime(2026, 9, 23, 12);
    alerts = AlertsProvider.test(clock: () => now, fetchAnnouncements: () async => []);
  });

  ApiException status(int code, [String body = '']) =>
      ApiException(statusCode: code, message: 'failed', responseBody: body);

  NetworkException network({bool isTimeout = false}) =>
      NetworkException('Network error', isTimeout: isTimeout);

  group('LTA and server outages', () {
    test('raises on 5xx and unparseable bodies, and clears on the next success', () {
      alerts.reportFailure(OutageSource.lta, status(503));
      alerts.reportFailure(OutageSource.server, ApiParsingException('bad body'));
      expect(alerts.outages, [OutageSource.lta, OutageSource.server]);

      alerts.reportSuccess(OutageSource.lta);
      expect(alerts.outages, [OutageSource.server]);
    });

    test('ignores 4xx responses and timeouts', () {
      alerts.reportSuccess(OutageSource.server);
      alerts.reportFailure(OutageSource.lta, status(401));
      alerts.reportFailure(OutageSource.lta, network(isTimeout: true));
      expect(alerts.outages, isEmpty);
    });

    test('does not treat a NUS upstream 502 as a server outage', () {
      alerts.reportFailure(OutageSource.server, status(502, '{"provider":"nus"}'));
      alerts.reportFailure(OutageSource.server, status(504, '{"provider":"nus"}'));
      expect(alerts.outages, isEmpty);

      alerts.reportFailure(OutageSource.server, status(502, '<html>Bad gateway</html>'));
      expect(alerts.outages, [OutageSource.server]);
    });
  });

  group('network failures', () {
    test('raise an outage when another dependency recently succeeded', () {
      alerts.reportSuccess(OutageSource.lta);
      now = now.add(const Duration(seconds: 5));
      alerts.reportFailure(OutageSource.server, network());
      expect(alerts.outages, [OutageSource.server]);
    });

    test('are confirmed when another dependency succeeds shortly after', () {
      alerts.reportFailure(OutageSource.server, network());
      expect(alerts.outages, isEmpty);

      now = now.add(const Duration(seconds: 5));
      alerts.reportSuccess(OutageSource.lta);
      expect(alerts.outages, [OutageSource.server]);
    });

    test('are treated as Offline when every dependency fails', () {
      alerts.reportSuccess(OutageSource.lta);
      now = now.add(const Duration(minutes: 5));
      alerts.reportFailure(OutageSource.server, network());
      alerts.reportFailure(OutageSource.lta, network());
      expect(alerts.outages, isEmpty);
    });

    test('are not confirmed by a NUS success, which also goes through the server', () {
      alerts.reportFailure(OutageSource.server, network());
      alerts.reportSuccess(OutageSource.nus);
      expect(alerts.outages, isEmpty);
    });

    test('are never a NUS outage', () {
      alerts.reportSuccess(OutageSource.lta);
      alerts.reportFailure(OutageSource.nus, network());
      expect(alerts.outages, isEmpty);
    });
  });

  test('raises a NUS outage only for the NUS upstream marker', () {
    alerts.reportFailure(OutageSource.nus, status(500));
    alerts.reportFailure(OutageSource.nus, status(504, '{"provider":"nus"}'));
    expect(alerts.outages, isEmpty);

    alerts.reportFailure(OutageSource.nus, status(502, '{"provider":"nus"}'));
    expect(alerts.outages, [OutageSource.nus]);
  });

  test('hides announcements once they expire without refetching', () async {
    alerts = AlertsProvider.test(
      clock: () => now,
      fetchAnnouncements: () async => [
        Announcement(
          id: 'a',
          title: 'A',
          body: 'a',
          severity: AnnouncementSeverity.CRITICAL,
          expiresAt: now.add(const Duration(minutes: 10)),
        ),
      ],
    );

    await alerts.refreshAnnouncements();
    expect(alerts.criticalAnnouncements, hasLength(1));

    now = now.add(const Duration(minutes: 10));
    expect(alerts.criticalAnnouncements, isEmpty);
    expect(alerts.hasAlerts, isFalse);
  });

  test('exposes critical announcements separately', () async {
    alerts = AlertsProvider.test(
      clock: () => now,
      fetchAnnouncements: () async => [
        Announcement(id: 'a', title: 'A', body: 'a', severity: AnnouncementSeverity.INFO),
        Announcement(id: 'b', title: 'B', body: 'b', severity: AnnouncementSeverity.CRITICAL),
      ],
    );

    await alerts.refreshAnnouncements();

    expect(alerts.hasAlerts, isTrue);
    expect(alerts.criticalAnnouncements.map((announcement) => announcement.id), ['b']);
  });

  test('a request hung on the previous server does not block fetching from the new one', () async {
    final Completer<List<Announcement>> hung = Completer();
    int calls = 0;
    alerts = AlertsProvider.test(
      clock: () => now,
      fetchAnnouncements: () {
        calls++;
        if (calls == 1) return hung.future;
        return Future.value([
          Announcement(id: 'a', title: 'A', body: 'a', severity: AnnouncementSeverity.INFO),
        ]);
      },
    );

    unawaited(alerts.refreshAnnouncements());
    alerts.resetServerState();
    await pumpEventQueue();
    expect(alerts.announcements.map((announcement) => announcement.id), ['a']);

    // The stale response arriving late must not replace the new server's Announcements
    hung.complete([]);
    await pumpEventQueue();
    expect(alerts.announcements, hasLength(1));
    expect(calls, 2);
  });
}
