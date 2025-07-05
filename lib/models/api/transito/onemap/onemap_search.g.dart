// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onemap_search.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OneMapSearch _$OneMapSearchFromJson(Map<String, dynamic> json) => OneMapSearch(
      totalCount: (json['totalCount'] as num).toInt(),
      count: (json['count'] as num).toInt(),
      totalPages: (json['totalPages'] as num).toInt(),
      page: (json['page'] as num).toInt(),
      data: (json['data'] as List<dynamic>)
          .map((e) => OneMapSearchData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$OneMapSearchToJson(OneMapSearch instance) =>
    <String, dynamic>{
      'totalCount': instance.totalCount,
      'count': instance.count,
      'totalPages': instance.totalPages,
      'page': instance.page,
      'data': instance.data,
    };

OneMapSearchData _$OneMapSearchDataFromJson(Map<String, dynamic> json) =>
    OneMapSearchData(
      name: json['name'] as String,
      address: json['address'] as String,
      postalCode: json['postalCode'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );

Map<String, dynamic> _$OneMapSearchDataToJson(OneMapSearchData instance) =>
    <String, dynamic>{
      'name': instance.name,
      'address': instance.address,
      'postalCode': instance.postalCode,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };
