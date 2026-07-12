import 'dart:async';

import 'package:flutter/material.dart';
import 'package:transito/global/providers/quick_start_tour_provider.dart';

class QuickStartTourOverlay extends StatefulWidget {
  const QuickStartTourOverlay({super.key, required this.controller});

  final QuickStartTourController controller;

  @override
  State<QuickStartTourOverlay> createState() => _QuickStartTourOverlayState();
}

class _QuickStartTourOverlayState extends State<QuickStartTourOverlay> {
  Timer? _refreshTimer;
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
    _observedStepIndex = widget.controller.stepIndex;
    _visibleStepIndex = _observedStepIndex;
    widget.controller.addListener(_handleControllerChanged);
    _refreshTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
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
    setState(() {
      _candidateRect = null;
      _stableRectSamples = 0;
      _missingTargetSamples = 0;
      _spotlightReady = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealAndRefresh());
  }

  Future<void> _revealAndRefresh() async {
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
            : const Duration(milliseconds: 300),
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
    final BuildContext? targetContext = widget.controller.registry
        .keyFor(widget.controller.step.target)
        .currentContext;
    final RenderObject? renderObject = targetContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      _missingTargetSamples++;
      if (_missingTargetSamples >= 7 && _visibleStepIndex != _observedStepIndex) {
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
      if (_stableRectSamples < 2) return;
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

  void _handleCoachAlignmentEnd() {
    if (!mounted || _visibleStepIndex == _observedStepIndex) return;
    setState(() => _visibleStepIndex = _observedStepIndex);
  }

  bool _rectsAreClose(Rect first, Rect second, {required double tolerance}) {
    return (first.left - second.left).abs() <= tolerance &&
        (first.top - second.top).abs() <= tolerance &&
        (first.right - second.right).abs() <= tolerance &&
        (first.bottom - second.bottom).abs() <= tolerance;
  }

  Alignment _alignmentFor(Rect target) {
    return target.center.dy > MediaQuery.sizeOf(context).height * 0.55
        ? Alignment.topCenter
        : Alignment.bottomCenter;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
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
    final bool spotlightHidden = !_spotlightReady || widget.controller.isSpotlightDismissed;
    final Color scrim = Colors.black.withValues(alpha: 0.52);
    final QuickStartTourStep activeStep = widget.controller.step;
    final QuickStartTourStep visibleStep = QuickStartTourController.steps[_visibleStepIndex];
    final bool isCoachMoving = _visibleStepIndex != _observedStepIndex;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              ignoring: spotlightHidden,
              child: AnimatedOpacity(
                opacity: spotlightHidden ? 0 : 1,
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 160),
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
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 220),
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
                          : const Duration(milliseconds: 220),
                      transitionBuilder: (Widget child, Animation<double> animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: Padding(
                        key: ValueKey<int>(_visibleStepIndex),
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_visibleStepIndex + 1} of ${QuickStartTourController.steps.length}',
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(visibleStep.title, style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 6),
                            Text(visibleStep.message, style: Theme.of(context).textTheme.bodyLarge),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                TextButton(
                                  onPressed: widget.controller.onFinished,
                                  child: const Text('Skip'),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: visibleStep.showPrimaryAction
                                        ? FilledButton(
                                            onPressed: widget.controller.next,
                                            child: Text(visibleStep.primaryLabel),
                                          )
                                        : Text(
                                            target == null
                                                ? 'Waiting for this screen…'
                                                : 'Tap the highlighted control',
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
