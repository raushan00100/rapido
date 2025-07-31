import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rapido/place_api_model.dart';

class RapidoServices {
  static Future<RapidoModel?> searchLocation(String searchText) async {
    var response = await http.post(
      Uri.parse("https://places.googleapis.com/v1/places:searchText"),
      body: {"textQuery": searchText},
      headers: {
        "X-Goog-Api-Key": "AIzaSyCILHFFrAhmyCY7Rp4itXt4qbbm0Ma8r9U",
        "X-Goog-FieldMask": "*",
      },
    );

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      var modelResponse = RapidoModel.fromJson(jsonResponse);
      return modelResponse;
    } else {
      return null;
    }
  }
}
