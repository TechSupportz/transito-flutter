import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_skeleton_ui/flutter_skeleton_ui.dart';

const double favouriteTimingRowExtent = 64;
const double favouriteTimingRowSpacing = 4;
const double favouriteTimingRowsBottomPadding = 16;

double favouriteTimingRowsHeight(int rowCount) {
  final int reservedRowCount = rowCount < 1 ? 1 : rowCount;
  return (reservedRowCount * favouriteTimingRowExtent) +
      ((reservedRowCount - 1) * favouriteTimingRowSpacing) +
      favouriteTimingRowsBottomPadding;
}

class FavouriteTimingRowsSkeleton extends StatelessWidget {
  const FavouriteTimingRowsSkeleton({super.key, required this.rowCount});

  final int rowCount;

  @override
  Widget build(BuildContext context) {
    final int reservedRowCount = rowCount < 1 ? 1 : rowCount;

    return Padding(
      padding: const EdgeInsets.only(bottom: favouriteTimingRowsBottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int index = 0; index < reservedRowCount; index++) ...[
            const SkeletonItem(
              child: SkeletonLine(
                style: SkeletonLineStyle(
                  height: favouriteTimingRowExtent - 3,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 1.5),
                ),
              ),
            ),
            if (index < reservedRowCount - 1) const SizedBox(height: favouriteTimingRowSpacing),
          ],
        ],
      ),
    );
  }
}

@Preview(name: 'Timing rows loading', group: 'Favourites', size: Size(390, 230))
Widget favouriteTimingRowsSkeletonPreview() {
  return const MaterialApp(
    home: Scaffold(
      body: Padding(
        padding: EdgeInsets.all(12),
        child: FavouriteTimingRowsSkeleton(rowCount: 3),
      ),
    ),
  );
}
