import 'package:json_annotation/json_annotation.dart';

part 'favourites.g.dart';

@JsonSerializable(createToJson: false)
class Favourites {
  String busStopCode;
  List<String> services;

  Favourites({
    required this.busStopCode,
    required this.services,
  });

  factory Favourites.fromJson(Map<String, dynamic> json) => _$FavouritesFromJson(json);
}
