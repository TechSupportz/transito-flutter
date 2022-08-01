import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:latlong2/latlong.dart';

part 'favourite.g.dart';

@JsonSerializable(explicitToJson: true)
class FavouritesList {
  List<Favourite> favouritesList;

  FavouritesList({
    required this.favouritesList,
  });

  factory FavouritesList.fromFirestore(DocumentSnapshot doc) =>
      FavouritesList.fromJson(doc.data()! as Map<String, dynamic>);

  factory FavouritesList.fromJson(Map<String, dynamic> json) => _$FavouritesListFromJson(json);
  Map<String, dynamic> toJson() => _$FavouritesListToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Favourite {
  String busStopCode;
  String busStopName;
  String busStopAddress;

  @JsonKey(fromJson: decodeBusStopLocation)
  LatLng busStopLocation;

  List<String?> services;

  static LatLng decodeBusStopLocation(GeoPoint busStopGeoPoint) {
    return LatLng(busStopGeoPoint.latitude, busStopGeoPoint.longitude);
  }

  Favourite({
    required this.busStopCode,
    required this.busStopName,
    required this.busStopAddress,
    required this.busStopLocation,
    required this.services,
  });

  factory Favourite.fromJson(Map<String, dynamic> json) => _$FavouriteFromJson(json);
  Map<String, dynamic> toJson() => _$FavouriteToJson(this);
}
