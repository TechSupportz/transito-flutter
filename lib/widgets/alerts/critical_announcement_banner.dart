import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:transito/global/providers/alerts_provider.dart';
import 'package:transito/models/api/transito/announcements.dart';
import 'package:transito/models/app/app_typography.dart';
import 'package:transito/widgets/common/app_symbol.dart';

/// Persistent banner for critical Announcements. It cannot be dismissed; it disappears only when
/// the Announcement expires or is deleted.
///
/// Placed at the top of Nearby, it takes 8px of that screen's top spacing whether shown or hidden.
class CriticalAnnouncementBanner extends StatelessWidget {
  const CriticalAnnouncementBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Announcement> announcements = context.watch<AlertsProvider>().criticalAnnouncements;

    // Grows open and fades in, so content below is pushed down rather than jumping
    return AnimatedSwitcher(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 300),
      switchInCurve: Easing.emphasizedDecelerate,
      switchOutCurve: Easing.emphasizedAccelerate,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SizeTransition(sizeFactor: animation, alignment: Alignment.topCenter, child: child),
      ),
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: Alignment.topCenter,
        children: [...previousChildren, ?currentChild],
      ),
      child: announcements.isEmpty
          // The banner sits closer to the app bar than Nearby's first heading, so when hidden it
          // keeps that heading's usual spacing
          ? const SizedBox(key: ValueKey('none'), width: double.infinity, height: 8)
          : _Banners(
              key: ValueKey(announcements.map((announcement) => announcement.id).join(',')),
              announcements: announcements,
            ),
    );
  }
}

class _Banners extends StatelessWidget {
  const _Banners({super.key, required this.announcements});

  final List<Announcement> announcements;

  @override
  Widget build(BuildContext context) {
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
