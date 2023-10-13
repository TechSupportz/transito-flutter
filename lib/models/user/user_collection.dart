import 'package:json_annotation/json_annotation.dart';
import 'package:transito/models/favourites/favourite.dart';

part 'user_collection.g.dart';

@JsonSerializable(explicitToJson: true)
class UserCollection {
  List<Favourite> favourites;
  String userId;

  UserCollection({
    required this.favourites,
    required this.userId,
  });

  factory UserCollection.fromJson(Map<String, dynamic> json) => _$UserCollectionFromJson(json);
  Map<String, dynamic> toJson() => _$UserCollectionToJson(this);
}
