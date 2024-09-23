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
            TextSpan(text: 'If the timing is in '),
            TextSpan(
              text: 'italics ',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            TextSpan(text: 'it\'s an estimated timing based on the bus schedule')
          ],
          style: TextStyle(fontFamily: 'Itim', fontSize: 18, fontWeight: FontWeight.w500),
        )),
        const SizedBox(
          height: 16,
        ),
        const Text(
          'Clicking the Bus Service Number will provide more details such as routes!',
          style: TextStyle(fontFamily: 'Itim', fontSize: 18, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
