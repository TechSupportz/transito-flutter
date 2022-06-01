import 'package:flutter/material.dart';
import 'package:transito/modals/app_colors.dart';

enum CrowdLvl {
  SEA, // for Seats Available
  SDA, // for Standing Available
  LSD // for Limited Standing
}

enum BusType {
  SD, // Single decker
  DD, // Double decker
  BD // Bendy
}

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
                    fontSize: 14, fontStyle: FontStyle.italic, color: AppColors.kindaGrey),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              ArrivalInfo(
                eta: "arr",
                accessible: true,
                crowdLvl: CrowdLvl.SEA,
                busType: BusType.SD,
              ),
              ArrivalInfo(
                eta: "8",
                accessible: true,
                crowdLvl: CrowdLvl.SDA,
                busType: BusType.DD,
              ),
              ArrivalInfo(
                eta: "16",
                accessible: true,
                crowdLvl: CrowdLvl.LSD,
                busType: BusType.BD,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ArrivalInfo extends StatefulWidget {
  const ArrivalInfo(
      {Key? key,
      required this.eta,
      required this.accessible,
      required this.crowdLvl,
      required this.busType})
      : super(key: key);

  final String eta;
  final bool accessible;
  final CrowdLvl crowdLvl;
  final BusType busType;

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
          padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 1.5),
          child: widget.accessible
              ? Icon(Icons.accessible_rounded, size: 16, color: AppColors.kindaGrey)
              : SizedBox(width: 16, height: 16),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              widget.eta,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w500,
                color: (() {
                  switch (widget.crowdLvl) {
                    case CrowdLvl.SEA:
                      {
                        return AppColors.prettyGreen;
                      }

                    case CrowdLvl.SDA:
                      {
                        return AppColors.notReallyYellow;
                      }

                    case CrowdLvl.LSD:
                      {
                        return AppColors.sortaRed;
                      }
                  }
                })(),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.5, vertical: 1.0),
              decoration: BoxDecoration(
                  border: Border.all(color: AppColors.kindaGrey),
                  borderRadius: BorderRadius.all(Radius.circular(5))),
              child: Text(
                (() {
                  switch (widget.busType) {
                    case BusType.SD:
                      {
                        return "Single";
                      }

                    case BusType.DD:
                      {
                        return "Double";
                      }

                    case BusType.BD:
                      {
                        return "Bendy";
                      }
                  }
                })(),
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
