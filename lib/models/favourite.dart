import 'package:json_annotation/json_annotation.dart';

part 'favourite.g.dart';

@JsonSerializable(explicitToJson: true)
class Favourite {
  String busStopCode;
  List<String?> services;

  Favourite({
    required this.busStopCode,
    required this.services,
  });

  factory Favourite.fromJson(Map<String, dynamic> json) => _$FavouriteFromJson(json);
  Map<String, dynamic> toJson() => _$FavouriteToJson(this);
}
