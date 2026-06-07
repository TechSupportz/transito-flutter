import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:transito/models/app/app_typography.dart';
import 'package:transito/widgets/common/app_symbol.dart';

enum ErrorTextStyle {
  inline,
  stacked,
}

class ErrorText extends StatelessWidget {
  const ErrorText({
    super.key,
    this.enableBackground = false,
    this.style = ErrorTextStyle.stacked,
    this.title = "Something went wrong",
    this.message = "Try again in a moment",
    this.icon = Symbols.bus_alert_rounded,
    this.showIcon = true,
  });

  final bool enableBackground;
  final ErrorTextStyle style;
  final String title;
  final String message;
  final IconData? icon;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final Color textColor = Theme.of(context).colorScheme.onSurfaceVariant;

    Widget inlineErrorText = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 8,
      children: [
        if (showIcon && icon != null) ...[
          AppSymbol(
            icon!,
            size: 32,
            color: textColor,
            fill: true,
          ),
        ],
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            Text(
              message,
              style: AppTypography.caption.copyWith(color: textColor),
            ),
          ],
        ),
      ],
    );

    Widget stackedErrorText = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon && icon != null) ...[
          AppSymbol(
            icon!,
            size: 42,
            color: textColor,
            fill: true,
          ),
          SizedBox(height: 8),
        ],
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTypography.cardTitle.copyWith(color: textColor),
        ),
        if (message.isNotEmpty) ...[
          SizedBox(height: 2),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(color: textColor),
          ),
        ],
      ],
    );

    final Widget errorText = Center(
      child: style == ErrorTextStyle.inline ? inlineErrorText : stackedErrorText,
    );

    if (enableBackground) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: errorText,
        ),
      );
    }

    return errorText;
  }
}
