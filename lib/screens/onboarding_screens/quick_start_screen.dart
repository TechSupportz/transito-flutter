import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../navbar_screens/main_screen.dart';

class QuickStartScreen extends StatelessWidget {
  const QuickStartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Almost there...'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'How to I decipher the details?',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  "assets/images/diagram.svg",
                  placeholderBuilder: (context) => const CircularProgressIndicator(),
                ),
                const SizedBox(
                  height: 16,
                ),
                const Text('Clicking the Bus Service Number will provide more details about it',
                    style:
                        TextStyle(fontFamily: 'Itim', fontSize: 18, fontWeight: FontWeight.w500)),
                // const SizedBox(
                //   height: 4,
                // ),
                // const Text(
                //     'If you press and hold on a bus service, you will get notification alerts on the bus\'s timing',
                //     style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ElevatedButton(
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MainScreen(),
                  ),
                  (Route<dynamic> route) => false,
                ),
                child: const Text("Take me to the home screen!"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
