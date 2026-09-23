import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:transito/global/providers/alerts_provider.dart';
import 'package:transito/models/api/transito/announcements.dart';
import 'package:transito/models/app/app_typography.dart';
import 'package:transito/widgets/common/app_symbol.dart';

/// Persistent banner for critical Announcements. It cannot be dismissed; it disappears only when
/// the Announcement expires or is deleted.
class CriticalAnnouncementBanner extends StatelessWidget {
  const CriticalAnnouncementBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Announcement> announcements = context.watch<AlertsProvider>().criticalAnnouncements;
    if (announcements.isEmpty) return const SizedBox.shrink();

    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          for (final Announcement announcement in announcements)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 12,
                children: [
                  AppSymbol(Symbols.error_rounded, color: colorScheme.onErrorContainer, fill: true),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2,
                      children: [
                        Text(
                          announcement.title,
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onErrorContainer,
                          ),
                        ),
                        Text(
                          announcement.body,
                          style: AppTypography.caption.copyWith(
                            color: colorScheme.onErrorContainer,
                          ),
                        ),
                      ],
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
