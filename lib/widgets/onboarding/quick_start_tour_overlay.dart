import 'dart:async';

import 'package:flutter/material.dart';
import 'package:transito/global/providers/quick_start_tour_provider.dart';

class QuickStartTourOverlay extends StatefulWidget {
  const QuickStartTourOverlay({super.key, required this.controller});

  final QuickStartTourController controller;

  @override
  State<QuickStartTourOverlay> createState() => _QuickStartTourOverlayState();
}

class _QuickStartTourOverlayState extends State<QuickStartTourOverlay>
    with SingleTickerProviderStateMixin {
  static const Duration _coachMoveDuration = Duration(milliseconds: 320);
  static const Duration _contentTransitionDuration = Duration(milliseconds: 160);

  Timer? _refreshTimer;
  Timer? _pagePulseTimer;
  late final AnimationController _pagePulseController;
  late final Animation<double> _pagePulseOpacity;
  Rect? _targetRect;
  Rect? _candidateRect;
  bool _revealingTarget = false;
  bool _spotlightReady = false;
  int _stableRectSamples = 0;
  int _missingTargetSamples = 0;
  late int _observedStepIndex;
  late int _visibleStepIndex;
  Alignment _coachAlignment = Alignment.bottomCenter;

  @override
  void initState() {
    super.initState();
    _pagePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _pagePulseOpacity = TweenSequence<double>([
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: 0,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 45,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: 1,
          end: 0,
        ).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 55,
      ),
    ]).animate(_pagePulseController);
    _observedStepIndex = widget.controller.stepIndex;
    _visibleStepIndex = _observedStepIndex;
    widget.controller.addListener(_handleControllerChanged);
    _refreshTimer = Timer.periodic(const Duration(milliseconds: 60), (_) {
      if (widget.controller.step.highlightBehavior == QuickStartHighlightBehavior.pagePulse) {
        return;
      }
      if (_targetRect == null) {
        _revealAndRefresh();
      } else {
        _refreshTarget();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealAndRefresh());
  }

  @override
  void didUpdateWidget(covariant QuickStartTourOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChanged);
      _cancelPagePulse();
      _observedStepIndex = widget.controller.stepIndex;
      _visibleStepIndex = _observedStepIndex;
      widget.controller.addListener(_handleControllerChanged);
      _revealAndRefresh();
    }
  }

  void _handleControllerChanged() {
    if (!mounted) return;
    if (_observedStepIndex == widget.controller.stepIndex) {
      setState(() {});
      return;
    }

    _observedStepIndex = widget.controller.stepIndex;
    _cancelPagePulse();
    setState(() {
      _candidateRect = null;
      _stableRectSamples = 0;
      _missingTargetSamples = 0;
      _spotlightReady = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealAndRefresh());
  }

  Future<void> _revealAndRefresh() async {
    if (widget.controller.step.highlightBehavior == QuickStartHighlightBehavior.pagePulse) {
      _showPageStep();
      return;
    }
    if (_revealingTarget || !mounted) return;
    _revealingTarget = true;
    final BuildContext? targetContext = widget.controller.registry
        .keyFor(widget.controller.step.target)
        .currentContext;
    if (targetContext != null) {
      await Scrollable.ensureVisible(
        targetContext,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
        curve: Easing.emphasizedDecelerate,
        alignment: 0.35,
      );
    }
    if (mounted) {
      _refreshTarget();
      _revealingTarget = false;
    }
  }

  void _refreshTarget() {
    if (!mounted) return;
    if (widget.controller.step.highlightBehavior == QuickStartHighlightBehavior.pagePulse) {
      return;
    }
    final BuildContext? targetContext = widget.controller.registry
        .keyFor(widget.controller.step.target)
        .currentContext;
    final RenderObject? renderObject = targetContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      _missingTargetSamples++;
      if (_missingTargetSamples >= 5 && _visibleStepIndex != _observedStepIndex) {
        setState(() => _visibleStepIndex = _observedStepIndex);
      }
      return;
    }
    _missingTargetSamples = 0;
    final Rect nextRect = renderObject.localToGlobal(Offset.zero) & renderObject.size;
    if (_candidateRect != null && _rectsAreClose(_candidateRect!, nextRect, tolerance: 0.75)) {
      _stableRectSamples++;
    } else {
      _candidateRect = nextRect;
      _stableRectSamples = 0;
    }

    if (!_spotlightReady) {
      if (_stableRectSamples < 1) return;
      _showTarget(nextRect);
      return;
    }

    final Rect? currentRect = _targetRect;
    if (currentRect == null || !_rectsAreClose(currentRect, nextRect, tolerance: 1.5)) {
      _showTarget(nextRect);
    }
  }

  void _showTarget(Rect targetRect) {
    final Alignment nextAlignment = _alignmentFor(targetRect);
    final bool waitForCoach =
        _visibleStepIndex != _observedStepIndex &&
        nextAlignment != _coachAlignment &&
        !MediaQuery.disableAnimationsOf(context);

    setState(() {
      _targetRect = targetRect;
      _spotlightReady = true;
      _coachAlignment = nextAlignment;
      if (!waitForCoach) {
        _visibleStepIndex = _observedStepIndex;
      }
    });
  }

  void _showPageStep() {
    if (!mounted) return;
    final Alignment nextAlignment = switch (widget.controller.step.coachPlacement) {
      QuickStartCoachPlacement.top => Alignment.topCenter,
      QuickStartCoachPlacement.bottom => Alignment.bottomCenter,
      QuickStartCoachPlacement.automatic => Alignment.bottomCenter,
    };
    final bool waitForCoach =
        _visibleStepIndex != _observedStepIndex &&
        nextAlignment != _coachAlignment &&
        !MediaQuery.disableAnimationsOf(context);

    setState(() {
      _targetRect = null;
      _candidateRect = null;
      _spotlightReady = true;
      _coachAlignment = nextAlignment;
      if (!waitForCoach) {
        _visibleStepIndex = _observedStepIndex;
      }
    });
    if (!waitForCoach) {
      _schedulePagePulse();
    }
  }

  void _handleCoachAlignmentEnd() {
    if (!mounted || _visibleStepIndex == _observedStepIndex) return;
    setState(() => _visibleStepIndex = _observedStepIndex);
    _schedulePagePulse();
  }

  void _schedulePagePulse() {
    _pagePulseTimer?.cancel();
    if (MediaQuery.disableAnimationsOf(context) ||
        widget.controller.step.highlightBehavior != QuickStartHighlightBehavior.pagePulse ||
        _visibleStepIndex != _observedStepIndex) {
      return;
    }
    final int expectedStepIndex = _observedStepIndex;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          _observedStepIndex != expectedStepIndex ||
          widget.controller.step.highlightBehavior != QuickStartHighlightBehavior.pagePulse ||
          _visibleStepIndex != _observedStepIndex) {
        return;
      }
      _pagePulseTimer = Timer(_contentTransitionDuration, () {
        if (!mounted ||
            _observedStepIndex != expectedStepIndex ||
            widget.controller.step.highlightBehavior != QuickStartHighlightBehavior.pagePulse ||
            _visibleStepIndex != _observedStepIndex) {
          return;
        }
        _pagePulseController.forward(from: 0);
      });
    });
  }

  void _cancelPagePulse() {
    _pagePulseTimer?.cancel();
    _pagePulseController
      ..stop()
      ..reset();
  }

  bool _rectsAreClose(Rect first, Rect second, {required double tolerance}) {
    return (first.left - second.left).abs() <= tolerance &&
        (first.top - second.top).abs() <= tolerance &&
        (first.right - second.right).abs() <= tolerance &&
        (first.bottom - second.bottom).abs() <= tolerance;
  }

  Alignment _alignmentFor(Rect target) {
    switch (widget.controller.step.coachPlacement) {
      case QuickStartCoachPlacement.top:
        return Alignment.topCenter;
      case QuickStartCoachPlacement.bottom:
        return Alignment.bottomCenter;
      case QuickStartCoachPlacement.automatic:
        break;
    }
    return target.center.dy > MediaQuery.sizeOf(context).height * 0.55
        ? Alignment.topCenter
        : Alignment.bottomCenter;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _pagePulseTimer?.cancel();
    _pagePulseController.dispose();
    widget.controller.removeListener(_handleControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final Rect? visibleTarget = _targetRect?.intersect(Offset.zero & size);
    final Rect? target = visibleTarget == null || visibleTarget.isEmpty
        ? null
        : visibleTarget.inflate(8).intersect(Offset.zero & size);
    final QuickStartTourStep activeStep = widget.controller.step;
    final bool usesSpotlight =
        activeStep.highlightBehavior == QuickStartHighlightBehavior.spotlight;
    final bool spotlightHidden =
        !usesSpotlight || !_spotlightReady || widget.controller.isSpotlightDismissed;
    final Color scrim = Colors.black.withValues(alpha: 0.52);
    final QuickStartTourStep visibleStep = QuickStartTourController.steps[_visibleStepIndex];
    final bool isCoachMoving = _visibleStepIndex != _observedStepIndex;
    final bool targetIsVisible = _spotlightReady && target != null;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          if (activeStep.highlightBehavior == QuickStartHighlightBehavior.pagePulse)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _pagePulseOpacity,
                  builder: (BuildContext context, Widget? child) => ColoredBox(
                    key: const ValueKey<String>('quick-start-page-pulse'),
                    color: Theme.of(context).colorScheme.primary.withValues(
                      alpha: 0.12 * _pagePulseOpacity.value,
                    ),
                  ),
                ),
              ),
            ),
          Positioned.fill(
            child: IgnorePointer(
              ignoring: spotlightHidden,
              child: AnimatedOpacity(
                opacity: spotlightHidden ? 0 : 1,
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 110),
                curve: Easing.standard,
                child: Stack(
                  children: [
                    if (target == null)
                      Positioned.fill(child: ColoredBox(color: scrim))
                    else ...[
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        height: target.top,
                        child: ColoredBox(color: scrim),
                      ),
                      Positioned(
                        left: 0,
                        top: target.top,
                        width: target.left,
                        height: target.height,
                        child: ColoredBox(color: scrim),
                      ),
                      Positioned(
                        left: target.right,
                        right: 0,
                        top: target.top,
                        height: target.height,
                        child: ColoredBox(color: scrim),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        top: target.bottom,
                        bottom: 0,
                        child: ColoredBox(color: scrim),
                      ),
                      Positioned.fromRect(
                        rect: target,
                        child: IgnorePointer(
                          child: CustomPaint(
                            key: const ValueKey<String>('quick-start-cutout'),
                            painter: _SpotlightCutoutPainter(
                              color: scrim,
                              radius: activeStep.spotlightRadius,
                            ),
                          ),
                        ),
                      ),
                      Positioned.fromRect(
                        rect: target,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.85),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(activeStep.spotlightRadius),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.08),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (!activeStep.allowsInteraction)
                        Positioned.fromRect(
                          rect: target,
                          child: const AbsorbPointer(child: SizedBox.expand()),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          AnimatedAlign(
            alignment: _coachAlignment,
            duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : _coachMoveDuration,
            curve: Easing.emphasizedDecelerate,
            onEnd: _handleCoachAlignmentEnd,
            child: SafeArea(
              minimum: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: AbsorbPointer(
                  absorbing: isCoachMoving,
                  child: Card(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    elevation: 8,
                    child: AnimatedSwitcher(
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : _contentTransitionDuration,
                      transitionBuilder: (Widget child, Animation<double> animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: Padding(
                        key: ValueKey<int>(_visibleStepIndex),
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(
                              label: 'Quick Start progress',
                              value: '${(visibleStep.progress * 100).round()} percent',
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  key: const ValueKey<String>('quick-start-progress'),
                                  value: visibleStep.progress,
                                  minHeight: 6,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(visibleStep.title, style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 6),
                            _QuickStartStepContent(step: visibleStep),
                            if (widget.controller.primaryError case final String error) ...[
                              const SizedBox(height: 8),
                              Text(
                                error,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                if (visibleStep.showSecondaryAction) ...[
                                  TextButton(
                                    onPressed: widget.controller.isPrimaryActionLoading
                                        ? null
                                        : widget.controller.onSecondaryPressed,
                                    child: Text(visibleStep.secondaryLabel),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: widget.controller.showPrimaryActionFor(visibleStep)
                                        ? FilledButton(
                                            onPressed: widget.controller.isPrimaryActionLoading
                                                ? null
                                                : widget.controller.onPrimaryPressed,
                                            child: widget.controller.isPrimaryActionLoading
                                                ? const SizedBox.square(
                                                    dimension: 18,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                                  )
                                                : Text(
                                                    widget.controller.primaryLabelFor(visibleStep),
                                                  ),
                                          )
                                        : Text(
                                            widget.controller.targetInstructionFor(
                                              visibleStep,
                                              targetIsVisible: targetIsVisible,
                                            ),
                                            textAlign: TextAlign.end,
                                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStartStepContent extends StatelessWidget {
  const _QuickStartStepContent({required this.step});

  final QuickStartTourStep step;

  @override
  Widget build(BuildContext context) {
    return switch (step.contentKind) {
      QuickStartContentKind.text => Text(
        step.message,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      QuickStartContentKind.arrivalLegend => const _ArrivalLegend(),
    };
  }
}

class _ArrivalLegend extends StatelessWidget {
  const _ArrivalLegend();

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color seatsAvailable = isDark ? const Color(0xFF96E2B6) : const Color(0xFF52AD7D);
    final Color standingAvailable = isDark ? const Color(0xFFFFCEA6) : const Color(0xFFF5A650);
    final Color limitedStanding = isDark ? const Color(0xFFFFAA8F) : const Color(0xFFF07251);
    final TextStyle body = Theme.of(context).textTheme.bodyLarge ?? const TextStyle();

    TextSpan legend(Color color, String label, String meaning) => TextSpan(
      children: [
        TextSpan(
          text: label,
          style: body.copyWith(color: color, fontWeight: FontWeight.w700),
        ),
        TextSpan(text: ' — $meaning\n', style: body),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(
            children: [
              legend(seatsAvailable, 'Green', 'seats available'),
              legend(standingAvailable, 'Amber', 'standing available'),
              legend(limitedStanding, 'Red', 'limited standing'),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(
            style: body,
            children: [
              const TextSpan(
                text: 'Italic ETAs',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
              const TextSpan(text: ' are schedule estimates. The accessibility icon marks '),
              const TextSpan(
                text: 'wheelchair-friendly',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const TextSpan(text: ' buses, and '),
              const TextSpan(
                text: 'Single / Double / Bendy',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const TextSpan(text: ' identifies the bus type.'),
            ],
          ),
        ),
      ],
    );
  }
}

class _SpotlightCutoutPainter extends CustomPainter {
  const _SpotlightCutoutPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;
    final Path corners = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(bounds)
      ..addRRect(RRect.fromRectAndRadius(bounds, Radius.circular(radius)));
    canvas.drawPath(corners, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SpotlightCutoutPainter oldDelegate) {
    return color != oldDelegate.color || radius != oldDelegate.radius;
  }
}
