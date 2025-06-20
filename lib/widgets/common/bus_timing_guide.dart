import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class BusTimingGuide extends StatelessWidget {
  const BusTimingGuide({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Theme.of(context).brightness == Brightness.light
            ? SvgPicture.asset(
                'assets/images/quick_start_light.svg',
                placeholderBuilder: (context) => const CircularProgressIndicator(strokeWidth: 3),
              )
            : SvgPicture.asset(
                'assets/images/quick_start_dark.svg',
                placeholderBuilder: (context) => const CircularProgressIndicator(strokeWidth: 3),
              ),
        const SizedBox(
          height: 16,
        ),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(text: 'Timings in '),
              TextSpan(
                text: 'italics ',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
              TextSpan(text: 'are a rough estimate based on the bus\'s schedule'),
            ],
            style: TextStyle(
                fontFamily: 'Itim',
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
        const SizedBox(
          height: 16,
        ),
        const Text(
          'Tap the Bus Service Number to view more details such as routes!',
          style: TextStyle(fontFamily: 'Itim', fontSize: 18, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
