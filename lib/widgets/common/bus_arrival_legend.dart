import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:transito/models/app/app_typography.dart';
import 'package:transito/widgets/common/app_symbol.dart';

class BusArrivalLegend extends StatefulWidget {
  const BusArrivalLegend({super.key});

  @override
  State<BusArrivalLegend> createState() => _BusArrivalLegendState();
}

class _BusArrivalLegendState extends State<BusArrivalLegend> {
  static const Duration _tickDuration = Duration(milliseconds: 900);
  static const Duration _transitionDuration = Duration(milliseconds: 250);
  static const List<String> _busTypes = ['Single', 'Double', 'Bendy'];

  late final Timer _stateTimer;
  int _tickIndex = 0;
  int _sequenceIndex = 0;
  int _busTypeIndex = 0;

  static Widget _fadeTransition(Widget child, Animation<double> animation) {
    return FadeTransition(opacity: animation, child: child);
  }

  @override
  void initState() {
    super.initState();
    _stateTimer = Timer.periodic(_tickDuration, (_) {
      _tickIndex++;
      final bool shouldAdvanceCrowd = _tickIndex.isEven;
      final bool shouldAdvanceBusType = _tickIndex >= 3 && (_tickIndex - 3) % 4 == 0;

      if (shouldAdvanceCrowd || shouldAdvanceBusType) {
        setState(() {
          if (shouldAdvanceCrowd) {
            _sequenceIndex = (_sequenceIndex + 1) % 6;
          }
          if (shouldAdvanceBusType) {
            _busTypeIndex = (_busTypeIndex + 1) % _busTypes.length;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _stateTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    final List<({String label, Color color})> crowdStates = [
      (
        label: 'Seats available',
        color: isDark ? const Color(0xFF96E2B6) : const Color(0xFF52AD7D),
      ),
      (
        label: 'Standing available',
        color: isDark ? const Color(0xFFFFCEA6) : const Color(0xFFF5A650),
      ),
      (
        label: 'Limited standing',
        color: isDark ? const Color(0xFFFFAA8F) : const Color(0xFFF07251),
      ),
    ];
    final int crowdIndex = _sequenceIndex % crowdStates.length;
    final bool isScheduleEstimate = _sequenceIndex >= crowdStates.length;
    final (:label, :color) = crowdStates[crowdIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'What each part of an arrival tells you',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 12),
        Semantics(
          container: true,
          label:
              'A regular arrival time is based on live vehicle location, while an italic arrival '
              'time is based on the schedule. Its colour indicates crowd level: green means seats '
              'available, amber means standing available, and red means limited standing. The '
              'accessibility icon marks a wheelchair-friendly bus. Single, Double, or Bendy '
              'identifies the bus type.',
          child: ExcludeSemantics(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: _transitionDuration,
                    transitionBuilder: _fadeTransition,
                    child: Text(
                      label,
                      key: ValueKey<int>(crowdIndex),
                      style: AppTypography.body.copyWith(color: color),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: _transitionDuration,
                    transitionBuilder: _fadeTransition,
                    child: Text(
                      'arr',
                      key: ValueKey<int>(_sequenceIndex),
                      style: AppBusTypography.etaMinutes.copyWith(
                        color: color,
                        fontStyle: isScheduleEstimate ? FontStyle.italic : FontStyle.normal,
                        fontWeight: isScheduleEstimate ? FontWeight.w500 : FontWeight.w600,
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: _transitionDuration,
                    transitionBuilder: _fadeTransition,
                    child: Text(
                      isScheduleEstimate
                          ? 'Estimated based on schedule'
                          : 'Based on live bus location',
                      key: ValueKey<bool>(isScheduleEstimate),
                      style: AppTypography.caption.copyWith(
                        color: onSurfaceVariant,
                        fontStyle: isScheduleEstimate ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Divider(height: 32),
        Row(
          children: [
            Expanded(
              child: _ArrivalClue(
                visual: AppSymbol(
                  Symbols.accessible_rounded,
                  size: 24,
                  color: onSurfaceVariant,
                ),
                label: 'Wheelchair-friendly',
              ),
            ),
            Expanded(
              child: _ArrivalClue(
                visual: AnimatedSwitcher(
                  duration: _transitionDuration,
                  transitionBuilder: _fadeTransition,
                  child: _BusTypeTag(
                    key: ValueKey<int>(_busTypeIndex),
                    label: _busTypes[_busTypeIndex],
                    color: onSurfaceVariant,
                  ),
                ),
                label: 'Bus type',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BusTypeTag extends StatelessWidget {
  const _BusTypeTag({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(label, style: AppBusTypography.busTypeTag.copyWith(color: color)),
    );
  }
}

class _ArrivalClue extends StatelessWidget {
  const _ArrivalClue({required this.visual, required this.label});

  final Widget visual;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 28, child: Center(child: visual)),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
