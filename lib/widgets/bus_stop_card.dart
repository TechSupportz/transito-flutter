import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:transito/models/app_colors.dart';

class BusStopCard extends StatelessWidget {
  const BusStopCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => debugPrint("tap"),
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Ink(
          decoration:
              BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(10)),
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  "Blk 121",
                  overflow: TextOverflow.fade,
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    margin: EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                        color: AppColors.veryPurple, borderRadius: BorderRadius.circular(5)),
                    child: Text(
                      "72069",
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "Bedok Reservoir Rd",
                      overflow: TextOverflow.fade,
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(color: AppColors.kindaGrey, fontStyle: FontStyle.italic),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
