import 'package:flutter/material.dart';
import 'package:flutter_skeleton_ui/flutter_skeleton_ui.dart';

class CheckboxSkeleton extends StatelessWidget {
  const CheckboxSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonListTile(
      leadingStyle: SkeletonAvatarStyle(
        width: 28,
        height: 28,
        borderRadius: BorderRadius.circular(5),
      ),
      titleStyle: SkeletonLineStyle(
          height: 20, padding: const EdgeInsets.only(left: 10), randomLength: true),
    );
  }
}
