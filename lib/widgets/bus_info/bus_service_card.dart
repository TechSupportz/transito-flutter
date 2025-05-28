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
    final searchProvider = context.read()<SearchProvider>();
    final appColors = context.read<AppColors>();

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
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    color: appColors.getOperatorColor(busServiceInfo.operator).$1,
                    borderRadius: BorderRadius.circular(8)),
                child: Text(
                  busServiceInfo.operator.name,
                  style: TextStyle(
                    color: appColors.getOperatorColor(busServiceInfo.operator).$2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
