import 'dart:convert';

RapidoModel placeApiModelFromJson(String str) =>
    RapidoModel.fromJson(json.decode(str));

String placeApiModelToJson(RapidoModel data) => json.encode(data.toJson());

class RapidoModel {
  List<Place>? places;

  RapidoModel({this.places});

  factory RapidoModel.fromJson(Map<String, dynamic> json) => RapidoModel(
    places: json["places"] == null
        ? []
        : List<Place>.from(json["places"]!.map((x) => Place.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "places": places == null
        ? []
        : List<dynamic>.from(places!.map((x) => x.toJson())),
  };
}

class Place {
  String? formattedAddress;
  DisplayName? displayName;

  Place({this.formattedAddress, this.displayName});

  factory Place.fromJson(Map<String, dynamic> json) => Place(
    formattedAddress: json["formattedAddress"],
    displayName: json["displayName"] == null
        ? null
        : DisplayName.fromJson(json["displayName"]),
  );

  Map<String, dynamic> toJson() => {
    "formattedAddress": formattedAddress,
    "displayName": displayName?.toJson(),
  };
}

class DisplayName {
  String? text;
  LanguageCode? languageCode;

  DisplayName({this.text, this.languageCode});

  factory DisplayName.fromJson(Map<String, dynamic> json) => DisplayName(
    text: json["text"],
    languageCode: languageCodeValues.map[json["languageCode"]]!,
  );

  Map<String, dynamic> toJson() => {
    "text": text,
    "languageCode": languageCodeValues.reverse[languageCode],
  };
}

enum LanguageCode { EN }

final languageCodeValues = EnumValues({"en": LanguageCode.EN});

class EnumValues<T> {
  Map<String, T> map;
  late Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    reverseMap = map.map((k, v) => MapEntry(v, k));
    return reverseMap;
  }
}
