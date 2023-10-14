import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transito/models/api/transito/bus_services.dart';

import 'package:transito/models/app/app_colors.dart';
import 'package:transito/models/enums/bus_operator_enum.dart';
import 'package:transito/providers/search_provider.dart';
import 'package:transito/screens/bus_info/bus_service_info_screen.dart';

class BusServiceCard extends StatelessWidget {
  const BusServiceCard({Key? key, required this.busServiceInfo}) : super(key: key);

  final BusServiceInfo busServiceInfo;

  // function that returns the correct colours for each bus operator
  Color getOperatorColor(BusOperator operator) {
    switch (operator) {
      case BusOperator.SBST:
        return AppColors.SBST;
      case BusOperator.SMRT:
        return AppColors.SMRT;
      case BusOperator.TTS:
        return AppColors.TTS;
      case BusOperator.GAS:
        return AppColors.GAS;
      default:
        return AppColors.accentColour;
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchProvider = Provider.of<SearchProvider>(context, listen: false);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          searchProvider.addRecentSearch(busServiceInfo);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BusServiceInfoScreen(busServiceInfo: busServiceInfo),
            ),
          );
        },
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Container(
          decoration:
              BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                busServiceInfo.serviceNo,
                overflow: TextOverflow.fade,
                maxLines: 1,
                softWrap: false,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                    color: getOperatorColor(busServiceInfo.operator),
                    borderRadius: BorderRadius.circular(5)),
                child: Text(busServiceInfo.operator.name,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
