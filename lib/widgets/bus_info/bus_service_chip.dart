import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:transito/models/api/transito/bus_services.dart';
import 'package:transito/models/app/app_colors.dart';
import 'package:transito/models/secret.dart';
import 'package:transito/screens/bus_info/bus_service_info_screen.dart';

class BusServiceChip extends StatelessWidget {
  const BusServiceChip({Key? key, required this.busServiceNumber, required this.isOperating})
      : super(key: key);

  final String busServiceNumber;
  final bool isOperating;

  Future<BusService> getBusServiceInfo() async {
    final response = await http.get(
      Uri.parse('${Secret.API_URL}/bus-service/$busServiceNumber'),
    );

    if (response.statusCode == 200) {
      debugPrint("Service info fetched");
      return BusServiceDetailsApiResponse.fromJson(json.decode(response.body)).data;
    } else {
      debugPrint("Error fetching bus service info");
      throw Exception("Error fetching bus service routes");
    }
  }

  Future<void> goToBusServiceInfoScreen(BuildContext context) async {
    BusService busService = await getBusServiceInfo();

    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BusServiceInfoScreen(
          busService: busService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isOperating ? 1 : 0.5,
      child: InkWell(
        onTap: () => goToBusServiceInfoScreen(context),
        borderRadius: BorderRadius.circular(7.5),
        splashColor: AppColors.accentColour.withOpacity(0.75),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.accentColour, width: 1.5),
            borderRadius: BorderRadius.circular(7.5),
          ),
          child: Text(
            busServiceNumber,
            style: const TextStyle(
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }
}
