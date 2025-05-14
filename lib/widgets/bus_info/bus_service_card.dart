import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transito/global/providers/search_provider.dart';
import 'package:transito/models/api/transito/bus_services.dart';
import 'package:transito/models/app/app_colors.dart';
import 'package:transito/screens/bus_info/bus_service_info_screen.dart';

class BusServiceCard extends StatelessWidget {
  const BusServiceCard({super.key, required this.busServiceInfo});

  final BusService busServiceInfo;

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
              builder: (context) => BusServiceInfoScreen(
                serviceNo: busServiceInfo.serviceNo,
                busService: busServiceInfo,
              ),
              settings: const RouteSettings(name: 'BusServiceInfoScreen'),
            ),
          );
        },
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Container(
          decoration: BoxDecoration(
              color: AppColors.cardBg(context), borderRadius: BorderRadius.circular(10)),
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
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                    color: AppColors.getOperatorColor(busServiceInfo.operator),
                    borderRadius: BorderRadius.circular(5)),
                child: Text(
                  busServiceInfo.operator.name,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
