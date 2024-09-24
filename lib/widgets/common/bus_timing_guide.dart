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
        SvgPicture.asset(
          "assets/images/diagram.svg",
          placeholderBuilder: (context) => const CircularProgressIndicator(strokeWidth: 3),
        ),
        const SizedBox(
          height: 16,
        ),
        RichText(
            text: const TextSpan(
          children: [
            TextSpan(text: 'Timings in '),
            TextSpan(
              text: 'italics ',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            TextSpan(text: 'are a rough estimate based on the bus\'s schedule'),
          ],
          style: TextStyle(fontFamily: 'Itim', fontSize: 18, fontWeight: FontWeight.w500),
        )),
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
