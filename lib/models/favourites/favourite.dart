import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:latlong2/latlong.dart';
import 'package:transito/models/api/transito/bus_stops.dart';

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
  static const int aliasMaxLength = 40;

  String busStopCode;
  String busStopName;
  String busStopAddress;

  @JsonKey(includeIfNull: false)
  String? alias;

  @JsonKey(fromJson: decodeBusStopLocation, toJson: encodeBusStopLocation)
  LatLng busStopLocation;

  List<String?> services;
  @JsonKey(includeIfNull: false)
  BusStopProviderSources? sources;

  static LatLng decodeBusStopLocation(GeoPoint busStopGeoPoint) {
    return LatLng(busStopGeoPoint.latitude, busStopGeoPoint.longitude);
  }

  static GeoPoint encodeBusStopLocation(LatLng busStopLocation) {
    return GeoPoint(busStopLocation.latitude, busStopLocation.longitude);
  }

  Favourite({
    required this.busStopCode,
    required this.busStopName,
    required this.busStopAddress,
    required this.busStopLocation,
    required this.services,
    this.alias,
    this.sources,
  });

  String get displayName => alias ?? busStopName;

  static String? normalizeAlias(String? value) {
    final String? normalizedValue = value?.trim();
    return normalizedValue == null || normalizedValue.isEmpty ? null : normalizedValue;
  }

  static bool isAliasInUse({
    required Iterable<Favourite> favourites,
    required String? alias,
    String? excludingBusStopCode,
  }) {
    final String? normalizedAlias = normalizeAlias(alias);
    if (normalizedAlias == null) return false;

    return favourites.any(
      (Favourite favourite) =>
          favourite.busStopCode != excludingBusStopCode && favourite.alias == normalizedAlias,
    );
  }

  factory Favourite.fromJson(Map<String, dynamic> json) => _$FavouriteFromJson(json);
  Map<String, dynamic> toJson() => _$FavouriteToJson(this);
}
