import 'package:flutter/material.dart';
import 'package:transito/models/api/transito/bus_services.dart';
import 'package:transito/models/app/app_colors.dart';
import 'package:transito/widgets/bus_info/bus_stop_card.dart';

class BusServiceInfoScreen extends StatefulWidget {
  const BusServiceInfoScreen({
    Key? key,
    required this.busService,
  }) : super(key: key);

  final BusService busService;

  @override
  State<BusServiceInfoScreen> createState() => _BusServiceInfoScreenState();
}

class _BusServiceInfoScreenState extends State<BusServiceInfoScreen> {
  int _destinationIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Service Info'),
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 12.0, right: 12.0, top: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bus ${widget.busService.serviceNo}',
                  overflow: TextOverflow.fade,
                  maxLines: 1,
                  softWrap: false,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                      color: AppColors.getOperatorColor(widget.busService.operator),
                      borderRadius: BorderRadius.circular(5)),
                  child: Text(widget.busService.operator.name,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Interchange${widget.busService.isLoopService ? "" : "s"}",
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.start,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Flexible(
                      child: Column(
                        verticalDirection: _destinationIndex == 0
                            ? VerticalDirection.down
                            : VerticalDirection.up, // TODO - figure out how to animate this
                        children: [
                          BusStopCard(
                            busStopInfo: widget.busService.interchanges[0],
                            searchMode: true,
                          ),
                          if (!widget.busService.isLoopService) ...[
                            const SizedBox(height: 24),
                            BusStopCard(
                              busStopInfo: widget.busService.interchanges[1],
                              searchMode: true,
                            ),
                          ]
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        const SizedBox(
                          height: 79,
                          child: Icon(
                            Icons.radio_button_unchecked_rounded,
                            color: AppColors.prettyGreen,
                            size: 28,
                          ),
                        ),
                        SizedBox(
                          height: 30,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            iconSize: 32,
                            splashRadius: 24,
                            icon: const Icon(
                              Icons.swap_vert_rounded,
                            ),
                            onPressed: () {
                              setState(() => _destinationIndex = (_destinationIndex + 1) % 2);
                            },
                          ),
                        ),
                        const SizedBox(
                          height: 79,
                          child: Icon(
                            Icons.place_rounded,
                            color: AppColors.sortaRed,
                            size: 28,
                          ),
                        ),
                      ],
                    )
                  ],
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
