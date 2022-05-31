import 'dart:ui';

import 'package:flutter/material.dart';

import '../modals/app_colors.dart';

class BusTimingRow extends StatefulWidget {
  const BusTimingRow({Key? key}) : super(key: key);

  @override
  State<BusTimingRow> createState() => _BusTimingRowState();
}

class _BusTimingRowState extends State<BusTimingRow> {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.ideographic,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('8', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500)),
            Text(
              'about 500m away',
              style:
                  TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.kindaGrey),
            ),
          ],
        ),
        SizedBox(width: 48),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ArrivalInfo(),
            ArrivalInfo(),
            ArrivalInfo(),
          ],
        ),
      ],
    );
  }
}

class ArrivalInfo extends StatefulWidget {
  const ArrivalInfo({Key? key}) : super(key: key);

  @override
  State<ArrivalInfo> createState() => _ArrivalInfoState();
}

class _ArrivalInfoState extends State<ArrivalInfo> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '8',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w500, color: AppColors.sortaRed),
        ),
        Row(
          children: [
            Icon(Icons.accessible_rounded, size: 16, color: AppColors.kindaGrey),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.5, vertical: 1.0),
              decoration: BoxDecoration(
                  border: Border.all(color: AppColors.kindaGrey),
                  borderRadius: BorderRadius.all(Radius.circular(5))),
              child: Text(
                'Single',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.kindaGrey,
                ),
              ),
            ),
          ],
        )
      ],
    );
  }
}
