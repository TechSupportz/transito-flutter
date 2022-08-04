// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_collection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserCollection _$UserCollectionFromJson(Map<String, dynamic> json) =>
    UserCollection(
      favourites: (json['favourites'] as List<dynamic>)
          .map((e) => Favourite.fromJson(e as Map<String, dynamic>))
          .toList(),
      userId: json['userId'] as String,
    );

Map<String, dynamic> _$UserCollectionToJson(UserCollection instance) =>
    <String, dynamic>{
      'favourites': instance.favourites.map((e) => e.toJson()).toList(),
      'userId': instance.userId,
    };
