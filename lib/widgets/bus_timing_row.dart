import 'package:flutter/material.dart';
import '../modals/app_colors.dart';

enum CrowdLvl {
  SEA, // for Seats Available
  SDA, // for Standing Available
  LSD // for Limited Standing
}

// enum BusType {
//
// }

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
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('8', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w500)),
              Text(
                'about 500m away',
                style: TextStyle(
                    fontSize: 16, fontStyle: FontStyle.italic, color: AppColors.kindaGrey),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ArrivalInfo(
                accessible: true,
                crowdLvl: CrowdLvl.SEA,
              ),
              ArrivalInfo(
                accessible: true,
                crowdLvl: CrowdLvl.SDA,
              ),
              ArrivalInfo(
                accessible: true,
                crowdLvl: CrowdLvl.LSD,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ArrivalInfo extends StatefulWidget {
  const ArrivalInfo({Key? key, required this.accessible, required this.crowdLvl}) : super(key: key);

  final bool accessible;
  final CrowdLvl crowdLvl;

  @override
  State<ArrivalInfo> createState() => _ArrivalInfoState();
}

class _ArrivalInfoState extends State<ArrivalInfo> {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 1.5),
          child: Icon(Icons.accessible_rounded, size: 16, color: AppColors.kindaGrey),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '8',
              style:
                  TextStyle(fontSize: 32, fontWeight: FontWeight.w500, color: AppColors.sortaRed),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.5, vertical: 1.0),
              decoration: BoxDecoration(
                  border: Border.all(color: AppColors.kindaGrey),
                  borderRadius: BorderRadius.all(Radius.circular(5))),
              child: Text(
                'Single',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.kindaGrey,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
