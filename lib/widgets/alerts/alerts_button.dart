import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:transito/global/providers/alerts_provider.dart';
import 'package:transito/models/api/transito/announcements.dart';
import 'package:transito/models/app/app_colors.dart';
import 'package:transito/models/app/app_typography.dart';
import 'package:transito/widgets/common/app_symbol.dart';

/// Top app bar action that opens the alert inbox. Only shown while any Alert is active.
class AlertsButton extends StatelessWidget {
  const AlertsButton({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors appColors = context.watch<AppColors>();
    final AlertsProvider alerts = context.watch<AlertsProvider>();

    return AnimatedSwitcher(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 250),
      switchInCurve: Easing.emphasizedDecelerate,
      switchOutCurve: Easing.emphasizedAccelerate,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: alerts.hasAlerts
          ? _buildButton(context, appColors, alerts)
          : const SizedBox.shrink(key: ValueKey('none')),
    );
  }

  Widget _buildButton(BuildContext context, AppColors appColors, AlertsProvider alerts) {
    final List<Announcement> announcements = alerts.announcements;
    final Color badgeColor;
    if (alerts.outages.isNotEmpty ||
        announcements.any(
          (announcement) => announcement.severity == AnnouncementSeverity.CRITICAL,
        )) {
      badgeColor = appColors.scheme.error;
    } else if (announcements.any(
      (announcement) => announcement.severity == AnnouncementSeverity.WARNING,
    )) {
      badgeColor = appColors.notReallyYellow;
    } else {
      badgeColor = appColors.accentColour;
    }

    return IconButton(
      key: const ValueKey('alerts'),
      tooltip: 'Alerts',
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (context) => const _AlertsSheet(),
      ),
      icon: Badge(
        smallSize: 8,
        backgroundColor: badgeColor,
        child: AppSymbol(
          alerts.outages.isNotEmpty ? Symbols.cloud_alert_rounded : Symbols.notifications_rounded,
          fill: true,
          color: alerts.outages.isNotEmpty ? appColors.scheme.error : null,
        ),
      ),
    );
  }
}

class _AlertsSheet extends StatelessWidget {
  const _AlertsSheet();

  @override
  Widget build(BuildContext context) {
    final AlertsProvider alerts = context.watch<AlertsProvider>();
    final AppColors appColors = context.watch<AppColors>();
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    // Most severe first, so a critical Announcement is never below the fold
    final List<Announcement> announcements = alerts.announcements
      ..sort((a, b) => b.severity.index.compareTo(a.severity.index));

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text('Alerts', style: AppTypography.sectionTitle),
            const SizedBox(height: 12),
            if (!alerts.hasAlerts)
              Text(
                'All clear right now',
                style: AppTypography.body.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            for (final OutageSource outage in alerts.outages)
              _AlertTile(
                icon: Symbols.cloud_off_rounded,
                color: colorScheme.error,
                title: _outageTitle(outage),
                body: _outageBody(outage),
              ),
            for (final Announcement announcement in announcements)
              _AlertTile(
                icon: _announcementIcon(announcement.severity),
                color: switch (announcement.severity) {
                  AnnouncementSeverity.INFO => colorScheme.primary,
                  AnnouncementSeverity.WARNING => appColors.notReallyYellow,
                  AnnouncementSeverity.CRITICAL => colorScheme.error,
                },
                title: announcement.title,
                body: announcement.body,
              ),
          ],
        ),
      ),
    );
  }

  static String _outageTitle(OutageSource outage) => switch (outage) {
    OutageSource.lta => "LTA's not talking to us right now",
    OutageSource.nus => "NUS isn't responding right now",
    OutageSource.server => "Can't reach Transito's server",
  };

  static String _outageBody(OutageSource outage) => switch (outage) {
    OutageSource.lta => 'Public bus timings may be unavailable.',
    OutageSource.nus => 'NUS shuttle timings may be unavailable.',
    OutageSource.server => 'Nearby stops, search, and NUS shuttle timings may not load.',
  };

  static IconData _announcementIcon(AnnouncementSeverity severity) => switch (severity) {
    AnnouncementSeverity.INFO => Symbols.info_rounded,
    AnnouncementSeverity.WARNING => Symbols.warning_rounded,
    AnnouncementSeverity.CRITICAL => Symbols.error_rounded,
  };
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        spacing: 12,
        children: [
          AppSymbol(icon, color: color, fill: true),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(title, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
                Text(
                  body,
                  style: AppTypography.caption.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
