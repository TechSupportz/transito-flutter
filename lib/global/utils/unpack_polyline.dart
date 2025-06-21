import 'package:latlong2/latlong.dart';
export 'package:google_polyline_algorithm/google_polyline_algorithm.dart' show decodePolyline;

extension PolylineExt on List<List<num>> {
  List<LatLng> unpackPolyline() => map((p) => LatLng(p[0].toDouble(), p[1].toDouble())).toList();
}
