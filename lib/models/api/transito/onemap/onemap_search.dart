import 'package:json_annotation/json_annotation.dart';

part 'onemap_search.g.dart';

@JsonSerializable()
class OneMapSearch {
  @JsonKey(name: "totalCount")
  int totalCount;
  @JsonKey(name: "count")
  int count;
  @JsonKey(name: "totalPages")
  int totalPages;
  @JsonKey(name: "page")
  int page;
  @JsonKey(name: "data")
  List<OneMapSearchData> data;

  OneMapSearch({
    required this.totalCount,
    required this.count,
    required this.totalPages,
    required this.page,
    required this.data,
    
  });

  factory OneMapSearch.fromJson(Map<String, dynamic> json) => _$OneMapSearchFromJson(json);

  Map<String, dynamic> toJson() => _$OneMapSearchToJson(this);
}

@JsonSerializable()
class OneMapSearchData {
  @JsonKey(name: "name")
  String name;
  @JsonKey(name: "address")
  String address;
  @JsonKey(name: "postalCode")
  String? postalCode;
  @JsonKey(name: "latitude")
  double latitude;
  @JsonKey(name: "longitude")
  double longitude;

  OneMapSearchData({
    required this.name,
    required this.address,
    required this.postalCode,
    required this.latitude,
    required this.longitude,
  });

  factory OneMapSearchData.fromJson(Map<String, dynamic> json) => _$OneMapSearchDataFromJson(json);

  Map<String, dynamic> toJson() => _$OneMapSearchDataToJson(this);
}
